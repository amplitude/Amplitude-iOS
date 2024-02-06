//
//  AMPUtilsTests.m
//  Amplitude
//
//  Created by Qingzhuo Zhen on 2/5/24.
//  Copyright © 2024 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMPUtils.h"

@interface AMPUtilTests : XCTestCase

@end

@implementation AMPUtilTests {
    
}

- (void) testIsSandboxEnabled {
    BOOL isSandboxEnabled = [AMPUtils isSandboxEnabled];
    #if TARGET_OS_OSX
        XCTAssertEqual(isSandboxEnabled, NO);
    #else
        XCTAssertEqual(isSandboxEnabled, YES);
    #endif
}

@end
