//
//  AmplitudeTests.m
//  Amplitude
//
//  Created by Daniel Jih on 8/7/15.
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
#import "AMPARCMacros.h"

// expose private methods for unit testing
@interface Amplitude (Tests)
- (NSDictionary*)mergeEventsAndIdentifys:(NSMutableArray*)events identifys:(NSMutableArray*)identifys numEvents:(long) numEvents;
- (id) truncate:(id) obj;
- (long long)getNextSequenceNumber;
@end

@interface AmplitudeTests : BaseTestCase

@end

@implementation AmplitudeTests {
    id _connectionMock;
    int _connectionCallCount;
}

- (void)setUp {
    [super setUp];
    _connectionMock = [OCMockObject mockForClass:NSURLConnection.class];
    _connectionCallCount = 0;
    [self.amplitude initializeApiKey:apiKey];
}

- (void)tearDown {
    [_connectionMock stopMocking];
}

- (void)setupAsyncResponse:(id) connectionMock response:(NSMutableDictionary*) serverResponse {
    [[[connectionMock expect] andDo:^(NSInvocation *invocation) {
        _connectionCallCount++;
        void (^handler)(NSURLResponse*, NSData*, NSError*);
        [invocation getArgument:&handler atIndex:4];
        handler(serverResponse[@"response"], serverResponse[@"data"], serverResponse[@"error"]);
    }] sendAsynchronousRequest:OCMOCK_ANY queue:OCMOCK_ANY completionHandler:OCMOCK_ANY];
}

- (void)testInitializeLoadNilUserIdFromEventData {
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], nil);
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];
    NSDictionary *event = [self.amplitude getLastEvent];
    XCTAssertEqual([event objectForKey:@"user_id"], nil);
    XCTAssertFalse([[event allKeys] containsObject:@"user_id"]);
}

- (void)testInitializeLoadUserIdFromEventData {
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], nil);

    NSString *testUserId = @"testUserId";
    [self.databaseHelper insertOrReplaceKeyValue:@"user_id" value:testUserId];
    [self.amplitude initializeApiKey:apiKey];
    [self.amplitude flushQueue];
    XCTAssertTrue([[self.amplitude userId] isEqualToString:testUserId]);
}

- (void)testInitializeWithNilUserId {
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], nil);

    NSString *nilUserId = nil;
    [self.amplitude initializeApiKey:apiKey userId:nilUserId];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], nilUserId);
}

- (void)testInitializeWithUserId {
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], nil);

    NSString *testUserId = @"testUserId";
    [self.amplitude initializeApiKey:apiKey userId:testUserId];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], testUserId);
}

- (void)testClearUserId {
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], nil);

    NSString *testUserId = @"testUserId";
    [self.amplitude setUserId:testUserId];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], testUserId);
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];
    NSDictionary *event1 = [self.amplitude getLastEvent];
    XCTAssert([[event1 objectForKey:@"user_id"] isEqualToString:testUserId]);

    NSString *nilUserId = nil;
    [self.amplitude setUserId:nilUserId];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], nilUserId);
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];
    NSDictionary *event2 = [self.amplitude getLastEvent];
    XCTAssertEqual([event2 objectForKey:@"user_id"], nilUserId);
    XCTAssertFalse([[event2 allKeys] containsObject:@"user_id"]);
}

- (void)testLogEventUploadLogic {
    NSMutableDictionary *serverResponse = [NSMutableDictionary dictionaryWithDictionary:
                                            @{ @"response" : [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:@{}],
                                            @"data" : [@"bad_checksum" dataUsingEncoding:NSUTF8StringEncoding]
                                            }];

    [self setupAsyncResponse:_connectionMock response:serverResponse];
    for (int i = 0; i < kAMPEventUploadThreshold; i++) {
        [self.amplitude logEvent:@"test"];
    }
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];

    // no sent events, event count will be threshold + 1
    XCTAssertEqual([self.amplitude queuedEventCount], kAMPEventUploadThreshold + 1);

    [serverResponse setValue:[@"request_db_write_failed" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"data"];
    [self setupAsyncResponse:_connectionMock response:serverResponse];
    for (int i = 0; i < kAMPEventUploadThreshold; i++) {
        [self.amplitude logEvent:@"test"];
    }
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude queuedEventCount], 2 * kAMPEventUploadThreshold + 1);

    // make post request should only be called 3 times
    XCTAssertEqual(_connectionCallCount, 2);
}

