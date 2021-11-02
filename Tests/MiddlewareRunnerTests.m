//
//  MiddlewareRunnerTests.m
//  Amplitude
//
//  Created by Qingzhuo Zhen on 10/24/21.
//  Copyright © 2021 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMPMiddleware.h"
#import "AMPMiddlewareRunner.h"

AMPMiddlewareBlock customizeBlock = ^(AMPMiddlewarePayload *_Nonnull payload, AMPMiddlewareNext _Nonnull next) {
    next(payload);
};

AMPBlockMiddleware *customizeAllTrackCalls = [[AMPBlockMiddleware alloc] initWithBlock:^(AMPMiddlewarePayload * _Nonnull payload, AMPMiddlewareNext  _Nonnull next) {
    [payload.extra setValue:@"test" forKey:@"event_type"];
    next(payload);
}];



@interface MiddlewareRunnerTests : XCTestCase

@end


@implementation MiddlewareRunnerTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
