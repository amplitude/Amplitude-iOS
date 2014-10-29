//
//  DeviceInfo.m

#import <Foundation/Foundation.h>
#import "AmplitudeARCMacros.h"
#import <UIKit/UIKit.h>
#import "DeviceInfo.h"
#import <sys/sysctl.h>

#include <sys/types.h>

@interface DeviceInfo ()
@end

@implementation DeviceInfo {
    NSObject* networkInfo;
}

@synthesize versionName = _versionName;
@synthesize buildVersionRelease = _buildVersionRelease;
@synthesize phoneModel = _phoneModel;
@synthesize phoneCarrier = _phoneCarrier;
@synthesize country = _country;
@synthesize language = _language;
@synthesize advertiserID = _advertiserID;
@synthesize vendorID = _vendorID;




-(id) init {
    self = [super init];
    return self;
}

-(NSString*) versionName {
    if (!_versionName) {
        _versionName = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
    }
    return _versionName;
}

-(NSString*) buildVersionRelease {
    if (!_buildVersionRelease) {
        _buildVersionRelease = [[UIDevice currentDevice] systemVersion];
    }
    return _buildVersionRelease;
}

-(NSString*) phoneManufacturer {
    return @"Apple";
}

-(NSString*) phoneModel {
    if (!_phoneModel) {
        _phoneModel = [DeviceInfo getPhoneModel];
    }
    return _phoneModel;
}

-(NSString*) phoneCarrier {
    if (!_phoneCarrier) {
        Class CTTelephonyNetworkInfo = NSClassFromString(@"CTTelephonyNetworkInfo");
        SEL subscriberCellularProvider = NSSelectorFromString(@"subscriberCellularProvider");
        SEL carrierName = NSSelectorFromString(@"carrierName");
        if (CTTelephonyNetworkInfo && subscriberCellularProvider && carrierName) {
            networkInfo = SAFE_ARC_RETAIN([[NSClassFromString(@"CTTelephonyNetworkInfo") alloc] init]);
            id carrier = nil;
            id (*imp1)(id, SEL) = (id (*)(id, SEL))[networkInfo methodForSelector:subscriberCellularProvider];
            if (imp1) {
                carrier = imp1(networkInfo, subscriberCellularProvider);
            }
            NSString* (*imp2)(id, SEL) = (NSString* (*)(id, SEL))[carrier methodForSelector:carrierName];
            if (imp2) {
                _phoneCarrier = imp2(carrier, carrierName);
            }
        }
    }
    return _phoneCarrier;
}

-(NSString*) country {
    if (!_country) {
        _country = [[NSLocale localeWithLocaleIdentifier:@"en_US"] displayNameForKey:
            NSLocaleCountryCode value:
            [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]];
    }
    return _country;
}

-(NSString*) language {
    if (!_language) {
        _language = [[NSLocale localeWithLocaleIdentifier:@"en_US"] displayNameForKey:
            NSLocaleLanguageCode value:[[NSLocale preferredLanguages] objectAtIndex:0]];
    }
    return _language;
}

-(NSString*) advertiserID {
    if (!_advertiserID) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= (float) 6.0) {
            NSString *advertiserId = [DeviceInfo getAdvertiserID:5];
            if (advertiserId != nil &&
                ![advertiserId isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
                _advertiserID = advertiserId;
            }
        }
    }
    return _advertiserID;
}

-(NSString*) vendorID {
    if (!_vendorID) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= (float) 6.0) {
            NSString *identifierForVendor = [DeviceInfo getVendorID:5];
            if (identifierForVendor != nil &&
                ![identifierForVendor isEqualToString:@"00000000-0000-0000-0000-000000000000"]) {
                _vendorID = identifierForVendor;
            }
        }
    }
    return _vendorID;
}

+ (NSString*)getAdvertiserID:(int) maxAttempts
{
    Class ASIdentifierManager = NSClassFromString(@"ASIdentifierManager");
    SEL sharedManager = NSSelectorFromString(@"sharedManager");
    SEL advertisingIdentifier = NSSelectorFromString(@"advertisingIdentifier");
    if (ASIdentifierManager && sharedManager && advertisingIdentifier) {
        id (*imp1)(id, SEL) = (id (*)(id, SEL))[ASIdentifierManager methodForSelector:sharedManager];
        id manager = nil;
        NSUUID *adid = nil;
        NSString *identifier = nil;
        if (imp1) {
            manager = imp1(ASIdentifierManager, sharedManager);
        }
        NSUUID* (*imp2)(id, SEL) = (NSUUID* (*)(id, SEL))[manager methodForSelector:advertisingIdentifier];
        if (imp2) {
            adid = imp2(manager, advertisingIdentifier);
        }
        if (adid) {
            identifier = [adid UUIDString];
        }
        if (identifier == nil && maxAttempts > 0) {
            // Try again every 5 seconds
            [NSThread sleepForTimeInterval:5.0];
            return [DeviceInfo getAdvertiserID:maxAttempts - 1];
        } else {
            return identifier;
        }
    } else {
        return nil;
    }
}

+ (NSString*)getVendorID:(int) maxAttempts
{
    NSString *identifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    if (identifier == nil && maxAttempts > 0) {
        // Try again every 5 seconds
        [NSThread sleepForTimeInterval:5.0];
        return [DeviceInfo getVendorID:maxAttempts - 1];
    } else {
        return identifier;
    }
}

- (NSString*)generateUUID
{
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
#if __has_feature(objc_arc)
    NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
#else
    NSString *uuidStr = (NSString *) CFUUIDCreateString(kCFAllocatorDefault, uuid);
#endif
    CFRelease(uuid);
    // Add "R" at the end of the ID to distinguish it from advertiserId
    NSString *result = [uuidStr stringByAppendingString:@"R"];
    SAFE_ARC_RELEASE(uuidStr);
    return result;
}

+ (NSString*)getPlatformString
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+ (NSString*)getPhoneModel{
    NSString *platform = [self getPlatformString];
    if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1";
    if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone3,3"])    return @"iPhone 4";
    if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([platform isEqualToString:@"iPhone5,1"])    return @"iPhone 5";
    if ([platform isEqualToString:@"iPhone5,2"])    return @"iPhone 5";
    if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([platform isEqualToString:@"iPod5,1"])      return @"iPod Touch 5G";
    if ([platform isEqualToString:@"iPad1,1"])      return @"iPad 1";
    if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,4"])      return @"iPad 2";
    if ([platform isEqualToString:@"iPad2,5"])      return @"iPad Mini";
    if ([platform isEqualToString:@"iPad2,6"])      return @"iPad Mini";
    if ([platform isEqualToString:@"iPad2,7"])      return @"iPad Mini";
    if ([platform isEqualToString:@"iPad3,1"])      return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,2"])      return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,3"])      return @"iPad 3";
    if ([platform isEqualToString:@"iPad3,4"])      return @"iPad 4";
    if ([platform isEqualToString:@"iPad3,5"])      return @"iPad 4";
    if ([platform isEqualToString:@"iPad3,6"])      return @"iPad 4";
    if ([platform isEqualToString:@"i386"])         return @"Simulator";
    if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
    return platform;
}
@end