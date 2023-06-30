//
//  UIViewController+AMPScreen.m
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

#ifndef AMPLITUDE_DEBUG
#define AMPLITUDE_DEBUG 0
#endif

#ifndef AMPLITUDE_LOG
#if AMPLITUDE_DEBUG
#   define AMPLITUDE_LOG(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#   define AMPLITUDE_LOG(...)
#endif
#endif

#import <objc/runtime.h>
#import "UIViewController+AMPScreen.h"
#import "Amplitude.h"
#import "AMPConstants.h"

#if !TARGET_OS_OSX && !TARGET_OS_WATCH


@implementation UIViewController (AMPScreen)

+ (void)amp_swizzleViewDidAppear {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];

        SEL originalSelector = @selector(viewDidAppear:);
        SEL swizzledSelector = @selector(amp_viewDidAppear:);

        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

        BOOL didAddMethod =
            class_addMethod(class,
                            originalSelector,
                            method_getImplementation(swizzledMethod),
                            method_getTypeEncoding(swizzledMethod));

        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}


+ (UIViewController *)amp_rootViewControllerFromView:(UIView *)view {
    UIViewController *root = view.window.rootViewController;
    return [self amp_topViewController:root];
}

+ (UIViewController *)amp_topViewController:(UIViewController *)rootViewController {
    AMPLITUDE_LOG(@"rootViewController is %@", rootViewController);
    UIViewController *nextRootViewController = [self amp_nextRootViewController:rootViewController];
    if (nextRootViewController) {
        AMPLITUDE_LOG(@"nextRootViewController is %@", nextRootViewController);
        return [self amp_topViewController:nextRootViewController];
    }

    return rootViewController;
}

+ (UIViewController *)amp_nextRootViewController:(UIViewController *)rootViewController {
    UIViewController *presentedViewController = rootViewController.presentedViewController;
    if (presentedViewController != nil) {
        return presentedViewController;
    }

    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UIViewController *lastViewController = ((UINavigationController *)rootViewController).viewControllers.lastObject;
        return lastViewController;
    }

    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        __auto_type *currentTabViewController = ((UITabBarController*)rootViewController).selectedViewController;
        if (currentTabViewController != nil) {
            return currentTabViewController;
        }
    }

    if (rootViewController.childViewControllers.count > 0) {
        __auto_type *firstChildViewController = rootViewController.childViewControllers.firstObject;
        if (firstChildViewController != nil) {
            return firstChildViewController;
        }
    }

    return nil;
}

- (void)amp_viewDidAppear:(BOOL)animated {
    AMPLITUDE_LOG(@"self is %@", self);
    UIViewController *top = [[self class] amp_rootViewControllerFromView:self.view];
    if (!top) {
        AMPLITUDE_LOG(@"Failed to infer screen");
        return;
    }

    NSString *name = [top title];
    if (!name || name.length == 0) {
        // if no class title found, try view controller's description
        name = [[[top class] description] stringByReplacingOccurrencesOfString:@"ViewController" withString:@""];
        if (name.length == 0) {
            AMPLITUDE_LOG(@"Failed to infer screen name");
            name = @"Unknown";
        }
    }

    [[Amplitude instance] logEvent:kAMPScreenViewed withEventProperties:@{
        kAMPEventPropScreenName: name ?: @"",
    }];

    // call original method, this is not recurrsive method call
    [self amp_viewDidAppear:animated];
}

@end
#endif
