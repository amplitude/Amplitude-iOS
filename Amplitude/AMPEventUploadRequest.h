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

@property (nonatomic, strong) NSString *httpMethod;
@property (nonatomic, strong) NSMutableData *httpBody;
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *httpHeaders;
@property (nonatomic, strong) NSURL *url;


- (instancetype)initWithMethod: (NSString *) httpMethod
                          body: (NSMutableData *) httpBody
                       headers: (NSDictionary<NSString *, NSString *> *) httpHeaders
                           url: (NSURL *)url;

@end
