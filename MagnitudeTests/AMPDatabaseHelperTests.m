//
//  AMPDatabaseHelperTests.m
//  Amplitude
//
//  Created by Daniel Jih on 9/9/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMPDatabaseHelper.h"
#import "AMPARCMacros.h"
#import "AMPConstants.h"

@interface AMPDatabaseHelperTests : XCTestCase
@property (nonatomic, strong)  AMPDatabaseHelper *databaseHelper;
@end

@implementation AMPDatabaseHelperTests {}

- (void)setUp {
    [super setUp];
    self.databaseHelper = [AMPDatabaseHelper getDatabaseHelper];
    [self.databaseHelper resetDB:NO];
}

- (void)tearDown {
    [super tearDown];
    [self.databaseHelper deleteDB];
    self.databaseHelper = nil;
}

- (void)testGetDatabaseHelper {
    // test backwards compatibility on default instance
    AMPDatabaseHelper *dbHelper = [AMPDatabaseHelper getDatabaseHelper];
    XCTAssertEqual(dbHelper, [AMPDatabaseHelper getDatabaseHelper:nil]);
    XCTAssertEqual(dbHelper, [AMPDatabaseHelper getDatabaseHelper:@""]);
    XCTAssertEqual(dbHelper, [AMPDatabaseHelper getDatabaseHelper:kAMPDefaultInstance]);

    AMPDatabaseHelper *a = [AMPDatabaseHelper getDatabaseHelper:@"a"];
    AMPDatabaseHelper *b = [AMPDatabaseHelper getDatabaseHelper:@"b"];
    XCTAssertNotEqual(dbHelper, a);
    XCTAssertNotEqual(dbHelper, b);
    XCTAssertNotEqual(a, b);
    XCTAssertEqual(a, [AMPDatabaseHelper getDatabaseHelper:@"a"]);
    XCTAssertEqual(b, [AMPDatabaseHelper getDatabaseHelper:@"b"]);

    // test case insensitive instance name
    XCTAssertEqual(a, [AMPDatabaseHelper getDatabaseHelper:@"A"]);
    XCTAssertEqual(b, [AMPDatabaseHelper getDatabaseHelper:@"B"]);
    XCTAssertEqual(dbHelper, [AMPDatabaseHelper getDatabaseHelper:[kAMPDefaultInstance uppercaseString]]);

    // test each instance maintains separate database files
    XCTAssertTrue([a.databasePath rangeOfString:@"com.amplitude.database_a"].location != NSNotFound);
    XCTAssertTrue([b.databasePath rangeOfString:@"com.amplitude.database_b"].location != NSNotFound);
    XCTAssertTrue([dbHelper.databasePath rangeOfString:@"com.amplitude.database"].location != NSNotFound);
    XCTAssertTrue([dbHelper.databasePath rangeOfString:@"com.amplitude.database_"].location == NSNotFound);

    [a deleteDB];
    [b deleteDB];
}

- (void)testSeparateInstances {
    AMPDatabaseHelper *dbHelper = [AMPDatabaseHelper getDatabaseHelper];
    AMPDatabaseHelper *a = [AMPDatabaseHelper getDatabaseHelper:@"a"];
    AMPDatabaseHelper *b = [AMPDatabaseHelper getDatabaseHelper:@"b"];

    [a resetDB:NO];
    [b resetDB:NO];

    [dbHelper insertOrReplaceKeyValue:@"device_id" value:@"test_device_id"];
    XCTAssertEqualObjects([dbHelper getValue:@"device_id"], @"test_device_id");
    XCTAssertNil([a getValue:@"device_id"]);
    XCTAssertNil([b getValue:@"device_id"]);

    [a addEvent:@"test_event"];
    XCTAssertEqual([dbHelper getEventCount], 0);
    XCTAssertEqual([a getEventCount], 1);
    XCTAssertEqual([b getEventCount], 0);

    [b addIdentify:@"test_identify"];
    XCTAssertEqual([dbHelper getIdentifyCount], 0);
    XCTAssertEqual([a getIdentifyCount], 0);
    XCTAssertEqual([b getIdentifyCount], 1);

    [a deleteDB];
    [b deleteDB];
}

