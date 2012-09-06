//
//  EventLog.h
//  Hash Helper
//
//  Created by Spenser Skates on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EventLog : NSObject

+ (void)initializeApiKey:(NSString*) apiKey;

+ (void)initializeApiKey:(NSString*) apiKey userId:(NSString*) userId;

+ (void)logEvent:(NSString*) eventType;

+ (void)logEvent:(NSString*) eventType withCustomProperties:(NSDictionary*) customProperties;

+ (void)uploadEvents;

+ (void)setGlobalUserProperties:(NSDictionary*) globalProperties;

+ (void)setUserId:(NSString*) userId;

+ (void)setLocation:(id) location;

+ (void)startListeningForLocation;

+ (void)stopListeningForLocation;

@end
