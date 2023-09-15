//
//  IdentifyInterceptorTests.m
//  Amplitude
//
//  Created by Justin Fiedler on 02/06/23.
//  Copyright © 2023 Amplitude. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AMPConstants.h"
#import "AMPEventUtils.h"
#import "AMPIdentify.h"
#import "AMPIdentifyInterceptor.h"

@interface AMPIdentifyInterceptor(PrivateTests)
- (AMPDatabaseHelper *)dbHelper;
@end

@interface IdentifyInterceptorTests : XCTestCase

@property AMPIdentifyInterceptor *identifyInterceptor;
@property NSOperationQueue *backgroundQueue;
@property AMPDatabaseHelper *dbHelper;

@end

@implementation IdentifyInterceptorTests

- (void)setUp {
    _dbHelper = [AMPDatabaseHelper getDatabaseHelper];
    [_dbHelper dropTables];
    [_dbHelper createTables];

    _backgroundQueue = [[NSOperationQueue alloc] init];
    // Force method calls to happen in FIFO order by only allowing 1 concurrent operation
    [_backgroundQueue setMaxConcurrentOperationCount:1];
    // Ensure initialize finishes running asynchronously before other calls are run
    [_backgroundQueue setSuspended:YES];
    // Name the queue so runOnBackgroundQueue can tell which queue an operation is running
    _backgroundQueue.name = @"BACKGROUND";

    _identifyInterceptor = [AMPIdentifyInterceptor getIdentifyInterceptor:_dbHelper backgroundQueue:_backgroundQueue];
}

- (void)tearDown {
    _identifyInterceptor = nil;
}

- (NSMutableDictionary *_Nonnull)getIdentifyEvent:(AMPIdentify *_Nonnull)identify {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    [event setValue:IDENTIFY_EVENT forKey:@"event_type"];
    [event setValue:[identify.userPropertyOperations mutableCopy] forKey:@"user_properties"];
    [event setValue:@([_dbHelper getNextSequenceNumber]) forKey:@"sequence_number"];

    return event;
}

- (NSMutableDictionary *_Nonnull)getEvent:(NSString *_Nonnull)eventType {
    return [self getEvent:eventType withEventProperties:nil];
}

- (NSMutableDictionary *_Nonnull)getEvent:(NSString *_Nonnull)eventType withEventProperties:(NSDictionary *)eventProperties {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    [event setValue:eventType forKey:@"event_type"];
    [event setValue:[eventProperties mutableCopy] forKey:@"event_properties"];
    [event setValue:@([_dbHelper getNextSequenceNumber]) forKey:@"sequence_number"];

    return event;
}

- (void)testIdentifyWithOnlySetIsIntercepted {
    AMPIdentify *identify = [AMPIdentify.identify set:@"set-key" value:@"set-value"];
    NSMutableDictionary *event = [self getIdentifyEvent:identify];
    NSMutableDictionary *userProperties = [AMPEventUtils getUserProperties:event];
    NSArray *userPropertiesOperations = [userProperties allKeys];

    XCTAssertNotNil(userProperties);
    XCTAssertEqual(userPropertiesOperations.count, 1);
    XCTAssertEqual(userPropertiesOperations[0], AMP_OP_SET);

    event = [self->_identifyInterceptor intercept:event];

    XCTAssertEqual([event count], 0);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 1);

}

- (void)testIdentifyWithOnlySetOnceIsNotIntercepted {
    AMPIdentify *identify = [AMPIdentify.identify setOnce:@"set-once-key" value:@"set-once-value"];
    NSMutableDictionary *event = [self getIdentifyEvent:identify];
    NSMutableDictionary *userProperties = [AMPEventUtils getUserProperties:event];
    NSArray *userPropertiesOperations = [userProperties allKeys];

    XCTAssertNotNil(userProperties);
    XCTAssertEqual(userPropertiesOperations.count, 1);
    XCTAssertEqual(userPropertiesOperations[0], AMP_OP_SET_ONCE);

    event = [self->_identifyInterceptor intercept:event];

    XCTAssertNotNil(event);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 0);
    // Note: we can't check getIdentifyCount = 1 since the IdenitfyInterceptor only adds intercepted idenitfies to DB
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);
}