- (void)testCreate {
    XCTAssertTrue([self.databaseHelper addEvent:@"test"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyValue:@"key" value:@"value"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyLongValue:@"key" value:[NSNumber numberWithLongLong:0LL]]);
    XCTAssertTrue([self.databaseHelper addIdentify:@"identify"]);
}

- (void)testGetEvents {
    NSArray *emptyResults = [self.databaseHelper getEvents:-1 limit:-1];
    XCTAssertEqual(0, [emptyResults count]);

    [self.databaseHelper addEvent:@"{\"event_type\":\"test1\"}"];
    [self.databaseHelper addEvent:@"{\"event_type\":\"test2\"}"];

    // test get all events
    NSArray *events = [self.databaseHelper getEvents:-1 limit:-1];
    XCTAssertEqual(2, events.count);
    XCTAssert([[[events objectAtIndex:0] objectForKey:@"event_type"] isEqualToString:@"test1"]);
    XCTAssertEqual(1, [[[events objectAtIndex:0] objectForKey:@"event_id"] longValue]);
    XCTAssert([[[events objectAtIndex:1] objectForKey:@"event_type"] isEqualToString:@"test2"]);
    XCTAssertEqual(2, [[[events objectAtIndex:1] objectForKey:@"event_id"] longValue]);

    // test get all events up to certain id
    events = [self.databaseHelper getEvents:1 limit:-1];
    XCTAssertEqual(1, events.count);
    XCTAssertEqual(1, [[events[0] objectForKey:@"event_id"] intValue]);

    // test get all events with limit
    events = [self.databaseHelper getEvents:1 limit:1];
    XCTAssertEqual(1, events.count);
    XCTAssertEqual(1, [[events[0] objectForKey:@"event_id"] intValue]);
}

