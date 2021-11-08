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

@interface MiddlewareRunnerTests : XCTestCase

@property AMPMiddlewareRunner *middlewareRunner;

@end


@implementation MiddlewareRunnerTests

- (void)setUp {
    _middlewareRunner = [AMPMiddlewareRunner middleRunner];
}

- (void)tearDown {
    _middlewareRunner = nil;
}

- (void)testMiddlewareRun {
    NSString *eventType = @"middleware event";
    AMPBlockMiddleware *updateEventTypeMiddleware = [[AMPBlockMiddleware alloc] initWithBlock: ^(AMPMiddlewarePayload * _Nonnull payload, AMPMiddlewareNext _Nonnull next) {
        [payload.event setValue:eventType forKey:@"event_type"];
        next(payload);
    }];
    NSString *deviceModel = @"middleware_device";
    AMPBlockMiddleware *updateDeviceModelMiddleware = [[AMPBlockMiddleware alloc] initWithBlock: ^(AMPMiddlewarePayload * _Nonnull payload, AMPMiddlewareNext _Nonnull next) {
        [payload.event setValue:deviceModel forKey:@"device_model"];
        next(payload);
    }];
    [_middlewareRunner add:updateEventTypeMiddleware];
    [_middlewareRunner add:updateDeviceModelMiddleware];
    
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    [event setValue:@"sample_event" forKey:@"event_type"];
    [event setValue:@"sample_device" forKey:@"device_model"];
    NSMutableDictionary *extra = [NSMutableDictionary dictionary];
    
    AMPMiddlewarePayload * middlewarePayload = [[AMPMiddlewarePayload alloc] initWithEvent:event extra:extra];
    
    __block BOOL middlewareCompleted = NO;
    
    [_middlewareRunner run:middlewarePayload next:^(AMPMiddlewarePayload *_Nullable newPayload){
        middlewareCompleted = YES;
    }];
    
    XCTAssertEqual(middlewareCompleted, YES);
    XCTAssertEqualObjects([event objectForKey:@"event_type"], eventType);
    XCTAssertEqualObjects([event objectForKey:@"device_model"], deviceModel);
}

- (void)testRunWithNotPassMiddleware {
    NSString *eventType = @"middleware event";
    AMPBlockMiddleware *updateEventTypeMiddleware = [[AMPBlockMiddleware alloc] initWithBlock: ^(AMPMiddlewarePayload * _Nonnull payload, AMPMiddlewareNext _Nonnull next) {
        [payload.event setValue:eventType forKey:@"event_type"];
        next(payload);
    }];
    AMPBlockMiddleware *swallowMiddleware = [[AMPBlockMiddleware alloc] initWithBlock: ^(AMPMiddlewarePayload * _Nonnull payload, AMPMiddlewareNext _Nonnull next) {
    }];
    [_middlewareRunner add:updateEventTypeMiddleware];
    [_middlewareRunner add:swallowMiddleware];
    
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    [event setValue:@"sample_event" forKey:@"event_type"];
    [event setValue:@"sample_device" forKey:@"device_model"];
    NSMutableDictionary *extra = [NSMutableDictionary dictionary];
    
    AMPMiddlewarePayload * middlewarePayload = [[AMPMiddlewarePayload alloc] initWithEvent:event extra:extra];
    
    __block BOOL middlewareCompleted = NO;
    
    [_middlewareRunner run:middlewarePayload next:^(AMPMiddlewarePayload *_Nullable newPayload){
        middlewareCompleted = YES;
    }];
    
    XCTAssertEqual(middlewareCompleted, NO);
    XCTAssertEqualObjects([event objectForKey:@"event_type"], eventType);
}

@end
