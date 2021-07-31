//
//  AmplitudeTests.m
//  Amplitude
//
//  Created by Daniel Jih on 8/7/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Amplitude.h"
#import "AMPConstants.h"
#import "Amplitude+Test.h"
#import "BaseTestCase.h"
#import "AMPDeviceInfo.h"
#import "AMPUtils.h"
#import "AMPTrackingOptions.h"
#import "AMPStorage.h"

@interface Amplitude (Tests)

@property (nonatomic, assign) BOOL updatingCurrently;
@property (nonatomic, strong) NSMutableArray *eventsBuffer;
@property (nonatomic, strong) NSMutableArray *identifyBuffer;
@property (nonatomic, assign) long long maxEventSequenceNumber;

- (NSDictionary*)mergeEventsAndIdentifys:(NSMutableArray*)events identifys:(NSMutableArray*)identifys numEvents:(long) numEvents;
- (id)truncate:(id) obj;
- (long long)getNextSequenceNumber;
+ (NSString *)getDataStorageKey:(NSString *)key instanceName:(NSString *)instanceName;
+ (void)cleanUp;
+ (void)cleanUpFileStorage;

@end

@interface AmplitudeTests : BaseTestCase

@end

@implementation AmplitudeTests {
    id _sharedSessionMock;
    int _connectionCallCount;
}

- (void)setUp {
    [super setUp];
    _sharedSessionMock = [OCMockObject partialMockForObject:[NSURLSession sharedSession]];
    _connectionCallCount = 0;
    [self.amplitude initializeApiKey:apiKey];
    [Amplitude cleanUp];
}

- (void)tearDown {
    [_sharedSessionMock stopMocking];
    [Amplitude cleanUp];
}

- (void)setupAsyncResponse: (NSMutableDictionary*) serverResponse {
    [[[_sharedSessionMock stub] andDo:^(NSInvocation *invocation) {
        _connectionCallCount++;
        void (^handler)(NSURLResponse*, NSData*, NSError*);
        [invocation getArgument:&handler atIndex:3];
        handler(serverResponse[@"data"], serverResponse[@"response"], serverResponse[@"error"]);
    }] dataTaskWithRequest:OCMOCK_ANY completionHandler:OCMOCK_ANY];
}

- (void)testInstanceWithName {
    Amplitude *a = [Amplitude instance];
    Amplitude *b = [Amplitude instanceWithName:@""];
    Amplitude *c = [Amplitude instanceWithName:nil];
    Amplitude *e = [Amplitude instanceWithName:kAMPDefaultInstance];
    Amplitude *f = [Amplitude instanceWithName:@"app1"];
    Amplitude *g = [Amplitude instanceWithName:@"app2"];

    XCTAssertEqual(a, b);
    XCTAssertEqual(b, c);
    XCTAssertEqual(c, e);
    XCTAssertEqual(e, a);
    XCTAssertEqual(e, [Amplitude instance]);
    XCTAssertNotEqual(e,f);
    XCTAssertEqual(f, [Amplitude instanceWithName:@"app1"]);
    XCTAssertNotEqual(f,g);
    XCTAssertEqual(g, [Amplitude instanceWithName:@"app2"]);
}

- (void)testInitWithInstanceName {
    Amplitude *a = [Amplitude instanceWithName:@"APP1"];
    [a flushQueueWithQueue:a.initializerQueue];
    XCTAssertEqualObjects(a.instanceName, @"app1");
    XCTAssertTrue([a.propertyListPath rangeOfString:@"com.amplitude.plist_app1"].location != NSNotFound);

    Amplitude *b = [Amplitude instanceWithName:[kAMPDefaultInstance uppercaseString]];
    [b flushQueueWithQueue:b.initializerQueue];
    XCTAssertEqualObjects(b.instanceName, kAMPDefaultInstance);
    XCTAssertTrue([b.propertyListPath rangeOfString:@"com.amplitude.plist"].location != NSNotFound);
    XCTAssertTrue([ b.propertyListPath rangeOfString:@"com.amplitude.plist_"].location == NSNotFound);
}


- (void)testInitializeLoadNilUserIdFromEventData {
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], nil);
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];
    NSDictionary *event = [self.amplitude getLastEvent];
    XCTAssertEqual([event objectForKey:@"user_id"], nil);
    XCTAssertFalse([[event allKeys] containsObject:@"user_id"]);
}

