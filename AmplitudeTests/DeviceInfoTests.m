//
//  DeviceInfoTests.m
//  DeviceInfoTests
//
//  Created by Allan on 4/21/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#if TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif
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
#if TARGET_OS_OSX
    XCTAssertEqualObjects(@"macOS", _deviceInfo.osName);
#else
    XCTAssertEqualObjects(@"ios", _deviceInfo.osName);
#endif
}

- (void) testOsVersion {
#if TARGET_OS_OSX
    XCTAssertEqualObjects([[NSProcessInfo processInfo] operatingSystemVersionString], _deviceInfo.osVersion);
#else
    XCTAssertEqualObjects([[UIDevice currentDevice] systemVersion], _deviceInfo.osVersion);
#endif
}

- (void) testManufacturer {
    XCTAssertEqualObjects(@"Apple", _deviceInfo.manufacturer);
}

- (void) testModel {
#if TARGET_OS_OSX
    XCTAssertTrue([_deviceInfo.model containsString:@"Mac"]);
#else
    XCTAssertEqualObjects(@"Simulator", _deviceInfo.model);
#endif
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

#if TARGET_OS_IPHONE
- (void) testVendorID {
    XCTAssertEqualObjects(_deviceInfo.vendorID, [[[UIDevice currentDevice] identifierForVendor] UUIDString]);
}
#endif


- (void) testGenerateUUID {
    NSString *a = [AMPDeviceInfo generateUUID];
    NSString *b = [AMPDeviceInfo generateUUID];
    XCTAssertNotNil(a);
    XCTAssertNotNil(b);
    XCTAssertNotEqual(a, b);
    XCTAssertNotEqual(a, b);
}

@end
