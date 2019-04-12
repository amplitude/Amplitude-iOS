//
//  AMPEventUploadRequest.m
//  Amplitude
//
//  Created by Francesco Perrotti Garcia on 10/24/18.
//  Copyright © 2018 Amplitude. All rights reserved.
//

#import "AMPEventUploadRequest.h"
#import "AMPARCMacros.h"

@implementation AMPEventUploadRequest

@synthesize httpMethod = _httpMethod;
@synthesize httpBody = _httpBody;
@synthesize httpHeaders = _httpHeaders;
@synthesize url = _url;

- (instancetype)initWithMethod: (NSString *) httpMethod
                          body: (NSMutableData *) httpBody
                       headers: (NSDictionary<NSString *, NSString *> *) httpHeaders
                           url: (NSURL *)url {
    self = [super init];
    _httpMethod = httpMethod;
    _httpBody = httpBody;
    _httpHeaders = httpHeaders;
    _url = url;
    return self;
}

- (void) dealloc {
    SAFE_ARC_RELEASE(_httpMethod);
    SAFE_ARC_RELEASE(_httpBody);
    SAFE_ARC_RELEASE(_httpHeaders);
    SAFE_ARC_RELEASE(_url);
    SAFE_ARC_SUPER_DEALLOC();
}

@end
