//
//  TunePushUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 8/15/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import "TunePushUtils.h"

@implementation TunePushUtils

#pragma mark - Push Notification Status Helper

+ (BOOL)isAlertPushNotificationEnabled {
    BOOL pushEnabled = NO;
    
#if TARGET_OS_IOS
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        // iOS8 and after way to get notification types
        pushEnabled = UIUserNotificationTypeAlert == (UIUserNotificationTypeAlert & [UIApplication sharedApplication].currentUserNotificationSettings.types);
    } else {
        // Pre iOS8 way to get notification types
        pushEnabled = UIUserNotificationTypeAlert == (UIUserNotificationTypeAlert & [UIApplication sharedApplication].enabledRemoteNotificationTypes);
    }
#endif
    
    return pushEnabled;
}

@end
