//
//  Amplitude+Test.h
//  Amplitude
//
//  Created by Allan on 3/11/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Amplitude (Test)

@property NSOperationQueue *backgroundQueue;
@property NSMutableDictionary *eventsData;
@property BOOL initialized;

- (void)flushQueue;
- (NSDictionary *)getLastEvent;
- (NSDictionary *)getEvent:(NSInteger) fromEnd;
- (NSUInteger)queuedEventCount;

@end
