//
//  TuneRegionMonitor.m
//  Tune
//
//  Created by John Bender on 4/30/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import "TuneRegionMonitor.h"
#import "Tune.h"
#import "Common/TuneEvent_internal.h"
#import "Common/TuneKeyStrings.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface Tune (PrivateMethods)
+ (void)setRegionName:(NSString*)regionName;
+ (void)setLocationAuthorizationStatus:(NSInteger)authStatus;
+ (void)setBluetoothState:(NSInteger)bluetoothState;
@end

#ifdef TUNE_USE_LOCATION
@interface TuneRegionMonitor() <CLLocationManagerDelegate, CBCentralManagerDelegate>
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


@implementation TuneRegionMonitor

- (void)startLocationManager
{
#ifdef TUNE_USE_LOCATION
    startCalled = TRUE;

    bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self
                                                            queue:dispatch_get_main_queue()
                                                          options:@{CBCentralManagerOptionShowPowerAlertKey: @(NO)}];
    [Tune setBluetoothState:bluetoothManager.state];

    CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
    [Tune setLocationAuthorizationStatus:authStatus];

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
#ifdef TUNE_USE_LOCATION
    if( !startCalled ) {
        [self startLocationManager];
    }

    if( ![CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]] ) {
        NSLog( @"Tune: beacon monitoring is not available -- are you using the simulator?" );
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
#endif // TUNE_USE_LOCATION
}

#ifdef TUNE_USE_LOCATION
- (void)setDelegate:(id<TuneRegionDelegate>)delegate
{
    _delegate = delegate;

    delegateRespondsToDidEnter = [delegate respondsToSelector:@selector(tuneDidEnterRegion:)];
    delegateRespondsToDidExit = [delegate respondsToSelector:@selector(tuneDidExitRegion:)];
    delegateRespondsToAuthStatus = [delegate respondsToSelector:@selector(tuneChangedAuthStatusTo:)];
    delegateRespondsToBTState = [delegate respondsToSelector:@selector(tuneChangedBluetoothStateTo:)];
#if DEBUG_REGION
    // check existence of secret ranging delegate methods
    delegateRespondsToRanging = [delegate respondsToSelector:@selector(tuneDidRangeBeacons:inRegion:)];
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
    TuneEvent *event = [TuneEvent eventWithName:TUNE_EVENT_GEOFENCE];
    event.iBeaconRegionId = region.identifier;
    
    [Tune measureEvent:event];
    
    if( delegateRespondsToDidEnter )
        [self.delegate tuneDidEnterRegion:region];
}


#pragma mark - Location manager delegate

- (void)locationManager:(CLLocationManager*)lm didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    [Tune setLocationAuthorizationStatus:status];
    if( delegateRespondsToAuthStatus )
        [self.delegate tuneChangedAuthStatusTo:status];
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
        [self.delegate tuneDidExitRegion:region];
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
        [self.delegate performSelector:@selector(tuneDidRangeBeacons:inRegion:) withObject:beacons withObject:region];
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
    [Tune setBluetoothState:central.state];
    if( delegateRespondsToBTState )
        [self.delegate tuneChangedBluetoothStateTo:central.state];
}

#endif // TUNE_USE_LOCATION

@end
