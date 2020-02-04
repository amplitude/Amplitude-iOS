//
//  AMPTrackingOptions.h
//  Amplitude
//
//  Created by Daniel Jih on 7/20/18.
//  Copyright © 2018 Amplitude. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMPTrackingOptions : NSObject

@property (nonatomic, strong, readonly) NSMutableSet *disabledFields;

- (AMPTrackingOptions*)disableCarrier;
- (AMPTrackingOptions*)disableCity;
- (AMPTrackingOptions*)disableCountry;
- (AMPTrackingOptions*)disableDeviceManufacturer;
- (AMPTrackingOptions*)disableDeviceModel;
- (AMPTrackingOptions*)disableDMA;
- (AMPTrackingOptions*)disableIDFA;
- (AMPTrackingOptions*)disableIDFV;
- (AMPTrackingOptions*)disableIPAddress;
- (AMPTrackingOptions*)disableLanguage;
- (AMPTrackingOptions*)disableLatLng;
- (AMPTrackingOptions*)disableOSName;
- (AMPTrackingOptions*)disableOSVersion;
- (AMPTrackingOptions*)disablePlatform;
- (AMPTrackingOptions*)disableRegion;
- (AMPTrackingOptions*)disableVersionName;

- (BOOL)shouldTrackCarrier;
- (BOOL)shouldTrackCity;
- (BOOL)shouldTrackCountry;
- (BOOL)shouldTrackDeviceManufacturer;
- (BOOL)shouldTrackDeviceModel;
- (BOOL)shouldTrackDMA;
- (BOOL)shouldTrackIDFA;
- (BOOL)shouldTrackIDFV;
- (BOOL)shouldTrackIPAddress;
- (BOOL)shouldTrackLanguage;
- (BOOL)shouldTrackLatLng;
- (BOOL)shouldTrackOSName;
- (BOOL)shouldTrackOSVersion;
- (BOOL)shouldTrackPlatform;
- (BOOL)shouldTrackRegion;
- (BOOL)shouldTrackVersionName;

- (NSMutableDictionary *)getApiPropertiesTrackingOption;
- (AMPTrackingOptions *)mergeIn: (AMPTrackingOptions *)options;
+ (instancetype)options;
+ (AMPTrackingOptions *)forCoppaControl;
+ (AMPTrackingOptions *)copyOf: (AMPTrackingOptions *)origin;

@end
