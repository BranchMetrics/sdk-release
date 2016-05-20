//
//  TuneTestsHelper.m
//  Tune
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import "TuneTestsHelper.h"

#import "TuneManager+Testing.h"
#import "Tune+Testing.h"
#import "TuneFileManager.h"
#import "TuneEventQueue+Testing.h"
#import "TuneUtils+Testing.h"
#import "TuneSkyhookCenter+Testing.h"
#import "TuneState+Testing.h"
#import "TuneAppDelegate.h"


#if TARGET_OS_TV
NSString * const kTestAdvertiserId  = @"3216";
NSString * const kTestConversionKey = @"7dd1feb3b304aa169e62e9a0966f5e4d";
NSString* const kTestBundleId = @"com.mobileapptracking.tvosunittest";
#else
NSString* const kTestAdvertiserId = @"877";
NSString* const kTestConversionKey = @"8c14d6bbe466b65211e781d62e301eec";
NSString* const kTestBundleId = @"com.mobileapptracking.iosunittest";
#endif

const NSTimeInterval TUNE_TEST_NETWORK_REQUEST_DURATION = 3.;

void RESET_EVERYTHING() {
#if TARGET_OS_IOS || TARGET_OS_IPHONE
    [TuneState updateTMADisabledState:NO];
    [UIViewController load];
    [TuneAppDelegate load];
#endif
    
    // To trigger the initialize method in Tune.m
    [Tune class];
    
    emptyRequestQueue();
    waitForQueuesToFinish();
    
    // Remove all generated files
    [TuneFileManager deleteAnalyticsFromDisk];
    [TuneFileManager deletePlaylistFromDisk];
    [TuneFileManager deleteRemoteConfigurationFromDisk];
    
    // Recreate a fresh skyhooks center
    [TuneSkyhookCenter nilDefaultCenter];
    [TuneSkyhookCenter defaultCenter];
    // Add the two skyhooks that TuneManager listens to (since it won't be recreated)
    [[TuneManager currentManager] registerSkyhooks];
    
    // Make sure that all singletons are fresh
    [TuneManager nilModules];
    
    // Clear out all settings
    clearUserDefaults();
    
    [TuneState updateTMADisabledState:NO];
    
    // Bring the modules up
    [TuneManager instantiateModules];
    pointMAUrlsToNothing();
    
    // Make sure shared manager is new
    [TuneEventQueue resetSharedInstance];
    [Tune reInitSharedManagerOverride];
    
    emptyRequestQueue();
    waitForQueuesToFinish();
}

void pointMAUrlsToNothing() {
    [[TuneManager currentManager].configuration setApiHostPort:nil];
    [[TuneManager currentManager].configuration setAnalyticsHostPort:nil];
    [[TuneManager currentManager].configuration setStaticContentHostPort:nil];
    [[TuneManager currentManager].configuration setConnectedModeHostPort:nil];
}

void clearUserDefaults() {
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSDictionary *dict = [defs dictionaryRepresentation];
    for (id key in dict) {
        [defs removeObjectForKey:key];
    }
    [defs synchronize];
    
    [NSUserDefaults resetStandardUserDefaults];
    
    // Check to make sure that NSUserDefaults is really cleared.
    for (NSString *key in [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]) {
        if ([key containsString:@"_TUNE_"] && ![key isEqualToString:@"_TUNE_mat_id"]) {
            ErrorLog(@"ARGH, NSUserDefaults was not cleared properly. Still has: %@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
            break;
        }
    }
}

void waitFor1( NSTimeInterval duration, BOOL* finished ) {
    // block test thread while app executes
    NSDate *stopDate = [[NSDate date] dateByAddingTimeInterval:duration];
    do [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:stopDate];
    while( [stopDate timeIntervalSinceNow] > 0 && !(*finished) );
}

void waitFor( NSTimeInterval duration ) {
    // block test thread while app executes
    NSDate *stopDate = [[NSDate date] dateByAddingTimeInterval:duration];
    do [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:stopDate];
    while( [stopDate timeIntervalSinceNow] > 0 );
}

void waitForQueuesToFinish() {
    [Tune waitUntilAllOperationsAreFinishedOnQueue];
    [[TuneEventQueue sharedInstance] waitUntilAllOperationsAreFinishedOnQueue];
}

void emptyRequestQueue() {
    [TuneEventQueue drainQueue];
}

void networkOffline() {
    [TuneUtils overrideNetworkReachability:[@NO stringValue]];
}

void networkOnline() {
    [TuneUtils overrideNetworkReachability:[@YES stringValue]];
}

int char2hex(unsigned char c) {
    switch (c) {
        case '0' ... '9':
            return c - '0';
        case 'a' ... 'f':
            return c - 'a' + 10;
        case 'A' ... 'F':
            return c - 'A' + 10;
        default:
            return 0xFF;
    }
}
