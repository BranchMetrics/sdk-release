//
//  TuneNotification.m
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/2/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneNotification.h"

@implementation TuneNotification

+ (NSString *)tuneNotificationTypeAsString:(TuneNotificationType)notificationType {
    NSString *notificationTypeString;
    
    switch (notificationType) {
        case TuneNotificationRemoteNotification:
            notificationTypeString = @"TuneNotificationRemoteNotification";
            break;
        case TuneNotificationRemoteInteractiveNotification:
            notificationTypeString = @"TuneNotificationRemoteInteractiveNotification";
            break;
    }
    
    return notificationTypeString;
}

@end
