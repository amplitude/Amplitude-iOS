//
//  AMPLocationManagerDelegate.h

#ifndef AMPLITUDE_LOCATION_TRACKING
#define AMPLITUDE_LOCATION_TRACKING 1
#endif

#if AMPLITUDE_LOCATION_TRACKING

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface AMPLocationManagerDelegate : NSObject <CLLocationManagerDelegate>

- (void)locationManager:(CLLocationManager*) manager didFailWithError:(NSError*) error;

- (void)locationManager:(CLLocationManager*) manager didUpdateToLocation:(CLLocation*) newLocation fromLocation:(CLLocation*) oldLocation;

- (void)locationManager:(CLLocationManager*) manager didChangeAuthorizationStatus:(CLAuthorizationStatus) status;

@end

#endif
