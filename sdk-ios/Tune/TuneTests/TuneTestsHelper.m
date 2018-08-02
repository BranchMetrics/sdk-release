//
//  TuneTestsHelper.m
//  Tune
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import <OCMock/OCMock.h>

#import "TuneTestsHelper.h"

#import "Tune+Testing.h"
#import "TuneFileManager.h"
#import "TuneEventQueue+Testing.h"
#import "TuneManager+Testing.h"
#import "TuneSkyhookCenter+Testing.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneConfiguration.h"


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

BOOL shouldCreateMocks = YES;

void RESET_EVERYTHING() {
    RESET_EVERYTHING_OPTIONAL_MOCKING();
}

void RESET_EVERYTHING_OPTIONAL_MOCKING() {
    // To trigger the initialize method in Tune.m
    [Tune class];
    
    emptyRequestQueue();
    waitForQueuesToFinish();
    
    // Remove all generated files
    [TuneFileManager deleteAnalyticsFromDisk];
    
    // Recreate a fresh skyhooks center
    [TuneSkyhookCenter nilDefaultCenter];
    [TuneSkyhookCenter defaultCenter];
    // Add the two skyhooks that TuneManager listens to (since it won't be recreated)
    [[TuneManager currentManager] registerSkyhooks];
    
    // Make sure that all singletons are fresh
    [[TuneManager currentManager] nilModules];
    
    // Clear out all settings
    clearUserDefaults();
        
    // Bring the modules up
    [[TuneManager currentManager] instantiateModules];
    
    // Make sure shared manager is new
    [TuneEventQueue resetSharedQueue];
    [Tune resetTuneTrackerSharedInstance];
    
    if(shouldCreateMocks) {
        mockTuneManager = OCMPartialMock([TuneManager currentManager]);
        classMockTuneManager = OCMClassMock([TuneManager class]);
        OCMStub([classMockTuneManager currentManager]).andReturn(mockTuneManager);
        shouldCreateMocks = NO;
    }
    
    emptyRequestQueue();
    waitForQueuesToFinish();
}

void REMOVE_MOCKS() {
    [mockTuneManager stopMocking];
    [classMockTuneManager stopMocking];
    
    shouldCreateMocks = YES;
}

void clearUserDefaults() {
    [TuneUserDefaultsUtils clearAll];
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
    [[Tune tuneQueue] waitUntilAllOperationsAreFinished];
    [[TuneEventQueue sharedQueue] waitUntilAllOperationsAreFinishedOnQueue];
}

void emptyRequestQueue() {
    [[TuneEventQueue sharedQueue] drainQueue];
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
