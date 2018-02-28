//
//  DeviceInfoTests.m
//  DeviceInfoTests
//
//  Created by Allan on 4/21/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <OCMock/OCMock.h>
#import "AMPConstants.h"
#import "AMPDeviceInfo.h"
#import "AMPARCMacros.h"

// expose private methods for unit testing
@interface AMPDeviceInfo (Tests)
+(NSString*)getAdvertiserID:(int) maxAttempts;
@end

@interface DeviceInfoTests : XCTestCase

@end

@implementation DeviceInfoTests {
    AMPDeviceInfo *_deviceInfo;
}

- (void)setUp {
    [super setUp];
    _deviceInfo = [[AMPDeviceInfo alloc] init];
}

- (void)tearDown {
    SAFE_ARC_RELEASE(_deviceInfo);
    [super tearDown];
}

- (void) testAppVersion {
    id mockBundle = [OCMockObject niceMockForClass:[NSBundle class]];
    [[[mockBundle stub] andReturn:mockBundle] mainBundle];
    NSDictionary *mockDictionary = @{
        @"CFBundleShortVersionString": kAMPVersion
    };
    OCMStub([mockBundle infoDictionary]).andReturn(mockDictionary);
    
    XCTAssertEqualObjects(kAMPVersion, _deviceInfo.appVersion);
    [mockBundle stopMocking];
}

- (void) testOsName {
    XCTAssertEqualObjects(@"ios", _deviceInfo.osName);
}

- (void) testOsVersion {
    XCTAssertEqualObjects([[UIDevice currentDevice] systemVersion], _deviceInfo.osVersion);
}

- (void) testManufacturer {
    XCTAssertEqualObjects(@"Apple", _deviceInfo.manufacturer);
}

- (void) testModel {
    XCTAssertEqualObjects(@"Simulator", _deviceInfo.model);
}

- (void) testCarrier {
    // TODO: Not sure how to test this on the simulator
//    XCTAssertEqualObjects(nil, _deviceInfo.carrier);
}

- (void) testCountry {
    XCTAssertEqualObjects(@"United States", _deviceInfo.country);
}

- (void) testLanguage {
    XCTAssertEqualObjects(@"English", _deviceInfo.language);
}

- (void) testAdvertiserID {
    id mockDeviceInfo = OCMClassMock([AMPDeviceInfo class]);
    [[mockDeviceInfo expect] getAdvertiserID:5];
    XCTAssertEqualObjects(nil, _deviceInfo.advertiserID);
    [mockDeviceInfo verify];
    [mockDeviceInfo stopMocking];
}

- (void) testDisableIDFATracking {
    id mockDeviceInfo = OCMClassMock([AMPDeviceInfo class]);
    [[mockDeviceInfo reject] getAdvertiserID:5];
    AMPDeviceInfo *newDeviceInfo = [[AMPDeviceInfo alloc] init:YES];
    XCTAssertEqualObjects(nil, newDeviceInfo.advertiserID);
    [mockDeviceInfo verify];
    [mockDeviceInfo stopMocking];
}

- (void) testVendorID {
    XCTAssertEqualObjects(_deviceInfo.vendorID, [[[UIDevice currentDevice] identifierForVendor] UUIDString]);
}


- (void) testGenerateUUID {
    NSString *a = [AMPDeviceInfo generateUUID];
    NSString *b = [AMPDeviceInfo generateUUID];
    XCTAssertNotNil(a);
    XCTAssertNotNil(b);
    XCTAssertNotEqual(a, b);
    XCTAssertNotEqual(a, b);
}

@end
