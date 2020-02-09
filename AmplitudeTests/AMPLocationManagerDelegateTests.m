//
//  AMPLocationManagerDelegateTests.m
//  AMPLocationManagerDelegateTests
//
//  Created by Curtis on 1/3/2015.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>

#if !TARGET_OS_OSX
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "AMPLocationManagerDelegate.h"

@interface AMPLocationManagerDelegateTests : XCTestCase

@end

@implementation AMPLocationManagerDelegateTests

AMPLocationManagerDelegate *locationManagerDelegate;
CLLocationManager *locationManager;

- (void)setUp {
    [super setUp];
    locationManager = [[CLLocationManager alloc] init];
    locationManagerDelegate = [[AMPLocationManagerDelegate alloc] init];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDidFailWithError {
    [locationManagerDelegate locationManager:locationManager didFailWithError:nil];
    
}

- (void)testDidUpdateToLocation {
    [locationManagerDelegate locationManager:locationManager didUpdateToLocation:nil fromLocation:nil];
    
}

- (void)testDidChangeAuthorizationStatus {
    [locationManagerDelegate locationManager:locationManager
                didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorized];
    [locationManagerDelegate locationManager:locationManager
                didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorizedAlways];
    [locationManagerDelegate locationManager:locationManager
                didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse];
#if !TARGET_OS_OSX
    [locationManagerDelegate locationManager:locationManager
                didChangeAuthorizationStatus:kCLAuthorizationStatusAuthorizedWhenInUse];
#endif
}
@end