- (void)testIdentifyWithOtherOpsIsNotIntercepted {
    AMPIdentify *identify = [AMPIdentify.identify add:@"add-key" value:@1];
    NSMutableDictionary *event = [self getIdentifyEvent:identify];
    NSMutableDictionary *userProperties = [AMPEventUtils getUserProperties:event];
    NSArray *userPropertiesOperations = [userProperties allKeys];

    XCTAssertNotNil(userProperties);
    XCTAssertEqual(userPropertiesOperations.count, 1);
    XCTAssertEqual(userPropertiesOperations[0], AMP_OP_ADD);

    event = [self->_identifyInterceptor intercept:event];

    XCTAssertNotNil(event);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 0);
    // Note: we can't check getIdentifyCount = 1 since the IdenitfyInterceptor only adds intercepted idenitfies to DB
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);
}

- (void)testStandardEventIsNotIntercepted {
    NSMutableDictionary *event = [self getEvent:@"test"];

    event = [self->_identifyInterceptor intercept:event];

    XCTAssertNotNil(event);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 0);
    // Note: we can't check getEventCount = 1 since the IdenitfyInterceptor only adds intercepted idenitfies to DB
    XCTAssertEqual(self->_dbHelper.getEventCount, 0);
}


- (void)testInterceptedIdentifyIsTransferredOnNextActiveIdentify {
    // identify with intercept props only
    AMPIdentify *identify1 = [AMPIdentify.identify set:@"set-key" value:@"set-value"];
    NSMutableDictionary *event1 = [self getIdentifyEvent:identify1];

    event1 = [self->_identifyInterceptor intercept:event1];

    XCTAssertEqual([event1 count], 0);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 1);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 1);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);

    // active identify
    AMPIdentify *identify2 = [AMPIdentify.identify add:@"add-key" value:@1];
    NSMutableDictionary *event2 = [self getIdentifyEvent:identify2];

    event2 = [self->_identifyInterceptor intercept:event2];

    XCTAssertNotNil(event2);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 2);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 0);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 1);

    NSMutableDictionary *userProperties2 = [AMPEventUtils getUserProperties:event2];
    NSArray *userPropertiesOperations2 = [userProperties2 allKeys];
    XCTAssertNotNil(userProperties2);
    XCTAssertEqual(userPropertiesOperations2.count, 1);
    BOOL hasAddOperationsOnly = [[NSSet setWithArray:userPropertiesOperations2] isEqualToSet:[NSSet setWithArray:@[AMP_OP_ADD]]];
    XCTAssertTrue(hasAddOperationsOnly);
    XCTAssertTrue([userProperties2[AMP_OP_ADD][@"add-key"] isEqualToNumber:@1]);

    NSArray *identifies = [_dbHelper getIdentifys:-1 limit:1];
    NSDictionary *interceptedIdentify = [identifies lastObject];
    NSMutableDictionary *userProperties = [AMPEventUtils getUserProperties:interceptedIdentify];
    NSArray *userPropertiesOperations = [userProperties allKeys];
    XCTAssertNotNil(userProperties);
    XCTAssertEqual(userPropertiesOperations.count, 1);
    BOOL hasSetOperationsOnly = [[NSSet setWithArray:userPropertiesOperations] isEqualToSet:[NSSet setWithArray:@[AMP_OP_SET]]];
    XCTAssertTrue(hasSetOperationsOnly);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key"] isEqualToString:@"set-value"]);
}

