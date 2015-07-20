//
//  Amplitude+Test.h
//  Amplitude
//
//  Created by Allan on 3/11/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Amplitude (Test)

@property (nonatomic, retain) NSOperationQueue *backgroundQueue;
@property (nonatomic, retain) NSOperationQueue *initializerQueue;
@property (nonatomic, retain) NSMutableDictionary *eventsData;
@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, assign) long long sessionId;

- (void)flushQueue;
- (void)flushQueueWithQueue:(NSOperationQueue*) queue;
- (void)flushUploads:(void (^)())handler;
- (NSDictionary *)getLastEvent;
- (NSDictionary *)getEvent:(NSInteger) fromEnd;
- (NSUInteger)queuedEventCount;

@end
