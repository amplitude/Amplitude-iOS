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
#import <OCMock/OCMock.h>

#if !TARGET_OS_OSX
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif
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
#if !TARGET_OS_OSX
    id mockApplication = [OCMockObject niceMockForClass:[UIApplication class]];
    [[[mockApplication stub] andReturn:mockApplication] sharedApplication];
    OCMStub([mockApplication applicationState]).andReturn(UIApplicationStateBackground);
#endif
    // mock amplitude object and verify enterForeground not called
    id mockAmplitude = [OCMockObject partialMockForObject:self.amplitude];
    [[mockAmplitude reject] enterForeground];
    [mockAmplitude initializeApiKey:apiKey];
    [mockAmplitude flushQueueWithQueue:[mockAmplitude initializerQueue]];
    [mockAmplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    [mockAmplitude verify];
    XCTAssertEqual([mockAmplitude queuedEventCount], 0);
}

- (void)testSessionAutoStartedInactive {
#if !TARGET_OS_OSX
    id mockApplication = [OCMockObject niceMockForClass:[UIApplication class]];
    [[[mockApplication stub] andReturn:mockApplication] sharedApplication];
    OCMStub([mockApplication applicationState]).andReturn(UIApplicationStateInactive);
#endif
    id mockAmplitude = [OCMockObject partialMockForObject:self.amplitude];
    [mockAmplitude initializeApiKey:apiKey];
    [mockAmplitude flushQueueWithQueue:[mockAmplitude initializerQueue]];
    [mockAmplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssertEqual([mockAmplitude queuedEventCount], 0);
}

- (void)testSessionHandling {

    // start new session on initializeApiKey
    id mockAmplitude = [OCMockObject partialMockForObject:self.amplitude];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];

    [mockAmplitude initializeApiKey:apiKey userId:nil];
    [mockAmplitude flushQueueWithQueue:[mockAmplitude initializerQueue]];
    [mockAmplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssertEqual([mockAmplitude queuedEventCount], 0);
    XCTAssertEqual([mockAmplitude sessionId], 1000000);

    // also test getSessionId
    XCTAssertEqual([mockAmplitude getSessionId], 1000000);

    // A new session should start on UIApplicationWillEnterForeground after minTimeBetweenSessionsMillis
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    [mockAmplitude enterBackground]; // simulate app entering background
    [mockAmplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssertEqual([mockAmplitude sessionId], 1000000);

    NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:1000 + (self.amplitude.minTimeBetweenSessionsMillis / 1000)];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date2)] currentTime];
    [mockAmplitude enterForeground]; // simulate app entering foreground
    [mockAmplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssertEqual([mockAmplitude queuedEventCount], 0);
    XCTAssertEqual([mockAmplitude sessionId], 1000000 + self.amplitude.minTimeBetweenSessionsMillis);


    // An event should continue the session in the foreground after minTimeBetweenSessionsMillis + 1 seconds
    NSDate *date3 = [NSDate dateWithTimeIntervalSince1970:1000 + (self.amplitude.minTimeBetweenSessionsMillis / 1000) + 1];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date3)] currentTime];
    [mockAmplitude logEvent:@"continue_session"];
    [mockAmplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssertEqual([[mockAmplitude lastEventTime] longLongValue], 1001000 + self.amplitude.minTimeBetweenSessionsMillis);
    XCTAssertEqual([mockAmplitude queuedEventCount], 1);
    XCTAssertEqual([mockAmplitude sessionId], 1000000 + self.amplitude.minTimeBetweenSessionsMillis);


    // session should continue on UIApplicationWillEnterForeground after minTimeBetweenSessionsMillis - 1 second
    NSDate *date4 = [NSDate dateWithTimeIntervalSince1970:2000];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date4)] currentTime];
    [mockAmplitude enterBackground]; // simulate app entering background

    NSDate *date5 = [NSDate dateWithTimeIntervalSince1970:2000 + (self.amplitude.minTimeBetweenSessionsMillis / 1000) - 1];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date5)] currentTime];
    [mockAmplitude enterForeground]; // simulate app entering foreground
    [mockAmplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssertEqual([mockAmplitude queuedEventCount], 1);
    XCTAssertEqual([mockAmplitude sessionId], 1000000 + self.amplitude.minTimeBetweenSessionsMillis);


   // test out of session event
    NSDate *date6 = [NSDate dateWithTimeIntervalSince1970:3000];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date6)] currentTime];
    [mockAmplitude logEvent:@"No Session" withEventProperties:nil outOfSession:NO];
    [mockAmplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssert([[mockAmplitude getLastEvent][@"session_id"]
               isEqualToNumber:[NSNumber numberWithLongLong:1000000 + self.amplitude.minTimeBetweenSessionsMillis]]);

    NSDate *date7 = [NSDate dateWithTimeIntervalSince1970:3001];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date7)] currentTime];
    // An out of session event should have session_id = -1
    [mockAmplitude logEvent:@"No Session" withEventProperties:nil outOfSession:YES];
    [mockAmplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssert([[mockAmplitude getLastEvent][@"session_id"]
               isEqualToNumber:[NSNumber numberWithLongLong:-1]]);

    // An out of session event should not continue the session
    XCTAssertEqual([[mockAmplitude lastEventTime] longLongValue], 3000000); // event time of first no session

    // Test setSessionId
    long testSessionId = 1337;
    [mockAmplitude setSessionId:testSessionId];
    XCTAssertEqual([mockAmplitude sessionId], testSessionId);
}