- (void)testMultipleInterceptedIdentifyIsTransferredOnNextActiveIdentify {
    AMPIdentify *identify1 = [AMPIdentify.identify set:@"set-key" value:@"set-value-a"];
    [identify1 set:@"set-key-2" value:@"set-value-b"];
    NSMutableDictionary *event1 = [self getIdentifyEvent:identify1];

    event1 = [self->_identifyInterceptor intercept:event1];

    XCTAssertEqual([event1 count], 0);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 1);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 1);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);

    // identify with intercept props only
    AMPIdentify *identify2 = [AMPIdentify.identify set:@"set-key" value:@"set-value-c"];
    [identify2 set:@"set-key-3" value:@"set-value-d"];
    NSMutableDictionary *event2 = [self getIdentifyEvent:identify2];

    event2 = [self->_identifyInterceptor intercept:event2];

    XCTAssertEqual([event2 count], 0);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 2);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 2);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);

    // active identify
    AMPIdentify *identify3 = [AMPIdentify.identify add:@"add-key" value:@1];
    [identify3 setOnce:@"set-once-key" value:@"set-once-value"];
    NSMutableDictionary *event3 = [self getIdentifyEvent:identify3];

    event3 = [self->_identifyInterceptor intercept:event3];

    XCTAssertNotNil(event3);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 3);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 0);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 1);

    // Active identify should not include intercepted values.
    NSMutableDictionary *userProperties3 = [AMPEventUtils getUserProperties:event3];
    NSArray *userPropertiesOperations3 = [userProperties3 allKeys];
    XCTAssertNotNil(userProperties3);
    XCTAssertEqual(userPropertiesOperations3.count, 2);
    BOOL hasAllOperations = [[NSSet setWithArray:userPropertiesOperations3] isEqualToSet:[NSSet setWithArray:@[AMP_OP_SET_ONCE, AMP_OP_ADD]]];
    XCTAssertTrue(hasAllOperations);
    XCTAssertTrue([userProperties3[AMP_OP_ADD][@"add-key"] isEqualToNumber:@1]);
    XCTAssertTrue([userProperties3[AMP_OP_SET_ONCE][@"set-once-key"] isEqualToString:@"set-once-value"]);
    // Active identify should not include intercepted values.
    XCTAssertNil(userProperties3[AMP_OP_SET]);

    NSArray *identifies = [_dbHelper getIdentifys:-1 limit:1];
    NSDictionary *interceptedIdentify = [identifies lastObject];
    NSMutableDictionary *userProperties = [AMPEventUtils getUserProperties:interceptedIdentify];
    NSArray *userPropertiesOperations = [userProperties allKeys];
    XCTAssertNotNil(userProperties);
    XCTAssertEqual(userPropertiesOperations.count, 1);
    BOOL hasSetOperationsOnly = [[NSSet setWithArray:userPropertiesOperations] isEqualToSet:[NSSet setWithArray:@[AMP_OP_SET]]];
    XCTAssertTrue(hasSetOperationsOnly);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key"] isEqualToString:@"set-value-c"]);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key-2"] isEqualToString:@"set-value-b"]);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key-3"] isEqualToString:@"set-value-d"]);
}

