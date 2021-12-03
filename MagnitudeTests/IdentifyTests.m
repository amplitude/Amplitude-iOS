//
//  IdentifyTests.m
//  Amplitude
//
//  Created by Daniel Jih on 10/5/15.
//  Copyright © 2015 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMPIdentify.h"
#import "AMPARCMacros.h"
#import "AMPConstants.h"

@interface IdentifyTests : XCTestCase

@end

@implementation IdentifyTests { }

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testAddProperty {
    NSString *property1 = @"int value";
    NSNumber *value1 = [NSNumber numberWithInt:5];

    NSString *property2 = @"double value";
    NSNumber *value2 = [NSNumber numberWithDouble:0.123];

    NSString *property3 = @"float value";
    NSNumber *value3 = [NSNumber numberWithFloat:0.625];

    NSString *property4 = @"long value";
    NSNumber *value4 = [NSNumber numberWithLong:18];

    NSString *property5 = @"NSDecimal number value";
    NSDecimalNumber *value5 = [NSDecimalNumber decimalNumberWithString:@"1.234"];

    NSString *property6 = @"string value";
    NSString *value6 = @"10";

    // add should ignore nonnumbers and nonstrings
    NSString *property7 = @"array value";
    NSArray *value7 = [NSArray array];

    AMPIdentify *identify = [[AMPIdentify identify] add:property1 value:value1];
    [[[identify add:property2 value:value2] add:property3 value:value3] add:property4 value:value4];
    [[[identify add:property5 value:value5] add:property6 value:value6] add:property7 value:value7];

    // identify should ignore this since duplicate key
    [identify add:property1 value:value3];

    // generate expected operations
    NSMutableDictionary *operations = [NSMutableDictionary dictionary];
    [operations setObject:value1 forKey:property1];
    [operations setObject:value2 forKey:property2];
    [operations setObject:value3 forKey:property3];
    [operations setObject:value4 forKey:property4];
    [operations setObject:value5 forKey:property5];
    [operations setObject:value6 forKey:property6];

    NSMutableDictionary *expected = [NSMutableDictionary dictionary];
    [expected setObject:operations forKey:AMP_OP_ADD];

    XCTAssertEqualObjects(identify.userPropertyOperations, expected);
}

- (void)testSetProperty {
    NSString *property1 = @"string value";
    NSString *value1 = @"test value";

    NSString *property2 = @"double value";
    NSNumber *value2 = [NSNumber numberWithDouble:0.123];

    NSString *property3 = @"boolean value";
    NSNumber *value3 = [NSNumber numberWithBool:YES];

    NSString *property4 = @"array value";
    NSArray *value4 = [NSArray array];

    AMPIdentify *identify = [[AMPIdentify identify] set:property1 value:value1];
    [[[identify set:property2 value:value2] set:property3 value:value3] set:property4 value:value4];

    // identify should ignore this since duplicate key
    [identify set:property1 value:value3];

    // generate expected operations
    NSMutableDictionary *operations = [NSMutableDictionary dictionary];
    [operations setObject:value1 forKey:property1];
    [operations setObject:value2 forKey:property2];
    [operations setObject:value3 forKey:property3];
    [operations setObject:value4 forKey:property4];

    NSMutableDictionary *expected = [NSMutableDictionary dictionary];
    [expected setObject:operations forKey:AMP_OP_SET];

    XCTAssertEqualObjects(identify.userPropertyOperations, expected);
}

- (void)testSetOnceProperty {
    NSString *property1 = @"string value";
    NSString *value1 = @"test value";

    NSString *property2 = @"double value";
    NSNumber *value2 = [NSNumber numberWithDouble:0.123];

    NSString *property3 = @"boolean value";
    NSNumber *value3 = [NSNumber numberWithBool:YES];

    NSString *property4 = @"array value";
    NSArray *value4 = [NSArray array];

    AMPIdentify *identify = [[AMPIdentify identify] setOnce:property1 value:value1];
    [[[identify setOnce:property2 value:value2] setOnce:property3 value:value3] setOnce:property4 value:value4];

    // identify should ignore this since duplicate key
    [identify setOnce:property1 value:value3];

    // generate expected operations
    NSMutableDictionary *operations = [NSMutableDictionary dictionary];
    [operations setObject:value1 forKey:property1];
    [operations setObject:value2 forKey:property2];
    [operations setObject:value3 forKey:property3];
    [operations setObject:value4 forKey:property4];

    NSMutableDictionary *expected = [NSMutableDictionary dictionary];
    [expected setObject:operations forKey:AMP_OP_SET_ONCE];

    XCTAssertEqualObjects(identify.userPropertyOperations, expected);
}

