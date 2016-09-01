//
//  TuneTestsHelper.m
//  Tune
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import <OCMock/OCMock.h>

#import "TuneTestsHelper.h"

#import "TuneManager+Testing.h"
#import "Tune+Testing.h"
#import "TuneAnalyticsManager+Testing.h"
#import "TuneFileManager.h"
#import "TuneEventQueue+Testing.h"
#import "TunePlaylistManager+Testing.h"
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

const NSTimeInterval TUNE_TEST_NETWORK_REQUEST_DURATION = 3.5;

id classMockTuneManager;
id mockTuneManager;
id newAM;
id newPM;

BOOL shouldCreateMocks = YES;

void RESET_EVERYTHING() {
    RESET_EVERYTHING_OPTIONAL_MOCKING(YES, YES);
}

void RESET_EVERYTHING_OPTIONAL_MOCKING(BOOL shouldMockPlaylistManager, BOOL shouldMockAnalyticsManager) {
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
    
    if(shouldCreateMocks && (shouldMockPlaylistManager || shouldMockAnalyticsManager)) {
        mockTuneManager = OCMPartialMock([TuneManager currentManager]);
        classMockTuneManager = OCMClassMock([TuneManager class]);
        OCMStub([classMockTuneManager currentManager]).andReturn(mockTuneManager);
        
        if (shouldMockAnalyticsManager) {
            // remove the original analytics manager skyhook registration
            [[TuneManager currentManager].analyticsManager unregisterSkyhooks];
            
            // make sure that the skyhook is registered for the mocked instance of TuneAnalyticsManager
            newAM = OCMPartialMock([TuneAnalyticsManager moduleWithTuneManager:mockTuneManager]);
            [newAM registerSkyhooks];
            
            OCMStub([newAM startScheduledDispatch]).andDo(^(NSInvocation *invocation) {
                DebugLog(@"mock TuneAnalyticsManager: ignoring startScheduledDispatch call");
            });
            
            OCMStub([newAM storeAndTrackAnalyticsEvent:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
                DebugLog(@"mock TuneAnalyticsManager: ignoring storeAndTrackAnalyticsEvent: call");
            });
            
            OCMStub([newAM dispatchAnalytics]).andDo(^(NSInvocation *invocation) {
                DebugLog(@"mock TuneAnalyticsManager: ignoring dispatchAnalytics() call");
            });
            
            OCMStub([newAM dispatchAnalytics:NO]).andDo(^(NSInvocation *invocation) {
                DebugLog(@"mock TuneAnalyticsManager: ignoring dispatchAnalytics(BOOL)NO call");
            });
            
            OCMStub([newAM dispatchAnalytics:YES]).andDo(^(NSInvocation *invocation) {
                DebugLog(@"mock TuneAnalyticsManager: ignoring dispatchAnalytics(BOOL)YES call");
            });
            
            OCMStub([mockTuneManager analyticsManager]).andReturn(newAM);
        }
        
        if (shouldMockPlaylistManager) {
            // remove the original playlist manager skyhook registration
            [[TuneManager currentManager].playlistManager unregisterSkyhooks];
            
            // make sure that the skyhook is registered for the mocked instance of TunePlaylistManager
            newPM = OCMPartialMock([TunePlaylistManager moduleWithTuneManager:mockTuneManager]);
            [newPM registerSkyhooks];
            
            OCMStub([newPM fetchAndUpdatePlaylist]).andDo(^(NSInvocation *invocation) {
                DebugLog(@"mock TunePlaylistManager: ignoring fetchAndUpdatePlaylist call");
            });
            
            OCMStub([mockTuneManager playlistManager]).andReturn(newPM);
        }
        
        shouldCreateMocks = NO;
    }
    
    emptyRequestQueue();
    waitForQueuesToFinish();
}

void REMOVE_MOCKS() {
    if(newAM) {
        [[newAM dispatchScheduler] invalidate];
        
        [newAM stopMocking];
    }
    
    if(newPM) {
        [newPM stopMocking];
    }
    
    [mockTuneManager stopMocking];
    [classMockTuneManager stopMocking];
    
    shouldCreateMocks = YES;
}

void pointMAUrlsToNothing() {
    [[TuneManager currentManager].configuration setPlaylistHostPort:nil];
    [[TuneManager currentManager].configuration setConfigurationHostPort:nil];
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
    NSArray *tuneKeys = [[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] filteredArrayUsingPredicate:
                         [NSPredicate predicateWithFormat:@"SELF beginswith '_TUNE_' and not SELF matches '_TUNE_mat_id'"]
                         ];
    if (tuneKeys.count > 0) {
        ErrorLog(@"ARGH, NSUserDefaults was not cleared properly. Still has: %@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]);
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
