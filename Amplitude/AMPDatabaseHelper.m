//
//  AMPDatabaseHelper.m
//  Amplitude
//
//  Created by Daniel Jih on 9/9/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMPARCMacros.h"
#import "AMPDatabaseHelper.h"
#import "AMPARCMacros.h"
#import "FMDB/FMDB.h"

@interface AMPDatabaseHelper()
@end

@implementation AMPDatabaseHelper
{
    NSString *_databasePath;
    BOOL _databaseCreated;
    FMDatabaseQueue *_dbQueue;
}

static NSString *const EVENT_TABLE_NAME = @"events";
static NSString *const IDENTIFY_TABLE_NAME = @"identifys";
static NSString *const ID_FIELD = @"id";
static NSString *const EVENT_FIELD = @"event";

static NSString *const STORE_TABLE_NAME = @"store";
static NSString *const LONG_STORE_TABLE_NAME = @"long_store";
static NSString *const KEY_FIELD = @"key";
static NSString *const VALUE_FIELD = @"value";

static NSString *const DROP_TABLE = @"DROP TABLE IF EXISTS %@;";
static NSString *const CREATE_EVENT_TABLE = @"CREATE TABLE IF NOT EXISTS %@ (%@ INTEGER PRIMARY KEY AUTOINCREMENT, %@ TEXT);";
static NSString *const CREATE_IDENTIFY_TABLE = @"CREATE TABLE IF NOT EXISTS %@ (%@ INTEGER PRIMARY KEY AUTOINCREMENT, %@ TEXT);";
static NSString *const CREATE_STORE_TABLE = @"CREATE TABLE IF NOT EXISTS %@ (%@ TEXT PRIMARY KEY NOT NULL, %@ TEXT);";
static NSString *const CREATE_LONG_STORE_TABLE = @"CREATE TABLE IF NOT EXISTS %@ (%@ TEXT PRIMARY KEY NOT NULL, %@ INTEGER);";

static NSString *const INSERT_EVENT = @"INSERT INTO %@ (%@) VALUES (?);";
static NSString *const GET_EVENT_WITH_UPTOID_AND_LIMIT = @"SELECT %@, %@ FROM %@ WHERE %@ <= %lli LIMIT %lli;";
static NSString *const GET_EVENT_WITH_UPTOID = @"SELECT %@, %@ FROM %@ WHERE %@ <= %lli;";
static NSString *const GET_EVENT_WITH_LIMIT = @"SELECT %@, %@ FROM %@ LIMIT %lli;";
static NSString *const GET_EVENT = @"SELECT %@, %@ FROM %@;";
static NSString *const COUNT_EVENTS = @"SELECT COUNT(*) FROM %@;";
static NSString *const REMOVE_EVENTS = @"DELETE FROM %@ WHERE %@ <= %lli;";
static NSString *const REMOVE_EVENT = @"DELETE FROM %@ WHERE %@ = %lli;";
static NSString *const GET_NTH_EVENT_ID = @"SELECT %@ FROM %@ LIMIT 1 OFFSET %lli;";

static NSString *const INSERT_OR_REPLACE_KEY_VALUE = @"INSERT OR REPLACE INTO %@ (%@, %@) VALUES (?, ?);";
static NSString *const GET_VALUE = @"SELECT %@, %@ FROM %@ WHERE %@ = (?);";


+ (AMPDatabaseHelper*)getDatabaseHelper
{
    static AMPDatabaseHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AMPDatabaseHelper alloc] init];
    });
    return instance;
}

- (id) init
{
    if (self = [super init]) {

        NSString *databaseDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
        _databasePath = SAFE_ARC_RETAIN([databaseDirectory stringByAppendingPathComponent:@"com.amplitude.database"]);
        _dbQueue = SAFE_ARC_RETAIN([FMDatabaseQueue databaseQueueWithPath:_databasePath flags:(SQLITE_OPEN_READWRITE|SQLITE_OPEN_CREATE)]);
        if (![[NSFileManager defaultManager] fileExistsAtPath:_databasePath]) {
            [self createTables];
        }
    }
    return self;
}

