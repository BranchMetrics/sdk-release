//
//  TuneLocationHelper.m
//  Tune
//
//  Created by Harshal Ogale on 7/6/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneLocationHelper.h"

#import "TuneLocation+Internal.h"
#import "TuneUtils.h"
#import "TuneUserProfile.h"

@interface TuneLocationHelper ()

@end


// Ref: CLLocationManager.CLAuthorizationStatus
// https://developer.apple.com/library/ios/documentation/CoreLocation/Reference/CLLocationManager_Class/index.html#//apple_ref/c/tdef/CLAuthorizationStatus
const int TunekCLAuthorizationStatusAuthorizedAlways = 3; // kCLAuthorizationStatusAuthorizedAlways, kCLAuthorizationStatusAuthorized
const int TunekCLAuthorizationStatusAuthorizedWhenInUse = 4; // kCLAuthorizationStatusAuthorizedWhenInUse

const NSTimeInterval TUNE_LOCATION_UPDATE_DELAY  = 5.;

/*!
 Duration in seconds during which an existing known device location may be reused.
 If the difference in seconds between current timestamp and the location timestamp
 is higher than this value, then a new location update request will be fired.
 */
const NSTimeInterval TUNE_LOCATION_VALIDITY_DURATION = 60.;

// required: local clone of CLLocation.CLLocationCoordinate2D
typedef struct {
    double latitude;
    double longitude;
} TuneCLLocationCoordinate2D;

static id tuneCLLocationManager;
static id tuneCLLocation;

static TuneLocationHelper *tuneSharedLocationHelper;

@implementation TuneLocationHelper


#pragma mark - Init Methods

+ (void)initialize
{
    tuneSharedLocationHelper = [TuneLocationHelper new];
}


#pragma mark - Public Methods

+ (void)getOrRequestDeviceLocation:(NSMutableArray *)resultArr
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    TuneLocation *location = nil;
    
    BOOL isEnabled = [self isLocationEnabled];
    
    // if the CLLocationManager has been created
    if(isEnabled)
    {
        if(nil != tuneCLLocationManager)
        {
            // get the current device location
            [self getCurrentCLLocation];
            
            location = [self tuneLocationFromCLLocation:tuneCLLocation];
        }
        
        if(!location)
        {
            // location is not ready, request a new update
            [tuneSharedLocationHelper startLocationUpdates];
        }
    }
    
    if(location)
    {
        resultArr[0] = location;
    }
#pragma clang diagnostic pop
}

+ (void)getCurrentCLLocation
{
    // get the current device location
    SEL selLocation = @selector(location);
    NSMethodSignature *signature = [tuneCLLocationManager methodSignatureForSelector:selLocation];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:tuneCLLocationManager];
    [invocation setSelector:selLocation];
    [invocation invoke];
    [invocation getReturnValue:&tuneCLLocation];
}

+ (TuneLocation *)tuneLocationFromCLLocation:(id)clLocation
{
    TuneLocation *location = nil;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if(clLocation && [NSNull null] != clLocation)
    {
        // get the location timestamp
        static NSDate *timestamp;
        SEL selTimestamp = @selector(timestamp);
        NSMethodSignature *signature = [clLocation methodSignatureForSelector:selTimestamp];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:clLocation];
        [invocation setSelector:selTimestamp];
        [invocation invoke];
        [invocation getReturnValue:&timestamp];
        
        // check if location is recent enough to be used, otherwise request a new location update
        if(timestamp && [[NSDate date] timeIntervalSinceDate:timestamp] < TUNE_LOCATION_VALIDITY_DURATION)
        {
            TuneCLLocationCoordinate2D coordinate;
            SEL selCoordinate = @selector(coordinate);
            signature = [clLocation methodSignatureForSelector:selCoordinate];
            invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:clLocation];
            [invocation setSelector:selCoordinate];
            [invocation invoke];
            [invocation getReturnValue:&coordinate];
            
            double altitude;
            SEL selAltitude = @selector(altitude);
            signature = [clLocation methodSignatureForSelector:selAltitude];
            invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:clLocation];
            [invocation setSelector:selAltitude];
            [invocation invoke];
            [invocation getReturnValue:&altitude];
            
            double hAccuracy;
            SEL selHorizontalAccu = @selector(horizontalAccuracy);
            signature = [clLocation methodSignatureForSelector:selHorizontalAccu];
            invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:clLocation];
            [invocation setSelector:selHorizontalAccu];
            [invocation invoke];
            [invocation getReturnValue:&hAccuracy];
            
            double vAccuracy;
            SEL selVerticalAccu = @selector(verticalAccuracy);
            signature = [clLocation methodSignatureForSelector:selVerticalAccu];
            invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:clLocation];
            [invocation setSelector:selVerticalAccu];
            [invocation invoke];
            [invocation getReturnValue:&vAccuracy];
            
            DebugLog(@"TuneLocationHelper: found new location = %f, %f, %f, %f, %f, %@", coordinate.latitude, coordinate.longitude, altitude, hAccuracy, vAccuracy, timestamp);
            
            location = [TuneLocation new];
            location.latitude = @(coordinate.latitude);
            location.longitude = @(coordinate.longitude);
            location.altitude = @(altitude);
            location.horizontalAccuracy = @(hAccuracy);
            location.verticalAccuracy = @(vAccuracy);
            location.timestamp = timestamp;
        }
    }
    return location;
}

