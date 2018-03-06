//
//  TuneManager.m
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
#import "TuneSmartWhereTriggeredEventManager.h"

@implementation TuneManager

// This is NOT recommended by Apple
+ (void)initialize {
    [[TuneManager sharedInstance] instantiateModules];
}

// ObjC singletons are usually named sharedSomething or just shared.  For example:  [UIApplication sharedApplication]
// Eventually switch to using just sharedInstance
+ (TuneManager *)currentManager {
    return [self sharedInstance];
}

+ (TuneManager *)sharedInstance {
    static TuneManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [TuneManager new];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)instantiateModules {
    [self instantiateAAModules];
    
    // If we are disabled or permanently disabled then don't even start these modules
    if (![TuneState isTMADisabled]) {
        InfoLog(@"STARTING WITH TMA ON");
        [self instantiateTMAModules];
    } else {
        InfoLog(@"STARTING WITH TMA OFF");
    }
}

- (void)instantiateAAModules {
    self.userProfile = [TuneUserProfile moduleWithTuneManager:self];
    [self.userProfile registerSkyhooks];
    
    self.configuration = [TuneConfiguration moduleWithTuneManager:self];
    [self.configuration registerSkyhooks];
    
    self.state = [TuneState moduleWithTuneManager:self];
    [self.state registerSkyhooks];
    
    self.sessionManager = [TuneSessionManager moduleWithTuneManager:self];
    [self.sessionManager registerSkyhooks];
    
    self.triggeredEventManager = [TuneSmartWhereTriggeredEventManager moduleWithTuneManager:self];
    [self.triggeredEventManager registerSkyhooks];
    
    // These need to be started, but don't bother registering its skyhooks unless TMA is actually on
    self.powerHookManager = [TunePowerHookManager moduleWithTuneManager:self];
    self.deepActionManager = [TuneDeepActionManager moduleWithTuneManager:self];
    self.playlistManager = [TunePlaylistManager moduleWithTuneManager:self];
}

- (void)instantiateTMAModules {
    // The PowerHookManager must be brought up before the PlaylistManager since it needs to listen to changes in the playlist from the skyhooks
    [self.powerHookManager bringUp];
    [self.deepActionManager bringUp];
    [self.playlistManager bringUp];
    
    if (self.experimentManager == nil) {
        self.experimentManager = [TuneExperimentManager moduleWithTuneManager:self];
        [self.experimentManager registerSkyhooks];
    } else {
        [self.experimentManager bringUp];
    }
    
    if (self.connectedModeManager == nil) {
        self.connectedModeManager = [TuneConnectedModeManager moduleWithTuneManager:self];
        [self.connectedModeManager registerSkyhooks];
    } else {
        [self.connectedModeManager bringUp];
    }
    
    if (self.analyticsManager == nil) {
        self.analyticsManager = [TuneAnalyticsManager moduleWithTuneManager:self];
        [self.analyticsManager registerSkyhooks];
    } else {
        [self.analyticsManager bringUp];
    }
    
    if (self.triggerManager == nil) {
        self.triggerManager = [TuneTriggerManager moduleWithTuneManager:self];
        [self.triggerManager registerSkyhooks];
    } else {
        [self.triggerManager bringUp];
    }
    
    if (self.campaignStateManager == nil) {
        self.campaignStateManager = [TuneCampaignStateManager moduleWithTuneManager:self];
        [self.campaignStateManager registerSkyhooks];
    } else {
        [self.campaignStateManager bringUp];
    }
    
    // Load the playlist for disk before we give control to the user
    [self.playlistManager loadPlaylistFromDisk];
}

#pragma mark - Skyhook management

- (void)registerSkyhooks {
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self selector:@selector(handleTMAEnable:) name:TuneStateTMAActivated object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:self selector:@selector(handleTMADisable:) name:TuneStateTMADeactivated object:nil];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self selector:@selector(handleSaveUserDefaults:) name:TuneSessionManagerSessionDidEnd object:nil priority:TuneSkyhookPriorityLast];
}

#pragma mark - Handle Enable/Disable

- (void)handleTMAEnable:(TuneSkyhookPayload*)payload {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleTMAEnable:) withObject:nil waitUntilDone:YES];
        return;
    }
    
    DebugLog(@"TURNING TMA ON");
    
    [[TuneManager sharedInstance] instantiateTMAModules];
}

- (void)handleTMADisable:(TuneSkyhookPayload*)payload {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(handleTMADisable:) withObject:nil waitUntilDone:YES];
        return;
    }
    
    DebugLog(@"TURNING TMA OFF");
    
    [self.analyticsManager bringDown];
    [self.sessionManager bringDown];
    [self.powerHookManager bringDown];
    [self.playlistManager bringDown];
    [self.campaignStateManager bringDown];
    [self.triggerManager bringDown];
    [self.deepActionManager bringDown];
    [self.connectedModeManager bringDown];
}

#pragma mark - Handle NSUserDefaults Saving

- (void)handleSaveUserDefaults:(TuneSkyhookPayload*)payload {
    [TuneUserDefaultsUtils synchronizeUserDefaults];
}

#pragma mark - Testing Helpers

#if TESTING
- (void)nilModules {
    /* WARNING! This module may not be wholey safe.  It is used for the enable/disable/permanently-disable tests since they need a fresh slate for each test. */
    [self.analyticsManager unregisterSkyhooks];
    [self.configuration unregisterSkyhooks];
    [self.powerHookManager unregisterSkyhooks];
    [self.state unregisterSkyhooks];
    [self.userProfile unregisterSkyhooks];
    [self.playlistManager unregisterSkyhooks];
    [self.sessionManager unregisterSkyhooks];
    [self.triggerManager unregisterSkyhooks];
    [self.campaignStateManager unregisterSkyhooks];
    [self.experimentManager unregisterSkyhooks];
    [self.deepActionManager unregisterSkyhooks];
    [self.connectedModeManager unregisterSkyhooks];
    
    self.analyticsManager = nil;
    self.configuration = nil;
    self.powerHookManager = nil;
    self.state = nil;
    self.userProfile = nil;
    self.playlistManager = nil;
    self.playlistPlayer = nil;
    self.configurationPlayer = nil;
    self.sessionManager = nil;
    self.triggerManager = nil;
    self.campaignStateManager = nil;
    self.experimentManager = nil;
    self.deepActionManager = nil;
    self.connectedModeManager = nil;
}
#endif

@end
