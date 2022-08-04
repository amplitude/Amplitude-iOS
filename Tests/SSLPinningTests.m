//
//  SSLPinningTests.m
//  SSLPinningTests
//
//  Created by Curtis on 9/24/14.
//  Copyright (c) 2014 Amplitude. All rights reserved.
//

#if AMPLITUDE_SSL_PINNING

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Amplitude.h"
#import "Amplitude+Test.h"
#import "BaseTestCase.h"
#import "AMPURLSession.h"
#import "Amplitude+SSLPinning.h"
#import "AMPConstants.h"
#import "AMPServerZone.h"

@interface AMPURLSession (Test)

+ (void)pinSSLCertificate:(NSDictionary *)domainCertFilenamesMap;

@end

@interface SSLPinningTests : BaseTestCase

@end

@implementation SSLPinningTests { }

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSSLWithoutPinning {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing Pinning"];

    self.amplitude.sslPinningEnabled = NO;

    [self.amplitude initializeApiKey:@"1cc2c1978ebab0f6451112a8f5df4f4e"];
    [self.amplitude logEvent:@"Test without SSL Pinning"];
    [self.amplitude flushUploads:^() {
        NSDictionary *event = [self.amplitude getLastEvent];
        XCTAssertNil(event);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)testSSLPinningInvalidCertUS {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing Pinning"];

    self.amplitude.sslPinningEnabled = YES;
    [AMPURLSession sharedSession]; // trigger static instance to pin valid certificates, then pin the invalid one
    NSDictionary *domainCertFilenamesMap = @{
        @"test1": @[@"InvalidCertificationAuthority"]
    };
    [AMPURLSession pinSSLCertificate:domainCertFilenamesMap];

    [self.amplitude initializeApiKey:@"1cc2c1978ebab0f6451112a8f5df4f4e"];
    [self.amplitude logEvent:@"Test Invalid SSL Pinning"];
    [self.amplitude flushQueue];

    [self.amplitude flushUploads:^() {
        // upload fails and so there should still be an unsent event
        NSDictionary *event = [self.amplitude getLastEvent];
        XCTAssertNotNil(event);
        XCTAssertEqual([self.databaseHelper getEventCount], 1);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)testSSLPinningInvalidCertEU {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing Pinning"];

    self.amplitude.sslPinningEnabled = YES;
    [AMPURLSession sharedSession]; // trigger static instance to pin valid certificates, then pin the invalid one
    NSDictionary *domainCertFilenamesMap = @{
        @"test1": @[@"InvalidCertificationAuthority"]
    };
    [AMPURLSession pinSSLCertificate:domainCertFilenamesMap];

    [self.amplitude setServerZone:EU];
    [self.amplitude initializeApiKey:@"361e4558bb359e288ef75d1ae31437a0"];
    [self.amplitude logEvent:@"Test Invalid SSL Pinning"];
    [self.amplitude flushQueue];

    [self.amplitude flushUploads:^() {
        // upload fails and so there should still be an unsent event
        NSDictionary *event = [self.amplitude getLastEvent];
        XCTAssertNotNil(event);
        XCTAssertEqual([self.databaseHelper getEventCount], 1);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)testSSLPinningValidCertForUS {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing Pinning"];

    self.amplitude.sslPinningEnabled = YES;
    NSDictionary *domainCertFilenamesMap = @{
        kAMPEventLogDomain: @[
            @"ComodoRsaDomainValidationCA.der",
            @"Amplitude_Amplitude.bundle/ComodoRsaDomainValidationCA.der"
        ]
    };
    [AMPURLSession pinSSLCertificate:domainCertFilenamesMap];

    [self.amplitude initializeApiKey:@"1cc2c1978ebab0f6451112a8f5df4f4e"];
    [self.amplitude logEvent:@"Test SSL Pinning"];
    [self.amplitude flushQueue];
    [self.amplitude flushUploads:^() {
        NSDictionary *event = [self.amplitude getLastEvent];
        XCTAssertNil(event);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

- (void)testSSLPinningValidCertForEU {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing Pinning"];

    self.amplitude.sslPinningEnabled = YES;
    NSDictionary *domainCertFilenamesMap = @{
        kAMPEventLogEuDomain: @[
            @"AmazonRootCA1.cer",
            @"Amplitude_Amplitude.bundle/AmazonRootCA1.cer"
        ]
    };
    [AMPURLSession pinSSLCertificate:domainCertFilenamesMap];

    [self.amplitude setServerZone:EU];
    [self.amplitude initializeApiKey:@"361e4558bb359e288ef75d1ae31437a0"];
    [self.amplitude logEvent:@"Test SSL Pinning"];
    [self.amplitude flushQueue];
    [self.amplitude flushUploads:^() {
        NSDictionary *event = [self.amplitude getLastEvent];
        XCTAssertNil(event);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

@end

#endif
