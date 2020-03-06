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
#import "AMPUtils.h"

// expose private methods for unit testing
@interface Amplitude (Tests)
- (NSDictionary*)mergeEventsAndIdentifys:(NSMutableArray*)events identifys:(NSMutableArray*)identifys numEvents:(long) numEvents;
- (id) truncate:(id) obj;
- (long long)getNextSequenceNumber;
@end

@interface AmplitudeTVOSTests : BaseTestCase

@end

@implementation AmplitudeTVOSTests {
    id _sharedSessionMock;
    int _connectionCallCount;
}

- (void)setUp {
    [super setUp];
    _sharedSessionMock = [OCMockObject partialMockForObject:[NSURLSession sharedSession]];
    _connectionCallCount = 0;
    [self.amplitude initializeApiKey:apiKey];
}

- (void)tearDown {
    [_sharedSessionMock stopMocking];
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

    // tv os should have upload event upload threshold set to 1
    XCTAssertEqual(kAMPEventUploadThreshold, 1);

    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];

    XCTAssertEqual(_connectionCallCount, 1);
    XCTAssertEqual([self.databaseHelper getEventCount], 1);  // upload failed due to bad checksum
}

- (void)testLogEventPlatformAndOSName {
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];
    NSDictionary *event = [self.amplitude getLastEvent];

    XCTAssertEqualObjects([event objectForKey:@"event_type"], @"test");
    XCTAssertEqualObjects([event objectForKey:@"os_name"], @"tvos");
    XCTAssertEqualObjects([event objectForKey:@"platform"], @"tvOS");
}

-(void)testSetTrackingConfig {
    AMPTrackingOptions *options = [[[[[AMPTrackingOptions options] disableCity] disableIPAddress] disableLanguage] disableCountry];
    [self.amplitude setTrackingOptions:options];

    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];
    NSDictionary *event = [self.amplitude getLastEvent];

    // verify we have platform and carrier since those were not filtered out
    XCTAssertEqualObjects([event objectForKey:@"platform"], @"tvOS");
    XCTAssertEqualObjects([event objectForKey:@"carrier"], @"Unknown");

    // verify we do not have any of the filtered out events
    XCTAssertNil([event objectForKey:@"city"]);
    XCTAssertNil([event objectForKey:@"country"]);
    XCTAssertNil([event objectForKey:@"language"]);

    // verify api properties contains tracking options for location filtering
    NSDictionary *apiProperties = [event objectForKey:@"api_properties"];
    XCTAssertNotNil([apiProperties objectForKey:@"ios_idfv"]);
    XCTAssertNotNil([apiProperties objectForKey:@"tracking_options"]);

    NSDictionary *trackingOptions = [apiProperties objectForKey:@"tracking_options"];
    XCTAssertEqual(3, trackingOptions.count);
    XCTAssertEqualObjects([NSNumber numberWithBool:NO], [trackingOptions objectForKey:@"city"]);
    XCTAssertEqualObjects([NSNumber numberWithBool:NO], [trackingOptions objectForKey:@"country"]);
    XCTAssertEqualObjects([NSNumber numberWithBool:NO], [trackingOptions objectForKey:@"ip_address"]);
}

@end
