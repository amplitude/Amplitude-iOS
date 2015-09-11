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
    [[self.amplitude eventsData] setObject:testUserId forKey:@"user_id"];
    [self.amplitude initializeApiKey:apiKey];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], testUserId);
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


@end