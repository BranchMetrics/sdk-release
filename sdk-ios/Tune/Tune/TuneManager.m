//
//  TuneManager.h
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneManager.h"

#import "TuneAnalyticsManager.h"
#import "TuneConfiguration.h"
#import "TuneSessionManager.h"
#import "TunePowerHookManager.h"
#import "TuneSkyhookCenter.h"
#import "TunePlaylistManager.h"
#import "TuneState.h"
#import "TuneUserProfile.h"
#import "TuneTriggerManager.h"
#import "TuneSkyhookPayload.h"
#import "TuneSkyhookConstants.h"
#import "TuneCampaignStateManager.h"
#import "TuneFileManager.h"
#import "TuneExperimentManager.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneDeepActionManager.h"
#import "TuneConnectedModeManager.h"

@implementation TuneManager

static TuneManager *_instance;
static dispatch_once_t onceToken;

#pragma mark - Initialization/Deallocation

+ (TuneManager *)currentManager {
    dispatch_once(&onceToken, ^{
        _instance = [[TuneManager alloc] init];
        _instance.concurrentQueue = dispatch_queue_create("com.tune.concurrentQueue", DISPATCH_QUEUE_CONCURRENT);
        
        [_instance registerSkyhooks];
    });
    
    return _instance;
}

#pragma mark - Skyhook management

- (void)registerSkyhooks {
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self selector:@selector(handleTMAEnable:) name:TuneStateTMAActivated object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:self selector:@selector(handleTMADisable:) name:TuneStateTMADeactivated object:nil];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self selector:@selector(handleSaveUserDefaults:) name:TuneSessionManagerSessionDidEnd object:nil priority:TuneSkyhookPriorityLast];
}

#pragma mark - Instantiate Modules

+ (void)instantiateModules {
    TuneManager *_tuneManager = [TuneManager currentManager];
    
    _tuneManager.userProfile = [TuneUserProfile moduleWithTuneManager:_tuneManager];
    [_tuneManager.userProfile registerSkyhooks];
    
    _tuneManager.configuration = [TuneConfiguration moduleWithTuneManager:_tuneManager];
    [_tuneManager.configuration registerSkyhooks];
    
    _tuneManager.state = [TuneState moduleWithTuneManager:_tuneManager];
    [_tuneManager.state registerSkyhooks];
    
    _tuneManager.sessionManager = [TuneSessionManager moduleWithTuneManager:_tuneManager];
    [_tuneManager.sessionManager registerSkyhooks];
    
    // These need to be started, but don't bother registering its skyhooks unless TMA is actually on
    _tuneManager.powerHookManager = [TunePowerHookManager moduleWithTuneManager:_tuneManager];
    _tuneManager.deepActionManager = [TuneDeepActionManager moduleWithTuneManager:_tuneManager];
    _tuneManager.playlistManager = [TunePlaylistManager moduleWithTuneManager:_tuneManager];
    
    // If we are disabled or permanently disabled then don't even start these modules
    if (![TuneState isTMADisabled]) {
        InfoLog(@"STARTING WITH TMA ON");
        [TuneManager instantiateTMAModules];
    } else {
        InfoLog(@"STARTING WITH TMA OFF");
    }
}

+ (void)instantiateTMAModules {
    TuneManager *_tuneManager = [TuneManager currentManager];
    
    // The PowerHookManager must be brought up before the PlaylistManager since it needs to listen to changes in the playlist from the skyhooks
    [_tuneManager.powerHookManager bringUp];
    [_tuneManager.deepActionManager bringUp];
    [_tuneManager.playlistManager bringUp];
    
    if (_tuneManager.experimentManager == nil) {
        _tuneManager.experimentManager = [TuneExperimentManager moduleWithTuneManager:_tuneManager];
        [_tuneManager.experimentManager registerSkyhooks];
    } else {
        [_tuneManager.experimentManager bringUp];
    }
    
    if (_tuneManager.connectedModeManager == nil) {
        _tuneManager.connectedModeManager = [TuneConnectedModeManager moduleWithTuneManager:_tuneManager];
        [_tuneManager.connectedModeManager registerSkyhooks];
    } else {
        [_tuneManager.connectedModeManager bringUp];
    }

    if (_tuneManager.analyticsManager == nil) {
        _tuneManager.analyticsManager = [TuneAnalyticsManager moduleWithTuneManager:_tuneManager];
        [_tuneManager.analyticsManager registerSkyhooks];
    } else {
        [_tuneManager.analyticsManager bringUp];
    }
    
    if (_tuneManager.triggerManager == nil) {
        _tuneManager.triggerManager = [TuneTriggerManager moduleWithTuneManager:_tuneManager];
        [_tuneManager.triggerManager registerSkyhooks];
    } else {
        [_tuneManager.triggerManager bringUp];
    }
    
    if (_tuneManager.campaignStateManager == nil) {
        _tuneManager.campaignStateManager = [TuneCampaignStateManager moduleWithTuneManager:_tuneManager];
        [_tuneManager.campaignStateManager registerSkyhooks];
    } else {
        [_tuneManager.campaignStateManager bringUp];
    }
    
    // Load the playlist for disk before we give control to the user
    [_tuneManager.playlistManager loadPlaylistFromDisk];
}

#pragma mark - Handle Enable/Disable

- (void)handleTMAEnable:(TuneSkyhookPayload*)payload {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleTMAEnable:)
                               withObject:nil
                            waitUntilDone:YES];
        return;
    }
    
    DebugLog(@"TURNING TMA ON");
    
    [TuneManager instantiateTMAModules];
}

- (void)handleTMADisable:(TuneSkyhookPayload*)payload {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleTMADisable:)
                               withObject:nil
                            waitUntilDone:YES];
        return;
    }
    
    DebugLog(@"TURNING TMA OFF");
    
    TuneManager *_tuneManager = [TuneManager currentManager];
    [_tuneManager.analyticsManager bringDown];
    [_tuneManager.sessionManager bringDown];
    [_tuneManager.powerHookManager bringDown];
    [_tuneManager.playlistManager bringDown];
    [_tuneManager.campaignStateManager bringDown];
    [_tuneManager.triggerManager bringDown];
    [_tuneManager.deepActionManager bringDown];
    [_tuneManager.connectedModeManager bringDown];
}

#pragma mark - Handle NSUserDefaults Saving

- (void)handleSaveUserDefaults:(TuneSkyhookPayload*)payload {
    [TuneUserDefaultsUtils synchronizeUserDefaults];
}

#pragma mark - Testing Helpers

#if TESTING
+ (void)nilModules {
    /* WARNING! This module may not be wholey safe.  It is used for the enable/disable/permanently-disable tests
     +                since they need a fresh slate for each test.
     +     */
    TuneManager *_tuneManager = [TuneManager currentManager];
    
    _tuneManager.analyticsManager = nil;
    _tuneManager.configuration = nil;
    _tuneManager.powerHookManager = nil;
    _tuneManager.state = nil;
    _tuneManager.userProfile = nil;
    _tuneManager.playlistManager = nil;
    _tuneManager.playlistPlayer = nil;
    _tuneManager.configurationPlayer = nil;
    _tuneManager.sessionManager = nil;
    _tuneManager.triggerManager = nil;
    _tuneManager.campaignStateManager = nil;
    _tuneManager.experimentManager = nil;
    _tuneManager.deepActionManager = nil;
    _tuneManager.connectedModeManager = nil;
}
#endif

@end
