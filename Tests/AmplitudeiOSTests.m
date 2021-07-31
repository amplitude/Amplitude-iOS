//
//  AmplitudeTests.m
//  Amplitude
//
//  Created by Daniel Jih on 8/7/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Amplitude.h"
#import "AMPConstants.h"
#import "Amplitude+Test.h"
#import "BaseTestCase.h"
#import "AMPDeviceInfo.h"
#import "AMPUtils.h"

// expose private methods for unit testing
@interface Amplitude (Tests)

@property (nonatomic, assign) BOOL updatingCurrently;
@property (nonatomic, strong) NSMutableArray *eventsBuffer;
+ (NSString *)getDataStorageKey:(NSString *)key instanceName:(NSString *)instanceName;
- (NSDictionary*)mergeEventsAndIdentifys:(NSMutableArray*)events identifys:(NSMutableArray*)identifys numEvents:(long) numEvents;
- (id) truncate:(id) obj;
- (long long)getNextSequenceNumber;
+ (void) cleanUp;

@end

@interface AmplitudeiOSTests : BaseTestCase

@end

@implementation AmplitudeiOSTests {
    id _sharedSessionMock;
    int _connectionCallCount;
}

- (void)setUp {
    [super setUp];
    _sharedSessionMock = [OCMockObject partialMockForObject:[NSURLSession sharedSession]];
    _connectionCallCount = 0;
    [self.amplitude initializeApiKey:apiKey];
    [Amplitude cleanUp];
}

- (void)tearDown {
    [_sharedSessionMock stopMocking];
    [Amplitude cleanUp];
}

- (void)setupAsyncResponse: (NSMutableDictionary*) serverResponse {
    [[[_sharedSessionMock stub] andDo:^(NSInvocation *invocation) {
        _connectionCallCount++;
        void (^handler)(NSURLResponse*, NSData*, NSError*);
        [invocation getArgument:&handler atIndex:3];
        handler(serverResponse[@"data"], serverResponse[@"response"], serverResponse[@"error"]);
    }] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
}

- (void)testLogEventUploadLogic {
    NSMutableDictionary *serverResponse = [NSMutableDictionary dictionaryWithDictionary:
                                            @{ @"response" : [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"/"] statusCode:200 HTTPVersion:nil headerFields:@{}],
                                            @"data" : [@"bad_checksum" dataUsingEncoding:NSUTF8StringEncoding]
                                            }];

    [self setupAsyncResponse:serverResponse];
    for (int i = 0; i < kAMPEventUploadThreshold; i++) {
        [self.amplitude logEvent:@"test"];
    }
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];

    // no sent events, event count will be threshold + 1
    XCTAssertEqual([self.amplitude.eventsBuffer count], kAMPEventUploadThreshold + 1);

    [serverResponse setValue:[@"request_db_write_failed" dataUsingEncoding:NSUTF8StringEncoding] forKey:@"data"];
    [self setupAsyncResponse:serverResponse];
    self.amplitude.updatingCurrently = NO;
    for (int i = 0; i < kAMPEventUploadThreshold; i++) {
        [self.amplitude logEvent:@"test"];
    }
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude queuedEventCount], 2 * kAMPEventUploadThreshold);
    XCTAssertEqual([self.amplitude.eventsBuffer count], 2 * kAMPEventUploadThreshold + 1);
    
    // make post request should only be called 3 times
    XCTAssertEqual(_connectionCallCount, 2);
}

- (void)testLogEventPlatformAndOSName {
    [self.amplitude setEventUploadThreshold:1];
    
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];
    NSDictionary *event = [self.amplitude getLastEvent];

    XCTAssertEqualObjects([event objectForKey:@"event_type"], @"test");
#if TARGET_OS_MACCATALYST || TARGET_OS_OSX
    XCTAssertEqualObjects([event objectForKey:@"os_name"], @"macos");
    XCTAssertEqualObjects([event objectForKey:@"platform"], @"macOS");
#elif TARGET_OS_IOS
    XCTAssertEqualObjects([event objectForKey:@"os_name"], @"ios");
    XCTAssertEqualObjects([event objectForKey:@"platform"], @"iOS");
#elif TARGET_OS_TV
    XCTAssertEqualObjects([event objectForKey:@"os_name"], @"tvos");
    XCTAssertEqualObjects([event objectForKey:@"platform"], @"tvOS");
#endif
}

@end
