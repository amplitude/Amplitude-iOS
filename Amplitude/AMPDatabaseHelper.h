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
- (int)addEvent:(NSString*) event;
- (NSDictionary*)getEvents:(long) upToId limit:(int) limit;

@end

