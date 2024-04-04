//
//  AMPEventUtils.m
//  Copyright (c) 2023 Amplitude Inc. (https://amplitude.com/)
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

#import "AMPUtils.h"
#import "AMPEventUtils.h"

@interface AMPEventUtils ()
@end

static NSString *const SEQUENCE_NUMBER = @"sequence_number";

@implementation AMPEventUtils

+ (instancetype)alloc {
    // Util class cannot be instantiated.
    return nil;
}

+ (NSString *_Nullable)getUserId:(NSDictionary *_Nonnull)event {
    return [event valueForKey:@"user_id"];
}

+ (NSString *_Nullable)getDeviceId:(NSDictionary *_Nonnull)event {
    return [event valueForKey:@"device_id"];
}

+ (long long)getEventId:(NSDictionary *_Nonnull)event {
    return [[event objectForKey:@"event_id"] longValue];
}

+ (NSString *)getEventType:(NSDictionary *_Nonnull)event {
    return [event valueForKey:@"event_type"];
}

+ (NSMutableDictionary *_Nullable)getGroups:(NSDictionary *_Nonnull)event {
    NSMutableDictionary *groups = [event valueForKey:@"groups"];
    return (groups == nil || groups.count == 0) ? nil : groups;
}

+ (NSMutableDictionary *)getUserProperties:(NSDictionary *_Nonnull)event {
    return [event valueForKey:@"user_properties"];
}

+ (void)setUserProperties:(NSMutableDictionary *_Nonnull)event userProperties:(NSMutableDictionary *_Nonnull)userProperties {
    return [event setValue:userProperties forKey:@"user_properties"];
}

// Note: This doesn't handle equality
+ (BOOL)hasLowerSequenceNumber:(NSDictionary *_Nonnull)event comparedTo:(NSDictionary *_Nonnull)otherEvent {
    return ([event objectForKey:SEQUENCE_NUMBER] == nil ||
                ([[event objectForKey:SEQUENCE_NUMBER] longLongValue] <
                 [[otherEvent objectForKey:SEQUENCE_NUMBER] longLongValue]));
}

+ (NSString *_Nullable)getJsonString:(NSDictionary *_Nonnull)event eventType:(NSString *_Nonnull)eventType error:(NSError **)error {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[AMPUtils makeJSONSerializable:event] options:0 error:error];
    if (*error != nil) {
        AMPLITUDE_ERROR(@"ERROR: could not JSONSerialize event type %@: %@", eventType, *error);
        return nil;
    }

    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if ([AMPUtils isEmptyString:jsonString]) {
        AMPLITUDE_ERROR(@"ERROR: JSONSerializing event type %@ resulted in an NULL string", eventType);
        *error = [NSError errorWithDomain:@"com.amplitude"
                          code:100
                          userInfo:@{
                            NSLocalizedDescriptionKey:@"Something went wrong"
                          }
                 ];
        return nil;
    }

    return jsonString;
}

@end
