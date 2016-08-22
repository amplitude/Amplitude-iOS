//
//  SessionTests.m
//  SessionTests
//
//  Created by Curtis on 9/24/14.
//  Copyright (c) 2014 Amplitude. All rights reserved.
//
//  NOTE: Having a lot of OCMock partialMockObjects causes tests to be flakey.
//        Combined a lot of tests into one large test so they share a single
//        mockAmplitude object instead creating lots of separate ones.
//        This seems to have fixed the flakiness issue.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <OCMock/OCMock.h>
#import "Amplitude.h"
#import "Amplitude+Test.h"
#import "BaseTestCase.h"

@interface SessionTests : BaseTestCase

@end

@implementation SessionTests { }

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSessionAutoStartedBackground {
    // mock application state
    id mockApplication = [OCMockObject niceMockForClass:[UIApplication class]];
    [[[mockApplication stub] andReturn:mockApplication] sharedApplication];
    OCMStub([mockApplication applicationState]).andReturn(UIApplicationStateBackground);

    // mock amplitude object and verify enterForeground not called
    id mockAmplitude = [OCMockObject partialMockForObject:self.amplitude];
    [[mockAmplitude reject] enterForeground];
    [[[mockAmplitude setApiKey:apiKey] initialize] flushQueue];
    [mockAmplitude verify];
    XCTAssertEqual([mockAmplitude queuedEventCount], 0);
}

- (void)testSessionAutoStartedInactive {
    id mockApplication = [OCMockObject niceMockForClass:[UIApplication class]];
    [[[mockApplication stub] andReturn:mockApplication] sharedApplication];
    OCMStub([mockApplication applicationState]).andReturn(UIApplicationStateInactive);

    id mockAmplitude = [OCMockObject partialMockForObject:self.amplitude];
    [[mockAmplitude expect] enterForeground];
    [[[mockAmplitude setApiKey:apiKey] initialize] flushQueue];
    [mockAmplitude verify];
    XCTAssertEqual([mockAmplitude queuedEventCount], 0);
}

- (void)testSessionHandling {

    // start new session on initializeApiKey
    id mockAmplitude = [OCMockObject partialMockForObject:self.amplitude];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
    [[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];

    [[[[mockAmplitude setApiKey:apiKey] setUserId:nil] initialize] flushQueue];
    XCTAssertEqual([mockAmplitude queuedEventCount], 0);
    XCTAssertEqual([mockAmplitude sessionId], 1000000);

    // also test getSessionId
    XCTAssertEqual([mockAmplitude getSessionId], 1000000);

    // A new session should start on UIApplicationWillEnterForeground after minTimeBetweenSessionsMillis
    [[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    [mockAmplitude enterBackground]; // simulate app entering background
    [mockAmplitude flushQueue];
    XCTAssertEqual([mockAmplitude sessionId], 1000000);

    NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:1000 + (self.amplitude.minTimeBetweenSessionsMillis / 1000)];
    [[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date2)] currentTime];
    [mockAmplitude enterForeground]; // simulate app entering foreground
    [mockAmplitude flushQueue];

    XCTAssertEqual([mockAmplitude queuedEventCount], 0);
    XCTAssertEqual([mockAmplitude sessionId], 1000000 + self.amplitude.minTimeBetweenSessionsMillis);


    // An event should continue the session in the foreground after minTimeBetweenSessionsMillis + 1 seconds
    NSDate *date3 = [NSDate dateWithTimeIntervalSince1970:1000 + (self.amplitude.minTimeBetweenSessionsMillis / 1000) + 1];
    [[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date3)] currentTime];
    [mockAmplitude logEvent:@"continue_session"];
    [mockAmplitude flushQueue];

    XCTAssertEqual([[mockAmplitude lastEventTime] longLongValue], 1001000 + self.amplitude.minTimeBetweenSessionsMillis);
    XCTAssertEqual([mockAmplitude queuedEventCount], 1);
    XCTAssertEqual([mockAmplitude sessionId], 1000000 + self.amplitude.minTimeBetweenSessionsMillis);


    // session should continue on UIApplicationWillEnterForeground after minTimeBetweenSessionsMillis - 1 second
    NSDate *date4 = [NSDate dateWithTimeIntervalSince1970:2000];
    [[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date4)] currentTime];
    [mockAmplitude enterBackground]; // simulate app entering background

    NSDate *date5 = [NSDate dateWithTimeIntervalSince1970:2000 + (self.amplitude.minTimeBetweenSessionsMillis / 1000) - 1];
    [[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date5)] currentTime];
    [mockAmplitude enterForeground]; // simulate app entering foreground
    [mockAmplitude flushQueue];

    XCTAssertEqual([mockAmplitude queuedEventCount], 1);
    XCTAssertEqual([mockAmplitude sessionId], 1000000 + self.amplitude.minTimeBetweenSessionsMillis);


   // test out of session event
    NSDate *date6 = [NSDate dateWithTimeIntervalSince1970:3000];
    [[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date6)] currentTime];
    [mockAmplitude logEvent:@"No Session" withEventProperties:nil outOfSession:NO];
    [mockAmplitude flushQueue];
    XCTAssert([[mockAmplitude getLastEvent][@"session_id"]
               isEqualToNumber:[NSNumber numberWithLongLong:1000000 + self.amplitude.minTimeBetweenSessionsMillis]]);

    NSDate *date7 = [NSDate dateWithTimeIntervalSince1970:3001];
    [[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date7)] currentTime];
    // An out of session event should have session_id = -1
    [mockAmplitude logEvent:@"No Session" withEventProperties:nil outOfSession:YES];
    [mockAmplitude flushQueue];
    XCTAssert([[mockAmplitude getLastEvent][@"session_id"]
               isEqualToNumber:[NSNumber numberWithLongLong:-1]]);

    // An out of session event should not continue the session
    XCTAssertEqual([[mockAmplitude lastEventTime] longLongValue], 3000000); // event time of first no session
}

