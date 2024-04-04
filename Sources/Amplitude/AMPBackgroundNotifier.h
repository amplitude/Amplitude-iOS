//
//  AMPBackgroundNotifier.h
//  Copyright (c) 2020 Amplitude Inc. (https://amplitude.com/)
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

#if TARGET_OS_WATCH

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const AMPAppWillEnterForegroundNotification;
extern NSNotificationName const AMPAppDidEnterBackgroundNotification;

/// watchOS adds support for background notifications in watchOS 7.0 with `WKExtension.applicationDidEnterBackgroundNotification`
/// and related notifications. But since this SDK is backwards compatible with watchOS 3.0, these notifications are not available. Instead, the user
/// should implement the appropriate background methods on their Extension Delegate and call the `AMPBackgroundNotifier` from those
/// methods.
@interface AMPBackgroundNotifier : NSObject

+ (void)applicationWillEnterForeground;
+ (void)applicationDidEnterBackground;

@end

NS_ASSUME_NONNULL_END

#endif
