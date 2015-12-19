//
//  AMPDatabaseHelper.m
//  Amplitude
//
//  Created by Daniel Jih on 9/9/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "AMPARCMacros.h"
#import "AMPDatabaseHelper.h"
#import "AMPARCMacros.h"

@interface AMPDatabaseHelper()
@end

@implementation AMPDatabaseHelper
{
    NSString *_databasePath;
    BOOL _databaseCreated;
    sqlite3 *_database;
    dispatch_queue_t _queue;
}

static NSString *const QUEUE_NAME = @"com.amplitude.db.queue";
static const void * const kDispatchQueueKey = &kDispatchQueueKey; // some unique key for dispatch queue

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
static NSString *const DELETE_KEY = @"DELETE FROM %@ WHERE %@ = ?;";
static NSString *const GET_VALUE = @"SELECT %@, %@ FROM %@ WHERE %@ = ?;";


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
        _queue = dispatch_queue_create([QUEUE_NAME UTF8String], NULL);
        dispatch_queue_set_specific(_queue, kDispatchQueueKey, (__bridge void *)self, NULL);
        if (![[NSFileManager defaultManager] fileExistsAtPath:_databasePath]) {
            [self createTables];
        }
    }
    return self;
}

- (void)dealloc
{
    SAFE_ARC_RELEASE(_databasePath);
    if (_queue) {
        SAFE_ARC_DISPATCH_RELEASE(_queue);
        _queue = NULL;
    }
    SAFE_ARC_SUPER_DEALLOC();
}

/**
 * Run queries in the queue. Needed because sqlite is not thread-safe.
 * Handles opening and closing of database for the block.
 * Returns YES if successfully opened database, else NO.
 */
- (BOOL)inDatabase:(void (^)(sqlite3 *db))block
{
    // check that the block doesn't isn't calling inDatabase itself, which would lead to a deadlock
    AMPDatabaseHelper *currentSyncQueue = (__bridge id)dispatch_get_specific(kDispatchQueueKey);
    if (currentSyncQueue == self) {
        NSLog(@"Should not call inDatabase in block passed to inDatabase");
        return NO;
    }

    __block BOOL success = YES;

    dispatch_sync(_queue, ^() {
        if (sqlite3_open([_databasePath UTF8String], &_database) != SQLITE_OK) {
            NSLog(@"Failed to open database");
            success = NO;
            return;
        }
        block(_database);
        sqlite3_close(_database);
    });

    return success;
}