- (void)testEnterBackgroundDoesNotTrackEvent {
    [[[[self.amplitude setApiKey:apiKey] setUserId:nil] initialize] flushQueue];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];

    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude queuedEventCount], 0);
}

- (void)testTrackSessionEvents {
    id mockAmplitude = [OCMockObject partialMockForObject:self.amplitude];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
    [[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    [mockAmplitude setTrackingSessionEvents:YES];

    [[[[mockAmplitude setApiKey:apiKey] setUserId:nil] initialize] flushQueue];
    XCTAssertEqual([mockAmplitude queuedEventCount], 1);
    XCTAssertEqual([[mockAmplitude getLastEvent][@"session_id"] longLongValue], 1000000);
    XCTAssertEqualObjects([mockAmplitude getLastEvent][@"event_type"], kAMPSessionStartEvent);


    // test end session with tracking session events
    [[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    [mockAmplitude enterBackground]; // simulate app entering background

    NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:1000 + (self.amplitude.minTimeBetweenSessionsMillis / 1000)];
    [[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date2)] currentTime];
    [mockAmplitude enterForeground]; // simulate app entering foreground
    [self.amplitude flushQueue];
    XCTAssertEqual([mockAmplitude queuedEventCount], 3);

    long long expectedSessionId = 1000000 + self.amplitude.minTimeBetweenSessionsMillis;
    XCTAssertEqual([mockAmplitude sessionId], expectedSessionId);

    XCTAssertEqual([[self.amplitude getEvent:1][@"session_id"] longLongValue], 1000000);
    XCTAssertEqualObjects([self.amplitude getEvent:1][@"event_type"], kAMPSessionEndEvent);
    XCTAssertEqual([[self.amplitude getEvent:1][@"timestamp"] longLongValue], 1000000);

    XCTAssertEqual([[self.amplitude getLastEvent][@"session_id"] longLongValue], expectedSessionId);
    XCTAssertEqualObjects([self.amplitude getLastEvent][@"event_type"], kAMPSessionStartEvent);
}

- (void)testSessionEventsOn32BitDevices {
    id mockAmplitude = [OCMockObject partialMockForObject:self.amplitude];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:21474836470];
    [[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    [mockAmplitude setTrackingSessionEvents:YES];

    [[[[mockAmplitude setApiKey:apiKey] setUserId:nil] initialize] flushQueue];
    XCTAssertEqual([mockAmplitude queuedEventCount], 1);
    XCTAssertEqual([[mockAmplitude getLastEvent][@"session_id"] longLongValue], 21474836470000);
    XCTAssertEqualObjects([mockAmplitude getLastEvent][@"event_type"], kAMPSessionStartEvent);


    // test end session with tracking session events
    [[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    [mockAmplitude enterBackground]; // simulate app entering background

    NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:214748364700];
    [[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date2)] currentTime];
    [mockAmplitude enterForeground]; // simulate app entering foreground
    [self.amplitude flushQueue];
    XCTAssertEqual([mockAmplitude queuedEventCount], 3);

    XCTAssertEqual([mockAmplitude sessionId], 214748364700000);

    XCTAssertEqual([[self.amplitude getEvent:1][@"session_id"] longLongValue], 21474836470000);
    XCTAssertEqualObjects([self.amplitude getEvent:1][@"event_type"], kAMPSessionEndEvent);

    XCTAssertEqual([[self.amplitude getLastEvent][@"session_id"] longLongValue], 214748364700000);
    XCTAssertEqualObjects([self.amplitude getLastEvent][@"event_type"], kAMPSessionStartEvent);
}

- (void)testSkipSessionCheckWhenLoggingSessionEvents {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
    NSNumber *timestamp = [NSNumber numberWithLongLong:[date timeIntervalSince1970] * 1000];
    [self.databaseHelper insertOrReplaceKeyLongValue:@"previous_session_id" value:timestamp];

    self.amplitude.trackingSessionEvents = YES;
    [[[[self.amplitude setApiKey:apiKey] setUserId:nil] initialize] flushQueue];
    XCTAssertEqual([self.databaseHelper getEventCount], 2);
    NSArray *events = [self.databaseHelper getEvents:-1 limit:2];
    XCTAssertEqualObjects(events[0][@"event_type"], kAMPSessionEndEvent);
    XCTAssertEqualObjects(events[1][@"event_type"], kAMPSessionStartEvent);
}

@end
