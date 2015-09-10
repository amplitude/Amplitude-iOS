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

+ (AMPDatabaseHelper *)getDatabaseHelper
{
    /*
    if (!instance) {
        instance = [[super allocWithZone:NULL]init];
        [instance createDB];
    }
    */
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
    databasePath = SAFE_ARC_RETAIN([[NSString alloc] initWithString:[databaseDirectory stringByAppendingString:@"Amplitude.db"]]);

    BOOL isSuccess = YES;

    if ([[NSFileManager defaultManager] fileExistsAtPath: databasePath] == NO) {
        if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK){
            NSString *createEventsTable = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ TEXT PRIMARY KEY NOT NULL, %@ TEXT);", STORE_TABLE_NAME, KEY_FIELD, VALUE_FIELD];
            char *errMsg;
            if (sqlite3_exec(database, [createEventsTable UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
                isSuccess = NO;
                NSLog(@"Failed to create events table");
            }
            NSString *createStoreTable = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ INTEGER PRIMARY KEY AUTOINCREMENT, %@ TEXT);", EVENT_TABLE_NAME, ID_FIELD, EVENT_FIELD];
            if (sqlite3_exec(database, [createStoreTable UTF8String], NULL, NULL, &errMsg) != SQLITE_OK) {
                isSuccess = NO;
                NSLog(@"Failed to create store table");
            }
            sqlite3_close(database);
            return isSuccess;
        }

        isSuccess = NO;
        NSLog(@"Failed to open/create database");
    }
    return isSuccess;
}

- (void)resetDB
{
    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        NSString *dropTableSQL;
        dropTableSQL = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@;", STORE_TABLE_NAME];
        sqlite3_exec(database, [dropTableSQL UTF8String], NULL, NULL, NULL);
        dropTableSQL = [NSString stringWithFormat:@"DROP TABLE IF EXISTS %@;", EVENT_TABLE_NAME];
        sqlite3_exec(database, [dropTableSQL UTF8String], NULL, NULL, NULL);
        sqlite3_close(database);
    }
}

- (int)addEvent:(NSString*) event
{
    int result = -1;

    if (sqlite3_open([databasePath UTF8String], &database) == SQLITE_OK) {
        NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES ('%@')", EVENT_TABLE_NAME, EVENT_FIELD, event];
        char *errMsg;
        if (sqlite3_exec(database, [insertSQL UTF8String], NULL, NULL, &errMsg) == SQLITE_OK){
            result = sqlite3_changes(database);
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
            querySQL = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@ WHERE %@ <= %ld LIMIT %d;", ID_FIELD, EVENT_FIELD, EVENT_TABLE_NAME, ID_FIELD, upToId, limit];
        } else if (upToId > 0) {
            querySQL = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@ WHERE %@ <= %ld;", ID_FIELD, EVENT_FIELD, EVENT_TABLE_NAME, ID_FIELD, upToId];
        } else if (limit > 0) {
            querySQL = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@ LIMIT %d;", ID_FIELD, EVENT_FIELD, EVENT_TABLE_NAME, limit];
        } else {
            querySQL = [NSString stringWithFormat:@"SELECT %@, %@ FROM %@ ORDER BY ID DESC;", ID_FIELD, EVENT_FIELD, EVENT_TABLE_NAME];
        }
        sqlite3_stmt *statement;
        if (sqlite3_prepare_v2(database, [querySQL UTF8String], -1, &statement, NULL) == SQLITE_OK) {
            while (sqlite3_step(statement) == SQLITE_ROW) {
                int eventId = sqlite3_column_int(statement, 0);
                char *eventChars = (char *) sqlite3_column_text(statement, 1);
                NSString *eventString = [[NSString alloc] initWithUTF8String:eventChars];
                NSData *eventData = [NSData dataWithBytes:[eventString UTF8String] length:[eventString length]];
                NSMutableDictionary *event = [NSJSONSerialization JSONObjectWithData:eventData options:NSJSONReadingMutableContainers error:NULL];
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

@end