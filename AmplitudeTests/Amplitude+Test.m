//
//  Amplitude+Test.m
//  Amplitude
//
//  Created by Allan on 3/11/15.
//  Copyright (c) 2015 Amplitude. All rights reserved.
//

#import "Amplitude.h"
#import "Amplitude+Test.h"

@implementation Amplitude (Test)

@dynamic backgroundQueue;
@dynamic eventsData;
@dynamic initialized;

- (void)flushQueue {
    [[self backgroundQueue] waitUntilAllOperationsAreFinished];
}

- (NSDictionary *)getEvent:(NSInteger) fromEnd {
    NSArray *events = [self eventsData][@"events"];
    return [events objectAtIndex:[events count] - fromEnd - 1];
}

- (NSDictionary *)getLastEvent {
    return [[self eventsData][@"events"] lastObject];
}

- (NSUInteger)queuedEventCount {
    return [[self eventsData][@"events"] count];
}

@end