- (void)testSeparateInstancesLogEventsSeparate {
    NSString *newInstance1 = @"newapp1";
    NSString *newApiKey1 = @"1234567890";
    
    NSString *newInstance2 = @"newapp2";
    NSString *newApiKey2 = @"0987654321";
    
    [AMPStorage storeEvent:@"{\"event_type\":\"oldEvent\"}" instanceName:kAMPDefaultInstance];
    [AMPStorage storeIdentify:@"{\"event_type\":\"$identify\"}" instanceName:kAMPDefaultInstance];
    [AMPStorage storeIdentify:@"{\"event_type\":\"$identify\"}" instanceName:kAMPDefaultInstance];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLongLong:1000] forKey:[Amplitude getDataStorageKey:@"sequence_number" instanceName:kAMPDefaultInstance]];
    [[Amplitude instance] setDeviceId:@"oldDeviceId"];
    [[Amplitude instance] flushQueue];
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"device_id" instanceName:kAMPDefaultInstance]], @"oldDeviceId");
    XCTAssertEqualObjects([[Amplitude instance] getDeviceId], @"oldDeviceId");
    XCTAssertEqual([[Amplitude instance] getNextSequenceNumber], 1001);

    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"device_id" instanceName:newInstance1]]);
    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"device_id" instanceName:newInstance2]]);
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"sequence_number" instanceName:kAMPDefaultInstance]], [NSNumber numberWithLongLong:1001]);
    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"sequence_number" instanceName:newInstance1]]);
    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"sequence_number" instanceName:newInstance2]]);

    // init first new app and verify separate database
    [[Amplitude instanceWithName:newInstance1] initializeApiKey:newApiKey1];
    [[Amplitude instanceWithName:newInstance1] flushQueue];
    XCTAssertNotEqualObjects([[Amplitude instanceWithName:newInstance1] getDeviceId], @"oldDeviceId");
    NSString *deviceKeyForNewInstance1 = [Amplitude getDataStorageKey:@"device_id" instanceName:newInstance1];
    XCTAssertEqualObjects([[Amplitude instanceWithName:newInstance1] getDeviceId], [[NSUserDefaults standardUserDefaults] objectForKey:deviceKeyForNewInstance1]);
    XCTAssertEqual([[Amplitude instanceWithName:newInstance1] getNextSequenceNumber], 1);
    XCTAssertEqual([[self.amplitude getAllEventsWithInstanceName:newInstance1] count], 0);
    XCTAssertEqual([[self.amplitude getAllIdentifyWithInstanceName:newInstance1] count], 0);

    // init second new app and verify separate database
    [[Amplitude instanceWithName:newInstance2] initializeApiKey:newApiKey2];
    [[Amplitude instanceWithName:newInstance2] flushQueue];
    XCTAssertNotEqualObjects([[Amplitude instanceWithName:newInstance2] getDeviceId], @"oldDeviceId");
    NSString *deviceKeyForNewInstance2 = [Amplitude getDataStorageKey:@"device_id" instanceName:newInstance2];
    XCTAssertEqualObjects([[Amplitude instanceWithName:newInstance2] getDeviceId], [[NSUserDefaults standardUserDefaults] objectForKey:deviceKeyForNewInstance2]);
    XCTAssertEqual([[Amplitude instanceWithName:newInstance2] getNextSequenceNumber], 1);
    XCTAssertEqual([[self.amplitude getAllEventsWithInstanceName:newInstance2] count], 0);
    XCTAssertEqual([[self.amplitude getAllIdentifyWithInstanceName:newInstance2] count], 0);

    // verify old database still intact
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"device_id" instanceName:kAMPDefaultInstance]], @"oldDeviceId");
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"sequence_number" instanceName:kAMPDefaultInstance]], [NSNumber numberWithLongLong:1001]);
    XCTAssertEqual([[self.amplitude getAllEvents] count], 1);
    XCTAssertEqual([[self.amplitude getAllIdentify] count], 2);

    // verify both apps can modify database independently and not affect old database
    [[Amplitude instanceWithName:newInstance1] setDeviceId:@"fakeDeviceId"];
    [[Amplitude instanceWithName:newInstance1] flushQueue];
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"device_id" instanceName:newInstance1]], @"fakeDeviceId");
    XCTAssertNotEqualObjects([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"device_id" instanceName:newInstance2]], @"fakeDeviceId");
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"device_id" instanceName:kAMPDefaultInstance]], @"oldDeviceId");
    [AMPStorage storeIdentify:@"{\"event_type\":\"$identify\"}" instanceName:newInstance1];
    XCTAssertEqual([[self.amplitude getAllIdentifyWithInstanceName:newInstance1] count], 1);
    XCTAssertEqual([[self.amplitude getAllIdentifyWithInstanceName:newInstance2] count], 0);
    XCTAssertEqual([[self.amplitude getAllIdentify] count], 2);
    
    [[Amplitude instanceWithName:newInstance2] setDeviceId:@"brandNewDeviceId"];
    [[Amplitude instanceWithName:newInstance2] flushQueue];
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"device_id" instanceName:newInstance1]], @"fakeDeviceId");
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"device_id" instanceName:newInstance2]], @"brandNewDeviceId");
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"device_id" instanceName:kAMPDefaultInstance]], @"oldDeviceId");
    
    [AMPStorage storeEvent:@"{\"event_type\":\"testEvent2\"}" instanceName:newInstance2];
    [AMPStorage storeEvent:@"{\"event_type\":\"testEvent2\"}" instanceName:newInstance2];
    XCTAssertEqual([[self.amplitude getAllIdentifyWithInstanceName:newInstance1] count], 1);
    XCTAssertEqual([[self.amplitude getAllIdentifyWithInstanceName:newInstance2] count], 0);
    XCTAssertEqual([[self.amplitude getAllEventsWithInstanceName:newInstance2] count], 2);
    XCTAssertEqual([[self.amplitude getAllEventsWithInstanceName:kAMPDefaultInstance] count], 1);
}

- (void)testInitializeLoadUserIdFromEventData {
    NSString *instanceName = @"testinitialize";
    Amplitude *client = [Amplitude instanceWithName:instanceName];
    [client flushQueue];
    XCTAssertEqual([client userId], nil);
    
    NSString *testUserId = @"testUserId";
    NSString *ampNSObjectKey = [Amplitude getDataStorageKey:@"user_id" instanceName:instanceName];
    [[NSUserDefaults standardUserDefaults] setObject:testUserId forKey:ampNSObjectKey];
    
    [client initializeApiKey:apiKey];
    [client flushQueue];
    XCTAssertTrue([[client userId] isEqualToString:testUserId]);
}

- (void)testInitializeWithNilUserId {
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], nil);

    NSString *nilUserId = nil;
    [self.amplitude initializeApiKey:apiKey userId:nilUserId];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], nilUserId);
    XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"user_id" instanceName:kAMPDefaultInstance]]);
}

- (void)testInitializeWithUserId {
    NSString *instanceName = @"testInitializeWithUserId";
    Amplitude *client = [Amplitude instanceWithName:instanceName];
    [client flushQueue];
    XCTAssertEqual([client userId], nil);

    NSString *testUserId = @"testUserId";
    [client initializeApiKey:apiKey userId:testUserId];
    [client flushQueue];
    XCTAssertEqual([client userId], testUserId);
}

- (void)testSkipReinitialization {
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], nil);

    NSString *testUserId = @"testUserId";
    [self.amplitude initializeApiKey:apiKey userId:testUserId];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], nil);
}

- (void)testClearUserId {
    [self.amplitude setEventUploadThreshold:1];

    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], nil);
    
    NSString *testUserId = @"testUserId";
    [self.amplitude setUserId:testUserId];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], testUserId);
    
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];
    NSDictionary *event1 = [self.amplitude getLastEvent];
    XCTAssert([[event1 objectForKey:@"user_id"] isEqualToString:testUserId]);
    
    [Amplitude cleanUp];

    NSString *nilUserId = nil;
    [self.amplitude setUserId:nilUserId];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude userId], nilUserId);
    
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];
    NSDictionary *event2 = [self.amplitude getLastEvent];
    XCTAssertEqual([event2 objectForKey:@"user_id"], nilUserId);
    XCTAssertFalse([[event2 allKeys] containsObject:@"user_id"]);
}

- (void)testRequestTooLargeBackoffLogic {
    [self.amplitude setEventUploadThreshold:2];
    
    NSMutableDictionary *serverResponse = [NSMutableDictionary dictionaryWithDictionary:
                                           @{ @"response" : [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"/"] statusCode:413 HTTPVersion:nil headerFields:@{}],
                                              @"data" : [@"response" dataUsingEncoding:NSUTF8StringEncoding]
                                              }];
    [self setupAsyncResponse:serverResponse];
    // 413 error force backoff with 2 events --> new upload limit will be 1

    [self.amplitude logEvent:@"test"];
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];

    // after first 413, the backoffupload batch size should now be 1
    XCTAssertTrue(self.amplitude.backoffUpload);
    XCTAssertEqual(self.amplitude.backoffUploadBatchSize, 1);

    // 3 upload attempts: upload 2 events, upload first event fail -> remove first event, upload second event fail -> remove second event
    XCTAssertEqual(_connectionCallCount, 3);
}

