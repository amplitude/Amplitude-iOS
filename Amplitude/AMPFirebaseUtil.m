//
//  AMPFirebaseUtil.m
//  Amplitude
//
//  Created by Hao Liu on 11/19/19.
//  Copyright © 2019 Amplitude. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMPFirebaseUtil.h"
#import "Amplitude.h"

NSString *const kAMPFirebaseUrl = @"https://amplitude-chrome-extension.firebaseio.com";
BOOL deviceIdReported = NO;

@interface AMPFirebaseUtil()

@end

@implementation AMPFirebaseUtil

+ (void)addEvent:(NSMutableDictionary *)event {
    NSString *deviceId = [Amplitude instance].deviceId;
    NSString *apiKey = [Amplitude instance].apiKey;
    
    if (deviceId == nil) {
        return;
    }
    if (apiKey == nil) {
        return;
    }
    
    [AMPFirebaseUtil postNewDeviceId:deviceId forAppKey:apiKey];
    
    NSNumber *timestamp = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    
    NSString *urlString = [[NSString alloc] initWithFormat:@"%@/events/%@/%@.json", kAMPFirebaseUrl, apiKey, deviceId];
    NSLog(@"Firebase url is: %@", urlString);
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setValue:event forKey:[timestamp stringValue]];
    
    NSData *eventData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                        options:NSJSONWritingPrettyPrinted
                                                          error:nil];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"PATCH";
    request.HTTPBody = eventData;
    NSURLSessionDataTask *updateTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"Added a new event");
    }];
    
    [updateTask resume];
}

+ (void)postNewDeviceId: (NSString *)deviceId forAppKey: (NSString *)appKey {
    if (deviceIdReported) {
        return;
    }
    NSString *urlString = [[NSString alloc] initWithFormat:@"%@/app/%@.json", kAMPFirebaseUrl, appKey];
    NSLog(@"Firebase url is: %@", urlString);
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    
    NSURLSessionTask *getTask = [[NSURLSession sharedSession] dataTaskWithURL:[[NSURL alloc] initWithString:urlString]
                                                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSMutableSet *array = [[NSMutableSet alloc] init];
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:nil];
        
        if (![(id)responseDict isEqual: [NSNull null]] && responseDict != nil) {
            [array addObjectsFromArray:[responseDict objectForKey:@"deviceIds"]];
        }
        
        [array addObject:deviceId];
        
        NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
        [dictionary setValue:[NSMutableArray arrayWithArray:[array allObjects]] forKey:@"deviceIds"];
        
        NSData *deviceIdsData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                                options:NSJSONWritingPrettyPrinted
                                                                  error:nil];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        request.HTTPMethod = @"PATCH";
        request.HTTPBody = deviceIdsData;
        NSURLSessionDataTask *updateTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSLog(@"post new device id finished");
            deviceIdReported = YES;
        }];
        
        [updateTask resume];
    }];
    
    [getTask resume];
}

@end
