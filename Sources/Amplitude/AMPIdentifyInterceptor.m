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
#import "AMPUtils.h"
#import "AMPEventUtils.h"
#import "AMPIdentifyInterceptor.h"
#import "AMPDatabaseHelper.h"

@implementation AMPIdentifyInterceptor {
    NSArray *_Nonnull _interceptOps;
    NSSet *_Nonnull _interceptOpsSet;
    BOOL _transferScheduled;
    NSOperationQueue *_Nonnull _backgroundQueue;
    AMPDatabaseHelper *_Nonnull _dbHelper;
    BOOL _hasIdentity;
    NSString *_Nullable _userId;
    NSString *_Nullable _deviceId;
    int _interceptedUploadPeriodSeconds;
    BOOL _disabled;
}

-(id)initWithParams:(AMPDatabaseHelper *_Nonnull)dbHelper
    backgroundQueue:(NSOperationQueue *_Nonnull)backgroundQueue
{
    if(self = [super init]) {
        _dbHelper = dbHelper;
        _backgroundQueue = backgroundQueue;
        _interceptedUploadPeriodSeconds = kAMPIdentifyUploadPeriodSeconds;
        _transferScheduled = NO;
        _disabled = NO;
        _interceptOps = @[AMP_OP_SET]; // Notice: Supporting AMP_OP_SET_ONCE would require more complex merge logic
        _interceptOpsSet = [NSSet setWithArray:_interceptOps];
        _hasIdentity = NO;
    }

    return self;
}

+ (instancetype _Nonnull)getIdentifyInterceptor:(AMPDatabaseHelper *_Nonnull) dbHelper
                                backgroundQueue:(NSOperationQueue *_Nonnull)backgroundQueue
{
    return [[self alloc] initWithParams:dbHelper backgroundQueue:backgroundQueue];
}

// If this returns YES, the given Identify user property operations should be queued and batched later
- (BOOL)hasInterceptOperationsOnly:(NSDictionary *_Nonnull)userPropertyOperations {
    NSSet *operations = [NSSet setWithArray:[userPropertyOperations allKeys]];

    return [operations isSubsetOfSet:_interceptOpsSet];
}

// If this returns YES, the given Identify has a different `user_id` or `device_id` than previous intercepts
- (BOOL)hasDifferentIdentity:(NSMutableDictionary *_Nonnull)event {
    NSString *eventUserId = [AMPEventUtils getUserId:event];
    NSString *eventDeviceId= [AMPEventUtils getDeviceId:event];

    @synchronized (self) {
        if (!_hasIdentity) {
            _hasIdentity = YES;
            _userId = eventUserId;
            _deviceId = eventDeviceId;
            return true;
        }

        BOOL isUpdated = NO;
        if (![self isIdEqual:_userId toId:eventUserId]) {
            _userId = eventUserId;
            isUpdated = YES;
        }
        if (![self isIdEqual:_deviceId toId:eventDeviceId]) {
            _deviceId = eventDeviceId;
            isUpdated = YES;
        }
        return isUpdated;
    }
}

- (BOOL)isIdEqual:(NSString *_Nonnull)id1 toId:(NSString *_Nonnull)id2 {
    return (id1 == nil ? id2 == nil : [id1 isEqualToString:id2]);
}

- (NSMutableDictionary *)intercept:(NSMutableDictionary *_Nonnull)event {
    if (_disabled) {
        return event;
    }

    if ([self hasDifferentIdentity:event]) {
        // if userId or deviceId is updated, send out intercepted identify's for older identity
        [self transferInterceptedIdentify];
    }

    NSString *eventType = [AMPEventUtils getEventType:event];
    NSMutableDictionary *userPropertyOperations = [AMPEventUtils getUserProperties:event];
    if (eventType == IDENTIFY_EVENT) {
        // Check to intercept - "set" ops only, and not setGroup
        if ([self hasInterceptOperationsOnly:userPropertyOperations] && [AMPEventUtils getGroups:event] == nil) {
            NSError *error = nil;
            NSString *eventJsonString = [AMPEventUtils getJsonString:event eventType:eventType error:&error];
            // Conversion to JSON string failed, return unmodified event to try to store as a normal identify
            if (error != nil) {
               return event;
            }

            // Store in Intercepted Identify DB
            [_dbHelper addInterceptedIdentify:eventJsonString];

            // Set timeout for transfer
            [self scheduleTransfer];

            // Event is intercepted, return nil
            return [NSMutableDictionary dictionary];
       } else if ([userPropertyOperations objectForKey:AMP_OP_CLEAR_ALL] != nil) {
            // Clear all pending intercepted Identify's
            [_dbHelper removeInterceptedIdentifys:[_dbHelper getLastSequenceNumber]];
       } else {
            [self transferInterceptedIdentify];
       }
    } else if ([eventType isEqualToString:GROUP_IDENTIFY_EVENT]) {
        // Group identify = no op
    } else {
        [self transferInterceptedIdentify];
    }

    return event;
}

- (NSMutableDictionary *_Nonnull)mergeUserPropertyOperations:(NSMutableDictionary *_Nonnull) userPropertyOperations withUserPropertiesOperations:(NSMutableDictionary *_Nonnull) userPropertyOperationsToMerge {
    NSMutableDictionary *mergedUserProperties = [userPropertyOperations mutableCopy] ?: [NSMutableDictionary dictionary];

    // This assumes we only evey merge INTERCEPT_OPS for Identify's
    for(int opIndex = 0; opIndex < _interceptOps.count; opIndex++) {
        NSString *operation = _interceptOps[opIndex];
        NSMutableDictionary *mergedOperationKVPs = [NSMutableDictionary dictionary];

        [AMPUtils addNonNilEntriesToDictionary:mergedOperationKVPs fromDictionary:userPropertyOperations[operation]];
        [AMPUtils addNonNilEntriesToDictionary:mergedOperationKVPs fromDictionary:userPropertyOperationsToMerge[operation]];

        if (mergedOperationKVPs.count > 0) {
            [mergedUserProperties setValue:mergedOperationKVPs forKey:operation];
        }
    }

    return mergedUserProperties;
}

- (void)scheduleTransfer {
    if (!_transferScheduled) {
        _transferScheduled = YES;
        __block __weak AMPIdentifyInterceptor *weakSelf = self;
        int interceptedUploadPeriodSeconds = _interceptedUploadPeriodSeconds;
        [_backgroundQueue addOperationWithBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf performSelector:@selector(transferInterceptedIdentify) withObject:nil afterDelay:interceptedUploadPeriodSeconds];
            });
        }];
    }
}

// Transfers all intercepted Identify's as a single Identify to (non-intercepted) Identify storage
- (void)transferInterceptedIdentify {
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
        } else {
            AMPLITUDE_ERROR(@"ERROR: could not JSONSerialize intercepted event type %@: %@", eventType, error);
            // TODO: If the events are unreadable, should we clear intercepted storage to prevent errors for subsequent events?
        }
    }
    _transferScheduled = NO;
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

        mergedUserProperties = [self mergeUserPropertyOperations:mergedUserProperties
                                    withUserPropertiesOperations:curUserProperties];
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

- (void)setDisabled:(BOOL)disable {
    _disabled = disable;
}

- (AMPDatabaseHelper *)dbHelper {
    return _dbHelper;
}

@end
