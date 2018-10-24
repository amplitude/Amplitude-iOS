//
//  NetworkClient.h
//  Amplitude
//
//  Created by Francesco Perrotti Garcia on 10/23/18.
//  Copyright © 2018 Amplitude. All rights reserved.
//

@class AMPEventUploadRequest;

NS_SWIFT_NAME(NetworkClient)
@protocol AMPNetworkClient <NSObject>

- (void) uploadEvents: (nonnull AMPEventUploadRequest *) request completionHandler: (void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)) completionHandler;

@end
