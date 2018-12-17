//
//  NetworkClient.h
//  Amplitude
//
//  Created by Francesco Perrotti Garcia on 10/23/18.
//  Copyright © 2018 Amplitude. All rights reserved.
//

#import "AMPEventUploadRequest.h"

NS_SWIFT_NAME(NetworkClient)
@protocol AMPNetworkClient <NSObject>

- (void) uploadEvents: (AMPEventUploadRequest *) uploadRequest using: (NSURLSession *) session completionHandler: (void (^)(NSData *data, NSURLResponse *response, NSError *error)) completionHandler;

@end