- (void)testRequestTooLargeBackoffRemoveEvent {
    [self.amplitude setEventUploadThreshold:1];
    NSMutableDictionary *serverResponse = [NSMutableDictionary dictionaryWithDictionary:
                                           @{ @"response" : [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"/"] statusCode:413 HTTPVersion:nil headerFields:@{}],
                                              @"data" : [@"response" dataUsingEncoding:NSUTF8StringEncoding]
                                              }];
    [self setupAsyncResponse:serverResponse];
    // 413 error force backoff with 1 events --> should drop the event

    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];

    // after first 413, the backoffupload batch size should now be 1
    XCTAssertTrue(self.amplitude.backoffUpload);
    XCTAssertEqual(self.amplitude.backoffUploadBatchSize, 1);
    XCTAssertEqual(_connectionCallCount, 1);
    XCTAssertEqual([self.databaseHelper getEventCount], 0);
}

- (void)testUUIDInEvent {
    [self.amplitude setEventUploadThreshold:2];

    [self.amplitude logEvent:@"event1"];
    [self.amplitude logEvent:@"event2"];
    [self.amplitude flushQueue];
    
    XCTAssertEqual([self.amplitude queuedEventCount], 2);
    NSArray *events = [self.amplitude getAllEvents];
    XCTAssertNotNil([events[0] objectForKey:@"uuid"]);
    XCTAssertNotNil([events[1] objectForKey:@"uuid"]);
    XCTAssertNotEqual([events[0] objectForKey:@"uuid"], [events[1] objectForKey:@"uuid"]);
}

- (void)testIdentify {
    [self.amplitude setEventUploadThreshold:2];

    AMPIdentify *identify = [[AMPIdentify identify] set:@"key1" value:@"value1"];
    [self.amplitude identify:identify];
    [self.amplitude flushQueue];

    XCTAssertEqual([self.amplitude getEventCount], 0);
    XCTAssertEqual([self.amplitude getIdentifyCount], 0);
    XCTAssertEqual([self.amplitude.identifyBuffer count], 1);

    NSDictionary *operations = [NSDictionary dictionaryWithObject:@"value1" forKey:@"key1"];
    NSDictionary *expected = [NSDictionary dictionaryWithObject:operations forKey:@"$set"];
    NSDictionary *event = self.amplitude.identifyBuffer[0];
    XCTAssertEqualObjects([event objectForKey:@"event_type"], IDENTIFY_EVENT);
    XCTAssertEqualObjects([event objectForKey:@"user_properties"], expected);
    XCTAssertEqualObjects([event objectForKey:@"event_properties"], [NSDictionary dictionary]); // event properties should be empty
    XCTAssertEqual(1, [[event objectForKey:@"sequence_number"] intValue]);

    NSMutableDictionary *serverResponse = [NSMutableDictionary dictionaryWithDictionary:
                                           @{ @"response" : [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"/"] statusCode:200 HTTPVersion:nil headerFields:@{}],
                                              @"data" : [@"success" dataUsingEncoding:NSUTF8StringEncoding]
                                              }];
    [self setupAsyncResponse:serverResponse];
    AMPIdentify *identify2 = [[[AMPIdentify alloc] init] set:@"key2" value:@"value2"];
    [self.amplitude identify:identify2];
    [self.amplitude flushQueue];

    XCTAssertEqual([self.amplitude getEventCount], 0);
    XCTAssertEqual([self.amplitude getIdentifyCount], 0);
    XCTAssertEqual([self.amplitude.identifyBuffer count], 2);
}

- (void)testGroupIdentify {
    NSString *groupType = @"test group type";
    NSString *groupName = @"test group name";

    AMPIdentify *identify = [[AMPIdentify identify] set:@"key1" value:@"value1"];
    [self.amplitude groupIdentifyWithGroupType:groupType groupName:groupName groupIdentify:identify];
    [self.amplitude flushQueue];

    XCTAssertEqual([self.amplitude getEventCount], 0);
    XCTAssertEqual([self.amplitude getIdentifyCount], 0);
    XCTAssertEqual([self.amplitude.identifyBuffer count], 1);

    NSDictionary *operations = [NSDictionary dictionaryWithObject:@"value1" forKey:@"key1"];
    NSDictionary *expected = [NSDictionary dictionaryWithObject:operations forKey:@"$set"];
    NSDictionary *expectedGroups = [NSDictionary dictionaryWithObject:@"test group name" forKey:@"test group type"];
    NSDictionary *event =  self.amplitude.identifyBuffer[0];
    XCTAssertEqualObjects([event objectForKey:@"event_type"], GROUP_IDENTIFY_EVENT);
    XCTAssertEqualObjects([event objectForKey:@"groups"], expectedGroups);
    XCTAssertEqualObjects([event objectForKey:@"group_properties"], expected);
    XCTAssertEqualObjects([event objectForKey:@"user_properties"], [NSDictionary dictionary]);
    XCTAssertEqualObjects([event objectForKey:@"event_properties"], [NSDictionary dictionary]); // event properties should be empty
    XCTAssertEqual(1, [[event objectForKey:@"sequence_number"] intValue]);

    NSMutableDictionary *serverResponse = [NSMutableDictionary dictionaryWithDictionary:
                                           @{ @"response" : [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"/"] statusCode:200 HTTPVersion:nil headerFields:@{}],
                                              @"data" : [@"success" dataUsingEncoding:NSUTF8StringEncoding]
                                              }];
    [self setupAsyncResponse:serverResponse];
    AMPIdentify *identify2 = [[[AMPIdentify alloc] init] set:@"key2" value:@"value2"];
    [self.amplitude groupIdentifyWithGroupType:groupType groupName:groupName groupIdentify:identify2];
    [self.amplitude flushQueue];

    XCTAssertEqual([self.amplitude getEventCount], 0);
    XCTAssertEqual([self.amplitude getIdentifyCount], 0);
    XCTAssertEqual([self.amplitude.identifyBuffer count], 2);
}

