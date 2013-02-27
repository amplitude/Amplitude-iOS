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
}

- (void)locationManager:(CLLocationManager*) manager didUpdateToLocation:(CLLocation*) newLocation fromLocation:(CLLocation*) oldLocation
{
}

- (void)locationManager:(CLLocationManager*) manager didChangeAuthorizationStatus:(CLAuthorizationStatus) status
{
    if (status == kCLAuthorizationStatusAuthorized) {
        SEL updateLocation = NSSelectorFromString(@"updateLocation");
        [GGEventLog performSelector:updateLocation];
    }
}

@end