- (void)dealloc
{
    [_dbQueue close];
    SAFE_ARC_RELEASE(_databasePath);
    SAFE_ARC_RELEASE(_dbQueue);
    SAFE_ARC_SUPER_DEALLOC();
}

- (BOOL)createTables
{
    __block BOOL success = YES;

    [_dbQueue inDatabase:^(FMDatabase *db) {

        if (![db open]) {
            NSLog(@"Failed to open database during create tables");
            success = NO;
            return;
        }

        NSString *createEventsTable = [NSString stringWithFormat:CREATE_EVENT_TABLE, EVENT_TABLE_NAME, ID_FIELD, EVENT_FIELD];
        success &= [db executeUpdate:createEventsTable];

        NSString *createIdentifysTable = [NSString stringWithFormat:CREATE_IDENTIFY_TABLE, IDENTIFY_TABLE_NAME, ID_FIELD, EVENT_FIELD];
        success &= [db executeUpdate:createIdentifysTable];

        NSString *createStoreTable = [NSString stringWithFormat:CREATE_STORE_TABLE, STORE_TABLE_NAME, KEY_FIELD, VALUE_FIELD];
        success &= [db executeUpdate:createStoreTable];

        NSString *createLongStoreTable = [NSString stringWithFormat:CREATE_LONG_STORE_TABLE, LONG_STORE_TABLE_NAME, KEY_FIELD, VALUE_FIELD];
        success &= [db executeUpdate:createLongStoreTable];

        [db close];
    }];

    return success;
}

- (BOOL)upgrade:(int) oldVersion newVersion:(int) newVersion
{
    __block BOOL success = YES;

    [_dbQueue inDatabase:^(FMDatabase *db) {

        if (![db open]) {
            NSLog(@"Failed to open database during upgrade");
            success = NO;
            return;
        }

        switch (oldVersion) {
            case 0:
            case 1: {
                NSString *createEventsTable = [NSString stringWithFormat:CREATE_EVENT_TABLE, EVENT_TABLE_NAME, ID_FIELD, EVENT_FIELD];
                success &= [db executeUpdate:createEventsTable];

                NSString *createStoreTable = [NSString stringWithFormat:CREATE_STORE_TABLE, STORE_TABLE_NAME, KEY_FIELD, VALUE_FIELD];
                success &= [db executeUpdate:createStoreTable];

                NSString *createLongStoreTable = [NSString stringWithFormat:CREATE_LONG_STORE_TABLE, LONG_STORE_TABLE_NAME, KEY_FIELD, VALUE_FIELD];
                success &= [db executeUpdate:createLongStoreTable];

                if (newVersion <= 2) break;
            }
            case 2: {
                NSString *createIdentifysTable = [NSString stringWithFormat:CREATE_IDENTIFY_TABLE, IDENTIFY_TABLE_NAME, ID_FIELD, EVENT_FIELD];
                success &= [db executeUpdate:createIdentifysTable];

                if (newVersion <= 3) break;
            }
            default:
                success = NO;
        }

        [db close];
    }];

    if (!success) {
        NSLog(@"upgrade with unknown oldVersion %d", oldVersion);
        return [self resetDB:NO];
    }

    return success;
}

- (BOOL)dropTables
{
    __block BOOL success = YES;

    [_dbQueue inDatabase:^(FMDatabase *db) {

        if (![db open]) {
            NSLog(@"Failed to open database during drop tables");
            success = NO;
            return;
        }

        NSString *dropEventTableSQL = [NSString stringWithFormat:DROP_TABLE, EVENT_TABLE_NAME];
        success &= [db executeUpdate: dropEventTableSQL];

        NSString *dropIdentifyTableSQL = [NSString stringWithFormat:DROP_TABLE, IDENTIFY_TABLE_NAME];
        success &= [db executeUpdate: dropIdentifyTableSQL];

        NSString *dropStoreTableSQL = [NSString stringWithFormat:DROP_TABLE, STORE_TABLE_NAME];
        success &= [db executeUpdate: dropStoreTableSQL];

        NSString *dropLongStoreTableSQL = [NSString stringWithFormat:DROP_TABLE, LONG_STORE_TABLE_NAME];
        success &= [db executeUpdate: dropLongStoreTableSQL];

        [db close];
    }];

    return success;
}

