#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#endif

#import <Foundation/Foundation.h>

//! Project version number for Amplitude.
FOUNDATION_EXPORT double AmplitudeVersionNumber;

//! Project version string for Amplitude.
FOUNDATION_EXPORT const unsigned char AmplitudeVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Amplitude/PublicHeader.h>

#import <Amplitude/Amplitude.h>
#import <Amplitude/AMPIdentify.h>
#import <Amplitude/AMPRevenue.h>
#import <Amplitude/AMPTrackingOptions.h>
#import <Amplitude/Amplitude+SSLPinning.h>