#pragma mark - Helper Methods

+ (BOOL)isLocationEnabled
{
    BOOL locationEnabled = NO;
    
    Class classLocationManager = [TuneUtils getClassFromString:@"CLLocationManager"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL selAuthStatus = @selector(authorizationStatus);
    SEL selLocationEnabled = @selector(locationServicesEnabled);
#pragma clang diagnostic pop
    if([classLocationManager class]
       && [classLocationManager respondsToSelector:selAuthStatus]
       && [classLocationManager respondsToSelector:selLocationEnabled])
    {
        IMP impAuthStatus = [classLocationManager methodForSelector:selAuthStatus];
        NSInteger authStatus = ((NSInteger (*)(id, SEL))impAuthStatus)(classLocationManager, selAuthStatus);
        
        // Since we are grabbing the auth status anyways we might as well store it.
        [[TuneManager currentManager].userProfile setLocationAuthorizationStatus:@(authStatus)];

        if(TunekCLAuthorizationStatusAuthorizedAlways == authStatus || TunekCLAuthorizationStatusAuthorizedWhenInUse == authStatus)
        {
            IMP impLocationEnabled = [classLocationManager methodForSelector:selLocationEnabled];
            locationEnabled = ((BOOL (*)(id, SEL))impLocationEnabled)(classLocationManager, selLocationEnabled);
        }
    }
    
    DebugLog(@"TuneLocationHelper: isLocationEnabled = %d", locationEnabled);
    
    return locationEnabled;
}

/*!
 Checks if location access is permitted and creates a CLLocationManager if one does not already exist.
 @returns YES if location access is permitted, NO otherwise
 */
+ (BOOL)createLocationManager
{
    BOOL locationEnabled = [self isLocationEnabled];
    
    // if location access is enabled and shared CLLocationManager does not exist, then create a new instance
    if (locationEnabled && nil == tuneCLLocationManager)
    {
        Class classLocationManager = [TuneUtils getClassFromString:@"CLLocationManager"];
        
        tuneCLLocationManager = [classLocationManager new];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        // set location delegate
        [tuneCLLocationManager performSelector:@selector(setDelegate:) withObject:tuneSharedLocationHelper];
#pragma clang diagnostic pop
    }
    
    return locationEnabled;
}

+ (void)startLocationUpdates
{
    [tuneSharedLocationHelper startLocationUpdates];
}

- (void)startLocationUpdates
{
    if ([[self class] createLocationManager])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#pragma clang diagnostic ignored "-Wundeclared-selector"
        // start updating location
        [tuneCLLocationManager performSelector:@selector(startUpdatingLocation)];
#pragma clang diagnostic pop
    }
}


#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(id)manager didFailWithError:(NSError *)error
{
    DebugLog(@"location: didFailWithError: error = %@", error);
}

- (void)locationManager:(id)manager didUpdateToLocation:(id)newLocation fromLocation:(id)oldLocation
{
    DebugLog(@"location: didUpdateToLocation: newLocation = %@", newLocation);
    
    if(newLocation)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#pragma clang diagnostic ignored "-Wundeclared-selector"
        // stop updating location
        [tuneCLLocationManager performSelector:@selector(stopUpdatingLocation)];
#pragma clang diagnostic pop
    }
}

-(void)locationManager:(id)manager didUpdateLocations:(NSArray *)locations
{
    DebugLog(@"location: didUpdateLocations: newLocation = %@", locations);
    
    id newLocation = locations && [NSNull null] != (id)locations ? locations[0] : nil;
    
    if(newLocation)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
#pragma clang diagnostic ignored "-Wundeclared-selector"
        // stop updating location
        [tuneCLLocationManager performSelector:@selector(stopUpdatingLocation)];
#pragma clang diagnostic pop
    }
}

@end
