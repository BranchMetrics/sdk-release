//
//  TuneAnalyticsConstants.h
//  MobileAppTracker
//
//  Created by Charles Gilliam on 7/28/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneAnalyticsConstants : NSObject

extern NSString *const TUNE_SCHEMA_VERSION;

#pragma mark - Event types
extern NSString *const TUNE_EVENT_TYPE_BASE;
extern NSString *const TUNE_EVENT_TYPE_SESSION;
extern NSString *const TUNE_EVENT_TYPE_PAGEVIEW;
extern NSString *const TUNE_EVENT_TYPE_IN_APP_MESSAGE;
extern NSString *const TUNE_EVENT_TYPE_PUSH_NOTIFICATION;

#pragma mark - URL-based events types
extern NSString *const TUNE_EVENT_TYPE_APP_OPENED_BY_URL;
extern NSString *const TUNE_EVENT_TYPE_APP_OPENED_BY_URL_FROM_EMAIL;
extern NSString *const TUNE_EVENT_TYPE_APP_OPENED_BY_URL_FROM_WEB;
extern NSString *const TUNE_EVENT_TYPE_APP_OPENED_BY_URL_FROM_SMS;
extern NSString *const TUNE_EVENT_TYPE_APP_OPENED_BY_URL_FROM_APP;
extern NSString *const TUNE_EVENT_TYPE_APP_OPENED_BY_URL_FROM_AD;
extern NSString *const TUNE_EVENT_TYPE_APP_OPENED_BY_URL_FROM_TODAY_EXTENSION;

#pragma mark - Event category values
extern NSString *const TUNE_EVENT_CATEGORY_CUSTOM;
extern NSString *const TUNE_EVENT_CATEGORY_APPLICATION;

#pragma mark - Event Actions
// See TuneEvent.m for additional values.
extern NSString *const TUNE_EVENT_ACTION_BACKGROUNDED;
extern NSString *const TUNE_EVENT_ACTION_FOREGROUNDED;
extern NSString *const TUNE_EVENT_ACTION_NOTIFICATION_OPENED;
extern NSString *const TUNE_EVENT_ACTION_DEEPLINK_OPENED;
extern NSString *const TUNE_EVENT_ACTION_FIRST_PLAYLIST_DOWNLOADED;
extern NSString *const TUNE_EVENT_ACTION_PROFILE_VARIABLES_CLEARED;

#pragma mark - Data Types
extern NSString *const TUNE_DATA_TYPE_STRING;
extern NSString *const TUNE_DATA_TYPE_DATETIME;
extern NSString *const TUNE_DATA_TYPE_BOOLEAN;
extern NSString *const TUNE_DATA_TYPE_FLOAT;
extern NSString *const TUNE_DATA_TYPE_GEOLOCATION;
extern NSString *const TUNE_DATA_TYPE_VERSION;

#pragma mark - Analytics Event 5 line names
extern NSString *const TUNE_EVENT_CATEGORY;
extern NSString *const TUNE_EVENT_CONTROL_EVENT;
extern NSString *const TUNE_EVENT_CONTROL;
extern NSString *const TUNE_EVENT_ACTION;
extern NSString *const TUNE_EVENT_TYPE;
extern NSString *const TUNE_EVENT_LOCATION;

#pragma mark - Category Analytics Variable Tags
extern NSString *const TUNE_CATEGORY_PARAMETER;
extern NSString *const TUNE_SUB_CATEGORY_PARAMETER;
extern NSString *const TUNE_SUB_SUB_CATEGORY_PARAMETER;

#pragma mark - Campaign IDs
extern NSString *const TUNE_CAMPAIGN_IDENTIFIER;
extern NSString *const TUNE_ANALYTICS_CAMPAIGN_IDENTIFIER;
extern NSString *const TUNE_CAMPAIGN_STEP_IDENTIFIER;
extern NSString *const TUNE_CAMPAIGN_VARIATION_IDENTIFIER;

#pragma mark - Current Variations
extern NSString *const TUNE_ACTIVE_VARIATION_ID;

#pragma mark - For recording in app messages
extern NSString *const TUNE_IN_APP_MESSAGE_IDENTIFIER;
extern NSString *const TUNE_IN_APP_MESSAGE_ACTION_SHOWN;
extern NSString *const TUNE_IN_APP_MESSAGE_ACTION_DISMISSED_AFTER_DURATION;
extern NSString *const TUNE_IN_APP_MESSAGE_SECONDS_DISPLAYED;
extern NSString *const TUNE_IN_APP_MESSAGE_ACTION_CTA_BUTTON_PRESSED;
extern NSString *const TUNE_IN_APP_MESSAGE_ACTION_CANCEL_BUTTON_PRESSED;
extern NSString *const TUNE_IN_APP_MESSAGE_ACTION_CLOSE_BUTTON_PRESSED;
extern NSString *const TUNE_IN_APP_MESSAGE_ACTION_CONTENT_AREA_PRESSED;
extern NSString *const TUNE_IN_APP_MESSAGE_ACTION_MESSAGE_PRESSED;

#pragma mark - Hash Types
extern NSString *const TUNE_HASH_TYPE_NONE;
extern NSString *const TUNE_HASH_TYPE_MD5;
extern NSString *const TUNE_HASH_TYPE_SHA1;
extern NSString *const TUNE_HASH_TYPE_SHA256;

#pragma mark - Push Notifications
extern NSString *const TUNE_PUSH_NOTIFICATION_ID;
extern NSString *const TUNE_PUSH_NOTIFICATION_ACTION;
extern NSString *const TUNE_PUSH_NOTIFICATION_ACTION_IGNORED;
extern NSString *const TUNE_PUSH_NOTIFICATION_ACTION_IGNORED_OPEN_URL;
extern NSString *const TUNE_PUSH_NOTIFICATION_ACTION_IGNORED_DEEP_ACTION;
extern NSString *const TUNE_PUSH_NOTIFICATION_ACTION_OPEN_URL;
extern NSString *const TUNE_PUSH_NOTIFICATION_ACTION_DEEP_ACTION;
extern NSString *const TUNE_PUSH_NOTIFICATION_NO_ACTION;
extern NSString *const TUNE_INTERACTIVE_NOTIFICATION_BUTTON_IDENTIFIER_SELECTED;
extern NSString *const TUNE_INTERACTIVE_NOTIFICATION_CATEGORY;

@end
