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
}

- (void)tearDown {
    [super tearDown];
    [self.databaseHelper resetDB];
    self.databaseHelper = nil;
}

- (void)testCreate {
    XCTAssertEqual(1, [self.databaseHelper addEvent:@"test"]);
}

- (void)testGetEvent {
    [self.databaseHelper addEvent:@"{event_type:\"test\"}"];
    NSDictionary *results = [self.databaseHelper getEvents:-1 limit:-1];
    XCTAssertEqual(1, [[results objectForKey:@"maxId"] intValue]);
    NSArray *events = [results objectForKey:@"events"];
    XCTAssertEqual(1, events.count);
}

@end