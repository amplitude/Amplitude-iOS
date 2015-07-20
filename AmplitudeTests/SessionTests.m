//
//  SessionTests.m
//  SessionTests
//
//  Created by Curtis on 9/24/14.
//  Copyright (c) 2014 Amplitude. All rights reserved.
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

- (void)testSessionAutoStarted {
    [self.amplitude initializeApiKey:apiKey];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude queuedEventCount], 0);
}

- (void)testSessionAutoStartedBackground {
    id mockApplication = [OCMockObject niceMockForClass:[UIApplication class]];
    [[[mockApplication stub] andReturn:mockApplication] sharedApplication];
    OCMStub([mockApplication applicationState]).andReturn(UIApplicationStateBackground);

    [[self.partialMockAmplitude reject] enterForeground];

    [self.amplitude initializeApiKey:apiKey];
    [self.amplitude flushQueue];
    [self.partialMockAmplitude verify];
    XCTAssertEqual([self.amplitude queuedEventCount], 0);

    [mockApplication stopMocking];
}

- (void)testSessionAutoStartedInactive {
    id mockApplication = [OCMockObject niceMockForClass:[UIApplication class]];
    [[[mockApplication stub] andReturn:mockApplication] sharedApplication];
    OCMStub([mockApplication applicationState]).andReturn(UIApplicationStateInactive);

    [[self.partialMockAmplitude expect] enterForeground];

    [self.amplitude initializeApiKey:apiKey];
    [self.amplitude flushQueue];
    [self.partialMockAmplitude verify];
    XCTAssertEqual([self.amplitude queuedEventCount], 0);
    
    [mockApplication stopMocking];
}

/**
 * A new session should start on initializeApiKey
 */
- (void)testStartSession {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
    OCMStub([self.partialMockAmplitude currentTime]).andReturn(date);

    [self.amplitude initializeApiKey:apiKey userId:nil];

    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude queuedEventCount], 0);

    XCTAssertEqual(self.amplitude.sessionId, 1000000);
}

/**
 * A new session should start on UIApplicationWillEnterForeground after minTimeBetweenSessionsMillis
 */
- (void)testRestartSessionOnUIApplicationWillEnterForeground {
    __block NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    [[[self.partialMockAmplitude stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:&date];
    }] currentTime];

    [self.amplitude initializeApiKey:apiKey userId:nil];
    [self.amplitude flushQueueWithQueue:self.amplitude.initializerQueue];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    date = [NSDate dateWithTimeIntervalSince1970:1000];
    [center postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];

    date = [NSDate dateWithTimeIntervalSince1970:1000 + (self.amplitude.minTimeBetweenSessionsMillis / 1000)];
    [center postNotificationName:UIApplicationWillEnterForegroundNotification object:nil userInfo:nil];

    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude queuedEventCount], 0);
    
    XCTAssertEqual(self.amplitude.sessionId, 1000000 + self.amplitude.minTimeBetweenSessionsMillis);
}

/**
 * An event should continue the session in the foreground after minTimeBetweenSessionsMillis + 1 seconds
 */
- (void)testContinueSessionInForeground {
    __block NSDate* date = [NSDate dateWithTimeIntervalSince1970:0];
    [[[self.partialMockAmplitude stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:&date];
    }] currentTime];

    [self.amplitude initializeApiKey:apiKey userId:nil];
    [self.amplitude flushQueueWithQueue:self.amplitude.initializerQueue];

    date = [NSDate dateWithTimeIntervalSince1970:1000 + (self.amplitude.minTimeBetweenSessionsMillis / 1000) + 1];
    [self.amplitude logEvent:@"continue_session"];

    [self.amplitude flushQueue];
    XCTAssertEqual([[self.amplitude getLastEventTime] longLongValue], 1001000 + self.amplitude.minTimeBetweenSessionsMillis);
    XCTAssertEqual([self.amplitude queuedEventCount], 1);
    XCTAssertEqual(self.amplitude.sessionId, 0);
}

/**
 * A new session should continue on UIApplicationWillEnterForeground after minTimeBetweenSessionsMillis - 1 second
 */
