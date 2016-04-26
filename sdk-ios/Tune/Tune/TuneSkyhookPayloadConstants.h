//
//  TuneSkyhookPayloadConstants.h
//  MobileAppTracker
//
//  Created by Charles Gilliam on 7/30/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

@interface TuneSkyhookPayloadConstants : NSObject

#pragma mark - Session Variable
extern NSString *const TunePayloadSessionVariableName;
extern NSString *const TunePayloadSessionVariableValue;
extern NSString *const TunePayloadSessionVariableSaveType;
extern NSString *const TunePayloadSessionVariableSaveTypeTag;
extern NSString *const TunePayloadSessionVariableSaveTypeProfile;

#pragma mark - Custom Event
extern NSString *const TunePayloadCustomEvent;

#pragma mark - Tracked Event
extern NSString *const TunePayloadTrackedEvent;

#pragma mark - Profile clear
extern NSString *const TunePayloadProfileVariablesToClear;

#pragma mark - Playlist
extern NSString *const TunePayloadNewPlaylist;
extern NSString *const TunePayloadPlaylistLoadedFromDisk;
extern NSString *const TunePayloadFirstPlaylistDownloaded;

#pragma mark - Push and Local Notification
extern NSString *const TunePayloadNotification;

#pragma mark - Campaign
extern NSString *const TunePayloadCampaign;
extern NSString *const TunePayloadCampaignStep;

#pragma mark - In App Message
extern NSString *const TunePayloadInAppMessageID;
extern NSString *const TunePayloadInAppMessageSecondsDisplayed;
extern NSString *const TunePayloadInAppMessageDismissedAction;

#pragma mark - Deep Actions
extern NSString *const TunePayloadDeepActionId;
extern NSString *const TunePayloadDeepActionData;

#pragma mark - Deeplinks
extern NSString *const TunePayloadDeeplink;

@end
 
