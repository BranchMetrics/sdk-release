//
//  TuneSkyhookPayloadConstants.h
//  MobileAppTracker
//
//  Created by Charles Gilliam on 7/30/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneSkyhookPayloadConstants : NSObject

#pragma mark - Session Variable
FOUNDATION_EXPORT NSString *const TunePayloadSessionVariableName;
FOUNDATION_EXPORT NSString *const TunePayloadSessionVariableValue;
FOUNDATION_EXPORT NSString *const TunePayloadSessionVariableSaveType;
FOUNDATION_EXPORT NSString *const TunePayloadSessionVariableSaveTypeTag;
FOUNDATION_EXPORT NSString *const TunePayloadSessionVariableSaveTypeProfile;

#pragma mark - Custom Event
FOUNDATION_EXPORT NSString *const TunePayloadCustomEvent;

#pragma mark - Tracked Event
FOUNDATION_EXPORT NSString *const TunePayloadTrackedEvent;

#pragma mark - Profile clear
FOUNDATION_EXPORT NSString *const TunePayloadProfileVariablesToClear;

#pragma mark - Playlist
FOUNDATION_EXPORT NSString *const TunePayloadNewPlaylist;
FOUNDATION_EXPORT NSString *const TunePayloadPlaylistLoadedFromDisk;
FOUNDATION_EXPORT NSString *const TunePayloadFirstPlaylistDownloaded;

#pragma mark - Push and Local Notification
FOUNDATION_EXPORT NSString *const TunePayloadNotification;

#pragma mark - Campaign
FOUNDATION_EXPORT NSString *const TunePayloadCampaign;
FOUNDATION_EXPORT NSString *const TunePayloadCampaignStep;

#pragma mark - Deeplinks
FOUNDATION_EXPORT NSString *const TunePayloadDeeplink;

@end
 
