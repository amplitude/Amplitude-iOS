//
//  AMPConfigManager.h
//  Amplitude
//
//  Created by Hao Liu on 8/5/20.
//  Copyright © 2020 Amplitude. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMPConfigManager : NSObject

@property (nonatomic, strong, readonly) NSString* ingestionEndpoint;

+ (instancetype)sharedInstance;
- (void)refresh:(void(^)(void))completionHandler;

@end

NS_ASSUME_NONNULL_END