- (void)testRequestTooLargeBackoffLogic {
    [self.amplitude setEventUploadThreshold:2];
    NSMutableDictionary *serverResponse = [NSMutableDictionary dictionaryWithDictionary:
                                           @{ @"response" : [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:413 HTTPVersion:nil headerFields:@{}],
                                              @"data" : [@"response" dataUsingEncoding:NSUTF8StringEncoding]
                                              }];

    // 413 error force backoff with 2 events --> new upload limit will be 1
    [self setupAsyncResponse:_connectionMock response:serverResponse];
    [self.amplitude logEvent:@"test"];
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];

    // with upload limit 1 and 413 --> the top event will be deleted until no events left
    XCTAssertEqual([self.amplitude queuedEventCount], 0);

    // sent 4 server requests: start_session, 2 events, delete top event, delete top event
    XCTAssertEqual(_connectionCallCount, 3);
}

- (void)testUUIDInEvent {
    [self.amplitude setEventUploadThreshold:5];
    [self.amplitude logEvent:@"event1"];
    [self.amplitude logEvent:@"event2"];
    [self.amplitude flushQueue];

    XCTAssertEqual([self.amplitude queuedEventCount], 2);
    NSArray *events = [[AMPDatabaseHelper getDatabaseHelper] getEvents:-1 limit:-1];
    XCTAssertEqual(2, [[events[1] objectForKey:@"event_id"] intValue]);
    XCTAssertNotNil([events[0] objectForKey:@"uuid"]);
    XCTAssertNotNil([events[1] objectForKey:@"uuid"]);
    XCTAssertNotEqual([events[0] objectForKey:@"uuid"], [events[1] objectForKey:@"uuid"]);
}

- (void)testIdentify {
    AMPDatabaseHelper *dbHelper = [AMPDatabaseHelper getDatabaseHelper];
    [self.amplitude setEventUploadThreshold:2];

    AMPIdentify *identify = [[AMPIdentify identify] set:@"key1" value:@"value1"];
    [self.amplitude identify:identify];
    [self.amplitude flushQueue];

    XCTAssertEqual([dbHelper getEventCount], 0);
    XCTAssertEqual([dbHelper getIdentifyCount], 1);
    XCTAssertEqual([dbHelper getTotalEventCount], 1);

    NSDictionary *operations = [NSDictionary dictionaryWithObject:@"value1" forKey:@"key1"];
    NSDictionary *expected = [NSDictionary dictionaryWithObject:operations forKey:@"$set"];
    NSDictionary *event = [self.amplitude getLastIdentify];
    XCTAssertEqualObjects([event objectForKey:@"event_type"], IDENTIFY_EVENT);
    XCTAssertEqualObjects([event objectForKey:@"user_properties"], expected);
    XCTAssertEqualObjects([event objectForKey:@"event_properties"], [NSDictionary dictionary]); // event properties should be empty
    XCTAssertEqual(1, [[event objectForKey:@"sequence_number"] intValue]);

    NSMutableDictionary *serverResponse = [NSMutableDictionary dictionaryWithDictionary:
                                           @{ @"response" : [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:@{}],
                                              @"data" : [@"success" dataUsingEncoding:NSUTF8StringEncoding]
                                              }];
    [self setupAsyncResponse:_connectionMock response:serverResponse];
    AMPIdentify *identify2 = [[[AMPIdentify alloc] init] set:@"key2" value:@"value2"];
    [self.amplitude identify:identify2];
    SAFE_ARC_RELEASE(identify2);
    [self.amplitude flushQueue];

    XCTAssertEqual([dbHelper getEventCount], 0);
    XCTAssertEqual([dbHelper getIdentifyCount], 0);
    XCTAssertEqual([dbHelper getTotalEventCount], 0);
}

