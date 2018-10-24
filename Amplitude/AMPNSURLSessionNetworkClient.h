//
//  AMPNSURLSessionNetworkClient.h
//  Amplitude
//
//  Created by Francesco Perrotti Garcia on 10/24/18.
//  Copyright © 2018 Amplitude. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMPNetworkClient.h"

@interface AMPNSURLSessionNetworkClient : NSObject <AMPNetworkClient>

- (nonnull instancetype) initWithNSURLSession: (nonnull NSURLSession *) session;

@end
