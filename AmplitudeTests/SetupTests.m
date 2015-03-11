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

@interface SetupTests : BaseTestCase

@end

@implementation SetupTests { }

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    // Ensure all background operations are done
    [super tearDown];
}

- (void)testApiKeySet {
    [self.amplitude initializeApiKey:apiKey];
    XCTAssertEqual(self.amplitude.apiKey, apiKey);
}

- (void)testDeviceIdSet {
    [self.amplitude initializeApiKey:apiKey];
    [self.amplitude flushQueue];
    XCTAssertNotNil([self.amplitude deviceId]);
    XCTAssertEqual([self.amplitude deviceId].length, 36);
    XCTAssertEqualObjects([self.amplitude deviceId], [[[UIDevice currentDevice] identifierForVendor] UUIDString]);
}

- (void)testUserIdNotSet {
    [self.amplitude initializeApiKey:apiKey];
    [self.amplitude flushQueue];
    XCTAssertNil([self.amplitude userId]);
}

- (void)testUserIdSet {
    [self.amplitude initializeApiKey:apiKey userId:userId];
    [self.amplitude flushQueue];
    XCTAssertEqualObjects([self.amplitude userId], userId);
}

- (void)testInitializedSet {
    [self.amplitude initializeApiKey:apiKey];
    XCTAssert([self.amplitude initialized]);
}

/**
 * Any number of session start calls should only generate exactly one logged event.
 */
- (void)testStartSession {
    [self.amplitude initializeApiKey:apiKey];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:UIApplicationDidBecomeActiveNotification object:nil userInfo:nil];
    [center postNotificationName:UIApplicationDidBecomeActiveNotification object:nil userInfo:nil];

    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude queuedEventCount], 1);
    XCTAssert([[self.amplitude getLastEvent][@"event_type"] isEqualToString:@"session_start"]);
}

- (void)testSessionEnd {
    [self.amplitude initializeApiKey:apiKey];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];

    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude queuedEventCount], 1);
    XCTAssert([[self.amplitude getEvent:0][@"event_type"] isEqualToString:@"session_end"]);
}

/**
 * Ending a session should case another start session event to be logged.
 */
- (void)testSessionRestart {
    [self.amplitude initializeApiKey:apiKey];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:UIApplicationDidBecomeActiveNotification object:nil userInfo:nil];
    [center postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil userInfo:nil];
    [center postNotificationName:UIApplicationDidBecomeActiveNotification object:nil userInfo:nil];

    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude queuedEventCount], 3);
    XCTAssert([[self.amplitude getEvent:0][@"event_type"] isEqualToString:@"session_start"]);
    XCTAssert([[self.amplitude getEvent:1][@"event_type"] isEqualToString:@"session_end"]);
    XCTAssert([[self.amplitude getEvent:2][@"event_type"] isEqualToString:@"session_start"]);
}

- (void)testOptOut {
    [self.amplitude initializeApiKey:apiKey];

    [self.amplitude setOptOut:YES];
    [self.amplitude logEvent:@"Opted Out"];
    [self.amplitude flushQueue];

    XCTAssert(self.amplitude.optOut == YES);
    XCTAssert(![[self.amplitude getLastEvent][@"event_type"] isEqualToString:@"Opted Out"]);

    [self.amplitude setOptOut:NO];
    [self.amplitude logEvent:@"Opted In"];
    [self.amplitude flushQueue];

    XCTAssert(self.amplitude.optOut == NO);
    XCTAssert([[self.amplitude getLastEvent][@"event_type"] isEqualToString:@"Opted In"]);
}

- (void)testUserPropertiesSet {
    [self.amplitude initializeApiKey:apiKey];

    NSDictionary *properties = @{
         @"shoeSize": @10,
         @"hatSize":  @5.125,
         @"name": @"John"
    };

    [self.amplitude setUserProperties:@{@"property": @"true"} replace:YES];
    [self.amplitude setUserProperties:properties replace:YES];

    [self.amplitude logEvent:@"Test Event"];
    [self.amplitude flushQueue];

    NSDictionary *event = [self.amplitude getLastEvent];
    XCTAssert([event[@"user_properties"] isEqualToDictionary:properties]);
}

- (void)testUserPropertiesMerge {
    [self.amplitude initializeApiKey:apiKey];

    NSMutableDictionary *properties = [@{
         @"shoeSize": @10,
         @"hatSize":  @5.125,
         @"name": @"John"
    } mutableCopy];

    [self.amplitude setUserProperties:properties];

    [self.amplitude logEvent:@"Test Event"];
    [self.amplitude flushQueue];

    NSDictionary *event = [self.amplitude getLastEvent];
    XCTAssert([event[@"user_properties"] isEqualToDictionary:properties]);

    NSDictionary *extraProperties = @{@"mergedProperty": @"merged"};
    [self.amplitude setUserProperties:extraProperties replace:NO];

    [self.amplitude logEvent:@"Test Event"];
    [self.amplitude flushQueue];

    event = [self.amplitude getLastEvent];
    [properties addEntriesFromDictionary:extraProperties];
    XCTAssert([event[@"user_properties"] isEqualToDictionary:properties]);
}

@end