- (void)testLogRevenueV2 {
    [self.amplitude setEventUploadThreshold:1];

    // ignore invalid revenue objects
    [self.amplitude logRevenueV2:nil];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude getEventCount], 0);

    [self.amplitude logRevenueV2:[AMPRevenue revenue]];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude getEventCount], 0);

    // log valid revenue object
    NSNumber *price = [NSNumber numberWithDouble:15.99];
    NSInteger quantity = 15;
    NSString *productId = @"testProductId";
    NSString *revenueType = @"testRevenueType";
    NSDictionary *props = [NSDictionary dictionaryWithObject:@"San Francisco" forKey:@"city"];
    AMPRevenue *revenue = [[[[AMPRevenue revenue] setProductIdentifier:productId] setPrice:price] setQuantity:quantity];
    [[revenue setRevenueType:revenueType] setEventProperties:props];

    [self.amplitude logRevenueV2:revenue];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude getEventCount], 1);

    NSDictionary *event = [self.amplitude getLastEvent];
    XCTAssertEqualObjects([event objectForKey:@"event_type"], @"revenue_amount");

    NSDictionary *dict = [event objectForKey:@"event_properties"];
    XCTAssertEqualObjects([dict objectForKey:@"$productId"], productId);
    XCTAssertEqualObjects([dict objectForKey:@"$price"], price);
    XCTAssertEqualObjects([dict objectForKey:@"$quantity"], [NSNumber numberWithInteger:quantity]);
    XCTAssertEqualObjects([dict objectForKey:@"$revenueType"], revenueType);
    XCTAssertEqualObjects([dict objectForKey:@"city"], @"San Francisco");

    // user properties should be empty
    XCTAssertEqualObjects([event objectForKey:@"user_properties"], [NSDictionary dictionary]);

    // api properties should not have any revenue info
    NSDictionary *api_props = [event objectForKey:@"api_properties"];
    XCTAssertTrue(api_props.count > 0);
    XCTAssertNil([api_props objectForKey:@"$productId"]);
    XCTAssertNil([api_props objectForKey:@"$price"]);
    XCTAssertNil([api_props objectForKey:@"quantity"]);
    XCTAssertNil([api_props objectForKey:@"revenueType"]);
}

- (void) test{
     NSMutableDictionary *event_properties = [NSMutableDictionary dictionary];
    [event_properties setObject:@"some event description" forKey:@"description"];
    [event_properties setObject:@"green" forKey:@"color"];
    [event_properties setObject:@"productIdentifier" forKey:@"$productId"];
    [event_properties setObject:[NSNumber numberWithDouble:10.99] forKey:@"$price"];
    [event_properties setObject:[NSNumber numberWithInt:2] forKey:@"$quantity"];
    [[Amplitude instance] logEvent:@"Completed Purchase" withEventProperties:event_properties];
}

- (void)testMergeEventsAndIdentifys {
    [self.amplitude setEventUploadThreshold:6];
    
    [self.amplitude logEvent:@"test_event1"];
    [self.amplitude identify:[[AMPIdentify identify] add:@"photoCount" value:[NSNumber numberWithInt:1]]];
    [self.amplitude logEvent:@"test_event2"];
    [self.amplitude logEvent:@"test_event3"];
    [self.amplitude logEvent:@"test_event4"];
    [self.amplitude identify:[[AMPIdentify identify] set:@"gender" value:@"male"]];
    [self.amplitude flushQueue];

    XCTAssertEqual([self.amplitude getEventCount], 4);
    XCTAssertEqual([self.amplitude getIdentifyCount], 2);

    // verify merging
    NSMutableArray *events = [[self.amplitude getAllEvents] mutableCopy];
    NSMutableArray *identifys = [[self.amplitude getAllIdentify] mutableCopy];
    NSDictionary *merged = [self.amplitude mergeEventsAndIdentifys:events identifys:identifys numEvents:[self.amplitude getEventCount] + [self.amplitude getIdentifyCount] ];
    NSArray *mergedEvents = [merged objectForKey:@"events"];
    XCTAssertEqual(6, [mergedEvents count]);

    XCTAssertEqualObjects([mergedEvents[0] objectForKey:@"event_type"], @"test_event1");
    XCTAssertEqual([[mergedEvents[0] objectForKey:@"sequence_number"] intValue], 1);

    XCTAssertEqualObjects([mergedEvents[1] objectForKey:@"event_type"], @"$identify");
    XCTAssertEqual([[mergedEvents[1] objectForKey:@"sequence_number"] intValue], 2);
    XCTAssertEqualObjects([mergedEvents[1] objectForKey:@"user_properties"], [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"photoCount"] forKey:@"$add"]);

    XCTAssertEqualObjects([mergedEvents[2] objectForKey:@"event_type"], @"test_event2");
    XCTAssertEqual([[mergedEvents[2] objectForKey:@"sequence_number"] intValue], 3);

    XCTAssertEqualObjects([mergedEvents[3] objectForKey:@"event_type"], @"test_event3");
    XCTAssertEqual([[mergedEvents[3] objectForKey:@"sequence_number"] intValue], 4);

    XCTAssertEqualObjects([mergedEvents[4] objectForKey:@"event_type"], @"test_event4");
    XCTAssertEqual([[mergedEvents[4] objectForKey:@"sequence_number"] intValue], 5);

    XCTAssertEqualObjects([mergedEvents[5] objectForKey:@"event_type"], @"$identify");
    XCTAssertEqual([[mergedEvents[5] objectForKey:@"sequence_number"] intValue], 6);
    XCTAssertEqualObjects([mergedEvents[5] objectForKey:@"user_properties"], [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:@"male" forKey:@"gender"] forKey:@"$set"]);
    
}

-(void)testMergeEventsBackwardsCompatible {
    [self.amplitude setEventUploadThreshold:2];
    
    [self.amplitude identify:[[AMPIdentify identify] unset:@"key"]];
    [self.amplitude logEvent:@"test_event"];
    [self.amplitude flushQueue];

    NSMutableArray *identifys = self.amplitude.getAllIdentify;
    NSUInteger totalEventsCount = self.amplitude.getEventCount + self.amplitude.getIdentifyCount;
    // reinsert test event without sequence_number
    NSMutableDictionary *event = [NSMutableDictionary dictionaryWithDictionary:[self.amplitude getLastEvent]];
    [event removeObjectForKey:@"sequence_number"];
    [Amplitude cleanUp];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:event options:0 error:NULL];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [AMPStorage storeEvent:jsonString instanceName:kAMPDefaultInstance];

    // the event without sequence number should be ordered before the identify
    NSMutableArray *events = self.amplitude.getAllEvents;
    NSDictionary *merged = [self.amplitude mergeEventsAndIdentifys:events identifys:identifys numEvents:totalEventsCount];
    NSArray *mergedEvents = [merged objectForKey:@"events"];
    XCTAssertEqualObjects([mergedEvents[0] objectForKey:@"event_type"], @"test_event");
    XCTAssertNil([mergedEvents[0] objectForKey:@"sequence_number"]);
    XCTAssertEqualObjects([mergedEvents[1] objectForKey:@"event_type"], @"$identify");
    XCTAssertEqual(1, [[mergedEvents[1] objectForKey:@"sequence_number"] intValue]);
 }