- (void)testEnterBackgroundDoesNotTrackEvent {
    [self.amplitude initializeApiKey:apiKey userId:nil];
    [self.amplitude flushQueueWithQueue:self.amplitude.initializerQueue];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
#if !TARGET_OS_OSX
    [center postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];
#else
    [center postNotificationName:NSApplicationDidResignActiveNotification object:nil userInfo:nil];
#endif

    [self.amplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssertEqual([self.amplitude queuedEventCount], 0);
}

- (void)testTrackSessionEvents {
    id mockAmplitude = [OCMockObject partialMockForObject:self.amplitude];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    AMPDefaultTrackingOptions *defaultTracking = [AMPDefaultTrackingOptions initWithNoneEnabled];
    defaultTracking.sessions = YES;
    [mockAmplitude setDefaultTracking:defaultTracking];

    [mockAmplitude initializeApiKey:apiKey userId:nil];
    [mockAmplitude flushQueueWithQueue:[mockAmplitude initializerQueue]];
    [mockAmplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssertEqual([mockAmplitude queuedEventCount], 1);
    XCTAssertEqual([[mockAmplitude getLastEvent][@"session_id"] longLongValue], 1000000);
    XCTAssertEqualObjects([mockAmplitude getLastEvent][@"event_type"], kAMPSessionStartEvent);


    // test end session with tracking session events
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    [mockAmplitude enterBackground]; // simulate app entering background

    NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:1000 + (self.amplitude.minTimeBetweenSessionsMillis / 1000)];
    [((Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date2)]) currentTime];
    [mockAmplitude enterForeground]; // simulate app entering foreground
    [mockAmplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssertEqual([mockAmplitude queuedEventCount], 3);

    long long expectedSessionId = 1000000 + self.amplitude.minTimeBetweenSessionsMillis;
    XCTAssertEqual([mockAmplitude sessionId], expectedSessionId);

    XCTAssertEqual([[self.amplitude getEvent:1][@"session_id"] longLongValue], 1000000);
    XCTAssertEqualObjects([self.amplitude getEvent:1][@"event_type"], kAMPSessionEndEvent);
    XCTAssertEqual([[self.amplitude getEvent:1][@"timestamp"] longLongValue], 1000000);

    XCTAssertEqual([[self.amplitude getLastEvent][@"session_id"] longLongValue], expectedSessionId);
    XCTAssertEqualObjects([self.amplitude getLastEvent][@"event_type"], kAMPSessionStartEvent);

    // test in session identify with app in background
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date2)] currentTime];
    [mockAmplitude enterBackground]; // simulate app entering background

    NSDate *date3 = [NSDate dateWithTimeIntervalSince1970:1000 + 2 * self.amplitude.minTimeBetweenSessionsMillis];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date3)] currentTime];
    AMPIdentify *identify = [[AMPIdentify identify] set:@"key" value:@"value"];
    [mockAmplitude identify:identify outOfSession:NO];
    [mockAmplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssertEqual([mockAmplitude queuedEventCount], 5); // triggers session events

    // test out of session identify with app in background
    NSDate *date4 = [NSDate dateWithTimeIntervalSince1970:1000 + 3 * self.amplitude.minTimeBetweenSessionsMillis];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date4)] currentTime];
    [mockAmplitude identify:identify outOfSession:YES];
    [mockAmplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssertEqual([mockAmplitude queuedEventCount], 5); // does not trigger session events
}

