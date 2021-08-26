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

@interface Amplitude (Testing)

@property (nonatomic, assign) long long sessionId;

@property (nonatomic, strong) NSMutableArray *eventsBuffer;
@property (nonatomic, strong) NSMutableArray *identifyBuffer;
+ (void)cleanUp;

@end

@implementation SessionTests {
    id _sharedSessionMock;
}

- (void)setUp {
    [super setUp];
#if !TARGET_OS_OSX
    _sharedSessionMock = [OCMockObject niceMockForClass:[UIApplication class]];
    [[[_sharedSessionMock stub] andReturn:_sharedSessionMock] sharedApplication];
    OCMStub([_sharedSessionMock applicationState]).andReturn(UIApplicationStateInactive);
#endif
}

- (void)tearDown {
    [super tearDown];
    [Amplitude cleanUp];
#if !TARGET_OS_OSX
    [_sharedSessionMock stopMocking];
#endif
}

- (void)testSessionAutoStartedBackground {
    // mock application state
    // mock amplitude object and verify enterForeground not called
    Amplitude *amplitude = [Amplitude instanceWithName:@"testSessionAutoStartedBackground"];
    id mockAmplitude = [OCMockObject partialMockForObject:amplitude];
    [[mockAmplitude reject] enterForeground];
    [mockAmplitude initializeApiKey:apiKey];
    [mockAmplitude flushQueueWithQueue:[mockAmplitude initializerQueue]];
    [mockAmplitude flushQueue];
    [mockAmplitude verify];
    XCTAssertEqual([[mockAmplitude getAllEventsWithInstanceName:amplitude.instanceName] count], 0);
    [mockAmplitude stopMocking];
}

- (void)testSessionAutoStartedInactive {
    Amplitude *amplitude = [Amplitude instanceWithName:@"testSessionAutoStartedInactive"];
    id mockAmplitude = [OCMockObject partialMockForObject:amplitude];
    [mockAmplitude initializeApiKey:apiKey];
    [mockAmplitude flushQueueWithQueue:[mockAmplitude initializerQueue]];
    [mockAmplitude flushQueue];
    XCTAssertEqual([[mockAmplitude getAllEventsWithInstanceName:amplitude.instanceName] count], 0);
    [mockAmplitude stopMocking];
}

- (void)testSessionHandling {
    // start new session on initializeApiKey
    Amplitude *amplitude = [Amplitude instanceWithName:@"testSessionHandling"];
    id mockAmplitude = [OCMockObject partialMockForObject:amplitude];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    
    [mockAmplitude initializeApiKey:apiKey userId:nil];
    [mockAmplitude flushQueueWithQueue:[mockAmplitude initializerQueue]];
    [mockAmplitude flushQueue];
    XCTAssertEqual([[mockAmplitude valueForKey:@"eventsBuffer"] count], 0);
    XCTAssertEqual([mockAmplitude sessionId], 1000000);

    // also test getSessionId
    XCTAssertEqual([mockAmplitude getSessionId], 1000000);

    // A new session should start on UIApplicationWillEnterForeground after minTimeBetweenSessionsMillis
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    [mockAmplitude enterBackground]; // simulate app entering background
    [mockAmplitude flushQueue];
    XCTAssertEqual([mockAmplitude sessionId], 1000000);

    NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:1000 + (amplitude.minTimeBetweenSessionsMillis / 1000)];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date2)] currentTime];
    [mockAmplitude enterForeground]; // simulate app entering foreground
    [mockAmplitude flushQueue];

    XCTAssertEqual([[mockAmplitude valueForKey:@"eventsBuffer"] count], 0);
    XCTAssertEqual([mockAmplitude sessionId], 1000000 + amplitude.minTimeBetweenSessionsMillis);


    // An event should continue the session in the foreground after minTimeBetweenSessionsMillis + 1 seconds
    NSDate *date3 = [NSDate dateWithTimeIntervalSince1970:1000 + (amplitude.minTimeBetweenSessionsMillis / 1000) + 1];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date3)] currentTime];
    [mockAmplitude logEvent:@"continue_session"];
    [mockAmplitude flushQueue];

    XCTAssertEqual([[mockAmplitude lastEventTime] longLongValue], 1001000 + amplitude.minTimeBetweenSessionsMillis);
    XCTAssertEqual([[mockAmplitude valueForKey:@"eventsBuffer"] count], 1);
    XCTAssertEqual([mockAmplitude sessionId], 1000000 + amplitude.minTimeBetweenSessionsMillis);


    // session should continue on UIApplicationWillEnterForeground after minTimeBetweenSessionsMillis - 1 second
    NSDate *date4 = [NSDate dateWithTimeIntervalSince1970:2000];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date4)] currentTime];
    [mockAmplitude enterBackground]; // simulate app entering background

    NSDate *date5 = [NSDate dateWithTimeIntervalSince1970:2000 + (amplitude.minTimeBetweenSessionsMillis / 1000) - 1];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date5)] currentTime];
    [mockAmplitude enterForeground]; // simulate app entering foreground
    [mockAmplitude flushQueue];

    XCTAssertEqual([[mockAmplitude valueForKey:@"eventsBuffer"] count], 1);
    XCTAssertEqual([mockAmplitude sessionId], 1000000 + amplitude.minTimeBetweenSessionsMillis);

   // test out of session event
    NSDate *date6 = [NSDate dateWithTimeIntervalSince1970:3000];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date6)] currentTime];
    [mockAmplitude logEvent:@"No Session" withEventProperties:nil outOfSession:NO];
    [mockAmplitude flushQueue];
    XCTAssert([[mockAmplitude getLastEventWithInstanceName:amplitude.instanceName][@"session_id"]
               isEqualToNumber:[NSNumber numberWithLongLong:1000000 + amplitude.minTimeBetweenSessionsMillis]]);

    NSDate *date7 = [NSDate dateWithTimeIntervalSince1970:3001];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date7)] currentTime];
    // An out of session event should have session_id = -1
    [mockAmplitude logEvent:@"No Session" withEventProperties:nil outOfSession:YES];
    [mockAmplitude flushQueue];
    XCTAssert([[[mockAmplitude valueForKey:@"eventsBuffer"] lastObject][@"session_id"]
               isEqualToNumber:[NSNumber numberWithLongLong:-1]]);

    // An out of session event should not continue the session
    XCTAssertEqual([[mockAmplitude lastEventTime] longLongValue], 3000000); // event time of first no session

    // Test setSessionId
    long testSessionId = 1337;
    [mockAmplitude setSessionId:testSessionId];
    XCTAssertEqual([mockAmplitude sessionId], testSessionId);
    [mockAmplitude stopMocking];
}

