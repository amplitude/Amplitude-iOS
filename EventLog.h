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

+ (void)logEvent:(NSString*) eventType;

@end
