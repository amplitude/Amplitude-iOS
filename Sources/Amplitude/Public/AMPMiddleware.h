//
//  AMPMiddleware.h
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

@class Amplitude;

/**
 * AMPMiddlewarePayload
 */
@interface AMPMiddlewarePayload: NSObject

@property NSMutableDictionary *_Nonnull event;
@property NSMutableDictionary *_Nullable extra;

- (instancetype _Nonnull)initWithEvent:(NSMutableDictionary *_Nonnull) event withExtra:(NSMutableDictionary *_Nullable) extra;

@end

/**
 * AMPMiddleware
 */
typedef void (^AMPMiddlewareNext)(AMPMiddlewarePayload *_Nullable newPayload);

@protocol AMPMiddleware

- (void)run:(AMPMiddlewarePayload *_Nonnull)payload next:(AMPMiddlewareNext _Nonnull)next;

@optional

- (void)amplitudeDidFinishInitializing:(nonnull Amplitude *)amplitude;
- (void)amplitude:(nonnull Amplitude *)amplitude didUploadEventsManually:(BOOL)manually;
- (void)amplitude:(nonnull Amplitude *)amplitude didChangeDeviceId:(nonnull NSString *)deviceId;
- (void)amplitude:(nonnull Amplitude *)amplitude didChangeSessionId:(long long)sessionId;
- (void)amplitude:(nonnull Amplitude *)amplitude didChangeUserId:(nonnull NSString *)userId;
- (void)amplitude:(nonnull Amplitude *)amplitude didOptOut:(BOOL)optOut;

@end

/**
 * AMPBlockMiddleware
 */
typedef void (^AMPMiddlewareBlock)(AMPMiddlewarePayload *_Nonnull payload, AMPMiddlewareNext _Nonnull next);

@interface AMPBlockMiddleware : NSObject <AMPMiddleware>

@property (nonnull, nonatomic, readonly) AMPMiddlewareBlock block;

@property (nonatomic, copy, nullable) void (^didFinishInitializing)(Amplitude * _Nonnull amplitude);
@property (nonatomic, copy, nullable) void (^didUploadEventsManually)(Amplitude * _Nonnull amplitude, BOOL isManualUpload);
@property (nonatomic, copy, nullable) void (^didChangeDeviceId)(Amplitude * _Nonnull amplitude, NSString * _Nonnull deviceId);
@property (nonatomic, copy, nullable) void (^didChangeSessionId)(Amplitude * _Nonnull amplitude, long long sessionId);
@property (nonatomic, copy, nullable) void (^didChangeUserId)(Amplitude * _Nonnull amplitude, NSString * _Nonnull userId);
@property (nonatomic, copy, nullable) void (^didOptOut)(Amplitude * _Nonnull amplitude, BOOL optOut);

- (instancetype _Nonnull)initWithBlock:(AMPMiddlewareBlock _Nonnull)block NS_DESIGNATED_INITIALIZER;

@end