- (BOOL)resetDB:(BOOL) deleteDB
{
    BOOL success = YES;

    if (deleteDB) {
        success &= [self deleteDB];
    } else {
        success &= [self dropTables];
    }
    success &= [self createTables];

    return success;
}

- (BOOL)deleteDB
{
    BOOL success = YES;
    if ([[NSFileManager defaultManager] fileExistsAtPath:_databasePath] == YES) {
        success = [[NSFileManager defaultManager] removeItemAtPath:_databasePath error:NULL];
    }
    return success;
}

- (BOOL)addEvent:(NSString*) event
{
    return [self addEventToTable:EVENT_TABLE_NAME event:event];
}

- (BOOL)addIdentify:(NSString*) identifyEvent
{
    return [self addEventToTable:IDENTIFY_TABLE_NAME event:identifyEvent];
}

- (BOOL)addEventToTable:(NSString*) table event:(NSString*) event
{
    __block BOOL success = NO;
    __block NSString *errMsg;

    [_dbQueue inDatabase:^(FMDatabase *db) {
        if (![db open]) {
            NSLog(@"Failed to open database during addEventToTable %@", table);
            return;
        }

        NSString *insertSQL = [NSString stringWithFormat:INSERT_EVENT, table, EVENT_FIELD];
        success = [db executeUpdate:insertSQL, event];
        if (!success) {
            errMsg = [db lastErrorMessage];
        }
        [db close];
    }];

    if (!success) {
        NSLog(@"addEventToTable %@ failed: %@", table, errMsg);
        [self resetDB:NO]; // not much we can do, just start fresh
    }
    return success;
}

- (NSMutableArray*)getEvents:(long long) upToId limit:(long long) limit
{
    return [self getEventsFromTable:EVENT_TABLE_NAME upToId:upToId limit:limit];
}

- (NSMutableArray*)getIdentifys:(long long) upToId limit:(long long) limit
{
    return [self getEventsFromTable:IDENTIFY_TABLE_NAME upToId:upToId limit:limit];
}

- (NSMutableArray*)getEventsFromTable:(NSString*) table upToId:(long long) upToId limit:(long long) limit
{
    __block NSMutableArray *events = [[NSMutableArray alloc] init];

    [_dbQueue inDatabase:^(FMDatabase *db) {
        if (![db open]) {
            NSLog(@"Failed to open database during getEventsFromTable %@", table);
            return;
        }

        NSString *querySQL;
        if (upToId > 0 && limit > 0) {
            querySQL = [NSString stringWithFormat:GET_EVENT_WITH_UPTOID_AND_LIMIT, ID_FIELD, EVENT_FIELD, table, ID_FIELD, upToId, limit];
        } else if (upToId > 0) {
            querySQL = [NSString stringWithFormat:GET_EVENT_WITH_UPTOID, ID_FIELD, EVENT_FIELD, table, ID_FIELD, upToId];
        } else if (limit > 0) {
            querySQL = [NSString stringWithFormat:GET_EVENT_WITH_LIMIT, ID_FIELD, EVENT_FIELD, table, limit];
        } else {
            querySQL = [NSString stringWithFormat:GET_EVENT, ID_FIELD, EVENT_FIELD, table];
        }
        FMResultSet *rs = [db executeQuery:querySQL];
        if (rs == nil) {
            NSLog(@"getEvents from table %@ failed: %@", table, [db lastErrorMessage]);
            [db close];
            [self resetDB:NO];
            return;
        }

        while ([rs next]) {
            int eventId = [rs intForColumnIndex:0];
            NSString *eventString = [rs stringForColumnIndex:1];
            NSData *eventData = [eventString dataUsingEncoding:NSUTF8StringEncoding];

            id eventImmutable = [NSJSONSerialization JSONObjectWithData:eventData options:0 error:NULL];
            if (eventImmutable == nil) {
                NSLog(@"Error JSON deserialization of event id %d from table %@", eventId, table);
                continue;
            }

            NSMutableDictionary *event = [eventImmutable mutableCopy];
            [event setValue:[NSNumber numberWithInt:eventId] forKey:@"event_id"];
            [events addObject:event];
            SAFE_ARC_RELEASE(event);
        }

        [db close];
    }];

    return SAFE_ARC_AUTORELEASE(events);
}