- (void)testSessionEventsOn32BitDevices {
    id mockAmplitude = [OCMockObject partialMockForObject:self.amplitude];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:21474836470];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    AMPDefaultTrackingOptions *defaultTracking = [AMPDefaultTrackingOptions initWithNoneEnabled];
    defaultTracking.sessions = YES;
    [mockAmplitude setDefaultTracking:defaultTracking];

    [mockAmplitude initializeApiKey:apiKey userId:nil];
    [mockAmplitude flushQueueWithQueue:[mockAmplitude initializerQueue]];
    [mockAmplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssertEqual([mockAmplitude queuedEventCount], 1);
    XCTAssertEqual([[mockAmplitude getLastEvent][@"session_id"] longLongValue], 21474836470000);
    XCTAssertEqualObjects([mockAmplitude getLastEvent][@"event_type"], kAMPSessionStartEvent);


    // test end session with tracking session events
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    [mockAmplitude enterBackground]; // simulate app entering background

    NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:214748364700];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date2)] currentTime];
    [mockAmplitude enterForeground]; // simulate app entering foreground
    [self.amplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssertEqual([mockAmplitude queuedEventCount], 3);

    XCTAssertEqual([mockAmplitude sessionId], 214748364700000);

    XCTAssertEqual([[self.amplitude getEvent:1][@"session_id"] longLongValue], 21474836470000);
    XCTAssertEqualObjects([self.amplitude getEvent:1][@"event_type"], kAMPSessionEndEvent);

    XCTAssertEqual([[self.amplitude getLastEvent][@"session_id"] longLongValue], 214748364700000);
    XCTAssertEqualObjects([self.amplitude getLastEvent][@"event_type"], kAMPSessionStartEvent);
}

- (void)testSkipSessionCheckWhenLoggingSessionEvents {
    AMPDatabaseHelper *dbHelper = [AMPDatabaseHelper getDatabaseHelper];

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
    NSNumber *timestamp = [NSNumber numberWithLongLong:[date timeIntervalSince1970] * 1000];
    [dbHelper insertOrReplaceKeyLongValue:@"previous_session_id" value:timestamp];

    AMPDefaultTrackingOptions *defaultTracking = [AMPDefaultTrackingOptions initWithNoneEnabled];
    defaultTracking.sessions = YES;
    [self.amplitude setDefaultTracking:defaultTracking];
    [self.amplitude initializeApiKey:apiKey userId:nil];

    [self.amplitude flushQueue];
    [NSThread sleepForTimeInterval:0.2];

    XCTAssertEqual([dbHelper getEventCount], 2);
    NSArray *events = [dbHelper getEvents:-1 limit:2];
    XCTAssertEqualObjects(events[0][@"event_type"], kAMPSessionEndEvent);
    XCTAssertEqualObjects(events[1][@"event_type"], kAMPSessionStartEvent);
}

@end
