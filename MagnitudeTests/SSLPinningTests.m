//
//  SSLPinningTests.m
//  SSLPinningTests
//
//  Created by Curtis on 9/24/14.
//  Copyright (c) 2014 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <OCMock/OCMock.h>
#import "Amplitude.h"
#import "Amplitude+Test.h"
#import "BaseTestCase.h"
#import "AMPURLSession.h"
#import "Amplitude+SSLPinning.h"

@interface AMPURLSession (Test)

+ (void)pinSSLCertificate:(NSArray *)certFilename;

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

- (void)testSSLPinningInvalidCert {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing Pinning"];

    self.amplitude.sslPinningEnabled = YES;
    [AMPURLSession sharedSession]; // trigger static instance to pin valid certificates, then pin the invalid one
    [AMPURLSession pinSSLCertificate:@[@"InvalidCertificationAuthority"]];

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

- (void)testSSLPinningValidCert {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing Pinning"];

    self.amplitude.sslPinningEnabled = YES;
    [AMPURLSession pinSSLCertificate:@[@"ComodoRsaCA", @"ComodoRsaDomainValidationCA"]];

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

@end
