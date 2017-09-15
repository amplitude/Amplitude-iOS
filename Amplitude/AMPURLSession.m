#if AMPLITUDE_SSL_PINNING
//
//  AMPURLSession.m
//  Amplitude
//
//  Created by Daniel Jih on 9/14/17.
//  Copyright (c) 2017 Amplitude. All rights reserved.
//

#import "AMPURLSession.h"
#import "AMPARCMacros.h"
#import "AMPConstants.h"
#import "ISPCertificatePinning.h"
#import "ISPPinnedNSURLSessionDelegate.h"

@interface AMPURLSession ()

@end

@implementation AMPURLSession

+ (void)initialize
{
    if (self == [AMPURLSession class]) {
        [AMPURLSession pinSSLCertificate:@[@"ComodoRsaCA", @"ComodoRsaDomainValidationCA"]];
    }
}

+ (void)pinSSLCertificate:(NSArray *)certFilenames
{
    // We pin the anchor/CA certificates
    NSMutableArray *certs = [NSMutableArray array];
    for (NSString *certFilename in certFilenames) {
        NSString *certPath =  [[NSBundle bundleForClass:[self class]] pathForResource:certFilename ofType:@"der"];
        NSData *certData = SAFE_ARC_AUTORELEASE([[NSData alloc] initWithContentsOfFile:certPath]);
        if (certData == nil) {
            NSLog(@"Failed to load a certificate");
            return;
        }
        [certs addObject:certData];
    }

    NSMutableDictionary *pins = [[NSMutableDictionary alloc] init];
    [pins setObject:certs forKey:kAMPEventLogDomain];

    if (pins == nil) {
        NSLog(@"Failed to pin a certificate");
        return;
    }

    // Save the SSL pins so that our connection delegates automatically use them
    if ([ISPCertificatePinning setupSSLPinsUsingDictionnary:pins] != YES) {
        NSLog(@"Failed to pin the certificates");
        SAFE_ARC_RELEASE(pins);
        return;
    }
    SAFE_ARC_RELEASE(pins);
}

- (void)dealloc
{
    SAFE_ARC_SUPER_DEALLOC();
}

+ (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {

    AMPURLSession *delegate = SAFE_ARC_AUTORELEASE([[AMPURLSession alloc] init]);
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:delegate delegateQueue:nil];
    return [session dataTaskWithRequest:request completionHandler:completionHandler];
}

@end
#endif
