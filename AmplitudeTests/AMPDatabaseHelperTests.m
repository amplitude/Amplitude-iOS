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

@implementation AMPDatabaseHelperTests {

}

- (void)setUp {
    [super setUp];
    self.databaseHelper = [AMPDatabaseHelper getDatabaseHelper];
    [self.databaseHelper resetDB];
}

- (void)tearDown {
    [super tearDown];
    self.databaseHelper = nil;
}

- (void)testCreate {
    XCTAssertEqual(1, [self.databaseHelper addEvent:@"test"]);
    XCTAssertEqual(1, [self.databaseHelper insertOrReplaceKeyValue:@"key" value:@"value"]);
}

- (void)testGetEvent {
    [self.databaseHelper addEvent:@"{\"event_type\":\"test1\"}"];
    [self.databaseHelper addEvent:@"{\"event_type\":\"test2\"}"];

    // test get all events
    NSDictionary *results = [self.databaseHelper getEvents:-1 limit:-1];
    XCTAssertEqual(2, [[results objectForKey:@"maxId"] intValue]);
    NSArray *events = [results objectForKey:@"events"];
    XCTAssertEqual(2, events.count);
    XCTAssert([[[events objectAtIndex:0] objectForKey:@"event_type"] isEqualToString:@"test1"]);
    XCTAssertEqual(1, [[[events objectAtIndex:0] objectForKey:@"event_id"] intValue]);
    XCTAssert([[[events objectAtIndex:1] objectForKey:@"event_type"] isEqualToString:@"test2"]);
    XCTAssertEqual(2, [[[events objectAtIndex:1] objectForKey:@"event_id"] intValue]);

    // test get all events up to certain id
    results = [self.databaseHelper getEvents:1 limit:-1];
    XCTAssertEqual(1, [[results objectForKey:@"maxId"] intValue]);
    events = [results objectForKey:@"events"];
    XCTAssertEqual(1, events.count);

    // test get all events with limit
    results = [self.databaseHelper getEvents:1 limit:1];
    XCTAssertEqual(1, [[results objectForKey:@"maxId"] intValue]);
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

- (void)testEventCount {
    XCTAssertEqual(1, [self.databaseHelper addEvent:@"{\"event_type\":\"test1\"}"]);
    XCTAssertEqual(2, [self.databaseHelper addEvent:@"{\"event_type\":\"test2\"}"]);
    XCTAssertEqual(3, [self.databaseHelper addEvent:@"{\"event_type\":\"test3\"}"]);
    XCTAssertEqual(4, [self.databaseHelper addEvent:@"{\"event_type\":\"test4\"}"]);
    XCTAssertEqual(5, [self.databaseHelper addEvent:@"{\"event_type\":\"test5\"}"]);

    XCTAssertEqual(5, [self.databaseHelper getEventCount]);

    [self.databaseHelper removeEvent:1];
    XCTAssertEqual(4, [self.databaseHelper getEventCount]);

    [self.databaseHelper removeEvents:3];
    XCTAssertEqual(2, [self.databaseHelper getEventCount]);

    [self.databaseHelper removeEvents:10];
    XCTAssertEqual(0, [self.databaseHelper getEventCount]);
}

- (void)testGetNthEventId {
    XCTAssertEqual(1, [self.databaseHelper addEvent:@"{\"event_type\":\"test1\"}"]);
    XCTAssertEqual(2, [self.databaseHelper addEvent:@"{\"event_type\":\"test2\"}"]);
    XCTAssertEqual(3, [self.databaseHelper addEvent:@"{\"event_type\":\"test3\"}"]);
    XCTAssertEqual(4, [self.databaseHelper addEvent:@"{\"event_type\":\"test4\"}"]);
    XCTAssertEqual(5, [self.databaseHelper addEvent:@"{\"event_type\":\"test5\"}"]);

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