- (void)testMergeEventsAndIdentifys {
    AMPDatabaseHelper *dbHelper = [AMPDatabaseHelper getDatabaseHelper];
    [self.amplitude setEventUploadThreshold:7];
    NSMutableDictionary *serverResponse = [NSMutableDictionary dictionaryWithDictionary:
                                           @{ @"response" : [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:@{}],
                                              @"data" : [@"success" dataUsingEncoding:NSUTF8StringEncoding]
                                              }];
    [self setupAsyncResponse:_connectionMock response:serverResponse];

    [self.amplitude logEvent:@"test_event1"];
    [self.amplitude identify:[[AMPIdentify identify] add:@"photoCount" value:[NSNumber numberWithInt:1]]];
    [self.amplitude logEvent:@"test_event2"];
    [self.amplitude logEvent:@"test_event3"];
    [self.amplitude logEvent:@"test_event4"];
    [self.amplitude identify:[[AMPIdentify identify] set:@"gender" value:@"male"]];
    [self.amplitude flushQueue];

    XCTAssertEqual([dbHelper getEventCount], 4);
    XCTAssertEqual([dbHelper getIdentifyCount], 2);
    XCTAssertEqual([dbHelper getTotalEventCount], 6);

    // verify merging
    NSMutableArray *events = [dbHelper getEvents:-1 limit:-1];
    NSMutableArray *identifys = [dbHelper getIdentifys:-1 limit:-1];
    NSDictionary *merged = [self.amplitude mergeEventsAndIdentifys:events identifys:identifys numEvents:[dbHelper getTotalEventCount]];
    NSArray *mergedEvents = [merged objectForKey:@"events"];

    XCTAssertEqual(4, [[merged objectForKey:@"max_event_id"] intValue]);
    XCTAssertEqual(2, [[merged objectForKey:@"max_identify_id"] intValue]);
    XCTAssertEqual(6, [mergedEvents count]);

    XCTAssertEqualObjects([mergedEvents[0] objectForKey:@"event_type"], @"test_event1");
    XCTAssertEqual([[mergedEvents[0] objectForKey:@"event_id"] intValue], 1);
    XCTAssertEqual([[mergedEvents[0] objectForKey:@"sequence_number"] intValue], 1);

    XCTAssertEqualObjects([mergedEvents[1] objectForKey:@"event_type"], @"$identify");
    XCTAssertEqual([[mergedEvents[1] objectForKey:@"event_id"] intValue], 1);
    XCTAssertEqual([[mergedEvents[1] objectForKey:@"sequence_number"] intValue], 2);
    XCTAssertEqualObjects([mergedEvents[1] objectForKey:@"user_properties"], [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"photoCount"] forKey:@"$add"]);

    XCTAssertEqualObjects([mergedEvents[2] objectForKey:@"event_type"], @"test_event2");
    XCTAssertEqual([[mergedEvents[2] objectForKey:@"event_id"] intValue], 2);
    XCTAssertEqual([[mergedEvents[2] objectForKey:@"sequence_number"] intValue], 3);

    XCTAssertEqualObjects([mergedEvents[3] objectForKey:@"event_type"], @"test_event3");
    XCTAssertEqual([[mergedEvents[3] objectForKey:@"event_id"] intValue], 3);
    XCTAssertEqual([[mergedEvents[3] objectForKey:@"sequence_number"] intValue], 4);

    XCTAssertEqualObjects([mergedEvents[4] objectForKey:@"event_type"], @"test_event4");
    XCTAssertEqual([[mergedEvents[4] objectForKey:@"event_id"] intValue], 4);
    XCTAssertEqual([[mergedEvents[4] objectForKey:@"sequence_number"] intValue], 5);

    XCTAssertEqualObjects([mergedEvents[5] objectForKey:@"event_type"], @"$identify");
    XCTAssertEqual([[mergedEvents[5] objectForKey:@"event_id"] intValue], 2);
    XCTAssertEqual([[mergedEvents[5] objectForKey:@"sequence_number"] intValue], 6);
    XCTAssertEqualObjects([mergedEvents[5] objectForKey:@"user_properties"], [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:@"male" forKey:@"gender"] forKey:@"$set"]);

    [self.amplitude identify:[[AMPIdentify identify] unset:@"karma"]];
    [self.amplitude flushQueue];

    XCTAssertEqual([dbHelper getEventCount], 0);
    XCTAssertEqual([dbHelper getIdentifyCount], 0);
    XCTAssertEqual([dbHelper getTotalEventCount], 0);
}

