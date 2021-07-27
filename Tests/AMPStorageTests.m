//
//  AMPStorageTests.m
//
//
//  Created by Dante Tam on 7/22/21.
//  Copyright © 2018 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMPStorage.h"

@interface AMPStorageTests : XCTestCase
    
@end

@implementation AMPStorageTests {}

NSString *exampleEvent = @"{\n    \"api_properties\" :     {\n        \"ios_idfv\" : \"2D623DDA-4AC8-4A1E-BB4B-8264CB2AB31A\"\n    },\n    \"carrier\" : \"Unknown\",\n    \"country\" : \"United States\",\n    \"device_id\" : \"8C027883-5AA1-43F8-8FB8-7837EBE519C4\",\n    \"event_type\" : \"testEvent\",\n \"user_id\" : \"userId\",\n    \"user_properties\" :     {\n    },\n    \"uuid\" : \"41EEDEBB-3A7E-4EDF-BEFC-689D7912BCF3\"\n}";

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
    NSString* dir = [AMPStorage getAppStorageAmpDir:@""];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSArray *fileArray = [fileMgr contentsOfDirectoryAtPath:dir error:nil];
    for (NSString *filename in fileArray)  {
        [fileMgr removeItemAtPath:[dir stringByAppendingPathComponent:filename] error:NULL];
    }
}

- (void)testGetAppStorageAmpDir {
    NSString* dir = [AMPStorage getAppStorageAmpDir:@"INSTANCE_NAME"];
    NSString* expectedDir = @"/Application Support/com.apple.dt.xctest.tool/INSTANCE_NAME";
    XCTAssertNotEqual([dir rangeOfString:expectedDir].location, NSNotFound);
    
    dir = [AMPStorage getAppStorageAmpDir:@""];
    expectedDir = @"/Application Support/com.apple.dt.xctest.tool/";
    XCTAssertNotEqual([dir rangeOfString:expectedDir].location, NSNotFound);
    
    dir = [AMPStorage getAppStorageAmpDir:NULL];
    expectedDir = @"/Application Support/com.apple.dt.xctest.tool/";
    XCTAssertNotEqual([dir rangeOfString:expectedDir].location, NSNotFound);
}

- (void)testGetDefaultEventsFile {
    NSString* dir = [AMPStorage getDefaultEventsFile:@"INSTANCE_NAME"];
    NSString* expectedDir = @"/Application Support/com.apple.dt.xctest.tool/INSTANCE_NAME/amplitude_event_storage.txt";
    XCTAssertNotEqual([dir rangeOfString:expectedDir].location, NSNotFound);

    dir = [AMPStorage getDefaultEventsFile:@""];
    NSLog(@"%@", dir);
    expectedDir = @"/Application Support/com.apple.dt.xctest.tool/DEFAULT_INSTANCE/amplitude_event_storage.txt";
    XCTAssertNotEqual([dir rangeOfString:expectedDir].location, NSNotFound);
    
    dir = [AMPStorage getDefaultEventsFile:NULL];
    expectedDir = @"/Application Support/com.apple.dt.xctest.tool/DEFAULT_INSTANCE/amplitude_event_storage.txt";
    XCTAssertNotEqual([dir rangeOfString:expectedDir].location, NSNotFound);
}

- (void)testGetDefaultIdentifyFile {
    NSString* dir = [AMPStorage getDefaultIdentifyFile:@"INSTANCE_NAME"];
    NSString* expectedDir = @"/Application Support/com.apple.dt.xctest.tool/INSTANCE_NAME/amplitude_identify_storage.txt";
    XCTAssertNotEqual([dir rangeOfString:expectedDir].location, NSNotFound);

    dir = [AMPStorage getDefaultIdentifyFile:@""];
    NSLog(@"%@", dir);
    expectedDir = @"/Application Support/com.apple.dt.xctest.tool/DEFAULT_INSTANCE/amplitude_identify_storage.txt";
    XCTAssertNotEqual([dir rangeOfString:expectedDir].location, NSNotFound);
    
    dir = [AMPStorage getDefaultIdentifyFile:NULL];
    expectedDir = @"/Application Support/com.apple.dt.xctest.tool/DEFAULT_INSTANCE/amplitude_identify_storage.txt";
    XCTAssertNotEqual([dir rangeOfString:expectedDir].location, NSNotFound);
}

- (void)testStoreEvent {
    [AMPStorage storeEvent:exampleEvent instanceName:@"INSTANCE_NAME"];
    NSString *eventsFilePath = [AMPStorage getDefaultEventsFile:@"INSTANCE_NAME"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    XCTAssertTrue([fileManager fileExistsAtPath:eventsFilePath]);
    
    NSString *content = [NSString stringWithContentsOfFile:eventsFilePath encoding:NSUTF8StringEncoding error:nil];
    XCTAssertNotEqual([content rangeOfString:exampleEvent].location, NSNotFound);
    XCTAssertNotEqual([content rangeOfString:@"{ \"batch\":"].location, NSNotFound);
}

- (void)testStoreIdentify {
    [AMPStorage storeIdentify:exampleEvent instanceName:@"INSTANCE_NAME"];
    NSString *identifyFilePath = [AMPStorage getDefaultIdentifyFile:@"INSTANCE_NAME"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    XCTAssertTrue([fileManager fileExistsAtPath:identifyFilePath]);
    
    NSString *content = [NSString stringWithContentsOfFile:identifyFilePath encoding:NSUTF8StringEncoding error:nil];
    XCTAssertNotEqual([content rangeOfString:exampleEvent].location, NSNotFound);
    XCTAssertNotEqual([content rangeOfString:@"{ \"batch\":"].location, NSNotFound);
}

/* This method also tests
 + (void)start:(NSString *)path
 + (void)finish:(NSString *)path
 + (void)remove:(NSString *)path
 */
- (void)testStoreEventAndFinishAtUrl {
    NSString *customPath = [AMPStorage getAppStorageAmpDir:@""];
    customPath = [customPath stringByAppendingString:@"/custom_path/nested_path"];
    NSURL *url = [NSURL fileURLWithPath:customPath];
    [AMPStorage storeEventAtUrl:url event:exampleEvent];
    [AMPStorage storeEventAtUrl:url event:exampleEvent];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    XCTAssertTrue([fileManager fileExistsAtPath:customPath]);
    
    [AMPStorage finish:customPath];
    
    NSString *content = [NSString stringWithContentsOfFile:customPath encoding:NSUTF8StringEncoding error:nil];
    XCTAssertNotEqual([content rangeOfString:exampleEvent].location, NSNotFound);
    XCTAssertNotEqual([content rangeOfString:@"{ \"batch\":"].location, NSNotFound);
    
    NSMutableArray *finishedFileDict = [AMPStorage getEventsFromDisk:customPath];
    NSDictionary *secondEvent = finishedFileDict[1];
    XCTAssertEqualObjects([secondEvent objectForKey:@"event_type"], @"testEvent");
    
    //Test a file that has not been finished
    [AMPStorage remove:customPath];
    XCTAssertFalse([fileManager fileExistsAtPath:customPath]);
    
    [AMPStorage storeEventAtUrl:url event:exampleEvent];
    [AMPStorage storeEventAtUrl:url event:exampleEvent];
    XCTAssertTrue([fileManager fileExistsAtPath:customPath]);
    finishedFileDict = [AMPStorage getEventsFromDisk:customPath];
    secondEvent = finishedFileDict[1];
    XCTAssertEqualObjects([secondEvent objectForKey:@"event_type"], @"testEvent");
}

@end