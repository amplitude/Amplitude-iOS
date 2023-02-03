//
//  AMPIdentifyInterceptor.m
//  Copyright (c) 2021 Amplitude Inc. (https://amplitude.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
#ifndef AMPLITUDE_LOG_ERRORS
#define AMPLITUDE_LOG_ERRORS 1
#endif

#ifndef AMPLITUDE_ERROR
#if AMPLITUDE_LOG_ERRORS
#   define AMPLITUDE_ERROR(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#   define AMPLITUDE_ERROR(...)
#endif
#endif

#import <Foundation/Foundation.h>
#import "AMPConstants.h"
#import "AMPEventUtils.h"
#import "AMPIdentifyInterceptor.h"
#import "AMPDatabaseHelper.h"
#import "AmplitudePrivate.h"

@implementation AMPIdentifyInterceptor

static NSArray *INTERCEPT_OPS;
+ (NSArray *) INTERCEPT_OPS { return @[AMP_OP_SET, AMP_OP_SET_ONCE]; }

BOOL _uploadScheduled;
Amplitude *_Nonnull _amplitude;
NSOperationQueue *_Nonnull _backgroundQueue;
AMPDatabaseHelper *_Nonnull _dbHelper;
long _lastIdentifyInterceptorId;
int _interceptedUploadPeriodSeconds;

- (instancetype)init {
    if ((self = [super init])) {
        _lastIdentifyInterceptorId = -1;
        _interceptedUploadPeriodSeconds = kAMPIdentifyUploadPeriodSeconds;
        _uploadScheduled = NO;
    }
    return self;
}

-(id)initWithParams:(AMPDatabaseHelper *_Nonnull)dbHelper
          amplitude:(Amplitude *_Nonnull) amplitude
    backgroundQueue:(NSOperationQueue *_Nonnull)backgroundQueue
{
    if(self = [super init]) {
        _dbHelper = dbHelper;
        _amplitude = amplitude;
        _backgroundQueue = backgroundQueue;
    }

    return self;
}

+ (instancetype _Nonnull)getIdentifyInterceptor:(AMPDatabaseHelper *_Nonnull) dbHelper
                                      amplitude:(Amplitude *_Nonnull) amplitude
                                backgroundQueue:(NSOperationQueue *_Nonnull)backgroundQueue
{
    return [[self alloc] initWithParams:dbHelper amplitude:amplitude backgroundQueue:backgroundQueue];
}

- (NSMutableDictionary *_Nonnull)mergeUserProperties:(NSMutableDictionary *_Nonnull) userPropertyOperations withUserProperties:(NSMutableDictionary *_Nonnull) userPropertyOperationsToMerge {
    NSMutableDictionary *mergedUserProperties = [[NSMutableDictionary alloc] init];

    // This assumes we only evey merge INTERCEPT_OPS for Identify's
    for(int opIndex = 0; opIndex < INTERCEPT_OPS.count; opIndex++) {
        NSString *operation = [INTERCEPT_OPS objectAtIndex:opIndex];
        NSMutableDictionary *operationKVPs = [userPropertyOperations objectForKey:operation];
        NSMutableDictionary *operationKVPsToMerge = [userPropertyOperationsToMerge objectForKey:operation];

        NSMutableDictionary *mergedOperationKVPs = [[NSMutableDictionary alloc] init];
        [mergedOperationKVPs addEntriesFromDictionary:operationKVPs];
        [mergedOperationKVPs addEntriesFromDictionary:operationKVPsToMerge];

        [mergedUserProperties setValue:mergedOperationKVPs forKey:operation];
    }

    return mergedUserProperties;
}

/**
 * Merged all pending intercepted user properties to the given @event
 * Clears intercepted Idenitfy's from DB
 */
- (void)mergeInterceptedUserProperties:(NSMutableDictionary *_Nonnull) event {
    NSMutableDictionary *mergedUserProperties = [[NSMutableDictionary alloc] init];

    // Load any intercepted Identify events from DB
    NSMutableDictionary *interceptedIdentify = [self getCombinedInterceptedIdentify];
    if (interceptedIdentify != nil) {
        mergedUserProperties = [self mergeUserProperties:mergedUserProperties withUserProperties:interceptedIdentify];
    }

    // Get the event's userProperties and apply them over the intercepted values
    NSMutableDictionary *eventUserProperties = [AMPEventUtils getUserProperties:event];
    if (eventUserProperties != nil) {
        mergedUserProperties = [self mergeUserProperties:mergedUserProperties withUserProperties:eventUserProperties];
    }

    // Apply merged user properties to the
    [AMPEventUtils setUserProperties:event userProperties:mergedUserProperties];

    // remove inter
    [_dbHelper removeInterceptedIdentifys:[_dbHelper getLastSequenceNumber]];
}

