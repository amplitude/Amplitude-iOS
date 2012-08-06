//
//  DatabaseHelper.m
//  Hash Helper
//
//  Created by Spenser Skates on 8/1/12.
//
//

#import "DatabaseHelper.h"
#import "sqlite3.h"

static sqlite3 *databaseConnection;
static NSMutableDictionary *events;

@implementation DatabaseHelper

+(void)initialize:(NSString *)initialize
{
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSString *databaseDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
    NSString *databasePath = [databaseDirectory stringByAppendingPathComponent:@"com.sonalight.analytics.api"];
    
    if (sqlite3_open([databasePath UTF8String], &databaseConnection) != SQLITE_OK) {
        // Database not valid, delete and remake
        [manager removeItemAtPath:databasePath error:nil];
        if (sqlite3_open([databasePath UTF8String], &databaseConnection) != SQLITE_OK) {
            // Can't remake database, error
            NSLog(@"ERROR: Can't initialize analytics database at %@", databasePath);
        }
    }
    
    // Assume we have database connection by this point, initialize the table if it doesn't exist
    if (sqlite3_exec(databaseConnection,
                     "CREATE TABLE IF NOT EXISTS events (id INTEGER PRIMARY KEY AUTOINCREMENT, event TEXT);",
                     NULL, NULL, NULL) != SQLITE_OK) {
        NSLog(@"ERROR: Can't create analytics database at %@", databasePath);
    }
}

+(void)addEvent:(NSString *)event
{
    
}

+ (long)getNumberRows
{
    return 0L;
}


+ (id)getEvents
{
    return nil;
}

+ (void)removeEvents:(long) maxId
{
    
}




@end
