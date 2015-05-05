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
#import "Amplitude.h"
#import "AMPConstants.h"
#import "Amplitude+Test.h"
#import "BaseTestCase.h"
#import "AMPDeviceInfo.h"

@interface DeviceInfoTests : BaseTestCase

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
    _deviceInfo = nil;
}

- (void) testAppVersion {
    id mockBundle = [OCMockObject niceMockForClass:[NSBundle class]];
    [[[mockBundle stub] andReturn:mockBundle] mainBundle];
    OCMStub([mockBundle infoDictionary]).andReturn(@{
        @"CFBundleShortVersionString": kAMPVersion
    });
    
    XCTAssertEqualObjects(kAMPVersion, _deviceInfo.appVersion);
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
    XCTAssertEqualObjects(@"Unknown", _deviceInfo.carrier);
}

- (void) testCountry {
    XCTAssertEqualObjects(@"United States", _deviceInfo.country);
}

- (void) testLanguage {
    XCTAssertEqualObjects(@"English", _deviceInfo.language);
}

- (void) testAdvertiserID {
    // TODO: Not sure how to test this on the simulator
    XCTAssertEqualObjects(nil, _deviceInfo.advertiserID);
}

- (void) testVendorID {
    XCTAssertEqualObjects(@"C6CAF400-5B8C-41CF-8E3D-FF744EE0308A", _deviceInfo.vendorID);
}


- (void) testGenerateUUID {
    NSString *a = [_deviceInfo generateUUID];
    NSString *b = [_deviceInfo generateUUID];
    XCTAssertNotNil(a);
    XCTAssertNotNil(b);
    XCTAssertNotEqual(a, b);
    XCTAssertNotEqual(a, b);
}

@end
