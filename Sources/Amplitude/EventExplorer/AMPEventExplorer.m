//
//  AMPEventExplorer.m
//  Amplitude
//
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

#import "AMPEventExplorer.h"
#import <UIKit/UIKit.h>
#import "AMPBubbleView.h"
#import "AMPUtils.h"
#import "AMPInfoViewController.h"

@interface AMPEventExplorer ()

@property (strong, nonatomic, readwrite) AMPBubbleView *bubbleView;
@property (strong, nonatomic, readwrite) NSString *instanceName;

@end

@implementation AMPEventExplorer

- (instancetype)initWithInstanceName:(NSString *)instanceName {
    if ((self = [super init])) {
        self.instanceName = instanceName;
    }
    return self;
}

- (void)showBubbleView {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        CGFloat screenHeight = screenRect.size.height;
        NSInteger bottomOffset = [AMPUtils barBottomOffset];
            
        self.bubbleView = [[AMPBubbleView alloc] initWithFrame:CGRectMake(screenWidth - 50,
                                                                          screenHeight - 50 - bottomOffset,
                                                                          35,
                                                                          35)];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [[AMPUtils getKeyWindow] addSubview:self.bubbleView];
        });
         
        [self.bubbleView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showInfoView)]];
        [self.bubbleView addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(bubbleViewDragged:)]];
    });
}

- (void)showInfoView {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.bubbleView != nil) {
            UIViewController *rootViewController = [[AMPUtils getKeyWindow] rootViewController];
            
            NSBundle *bundle = [NSBundle bundleForClass:[AMPInfoViewController class]];
            AMPInfoViewController *infoVC = [[AMPInfoViewController alloc] initWithNibName:@"AMPInfoViewController" bundle:bundle];
            infoVC.instanceName = self.instanceName;
            
            [infoVC setModalPresentationStyle:UIModalPresentationFullScreen];
            [rootViewController presentViewController:infoVC animated:YES completion:nil];
        }
    });
}

- (void)bubbleViewDragged:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.bubbleView];
    
    CGFloat statusBarHeight = [AMPUtils statusBarHeight];
    NSInteger bottomOffset = [AMPUtils barBottomOffset];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    CGFloat newY = MIN(self.bubbleView.center.y + translation.y, screenHeight - bottomOffset);
    newY = MAX(statusBarHeight + (CGRectGetHeight(self.bubbleView.bounds) / 2), newY);
    
    CGFloat newX = MIN(self.bubbleView.center.x + translation.x, screenWidth);
    newX = MAX((CGRectGetWidth(self.bubbleView.bounds) / 2), newX);
    
    self.bubbleView.center = CGPointMake(newX, newY);
    [sender setTranslation:CGPointZero inView:self.bubbleView];
}

@end