- (void)testContinueSessionOnUIApplicationWillEnterForeground {
    __block NSDate* date = [NSDate dateWithTimeIntervalSince1970:0];
    [[[self.partialMockAmplitude stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:&date];
    }] currentTime];
    
    [self.amplitude initializeApiKey:apiKey userId:nil];
    [self.amplitude flushQueueWithQueue:self.amplitude.initializerQueue];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    date = [NSDate dateWithTimeIntervalSince1970:1000];
    [center postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];

    date = [NSDate dateWithTimeIntervalSince1970:1000 + (self.amplitude.minTimeBetweenSessionsMillis / 1000) - 1];

    [center postNotificationName:UIApplicationWillEnterForegroundNotification object:nil userInfo:nil];
    
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude queuedEventCount], 0);
    
    XCTAssertEqual(self.amplitude.sessionId, 0);
}

- (void)testSessionEnd {
    [self.amplitude initializeApiKey:apiKey userId:nil];
    [self.amplitude flushQueueWithQueue:self.amplitude.initializerQueue];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];

    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude queuedEventCount], 0);
}

- (void)testOutOfSessionEvent {
    __block NSDate* date = [NSDate dateWithTimeIntervalSince1970:1000];
    [[[self.partialMockAmplitude stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:&date];
    }] currentTime];
    [self.amplitude initializeApiKey:apiKey];
    [self.amplitude flushQueueWithQueue:self.amplitude.initializerQueue];
    
    [self.amplitude logEvent:@"No Session" withEventProperties:nil outOfSession:NO];
    [self.amplitude flushQueue];
    
    XCTAssert([[self.amplitude getLastEvent][@"session_id"]
                isEqualToNumber:[NSNumber numberWithLongLong:1000000]]);

    
    date = [NSDate dateWithTimeIntervalSince1970:1001];
    // An out of session event should have session_id = -1
    [self.amplitude logEvent:@"No Session" withEventProperties:nil outOfSession:YES];
    [self.amplitude flushQueue];
    
    XCTAssert([[self.amplitude getLastEvent][@"session_id"]
               isEqualToNumber:[NSNumber numberWithLongLong:-1]]);
    
    // An out of session event should not continue the session
    XCTAssertEqual([[self.amplitude getLastEventTime] longLongValue], 1000000);
}

- (void)testStartSessionWithTrackSessionEvents {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
    OCMStub([self.partialMockAmplitude currentTime]).andReturn(date);
    self.amplitude.trackingSessionEvents = true;
    [self.amplitude initializeApiKey:apiKey userId:nil];

    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude queuedEventCount], 1);

    XCTAssertEqual([[self.amplitude getLastEvent][@"session_id"] longLongValue], 1000000);
    XCTAssertEqualObjects([self.amplitude getLastEvent][@"event_type"], kAMPSessionStartEvent);
}


- (void)testEndSessionWithTrackSessionEvents {
    __block NSDate *date = [NSDate dateWithTimeIntervalSince1970:0];
    [[[self.partialMockAmplitude stub] andDo:^(NSInvocation *invocation) {
        [invocation setReturnValue:&date];
    }] currentTime];

    self.amplitude.trackingSessionEvents = true;
    [self.amplitude initializeApiKey:apiKey userId:nil];
    [self.amplitude flushQueueWithQueue:self.amplitude.initializerQueue];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    date = [NSDate dateWithTimeIntervalSince1970:1000];
    [center postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];

    date = [NSDate dateWithTimeIntervalSince1970:1000 + (self.amplitude.minTimeBetweenSessionsMillis / 1000)];
    [center postNotificationName:UIApplicationWillEnterForegroundNotification object:nil userInfo:nil];

    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude queuedEventCount], 3);

    long long expectedSessionId = 1000000 + self.amplitude.minTimeBetweenSessionsMillis;
    XCTAssertEqual(self.amplitude.sessionId, expectedSessionId);

    XCTAssertEqual([[self.amplitude getEvent:1][@"session_id"] longLongValue], 0);
    XCTAssertEqualObjects([self.amplitude getEvent:1][@"event_type"], kAMPSessionEndEvent);
    XCTAssertEqual([[self.amplitude getEvent:1][@"timestamp"] longLongValue], 1000000);

    XCTAssertEqual([[self.amplitude getLastEvent][@"session_id"] longLongValue], expectedSessionId);
    XCTAssertEqualObjects([self.amplitude getLastEvent][@"event_type"], kAMPSessionStartEvent);
}

@end
