//
//  AMPEventUtils.h
//  Copyright (c) 2023 Amplitude Inc. (https://amplitude.com/)
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
#if !TARGET_OS_OSX && !TARGET_OS_WATCH
#import <UIKit/UIKit.h>
#endif

@interface AMPEventUtils : NSObject

+ (NSString *_Nullable)getUserId:(NSDictionary *_Nonnull)event;
+ (NSString *_Nullable)getDeviceId:(NSDictionary *_Nonnull)event;
+ (long long)getEventId:(NSDictionary *_Nonnull)event;
+ (NSString *_Nullable)getEventType:(NSDictionary *_Nonnull)event;
+ (NSMutableDictionary *_Nullable)getGroups:(NSDictionary *_Nonnull)event;
+ (NSMutableDictionary *_Nonnull)getUserProperties:(NSDictionary *_Nonnull)event;
+ (void)setUserProperties:(NSMutableDictionary *_Nonnull)event userProperties:(NSMutableDictionary *_Nonnull)userProperties;
+ (BOOL)hasLowerSequenceNumber:(NSDictionary *_Nonnull)event comparedTo:(NSDictionary *_Nonnull)otherEvent;
+ (NSString *_Nullable)getJsonString:(NSDictionary *_Nonnull)event eventType:(NSString *_Nonnull)eventType error:(NSError * _Nullable * _Nullable)error;

@end
