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

- (void) uploadEvents: (nonnull AMPEventUploadRequest *) uploadRequest using: (nonnull NSURLSession *) session completionHandler: (void (^ _Nonnull )(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)) completionHandler;

@end
