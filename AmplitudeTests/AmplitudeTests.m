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

- (void)testLogEventUploadLogic {
    // mocking sendAsynchronousRequest
    NSMutableDictionary *serverResponse = [NSMutableDictionary dictionaryWithDictionary:
                                            @{ @"response" : [[NSHTTPURLResponse alloc] initWithURL:nil statusCode:200 HTTPVersion:nil headerFields:@{}],
                                            @"data" : [@"invalid_api_key" dataUsingEncoding:NSUTF8StringEncoding]
                                            }];
    [self setupAsyncResponse:_connectionMock response:serverResponse];
    [self.amplitude flushQueue];

    [serverResponse setValue:[@"bad_checksum" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"data"];
    [self setupAsyncResponse:_connectionMock response:serverResponse];
    for (int i = 0; i < kAMPEventUploadThreshold; i++) {
        [self.amplitude logEvent:@"test"];
    }
    [self.amplitude flushQueue];

    // no sent events, event count will be threshold + 1 (for start session)
    XCTAssertEqual([self.amplitude queuedEventCount], kAMPEventUploadThreshold + 1);

    [serverResponse setValue:[@"request_db_write_failed" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"data"];
    [self setupAsyncResponse:_connectionMock response:serverResponse];
    for (int i = 0; i < kAMPEventUploadThreshold; i++) {
        [self.amplitude logEvent:@"test"];
    }
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude queuedEventCount], 2 * kAMPEventUploadThreshold + 1);

    // make post request should only be called 3 times
    XCTAssertEqual(_connectionCallCount, 3);
}


@end