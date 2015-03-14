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
#import "AMPURLConnection.h"

@interface AMPURLConnection (Test)

+ (void)pinSSLCertificate:(NSString *)certFilename;
+ (void)unpinSSLCertificate;

@end

@interface SSLPinningTests : BaseTestCase

@end

@implementation SSLPinningTests { }

- (void)setUp {
    [super setUp];
    [AMPURLConnection unpinSSLCertificate];
}

- (void)tearDown {
    [AMPURLConnection unpinSSLCertificate];
    [super tearDown];
}

- (void)testSSLWithoutPinning {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing Pinning"];

    [self.amplitude initializeApiKey:@"cd6312957e01361e6c876290f26d9104"];
    [self.amplitude logEvent:@"Test SSL Pinning"];
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

    NSString *certFile = @"InvalidCertificationAuthority";
    [AMPURLConnection pinSSLCertificate:certFile];

    [self.amplitude initializeApiKey:@"cd6312957e01361e6c876290f26d9104"];
    [self.amplitude logEvent:@"Test SSL Pinning"];
    [self.amplitude flushUploads:^() {
        NSDictionary *event = [self.amplitude getLastEvent];
        XCTAssertNotNil(event);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

// For some reason, this test needs to run second in order for the tests to pass.
// They both pass when run individually, but when run together, there must be some
// caching or session holding that happens once a successful connection is made.
- (void)testSSLPinningValidCert {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Testing Pinning"];

    NSString *certFile = @"ComodoCaLimitedRsaCertificationAuthority";
    [AMPURLConnection pinSSLCertificate:certFile];

    [self.amplitude initializeApiKey:@"cd6312957e01361e6c876290f26d9104"];
    [self.amplitude logEvent:@"Test SSL Pinning"];
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
