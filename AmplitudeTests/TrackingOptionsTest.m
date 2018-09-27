//
//  TrackingOptionsTest.m
//  Amplitude
//
//  Created by Daniel Jih on 7/20/18.
//  Copyright © 2018 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMPTrackingOptions.h"
#import "AMPARCMacros.h"
#import "AMPConstants.h"

@interface TrackingOptionsTests : XCTestCase

@end

@implementation TrackingOptionsTests { }

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDisableFields {
    AMPTrackingOptions *options = [[[[AMPTrackingOptions options] disableCity] disableIPAddress] disableLanguage];

    XCTAssertTrue([options shouldTrackCarrier]);
    XCTAssertFalse([options shouldTrackCity]);
    XCTAssertTrue([options shouldTrackCountry]);
    XCTAssertTrue([options shouldTrackDeviceManufacturer]);
    XCTAssertTrue([options shouldTrackDeviceModel]);
    XCTAssertTrue([options shouldTrackDMA]);
    XCTAssertTrue([options shouldTrackIDFA]);
    XCTAssertTrue([options shouldTrackIDFV]);
    XCTAssertFalse([options shouldTrackIPAddress]);
    XCTAssertFalse([options shouldTrackLanguage]);
    XCTAssertTrue([options shouldTrackLatLng]);
    XCTAssertTrue([options shouldTrackOSName]);
    XCTAssertTrue([options shouldTrackOSVersion]);
    XCTAssertTrue([options shouldTrackPlatform]);
    XCTAssertTrue([options shouldTrackRegion]);
    XCTAssertTrue([options shouldTrackVersionName]);
}

- (void)testGetApiPropertiesTrackingOptions {
    AMPTrackingOptions *options = [[[[[[AMPTrackingOptions options] disableCity] disableIPAddress] disableLanguage] disableCountry] disableLatLng];

    NSMutableDictionary *apiPropertiesTrackingOptions = [options getApiPropertiesTrackingOption];
    XCTAssertEqual([apiPropertiesTrackingOptions count], 4);
    XCTAssertEqual([apiPropertiesTrackingOptions objectForKey:@"city"], [NSNumber numberWithBool:NO]);
    XCTAssertEqual([apiPropertiesTrackingOptions objectForKey:@"country"], [NSNumber numberWithBool:NO]);
    XCTAssertEqual([apiPropertiesTrackingOptions objectForKey:@"ip_address"], [NSNumber numberWithBool:NO]);
    XCTAssertEqual([apiPropertiesTrackingOptions objectForKey:@"lat_lng"], [NSNumber numberWithBool:NO]);
}
@end
