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

// This must be called on Main Thread!
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

// This method calls the completion block on Main Thread!  If it's expensive do a dispatch async to a background thread.
+ (void)checkNotificationSettingsWithCompletion:(void(^)(BOOL pushEnabled))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        __block BOOL pushEnabled = [self isAlertPushNotificationEnabled];

        if (completion) {
            completion(pushEnabled);
        }
    });
}

@end
