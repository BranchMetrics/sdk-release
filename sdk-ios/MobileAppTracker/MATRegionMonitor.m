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
#import "Common/MATEvent_internal.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface MobileAppTracker (PrivateMethods)
+ (void)setLocationAuthorizationStatus:(NSInteger)authStatus;
+ (void)setBluetoothState:(NSInteger)bluetoothState;
@end

#ifdef MAT_USE_LOCATION
@interface MATRegionMonitor() <CLLocationManagerDelegate, CBCentralManagerDelegate>
{
    CLLocationManager *locationManager;
    CBCentralManager *bluetoothManager;
    BOOL startCalled;
    
    BOOL delegateRespondsToDidEnter;
    BOOL delegateRespondsToDidExit;
    BOOL delegateRespondsToAuthStatus;
    BOOL delegateRespondsToBTState;
#if DEBUG_REGION
    BOOL delegateRespondsToRanging;
#endif
}
@end
#endif


@implementation MATRegionMonitor

- (void)startLocationManager
{
#ifdef MAT_USE_LOCATION
    startCalled = TRUE;
    
    bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self
                                                            queue:dispatch_get_current_queue()
                                                          options:@{CBCentralManagerOptionShowPowerAlertKey: @(NO)}];
    [MobileAppTracker setBluetoothState:bluetoothManager.state];
    
    CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
    [MobileAppTracker setLocationAuthorizationStatus:authStatus];
    
    if( authStatus == kCLAuthorizationStatusRestricted ||
       authStatus == kCLAuthorizationStatusDenied )
        return;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        locationManager = [CLLocationManager new];
        locationManager.delegate = self;
        
        if( authStatus == kCLAuthorizationStatusNotDetermined )
            [locationManager requestAlwaysAuthorization];
    }];
#endif
}

- (void)addBeaconRegion:(NSUUID*)UUID
                 nameId:(NSString*)nameId
                majorId:(NSUInteger)majorId
                minorId:(NSUInteger)minorId
{
#ifdef MAT_USE_LOCATION
    if( !startCalled ) {
        [self startLocationManager];
    }
    
    if( ![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]] ) {
        NSLog( @"beacon monitoring is not available -- are you using the simulator?" );
        return;
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
#endif // MAT_USE_LOCATION
}

#ifdef MAT_USE_LOCATION
- (void)setDelegate:(id<MobileAppTrackerRegionDelegate>)delegate
{
    _delegate = delegate;
    
    delegateRespondsToDidEnter = [delegate respondsToSelector:@selector(mobileAppTrackerDidEnterRegion:)];
    delegateRespondsToDidExit = [delegate respondsToSelector:@selector(mobileAppTrackerDidExitRegion:)];
    delegateRespondsToAuthStatus = [delegate respondsToSelector:@selector(mobileAppTrackerChangedAuthStatusTo:)];
    delegateRespondsToBTState = [delegate respondsToSelector:@selector(mobileAppTrackerChangedBluetoothStateTo:)];
#if DEBUG_REGION
    // check existence of secret ranging delegate methods
    delegateRespondsToRanging = [delegate respondsToSelector:@selector(mobileAppTrackerDidRangeBeacons:inRegion:)];
    NSLog( @"responds to ranging: %d", delegateRespondsToRanging );
#endif
}

#if DEBUG_REGION
- (void)printRegions
{
    for( CLRegion *region in locationManager.monitoredRegions )
        NSLog( @"monitoring region %@", region.identifier );
}
#endif

- (void)measureEventForRegion:(CLRegion*)region
{
    MATEvent *event = [MATEvent eventWithName:MAT_EVENT_GEOFENCE];
    event.iBeaconRegionId = region.identifier;
    
    [MobileAppTracker measureEvent:event];
    
    if( delegateRespondsToDidEnter )
        [self.delegate mobileAppTrackerDidEnterRegion:region];
}


#pragma mark - Location manager delegate

- (void)locationManager:(CLLocationManager*)lm didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [MobileAppTracker setLocationAuthorizationStatus:status];
    if( delegateRespondsToAuthStatus )
        [self.delegate mobileAppTrackerChangedAuthStatusTo:status];
}

#if DEBUG_REGION
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog( @"location manager did fail with error %@", error );
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    NSLog( @"did start monitoring for region %@", region.identifier );
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog( @"monitoring did fail for region %@", region.identifier );
}
#endif

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
#if DEBUG_REGION
    NSLog( @"did enter region %@", region.identifier );
    if( delegateRespondsToRanging )
        [manager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
#endif
    [self measureEventForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
#if DEBUG_REGION
    NSLog( @"did exit region %@", region.identifier );
    if( delegateRespondsToRanging )
        [manager stopRangingBeaconsInRegion:(CLBeaconRegion*)region];
#endif
    if( delegateRespondsToDidExit )
        [self.delegate mobileAppTrackerDidExitRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
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
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region
{
    if( delegateRespondsToRanging ) {
        [self.delegate performSelector:@selector(mobileAppTrackerDidRangeBeacons:inRegion:) withObject:beacons withObject:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error
{
    NSLog( @"ranging beacons failed for %@", region.identifier );
}
#endif


#pragma mark - Bluetooth manager delegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    [MobileAppTracker setBluetoothState:central.state];
    if( delegateRespondsToBTState )
        [self.delegate mobileAppTrackerChangedBluetoothStateTo:central.state];
}

#endif // MAT_USE_LOCATION

@end
