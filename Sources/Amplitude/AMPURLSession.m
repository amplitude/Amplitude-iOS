//
//  AMPURLSession.m
//  Copyright (c) 2014 Amplitude Inc. (https://amplitude.com/)
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

#if AMPLITUDE_SSL_PINNING

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

#import "AMPURLSession.h"
#import "AMPConstants.h"
#import "ISPCertificatePinning.h"
#import "ISPPinnedNSURLSessionDelegate.h"

@interface AMPURLSession ()

@end

@implementation AMPURLSession {
    NSURLSession *_sharedSession;
}

+ (AMPURLSession *)sharedSession {
    static AMPURLSession *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[AMPURLSession alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if ((self = [super init])) {
        // ComodoRsaDomainValidationCA is for US endpoint, AmazonRootCA1 is for EU endpoint
        NSDictionary *domainCertFilenamesMap = @{
            kAMPEventLogDomain: @[
                @"ComodoRsaDomainValidationCA.der",
                @"Amplitude_Amplitude.bundle/ComodoRsaDomainValidationCA.der"
            ],
            kAMPEventLogEuDomain: @[
                @"AmazonRootCA1.cer",
                @"Amplitude_Amplitude.bundle/AmazonRootCA1.cer"
            ]
        };
        [AMPURLSession pinSSLCertificate:domainCertFilenamesMap];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _sharedSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    }
    return self;
}

+ (void)pinSSLCertificate:(NSDictionary *)domainCertFilenamesMap {
    // We pin the anchor/CA certificates
    NSMutableDictionary *pins = [[NSMutableDictionary alloc] init];
    for (id domain in domainCertFilenamesMap) {
        NSMutableArray *certs = [NSMutableArray array];
        NSArray *certFilenames = [domainCertFilenamesMap objectForKey:domain];
        for (NSString *certFilename in certFilenames) {
            NSString *certPath =  [[NSBundle bundleForClass:[self class]] pathForResource:certFilename ofType:nil];
            NSData *certData = [[NSData alloc] initWithContentsOfFile:certPath];
            if (certData == nil) {
                continue;
            }
            [certs addObject:certData];
        }
        if ([certs count] == 0) {
            AMPLITUDE_LOG([NSString stringWithFormat:@"Failed to load certificate for domain: %@", domain]);
        } else {
            [pins setObject:certs forKey:domain];
        }
    }

    if (pins == nil) {
        AMPLITUDE_LOG(@"Failed to pin a certificate");
        return;
    }

    // Save the SSL pins so that our connection delegates automatically use them
    if ([ISPCertificatePinning setupSSLPinsUsingDictionnary:pins] != YES) {
        AMPLITUDE_LOG(@"Failed to pin the certificates");
        return;
    }
}

- (void)dealloc {
    [_sharedSession finishTasksAndInvalidate];
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    return [_sharedSession dataTaskWithRequest:request completionHandler:completionHandler];
}

@end

#endif