- (void)testAppendProperty {
    NSString *property1 = @"string value";
    NSString *value1 = @"test value";

    NSString *property2 = @"double value";
    NSNumber *value2 = [NSNumber numberWithDouble:0.123];

    NSString *property3 = @"boolean value";
    NSNumber *value3 = [NSNumber numberWithBool:YES];

    NSString *property4 = @"array value";
    NSMutableArray *value4 = [NSMutableArray array];
    [value4 addObject:@"test"];
    [value4 addObject:[NSNumber numberWithInt:15]];

    AMPIdentify *identify = [[AMPIdentify identify] append:property1 value:value1];
    [[[identify append:property2 value:value2] append:property3 value:value3] append:property4 value:value4];

    // identify should ignore this since duplicate key
    [identify setOnce:property1 value:value3];

    // generate expected operations
    NSMutableDictionary *operations = [NSMutableDictionary dictionary];
    [operations setObject:value1 forKey:property1];
    [operations setObject:value2 forKey:property2];
    [operations setObject:value3 forKey:property3];
    [operations setObject:value4 forKey:property4];

    NSMutableDictionary *expected = [NSMutableDictionary dictionary];
    [expected setObject:operations forKey:AMP_OP_APPEND];

    XCTAssertEqualObjects(identify.userPropertyOperations, expected);
}

- (void)testPrependProperty {
    NSString *property1 = @"string value";
    NSString *value1 = @"test value";

    NSString *property2 = @"double value";
    NSNumber *value2 = [NSNumber numberWithDouble:0.123];

    NSString *property3 = @"boolean value";
    NSNumber *value3 = [NSNumber numberWithBool:YES];

    NSString *property4 = @"array value";
    NSMutableArray *value4 = [NSMutableArray array];
    [value4 addObject:@"test"];
    [value4 addObject:[NSNumber numberWithInt:15]];

    AMPIdentify *identify = [[AMPIdentify identify] prepend:property1 value:value1];
    [[[identify prepend:property2 value:value2] prepend:property3 value:value3] prepend:property4 value:value4];

    // identify should ignore this since duplicate key
    [identify setOnce:property1 value:value3];

    // generate expected operations
    NSMutableDictionary *operations = [NSMutableDictionary dictionary];
    [operations setObject:value1 forKey:property1];
    [operations setObject:value2 forKey:property2];
    [operations setObject:value3 forKey:property3];
    [operations setObject:value4 forKey:property4];

    NSMutableDictionary *expected = [NSMutableDictionary dictionary];
    [expected setObject:operations forKey:AMP_OP_PREPEND];

    XCTAssertEqualObjects(identify.userPropertyOperations, expected);
}

- (void)testUnsetProperty {
    NSString *property1 = @"testProperty1";
    NSString *property2 = @"testProperty2";

    AMPIdentify *identify = [AMPIdentify identify];
    [[identify unset:property1] unset:property2];

    NSMutableDictionary *operations = [NSMutableDictionary dictionary];
    [operations setObject:@"-" forKey:property1];
    [operations setObject:@"-" forKey:property2];

    NSMutableDictionary *expected = [NSMutableDictionary dictionary];
    [expected setObject:operations forKey:AMP_OP_UNSET];

    XCTAssertEqualObjects(identify.userPropertyOperations, expected);
}

