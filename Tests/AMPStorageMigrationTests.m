//
//  AMPStorageMigrationTests.m
//  Amplitude
//
//  Created by Hao Yu on 8/24/21.
//  Copyright © 2021 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Amplitude.h"
#import "AMPDatabaseHelper.h"
#import "AMPStorage.h"
#import "Amplitude+Test.h"
#import "AMPStorage.h"

@interface Amplitude (Tests)

@property (nonatomic, strong) NSMutableArray *eventsBuffer;
@property (nonatomic, strong) NSMutableArray *identifyBuffer;
@property (nonatomic, assign) long long previousSessionId;
+ (NSString *)getDataStorageKey:(NSString *)key instanceName:(NSString *)instanceName;
+ (BOOL)hasDatabase:(NSString *)instanceName;
+ (void)cleanUp;

@end

@interface AMPStorageMigrationTests : XCTestCase

@end

@implementation AMPStorageMigrationTests

NSString *testEvent = @"{\n    \"api_properties\" :     {\n        \"ios_idfv\" : \"2D623DDA-4AC8-4A1E-BB4B-8264CB2AB31A\"\n    },\n    \"carrier\" : \"Unknown\",\n    \"country\" : \"United States\",\n    \"device_id\" : \"8C027883-5AA1-43F8-8FB8-7837EBE519C4\",\n    \"event_type\" : \"testEvent\",\n \"user_id\" : \"userId\",\n    \"user_properties\" :     {\n    },\n    \"uuid\" : \"41EEDEBB-3A7E-4EDF-BEFC-689D7912BCF3\"\n,    \"sequence_number\" : \"1\"}";
NSString *testIdentify = @"{\"event_type\" : \"$identify\",    \"sequence_number\" : \"1\"}";

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    [Amplitude cleanUp];
}

- (void)testMigration {
    AMPDatabaseHelper *databaseHelper = [AMPDatabaseHelper getDatabaseHelper:@"migration_test"];
    [databaseHelper resetDB:NO];
    NSString *userId = @"test@gmail.com";
    NSString *deviceId = @"8C027883-5AA1-43F8-8FB8-7837EBE519C4";
    long long sequenceNumber = 2;
    BOOL optOut = NO;
    NSNumber *timestamp = [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000];
    
    [databaseHelper addEvent:testEvent];
    [databaseHelper addIdentify:testIdentify];
    [databaseHelper insertOrReplaceKeyValue:@"user_id" value:userId];
    [databaseHelper insertOrReplaceKeyValue:@"device_id" value:deviceId];
    [databaseHelper insertOrReplaceKeyLongValue:@"opt_out" value:[NSNumber numberWithBool:optOut]];
    [databaseHelper insertOrReplaceKeyLongValue:@"previous_session_id" value:timestamp];
    [databaseHelper insertOrReplaceKeyLongValue:@"previous_session_time" value:timestamp];
    [databaseHelper insertOrReplaceKeyLongValue:@"sequence_number" value:[NSNumber numberWithLongLong:sequenceNumber]];
    
    XCTAssertEqual([databaseHelper getEventCount], 1);
    XCTAssertEqual([databaseHelper getIdentifyCount], 1);
    
    Amplitude *amplitude = [Amplitude instanceWithName:@"migration_test"];
    [amplitude initializeApiKey:@"000000"];
    [amplitude flushQueueWithQueue:amplitude.initializerQueue];
    
    XCTAssertEqual([AMPStorage hasFileStorage:@"migration_test"], NO);
    XCTAssertEqual([AMPDatabaseHelper hasDatabase:@"migration_test"], YES);
    
    XCTAssertEqual([amplitude.eventsBuffer count], 1);
    XCTAssertEqual([amplitude.identifyBuffer count], 1);
    XCTAssertEqual([databaseHelper getEventCount], 0);
    XCTAssertEqual([databaseHelper getIdentifyCount], 0);
    
    XCTAssertEqualObjects(amplitude.userId, userId);
    XCTAssertEqualObjects([amplitude getDeviceId], deviceId);
    XCTAssertEqual([amplitude optOut], optOut);
    XCTAssertEqual([amplitude lastEventTime], timestamp);
    XCTAssertEqual([amplitude previousSessionId], [timestamp longLongValue]);
    XCTAssertEqual([[[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"sequence_number" instanceName:amplitude.instanceName]] longLongValue], sequenceNumber);
    
    [amplitude flushQueue];
    XCTAssertEqual([[amplitude getAllEventsWithInstanceName:amplitude.instanceName] count], 1);
    XCTAssertEqual([[amplitude getAllIdentifyWithInstanceName:amplitude.instanceName] count], 1);
    
    [databaseHelper deleteDB];
    databaseHelper = nil;
}

@end
