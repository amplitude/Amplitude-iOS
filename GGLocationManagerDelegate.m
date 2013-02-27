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
        SEL stopListeningForLocation = NSSelectorFromString(@"stopListeningForLocation");
        [GGEventLog performSelector:stopListeningForLocation];
    }
}

- (void)locationManager:(CLLocationManager*) manager didUpdateToLocation:(CLLocation*) newLocation fromLocation:(CLLocation*) oldLocation
{
    NSLog(@"didUpdateToLocation:%@", newLocation);
    SEL setLocation = NSSelectorFromString(@"setLocation:");
    [GGEventLog performSelector:setLocation withObject:newLocation];
    SEL stopListeningForLocation = NSSelectorFromString(@"stopListeningForLocation");
    [GGEventLog performSelector:stopListeningForLocation];
}

- (void)locationManager:(CLLocationManager*) manager didChangeAuthorizationStatus:(CLAuthorizationStatus) status
{
    NSLog(@"Did change authorization status:%d", status);
    if (status == kCLAuthorizationStatusAuthorized) {
        SEL startListeningForLocationIfAvailable = NSSelectorFromString(@"startListeningForLocationIfAvailable");
        [GGEventLog performSelector:startListeningForLocationIfAvailable];
    } else {
        SEL stopListeningForLocation = NSSelectorFromString(@"stopListeningForLocation");
        [GGEventLog performSelector:stopListeningForLocation];
    }
}

@end