- (void)testMultipleInterceptedIdentifyIsTransferredOnNextActiveIdentifyWithSetOperation {
    AMPIdentify *identify1 = [AMPIdentify.identify set:@"set-key" value:@"set-value-a"];
    [identify1 set:@"set-key-2" value:@"set-value-b"];
    NSMutableDictionary *event1 = [self getIdentifyEvent:identify1];

    event1 = [self->_identifyInterceptor intercept:event1];

    XCTAssertEqual([event1 count], 0);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 1);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 1);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);

    // identify with intercept props only
    AMPIdentify *identify2 = [AMPIdentify.identify set:@"set-key" value:@"set-value-c"];
    [identify2 set:@"set-key-3" value:@"set-value-d"];
    NSMutableDictionary *event2 = [self getIdentifyEvent:identify2];

    event2 = [self->_identifyInterceptor intercept:event2];

    XCTAssertEqual([event2 count], 0);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 2);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 2);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);

    // active identify
    AMPIdentify *identify3 = [AMPIdentify.identify add:@"add-key" value:@1];
    [identify3 set:@"set-key-active" value:@"set-value-active"];
    NSMutableDictionary *event3 = [self getIdentifyEvent:identify3];

    event3 = [self->_identifyInterceptor intercept:event3];

    XCTAssertNotNil(event3);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 3);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 0);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 1);

    NSMutableDictionary *userProperties3 = [AMPEventUtils getUserProperties:event3];
    NSArray *userPropertiesOperations3 = [userProperties3 allKeys];
    XCTAssertNotNil(userProperties3);
    XCTAssertEqual(userPropertiesOperations3.count, 2);
    BOOL hasAllOperations = [[NSSet setWithArray:userPropertiesOperations3] isEqualToSet:[NSSet setWithArray:@[AMP_OP_SET, AMP_OP_ADD]]];
    XCTAssertTrue(hasAllOperations);
    XCTAssertTrue([userProperties3[AMP_OP_ADD][@"add-key"] isEqualToNumber:@1]);
    // Active identify should not include intercepted values.
    XCTAssertTrue([userProperties3[AMP_OP_SET][@"set-key-active"] isEqualToString:@"set-value-active"]);
    XCTAssertNil(userProperties3[AMP_OP_SET][@"set-key"]);
    XCTAssertNil(userProperties3[AMP_OP_SET][@"set-key-2"]);
    XCTAssertNil(userProperties3[AMP_OP_SET][@"set-key-3"]);

    NSArray *identifies = [_dbHelper getIdentifys:-1 limit:1];
    NSDictionary *interceptedIdentify = [identifies lastObject];
    NSMutableDictionary *userProperties = [AMPEventUtils getUserProperties:interceptedIdentify];
    NSArray *userPropertiesOperations = [userProperties allKeys];
    XCTAssertNotNil(userProperties);
    XCTAssertEqual(userPropertiesOperations.count, 1);
    BOOL hasSetOperationsOnly = [[NSSet setWithArray:userPropertiesOperations] isEqualToSet:[NSSet setWithArray:@[AMP_OP_SET]]];
    XCTAssertTrue(hasSetOperationsOnly);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key"] isEqualToString:@"set-value-c"]);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key-2"] isEqualToString:@"set-value-b"]);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key-3"] isEqualToString:@"set-value-d"]);
    // Intercepted identify should not include active values.
    XCTAssertNil(userProperties[AMP_OP_SET][@"set-key-active"]);
}

- (void)testInterceptedIdentifyIsTransferredOnNextActiveEvent {
    // identify with intercept props only
    AMPIdentify *identify = [AMPIdentify.identify set:@"set-key" value:@"set-value"];
    NSMutableDictionary *event = [self getIdentifyEvent:identify];

    event = [self->_identifyInterceptor intercept:event];

    XCTAssertEqual([event count], 0);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 1);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 1);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);

    // standard event
    NSMutableDictionary *event2 = [self getEvent:@"test"];

    event2 = [self->_identifyInterceptor intercept:event2];
    XCTAssertNotNil(event2);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 2);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 0);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 1);
    XCTAssertEqual(self->_dbHelper.getEventCount, 0);

    NSMutableDictionary *userProperties3 = [AMPEventUtils getUserProperties:event2];
    XCTAssertNil(userProperties3);

    NSArray *identifies = [_dbHelper getIdentifys:-1 limit:1];
    NSDictionary *interceptedIdentify = [identifies lastObject];
    NSMutableDictionary *userProperties = [AMPEventUtils getUserProperties:interceptedIdentify];
    NSArray *userPropertiesOperations = [userProperties allKeys];
    XCTAssertNotNil(userProperties);
    XCTAssertEqual(userPropertiesOperations.count, 1);
    BOOL hasSetOperationsOnly = [[NSSet setWithArray:userPropertiesOperations] isEqualToSet:[NSSet setWithArray:@[AMP_OP_SET]]];
    XCTAssertTrue(hasSetOperationsOnly);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key"] isEqualToString:@"set-value"]);
}