- (NSMutableDictionary *)intercept:(NSMutableDictionary *_Nonnull)event {
    NSString *eventType = [AMPEventUtils getEventType:event];

    NSMutableDictionary *userPropertyOperations = [AMPEventUtils getUserProperties:event];
    if (eventType == IDENTIFY_EVENT) {
        // Check to intercept
        if ([self hasInterceptOperationsOnly:userPropertyOperations]) {
            NSError *error = nil;
            NSString *eventJsonString = [AMPEventUtils getJsonString:event eventType:eventType error:&error];
            // Conversion to JSON string failed, return unmodified event to try to store as a normal identify
            if (error != nil) {
                return event;
            }

            // Store in Intercepted Identify DB
            [_dbHelper addInterceptedIdentify:eventJsonString];

            // Set timeout for transfer
            [self scheduleUpload];

            // Event is intercepted, return nil
            return nil;
        } else if ([userPropertyOperations objectForKey:AMP_OP_CLEAR_ALL] != nil) {
           // Clear all pending intercepted Identify's
           [_dbHelper removeInterceptedIdentifys:[_dbHelper getLastSequenceNumber]];
        } else {
           // This is an "active" Identify, merge intercepted user properties
           [self mergeInterceptedUserProperties:event];
        }
    } else if ([eventType isEqualToString:GROUP_IDENTIFY_EVENT]) {
        // Group identify = no op
    } else {
        // Normal event, merge intercepted user properties
        [self mergeInterceptedUserProperties:event];
    }

    return event;
}

// If this returns YES, the given Identify user property operations should be queued and batched later
- (BOOL)hasInterceptOperationsOnly:(NSDictionary *_Nonnull)userPropertyOperations {
    NSSet *operations = [NSSet setWithArray:[userPropertyOperations allKeys]];
    NSSet *interceptSet = [NSSet setWithArray:INTERCEPT_OPS];

    return [operations isSubsetOfSet:interceptSet];
}

- (void)scheduleUpload {
    // TODO:
    if (!_uploadScheduled) {
        _uploadScheduled = YES;
        __block __weak AMPIdentifyInterceptor *weakSelf = self;
        [_backgroundQueue addOperationWithBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf performSelector:@selector(uploadCombinedInterceptedIdentify) withObject:nil afterDelay:_interceptedUploadPeriodSeconds];
            });
        }];
    }
}

- (void)uploadCombinedInterceptedIdentify {
    NSMutableDictionary *interceptedIdentify = [self getCombinedInterceptedIdentify];
    if (interceptedIdentify != nil) {
        NSString *eventType = [AMPEventUtils getEventType:interceptedIdentify];

        NSError *error = nil;
        NSString *eventJsonString = [AMPEventUtils getJsonString:interceptedIdentify eventType:eventType error:&error];
        // Conversion to JSON string failed, return unmodified event to try to store as a normal identify
        if (error == nil) {
            // Remove pending intercepts from DB
            [_dbHelper removeInterceptedIdentifys:[_dbHelper getLastSequenceNumber]];

            // Save combined Identify to "active" storage
            [_dbHelper addIdentify:eventJsonString];

            // Upload immediately
            [_amplitude uploadEvents];
        } else {
            AMPLITUDE_ERROR(@"ERROR: could not JSONSerialize intercepted event type %@: %@", eventType, error);
        }
    }
    _uploadScheduled = NO;
}

/**
 * Returns the current combined intercepted Identify operations
 *
 *  WARNING: This doesn't clear the intercepted events from the DB, it only retrieves them
 */
- (NSMutableDictionary *)getCombinedInterceptedIdentify {
    // Load any intercepted Identify events from DB
    NSMutableArray *interceptedIdentifys = [_dbHelper getInterceptedIdentifys:-1 limit:-1];

    long interceptedCount = (interceptedIdentifys != nil) ? interceptedIdentifys.count : 0;
    NSMutableDictionary *combinedInterceptedIdentify = (interceptedCount > 0)
        ? [interceptedIdentifys[0] mutableCopy]
        : nil;
    NSMutableDictionary *mergedUserProperties = (interceptedCount > 0)
        ? [AMPEventUtils getUserProperties:combinedInterceptedIdentify]
        : nil;

    for(int interceptedIndex = 1; interceptedIndex < interceptedCount; interceptedIndex++) {
        NSMutableDictionary *curIdentify = interceptedIdentifys[interceptedIndex];
        NSMutableDictionary *curUserProperties = [AMPEventUtils getUserProperties:curIdentify];

        mergedUserProperties = [self mergeUserProperties:mergedUserProperties withUserProperties:curUserProperties];
    }

    if (mergedUserProperties != nil && combinedInterceptedIdentify != nil) {
        [AMPEventUtils setUserProperties:combinedInterceptedIdentify userProperties:mergedUserProperties];
    }

    return combinedInterceptedIdentify;
}

-(BOOL)setInterceptedIdentifyUploadPeriodSeconds:(int)uploadPeriodSeconds {
    if (uploadPeriodSeconds < kAMPMinIdentifyUploadPeriodSeconds) {
        AMPLITUDE_ERROR(@"ERROR: Minimum Identify upload period is %d seconds", kAMPMinIdentifyUploadPeriodSeconds);
        return NO;
    }
    _interceptedUploadPeriodSeconds = uploadPeriodSeconds;

    return YES;
}


@end