-(void)testTruncateLongStrings {
    NSString *longString = [@"" stringByPaddingToLength:kAMPMaxStringLength*2 withString: @"c" startingAtIndex:0];
    XCTAssertEqual([longString length], kAMPMaxStringLength*2);
    NSString *truncatedString = [self.amplitude truncate:longString];
    XCTAssertEqual([truncatedString length], kAMPMaxStringLength);
    XCTAssertEqualObjects(truncatedString, [@"" stringByPaddingToLength:kAMPMaxStringLength withString: @"c" startingAtIndex:0]);

    NSString *shortString = [@"" stringByPaddingToLength:kAMPMaxStringLength-1 withString: @"c" startingAtIndex:0];
    XCTAssertEqual([shortString length], kAMPMaxStringLength-1);
    truncatedString = [self.amplitude truncate:shortString];
    XCTAssertEqual([truncatedString length], kAMPMaxStringLength-1);
    XCTAssertEqualObjects(truncatedString, shortString);
}

-(void)testTruncateNullObjects {
    XCTAssertNil([self.amplitude truncate:nil]);
}

-(void)testTruncateDictionary {
    NSString *longString = [@"" stringByPaddingToLength:kAMPMaxStringLength*2 withString: @"c" startingAtIndex:0];
    NSString *truncString = [@"" stringByPaddingToLength:kAMPMaxStringLength withString: @"c" startingAtIndex:0];
    NSMutableDictionary *object = [NSMutableDictionary dictionary];
    [object setValue:[NSNumber numberWithInt:10] forKey:@"int value"];
    [object setValue:[NSNumber numberWithBool:NO] forKey:@"bool value"];
    [object setValue:longString forKey:@"long string"];
    [object setValue:[NSArray arrayWithObject:longString] forKey:@"array"];
    [object setValue:longString forKey:AMP_REVENUE_RECEIPT];

    object = [self.amplitude truncate:object];
    XCTAssertEqual([[object objectForKey:@"int value"] intValue], 10);
    XCTAssertFalse([[object objectForKey:@"bool value"] boolValue]);
    XCTAssertEqual([[object objectForKey:@"long string"] length], kAMPMaxStringLength);
    XCTAssertEqual([[object objectForKey:@"array"] count], 1);
    XCTAssertEqualObjects([object objectForKey:@"array"][0], truncString);
    XCTAssertEqual([[object objectForKey:@"array"][0] length], kAMPMaxStringLength);

    // receipt field should not be truncated
    XCTAssertEqualObjects([object objectForKey:AMP_REVENUE_RECEIPT], longString);
}

-(void)testTruncateEventAndIdentify {
    [self.amplitude setEventUploadThreshold:2];

    NSString *longString = [@"" stringByPaddingToLength:kAMPMaxStringLength*2 withString: @"c" startingAtIndex:0];
    NSString *truncString = [@"" stringByPaddingToLength:kAMPMaxStringLength withString: @"c" startingAtIndex:0];

    NSDictionary *props = [NSDictionary dictionaryWithObjectsAndKeys:longString, @"long_string", longString, AMP_REVENUE_RECEIPT, nil];
    [self.amplitude logEvent:@"test" withEventProperties:props];
    [self.amplitude identify:[[AMPIdentify identify] set:@"long_string" value:longString]];
    [self.amplitude flushQueue];

    NSDictionary *event = [self.amplitude getLastEvent];
    NSDictionary *expected = [NSDictionary dictionaryWithObjectsAndKeys:truncString, @"long_string", longString, AMP_REVENUE_RECEIPT, nil];
    XCTAssertEqualObjects([event objectForKey:@"event_type"], @"test");
    XCTAssertEqualObjects([event objectForKey:@"event_properties"], expected);

    NSDictionary *identify = [self.amplitude getLastIdentify];
    XCTAssertEqualObjects([identify objectForKey:@"event_type"], @"$identify");
    XCTAssertEqualObjects([identify objectForKey:@"user_properties"], [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:truncString forKey:@"long_string"] forKey:@"$set"]);
}

-(void)testAutoIncrementSequenceNumber {
    int limit = 10;
    for (int i = 0; i < limit; i++) {
        XCTAssertEqual([self.amplitude getNextSequenceNumber], i+1);
        XCTAssertEqual([[[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"sequence_number" instanceName:kAMPDefaultInstance]] intValue], i+1);
    }
}

-(void)testSetOffline {
    [self.amplitude setEventUploadThreshold:3];

    [self.amplitude setOffline:YES];
    [self.amplitude logEvent:@"test"];
    [self.amplitude logEvent:@"test"];
    [self.amplitude identify:[[AMPIdentify identify] set:@"key" value:@"value"]];
    [self.amplitude flushQueue];

    XCTAssertEqual([self.amplitude getEventCount], 0);
    XCTAssertEqual([self.amplitude  getIdentifyCount], 0);

    [self.amplitude setOffline:NO];
    [self.amplitude flushQueue];

    XCTAssertEqual([self.amplitude  getEventCount], 2);
    XCTAssertEqual([self.amplitude  getIdentifyCount], 1);
}

-(void)testSetOfflineTruncate {
    int eventMaxCount = 3;
    self.amplitude.eventMaxCount = eventMaxCount;

    [self.amplitude setOffline:YES];
    [self.amplitude logEvent:@"test1"];
    [self.amplitude logEvent:@"test2"];
    [self.amplitude logEvent:@"test3"];
    [self.amplitude identify:[[AMPIdentify identify] unset:@"key1"]];
    [self.amplitude identify:[[AMPIdentify identify] unset:@"key2"]];
    [self.amplitude identify:[[AMPIdentify identify] unset:@"key3"]];
    [self.amplitude flushQueue];
    
    // when setOffline:YES, all events should only in buffer
    XCTAssertEqual([self.amplitude getEventCount], 0);
    XCTAssertEqual([self.amplitude getIdentifyCount], 0);
    XCTAssertEqual([self.amplitude.eventsBuffer count], 3);
    XCTAssertEqual([self.amplitude.identifyBuffer count], 3);
    
    [self.amplitude setOffline:NO];
    [self.amplitude logEvent:@"test4"];
    [self.amplitude identify:[[AMPIdentify identify] unset:@"key4"]];
    [self.amplitude flushQueue];

    XCTAssertEqual([self.amplitude.eventsBuffer count], 3);
    XCTAssertEqual([self.amplitude.identifyBuffer count], 3);
    
    NSMutableArray *events = self.amplitude.eventsBuffer;
    XCTAssertEqual([events count], 3);
    XCTAssertEqualObjects([events[0] objectForKey:@"event_type"], @"test2");
    XCTAssertEqualObjects([events[1] objectForKey:@"event_type"], @"test3");
    XCTAssertEqualObjects([events[2] objectForKey:@"event_type"], @"test4");

    NSMutableArray *identifys = self.amplitude.identifyBuffer;
    XCTAssertEqual([identifys count], 3);
    XCTAssertEqualObjects([[[identifys[0] objectForKey:@"user_properties"] objectForKey:@"$unset"] objectForKey:@"key2"], @"-");
    XCTAssertEqualObjects([[[identifys[1] objectForKey:@"user_properties"] objectForKey:@"$unset"] objectForKey:@"key3"], @"-");
    XCTAssertEqualObjects([[[identifys[2] objectForKey:@"user_properties"] objectForKey:@"$unset"] objectForKey:@"key4"], @"-");
}