- (void)testMultipleInterceptedIdentifyIsTransferredNextActiveEvent {
    // intercept identify 1
    AMPIdentify *identify1 = [AMPIdentify.identify set:@"set-key" value:@"set-value-a"];
    [identify1 set:@"set-key-2" value:@"set-value-b"];
    NSMutableDictionary *event1 = [self getIdentifyEvent:identify1];

    event1 = [self->_identifyInterceptor intercept:event1];

    XCTAssertEqual([event1 count], 0);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 1);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 1);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);

    // intercept identify 2
    AMPIdentify *identify2 = [AMPIdentify.identify set:@"set-key" value:@"set-value-c"];
    [identify2 set:@"set-key-3" value:@"set-value-d"];
    NSMutableDictionary *event2 = [self getIdentifyEvent:identify2];

    event2 = [self->_identifyInterceptor intercept:event2];

    XCTAssertEqual([event2 count], 0);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 2);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 2);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);

    // active event
    NSMutableDictionary *event3 = [self getEvent:@"test"];

    event3 = [self->_identifyInterceptor intercept:event3];

    XCTAssertNotNil(event3);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 3);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 0);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 1);

    NSMutableDictionary *userProperties3 = [AMPEventUtils getUserProperties:event3];
    XCTAssertNil(userProperties3);

    NSArray *identifies = [_dbHelper getIdentifys:-1 limit:1];
    NSDictionary *interceptedIdentify = [identifies lastObject];
    NSMutableDictionary *userProperties = [AMPEventUtils getUserProperties:interceptedIdentify];
    NSArray *userPropertiesOperations = [userProperties allKeys];
    XCTAssertNotNil(userProperties);
    XCTAssertEqual(userPropertiesOperations.count, 1);
    BOOL hasSetOperationsOnly = [[NSSet setWithArray:userPropertiesOperations] isEqualToSet:[NSSet setWithArray:@[AMP_OP_SET]]];
    XCTAssertTrue(hasSetOperationsOnly);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key"] isEqualToString:@"set-value-c"]);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key-2"] isEqualToString:@"set-value-b"]);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key-3"] isEqualToString:@"set-value-d"]);
}

- (void)testNullValuesInIdentifySetAreIgnoredOnActiveIdentify {
    // intercept identify 1
    AMPIdentify *identify1 = [AMPIdentify.identify set:@"set-key" value:@"set-value-a"];
    [identify1 set:@"set-key-2" value:@"set-value-b"];
    NSMutableDictionary *event1 = [self getIdentifyEvent:identify1];

    event1 = [self->_identifyInterceptor intercept:event1];

    XCTAssertEqual([event1 count], 0);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 1);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 1);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);

    // intercept identify 2
    AMPIdentify *identify2 = [AMPIdentify.identify set:@"set-key" value:nil];
    [identify2 set:@"set-key-2" value:@"set-value-c"];
    [identify2 set:@"set-key-3" value:nil];
    NSMutableDictionary *event2 = [self getIdentifyEvent:identify2];

    event2 = [self->_identifyInterceptor intercept:event2];

    XCTAssertEqual([event2 count], 0);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 2);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 2);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);

    // active identify
    AMPIdentify *identify3 = [AMPIdentify.identify add:@"add-key" value:@1];
    NSMutableDictionary *event3 = [self getIdentifyEvent:identify3];

    event3 = [self->_identifyInterceptor intercept:event3];

    XCTAssertNotNil(event3);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 3);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 0);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 1);

    NSMutableDictionary *userProperties3 = [AMPEventUtils getUserProperties:event3];
    XCTAssertNotNil(userProperties3);
    NSArray *userPropertiesOperations3 = [userProperties3 allKeys];
    XCTAssertEqual(userPropertiesOperations3.count, 1);
    BOOL hasAddOperationsOnly = [[NSSet setWithArray:userPropertiesOperations3] isEqualToSet:[NSSet setWithArray:@[AMP_OP_ADD]]];
    XCTAssertTrue(hasAddOperationsOnly);
    XCTAssertTrue([userProperties3[AMP_OP_ADD][@"add-key"] isEqualToNumber:@1]);

    NSArray *identifies = [_dbHelper getIdentifys:-1 limit:1];
    NSDictionary *interceptedIdentify = [identifies lastObject];
    NSMutableDictionary *userProperties = [AMPEventUtils getUserProperties:interceptedIdentify];
    NSArray *userPropertiesOperations = [userProperties allKeys];
    XCTAssertNotNil(userProperties);
    XCTAssertEqual(userPropertiesOperations.count, 1);
    BOOL hasSetOperationsOnly = [[NSSet setWithArray:userPropertiesOperations] isEqualToSet:[NSSet setWithArray:@[AMP_OP_SET]]];
    XCTAssertTrue(hasSetOperationsOnly);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key"] isEqualToString:@"set-value-a"]);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key-2"] isEqualToString:@"set-value-c"]);
    XCTAssertNil(userProperties[AMP_OP_SET][@"set-key-3"]);
}