- (BOOL)insertOrReplaceKeyValue:(NSString*) key value:(NSString*) value
{
    return [self insertOrReplaceKeyValueToTable:STORE_TABLE_NAME key:key value:value];
}

- (BOOL)insertOrReplaceKeyLongValue:(NSString *) key value:(NSNumber*) value
{
    return [self insertOrReplaceKeyValueToTable:LONG_STORE_TABLE_NAME key:key value:value];
}

- (BOOL)insertOrReplaceKeyValueToTable:(NSString*) table key:(NSString*) key value:(NSObject*) value
{
    __block BOOL success = NO;
    __block NSString *errMsg;

    [_dbQueue inDatabase:^(FMDatabase *db) {
        if (![db open]) {
            NSLog(@"Failed to open database during insertOrReplaceKeyValueToTable %@", table);
            return;
        }

        NSString *insertSQL = [NSString stringWithFormat:INSERT_OR_REPLACE_KEY_VALUE, table, KEY_FIELD, VALUE_FIELD];
        if ([table isEqualToString:STORE_TABLE_NAME]) {
            success = [db executeUpdate:insertSQL, key, (NSString*) value];
        } else {
            success = [db executeUpdate:insertSQL, key, (NSNumber*) value];
        }

        if (!success) {
            errMsg = [db lastErrorMessage];
        }
        [db close];
    }];

    if (!success) {
        NSLog(@"insertOrReplaceKeyValue to table %@ failed: %@", table, errMsg);
        [self resetDB:NO]; // not much we can do, just start fresh
    }
    return success;
}

- (NSString*)getValue:(NSString*) key
{
    return (NSString*)[self getValueFromTable:STORE_TABLE_NAME key:key];
}

- (NSNumber*)getLongValue:(NSString*) key
{
    return (NSNumber*)[self getValueFromTable:LONG_STORE_TABLE_NAME key:key];
}

- (NSObject*)getValueFromTable:(NSString*) table key:(NSString*) key
{
    __block NSObject *value = nil;
    __block BOOL success = NO;

    [_dbQueue inDatabase:^(FMDatabase *db) {
        if (![db open]) {
            NSLog(@"Failed to open database during getValueFromTable %@", table);
            return;
        }

        NSString *querySQL = [NSString stringWithFormat:GET_VALUE, KEY_FIELD, VALUE_FIELD, table, KEY_FIELD];
        FMResultSet *rs = [db executeQuery:querySQL, key];
        if (rs == nil) {
            NSLog(@"getValueFromTable %@ failed: %@", table, [db lastErrorMessage]);
            [db close];
            return;
        }

        if ([rs next]) {
            success = YES;
            if (![rs columnIndexIsNull:1]) { // possible to have null values
                if ([table isEqualToString:STORE_TABLE_NAME]) {
                    value = [[NSString alloc] initWithString:[rs stringForColumnIndex:1]];
                } else {
                    value = [[NSNumber alloc] initWithLongLong:[rs longLongIntForColumnIndex:1]];
                }
            }
        }

        [db close];
    }];

    if (!success) {
        return nil;
    }
    return SAFE_ARC_AUTORELEASE(value);
}

- (int)getEventCount
{
    return [self getEventCountFromTable:EVENT_TABLE_NAME];
}

- (int)getIdentifyCount
{
    return [self getEventCountFromTable:IDENTIFY_TABLE_NAME];
}

- (int)getTotalEventCount
{
    return [self getEventCount] + [self getIdentifyCount];
}

