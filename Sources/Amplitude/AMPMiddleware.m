//
//  AMPMiddleware.m
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
#import "AMPMiddleware.h"

@implementation AMPMiddlewarePayload

- (instancetype _Nonnull)initWithEvent:(NSMutableDictionary *_Nonnull) event withExtra:(NSMutableDictionary *_Nullable) extra {
    if ((self = [super init])) {
        self.event = event;
        self.extra = extra;
    }
    return self;
}

@end

@implementation AMPBlockMiddleware

- (instancetype)init {
    return [self initWithBlock:^(AMPMiddlewarePayload *payload, AMPMiddlewareNext next) {
        next(payload);
    }];
}

- (instancetype _Nonnull)initWithBlock:(AMPMiddlewareBlock)block {
    if (self = [super init]) {
        _block = block;
    }
    return self;
}

- (void)run:(AMPMiddlewarePayload *)payload next:(AMPMiddlewareNext)next {
    self.block(payload, next);
}

- (void)amplitudeDidFinishInitializing:(Amplitude *)amplitude {
    if (self.didFinishInitializing) {
        self.didFinishInitializing(amplitude);
    }
}

- (void)amplitude:(Amplitude *)amplitude didUploadEventsManually:(BOOL)manually {
    if (self.didUploadEventsManually) {
        self.didUploadEventsManually(amplitude, manually);
    }
}

- (void)amplitude:(Amplitude *)amplitude didChangeDeviceId:(NSString *)deviceId {
    if (self.didChangeDeviceId) {
        self.didChangeDeviceId(amplitude, deviceId);
    }
}

- (void)amplitude:(Amplitude *)amplitude didChangeSessionId:(long long)sessionId {
    if (self.didChangeSessionId) {
        self.didChangeSessionId(amplitude, sessionId);
    }
}

- (void)amplitude:(Amplitude *)amplitude didChangeUserId:(NSString *)userId {
    if (self.didChangeUserId) {
        self.didChangeUserId(amplitude, userId);
    }
}

- (void)amplitude:(Amplitude *)amplitude didOptOut:(BOOL)optOut {
    if (self.didOptOut) {
        self.didOptOut(amplitude, optOut);
    }
}

@end
