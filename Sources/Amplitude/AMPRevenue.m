//
//  AMPRevenue.m
//  Amplitude
//
//  Created by Daniel Jih on 04/18/16.
//  Copyright © 2016 Amplitude. All rights reserved.
//

#ifndef AMPLITUDE_DEBUG
#define AMPLITUDE_DEBUG 0
#endif

#ifndef AMPLITUDE_LOG
#if AMPLITUDE_DEBUG
#   define AMPLITUDE_LOG(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#   define AMPLITUDE_LOG(...)
#endif
#endif

#import "AMPRevenue.h"
#import "AMPConstants.h"
#import "AMPUtils.h"

@interface AMPRevenue()

@end

@implementation AMPRevenue{}

- (instancetype)init {
    if ((self = [super init])) {
        _quantity = 1;
    }
    return self;
}

/*
 * Create an AMPRevenue object
 */
+ (instancetype)revenue {
    return [[self alloc] init];
}

- (BOOL)isValidRevenue {
    if (_price == nil) {
        AMPLITUDE_LOG(@"Invalid revenue, need to set price field");
        return NO;
    }
    return YES;
}

- (AMPRevenue*)setProductIdentifier:(NSString *) productIdentifier {
    if ([AMPUtils isEmptyString:productIdentifier]) {
        AMPLITUDE_LOG(@"Invalid empty productIdentifier");
        return self;
    }

    _productId = productIdentifier;
    return self;
}

- (AMPRevenue*)setQuantity:(NSInteger)quantity {
    _quantity = quantity;
    return self;
}

- (AMPRevenue*)setPrice:(NSNumber *)price {
    _price = price;
    return self;
}

- (AMPRevenue*)setRevenueType:(NSString*)revenueType {
    _revenueType = revenueType;
    return self;
}

- (AMPRevenue*)setReceipt:(NSData*)receipt {
    _receipt = receipt;
    return self;
}

- (AMPRevenue*)setEventProperties:(NSDictionary*)eventProperties {
    eventProperties = [eventProperties copy];
    _properties = eventProperties;
    return self;
}

- (NSDictionary*)toNSDictionary {
    NSMutableDictionary *dict;
    if (_properties == nil) {
        dict = [[NSMutableDictionary alloc] init];
    } else {
        dict = [_properties mutableCopy];
    }

    [dict setValue:_productId forKey:AMP_REVENUE_PRODUCT_ID];
    [dict setValue:[NSNumber numberWithInteger:_quantity] forKey:AMP_REVENUE_QUANTITY];
    [dict setValue:_price forKey:AMP_REVENUE_PRICE];
    [dict setValue:_revenueType forKey:AMP_REVENUE_REVENUE_TYPE];

    if ([_receipt respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        [dict setValue:[_receipt base64EncodedStringWithOptions:0] forKey:AMP_REVENUE_RECEIPT];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
        [dict setValue:[_receipt base64Encoding] forKey:AMP_REVENUE_RECEIPT];
#pragma clang diagnostic pop
    }

    return dict;
}

@end
