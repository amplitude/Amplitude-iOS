//
//  NetworkClient.h
//  Amplitude
//
//  Created by Francesco Perrotti Garcia on 10/23/18.
//  Copyright © 2018 Amplitude. All rights reserved.
//

NS_SWIFT_NAME(NetworkClient)
@protocol AMPNetworkClient <NSObject>

- (void) uploadEvents: (nonnull AMPEventUploadRequest *) request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)

@end
