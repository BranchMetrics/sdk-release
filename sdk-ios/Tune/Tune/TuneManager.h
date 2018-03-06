//
//  TuneManager.h
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

@class TuneAnalyticsManager;
@class TuneConfiguration;
@class TuneFileManager;
@class TuneSessionManager;
@class TunePowerHookManager;
@class TuneSkyhookCenter;
@class TuneState;
@class TuneUserProfile;
@class TunePlaylistManager;
@class TuneTriggerManager;
@class TuneJSONPlayer;
@class TuneCampaignStateManager;
@class TuneExperimentManager;
@class TuneDeepActionManager;
@class TuneConnectedModeManager;
@class TuneSmartWhereTriggeredEventManager;

// This singleton is responsible for keeping references to all major components
// so various parts of the system can be initialized with the TuneManager and then
// have access to its many counterparts.

@interface TuneManager : NSObject

@property (strong, nonatomic) TuneAnalyticsManager *analyticsManager;
@property (strong, nonatomic) TuneConfiguration *configuration;
@property (strong, nonatomic) TunePowerHookManager *powerHookManager;
@property (strong, nonatomic) TuneState *state;
@property (strong, nonatomic) TuneUserProfile *userProfile;
@property (strong, nonatomic) TunePlaylistManager *playlistManager;
@property (strong, nonatomic) TuneJSONPlayer *playlistPlayer;
@property (strong, nonatomic) TuneJSONPlayer *configurationPlayer;
@property (strong, nonatomic) TuneSessionManager *sessionManager;
@property (strong, nonatomic) TuneTriggerManager *triggerManager;
@property (strong, nonatomic) TuneCampaignStateManager *campaignStateManager;
@property (strong, nonatomic) TuneExperimentManager *experimentManager;
@property (strong, nonatomic) TuneDeepActionManager *deepActionManager;
@property (strong, nonatomic) TuneConnectedModeManager *connectedModeManager;
@property (strong, nonatomic) TuneSmartWhereTriggeredEventManager *triggeredEventManager;


+ (TuneManager *)currentManager;
- (void)instantiateModules;

@end