- (void)testEnterBackgroundDoesNotTrackEvent {
    Amplitude *amplitude = [Amplitude instanceWithName:@"testEnterBackgroundDoesNotTrackEvent"];
    [amplitude initializeApiKey:apiKey userId:nil];
    [amplitude flushQueueWithQueue:amplitude.initializerQueue];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
#if !TARGET_OS_OSX
    [center postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];
#else
    [center postNotificationName:NSApplicationDidResignActiveNotification object:nil userInfo:nil];
#endif

    [amplitude flushQueue];
    XCTAssertEqual([[amplitude valueForKey:@"eventsBuffer"] count], 0);
}

- (void)testTrackSessionEvents {
    Amplitude *amplitude = [Amplitude instanceWithName:@"testTrackSessionEvents"];
    id mockAmplitude = [OCMockObject partialMockForObject:amplitude];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    [mockAmplitude setTrackingSessionEvents:YES];

    [mockAmplitude initializeApiKey:apiKey userId:nil];
    [mockAmplitude flushQueueWithQueue:[mockAmplitude initializerQueue]];
    [mockAmplitude flushQueue];
    XCTAssertEqual([[mockAmplitude valueForKey:@"eventsBuffer"] count], 1);
    XCTAssertEqual([[[mockAmplitude valueForKey:@"eventsBuffer"] lastObject][@"session_id"] longLongValue], 1000000);
    XCTAssertEqualObjects([[mockAmplitude valueForKey:@"eventsBuffer"] lastObject][@"event_type"], kAMPSessionStartEvent);


    // test end session with tracking session events
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    [mockAmplitude enterBackground]; // simulate app entering background

    NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:1000 + (amplitude.minTimeBetweenSessionsMillis / 1000)];
    [((Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date2)]) currentTime];
    [mockAmplitude enterForeground]; // simulate app entering foreground
    [mockAmplitude flushQueue];
    XCTAssertEqual([[mockAmplitude valueForKey:@"eventsBuffer"] count], 3);

    long long expectedSessionId = 1000000 + amplitude.minTimeBetweenSessionsMillis;
    XCTAssertEqual([mockAmplitude sessionId], expectedSessionId);

    XCTAssertEqual([[mockAmplitude valueForKey:@"eventsBuffer"][1][@"session_id"] longLongValue], 1000000);
    XCTAssertEqualObjects([mockAmplitude valueForKey:@"eventsBuffer"][1][@"event_type"], kAMPSessionEndEvent);
    XCTAssertEqual([[mockAmplitude valueForKey:@"eventsBuffer"][1][@"timestamp"] longLongValue], 1000000);

    XCTAssertEqual([[[mockAmplitude valueForKey:@"eventsBuffer"] lastObject][@"session_id"] longLongValue], expectedSessionId);
    XCTAssertEqualObjects([[mockAmplitude valueForKey:@"eventsBuffer"] lastObject][@"event_type"], kAMPSessionStartEvent);

    // test in session identify with app in background
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date2)] currentTime];
    [mockAmplitude enterBackground]; // simulate app entering background

    NSDate *date3 = [NSDate dateWithTimeIntervalSince1970:1000 + 2 * amplitude.minTimeBetweenSessionsMillis];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date3)] currentTime];
    AMPIdentify *identify = [[AMPIdentify identify] set:@"key" value:@"value"];
    [mockAmplitude identify:identify outOfSession:NO];
    [mockAmplitude flushQueue];
    XCTAssertEqual([[mockAmplitude valueForKey:@"eventsBuffer"] count], 5);
    XCTAssertEqual([[mockAmplitude valueForKey:@"identifyBuffer"] count], 1);

    // test out of session identify with app in background
    NSDate *date4 = [NSDate dateWithTimeIntervalSince1970:1000 + 3 * amplitude.minTimeBetweenSessionsMillis];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date4)] currentTime];
    [mockAmplitude identify:identify outOfSession:YES];
    [mockAmplitude flushQueue];
    XCTAssertEqual([[mockAmplitude valueForKey:@"eventsBuffer"] count], 5);
    XCTAssertEqual([[mockAmplitude valueForKey:@"identifyBuffer"] count], 2);
    [mockAmplitude stopMocking];
 }

