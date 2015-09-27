//
//  AMPDatabaseHelperTests.m
//  Amplitude
//
//  Created by Daniel Jih on 9/9/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMPDatabaseHelper.h"
#import "AMPDatabaseHelperTests.h"
#import "AMPARCMacros.h"

@implementation AMPDatabaseHelperTests {

}

- (void)setUp {
    [super setUp];
    self.databaseHelper = [AMPDatabaseHelper getDatabaseHelper];
    [self.databaseHelper resetDB];
}

- (void)tearDown {
    [super tearDown];
    [self.databaseHelper delete];
    self.databaseHelper = nil;
}

- (void)testCreate {
    XCTAssertTrue([self.databaseHelper addEvent:@"test"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyValue:@"key" value:@"value"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyLongValue:@"key" value:[NSNumber numberWithLongLong:0LL]]);
}

- (void)testGetEvents {
    NSDictionary *emptyResults = [self.databaseHelper getEvents:-1 limit:-1];
    XCTAssertEqual(-1, [[emptyResults objectForKey:@"maxId"] longValue]);

    [self.databaseHelper addEvent:@"{\"event_type\":\"test1\"}"];
    [self.databaseHelper addEvent:@"{\"event_type\":\"test2\"}"];

    // test get all events
    NSDictionary *results = [self.databaseHelper getEvents:-1 limit:-1];
    XCTAssertEqual(2, [[results objectForKey:@"maxId"] longValue]);
    NSArray *events = [results objectForKey:@"events"];
    XCTAssertEqual(2, events.count);
    XCTAssert([[[events objectAtIndex:0] objectForKey:@"event_type"] isEqualToString:@"test1"]);
    XCTAssertEqual(1, [[[events objectAtIndex:0] objectForKey:@"event_id"] longValue]);
    XCTAssert([[[events objectAtIndex:1] objectForKey:@"event_type"] isEqualToString:@"test2"]);
    XCTAssertEqual(2, [[[events objectAtIndex:1] objectForKey:@"event_id"] longValue]);

    // test get all events up to certain id
    results = [self.databaseHelper getEvents:1 limit:-1];
    XCTAssertEqual(1, [[results objectForKey:@"maxId"] longValue]);
    events = [results objectForKey:@"events"];
    XCTAssertEqual(1, events.count);

    // test get all events with limit
    results = [self.databaseHelper getEvents:1 limit:1];
    XCTAssertEqual(1, [[results objectForKey:@"maxId"] longValue]);
    events = [results objectForKey:@"events"];
    XCTAssertEqual(1, events.count);
}

- (void)testInsertAndReplaceKeyValue {
    NSString *key = @"test_key";
    NSString *value1 = @"test_value1";
    NSString *value2 = @"test_value2";
    XCTAssertNil([self.databaseHelper getValue:key]);

    [self.databaseHelper insertOrReplaceKeyValue:key value:value1];
    XCTAssert([[self.databaseHelper getValue:key] isEqualToString:value1]);

    [self.databaseHelper insertOrReplaceKeyValue:key value:value2];
    XCTAssert([[self.databaseHelper getValue:key] isEqualToString:value2]);
}

- (void)testInsertAndReplaceKeyLongValue {
    NSString *key = @"test_key";
    NSNumber *value1 = [NSNumber numberWithLongLong:1LL];
    NSNumber *value2 = [NSNumber numberWithLongLong:2LL];
    XCTAssertNil([self.databaseHelper getLongValue:key]);

    [self.databaseHelper insertOrReplaceKeyLongValue:key value:value1];
    XCTAssert([[self.databaseHelper getLongValue:key] isEqualToNumber:value1]);

    [self.databaseHelper insertOrReplaceKeyLongValue:key value:value2];
    XCTAssert([[self.databaseHelper getLongValue:key] isEqualToNumber:value2]);
}

- (void)testEventCount {
    XCTAssertTrue([self.databaseHelper addEvent:@"{\"event_type\":\"test1\"}"]);
    XCTAssertTrue([self.databaseHelper addEvent:@"{\"event_type\":\"test2\"}"]);
    XCTAssertTrue([self.databaseHelper addEvent:@"{\"event_type\":\"test3\"}"]);
    XCTAssertTrue([self.databaseHelper addEvent:@"{\"event_type\":\"test4\"}"]);
    XCTAssertTrue([self.databaseHelper addEvent:@"{\"event_type\":\"test5\"}"]);

    XCTAssertEqual(5, [self.databaseHelper getEventCount]);

    [self.databaseHelper removeEvent:1];
    XCTAssertEqual(4, [self.databaseHelper getEventCount]);

    [self.databaseHelper removeEvents:3];
    XCTAssertEqual(2, [self.databaseHelper getEventCount]);

    [self.databaseHelper removeEvents:10];
    XCTAssertEqual(0, [self.databaseHelper getEventCount]);
}

- (void)testGetNthEventId {
    XCTAssertTrue([self.databaseHelper addEvent:@"{\"event_type\":\"test1\"}"]);
    XCTAssertTrue([self.databaseHelper addEvent:@"{\"event_type\":\"test2\"}"]);
    XCTAssertTrue([self.databaseHelper addEvent:@"{\"event_type\":\"test3\"}"]);
    XCTAssertTrue([self.databaseHelper addEvent:@"{\"event_type\":\"test4\"}"]);
    XCTAssertTrue([self.databaseHelper addEvent:@"{\"event_type\":\"test5\"}"]);

    XCTAssertEqual(1, [self.databaseHelper getNthEventId:0]);
    XCTAssertEqual(1, [self.databaseHelper getNthEventId:1]);
    XCTAssertEqual(2, [self.databaseHelper getNthEventId:2]);
    XCTAssertEqual(3, [self.databaseHelper getNthEventId:3]);
    XCTAssertEqual(4, [self.databaseHelper getNthEventId:4]);
    XCTAssertEqual(5, [self.databaseHelper getNthEventId:5]);

    [self.databaseHelper removeEvent:1];
    XCTAssertEqual(2, [self.databaseHelper getNthEventId:1]);

    [self.databaseHelper removeEvents:3];
    XCTAssertEqual(4, [self.databaseHelper getNthEventId:1]);

    [self.databaseHelper removeEvents:10];
    XCTAssertEqual(-1, [self.databaseHelper getNthEventId:1]);
}

@end