//
//  AMPEventUploadRequest.h
//  Amplitude
//
//  Created by Francesco Perrotti Garcia on 10/24/18.
//  Copyright © 2018 Amplitude. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_SWIFT_NAME(EventUploadRequest)
@interface AMPEventUploadRequest : NSObject

@property (nonatomic, assign) int apiVersion;
@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *events;
@property (nonatomic, assign) long long uploadTime;
@property (nonatomic, strong) NSString *checksum;
@property (nonatomic, strong) NSURL *url;

- (instancetype)initWithApiVersion: (int) apiVersion
                            apiKey: (NSString *) apiKey
                            events: (NSString *) events
                        uploadTime: (long long) uploadTime
                          checksum: (NSString *)checksum
                               url: (NSURL *)url;
@end
