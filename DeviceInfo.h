//
//  DeviceInfo.h

#import <CoreLocation/CoreLocation.h>

@interface DeviceInfo : NSObject

-(id) init;
@property (readonly) NSString *versionName;
@property (readonly) NSString *buildVersionRelease;
@property (readonly) NSString *phoneManufacturer;
@property (readonly) NSString *phoneModel;
@property (readonly) NSString *phoneCarrier;
@property (readonly) NSString *country;
@property (readonly) NSString *language;
@property (readonly) NSString *advertiserID;
@property (readonly) NSString *vendorID;

-(NSString*) generateUUID;

@end