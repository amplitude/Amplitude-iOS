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
    XCTAssertFalse([options shouldTrackDeviceManufacturer]);
    XCTAssertTrue([options shouldTrackDeviceModel]);
    XCTAssertTrue([options shouldTrackDMA]);
    XCTAssertTrue([options shouldTrackIDFA]);
    XCTAssertTrue([options shouldTrackIDFV]);
    XCTAssertFalse([options shouldTrackIPAddress]);
    XCTAssertFalse([options shouldTrackLanguage]);
    XCTAssertTrue([options shouldTrackLatLon]);
    XCTAssertTrue([options shouldTrackOSName]);
    XCTAssertTrue([options shouldTrackOSVersion]);
    XCTAssertTrue([options shouldTrackPlatform]);
    XCTAssertTrue([options shouldTrackRegion]);
    XCTAssertTrue([options shouldTrackVersionName]);

}

//- (void)testAddProperty {
//    NSString *property1 = @"int value";
//    NSNumber *value1 = [NSNumber numberWithInt:5];
//
//    NSString *property2 = @"double value";
//    NSNumber *value2 = [NSNumber numberWithDouble:0.123];
//
//    NSString *property3 = @"float value";
//    NSNumber *value3 = [NSNumber numberWithFloat:0.625];
//
//    NSString *property4 = @"long value";
//    NSNumber *value4 = [NSNumber numberWithLong:18];
//
//    NSString *property5 = @"NSDecimal number value";
//    NSDecimalNumber *value5 = [NSDecimalNumber decimalNumberWithString:@"1.234"];
//
//    NSString *property6 = @"string value";
//    NSString *value6 = @"10";
//
//    // add should ignore nonnumbers and nonstrings
//    NSString *property7 = @"array value";
//    NSArray *value7 = [NSArray array];
//
//    AMPIdentify *identify = [[AMPIdentify identify] add:property1 value:value1];
//    [[[identify add:property2 value:value2] add:property3 value:value3] add:property4 value:value4];
//    [[[identify add:property5 value:value5] add:property6 value:value6] add:property7 value:value7];
//
//    // identify should ignore this since duplicate key
//    [identify add:property1 value:value3];
//
//    // generate expected operations
//    NSMutableDictionary *operations = [NSMutableDictionary dictionary];
//    [operations setObject:value1 forKey:property1];
//    [operations setObject:value2 forKey:property2];
//    [operations setObject:value3 forKey:property3];
//    [operations setObject:value4 forKey:property4];
//    [operations setObject:value5 forKey:property5];
//    [operations setObject:value6 forKey:property6];
//
//    NSMutableDictionary *expected = [NSMutableDictionary dictionary];
//    [expected setObject:operations forKey:AMP_OP_ADD];
//
//    XCTAssertEqualObjects(identify.userPropertyOperations, expected);
//}

@end