-(void)testTruncateEventsQueues {
    int eventMaxCount = 50;

    XCTAssertGreaterThanOrEqual(eventMaxCount, kAMPEventRemoveBatchSize);
    self.amplitude.eventMaxCount = eventMaxCount;

    for (int i = 0; i < eventMaxCount; i++) {
        [self.amplitude logEvent:@"test"];
    }
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude.eventsBuffer count], eventMaxCount);

    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude.eventsBuffer count], eventMaxCount - (eventMaxCount/10) + 1);
}

-(void)testTruncateEventsQueuesWithOneEvent {
    [self.amplitude setEventUploadThreshold:1];
    int eventMaxCount = 1;
    self.amplitude.eventMaxCount = eventMaxCount;

    [self.amplitude logEvent:@"test1"];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude getEventCount], eventMaxCount);

    [Amplitude cleanUpFileStorage];
    self.amplitude.eventsBuffer = [[NSMutableArray alloc] init];
    [self.amplitude setEventUploadThreshold:1];
    self.amplitude.updatingCurrently = NO;
    
    [self.amplitude logEvent:@"test2"];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude getEventCount], eventMaxCount);

    NSDictionary *event = [self.amplitude getLastEvent];
    XCTAssertEqualObjects([event objectForKey:@"event_type"], @"test2");
}

-(void)testInvalidJSONEventProperties {
    [self.amplitude setEventUploadThreshold:1];
    
    NSURL *url = [NSURL URLWithString:@"https://amplitude.com/"];
    NSDictionary *properties = [NSDictionary dictionaryWithObjectsAndKeys:url, url, url, @"url", nil];
    [self.amplitude logEvent:@"test" withEventProperties:properties];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude getEventCount], 1);
}

-(void)testClearUserProperties {
    [self.amplitude setEventUploadThreshold:2];

    [self.amplitude clearUserProperties];
    [self.amplitude flushQueue];

    XCTAssertEqual([self.amplitude getEventCount], 0);
    XCTAssertEqual([self.amplitude getIdentifyCount], 0);
    XCTAssertEqual([self.amplitude.identifyBuffer count], 1);

    NSDictionary *expected = [NSDictionary dictionaryWithObject:@"-" forKey:@"$clearAll"];
    NSDictionary *event = self.amplitude.identifyBuffer[0];
    XCTAssertEqualObjects([event objectForKey:@"event_type"], IDENTIFY_EVENT);
    XCTAssertEqualObjects([event objectForKey:@"user_properties"], expected);
    XCTAssertEqualObjects([event objectForKey:@"event_properties"], [NSDictionary dictionary]); // event properties should be empty
    XCTAssertEqual(1, [[event objectForKey:@"sequence_number"] intValue]);
}

-(void)testSetGroup {
    [self.amplitude setGroup:@"orgId" groupName:[NSNumber numberWithInt:15]];
    [self.amplitude flushQueue];

    XCTAssertEqual([self.amplitude getEventCount], 0);
    XCTAssertEqual([self.amplitude getIdentifyCount], 0);
    XCTAssertEqual([self.amplitude.identifyBuffer count], 1);

    NSDictionary *groups = [NSDictionary dictionaryWithObject:@"15" forKey:@"orgId"];
    NSDictionary *userProperties = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:15] forKey:@"orgId"] forKey:@"$set"];

    NSDictionary *event = self.amplitude.identifyBuffer[0];

    XCTAssertEqualObjects([event objectForKey:@"user_properties"], userProperties);
    XCTAssertEqualObjects([event objectForKey:@"event_properties"], [NSDictionary dictionary]); // event properties should be empty
    XCTAssertEqualObjects([event objectForKey:@"groups"], groups);
}

-(void)testLogEventWithGroups {
    [self.amplitude setEventUploadThreshold:1];
    
    NSMutableDictionary *groups = [NSMutableDictionary dictionary];

    [groups setObject:[NSNumber numberWithInt: 10] forKey:[NSNumber numberWithFloat: 1.23]]; // validateGroups should coerce non-string values into strings
    NSMutableArray *innerArray = [NSMutableArray arrayWithObjects:@"test", [NSNumber numberWithInt:23], nil]; // should ignore nested array
    [groups setObject:[NSArray arrayWithObjects:@"test2", [NSNumber numberWithBool:FALSE], innerArray, [NSNull null], nil] forKey:@"array"]; // should ignore null values
    [groups setObject:[NSDictionary dictionaryWithObject:@"test3" forKey:[NSNumber numberWithDouble:160.0]] forKey:@"dictionary"]; // should ignore dictionary values
    [groups setObject:[NSNull null] forKey:@"null"]; // should ignore null values

    [self.amplitude logEvent:@"test" withEventProperties:nil withGroups:groups outOfSession:NO];
    [self.amplitude flushQueue];

    
    XCTAssertEqual([self.amplitude getEventCount], 1);
    XCTAssertEqual([self.amplitude getIdentifyCount], 0);

    NSDictionary *expectedGroups = [NSDictionary dictionaryWithObjectsAndKeys:@"10", @"1.23", @[@"test2", @"0"], @"array", nil];

    NSDictionary *event = [self.amplitude getLastEvent];
    XCTAssertEqualObjects([event objectForKey:@"event_type"], @"test");
    XCTAssertEqualObjects([event objectForKey:@"user_properties"], [NSDictionary dictionary]); // user properties should be empty
    XCTAssertEqualObjects([event objectForKey:@"event_properties"], [NSDictionary dictionary]); // event properties should be empty
    XCTAssertEqualObjects([event objectForKey:@"groups"], expectedGroups);
}

-(void)testUnarchiveEventsDict {
    NSString *archiveName = @"test_archive";
    NSDictionary *event = [NSDictionary dictionaryWithObject:@"test event" forKey:@"event_type"];
    XCTAssertTrue([self.amplitude archive:event toFile:archiveName]);

    NSDictionary *unarchived = [self.amplitude unarchive:archiveName];
#if !TARGET_OS_OSX
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_8_4) {
        XCTAssertEqualObjects(unarchived, event);
    } else {
        XCTAssertNil(unarchived);
    }
#else
    XCTAssertEqualObjects(unarchived, event);
#endif
}

