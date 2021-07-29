//
//  Amplitude+Test.m
//  Amplitude
//
//  Created by Allan on 3/11/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import "Amplitude.h"
#import "Amplitude+Test.h"
#import "AMPDatabaseHelper.h"
#import "AMPStorage.h"
#import "AMPConstants.h"

@interface Amplitude (Tests)
+ (NSString *)getDataStorageKey:(NSString *)key instanceName:(NSString *)instanceName;
@end

@implementation Amplitude (Test)

@dynamic backgroundQueue;
@dynamic initializerQueue;
@dynamic eventsData;
@dynamic initialized;
@dynamic sessionId;
@dynamic lastEventTime;
@dynamic backoffUpload;
@dynamic backoffUploadBatchSize;
@dynamic sslPinningEnabled;

- (void)flushQueue {
    [self flushQueueWithQueue:[self backgroundQueue]];
   // [AMPStorage remove:[AMPStorage getAppStorageAmpDir:self.instanceName]];
}

- (void)flushQueueWithQueue:(NSOperationQueue*) queue {
    [queue waitUntilAllOperationsAreFinished];
}

- (NSMutableArray *)getAllEvents {
    return [self getAllEventsWithInstanceName:kAMPDefaultInstance];
}

- (NSMutableArray *)getAllEventsWithInstanceName:(NSString *)instanceName {
    NSString * path = [AMPStorage getDefaultEventsFile:instanceName];
    NSArray *events = [AMPStorage getEventsFromDisk:path];
    return events;
}

- (NSUInteger)getEventCount{
    return [self.getAllEvents count];
}

- (NSDictionary *)getEvent:(NSInteger)fromEnd {
    NSString * path = [AMPStorage getDefaultEventsFile:kAMPDefaultInstance];
    NSArray *events = [AMPStorage getEventsFromDisk:path];
    return [events objectAtIndex:[events count] - fromEnd - 1];
}

- (NSDictionary *)getLastEvent {
    return [self getLastEventWithInstanceName:kAMPDefaultInstance];
}

- (NSDictionary *)getLastEventWithInstanceName:(NSString *)instanceName {
    NSString * path = [AMPStorage getDefaultEventsFile:instanceName];
    NSArray *events = [AMPStorage getEventsFromDisk:path];
    return [events lastObject];
}

- (NSMutableArray *)getAllIdentify {
    return [self getAllIdentifyWithInstanceName:kAMPDefaultInstance];
}

- (NSMutableArray *)getAllIdentifyWithInstanceName:(NSString *)instanceName {
    NSString * path = [AMPStorage getDefaultIdentifyFile:instanceName];
    NSArray *identify = [AMPStorage getEventsFromDisk:path];
    return identify;
}

- (NSUInteger)getIdentifyCount{
    return [self.getAllIdentify count];
}

- (NSDictionary *)getLastIdentify {
    return [self getLastIdentifyWithInstanceName:kAMPDefaultInstance];
}

- (NSDictionary *)getLastIdentifyWithInstanceName:(NSString *)instanceName {
    NSString * path = [AMPStorage getDefaultIdentifyFile:kAMPDefaultInstance];
    NSArray *identifys = [AMPStorage getEventsFromDisk:path];
    return [identifys lastObject];
}

- (NSUInteger)queuedEventCount {
    return [self.getAllEvents count];
}

- (void)flushUploads:(void (^)(void))handler {
    [self performSelector:@selector(uploadEvents)];
    [self flushQueue];

    // Wait a second for the upload response to get into the queue.
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        [self flushQueue];
        handler();
    });
}

- (void)cleanUp {
    [self cleanUp:kAMPDefaultInstance];

}

- (void)cleanUp:(NSString *)instanceName {
    [AMPStorage remove:[AMPStorage getDefaultEventsFile:instanceName]];
    [AMPStorage remove:[AMPStorage getDefaultIdentifyFile:instanceName]];
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[Amplitude getDataStorageKey:@"sequence_number" instanceName:instanceName]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[Amplitude getDataStorageKey:@"device_id" instanceName:instanceName]];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:[Amplitude getDataStorageKey:@"user_id" instanceName:instanceName]];
}


@end

