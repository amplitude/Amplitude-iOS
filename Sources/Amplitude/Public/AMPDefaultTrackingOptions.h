//
//  AMPDefaultTrackingOptions.h
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

#ifndef AMPDefaultTrackingOptions_h
#define AMPDefaultTrackingOptions_h

@interface AMPDefaultTrackingOptions : NSObject

/**
 Enables/disables session tracking. Default to enabled.
 */
@property (nonatomic, assign) BOOL sessions;

/**
 Enables/disables app lifecycle events tracking. Default to disabled.
 */
@property (nonatomic, assign) BOOL appLifecycles;

/**
 Enables/disables deep link events tracking. Default to disabled.
 */
@property (nonatomic, assign) BOOL deepLinks;

/**
 Enables/disables screen view events tracking. Default to disabled.
 */
@property (nonatomic, assign) BOOL screenViews;

- (instancetype)init;
+ (instancetype)initWithSessions:(BOOL)sessions
                   appLifecycles:(BOOL)appLifecycles
                       deepLinks:(BOOL)deepLinks
                     screenViews:(BOOL)screenViews;
+ (instancetype)initWithAllEnabled;
+ (instancetype)initWithNoneEnabled;

@end

#endif /* AMPDefaultTrackingOptions_h */
