//
//  DatabaseHelper.h
//  Hash Helper
//
//  Created by Spenser Skates on 8/1/12.
//
//

#import <Foundation/Foundation.h>

@interface DatabaseHelper : NSObject

+ (void)initialize:(NSString*) initialize;

+ (void)addEvent:(NSString*) event;

+ (long)getNumberRows;

+ (id)getEvents;

+ (void)removeEvents:(long) maxId;

@end