-(void)testBlockTooManyProperties {
    [self.amplitude setEventUploadThreshold:2];

    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    NSMutableDictionary *userProperties = [NSMutableDictionary dictionary];
    AMPIdentify *identify = [AMPIdentify identify];
    for (int i = 0; i < kAMPMaxPropertyKeys + 1; i++) {
        [eventProperties setObject:[NSNumber numberWithInt:i] forKey:[NSNumber numberWithInt:i]];
        [userProperties setObject:[NSNumber numberWithInt:i*2] forKey:[NSNumber numberWithInt:i*2]];
        [identify setOnce:[NSString stringWithFormat:@"%d", i] value:[NSNumber numberWithInt:i]];
    }

    // verify that setUserProperties ignores dict completely
    [self.amplitude setUserProperties:userProperties];
    [self.amplitude flushQueue];
    XCTAssertEqual([self.amplitude.identifyBuffer count], 0);

    // verify that event properties and user properties are scrubbed
    [self.amplitude logEvent:@"test event" withEventProperties:eventProperties];
    [self.amplitude identify:identify];
    [self.amplitude flushQueue];

    XCTAssertEqual([self.amplitude getEventCount], 1);
    NSDictionary *event = [self.amplitude getLastEvent];
    XCTAssertEqualObjects(event[@"event_properties"], [NSDictionary dictionary]);
    XCTAssertEqualObjects(event[@"user_properties"], [NSDictionary dictionary]);

    XCTAssertEqual([self.amplitude getIdentifyCount], 1);
    NSDictionary *identifyEvent = [self.amplitude getLastIdentify];
    XCTAssertEqualObjects(identifyEvent[@"event_properties"], [NSDictionary dictionary]);
    XCTAssertEqualObjects(identifyEvent[@"user_properties"], [NSDictionary dictionaryWithObject:[NSDictionary dictionary] forKey:@"$setOnce"]);
}

-(void)testLogEventWithTimestamp {
    [self.amplitude setEventUploadThreshold:1];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:1000];
    NSNumber *timestamp = [NSNumber numberWithLongLong:[date timeIntervalSince1970]];

    [self.amplitude logEvent:@"test" withEventProperties:nil withGroups:nil withTimestamp:timestamp outOfSession:NO];
    [self.amplitude flushQueue];
    NSMutableArray *eventsBuffer = self.amplitude.eventsBuffer;
    XCTAssertEqual([eventsBuffer count], 1);
    NSDictionary *event = eventsBuffer[0];
    XCTAssertEqual(1000, [[event objectForKey:@"timestamp"] longLongValue]);

    [self.amplitude logEvent:@"test2" withEventProperties:nil withGroups:nil withLongLongTimestamp:2000 outOfSession:NO];
    [self.amplitude flushQueue];
    XCTAssertEqual([eventsBuffer count], 2);
    event = self.amplitude.eventsBuffer[1];
    XCTAssertEqual(2000, [[event objectForKey:@"timestamp"] longLongValue]);
}


-(void)testRegenerateDeviceId {
    [self.amplitude flushQueue];
    NSString *oldDeviceId = [self.amplitude getDeviceId];
    XCTAssertFalse([AMPUtils isEmptyString:oldDeviceId]);
    XCTAssertEqualObjects(oldDeviceId, [[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"device_id" instanceName:kAMPDefaultInstance]]);

    [self.amplitude regenerateDeviceId];
    [self.amplitude flushQueue];
    NSString *newDeviceId = [self.amplitude getDeviceId];
    XCTAssertNotEqualObjects(oldDeviceId, newDeviceId);
    XCTAssertEqualObjects(newDeviceId, [[NSUserDefaults standardUserDefaults] objectForKey:[Amplitude getDataStorageKey:@"device_id" instanceName:kAMPDefaultInstance]]);
    XCTAssertTrue([newDeviceId hasSuffix:@"R"]);
}

-(void)testTrackIdfa {
    [self.amplitude setEventUploadThreshold:1];
    
    NSString *value = @"12340000-0000-0000-0000-000000000000";
    
    self.amplitude.adSupportBlock = ^NSString * _Nonnull{
        return value;
    };
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];
    
    self.amplitude.adSupportBlock = nil;
    
    NSDictionary *apiProps = [self.amplitude getLastEvent][@"api_properties"];
    XCTAssertTrue([[apiProps objectForKey:@"ios_idfa"] isEqualToString:value]);
}

#if TARGET_OS_IOS
-(void)testIdfaAsDeviceId {
    AMPTrackingOptions *opts = [AMPTrackingOptions options]; // has shouldTrackIDFA set.
    [AMPStorage remove:[AMPStorage getDefaultEventsFile:@"idfv"]];
    
    NSString *value = @"12340000-0000-0000-0000-000000000000";
    
    Amplitude *client = [Amplitude instanceWithName:@"idfa"];
    client.adSupportBlock = ^NSString * _Nonnull{
        return value;
    };
    [client setTrackingOptions:opts];
    [client flushQueueWithQueue:client.initializerQueue];
    [client initializeApiKey:@"api key"];
    [client useAdvertisingIdForDeviceId];
    [client flushQueue];

    NSString *deviceId = [client getDeviceId];
    XCTAssertTrue([deviceId isEqual:value]);
}

-(void)testDisableIdfaAsDeviceId {
    AMPTrackingOptions *options = [[AMPTrackingOptions options] disableIDFA];
    [AMPStorage remove:[AMPStorage getDefaultEventsFile:@"disable_idfv"]];
    
    NSString *value = @"12340000-0000-0000-0000-000000000000";
    
    Amplitude *client = [Amplitude instanceWithName:@"disable_idfa"];
    client.adSupportBlock = ^NSString * _Nonnull{
        return value;
    };

    [client flushQueueWithQueue:client.initializerQueue];
    [client setTrackingOptions:options];
    [client initializeApiKey:@"api key"];
    [client useAdvertisingIdForDeviceId];
    [client flushQueue];

    NSString *deviceId = [client getDeviceId];
    XCTAssertFalse([deviceId isEqual:value]);
}
#endif

-(void)testIdfvAsDeviceId {
    [AMPStorage remove:[AMPStorage getDefaultEventsFile:@"idfv"]];
    Amplitude *client = [Amplitude instanceWithName:@"idfv"];
    
    AMPDeviceInfo * deviceInfo = [[AMPDeviceInfo alloc] init];

    [client flushQueueWithQueue:client.initializerQueue];
    [client initializeApiKey:@"api key"];
    [client flushQueue];

    XCTAssertTrue([[client getDeviceId] isEqual:deviceInfo.vendorID]);
}

-(void)testDisableIdfvAsDeviceId {
    AMPTrackingOptions *options = [[AMPTrackingOptions options] disableIDFV];
    AMPDeviceInfo *deviceInfo = [[AMPDeviceInfo alloc] init];
    
    [AMPStorage remove:[AMPStorage getDefaultEventsFile:@"disable_idfv"]];
    Amplitude *client = [Amplitude instanceWithName:@"disable_idfv"];
    [client flushQueueWithQueue:client.initializerQueue];
    [client setTrackingOptions:options];
    [client initializeApiKey:@"api key"];
    [client flushQueue];

    XCTAssertFalse([[client getDeviceId] isEqual:deviceInfo.vendorID]);
    XCTAssertEqual([[client getDeviceId] characterAtIndex:36], 'R');
}

