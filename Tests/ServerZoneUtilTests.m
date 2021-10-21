//
//  ServerPlanUtilTests.m
//  Amplitude
//
//  Created by Qingzhuo Zhen on 10/20/21.
//  Copyright © 2021 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMPServerZone.h"
#import "AMPServerZoneUtil.h"
#import "AMPConstants.h"

@interface ServerZoneUtilTests : XCTestCase

@end

@implementation ServerZoneUtilTests { }

- (void) testGetEventLogApi {
    XCTAssertEqualObjects(kAMPEventLogUrl, [AMPServerZoneUtil getEventLogApi:US]);
    XCTAssertEqualObjects(kAMPEventLogEuUrl, [AMPServerZoneUtil getEventLogApi:EU]);
}

- (void) testGetDynamicConfigApi {
    XCTAssertEqualObjects(kAMPDyanmicConfigUrl, [AMPServerZoneUtil getDynamicConfigApi:US]);
    XCTAssertEqualObjects(kAMPDyanmicConfigEuUrl, [AMPServerZoneUtil getDynamicConfigApi:EU]);
}

@end
