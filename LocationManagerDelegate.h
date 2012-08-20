//
//  LocationManagerDelegate.h
//  Hash Helper
//
//  Created by Spenser Skates on 8/19/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationManagerDelegate : NSObject <CLLocationManagerDelegate>

- (void)locationManager:(CLLocationManager*) manager didFailWithError:(NSError*) error;

- (void)locationManager:(CLLocationManager*) manager didUpdateToLocation:(CLLocation*) newLocation fromLocation:(CLLocation*) oldLocation;

- (void)locationManager:(CLLocationManager*) manager didChangeAuthorizationStatus:(CLAuthorizationStatus) status;

@end
