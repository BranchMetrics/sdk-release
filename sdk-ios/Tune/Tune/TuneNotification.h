//
//  TuneNotification.h
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/2/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneCampaign.h"
#import "TuneMessageAction.h"

@interface TuneNotification : NSObject

enum TuneNotificationType {
    TuneNotificationRemoteNotification = 1,
    TuneNotificationRemoteInteractiveNotification
};
typedef enum TuneNotificationType TuneNotificationType;

@property (nonatomic) TuneNotificationType notificationType;
@property (nonatomic, copy) NSString *tunePushID;
@property (nonatomic, copy) NSDictionary *userInfo;
@property (nonatomic, copy) NSString *analyticsReportingAction;  // TUNE_PUSH_NOTIFICATION_ACTION
@property (strong, nonatomic) TuneCampaign *campaign;
@property (strong, nonatomic) TuneMessageAction *actionAfterOpened;

// For interactive remote notification only
@property (nonatomic, copy) NSString *interactivePushIdentifierSelected;
@property (nonatomic, copy) NSString *interactivePushCategory;

+ (NSString *)tuneNotificationTypeAsString:(TuneNotificationType)notificationType;

@end
