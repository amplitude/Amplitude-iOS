//
//  AMPInfoViewController.m
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
#import "AMPInfoViewController.h"
#import "Amplitude.h"

@interface AMPInfoViewController ()

@property (weak, nonatomic) IBOutlet UILabel *deviceIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *userIdLabel;
@property (weak, nonatomic) IBOutlet UIButton *deviceIdCopyButton;
@property (weak, nonatomic) IBOutlet UIButton *userIdCopyButton;
@property (weak, nonatomic) IBOutlet UIImageView *dismissButton;
@property (weak, nonatomic) IBOutlet UILabel *copiedLabel;

@end

@implementation AMPInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.dismissButton addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissSelf)]];
    
    NSString *deviceId = [Amplitude instanceWithName:self.instanceName].deviceId;
    NSString *userId = [Amplitude instanceWithName:self.instanceName].userId;
    
    // Populate deviceId and userId
    self.deviceIdLabel.text = deviceId;
    self.userIdLabel.text = userId;
    
    // Customize styles
    self.deviceIdCopyButton.layer.borderWidth = 1;
    self.deviceIdCopyButton.layer.borderColor = [[UIColor colorWithRed:198.0/255.0 green:208.0/255.0 blue:217.0/255.0 alpha:1] CGColor];
    self.userIdCopyButton.layer.borderWidth = 1;
    self.userIdCopyButton.layer.borderColor = [[UIColor colorWithRed:198.0/255.0 green:208.0/255.0 blue:217.0/255.0 alpha:1] CGColor];
    
    self.copiedLabel.alpha = 0;
    self.copiedLabel.layer.borderWidth = 1;
    self.copiedLabel.layer.borderColor = [[UIColor colorWithRed:198.0/255.0 green:208.0/255.0 blue:217.0/255.0 alpha:1] CGColor];
}

- (void)dismissSelf {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)deviceIdCopyTapped:(id)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.deviceIdLabel.text;
    
    [self showAndDismissCopiedLabel];
}

- (IBAction)userIdCopyTapped:(id)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.userIdLabel.text;
    
    [self showAndDismissCopiedLabel];
}

- (void)showAndDismissCopiedLabel {
    self.copiedLabel.alpha = 1;
    [UIView animateWithDuration:2
                      delay:0.0
                    options:UIViewAnimationOptionTransitionCrossDissolve
                 animations:^{
    [self.copiedLabel setAlpha:0];
                             }
                 completion:NULL];
}

@end
