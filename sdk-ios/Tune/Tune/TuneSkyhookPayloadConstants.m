//
//  TuneSkyhookPayloadConstants.m
//  MobileAppTracker
//
//  Created by Charles Gilliam on 7/30/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneSkyhookPayloadConstants.h"

@implementation TuneSkyhookPayloadConstants

#pragma mark - Session Variable
NSString *const TunePayloadSessionVariableName = @"TunePayloadSessionVariableName";
NSString *const TunePayloadSessionVariableValue = @"TunePayloadSessionVariableValue";
NSString *const TunePayloadSessionVariableSaveType = @"TunePayloadSessionVariableSaveType";
NSString *const TunePayloadSessionVariableSaveTypeTag = @"TunePayloadSessionVariableSaveTypeTag";
NSString *const TunePayloadSessionVariableSaveTypeProfile = @"TunePayloadSessionVariableSaveTypeProfile";

#pragma mark - Custom Event
NSString *const TunePayloadCustomEvent = @"TuneCustomEvent";

#pragma mark - Tracked Event
NSString *const TunePayloadTrackedEvent = @"TunePayloadTrackedEvent";

#pragma mark - Profile clear
NSString *const TunePayloadProfileVariablesToClear = @"TunePayloadClearedVariables";

#pragma mark - Playlist
NSString *const TunePayloadNewPlaylist = @"TunePayloadNewPlaylist";
NSString *const TunePayloadPlaylistLoadedFromDisk = @"TunePayloadPlaylistLoadedFromDisk";
NSString *const TunePayloadFirstPlaylistDownloaded = @"TunePayloadFirstPlaylistDownloaded";

#pragma mark - Push and Local Notification
NSString *const TunePayloadNotification = @"TunePayloadNotification";

#pragma mark - Campaign
NSString *const TunePayloadCampaign = @"TunePayloadCampaign";
NSString *const TunePayloadCampaignStep = @"TunePayloadCampaignStep";

#pragma mark - In App Message
NSString *const TunePayloadInAppMessageID = @"TunePayloadInAppMessageID";
NSString *const TunePayloadInAppMessageSecondsDisplayed = @"TunePayloadInAppMessageSecondsDisplayed";
NSString *const TunePayloadInAppMessageDismissedAction = @"TunePayloadInAppMessageDismissedAction";

#pragma mark - Deep Actions
NSString *const TunePayloadDeepActionId = @"TunePayloadDeepActionId";
NSString *const TunePayloadDeepActionData = @"TunePayloadDeepActionData";

#pragma mark - Deeplinks
NSString *const TunePayloadDeeplink = @"TunePayloadDeeplink";

@end
