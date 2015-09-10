//
//  AMPDatabaseHelper.h
//  Amplitude
//
//  Created by Daniel Jih on 9/9/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

@interface AMPDatabaseHelper : NSObject
{
    NSString *databasePath;
}

+ (AMPDatabaseHelper*)getDatabaseHelper;
- (BOOL)createDB;
- (void)resetDB;
- (void)delete;

- (long)addEvent:(NSString*) event;
- (NSDictionary*)getEvents:(long) upToId limit:(int) limit;
- (long)getEventCount;
- (void)removeEvents:(long) maxId;
- (void)removeEvent:(long) eventId;
- (long)getNthEventId:(long) n;

- (long)insertOrReplaceKeyValue:(NSString*) key value:(NSString*) value;
- (NSString*)getValue:(NSString*)key;

@end

