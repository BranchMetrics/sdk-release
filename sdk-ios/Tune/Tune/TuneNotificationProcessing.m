//
//  TuneNotificationProcessing.m
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/2/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneNotificationProcessing.h"
#import "TuneAnalyticsConstants.h"
#import "TuneCampaign.h"
#import "TuneNotification.h"
#import "TuneSkyhookConstants.h"
#import "TuneSessionManager.h"
#import "TuneDeviceDetails.h"


// Note: string equivalent of constant UNNotificationDefaultActionIdentifier;
// keeps UserNotification framework reference optional in the host app project
NSString * const TUNE_UNNotificationDefaultActionIdentifier = @"com.apple.UNNotificationDefaultActionIdentifier";


@implementation TuneNotificationProcessing

// This handles dealing with the next action in the push payload if neccessary and stripping out the ANA dictionary if there
// This method is responsible for executing the action if present
+ (TuneNotification *)processUserInfoFromNotification:(NSDictionary *)userInfo withIdentifier:(NSString *)identifier {
    
    TuneNotification *tuneNotification = [[TuneNotification alloc] init];
    
    NSString *pushNotificationAction = TUNE_PUSH_NOTIFICATION_NO_ACTION;
    
    @try {
        // Look for campaign info
        // Find TUNE_PUSH_NOTIFICATION_ID if present
        NSString *pushId = userInfo[TUNE_PUSH_NOTIFICATION_ID];
        if (pushId) {
            tuneNotification.tunePushID = pushId;
        }
        
        TuneCampaign *campaign = [[TuneCampaign alloc] initWithNotificationUserInfo:userInfo];
        if (campaign) {
            tuneNotification.campaign = campaign;
        }
        
        // Look for category if exists
        NSString *category = userInfo[@"aps"][@"aps"][@"category"];
        if (category) {
            tuneNotification.interactivePushCategory = category;
        }
        
        NSDictionary *nextAction = nil;
        
        BOOL isDefaultAction = NO;

        if ([TuneDeviceDetails runningOnPhone] || [TuneDeviceDetails runningOnTablet] || [TuneDeviceDetails appIsRunningIniOS10OrAfter]) {
            isDefaultAction = [identifier isEqualToString:TUNE_UNNotificationDefaultActionIdentifier];
        }
        
        if (identifier && !isDefaultAction) {
            // Since there's identifier user has selected an interactive button
            tuneNotification.interactivePushIdentifierSelected = identifier;
            
            NSString *interactiveButtonActionDictionaryKey = [NSString stringWithFormat:@"ANA_%@",identifier];
            
            if (userInfo[interactiveButtonActionDictionaryKey]) {
                // We have an action for this identifier
                nextAction = userInfo[interactiveButtonActionDictionaryKey];
            }
        } else {
            if ((userInfo[@"ANA"]) || (userInfo[@"ANAF"])) {
                if (userInfo[@"ANA"]) {
                    // Only do next action if the app is not active
                    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
                        nextAction = userInfo[@"ANA"];
                    } else {
                        pushNotificationAction = TUNE_PUSH_NOTIFICATION_ACTION_IGNORED;
                        NSDictionary *ignoredNextAction = userInfo[@"ANA"];
                        if (ignoredNextAction[@"URL"]) {
                            pushNotificationAction = TUNE_PUSH_NOTIFICATION_ACTION_IGNORED_OPEN_URL;
                        }
                        if (ignoredNextAction[@"DA"]) {
                            pushNotificationAction = TUNE_PUSH_NOTIFICATION_ACTION_IGNORED_DEEP_ACTION;
                        }
                    }
                }
                
                if (userInfo[@"ANAF"]) {
                    nextAction = userInfo[@"ANAF"];
                }
            }
        }
        // If we have a next action then do it
        if (nextAction) {
            // Unless this has URL or DA it's TUNE_PUSH_NOTIFICATION_NO_ACTION
            pushNotificationAction = TUNE_PUSH_NOTIFICATION_NO_ACTION;
            
            // Is the next action a deep link?
            if (nextAction[@"URL"]) {
                NSString *url = nextAction[@"URL"];
                TuneMessageAction *action = [[TuneMessageAction alloc] init];
                action.url = url;
                tuneNotification.actionAfterOpened = action;
                pushNotificationAction = TUNE_PUSH_NOTIFICATION_ACTION_OPEN_URL;
            }
            
            // Is the next action a deep action?
            if (nextAction[@"DA"]) {
                NSString *deepActionName = nextAction[@"DA"];
                NSMutableDictionary *deepActionData = nil;
                if (nextAction[@"DAD"]) {
                    deepActionData = nextAction[@"DAD"];
                }
                
                pushNotificationAction = TUNE_PUSH_NOTIFICATION_ACTION_DEEP_ACTION;
                
                TuneMessageAction *action = [[TuneMessageAction alloc] init];
                action.deepActionName = deepActionName;
                action.deepActionData = deepActionData;
                tuneNotification.actionAfterOpened = action;
            }
            
#if TARGET_OS_IOS
            // Do we need to remove the notification from the notification center?
            if ( (nextAction[@"D"]) && ([nextAction[@"D"] isEqualToString:@"1"]) ) {
                // NOTE: this perserves the badge number and will delete ALL notifications for a given app in the notification center
                int badgeNum = (int)[[UIApplication sharedApplication] applicationIconBadgeNumber];
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badgeNum];
            }
#endif
        }
    } @catch (NSException *exception) {
        ErrorLog(@"Parsing push payload failed: %@",exception.description);
    }
    
    tuneNotification.analyticsReportingAction = pushNotificationAction;
    tuneNotification.userInfo = userInfo;
    
    // Update this ASAP since the user will need to know immediately if they have gotten a Tune push
    [TuneManager currentManager].sessionManager.lastOpenedPushNotification = tuneNotification;
    
    return tuneNotification;
}

@end
