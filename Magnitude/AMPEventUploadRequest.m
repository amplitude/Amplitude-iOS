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

@synthesize apiKey = _apiKey;
@synthesize events = _events;
@synthesize checksum = _checksum;
@synthesize url = _url;

- (instancetype)initWithApiVersion: (int) apiVersion
                            apiKey: (NSString *) apiKey
                            events: (NSString *) events
                        uploadTime: (long long) uploadTime
                          checksum: (NSString *)checksum
                               url: (NSURL *)url {
    self = [super init];
    _apiVersion = apiVersion;
    _apiKey = apiKey;
    _events = events;
    _uploadTime = uploadTime;
    _checksum = checksum;
    _url = url;
    return self;
}

- (void) dealloc {
    SAFE_ARC_RELEASE(_apiKey);
    SAFE_ARC_RELEASE(_events);
    SAFE_ARC_RELEASE(_checksum);
    SAFE_ARC_RELEASE(_url);
    SAFE_ARC_SUPER_DEALLOC();
}

@end
