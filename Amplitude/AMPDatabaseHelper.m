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

@interface AMPDatabaseHelper()
@end

@implementation AMPDatabaseHelper

static AMPDatabaseHelper *instance = nil;
static sqlite3 *database = nil;

static NSString *const STORE_TABLE_NAME = @"store";
static NSString *const KEY_FIELD = @"key";
static NSString *const VALUE_FIELD = @"value";
static NSString *const EVENT_TABLE_NAME = @"events";
static NSString *const ID_FIELD = @"id";
static NSString *const EVENT_FIELD = @"event";

static NSString *const DROP_TABLE = @"DROP TABLE IF EXISTS %@;";
static NSString *const CREATE_STORE_TABLE = @"CREATE TABLE IF NOT EXISTS %@ (%@ TEXT PRIMARY KEY NOT NULL, %@ TEXT);";
static NSString *const CREATE_EVENT_TABLE = @"CREATE TABLE IF NOT EXISTS %@ (%@ INTEGER PRIMARY KEY AUTOINCREMENT, %@ TEXT);";
static NSString *const DELETE_EVENT_ID_COLUMN = @"DELETE FROM sqlite_sequence WHERE NAME='%@';";

static NSString *const INSERT_EVENT = @"INSERT INTO %@ (%@) VALUES ('%s');";
static NSString *const GET_EVENT_WITH_UPTOID_AND_LIMIT = @"SELECT %@, %@ FROM %@ WHERE %@ <= %ld LIMIT %d;";
static NSString *const GET_EVENT_WITH_UPTOID = @"SELECT %@, %@ FROM %@ WHERE %@ <= %ld;";
static NSString *const GET_EVENT_WITH_LIMIT = @"SELECT %@, %@ FROM %@ LIMIT %d;";
static NSString *const GET_EVENT = @"SELECT %@, %@ FROM %@;";
static NSString *const COUNT_EVENTS = @"SELECT COUNT(*) FROM %@;";
static NSString *const REMOVE_EVENTS = @"DELETE FROM %@ WHERE %@ <= %ld;";
static NSString *const REMOVE_EVENT = @"DELETE FROM %@ WHERE %@ = %ld;";
static NSString *const GET_NTH_EVENT_ID = @"SELECT %@ FROM %@ LIMIT 1 OFFSET %ld;";

static NSString *const INSERT_OR_REPLACE_KEY_VALUE = @"INSERT OR REPLACE INTO %@ (%@, %@) VALUES ('%s', '%s');";
static NSString *const GET_VALUE = @"SELECT %@, %@ FROM %@ WHERE %@ = '%s';";

+ (AMPDatabaseHelper*)getDatabaseHelper
{
    static AMPDatabaseHelper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AMPDatabaseHelper alloc] init];
        [instance createDB];
    });
    return instance;
}

- (BOOL)createDB
{
    NSString *databaseDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
    databasePath = [[NSString alloc] initWithString:[databaseDirectory stringByAppendingString:@"Amplitude.db"]];

    BOOL isSuccess = YES;
    // if ([[NSFileManager defaultManager] fileExistsAtPath:databasePath] == NO) {
        if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK){
            NSString *createEventsTable = [NSString stringWithFormat:CREATE_EVENT_TABLE, EVENT_TABLE_NAME, ID_FIELD, EVENT_FIELD];
            char *errMsg;
            if (sqlite3_exec(database, [createEventsTable UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
                isSuccess = NO;
                NSLog(@"Failed to create events table");
            }
            NSString *createStoreTable = [NSString stringWithFormat:CREATE_STORE_TABLE, STORE_TABLE_NAME, KEY_FIELD, VALUE_FIELD];
            if (sqlite3_exec(database, [createStoreTable UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
                isSuccess = NO;
                NSLog(@"Failed to create store table");
            }
            sqlite3_close(database);
        } else {
            isSuccess = NO;
            NSLog(@"Failed to open/create database");
        }
    // }
    return isSuccess;
}

- (void)resetDB
{
    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        char *errMsg;
        NSString *dropTableSQL;
        dropTableSQL = [NSString stringWithFormat:DROP_TABLE, STORE_TABLE_NAME];
        sqlite3_exec(database, [dropTableSQL UTF8String], NULL, NULL, &errMsg);
        dropTableSQL = [NSString stringWithFormat:DROP_TABLE, EVENT_TABLE_NAME];
        sqlite3_exec(database, [dropTableSQL UTF8String], NULL, NULL, &errMsg);
        dropTableSQL = [NSString stringWithFormat:DELETE_EVENT_ID_COLUMN, EVENT_TABLE_NAME];
        sqlite3_exec(database, [dropTableSQL UTF8String], NULL, NULL, &errMsg);
        sqlite3_close(database);
    }
    [self createDB];
}

- (void)delete
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:databasePath] == YES) {
        [[NSFileManager defaultManager] removeItemAtPath:databasePath error:NULL];
    }
}

