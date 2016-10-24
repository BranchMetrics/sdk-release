//
//  TuneSkyhookConstants.m
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneSkyhookConstants.h"

# pragma mark - Priorities
const int TuneSkyhookPriorityFirst = 1;
const int TuneSkyhookPrioritySecond = 2;
const int TuneSkyhookPriorityIrrelevant = 9999;
const int TuneSkyhookPriorityLast = 10000;

#pragma mark - Analytics Hooks
NSString *const TuneCustomEventOccurred = @"TuneCustomEventOccurred";
NSString *const TunePushNotificationOpened = @"TunePushNotificationOpened";
NSString *const TunePushEnabled = @"Push Enabled";
NSString *const TunePushDisabled = @"Push Disabled";
NSString *const TuneAppOpenedFromURL = @"TuneAppOpenedFromURL";
NSString *const TuneEventTracked = @"TuneEventTracked"; // Posted on every event via AnalyticsManager#storeAndTrackAnalyticsEvents
NSString *const TuneSessionVariableToSet = @"TuneSessionVariableToSet";
NSString *const TuneUserProfileVariablesCleared = @"TuneUserProfileVariablesCleared";

#pragma mark - Campaign Hooks
NSString *const TuneCampaignViewed = @"TuneCampaignViewed";

#pragma mark - TuneConfiguration
NSString *const TuneConfigurationUpdated = @"TuneConfigurationUpdated";

#pragma mark - View Controller Lifecycle
NSString *const TuneViewControllerAppeared = @"TuneViewControllerAppeared";

#pragma mark - Session Hooks
NSString *const TuneSessionManagerSessionDidStart = @"TuneSessionManagerSessionDidStart";
NSString *const TuneSessionManagerSessionDidEnd = @"TuneSessionManagerSessionDidEnd";

#pragma mark - Crash Reporting
NSString *const TuneCrashFound = @"TuneCrashFound";

#pragma mark - TuneState
NSString *const TuneStateNetworkStatusChanged = @"TuneStateNetworkStatusChanged";

NSString *const TuneStateTMAConnectedModeTurnedOn = @"TuneStateTMAConnectedModeTurnedOn";
NSString *const TuneStateTMAConnectedModeTurnedOff = @"TuneStateTMAConnectedModeTurnedOff";

#pragma mark - TunePlaylistManager
NSString *const TunePlaylistManagerCurrentPlaylistChanged = @"TunePlaylistManagerCurrentPlaylistChanged";
NSString *const TunePlaylistManagerFinishedPlaylistDownload  = @"TunePlaylistManagerFinishedPlaylistDownload";
NSString *const TunePlaylistManagerFirstPlaylistDownloaded = @"TunePlaylistManagerFirstPlaylistDownloaded";

#pragma mark - TunePlaylist
NSString *const TunePlaylistAssetsDownloaded = @"TunePlaylistAssetsDownloaded";

#pragma mark - Device Token
NSString *const TuneRegisteredForRemoteNotificationsWithDeviceToken = @"TuneRegisteredForRemoteNotificationsWithDeviceToken";
NSString *const TuneFailedToRegisterForRemoteNotifications = @"TuneFailedToRegisterForRemoteNotifications";

#pragma mark - Force update from Tune
NSString *const TuneDispatchNow = @"TuneDispatchNow";

#pragma mark - TuneManager
NSString *const TuneStateTMAActivated = @"TuneStateTMAActivated";
NSString *const TuneStateTMADeactivated = @"TuneStateTMADeactivated";

#pragma mark - Deep Actions
NSString *const TuneDeepActionTriggered = @"TuneDeepActionTriggered";

#pragma mark - In App Message
NSString *const TuneInAppMessageShown = @"TuneInAppMessageShown";
NSString *const TuneInAppMessageDismissed = @"TuneInAppMessageDismissed";
