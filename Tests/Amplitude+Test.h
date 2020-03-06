//
//  Amplitude+Test.h
//  Amplitude
//
//  Created by Allan on 3/11/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Amplitude (Test)

@property (nonatomic, strong) NSOperationQueue *backgroundQueue;
@property (nonatomic, strong) NSOperationQueue *initializerQueue;
@property (nonatomic, strong) NSMutableDictionary *eventsData;
@property (nonatomic, assign) BOOL initialized;
@property (nonatomic, assign) long long sessionId;
@property (nonatomic, strong) NSNumber* lastEventTime;
@property (nonatomic, assign) BOOL backoffUpload;
@property (nonatomic, assign) int backoffUploadBatchSize;
@property (nonatomic, assign) BOOL sslPinningEnabled;

- (void)flushQueue;
- (void)flushQueueWithQueue:(NSOperationQueue*) queue;
- (void)flushUploads:(void (^)(void))handler;
- (NSDictionary *)getLastEvent;
- (NSDictionary *)getLastIdentify;
- (NSDictionary *)getEvent:(NSInteger) fromEnd;
- (NSUInteger)queuedEventCount;
- (void)enterForeground;
- (void)enterBackground;
- (NSDate*)currentTime;
- (id)unarchive:(NSString*)path;
- (BOOL)archive:(id) obj toFile:(NSString*)path;

@end