- (long)addEvent:(NSString*) event
{
    long result = -1;

    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        NSString *insertSQL = [NSString stringWithFormat:INSERT_EVENT, EVENT_TABLE_NAME, EVENT_FIELD, [event UTF8String]];
        char *errMsg;
        if (sqlite3_exec(database, [insertSQL UTF8String], NULL, NULL, &errMsg) == SQLITE_OK){
            result = sqlite3_last_insert_rowid(database);
        } else {
            NSLog(@"addEvent failed");
        }
        sqlite3_close(database);
    }

    return result;
}

- (NSDictionary*)getEvents:(long) upToId limit:(int) limit
{
    long maxId = -1;
    NSMutableArray *events = [NSMutableArray array];

    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        NSString *querySQL;
        if (upToId > 0 && limit > 0) {
            querySQL = [NSString stringWithFormat:GET_EVENT_WITH_UPTOID_AND_LIMIT, ID_FIELD, EVENT_FIELD, EVENT_TABLE_NAME, ID_FIELD, upToId, limit];
        } else if (upToId > 0) {
            querySQL = [NSString stringWithFormat:GET_EVENT_WITH_UPTOID, ID_FIELD, EVENT_FIELD, EVENT_TABLE_NAME, ID_FIELD, upToId];
        } else if (limit > 0) {
            querySQL = [NSString stringWithFormat:GET_EVENT_WITH_LIMIT, ID_FIELD, EVENT_FIELD, EVENT_TABLE_NAME, limit];
        } else {
            querySQL = [NSString stringWithFormat:GET_EVENT, ID_FIELD, EVENT_FIELD, EVENT_TABLE_NAME];
        }
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [querySQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                int eventId = sqlite3_column_int(statement, 0);
                char *eventChars = (char *) sqlite3_column_text(statement, 1);
                NSString *eventString = [[NSString alloc] initWithUTF8String:eventChars];
                NSData *eventData = [eventString dataUsingEncoding:NSUTF8StringEncoding];
                id eventImmutable = [NSJSONSerialization JSONObjectWithData:eventData options:0 error:NULL];
                if (eventImmutable == nil) {
                    continue;
                }
                NSMutableDictionary *event = [eventImmutable mutableCopy];
                [event setValue:[NSNumber numberWithInt:eventId] forKey:@"event_id"];
                [events addObject:event];
                maxId = eventId;
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(database);
    }

    return [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithLong:maxId], @"maxId", events, @"events", nil];
}

- (long)insertOrReplaceKeyValue:(NSString*) key value:(NSString*) value
{
    long result = -1;

    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        NSString *insertSQL = [NSString stringWithFormat:INSERT_OR_REPLACE_KEY_VALUE, STORE_TABLE_NAME, KEY_FIELD, VALUE_FIELD, [key UTF8String], [value UTF8String]];
        char *errMsg;
        if (sqlite3_exec(database, [insertSQL UTF8String], NULL, NULL, &errMsg) == SQLITE_OK){
            result = sqlite3_last_insert_rowid(database);
        } else {
            NSLog(@"insertOrReplaceKeyValue failed");
        }
        sqlite3_close(database);
    }

    return result;
}

- (NSString*)getValue:(NSString*) key
{
    NSString *value = nil;

    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:GET_VALUE, KEY_FIELD, VALUE_FIELD, STORE_TABLE_NAME, KEY_FIELD, [key UTF8String]];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [querySQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                char *valueChars = (char *) sqlite3_column_text(statement, 1);
                value = [[NSString alloc] initWithUTF8String:valueChars];
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(database);
    }

    return value;
}

- (long)getEventCount
{
    long count = 0;

    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:COUNT_EVENTS, EVENT_TABLE_NAME];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [querySQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                count = sqlite3_column_int64(statement, 0);
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(database);
    }

    return count;
}

- (void)removeEvents:(long) maxId
{
    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        NSString *removeSQL = [NSString stringWithFormat:REMOVE_EVENTS, EVENT_TABLE_NAME, ID_FIELD, maxId];
        char* errMsg;
        if (sqlite3_exec(database, [removeSQL UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
            NSLog(@"Unable to remove events");
        }
        sqlite3_close(database);
    }
}

- (void)removeEvent:(long) eventId
{
    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        NSString *removeSQL = [NSString stringWithFormat:REMOVE_EVENT, EVENT_TABLE_NAME, ID_FIELD, eventId];
        char* errMsg;
        if (sqlite3_exec(database, [removeSQL UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
            NSLog(@"Unable to remove event");
        }
        sqlite3_close(database);
    }
}


- (long)getNthEventId:(long) n
{
    long eventId = -1;

    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        NSString *querySQL = [NSString stringWithFormat:GET_NTH_EVENT_ID, ID_FIELD, EVENT_TABLE_NAME, n-1];
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [querySQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            if (sqlite3_step(statement) == SQLITE_ROW) {
                eventId = sqlite3_column_int64(statement, 0);
            }
            sqlite3_finalize(statement);
        }
        sqlite3_close(database);
    }

    return eventId;
}

@end