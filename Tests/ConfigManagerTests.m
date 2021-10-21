//
//  ConfigManagerTests.m
//  Amplitude
//
//  Created by Qingzhuo Zhen on 10/20/21.
//  Copyright © 2021 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "AMPConfigManager.h"
#import "AMPServerZone.h"
#import "AMPConstants.h"

@interface ConfigManagerTests : XCTestCase

@end

@implementation ConfigManagerTests

id _sharedSessionMock;

- (void)setUp {
    [super setUp];
    _sharedSessionMock = [OCMockObject partialMockForObject:[NSURLSession sharedSession]];
}

- (void)tearDown {
    [_sharedSessionMock stopMocking];
    [super tearDown];
}

- (void)setupAsyncResponse: (NSMutableDictionary*) serverResponse {
    [[[_sharedSessionMock stub] andDo:^(NSInvocation *invocation) {
        void (^handler)(NSURLResponse*, NSData*, NSError*);
        [invocation getArgument:&handler atIndex:3];
        handler(serverResponse[@"data"], serverResponse[@"response"], serverResponse[@"error"]);
    }] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
}

- (void)testDynamicConfigurationWithEU {
    NSMutableDictionary *serverResponse = [NSMutableDictionary dictionaryWithDictionary:
                                           @{ @"response" : [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"/"] statusCode:200 HTTPVersion:nil headerFields:@{}],
                                              @"data" : [@"{\"ingestionEndpoint\": \"api.eu.amplitude.com\"}" dataUsingEncoding:NSUTF8StringEncoding]
                                              }];
   
    [self setupAsyncResponse:serverResponse];
    [[AMPConfigManager sharedInstance] refresh:^{
        XCTAssertEqualObjects(kAMPEventLogEuUrl, [[AMPConfigManager sharedInstance].ingestionEndpoint stringByAppendingString:@"/"]);
    } serverZone:EU];
}

@end
