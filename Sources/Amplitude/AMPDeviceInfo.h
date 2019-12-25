//
//  AMPDeviceInfo.h

#import <Foundation/Foundation.h>

@interface AMPDeviceInfo: NSObject

- (instancetype)init:(BOOL)disableIdfaTracking;

@property (readonly, strong, nonatomic) NSString *appVersion;
@property (readonly, strong, nonatomic) NSString *osName;
@property (readonly, strong, nonatomic) NSString *osVersion;
@property (readonly, strong, nonatomic) NSString *manufacturer;
@property (readonly, strong, nonatomic) NSString *model;
@property (readonly, strong, nonatomic) NSString *carrier;
@property (readonly, strong, nonatomic) NSString *country;
@property (readonly, strong, nonatomic) NSString *language;
@property (readonly, strong, nonatomic) NSString *advertiserID;
@property (readonly, strong, nonatomic) NSString *vendorID;

+ (NSString*) generateUUID;

@end