- (int)getEventCountFromTable:(NSString*) table
{
    __block int count = 0;

    [_dbQueue inDatabase:^(FMDatabase *db) {
        if (![db open]) {
            NSLog(@"Failed to open database during getEventCountFromTable %@", table);
            return;
        }

        NSString *querySQL = [NSString stringWithFormat:COUNT_EVENTS, table];
        FMResultSet *rs = [db executeQuery:querySQL];
        if (rs == nil) {
            NSLog(@"getEventCountFromTable %@ failed: %@", table, [db lastErrorMessage]);
            [db close];
            return;
        }

        if ([rs next]) {
            count = [rs intForColumnIndex:0];
        } else {
            NSLog(@"getEventCountFromTable %@ failed", table);
        }

        [db close];
    }];

    return count;
}

- (BOOL)removeEvents:(long long) maxId
{
    return [self removeEventsFromTable:EVENT_TABLE_NAME maxId:maxId];
}

- (BOOL)removeIdentifys:(long long) maxIdentifyId
{
    return [self removeEventsFromTable:IDENTIFY_TABLE_NAME maxId:maxIdentifyId];
}

- (BOOL)removeEventsFromTable:(NSString*) table maxId:(long long) maxId
{
    __block BOOL success = NO;

    [_dbQueue inDatabase:^(FMDatabase *db) {
        if (![db open]) {
            NSLog(@"Failed to open database during removeEventsFromTable %@", table);
            return;
        }

        NSString *removeSQL = [NSString stringWithFormat:REMOVE_EVENTS, table, ID_FIELD, maxId];
        BOOL success = [db executeUpdate:removeSQL];
        if (!success) {
            NSLog(@"removeEventsFromTable %@ failed: %@", table, [db lastErrorMessage]);
        }

        [db close];
    }];

    return success;
}

- (BOOL)removeEvent:(long long) eventId
{
    return [self removeEventFromTable:EVENT_TABLE_NAME eventId:eventId];
}

- (BOOL)removeIdentify:(long long) identifyId
{
    return [self removeEventFromTable:IDENTIFY_TABLE_NAME eventId:identifyId];
}

- (BOOL)removeEventFromTable:(NSString*) table eventId:(long long) eventId
{
    __block BOOL success = NO;

    [_dbQueue inDatabase:^(FMDatabase *db) {
        if (![db open]) {
            NSLog(@"Failed to open database during removeEventFromTable %@", table);
            return;
        }

        NSString *removeSQL = [NSString stringWithFormat:REMOVE_EVENT, table, ID_FIELD, eventId];
        BOOL success = [db executeUpdate:removeSQL];
        if (!success) {
            NSLog(@"removeEvent from table %@ failed: %@", table, [db lastErrorMessage]);
        }

        [db close];
    }];

    return success;
}

- (long long)getNthEventId:(long long) n
{
    return [self getNthEventIdFromTable:EVENT_TABLE_NAME n:n];
}

- (long long)getNthIdentifyId:(long long) n
{
    return [self getNthEventIdFromTable:IDENTIFY_TABLE_NAME n:n];
}

- (long long)getNthEventIdFromTable:(NSString*) table n:(long long) n
{
    __block long long eventId = -1;

    [_dbQueue inDatabase:^(FMDatabase *db) {
        if (![db open]) {
            NSLog(@"Failed to open database during getNthEventIdFromTable %@", table);
            return;
        }

        NSString *querySQL = [NSString stringWithFormat:GET_NTH_EVENT_ID, ID_FIELD, table, n-1];
        FMResultSet *rs = [db executeQuery:querySQL];
        if (rs == nil) {
            NSLog(@"getNthEventIdFromTable %@ failed: %@", table, [db lastErrorMessage]);
            [db close];
            return;
        }

        if ([rs next]) {
            eventId = [rs longLongIntForColumnIndex:0];
        } else {
            NSLog(@"getNthEventIdFromTable %@ failed", table);
        }

        [db close];
    }];

    return eventId;
}

@end