- (void)testGetIdentifys {
    NSArray *emptyResults = [self.databaseHelper getIdentifys:-1 limit:-1];
    XCTAssertEqual(0, [emptyResults count]);
    XCTAssertEqual(0, [self.databaseHelper getTotalEventCount]);

    [self.databaseHelper addIdentify:@"{\"event_type\":\"$identify\"}"];
    [self.databaseHelper addIdentify:@"{\"event_type\":\"$identify\"}"];

    XCTAssertEqual(0, [self.databaseHelper getEventCount]);
    XCTAssertEqual(2, [self.databaseHelper getIdentifyCount]);
    XCTAssertEqual(2, [self.databaseHelper getTotalEventCount]);

    // test get all identify events
    NSArray *events = [self.databaseHelper getIdentifys:-1 limit:-1];
    XCTAssertEqual(2, events.count);
    XCTAssertEqual(2, [[events[1] objectForKey:@"event_id"] intValue]);
    XCTAssert([[[events objectAtIndex:0] objectForKey:@"event_type"] isEqualToString:IDENTIFY_EVENT]);
    XCTAssertEqual(1, [[[events objectAtIndex:0] objectForKey:@"event_id"] longValue]);
    XCTAssert([[[events objectAtIndex:1] objectForKey:@"event_type"] isEqualToString:IDENTIFY_EVENT]);
    XCTAssertEqual(2, [[[events objectAtIndex:1] objectForKey:@"event_id"] longValue]);

    // test get all identify events up to certain id
    events = [self.databaseHelper getIdentifys:1 limit:-1];
    XCTAssertEqual(1, events.count);
    XCTAssertEqual(1, [[events[0] objectForKey:@"event_id"] intValue]);

    // test get all identify events with limit
    events = [self.databaseHelper getIdentifys:1 limit:1];
    XCTAssertEqual(1, events.count);
    XCTAssertEqual(1, [[events[0] objectForKey:@"event_id"] intValue]);
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

- (void)testInsertNilValue {
    NSString *key = @"test_key";
    NSString *value = nil;
    XCTAssertNil([self.databaseHelper getValue:key]);

    [self.databaseHelper insertOrReplaceKeyValue:key value:value];
    XCTAssertNil([self.databaseHelper getValue:key]);

    NSNumber *longValue = nil;
    XCTAssertNil([self.databaseHelper getLongValue:key]);

    [self.databaseHelper insertOrReplaceKeyLongValue:key value:longValue];
    XCTAssertNil([self.databaseHelper getLongValue:key]);

    // inserting nil value should delete the key from the table
    NSString *value2 = @"test_value";
    [self.databaseHelper insertOrReplaceKeyValue:key value:value2];
    XCTAssertEqualObjects([self.databaseHelper getValue:key], value2);
    [self.databaseHelper insertOrReplaceKeyValue:key value:nil];
    XCTAssertNil([self.databaseHelper getValue:key]);

    NSNumber *longValue2 = [NSNumber numberWithLongLong:2LL];
    [self.databaseHelper insertOrReplaceKeyLongValue:key value:longValue2];
    XCTAssertEqualObjects([self.databaseHelper getLongValue:key], longValue2);
    [self.databaseHelper insertOrReplaceKeyLongValue:key value:nil];
    XCTAssertNil([self.databaseHelper getLongValue:key]);
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

    NSString *boolKey = @"bool_value";
    NSNumber *boolValue = [NSNumber numberWithBool:YES];
    [self.databaseHelper insertOrReplaceKeyLongValue:boolKey value:boolValue];
    XCTAssertTrue([[self.databaseHelper getLongValue:boolKey] boolValue]);
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

- (void)testIdentifyCount {
    XCTAssertTrue([self.databaseHelper addIdentify:@"{\"event_type\":\"$identify\"}"]);
    XCTAssertTrue([self.databaseHelper addIdentify:@"{\"event_type\":\"$identify\"}"]);
    XCTAssertTrue([self.databaseHelper addIdentify:@"{\"event_type\":\"$identify\"}"]);
    XCTAssertTrue([self.databaseHelper addIdentify:@"{\"event_type\":\"$identify\"}"]);
    XCTAssertTrue([self.databaseHelper addIdentify:@"{\"event_type\":\"$identify\"}"]);

    XCTAssertEqual(0, [self.databaseHelper getEventCount]);
    XCTAssertEqual(5, [self.databaseHelper getIdentifyCount]);
    XCTAssertEqual(5, [self.databaseHelper getTotalEventCount]);

    [self.databaseHelper removeIdentify:1];
    XCTAssertEqual(4, [self.databaseHelper getIdentifyCount]);

    [self.databaseHelper removeIdentifys:3];
    XCTAssertEqual(2, [self.databaseHelper getIdentifyCount]);

    [self.databaseHelper removeIdentifys:10];
    XCTAssertEqual(0, [self.databaseHelper getIdentifyCount]);
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

- (void)testGetNthIdentifyId {
    XCTAssertTrue([self.databaseHelper addIdentify:@"{\"event_type\":\"$identify\"}"]);
    XCTAssertTrue([self.databaseHelper addIdentify:@"{\"event_type\":\"$identify\"}"]);
    XCTAssertTrue([self.databaseHelper addIdentify:@"{\"event_type\":\"$identify\"}"]);
    XCTAssertTrue([self.databaseHelper addIdentify:@"{\"event_type\":\"$identify\"}"]);
    XCTAssertTrue([self.databaseHelper addIdentify:@"{\"event_type\":\"$identify\"}"]);

    XCTAssertEqual(1, [self.databaseHelper getNthIdentifyId:0]);
    XCTAssertEqual(1, [self.databaseHelper getNthIdentifyId:1]);
    XCTAssertEqual(2, [self.databaseHelper getNthIdentifyId:2]);
    XCTAssertEqual(3, [self.databaseHelper getNthIdentifyId:3]);
    XCTAssertEqual(4, [self.databaseHelper getNthIdentifyId:4]);
    XCTAssertEqual(5, [self.databaseHelper getNthIdentifyId:5]);

    [self.databaseHelper removeIdentify:1];
    XCTAssertEqual(2, [self.databaseHelper getNthIdentifyId:1]);

    [self.databaseHelper removeIdentifys:3];
    XCTAssertEqual(4, [self.databaseHelper getNthIdentifyId:1]);

    [self.databaseHelper removeIdentifys:10];
    XCTAssertEqual(-1, [self.databaseHelper getNthIdentifyId:1]);
}

- (void)testNoConflictBetweenEventsAndIdentifys{
    XCTAssertTrue([self.databaseHelper addEvent:@"{\"event_type\":\"test1\"}"]);
    XCTAssertTrue([self.databaseHelper addEvent:@"{\"event_type\":\"test2\"}"]);
    XCTAssertTrue([self.databaseHelper addEvent:@"{\"event_type\":\"test3\"}"]);
    XCTAssertTrue([self.databaseHelper addEvent:@"{\"event_type\":\"test4\"}"]);
    XCTAssertEqual(4, [self.databaseHelper getEventCount]);
    XCTAssertEqual(0, [self.databaseHelper getIdentifyCount]);

    XCTAssertTrue([self.databaseHelper addIdentify:@"{\"event_type\":\"$identify\"}"]);
    XCTAssertTrue([self.databaseHelper addIdentify:@"{\"event_type\":\"$identify\"}"]);
    XCTAssertEqual(4, [self.databaseHelper getEventCount]);
    XCTAssertEqual(2, [self.databaseHelper getIdentifyCount]);

    [self.databaseHelper removeEvent:1];
    XCTAssertEqual(3, [self.databaseHelper getEventCount]);
    XCTAssertEqual(2, [self.databaseHelper getIdentifyCount]);

    [self.databaseHelper removeIdentify:1];
    XCTAssertEqual(3, [self.databaseHelper getEventCount]);
    XCTAssertEqual(1, [self.databaseHelper getIdentifyCount]);

    [self.databaseHelper removeEvents:4];
    XCTAssertEqual(0, [self.databaseHelper getEventCount]);
    XCTAssertEqual(1, [self.databaseHelper getIdentifyCount]);
}

- (void)testUpgradeFromVersion0ToVersion2{
    // inserts will fail since no tables exist
    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper addEvent:@"test_event"]);

    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper insertOrReplaceKeyValue:@"test_key" value:@"test_value"]);

    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper insertOrReplaceKeyLongValue:@"test_key" value:[NSNumber numberWithInt:0]]);

    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper addIdentify:@"test_identify"]);

    // after upgrade, can insert into event, store, long_store
    [self.databaseHelper dropTables];
    XCTAssertTrue([self.databaseHelper upgrade:0 newVersion:2]);
    XCTAssertTrue([self.databaseHelper addEvent:@"test"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyValue:@"key" value:@"value"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyLongValue:@"key" value:[NSNumber numberWithLongLong:0LL]]);

    // still can't insert into identify
    XCTAssertFalse([self.databaseHelper addIdentify:@"test_identify"]);
}

