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

- (NSDictionary *)getEvent:(NSInteger) fromEnd {
    NSString * path = [AMPStorage getDefaultEventsFile:kAMPDefaultInstance];
    NSArray *events = [AMPStorage getEventsFromDisk:path];
    return [events objectAtIndex:[events count] - fromEnd - 1];
}

- (NSDictionary *)getLastEventFromInstanceName:(NSString *)instanceName {
    NSString * path = [AMPStorage getDefaultEventsFile:instanceName];
    NSArray *events = [AMPStorage getEventsFromDisk:path];
    return [events lastObject];
}

- (NSDictionary *)getLastEvent {
    NSString * path = [AMPStorage getDefaultEventsFile:kAMPDefaultInstance];
    NSArray *events = [AMPStorage getEventsFromDisk:path];
    return [events lastObject];
}

- (NSDictionary *)getLastIdentify {
    NSString * path = [AMPStorage getDefaultIdentifyFile:kAMPDefaultInstance];
    NSArray *identifys = [AMPStorage getEventsFromDisk:path];
    return [identifys lastObject];
}

- (NSUInteger)queuedEventCount {
    NSString * path = [AMPStorage getDefaultEventsFile:kAMPDefaultInstance];
    NSArray *events = [AMPStorage getEventsFromDisk:path];
    return [events count];
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

@end

