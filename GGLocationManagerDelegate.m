//
//  GGLocationManagerDelegate.m
//  Fawkes
//
//  Created by Spenser Skates on 8/19/12.
//  Copyright (c) 2012 GiraffeGraph. All rights reserved.
//

#import "GGLocationManagerDelegate.h"
#import "GGEventLog.h"

@implementation GGLocationManagerDelegate


- (void)locationManager:(CLLocationManager*) manager didFailWithError:(NSError*) error
{
    if ([error code] == kCLErrorDenied) {
        [GGEventLog stopListeningForLocation];
    }
}

- (void)locationManager:(CLLocationManager*) manager didUpdateToLocation:(CLLocation*) newLocation fromLocation:(CLLocation*) oldLocation
{
    [GGEventLog setLocation:newLocation];
}

- (void)locationManager:(CLLocationManager*) manager didChangeAuthorizationStatus:(CLAuthorizationStatus) status
{

}

@end
