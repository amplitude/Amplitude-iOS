//
//  DatabaseRecoveryTest.m
//  AmplitudeTests
//
//  Created by Daniel Jih on 8/13/18.
//  Copyright © 2018 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <OCMock/OCMock.h>
#import "Amplitude.h"
#import "AMPConstants.h"
#import "Amplitude+Test.h"
#import "BaseTestCase.h"
#import "AMPDatabaseHelper.h"
#import <sqlite3.h>


@interface AMPDatabaseHelper (Test)

- (BOOL)inDatabaseWithStatement:(NSString*) SQLString block:(void (^)(sqlite3_stmt *stmt)) block;

@end


@interface DatabaseRecoveryTests : XCTestCase
@end

@implementation DatabaseRecoveryTests {
    NSString *instanceName;
    Amplitude *amp;
    AMPDatabaseHelper *dbHelper;
}

- (void)setUp {
    [super setUp];
    instanceName = @"recovery";
    amp = [Amplitude instanceWithName:instanceName];
    [amp initializeApiKey:apiKey];
    [amp flushQueueWithQueue:amp.initializerQueue];
    [amp flushQueueWithQueue:amp.backgroundQueue];
    dbHelper = amp.dbHelper;
    dbHelper.callResetListenerOnDatabaseReset = NO;
    [dbHelper resetDB:NO];
}

- (void)tearDown {
    [super tearDown];
    dbHelper.callResetListenerOnDatabaseReset = NO;
    [dbHelper resetDB:NO];
}

- (void)testDatabaseRecoverStackOverflow {
    [amp logEvent:@"test"];
    [amp flushQueueWithQueue:amp.backgroundQueue];
    NSArray *events = [dbHelper getEvents:-1 limit:-1];
    NSDictionary *event = [events lastObject];
    XCTAssertEqualObjects([event valueForKey:@"event_type"], @"test");

    NSString *deviceId = [dbHelper getValue:@"device_id"];
    NSNumber *previousSessionId = [dbHelper getLongValue:@"previous_session_id"];
    NSNumber *previousSessionTime = [dbHelper getLongValue:@"previous_session_time"];
    NSNumber *sequenceNumber = [dbHelper getLongValue:@"sequence_number"];

    XCTAssertNotNil(amp.deviceId);
    XCTAssertGreaterThanOrEqual([previousSessionId longLongValue], 0);
    XCTAssertGreaterThanOrEqual([previousSessionTime longLongValue], 0);
    XCTAssertEqual([sequenceNumber intValue], 1);

    dbHelper.callResetListenerOnDatabaseReset = YES;
    id mockDbHelper = OCMPartialMock(dbHelper);
    [[[mockDbHelper stub] andReturnValue:@NO] inDatabaseWithStatement:[OCMArg any] block:[OCMArg any]];
    amp.dbHelper = mockDbHelper;

    [amp logEvent:@"test"];
    [amp flushQueueWithQueue:amp.backgroundQueue];

    // verify stack overflow stopped but metadata was not re-written
    deviceId = [dbHelper getValue:@"device_id"];
    previousSessionId = [dbHelper getLongValue:@"previous_session_id"];
    previousSessionTime = [dbHelper getLongValue:@"previous_session_time"];
    sequenceNumber = [dbHelper getLongValue:@"sequence_number"];

    XCTAssertNil(deviceId);
    XCTAssertNil(previousSessionId);
    XCTAssertNil(previousSessionTime);
    XCTAssertNil(sequenceNumber);

    [mockDbHelper stopMocking];
    [dbHelper setDatabaseResetListener:nil];
    amp.dbHelper = dbHelper;
}

@end
