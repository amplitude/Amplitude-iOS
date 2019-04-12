//
//  AMPNSURLSessionNetworkClient.m
//  Amplitude
//
//  Created by Francesco Perrotti Garcia on 10/24/18.
//  Copyright © 2018 Amplitude. All rights reserved.
//

#import "AMPNSURLSessionNetworkClient.h"
#import "AMPARCMacros.h"
#import "AMPEventUploadRequest.h"

@interface AMPNSURLSessionNetworkClient()
@property (nonatomic, strong) NSURLSession *session;
@end

@implementation AMPNSURLSessionNetworkClient
- (instancetype) init {
    return [super init];
}

- (void) uploadEvents: (AMPEventUploadRequest *) uploadRequest using: (NSURLSession *) session completionHandler: (void (^)(NSData *  data, NSURLResponse *response, NSError *error)) completionHandler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:uploadRequest.url];
    [request setTimeoutInterval:60.0];

    request.HTTPMethod = uploadRequest.httpMethod;
    request.HTTPBody = uploadRequest.httpBody;
    request.allHTTPHeaderFields = uploadRequest.httpHeaders;

    [[session dataTaskWithRequest:request completionHandler:completionHandler] resume];
}


@end
