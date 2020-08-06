//
//  AMPConfigManager.m
//  Amplitude
//
//  Created by Hao Liu on 8/5/20.
//  Copyright © 2020 Amplitude. All rights reserved.
//

#import "AMPConfigManager.h"
#import "AMPConstants.h"

@interface AMPConfigManager()

@property (nonatomic, strong, readwrite) NSString* ingestionEndpoint;

@end

@implementation AMPConfigManager

+ (instancetype)sharedInstance {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if ((self = [super init])) {
        self.ingestionEndpoint = kAMPEventLogUrl;
    }
    return self;
}

- (void)refresh:(void(^)(void))completionHandler {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:kAMPDyanmicConfigUrl]];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            NSError *jsonError = nil;
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            NSString *ingestionEndpoint = [NSString stringWithFormat:@"https://%@", [dictionary objectForKey:@"ingestionEndpoint"]];
            
            NSURL *url = [NSURL URLWithString: ingestionEndpoint];
            if (url && url.scheme && url.host) {
                self.ingestionEndpoint = ingestionEndpoint;
            }
        } else {
            // Error
        }
        
        completionHandler();
    }];
    [task resume];
}

@end
