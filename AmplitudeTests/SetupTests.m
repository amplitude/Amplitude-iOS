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
#import "AMPConstants.h"

@interface SetupTests : BaseTestCase

@end

@implementation SetupTests { }

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
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
    AMPDatabaseHelper *dbHelper = [AMPDatabaseHelper getDatabaseHelper];
    XCTAssertEqual([dbHelper getEventCount], 0);

    NSDictionary *properties = @{
         @"shoeSize": @10,
         @"hatSize":  @5.125,
         @"name": @"John"
    };

    [self.amplitude setUserProperties:properties];
    [self.amplitude flushQueue];
    XCTAssertEqual([dbHelper getEventCount], 1);

    NSDictionary *expected = [NSDictionary dictionaryWithObject:properties forKey:AMP_OP_SET];

    NSDictionary *event = [self.amplitude getLastEvent];
    XCTAssertEqualObjects([event objectForKey:@"event_type"], IDENTIFY_EVENT);
    XCTAssertEqualObjects([event objectForKey:@"user_properties"], expected);
    XCTAssertEqualObjects([event objectForKey:@"event_properties"], [NSDictionary dictionary]); // event properties should be empty
}

@end