// Assumes db is already opened
- (BOOL)execSQLString:(sqlite3*) db SQLString:(NSString*) SQLString
{
    char *errMsg;
    if (sqlite3_exec(db, [SQLString UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
        NSLog(@"Failed to exec sql string %@: %s", SQLString, errMsg);
        return NO;
    }
    return YES;
}

- (BOOL)createTables
{
    __block BOOL success = YES;

    success &= [self inDatabase:^(sqlite3 *db) {
        NSString *createEventsTable = [NSString stringWithFormat:CREATE_EVENT_TABLE, EVENT_TABLE_NAME, ID_FIELD, EVENT_FIELD];
        success &= [self execSQLString:db SQLString:createEventsTable];

        NSString *createIdentifysTable = [NSString stringWithFormat:CREATE_IDENTIFY_TABLE, IDENTIFY_TABLE_NAME, ID_FIELD, EVENT_FIELD];
        success &= [self execSQLString:db SQLString:createIdentifysTable];

        NSString *createStoreTable = [NSString stringWithFormat:CREATE_STORE_TABLE, STORE_TABLE_NAME, KEY_FIELD, VALUE_FIELD];
        success &= [self execSQLString:db SQLString:createStoreTable];

        NSString *createLongStoreTable = [NSString stringWithFormat:CREATE_LONG_STORE_TABLE, LONG_STORE_TABLE_NAME, KEY_FIELD, VALUE_FIELD];
        success &= [self execSQLString:db SQLString:createLongStoreTable];
    }];

    return success;
}

- (BOOL)upgrade:(int) oldVersion newVersion:(int) newVersion
{
    __block BOOL success = YES;

    success &= [self inDatabase:^(sqlite3 *db) {
        switch (oldVersion) {
            case 0:
            case 1: {
                NSString *createEventsTable = [NSString stringWithFormat:CREATE_EVENT_TABLE, EVENT_TABLE_NAME, ID_FIELD, EVENT_FIELD];
                success &= [self execSQLString:db SQLString:createEventsTable];

                NSString *createStoreTable = [NSString stringWithFormat:CREATE_STORE_TABLE, STORE_TABLE_NAME, KEY_FIELD, VALUE_FIELD];
                success &= [self execSQLString:db SQLString:createStoreTable];

                NSString *createLongStoreTable = [NSString stringWithFormat:CREATE_LONG_STORE_TABLE, LONG_STORE_TABLE_NAME, KEY_FIELD, VALUE_FIELD];
                success &= [self execSQLString:db SQLString:createLongStoreTable];
                if (newVersion <= 2) break;
            }
            case 2: {
                NSString *createIdentifysTable = [NSString stringWithFormat:CREATE_IDENTIFY_TABLE, IDENTIFY_TABLE_NAME, ID_FIELD, EVENT_FIELD];
                success &= [self execSQLString:db SQLString:createIdentifysTable];
                if (newVersion <= 3) break;
            }
            default:
                success = NO;
        }
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

    success &= [self inDatabase:^(sqlite3 *db) {
        NSString *dropEventTableSQL = [NSString stringWithFormat:DROP_TABLE, EVENT_TABLE_NAME];
        success &= [self execSQLString:db SQLString:dropEventTableSQL];

        NSString *dropIdentifyTableSQL = [NSString stringWithFormat:DROP_TABLE, IDENTIFY_TABLE_NAME];
        success &= [self execSQLString:db SQLString:dropIdentifyTableSQL];

        NSString *dropStoreTableSQL = [NSString stringWithFormat:DROP_TABLE, STORE_TABLE_NAME];
        success &= [self execSQLString:db SQLString:dropStoreTableSQL];

        NSString *dropLongStoreTableSQL = [NSString stringWithFormat:DROP_TABLE, LONG_STORE_TABLE_NAME];
        success &= [self execSQLString:db SQLString:dropLongStoreTableSQL];
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
    if ([[NSFileManager defaultManager] fileExistsAtPath:_databasePath] == YES) {
        return [[NSFileManager defaultManager] removeItemAtPath:_databasePath error:NULL];
    }
    return YES;
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
    __block BOOL success = YES;

    success &= [self inDatabase:^(sqlite3 *db) {
        sqlite3_stmt *stmt;
        NSString *insertSQL = [NSString stringWithFormat:INSERT_EVENT, table, EVENT_FIELD];
        if (sqlite3_prepare_v2(db, [insertSQL UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
            NSLog(@"Failed to prepare insert statement for adding event to table %@", table);
            success = NO;
            return;
        }

        if (sqlite3_bind_text(stmt, 1, [event UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
            NSLog(@"Failed to bind event text to insert statement for adding event to table %@", table);
            sqlite3_finalize(stmt);
            success = NO;
            return;
        }

        if (sqlite3_step(stmt) != SQLITE_DONE) {
            NSLog(@"Failed to execute prepared statement to add event to table %@", table);
            success = NO;
        }

        sqlite3_finalize(stmt);
    }];

    if (!success) {
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

    [self inDatabase:^(sqlite3 *db) {
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

        sqlite3_stmt *stmt;
        if (sqlite3_prepare_v2(db, [querySQL UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
            NSLog(@"Failed to prepare select statement for getEventsFromTable %@", table);
            return;
        }

        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSInteger eventId = sqlite3_column_int64(stmt, 0);
            NSString *eventString = [NSString stringWithUTF8String:(char *)sqlite3_column_text(stmt, 1)];
            NSData *eventData = [eventString dataUsingEncoding:NSUTF8StringEncoding];

            id eventImmutable = [NSJSONSerialization JSONObjectWithData:eventData options:0 error:NULL];
            if (eventImmutable == nil) {
                NSLog(@"Error JSON deserialization of event id %ld from table %@", eventId, table);
                continue;
            }

            NSMutableDictionary *event = [eventImmutable mutableCopy];
            [event setValue:[NSNumber numberWithInteger:eventId] forKey:@"event_id"];
            [events addObject:event];
            SAFE_ARC_RELEASE(event);
        }

        sqlite3_finalize(stmt);
    }];

    return SAFE_ARC_AUTORELEASE(events);
}

- (BOOL)insertOrReplaceKeyValue:(NSString*) key value:(NSString*) value
{
    if (value == nil) return [self deleteKeyFromTable:STORE_TABLE_NAME key:key];
    return [self insertOrReplaceKeyValueToTable:STORE_TABLE_NAME key:key value:value];
}

- (BOOL)insertOrReplaceKeyLongValue:(NSString *) key value:(NSNumber*) value
{
    if (value == nil) return [self deleteKeyFromTable:LONG_STORE_TABLE_NAME key:key];
    return [self insertOrReplaceKeyValueToTable:LONG_STORE_TABLE_NAME key:key value:value];
}

- (BOOL)insertOrReplaceKeyValueToTable:(NSString*) table key:(NSString*) key value:(NSObject*) value
{
    __block BOOL success = YES;

    success &= [self inDatabase:^(sqlite3 *db) {
        NSString *insertSQL = [NSString stringWithFormat:INSERT_OR_REPLACE_KEY_VALUE, table, KEY_FIELD, VALUE_FIELD];
        sqlite3_stmt *stmt;

        if (sqlite3_prepare_v2(db, [insertSQL UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
            NSLog(@"Failed to prepare insert statement for adding key %@ value %@ to table %@", key, value, table);
            success = NO;
            return;
        }

        success &= sqlite3_bind_text(stmt, 1, [key UTF8String], -1, SQLITE_STATIC) == SQLITE_OK;
        if ([table isEqualToString:STORE_TABLE_NAME]) {
            success &= sqlite3_bind_text(stmt, 2, [(NSString *)value UTF8String], -1, SQLITE_STATIC) == SQLITE_OK;
        } else {
            success &= sqlite3_bind_int64(stmt, 2, [(NSNumber*)value integerValue]) == SQLITE_OK;
        }

        if (!success) {
            NSLog(@"Failed to bind key %@ value %@ to statement", key, value);
            sqlite3_finalize(stmt);
            return;
        }

        if (sqlite3_step(stmt) != SQLITE_DONE) {
            NSLog(@"Failed to execute statement to insert key %@ value %@ to table %@", key, value, table);
            success = NO;
        }

        sqlite3_finalize(stmt);
    }];

    if (!success) {
        [self resetDB:NO]; // not much we can do, just start fresh
    }
    return success;
}

- (BOOL) deleteKeyFromTable:(NSString*) table key:(NSString*) key
{
    __block BOOL success = YES;

    success &= [self inDatabase:^(sqlite3 *db) {
        NSString *deleteSQL = [NSString stringWithFormat:DELETE_KEY, table, KEY_FIELD];
        sqlite3_stmt *stmt;

        if (sqlite3_prepare_v2(db, [deleteSQL UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
            NSLog(@"Could not prepare statement to delete key %@ from table %@", key, table);
            success = NO;
            return;
        }

        if (sqlite3_bind_text(stmt, 1, [key UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
            NSLog(@"Failed to bind key to statement to delete key %@ from table %@", key, table);
            sqlite3_finalize(stmt);
            success = NO;
            return;
        }

        if (sqlite3_step(stmt) != SQLITE_DONE) {
            NSLog(@"Failed to execute statement to delete key %@ from table %@", key, table);
            success = NO;
        }

        sqlite3_finalize(stmt);
    }];

    if (!success) {
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

    [self inDatabase:^(sqlite3 *db) {
        NSString *querySQL = [NSString stringWithFormat:GET_VALUE, KEY_FIELD, VALUE_FIELD, table, KEY_FIELD];
        sqlite3_stmt *stmt;

        if (sqlite3_prepare_v2(db, [querySQL UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
            NSLog(@"Failed to prepare statement to get value for key %@ from table %@", key, table);
            return;
        }

        if (sqlite3_bind_text(stmt, 1, [key UTF8String], -1, SQLITE_STATIC) != SQLITE_OK) {
            NSLog(@"Failed to bind key %@ to stmt when getValueFromTable %@", key, table);
            sqlite3_finalize(stmt);
            return;
        }

        if (sqlite3_step(stmt) == SQLITE_ROW) {
            if (sqlite3_column_type(stmt, 1) != SQLITE_NULL) {
                if ([table isEqualToString:STORE_TABLE_NAME]) {
                    value = [[NSString alloc] initWithUTF8String:(char*)sqlite3_column_text(stmt, 1)];
                } else {
                    value = [[NSNumber alloc] initWithInteger:sqlite3_column_int64(stmt, 1)];
                }
            }
        } else {
            NSLog(@"Failed to get value for key %@ from table %@", key, table);
        }

        sqlite3_finalize(stmt);
    }];

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

    [self inDatabase:^(sqlite3 *db) {
        NSString *querySQL = [NSString stringWithFormat:COUNT_EVENTS, table];
        sqlite3_stmt *stmt;

        if (sqlite3_prepare_v2(db, [querySQL UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
            NSLog(@"Failed to prepare statement to get event count from table %@", table);
            return;
        }

        if (sqlite3_step(stmt) == SQLITE_ROW) {
            count = sqlite3_column_int(stmt, 0);
        } else {
            NSLog(@"Failed to get event count from table %@", table);
        }

        sqlite3_finalize(stmt);
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
    __block BOOL success = YES;

    success &= [self inDatabase:^(sqlite3 *db) {
        NSString *removeSQL = [NSString stringWithFormat:REMOVE_EVENTS, table, ID_FIELD, maxId];
        success &= [self execSQLString:db SQLString:removeSQL];
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
    __block BOOL success = YES;

    success &= [self inDatabase:^(sqlite3 *db) {
        NSString *removeSQL = [NSString stringWithFormat:REMOVE_EVENT, table, ID_FIELD, eventId];
        success &= [self execSQLString:db SQLString:removeSQL];
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

    [self inDatabase:^(sqlite3 *db) {
        NSString *querySQL = [NSString stringWithFormat:GET_NTH_EVENT_ID, ID_FIELD, table, n-1];
        sqlite3_stmt *stmt;

        if (sqlite3_prepare_v2(db, [querySQL UTF8String], -1, &stmt, NULL) != SQLITE_OK) {
            NSLog(@"Failed to prepare statement to getNthEventIdFromTable");
            return;
        }

        if (sqlite3_step(stmt) == SQLITE_ROW) {
            eventId = sqlite3_column_int64(stmt, 0);
        } else {
            NSLog(@"Failed to getNthEventIdFromTable");
        }

        sqlite3_finalize(stmt);
    }];

    return eventId;
}

@end
