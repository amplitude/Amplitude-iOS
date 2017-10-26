//
//  SessionTests.m
//  SessionTests
//
//  Created by Curtis on 9/24/14.
//  Copyright (c) 2014 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#if TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif
#import <OCMock/OCMock.h>
#import "Amplitude.h"
#import "Amplitude+Test.h"
#import "BaseTestCase.h"
#import "AMPConstants.h"
#import "AMPUtils.h"

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
#if TARGET_OS_OSX
    XCTAssertEqual([self.amplitude deviceId].length, 12);
#else
    XCTAssertEqual([self.amplitude deviceId].length, 36);
    XCTAssertEqualObjects([self.amplitude deviceId], [[[UIDevice currentDevice] identifierForVendor] UUIDString]);
#endif
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
    XCTAssertEqual([dbHelper getEventCount], 0);
    XCTAssertEqual([dbHelper getIdentifyCount], 1);
    XCTAssertEqual([dbHelper getTotalEventCount], 1);

    NSDictionary *expected = [NSDictionary dictionaryWithObject:properties forKey:AMP_OP_SET];

    NSDictionary *event = [self.amplitude getLastIdentify];
    XCTAssertEqualObjects([event objectForKey:@"event_type"], IDENTIFY_EVENT);
    XCTAssertEqualObjects([event objectForKey:@"user_properties"], expected);
    XCTAssertEqualObjects([event objectForKey:@"event_properties"], [NSDictionary dictionary]); // event properties should be empty
    XCTAssertEqual(1, [[event objectForKey:@"sequence_number"] intValue]);
}

- (void)testSetDeviceId {
    AMPDatabaseHelper *dbHelper = [AMPDatabaseHelper getDatabaseHelper];
    NSString *initialDeviceId = [self.amplitude getDeviceId];
    XCTAssertNil(initialDeviceId);  // device id not initialized yet

    [self.amplitude initializeApiKey:apiKey];
    [self.amplitude flushQueueWithQueue:self.amplitude.initializerQueue];
    [self.amplitude flushQueue];
    NSString *generatedDeviceId = [self.amplitude getDeviceId];
    XCTAssertNotNil(generatedDeviceId);
    XCTAssertNotEqualObjects(initialDeviceId, generatedDeviceId);
#if TARGET_OS_OSX
    XCTAssertEqual(generatedDeviceId.length, 12);
#else
    XCTAssertEqual(generatedDeviceId.length, 36);
#endif
    XCTAssertEqualObjects([dbHelper getValue:@"device_id"], generatedDeviceId);

    // test setting invalid device ids
    [self.amplitude setDeviceId:nil];
    [self.amplitude flushQueue];
    XCTAssertEqualObjects([self.amplitude getDeviceId], generatedDeviceId);
    XCTAssertEqualObjects([dbHelper getValue:@"device_id"], generatedDeviceId);

    id dict = [NSDictionary dictionary];
    [self.amplitude setDeviceId:dict];
    [self.amplitude flushQueue];
    XCTAssertEqualObjects([self.amplitude getDeviceId], generatedDeviceId);
    XCTAssertEqualObjects([dbHelper getValue:@"device_id"], generatedDeviceId);

    [self.amplitude setDeviceId:@"e3f5536a141811db40efd6400f1d0a4e"];
    [self.amplitude flushQueue];
    XCTAssertEqualObjects([self.amplitude getDeviceId], generatedDeviceId);
    XCTAssertEqualObjects([dbHelper getValue:@"device_id"], generatedDeviceId);

    [self.amplitude setDeviceId:@"04bab7ee75b9a58d39b8dc54e8851084"];
    [self.amplitude flushQueue];
    XCTAssertEqualObjects([self.amplitude getDeviceId], generatedDeviceId);
    XCTAssertEqualObjects([dbHelper getValue:@"device_id"], generatedDeviceId);

    NSString *validDeviceId = [AMPUtils generateUUID];
    [self.amplitude setDeviceId:validDeviceId];
    [self.amplitude flushQueue];
    XCTAssertEqualObjects([self.amplitude getDeviceId], validDeviceId);
    XCTAssertEqualObjects([dbHelper getValue:@"device_id"], validDeviceId);
}

@end
