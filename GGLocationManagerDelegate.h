//
//  GGLocationManagerDelegate.h
//  Fawkes
//
//  Created by Spenser Skates on 8/19/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface GGLocationManagerDelegate : NSObject <CLLocationManagerDelegate>

- (void)locationManager:(CLLocationManager*) manager didFailWithError:(NSError*) error;

- (void)locationManager:(CLLocationManager*) manager didUpdateToLocation:(CLLocation*) newLocation fromLocation:(CLLocation*) oldLocation;

- (void)locationManager:(CLLocationManager*) manager didChangeAuthorizationStatus:(CLAuthorizationStatus) status;

@end
