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

@interface FakeAMPUtils: AMPUtils
@end

@implementation FakeAMPUtils

+ (NSDictionary *)getEnvironment {
    return @{@"APP_SANDBOX_CONTAINER_ID": @"test-container-id"};
}

@end

@implementation AMPUtilTests {}

- (void) testIsSandboxEnabled {
    BOOL isSandboxEnabled = [AMPUtils isSandboxEnabled];
    #if TARGET_OS_OSX
        XCTAssertEqual(isSandboxEnabled, NO);
    #else
        XCTAssertEqual(isSandboxEnabled, YES);
    #endif
}

#if TARGET_OS_OSX
- (void) testIsSandboxEnabledWhenMacOSIsSandboxed {
    BOOL isSandboxEnabled = [FakeAMPUtils isSandboxEnabled];
    XCTAssertEqual(isSandboxEnabled, YES);
}
#endif

@end
