//
//  AMPTrackingOptions.m
//  Amplitude
//
//  Created by Daniel Jih on 7/20/18.
//  Copyright © 2018 Amplitude. All rights reserved.
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

#import <Foundation/Foundation.h>
#import "AMPTrackingOptions.h"
#import "AMPARCMacros.h"
#import "AMPConstants.h"

@interface AMPTrackingOptions()
@end

@implementation AMPTrackingOptions
{
    NSMutableSet *_disabledFields;
    NSArray *SERVER_SIDE_PROPERTIES;
}

- (id)init
{
    if ((self = [super init])) {
        _disabledFields = [[NSMutableSet alloc] init];
    }
    return self;
}

+ (instancetype)options
{
    return SAFE_ARC_AUTORELEASE([[self alloc] init]);
}

- (void)dealloc
{
    SAFE_ARC_RELEASE(_disabledFields);
    SAFE_ARC_SUPER_DEALLOC();
}

- (AMPTrackingOptions*)disableCarrier
{
    [self disableTrackingField:AMP_TRACKING_OPTION_CARRIER];
}

- (BOOL)shouldTrackCarrier
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_CARRIER];
}

- (AMPTrackingOptions*)disableCity
{
    [self disableTrackingField:AMP_TRACKING_OPTION_CITY];
}

- (BOOL)shouldTrackCity
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_CITY];
}

- (AMPTrackingOptions*)disableCountry
{
    [self disableTrackingField:AMP_TRACKING_OPTION_COUNTRY];
}

- (BOOL)shouldTrackCountry
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_COUNTRY];
}

- (AMPTrackingOptions*)disableDeviceManufacturer
{
    [self disableTrackingField:AMP_TRACKING_OPTION_DEVICE_MANUFACTURER];
}

- (BOOL)shouldTrackDeviceModel
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_DEVICE_MODEL];
}

- (AMPTrackingOptions*)disableDMA
{
    [self disableTrackingField:AMP_TRACKING_OPTION_DMA];
}

- (BOOL)shouldTrackDMA
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_DMA];
}

- (AMPTrackingOptions*)disableIDFA
{
    [self disableTrackingField:AMP_TRACKING_OPTION_IDFA];
}

- (BOOL)shouldTrackIDFA
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_IDFA];
}

- (AMPTrackingOptions*)disableIDFV
{
    [self disableTrackingField:AMP_TRACKING_OPTION_IDFV];
}

- (BOOL)shouldTrackIDFV
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_IDFV];
}

- (AMPTrackingOptions*)disableIPAddress
{
    [self disableTrackingField:AMP_TRACKING_OPTION_IP_ADDRESS];
}

- (BOOL)shouldTrackIPAddress
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_IP_ADDRESS];
}

- (AMPTrackingOptions*)disableLanguage
{
    [self disableTrackingField:AMP_TRACKING_OPTION_LANGUAGE];
}

- (BOOL)shouldTrackLanguage
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_LANGUAGE];
}

- (AMPTrackingOptions*)disableLatLon
{
    [self disableTrackingField:AMP_TRACKING_OPTION_LAT_LON];
}

- (BOOL)shouldTrackLatLon
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_LAT_LON];
}

- (AMPTrackingOptions*)disableOSName
{
    [self disableTrackingField:AMP_TRACKING_OPTION_OS_NAME];
}

- (BOOL)shouldTrackOSName
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_OS_NAME];
}

- (AMPTrackingOptions*)disableOSVersion
{
    [self disableTrackingField:AMP_TRACKING_OPTION_OS_VERSION];
}

- (BOOL)shouldTrackOSVersion
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_OS_VERSION];
}

- (AMPTrackingOptions*)disablePlatform
{
    [self disableTrackingField:AMP_TRACKING_OPTION_PLATFORM];
}

- (BOOL)shouldTrackPlatform
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_PLATFORM];
}

- (AMPTrackingOptions*)disableRegion
{
    [self disableTrackingField:AMP_TRACKING_OPTION_REGION];
}

- (BOOL)shouldTrackRegion
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_REGION];
}

- (AMPTrackingOptions*)disableVersionName
{
    [self disableTrackingField:AMP_TRACKING_OPTION_VERSION_NAME];
}

- (BOOL)shouldTrackVersionName
{
    return [self shouldTrackField:AMP_TRACKING_OPTION_VERSION_NAME];
}

- (void) disableTrackingField:(NSString*)field
{
    [_disabledFields addObject:field];
}

- (BOOL) shouldTrackField:(NSString*)field
{
    return ![_disabledFields containsObject:field];
}

- (NSMutableDictionary*) getApiPropertiesTrackingOption {
    NSMutableDictionary *apiPropertiesTrackingOptions = [[NSMutableDictionary alloc] init];
    if ([_disabledFields count] == 0) {
        return SAFE_ARC_AUTORELEASE(apiPropertiesTrackingOptions);
    }

    for (id key in @[AMP_TRACKING_OPTION_CITY, AMP_TRACKING_OPTION_COUNTRY, AMP_TRACKING_OPTION_DMA, AMP_TRACKING_OPTION_IP_ADDRESS, AMP_TRACKING_OPTION_LAT_LON, AMP_TRACKING_OPTION_REGION]) {
        if ([_disabledFields containsObject:key]) {
            [apiPropertiesTrackingOptions setObject:[NSNumber numberWithBool:NO] forKey:key];
        }
    }

    return SAFE_ARC_AUTORELEASE(apiPropertiesTrackingOptions);
}

@end
