//
//  TuneSkyhookConstants.h
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

# pragma mark - Priorities
extern const int TuneSkyhookPriorityFirst;
extern const int TuneSkyhookPrioritySecond;
extern const int TuneSkyhookPriorityIrrelevant;
extern const int TuneSkyhookPriorityLast;

#pragma mark - Analytics Hooks
extern NSString *const TuneCustomEventOccurred;
extern NSString *const TunePushNotificationOpened;
extern NSString *const TunePushEnabled;
extern NSString *const TunePushDisabled;
extern NSString *const TuneAppOpenedFromURL;
extern NSString *const TuneEventTracked;
extern NSString *const TuneSessionVariableToSet;
extern NSString *const TuneUserProfileVariablesCleared;

#pragma mark - Campaign Hooks
extern NSString *const TuneCampaignViewed;

#pragma mark - TuneConfiguration
extern NSString *const TuneConfigurationUpdated;

#pragma mark - View Controller Lifecycle
extern NSString *const TuneViewControllerAppeared;

#pragma mark - Session Hooks
extern NSString *const TuneSessionManagerSessionDidStart;
extern NSString *const TuneSessionManagerSessionDidEnd;

#pragma mark - Crash Reporting
extern NSString *const TuneCrashFound;

#pragma mark - TuneState
extern NSString *const TuneStateNetworkStatusChanged;

extern NSString *const TuneStateTMAConnectedModeTurnedOn;
extern NSString *const TuneStateTMAConnectedModeTurnedOff;

#pragma mark - TunePlaylistManager
extern NSString *const TunePlaylistManagerCurrentPlaylistChanged;
extern NSString *const TunePlaylistManagerFinishedPlaylistDownload;
extern NSString *const TunePlaylistManagerFirstPlaylistDownloaded;

#pragma mark - TunePlaylist
extern NSString *const TunePlaylistAssetsDownloaded;

#pragma mark - Device Token
extern NSString *const TuneRegisteredForRemoteNotificationsWithDeviceToken;
extern NSString *const TuneFailedToRegisterForRemoteNotifications;

#pragma mark - Force update from Tune
extern NSString *const TuneDispatchNow;

#pragma mark - TuneManager
extern NSString *const TuneStateTMAActivated;
extern NSString *const TuneStateTMADeactivated;
extern NSString *const TuneStateTMADeactivated;

#pragma mark - Deep Actions
extern NSString *const TuneDeepActionTriggered;

#pragma mark - In App Message
extern NSString *const TuneInAppMessageShown;
extern NSString *const TuneInAppMessageDismissed;