-(void)testTruncateLongStrings {
    NSString *longString = [@"" stringByPaddingToLength:kAMPMaxStringLength*2 withString: @"c" startingAtIndex:0];
    XCTAssertEqual([longString length], kAMPMaxStringLength*2);
    NSString *truncatedString = [self.amplitude truncate:longString];
    XCTAssertEqual([truncatedString length], kAMPMaxStringLength);
    XCTAssertEqualObjects(truncatedString, [@"" stringByPaddingToLength:kAMPMaxStringLength withString: @"c" startingAtIndex:0]);

    NSString *shortString = [@"" stringByPaddingToLength:kAMPMaxStringLength-1 withString: @"c" startingAtIndex:0];
    XCTAssertEqual([shortString length], kAMPMaxStringLength-1);
    truncatedString = [self.amplitude truncate:shortString];
    XCTAssertEqual([truncatedString length], kAMPMaxStringLength-1);
    XCTAssertEqualObjects(truncatedString, shortString);
}

-(void)testTruncateNullObjects {
    XCTAssertNil([self.amplitude truncate:nil]);
}

-(void)testTruncateDictionary {
    NSString *longString = [@"" stringByPaddingToLength:kAMPMaxStringLength*2 withString: @"c" startingAtIndex:0];
    NSString *truncString = [@"" stringByPaddingToLength:kAMPMaxStringLength withString: @"c" startingAtIndex:0];
    NSMutableDictionary *object = [NSMutableDictionary dictionary];
    [object setValue:[NSNumber numberWithInt:10] forKey:@"int value"];
    [object setValue:[NSNumber numberWithBool:NO] forKey:@"bool value"];
    [object setValue:longString forKey:@"long string"];
    [object setValue:[NSArray arrayWithObject:longString] forKey:@"array"];

    object = [self.amplitude truncate:object];
    XCTAssertEqual([[object objectForKey:@"int value"] intValue], 10);
    XCTAssertFalse([[object objectForKey:@"bool value"] boolValue]);
    XCTAssertEqual([[object objectForKey:@"long string"] length], kAMPMaxStringLength);
    XCTAssertEqual([[object objectForKey:@"array"] count], 1);
    XCTAssertEqualObjects([object objectForKey:@"array"][0], truncString);
    XCTAssertEqual([[object objectForKey:@"array"][0] length], kAMPMaxStringLength);
}

-(void)testTruncateEventAndIdentify {
    NSString *longString = [@"" stringByPaddingToLength:kAMPMaxStringLength*2 withString: @"c" startingAtIndex:0];
    NSString *truncString = [@"" stringByPaddingToLength:kAMPMaxStringLength withString: @"c" startingAtIndex:0];

    [self.amplitude logEvent:@"test" withEventProperties:[NSDictionary dictionaryWithObject:longString forKey:@"long_string"]];
    [self.amplitude identify:[[AMPIdentify identify] set:@"long_string" value:longString]];
    [self.amplitude flushQueue];

    NSDictionary *event = [self.amplitude getLastEvent];
    XCTAssertEqualObjects([event objectForKey:@"event_type"], @"test");
    XCTAssertEqualObjects([event objectForKey:@"event_properties"], [NSDictionary dictionaryWithObject:truncString forKey:@"long_string"]);

    NSDictionary *identify = [self.amplitude getLastIdentify];
    XCTAssertEqualObjects([identify objectForKey:@"event_type"], @"$identify");
    XCTAssertEqualObjects([identify objectForKey:@"user_properties"], [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:truncString forKey:@"long_string"] forKey:@"$set"]);
}

-(void)testAutoIncrementSequenceNumber {
    AMPDatabaseHelper *dbHelper = [AMPDatabaseHelper getDatabaseHelper];
    int limit = 10;
    for (int i = 0; i < limit; i++) {
        XCTAssertEqual([self.amplitude getNextSequenceNumber], i+1);
        XCTAssertEqual([[dbHelper getLongValue:@"sequence_number"] intValue], i+1);
    }
}

@end