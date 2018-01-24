//
//  TuneSkyhookConstants.h
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

# pragma mark - Priorities
FOUNDATION_EXPORT const int TuneSkyhookPriorityFirst;
FOUNDATION_EXPORT const int TuneSkyhookPrioritySecond;
FOUNDATION_EXPORT const int TuneSkyhookPriorityIrrelevant;
FOUNDATION_EXPORT const int TuneSkyhookPriorityLast;

#pragma mark - Analytics Hooks
FOUNDATION_EXPORT NSString *const TuneCustomEventOccurred;
FOUNDATION_EXPORT NSString *const TunePushNotificationOpened;
FOUNDATION_EXPORT NSString *const TunePushEnabled;
FOUNDATION_EXPORT NSString *const TunePushDisabled;
FOUNDATION_EXPORT NSString *const TuneAppOpenedFromURL;
FOUNDATION_EXPORT NSString *const TuneEventTracked;
FOUNDATION_EXPORT NSString *const TuneSessionVariableToSet;
FOUNDATION_EXPORT NSString *const TuneUserProfileVariablesCleared;

#pragma mark - Campaign Hooks
FOUNDATION_EXPORT NSString *const TuneCampaignViewed;

#pragma mark - TuneConfiguration
FOUNDATION_EXPORT NSString *const TuneConfigurationUpdated;

#pragma mark - View Controller Lifecycle
FOUNDATION_EXPORT NSString *const TuneViewControllerAppeared;

#pragma mark - Session Hooks
FOUNDATION_EXPORT NSString *const TuneSessionManagerSessionDidStart;
FOUNDATION_EXPORT NSString *const TuneSessionManagerSessionDidEnd;

#pragma mark - Crash Reporting
FOUNDATION_EXPORT NSString *const TuneCrashFound;

#pragma mark - TuneState
FOUNDATION_EXPORT NSString *const TuneStateNetworkStatusChanged;

FOUNDATION_EXPORT NSString *const TuneStateTMAConnectedModeTurnedOn;
FOUNDATION_EXPORT NSString *const TuneStateTMAConnectedModeTurnedOff;

#pragma mark - TunePlaylistManager
FOUNDATION_EXPORT NSString *const TunePlaylistManagerCurrentPlaylistChanged;
FOUNDATION_EXPORT NSString *const TunePlaylistManagerFinishedPlaylistDownload;
FOUNDATION_EXPORT NSString *const TunePlaylistManagerFirstPlaylistDownloaded;

#pragma mark - TunePlaylist
FOUNDATION_EXPORT NSString *const TunePlaylistUpdatePlaylist;

#pragma mark - Device Token
FOUNDATION_EXPORT NSString *const TuneRegisteredForRemoteNotificationsWithDeviceToken;
FOUNDATION_EXPORT NSString *const TuneFailedToRegisterForRemoteNotifications;

#pragma mark - Force update from Tune
FOUNDATION_EXPORT NSString *const TuneDispatchNow;

#pragma mark - TuneManager
FOUNDATION_EXPORT NSString *const TuneStateTMAActivated;
FOUNDATION_EXPORT NSString *const TuneStateTMADeactivated;
FOUNDATION_EXPORT NSString *const TuneStateTMADeactivated;

#pragma mark - Deep Actions
FOUNDATION_EXPORT NSString *const TuneDeepActionTriggered;

#pragma mark - In App Message
FOUNDATION_EXPORT NSString *const TuneInAppMessageShown;
FOUNDATION_EXPORT NSString *const TuneInAppMessageDismissed;
FOUNDATION_EXPORT NSString *const TuneInAppMessageDismissedWithUnspecifiedAction;