- (void)testNullValuesInIdentifySetAreIgnoredOnActiveEvent {
    // intercept identify 1
    AMPIdentify *identify1 = [AMPIdentify.identify set:@"set-key" value:@"set-value-a"];
    [identify1 set:@"set-key-2" value:@"set-value-b"];
    NSMutableDictionary *event1 = [self getIdentifyEvent:identify1];

    event1 = [self->_identifyInterceptor intercept:event1];

    XCTAssertEqual([event1 count], 0);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 1);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 1);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);

    // intercept identify 2
    AMPIdentify *identify2 = [AMPIdentify.identify set:@"set-key" value:nil];
    [identify2 set:@"set-key-2" value:@"set-value-c"];
    [identify2 set:@"set-key-3" value:nil];
    NSMutableDictionary *event2 = [self getIdentifyEvent:identify2];

    event2 = [self->_identifyInterceptor intercept:event2];

    XCTAssertEqual([event2 count], 0);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 2);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 2);
    XCTAssertEqual(self->_dbHelper.getIdentifyCount, 0);

    // active event
    NSMutableDictionary *event3 = [self getEvent:@"test"];

    event3 = [self->_identifyInterceptor intercept:event3];

    XCTAssertNotNil(event3);
    XCTAssertEqual(self->_dbHelper.getLastSequenceNumber, 3);
    XCTAssertEqual(self->_dbHelper.getInterceptedIdentifyCount, 0);

    NSMutableDictionary *userProperties3 = [AMPEventUtils getUserProperties:event3];
    XCTAssertNil(userProperties3);

    NSArray *identifies = [_dbHelper getIdentifys:-1 limit:1];
    NSDictionary *interceptedIdentify = [identifies lastObject];
    NSMutableDictionary *userProperties = [AMPEventUtils getUserProperties:interceptedIdentify];
    NSArray *userPropertiesOperations = [userProperties allKeys];
    XCTAssertNotNil(userProperties);
    XCTAssertEqual(userPropertiesOperations.count, 1);
    BOOL hasSetOperationsOnly = [[NSSet setWithArray:userPropertiesOperations] isEqualToSet:[NSSet setWithArray:@[AMP_OP_SET]]];
    XCTAssertTrue(hasSetOperationsOnly);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key"] isEqualToString:@"set-value-a"]);
    XCTAssertTrue([userProperties[AMP_OP_SET][@"set-key-2"] isEqualToString:@"set-value-c"]);
    XCTAssertNil(userProperties[AMP_OP_SET][@"set-key-3"]);
}

- (void)testDbHelperIsNotReusedAcrossDifferentIdentifyInterceptorInstances {
    AMPDatabaseHelper *dbHelper1 = [AMPDatabaseHelper getDatabaseHelper:@"dbHelper1"];
    AMPIdentifyInterceptor *identifyInterceptor1 = [AMPIdentifyInterceptor getIdentifyInterceptor:dbHelper1
                                                                                  backgroundQueue:[[NSOperationQueue alloc] init]];

    AMPDatabaseHelper *dbHelper2 = [AMPDatabaseHelper getDatabaseHelper:@"dbHelper2"];
    AMPIdentifyInterceptor *identifyInterceptor2 = [AMPIdentifyInterceptor getIdentifyInterceptor:dbHelper2
                                                                                  backgroundQueue:[[NSOperationQueue alloc] init]];

    XCTAssertIdentical(identifyInterceptor1.dbHelper, dbHelper1);
    XCTAssertIdentical(identifyInterceptor2.dbHelper, dbHelper2);
}
@end
