//
//  DeviceInfoTests.m
//  DeviceInfoTests
//
//  Created by Allan on 4/21/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#if !TARGET_OS_OSX
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "AMPConstants.h"
#import "AMPDeviceInfo.h"

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
    [super tearDown];
}

- (void)testAppVersion {
    id mockBundle = [OCMockObject niceMockForClass:[NSBundle class]];
    [[[mockBundle stub] andReturn:mockBundle] mainBundle];
    NSDictionary *mockDictionary = @{
        @"CFBundleShortVersionString": kAMPVersion
    };
    OCMStub([mockBundle infoDictionary]).andReturn(mockDictionary);
    
    XCTAssertEqualObjects(kAMPVersion, _deviceInfo.appVersion);
    [mockBundle stopMocking];
}

- (void)testOsName {
#if TARGET_OS_MACCATALYST || TARGET_OS_OSX
    XCTAssertEqualObjects(@"macos", _deviceInfo.osName);
#elif TARGET_OS_IOS
    XCTAssertEqualObjects(@"ios", _deviceInfo.osName);
#elif TARGET_OS_TV
    XCTAssertEqualObjects(@"tvos", _deviceInfo.osName);
#endif
}

- (void)testOsVersion {
#if !TARGET_OS_OSX
    XCTAssertEqualObjects([[UIDevice currentDevice] systemVersion], _deviceInfo.osVersion);
#else
    XCTAssertTrue([[[NSProcessInfo processInfo] operatingSystemVersionString] containsString: _deviceInfo.osVersion]);
#endif
}

- (void)testManufacturer {
    XCTAssertEqualObjects(@"Apple", _deviceInfo.manufacturer);
}

- (void)testModel {
#if TARGET_OS_OSX && TARGET_CPU_X86_64
    XCTAssertTrue([_deviceInfo.model containsString:@"Mac"]);
#elif TARGET_CPU_ARM64
    XCTAssertTrue([_deviceInfo.model containsString:@"arm64"]);
#else
    XCTAssertEqualObjects(@"Simulator", _deviceInfo.model);
#endif
}

- (void)testCountry {
    XCTAssertEqualObjects(@"United States", _deviceInfo.country);
}

- (void)testLanguage {
    XCTAssertEqualObjects(@"English", _deviceInfo.language);
}


#if TARGET_OS_IPHONE
- (void)testVendorID {
    XCTAssertEqualObjects(_deviceInfo.vendorID, [[[UIDevice currentDevice] identifierForVendor] UUIDString]);
}
#endif

- (void)testGenerateUUID {
    NSString *a = [AMPDeviceInfo generateUUID];
    NSString *b = [AMPDeviceInfo generateUUID];
    XCTAssertNotNil(a);
    XCTAssertNotNil(b);
    XCTAssertNotEqual(a, b);
    XCTAssertNotEqual(a, b);
}

- (void)testCarrier {
    XCTAssertEqualObjects(_deviceInfo.carrier, @"Unknown");
}

@end