// should be exact same as upgrading from 0 to 2
- (void)testUpgradeFromVersion1ToVersion2{
    // inserts will fail since no tables exist
    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper addEvent:@"test_event"]);

    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper insertOrReplaceKeyValue:@"test_key" value:@"test_value"]);

    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper insertOrReplaceKeyLongValue:@"test_key" value:[NSNumber numberWithInt:0]]);

    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper addIdentify:@"test_identify"]);

    // after upgrade, can insert into event, store, long_store
    [self.databaseHelper dropTables];
    XCTAssertTrue([self.databaseHelper upgrade:1 newVersion:2]);
    XCTAssertTrue([self.databaseHelper addEvent:@"test"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyValue:@"key" value:@"value"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyLongValue:@"key" value:[NSNumber numberWithLongLong:0LL]]);

    // still can't insert into identify
    XCTAssertFalse([self.databaseHelper addIdentify:@"test_identify"]);
}

- (void)testUpgradeFromVersion2ToVersion3 {
    [self.databaseHelper dropTables];
    [self.databaseHelper upgrade:1 newVersion:2];

    // can insert into events, store, long_store
    XCTAssertTrue([self.databaseHelper addEvent:@"test"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyValue:@"key" value:@"value"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyLongValue:@"key" value:[NSNumber numberWithLongLong:0LL]]);

    // insert into identifys fail since table doesn't exist yet
    XCTAssertFalse([self.databaseHelper addIdentify:@"test_identify"]);

    // after upgrade, can insert into identify
    [self.databaseHelper dropTables];
    [self.databaseHelper upgrade:1 newVersion:2];
    [self.databaseHelper upgrade:2 newVersion:3];
    XCTAssertTrue([self.databaseHelper addEvent:@"test"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyValue:@"key" value:@"value"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyLongValue:@"key" value:[NSNumber numberWithLongLong:0LL]]);
    XCTAssertTrue([self.databaseHelper addIdentify:@"test_identify"]);
}

