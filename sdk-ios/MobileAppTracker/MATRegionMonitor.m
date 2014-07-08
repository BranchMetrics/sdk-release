//
//  MATRegionMonitor.m
//  MobileAppTracker
//
//  Created by John Bender on 4/30/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import "MATRegionMonitor.h"
#import "MobileAppTracker.h"
#import "Common/MATKeyStrings.h"
#import <CoreLocation/CoreLocation.h>

@interface MobileAppTracker (PrivateMethods)
+(void) setRegionName:(NSString*)regionName;
+(void) setLocationAuthorizationStatus:(NSInteger)authStatus;
@end


@interface MATRegionMonitor() <CLLocationManagerDelegate>
{
    CLLocationManager *locationManager;
    
#if DEBUG_REGION
    BOOL delegateRespondsToRanging;
    BOOL delegateRespondsToAuthStatus;
#endif
}
@end


@implementation MATRegionMonitor

-(void) startLocationManager
{
    if( [CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]] ) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // This must be on the main thread. I have no idea why.
            locationManager = [CLLocationManager new];
            locationManager.delegate = self;
        }];
    }

    [MobileAppTracker setLocationAuthorizationStatus:kCLAuthorizationStatusNotDetermined];
#if DEBUG_REGION
    if( delegateRespondsToAuthStatus )
        [self.delegate performSelector:@selector(mobileAppTrackerChangedAuthStatusTo:) withObject:@(kCLAuthorizationStatusNotDetermined)];
#endif
}

-(void) addBeaconRegion:(NSUUID*)UUID
                 nameId:(NSString*)nameId
                majorId:(NSUInteger)majorId
                minorId:(NSUInteger)minorId
{
    if( !locationManager ) {
        [self startLocationManager];
    }

    CLBeaconRegion *region = nil;
    if( majorId > 0 ) {
        if( minorId > 0 ) {
            region = [[CLBeaconRegion alloc] initWithProximityUUID:UUID major:majorId minor:minorId identifier:nameId];
        }
        else {
            region = [[CLBeaconRegion alloc] initWithProximityUUID:UUID major:majorId identifier:nameId];
        }
    }
    else {
        region = [[CLBeaconRegion alloc] initWithProximityUUID:UUID identifier:nameId];
    }

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        // This must be on the main thread. I have no idea why.
        [locationManager startMonitoringForRegion:region];
#if DEBUG_REGION
        [self printRegions];
#endif
    }];
}

-(void) setDelegate:(id<MobileAppTrackerRegionDelegate>)delegate
{
    _delegate = delegate;

#if DEBUG_REGION
    // check existence of secret ranging delegate methods
    delegateRespondsToRanging = [delegate respondsToSelector:@selector(mobileAppTrackerDidRangeBeacons:inRegion:)];
    delegateRespondsToAuthStatus = [delegate respondsToSelector:@selector(mobileAppTrackerChangedAuthStatusTo:)];
#endif
}

#if DEBUG_REGION
-(void) printRegions
{
    for( CLRegion *region in locationManager.monitoredRegions )
        NSLog( @"monitoring region %@", region.identifier );
}
#endif

-(void) measureEventForRegion:(CLRegion*)region
{
    [MobileAppTracker setRegionName:region.identifier];
    [MobileAppTracker measureAction:EVENT_GEOFENCE];
    [self.delegate mobileAppTrackerDidEnterRegion:region];
}

#pragma mark - Location manager delegate

-(void) locationManager:(CLLocationManager*)lm didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [MobileAppTracker setLocationAuthorizationStatus:status];
#if DEBUG_REGION
    NSLog( @"location manager auth status changed to %d", status );
    if( delegateRespondsToAuthStatus )
        [self.delegate performSelector:@selector(mobileAppTrackerChangedAuthStatusTo:) withObject:@(status)];
#endif
}

#if DEBUG_REGION
-(void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog( @"location manager did fail with error %@", error );
}

-(void) locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog( @"did start monitoring for region %@", region.identifier );
}

-(void) locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog( @"monitoring did fail for region %@", region.identifier );
}
#endif

-(void) locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
#if DEBUG_REGION
    NSLog( @"did enter region %@", region.identifier );
    if( delegateRespondsToRanging )
        [manager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
#endif
    [self measureEventForRegion:region];
}

-(void) locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
#if DEBUG_REGION
    NSLog( @"did exit region %@", region.identifier );
    if( delegateRespondsToRanging )
        [manager stopRangingBeaconsInRegion:(CLBeaconRegion*)region];
#endif
    [self.delegate mobileAppTrackerDidExitRegion:region];
}

-(void) locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    static CLRegionState prevState = CLRegionStateUnknown;

#if DEBUG_REGION
    NSLog( @"did determine state %d for region %@", (int)state, region.identifier );
#endif
    if( state == CLRegionStateInside && prevState == CLRegionStateUnknown ) {
        // when we start inside the region
        [self measureEventForRegion:region];
#if DEBUG_REGION
        if( delegateRespondsToRanging )
            [manager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
#endif
    }
    
    prevState = state;
}

#if DEBUG_REGION
-(void) locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if( delegateRespondsToRanging ) {
        [self.delegate performSelector:@selector(mobileAppTrackerDidRangeBeacons:inRegion:) withObject:beacons withObject:region];
    }
}

-(void) locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog( @"ranging beacons failed for %@", region.identifier );
}
#endif

@end