- (void)testSessionEventsOn32BitDevices {
    Amplitude *amplitude = [Amplitude instanceWithName:@"testSessionEventsOn32BitDevices"];
    id mockAmplitude = [OCMockObject partialMockForObject:amplitude];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:21474836470];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    [mockAmplitude setTrackingSessionEvents:YES];

    [mockAmplitude initializeApiKey:apiKey userId:nil];
    [mockAmplitude flushQueueWithQueue:[mockAmplitude initializerQueue]];
    [mockAmplitude flushQueue];

    NSMutableArray *events = [mockAmplitude valueForKey:@"eventsBuffer"];
    XCTAssertEqual([events count], 1);
    XCTAssertEqual([[events lastObject][@"session_id"] longLongValue], 21474836470000);
    XCTAssertEqualObjects([events lastObject][@"event_type"], kAMPSessionStartEvent);

    // test end session with tracking session events
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];
    [mockAmplitude enterBackground]; // simulate app entering background

    NSDate *date2 = [NSDate dateWithTimeIntervalSince1970:214748364700];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date2)] currentTime];
    [mockAmplitude enterForeground]; // simulate app entering foreground
    [amplitude flushQueue];
    XCTAssertEqual([[mockAmplitude valueForKey:@"eventsBuffer"] count], 3);

    XCTAssertEqual([mockAmplitude sessionId], 214748364700000);
    XCTAssertEqual([[mockAmplitude valueForKey:@"eventsBuffer"][1][@"session_id"] longLongValue], 21474836470000);
    XCTAssertEqualObjects([mockAmplitude valueForKey:@"eventsBuffer"][1][@"event_type"], kAMPSessionEndEvent);

    XCTAssertEqual([[[mockAmplitude valueForKey:@"eventsBuffer"] lastObject][@"session_id"] longLongValue], 214748364700000);
    XCTAssertEqualObjects([[mockAmplitude valueForKey:@"eventsBuffer"] lastObject][@"event_type"], kAMPSessionStartEvent);
    [mockAmplitude stopMocking];
}

- (void)testSkipSessionCheckWhenLoggingSessionEvents {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
    NSNumber *timestamp = [NSNumber numberWithLongLong:[date timeIntervalSince1970] * 1000];
    Amplitude *amplitude = [Amplitude instanceWithName:@"testSkipSessionCheckWhenLoggingSessionEvents"];
    amplitude.sessionId = [timestamp longLongValue];

    id mockAmplitude = [OCMockObject partialMockForObject:amplitude];
    [(Amplitude *)[[mockAmplitude expect] andReturnValue:OCMOCK_VALUE(date)] currentTime];

    [mockAmplitude setTrackingSessionEvents:YES];
    [mockAmplitude initializeApiKey:apiKey userId:nil];

    [mockAmplitude flushQueueWithQueue:[mockAmplitude initializerQueue]];
    [mockAmplitude flushQueue];
    NSMutableArray *events = [mockAmplitude valueForKey:@"eventsBuffer"];
    XCTAssertEqual([events count], 2);
    XCTAssertEqualObjects(events[0][@"event_type"], kAMPSessionEndEvent);
    XCTAssertEqualObjects(events[1][@"event_type"], kAMPSessionStartEvent);
    [mockAmplitude stopMocking];
    
}

@end
