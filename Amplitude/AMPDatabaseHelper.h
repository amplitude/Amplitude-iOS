//
//  AMPDatabaseHelper.h
//  Amplitude
//
//  Created by Daniel Jih on 9/9/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

@interface AMPDatabaseHelper : NSObject

+ (AMPDatabaseHelper*)getDatabaseHelper;
- (BOOL)createTables;
- (BOOL)dropTables;
- (void)upgrade:(int) oldVersion newVersion:(int) newVersion;
- (BOOL)resetDB:(BOOL) deleteDB;
- (BOOL)deleteDB;

- (BOOL)addEvent:(NSString*) event;
- (NSDictionary*)getEvents:(long) upToId limit:(long) limit;
- (int)getEventCount;
- (BOOL)removeEvents:(long) maxId;
- (BOOL)removeEvent:(long) eventId;
- (long long)getNthEventId:(long) n;

- (BOOL)insertOrReplaceKeyValue:(NSString*) key value:(NSString*) value;
- (BOOL)insertOrReplaceKeyLongValue:(NSString*) key value:(NSNumber*) value;
- (NSString*)getValue:(NSString*) key;
- (NSNumber*)getLongValue:(NSString*) key;

@end