-(void)testSetTrackingConfig {
    [self.amplitude setEventUploadThreshold:1];
    
    AMPTrackingOptions *options = [[[[[AMPTrackingOptions options] disableCity] disableIPAddress] disableLanguage] disableCountry];
    [self.amplitude setTrackingOptions:options];
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];
    NSDictionary *event = [self.amplitude getLastEvent];

    // verify we have platform and carrier since those were not filtered out
    XCTAssertEqualObjects([event objectForKey:@"carrier"], @"Unknown");

    // verify we do not have any of the filtered out events
    XCTAssertNil([event objectForKey:@"city"]);
    XCTAssertNil([event objectForKey:@"country"]);
    XCTAssertNil([event objectForKey:@"language"]);

    // verify api properties contains tracking options for location filtering
    NSDictionary *apiProperties = [event objectForKey:@"api_properties"];
    XCTAssertNotNil([apiProperties objectForKey:@"ios_idfv"]);
    XCTAssertNotNil([apiProperties objectForKey:@"tracking_options"]);

    NSDictionary *trackingOptions = [apiProperties objectForKey:@"tracking_options"];
    XCTAssertEqual(3, trackingOptions.count);
    XCTAssertEqualObjects([NSNumber numberWithBool:NO], [trackingOptions objectForKey:@"city"]);
    XCTAssertEqualObjects([NSNumber numberWithBool:NO], [trackingOptions objectForKey:@"country"]);
    XCTAssertEqualObjects([NSNumber numberWithBool:NO], [trackingOptions objectForKey:@"ip_address"]);
}

- (void)testEnableCoppaControl {
    [self.amplitude setEventUploadThreshold:1];
    
    NSDictionary *event = nil;
    NSDictionary *apiProperties = nil;
    [self.amplitude disableCoppaControl];
    
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];
    event = self.amplitude.eventsBuffer[0];

    apiProperties = [event objectForKey:@"api_properties"];
    XCTAssertNotNil([apiProperties objectForKey:@"ios_idfv"]);
    
    [Amplitude cleanUpFileStorage];
    self.amplitude.updatingCurrently = NO;
    [self.amplitude setEventUploadThreshold:1];
    [self.amplitude enableCoppaControl];
    [self.amplitude logEvent:@"test"];
    [self.amplitude flushQueue];
    
    event = [self.amplitude.eventsBuffer lastObject];
    apiProperties = [event objectForKey:@"api_properties"];
    XCTAssertNil([apiProperties objectForKey:@"ios_idfv"]);
    
    // Minor guard covers 3 server configs. city, lat_lng, ip
    NSDictionary *trackingOptions = [apiProperties objectForKey:@"tracking_options"];
    XCTAssertEqual(3, trackingOptions.count);
    XCTAssertEqualObjects([NSNumber numberWithBool:NO], [trackingOptions objectForKey:@"city"]);
    XCTAssertEqualObjects([NSNumber numberWithBool:NO], [trackingOptions objectForKey:@"lat_lng"]);
    XCTAssertEqualObjects([NSNumber numberWithBool:NO], [trackingOptions objectForKey:@"ip_address"]);
}

- (void)testCustomizedLibrary {
    Amplitude *client = [Amplitude instanceWithName:@"custom_lib"];
    [client setEventUploadThreshold:1];
    [client initializeApiKey:@"blah"];
    client.libraryName = @"amplitude-unity";
    client.libraryVersion = @"1.0.0";
    
    [client logEvent:@"test"];
    [client flushQueue];

    NSDictionary *event = [client getLastEventWithInstanceName:@"custom_lib"];
    NSDictionary *targetLibraryValue = @{ @"name" : @"amplitude-unity",
                                          @"version" : @"1.0.0"
    };
    
    NSDictionary *currentLibraryValue = event[@"library"];
    XCTAssertEqualObjects(currentLibraryValue, targetLibraryValue);
}

- (void)testCustomizedLibraryWithNilVersion {
    Amplitude *client = [Amplitude instanceWithName:@"custom_lib"];
    client.eventsBuffer = [[NSMutableArray alloc] init];
    client.maxEventSequenceNumber = 0;
    [client setEventUploadThreshold:1];
    [client initializeApiKey:@"blah"];
    client.updatingCurrently = NO;
    
    client.libraryName = @"amplitude-unity";
    client.libraryVersion = nil;
    
    [client logEvent:@"test"];
    [client flushQueue];

    NSDictionary *event = [client getLastEventWithInstanceName:@"custom_lib"];
    NSDictionary *targetLibraryValue = @{ @"name" : @"amplitude-unity",
                                          @"version" : kAMPUnknownVersion
    };
    
    NSDictionary *currentLibraryValue = event[@"library"];
    XCTAssertEqualObjects(currentLibraryValue, targetLibraryValue);
  
}

- (void)testCustomizedLibraryWithNilLibrary {
    Amplitude *client = [Amplitude instanceWithName:@"custom_lib"];
    client.eventsBuffer = [[NSMutableArray alloc] init];
    client.maxEventSequenceNumber = 0;
    [client setEventUploadThreshold:1];
    [client initializeApiKey:@"blah"];
    client.updatingCurrently = NO;
    
    client.libraryName = nil;
    client.libraryVersion = @"1.0.0";
    
    [client logEvent:@"test"];
    [client flushQueue];

    NSDictionary *event = [client getLastEventWithInstanceName:@"custom_lib"];
    NSDictionary *targetLibraryValue = @{ @"name" : kAMPUnknownLibrary,
                                          @"version" : @"1.0.0"
    };
    
    NSDictionary *currentLibraryValue = event[@"library"];
    XCTAssertEqualObjects(currentLibraryValue, targetLibraryValue);
}

- (void)testCustomizedLibraryWithNilLibraryAndVersion {
    Amplitude *client = [Amplitude instanceWithName:@"custom_lib"];
    client.eventsBuffer = [[NSMutableArray alloc] init];
    client.maxEventSequenceNumber = 0;
    [client setEventUploadThreshold:1];
    [client initializeApiKey:@"blah"];
    client.updatingCurrently = NO;
    
    client.libraryName = nil;
    client.libraryVersion = nil;
    
    [client logEvent:@"test"];
    [client flushQueue];

    NSDictionary *event = [client getLastEventWithInstanceName:@"custom_lib"];
    NSDictionary *targetLibraryValue = @{ @"name" : kAMPUnknownLibrary,
                                          @"version" : kAMPUnknownVersion
    };
    
    NSDictionary *currentLibraryValue = event[@"library"];
    XCTAssertEqualObjects(currentLibraryValue, targetLibraryValue);
}

@end
