//
//  LocationManagerDelegate.m
//  Hash Helper
//
//  Created by Spenser Skates on 8/19/12.
//  Copyright (c) 2012 GiraffeGraph. All rights reserved.
//

#import "LocationManagerDelegate.h"
#import "EventLog.h"

@implementation LocationManagerDelegate


- (void)locationManager:(CLLocationManager*) manager didFailWithError:(NSError*) error
{
    if ([error code] == kCLErrorDenied) {
        [EventLog stopListeningForLocation];
    }
}

- (void)locationManager:(CLLocationManager*) manager didUpdateToLocation:(CLLocation*) newLocation fromLocation:(CLLocation*) oldLocation
{
    [EventLog setLocation:newLocation];
}

- (void)locationManager:(CLLocationManager*) manager didChangeAuthorizationStatus:(CLAuthorizationStatus) status
{

}

@end
