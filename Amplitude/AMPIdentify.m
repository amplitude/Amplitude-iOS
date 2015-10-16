//
//  AMPIdentify.m
//  Amplitude
//
//  Created by Daniel Jih on 10/5/15.
//  Copyright © 2015 Amplitude. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMPIdentify.h"
#import "AMPARCMacros.h"
#import "AMPConstants.h"

@interface AMPIdentify()
@end

@implementation AMPIdentify
{
    NSMutableSet *_userProperties;
}

- (id)init
{
    if (self = [super init]) {
        _userPropertyOperations = [[NSMutableDictionary alloc] init];
        _userProperties = [[NSMutableSet alloc] init];
    }
    return self;
}

+ (instancetype)identify
{
    return SAFE_ARC_AUTORELEASE([[self alloc] init]);
}

- (void)dealloc
{
    SAFE_ARC_RELEASE(_userPropertyOperations);
    SAFE_ARC_RELEASE(_userProperties);
    SAFE_ARC_SUPER_DEALLOC();
}

- (AMPIdentify*)add:(NSString*) property value:(NSObject*) value
{
    if ([value isKindOfClass:[NSNumber class]] || [value isKindOfClass:[NSString class]]) {
        [self addToUserProperties:AMP_OP_ADD property:property value:value];
    } else {
        NSLog(@"Unsupported value type for ADD operation, expecting NSNumber or NSString");
    }
    return self;
}

- (AMPIdentify*)set:(NSString*) property value:(NSObject*) value
{
    [self addToUserProperties:AMP_OP_SET property:property value:value];
    return self;
}

- (AMPIdentify*)setOnce:(NSString*) property value:(NSObject*) value
{
    [self addToUserProperties:AMP_OP_SET_ONCE property:property value:value];
    return self;
}

- (AMPIdentify*)unset:(NSString*) property
{
    [self addToUserProperties:AMP_OP_UNSET property:property value:@"-"];
    return self;
}

- (void)addToUserProperties:(NSString*)operation property:(NSString*) property value:(NSObject*) value
{
    // check if property already used in a previous operation
    if ([_userProperties containsObject:property]) {
        NSLog(@"Already used property '%@' in previous operation, ignoring for operation '%@'", property, operation);
        return;
    }

    NSMutableDictionary *operations = [_userPropertyOperations objectForKey:operation];
    if (operations == nil) {
        operations = [NSMutableDictionary dictionary];
        [_userPropertyOperations setObject:operations forKey:operation];
    }
    [operations setObject:value forKey:property];
    [_userProperties addObject:property];
}

@end
