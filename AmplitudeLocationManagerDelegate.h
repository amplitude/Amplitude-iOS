//
//  AmplitudeLocationManagerDelegate.h

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface AmplitudeLocationManagerDelegate : NSObject <CLLocationManagerDelegate>

- (void)locationManager:(CLLocationManager*) manager didFailWithError:(NSError*) error;

- (void)locationManager:(CLLocationManager*) manager didUpdateToLocation:(CLLocation*) newLocation fromLocation:(CLLocation*) oldLocation;

- (void)locationManager:(CLLocationManager*) manager didChangeAuthorizationStatus:(CLAuthorizationStatus) status;

@end