- (void)testMultipleOperations {
    NSString *property1 = @"string value";
    NSString *value1 = @"test value";

    NSString *property2 = @"double value";
    NSNumber *value2 = [NSNumber numberWithDouble:0.123];

    NSString *property3 = @"boolean value";
    NSNumber *value3 = [NSNumber numberWithBool:YES];

    NSString *property4 = @"array value";

    NSString *property5 = @"list value";
    NSMutableArray *value5 = [NSMutableArray array];
    [value5 addObject:@"test"];
    [value5 addObject:[NSNumber numberWithFloat:14.23456]];

    AMPIdentify *identify = [[AMPIdentify identify] setOnce:property1 value:value1];
    [[[[identify add:property2 value:value2] set:property3 value:value3] unset:property4] append:property5 value:value5];

    // identify should ignore this since duplicate key
    [identify set:property4 value:value3];

    // generate expected operations
    NSDictionary *setOnce = [NSDictionary dictionaryWithObject:value1 forKey:property1];
    NSDictionary *add = [NSDictionary dictionaryWithObject:value2 forKey:property2];
    NSDictionary *set = [NSDictionary dictionaryWithObject:value3 forKey:property3];
    NSDictionary *unset = [NSDictionary dictionaryWithObject:@"-" forKey:property4];
    NSDictionary *append = [NSDictionary dictionaryWithObject:value5 forKey:property5];

    NSDictionary *expected = [NSDictionary dictionaryWithObjectsAndKeys:setOnce, AMP_OP_SET_ONCE, add, AMP_OP_ADD, set, AMP_OP_SET, unset, AMP_OP_UNSET, append, AMP_OP_APPEND, nil];

    XCTAssertEqualObjects(identify.userPropertyOperations, expected);
}

- (void)testDisallowDuplicateProperties {
    NSString *property = @"testProperty";
    NSString *value1 = @"testValue";
    NSNumber *value2 = [NSNumber numberWithDouble:0.123];
    NSNumber *value3 = [NSNumber numberWithBool:YES];

    AMPIdentify *identify = [AMPIdentify identify];
    [[[[identify setOnce:property value:value1] add:property value:value2] set:property value:value3] unset:property];

    NSMutableDictionary *operations = [NSMutableDictionary dictionary];
    [operations setObject:value1 forKey:property];

    NSMutableDictionary *expected = [NSMutableDictionary dictionary];
    [expected setObject:operations forKey:AMP_OP_SET_ONCE];

    XCTAssertEqualObjects(identify.userPropertyOperations, expected);
}

- (void)testMakeJSONSerializableProperty {
    NSString *urlString = @"https://amplitude.com";
    NSString *key = @"url";
    NSURL *url = [NSURL URLWithString:urlString];

    AMPIdentify *identify = [AMPIdentify identify];
    [identify set:key value:url]; // should coerce NSURL object into a string

    NSMutableDictionary *operations = [NSMutableDictionary dictionary];
    [operations setObject:urlString forKey:key];

    NSMutableDictionary *expected = [NSMutableDictionary dictionary];
    [expected setObject:operations forKey:AMP_OP_SET];

    XCTAssertEqualObjects(identify.userPropertyOperations, expected);
}

- (void)testDisallowOtherOperationsOnClearAllIdentify {
    NSString *property = @"testProperty";
    NSString *value1 = @"testValue";
    NSNumber *value2 = [NSNumber numberWithDouble:0.123];
    NSNumber *value3 = [NSNumber numberWithBool:YES];

    AMPIdentify *identify = [[AMPIdentify identify] clearAll];
    [[[[identify setOnce:property value:value1] add:property value:value2] set:property value:value3] unset:property];

    NSMutableDictionary *expected = [NSMutableDictionary dictionary];
    [expected setObject:@"-" forKey:AMP_OP_CLEAR_ALL];

    XCTAssertEqualObjects(identify.userPropertyOperations, expected);
}

- (void)testDisallowClearAllOnIdentifysWithOtherOperations {
    NSString *property = @"testProperty";
    NSString *value1 = @"testValue";
    NSNumber *value2 = [NSNumber numberWithDouble:0.123];
    NSNumber *value3 = [NSNumber numberWithBool:YES];

    AMPIdentify *identify = [AMPIdentify identify];
    [[[[identify setOnce:property value:value1] add:property value:value2] set:property value:value3] unset:property];
    [identify clearAll];

    NSMutableDictionary *operations = [NSMutableDictionary dictionary];
    [operations setObject:value1 forKey:property];

    NSMutableDictionary *expected = [NSMutableDictionary dictionary];
    [expected setObject:operations forKey:AMP_OP_SET_ONCE];

    XCTAssertEqualObjects(identify.userPropertyOperations, expected);
}

@end
