//
//  IngestionMetadataTests.m
//  Amplitude
//
//  Created by Marvin Liu on 8/31/22.
//  Copyright © 2022 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMPIngestionMetadata.h"
#import "AMPConstants.h"

@interface IngestionMetadataTests : XCTestCase

@end

@implementation IngestionMetadataTests { }

- (void)testSetSourceName {
    AMPIngestionMetadata *ingestionMetadata = [AMPIngestionMetadata ingestionMetadata];
    XCTAssertNil(ingestionMetadata.sourceName);

    NSString *sourceName = @"ampli";
    [ingestionMetadata setSourceName:sourceName];
    XCTAssertEqualObjects(ingestionMetadata.sourceName, sourceName);

    // test that ignore empty inputs
    [ingestionMetadata setSourceName:nil];
    XCTAssertEqualObjects(ingestionMetadata.sourceName, sourceName);
    [ingestionMetadata setSourceName:@""];
    XCTAssertEqualObjects(ingestionMetadata.sourceName, sourceName);

    NSDictionary *dict = [ingestionMetadata toNSDictionary];
    XCTAssertEqualObjects([dict objectForKey:@"source_name"], sourceName);
}

- (void)testSetSourceVersion {
    AMPIngestionMetadata *ingestionMetadata = [AMPIngestionMetadata ingestionMetadata];
    XCTAssertNil(ingestionMetadata.sourceVersion);

    NSString *sourceVersion = @"2.0.0";
    [ingestionMetadata setSourceVersion:sourceVersion];
    XCTAssertEqualObjects(ingestionMetadata.sourceVersion, sourceVersion);

    // test that ignore empty inputs
    [ingestionMetadata setSourceVersion:nil];
    XCTAssertEqualObjects(ingestionMetadata.sourceVersion, sourceVersion);
    [ingestionMetadata setSourceVersion:@""];
    XCTAssertEqualObjects(ingestionMetadata.sourceVersion, sourceVersion);

    NSDictionary *dict = [ingestionMetadata toNSDictionary];
    XCTAssertEqualObjects([dict objectForKey:@"source_version"], sourceVersion);
}

- (void)testToNSDictionary {
    NSString *sourceName = @"ampli";
    NSString *sourceVersion = @"2.0.0";

    AMPIngestionMetadata *ingestionMetadata = [[[AMPIngestionMetadata ingestionMetadata] setSourceName:sourceName] setSourceVersion:sourceVersion];

    NSDictionary *dict = [ingestionMetadata toNSDictionary];
    XCTAssertEqualObjects([dict objectForKey:@"source_name"], sourceName);
    XCTAssertEqualObjects([dict objectForKey:@"source_version"], sourceVersion);
}

@end
