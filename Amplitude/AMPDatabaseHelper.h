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
- (BOOL)upgrade:(int) oldVersion newVersion:(int) newVersion;
- (BOOL)resetDB:(BOOL) deleteDB;
- (BOOL)deleteDB;

- (BOOL)addEvent:(NSString*) event;
- (BOOL)addIdentify:(NSString*) identify;
- (NSMutableArray*)getEvents:(long) upToId limit:(long) limit;
- (NSMutableArray*)getIdentifys:(long) upToId limit:(long) limit;
- (int)getEventCount;
- (int)getIdentifyCount;
- (int)getTotalEventCount;
- (BOOL)removeEvents:(long) maxId;
- (BOOL)removeIdentifys:(long) maxIdentifyId;
- (BOOL)removeEvent:(long) eventId;
- (BOOL)removeIdentify:(long) identifyId;
- (long long)getNthEventId:(long) n;
- (long long)getNthIdentifyId:(long) n;

- (BOOL)insertOrReplaceKeyValue:(NSString*) key value:(NSString*) value;
- (BOOL)insertOrReplaceKeyLongValue:(NSString*) key value:(NSNumber*) value;
- (NSString*)getValue:(NSString*) key;
- (NSNumber*)getLongValue:(NSString*) key;

@end
