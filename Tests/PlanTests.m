//
//  PlanTests.m
//  Amplitude
//
//  Created by Qingzhuo Zhen on 9/20/21.
//  Copyright © 2021 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMPPlan.h"
#import "AMPConstants.h"

@interface PlanTests : XCTestCase

@end

@implementation PlanTests { }

- (void)testSetBranch {
    AMPPlan *plan = [AMPPlan plan];
    XCTAssertNil(plan.branch);

    NSString *branch = @"test";
    [plan setBranch:branch];
    XCTAssertEqualObjects(plan.branch, branch);

    // test that ignore empty inputs
    [plan setBranch:nil];
    XCTAssertEqualObjects(plan.branch, branch);
    [plan setBranch:@""];
    XCTAssertEqualObjects(plan.branch, branch);

    NSDictionary *dict = [plan toNSDictionary];
    XCTAssertEqualObjects([dict objectForKey:@"branch"], branch);
}

- (void)testSetSource {
    AMPPlan *plan = [AMPPlan plan];
    XCTAssertNil(plan.source);

    NSString *source = @"mobile";
    [plan setSource:source];
    XCTAssertEqualObjects(plan.source, source);

    // test that ignore empty inputs
    [plan setSource:nil];
    XCTAssertEqualObjects(plan.source, source);
    [plan setSource:@""];
    XCTAssertEqualObjects(plan.source, source);

    NSDictionary *dict = [plan toNSDictionary];
    XCTAssertEqualObjects([dict objectForKey:@"source"], source);
}

- (void)testSetVersion {
    AMPPlan *plan = [AMPPlan plan];
    XCTAssertNil(plan.version);

    NSString *version = @"1.0";
    [plan setVersion:version];
    XCTAssertEqualObjects(plan.version, version);

    // test that ignore empty inputs
    [plan setVersion:nil];
    XCTAssertEqualObjects(plan.version, version);
    [plan setVersion:@""];
    XCTAssertEqualObjects(plan.version, version);

    NSDictionary *dict = [plan toNSDictionary];
    XCTAssertEqualObjects([dict objectForKey:@"version"], version);
}

- (void)testSetVersionId {
    AMPPlan *plan = [AMPPlan plan];
    XCTAssertNil(plan.versionId);

    NSString *versionId = @"9ec23ba0-275f-468f-80d1-66b88bff9529";
    [plan setVersionId:versionId];
    XCTAssertEqualObjects(plan.versionId, versionId);

    // test that ignore empty inputs
    [plan setVersionId:nil];
    XCTAssertEqualObjects(plan.versionId, versionId);
    [plan setVersionId:@""];
    XCTAssertEqualObjects(plan.versionId, versionId);

    NSDictionary *dict = [plan toNSDictionary];
    XCTAssertEqualObjects([dict objectForKey:@"versionId"], versionId);
}

- (void)testToNSDictionary {
    NSString *branch = @"main";
    NSString *source = @"mobile";
    NSString *version = @"1.0.0";
    NSString *versionId = @"9ec23ba0-275f-468f-80d1-66b88bff9529";

    AMPPlan *plan = [[[[[AMPPlan plan] setBranch:branch] setSource:source] setVersion:version] setVersionId:versionId];

    NSDictionary *dict = [plan toNSDictionary];
    XCTAssertEqualObjects([dict objectForKey:@"branch"], branch);
    XCTAssertEqualObjects([dict objectForKey:@"source"], source);
    XCTAssertEqualObjects([dict objectForKey:@"version"], version);
    XCTAssertEqualObjects([dict objectForKey:@"versionId"], versionId);
}

@end