- (void)testUpgradeFromVersion0ToVersion3 {
    // inserts will fail since no tables exist
    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper addEvent:@"test_event"]);

    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper insertOrReplaceKeyValue:@"test_key" value:@"test_value"]);

    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper insertOrReplaceKeyLongValue:@"test_key" value:[NSNumber numberWithInt:0]]);

    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper addIdentify:@"test_identify"]);

    // after upgrade, can insert into event, store, long_store, identify
    [self.databaseHelper dropTables];
    XCTAssertTrue([self.databaseHelper upgrade:0 newVersion:3]);
    XCTAssertTrue([self.databaseHelper addEvent:@"test"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyValue:@"key" value:@"value"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyLongValue:@"key" value:[NSNumber numberWithLongLong:0LL]]);
    XCTAssertTrue([self.databaseHelper addIdentify:@"test_identify"]);
}

// should be exact same as upgrading from 0 to 3
- (void)testUpgradeFromVersion1ToVersion3 {
    // inserts will fail since no tables exist
    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper addEvent:@"test_event"]);

    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper insertOrReplaceKeyValue:@"test_key" value:@"test_value"]);

    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper insertOrReplaceKeyLongValue:@"test_key" value:[NSNumber numberWithInt:0]]);

    [self.databaseHelper dropTables];
    XCTAssertFalse([self.databaseHelper addIdentify:@"test_identify"]);

    // after upgrade, can insert into event, store, long_store, identify
    [self.databaseHelper dropTables];
    XCTAssertTrue([self.databaseHelper upgrade:1 newVersion:3]);
    XCTAssertTrue([self.databaseHelper addEvent:@"test"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyValue:@"key" value:@"value"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyLongValue:@"key" value:[NSNumber numberWithLongLong:0LL]]);
    XCTAssertTrue([self.databaseHelper addIdentify:@"test_identify"]);
}

- (void)testUpgradeFromVersion3ToVersion3{
    // upgrade does nothing, can insert into event, store, long_store, identify
    [self.databaseHelper dropTables];
    XCTAssertTrue([self.databaseHelper upgrade:3 newVersion:3]);
    XCTAssertTrue([self.databaseHelper addEvent:@"test"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyValue:@"key" value:@"value"]);
    XCTAssertTrue([self.databaseHelper insertOrReplaceKeyLongValue:@"key" value:[NSNumber numberWithLongLong:0LL]]);
    XCTAssertTrue([self.databaseHelper addIdentify:@"test"]);
}

- (void)testInsertAndReplaceKeyLargeLongValue {
    NSString *key = @"test_key";
    NSNumber *value1 = [NSNumber numberWithLongLong:214748364700000LL];
    NSNumber *value2 = [NSNumber numberWithLongLong:2147483647000000LL];
    XCTAssertNil([self.databaseHelper getLongValue:key]);

    [self.databaseHelper insertOrReplaceKeyLongValue:key value:value1];
    XCTAssert([[self.databaseHelper getLongValue:key] isEqualToNumber:value1]);

    [self.databaseHelper insertOrReplaceKeyLongValue:key value:value2];
    XCTAssert([[self.databaseHelper getLongValue:key] isEqualToNumber:value2]);
}

- (void)testInsertNullEventString {
    [self.databaseHelper addEvent:nil];
    [self.databaseHelper addEvent:@"{\"event_type\":\"test1\"}"];
    XCTAssertEqual(2, [self.databaseHelper getEventCount]);

    NSArray *events = [self.databaseHelper getEvents:-1 limit:-1];  // this should not crash
    // verify that the null event is filtered out
    XCTAssertEqual([events count], 1);
    XCTAssert([[[events objectAtIndex:0] objectForKey:@"event_type"] isEqualToString:@"test1"]);
    XCTAssertEqualObjects([[events objectAtIndex:0] objectForKey:@"event_id"], [NSNumber numberWithInt:2]);
}

@end
