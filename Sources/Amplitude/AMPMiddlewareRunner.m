//
//  AMPMiddlewareRunner.m
//  Copyright (c) 2021 Amplitude Inc. (https://amplitude.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <Foundation/Foundation.h>
#import "AMPMiddlewareRunner.h"
#import "AMPMiddleware.h"

@implementation AMPMiddlewareRunner

- (instancetype)init {
    if ((self = [super init])) {
        _middlewares = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (instancetype _Nonnull)middleRunner {
    return [[self alloc] init];
}

- (void) add:(id<AMPMiddleware> _Nonnull)middleware {
    [self.middlewares addObject:middleware];
}

- (void) run:(AMPMiddlewarePayload *_Nonnull)payload next:(AMPMiddlewareNext _Nonnull)next {
    [self runMiddlewares:self.middlewares payload:payload callback:next];
}

- (void) runMiddlewares:(NSArray<id<AMPMiddleware>> *_Nonnull)middlewares
                payload:(AMPMiddlewarePayload *_Nonnull)payload
               callback:(AMPMiddlewareNext _Nullable)callback {
    if (middlewares.count == 0) {
        if (callback) {
            callback(payload);
        }
        return;
    }
    
    [middlewares[0] run:payload next:^(AMPMiddlewarePayload *_Nullable newPayload) {
        NSArray *remainingMiddlewares = [middlewares subarrayWithRange:NSMakeRange(1, middlewares.count - 1)];
        [self runMiddlewares:remainingMiddlewares payload:newPayload callback:callback];
    }];
}

@end
