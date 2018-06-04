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
@property (strong, nonatomic) TuneConfiguration *configuration DEPRECATED_MSG_ATTRIBUTE("IAM functionality. This property will be removed in Tune iOS SDK v6.0.0");
@property (strong, nonatomic) TunePowerHookManager *powerHookManager DEPRECATED_MSG_ATTRIBUTE("IAM functionality. This property will be removed in Tune iOS SDK v6.0.0");
@property (strong, nonatomic) TuneState *state DEPRECATED_MSG_ATTRIBUTE("IAM functionality. This property will be removed in Tune iOS SDK v6.0.0");
@property (strong, nonatomic) TuneUserProfile *userProfile;
@property (strong, nonatomic) TunePlaylistManager *playlistManager DEPRECATED_MSG_ATTRIBUTE("IAM functionality. This property will be removed in Tune iOS SDK v6.0.0");
@property (strong, nonatomic) TuneJSONPlayer *playlistPlayer DEPRECATED_MSG_ATTRIBUTE("IAM functionality. This property will be removed in Tune iOS SDK v6.0.0");
@property (strong, nonatomic) TuneJSONPlayer *configurationPlayer DEPRECATED_MSG_ATTRIBUTE("IAM functionality. This property will be removed in Tune iOS SDK v6.0.0");
@property (strong, nonatomic) TuneSessionManager *sessionManager;
@property (strong, nonatomic) TuneTriggerManager *triggerManager DEPRECATED_MSG_ATTRIBUTE("IAM functionality. This property will be removed in Tune iOS SDK v6.0.0");
@property (strong, nonatomic) TuneCampaignStateManager *campaignStateManager DEPRECATED_MSG_ATTRIBUTE("IAM functionality. This property will be removed in Tune iOS SDK v6.0.0");
@property (strong, nonatomic) TuneExperimentManager *experimentManager DEPRECATED_MSG_ATTRIBUTE("IAM functionality. This property will be removed in Tune iOS SDK v6.0.0");
@property (strong, nonatomic) TuneDeepActionManager *deepActionManager DEPRECATED_MSG_ATTRIBUTE("IAM functionality. This property will be removed in Tune iOS SDK v6.0.0");
@property (strong, nonatomic) TuneConnectedModeManager *connectedModeManager DEPRECATED_MSG_ATTRIBUTE("IAM functionality. This property will be removed in Tune iOS SDK v6.0.0");
@property (strong, nonatomic) TuneSmartWhereTriggeredEventManager *triggeredEventManager DEPRECATED_MSG_ATTRIBUTE("IAM functionality. This property will be removed in Tune iOS SDK v6.0.0");


+ (TuneManager *)currentManager;
- (void)instantiateModules;

@end
