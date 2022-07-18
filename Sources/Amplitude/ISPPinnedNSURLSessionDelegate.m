//
//  ISPPinnedNSURLSessionDelegate.m
//  SSLCertificatePinning
//
//  Created by Alban Diquet on 1/14/14.
//  Copyright (c) 2014 iSEC Partners. All rights reserved.
//

#if AMPLITUDE_SSL_PINNING

#import <Foundation/NSURLSession.h>
#import "ISPPinnedNSURLSessionDelegate.h"
#import "ISPCertificatePinning.h"

@implementation ISPPinnedNSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {

    if([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {

        SecTrustRef serverTrust = [[challenge protectionSpace] serverTrust];
        NSString *domain = [[challenge protectionSpace] host];

        // Validate the certificate chain with the device's trust store anyway
        // This *might* give use revocation checking
        BOOL isTrusted = false;
        if (@available(iOS 12.0, macos 10.14, *)) {
            CFErrorRef error;
            isTrusted = SecTrustEvaluateWithError(serverTrust, &error);
        } else {
            SecTrustResultType trustResult;
            SecTrustEvaluate(serverTrust, &trustResult);
            isTrusted = trustResult == kSecTrustResultUnspecified;
        }
        if (isTrusted) {
            // Look for a pinned certificate in the server's certificate chain
            if ([ISPCertificatePinning verifyPinnedCertificateForTrust:serverTrust andDomain:domain]) {

                // Found the certificate; continue connecting
                completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
            } else {
                // The certificate wasn't found in the certificate chain; cancel the connection
                completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
            }
        } else {
            // Certificate chain validation failed; cancel the connection
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
        }
    }
}

@end
#endif
