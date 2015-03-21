//
//  InitializeTests.m
//  InitializeTests
//
//  Created by Curtis on 9/24/14.
//  Copyright (c) 2014 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <OCMock/OCMock.h>
#import "Amplitude.h"


@interface InitializeTests : XCTestCase

@end

@interface Amplitude (Test)

@property NSOperationQueue *backgroundQueue;
@property NSMutableDictionary *eventsData;
@property BOOL initialized;

- (void)flushQueue;
- (NSDictionary *)getLastEvent;

@end

@implementation Amplitude (Test)

@dynamic backgroundQueue;
@dynamic eventsData;
@dynamic initialized;

- (void)flushQueue {
    [[self backgroundQueue] waitUntilAllOperationsAreFinished];
}

- (NSDictionary *)getLastEvent {
    return [[self eventsData][@"events"] lastObject];
}

@end

@implementation InitializeTests

Amplitude *amplitude;

NSString *const apiKey = @"000000";
NSString *const userId = @"userId";

id archivedObj;
id partialMock;

- (BOOL) archive:(id)rootObject toFile:(NSString *)path {
    archivedObj = rootObject;
    return TRUE;
}

- (id) unarchive:(NSString *)path {
    return archivedObj;
}

- (void)setUp {
    [super setUp];
    amplitude = [Amplitude alloc];
    // Mock the methods before init
    partialMock = OCMPartialMock(amplitude);
    OCMStub([partialMock archive:[OCMArg any] toFile:[OCMArg any]]).andCall(self, @selector(archive:toFile:));
    OCMStub([partialMock unarchive:[OCMArg any]]).andCall(self, @selector(unarchive:));
    [amplitude init];
}

- (void)tearDown {
    // Ensure all background operations are done
    [amplitude flushQueue];
    [super tearDown];
}

- (void)testApiKeySet {
    [amplitude initializeApiKey:apiKey];
    XCTAssertEqual(amplitude.apiKey, apiKey);
}

- (void)testDeviceIdSet {
    [amplitude initializeApiKey:apiKey];
    [amplitude flushQueue];
    XCTAssertNotNil([amplitude deviceId]);
    XCTAssertEqual([amplitude deviceId].length, 36);
    XCTAssertEqualObjects([amplitude deviceId], [[[UIDevice currentDevice] identifierForVendor] UUIDString]);
}

- (void)testUserIdNotSet {
    [amplitude initializeApiKey:apiKey];
    [amplitude flushQueue];
    XCTAssertNil([amplitude userId]);
}

- (void)testUserIdSet {
    [amplitude initializeApiKey:apiKey userId:userId];
    [amplitude flushQueue];
    XCTAssertEqualObjects([amplitude userId], userId);
}

- (void)testInitializedSet {
    [amplitude initializeApiKey:apiKey];
    XCTAssert([amplitude initialized]);
}

- (void)testOptOut {
    [amplitude initializeApiKey:apiKey];

    [amplitude setOptOut:YES];
    [amplitude logEvent:@"Opted Out"];
    [amplitude flushQueue];

    XCTAssert(amplitude.optOut == YES);
    XCTAssert(![[amplitude getLastEvent][@"event_type"] isEqualToString:@"Opted Out"]);

    [amplitude setOptOut:NO];
    [amplitude logEvent:@"Opted In"];
    [amplitude flushQueue];

    XCTAssert(amplitude.optOut == NO);
    XCTAssert([[amplitude getLastEvent][@"event_type"] isEqualToString:@"Opted In"]);
}

- (void)testUserPropertiesSet {
    [amplitude initializeApiKey:apiKey];

    NSDictionary *properties = @{
         @"shoeSize": @10,
         @"hatSize":  @5.125,
         @"name": @"John"
    };

    [amplitude setUserProperties:@{@"property": @"true"} replace:YES];
    [amplitude setUserProperties:properties replace:YES];

    [amplitude logEvent:@"Test Event"];
    [amplitude flushQueue];

    NSDictionary *event = [amplitude getLastEvent];
    XCTAssert([event[@"user_properties"] isEqualToDictionary:properties]);
}

- (void)testUserPropertiesMerge {
    [amplitude initializeApiKey:apiKey];

    NSMutableDictionary *properties = [@{
         @"shoeSize": @10,
         @"hatSize":  @5.125,
         @"name": @"John"
    } mutableCopy];

    [amplitude setUserProperties:properties];

    [amplitude logEvent:@"Test Event"];
    [amplitude flushQueue];

    NSDictionary *event = [amplitude getLastEvent];
    XCTAssert([event[@"user_properties"] isEqualToDictionary:properties]);

    NSDictionary *extraProperties = @{@"mergedProperty": @"merged"};
    [amplitude setUserProperties:extraProperties replace:NO];

    [amplitude logEvent:@"Test Event"];
    [amplitude flushQueue];

    event = [amplitude getLastEvent];
    [properties addEntriesFromDictionary:extraProperties];
    XCTAssert([event[@"user_properties"] isEqualToDictionary:properties]);
}

@end
