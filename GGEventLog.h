//
//  GGEventLog.h
//  Fawkes
//
//  Created by Spenser Skates on 7/26/12.
//  Copyright (c) 2012 GiraffeGraph. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GGEventLog : NSObject

+ (void)initializeApiKey:(NSString*) apiKey;

+ (void)initializeApiKey:(NSString*) apiKey userId:(NSString*) userId;

+ (void)initializeApiKey:(NSString*) apiKey trackCampaignSource:(bool) trackCampaignSource;

+ (void)initializeApiKey:(NSString*) apiKey userId:(NSString*) userId trackCampaignSource:(bool) trackCampaignSource;

+ (void)enableCampaignTrackingApiKey:(NSString*) apiKey;

+ (NSDictionary*)getCampaignInformation;

+ (void)logEvent:(NSString*) eventType;

+ (void)logEvent:(NSString*) eventType withCustomProperties:(NSDictionary*) customProperties;

+ (void)uploadEvents;

+ (void)setGlobalUserProperties:(NSDictionary*) globalProperties;

+ (void)setUserId:(NSString*) userId;

+ (void)setLocation:(id) location;

+ (void)startListeningForLocation;

+ (void)stopListeningForLocation;

@end
