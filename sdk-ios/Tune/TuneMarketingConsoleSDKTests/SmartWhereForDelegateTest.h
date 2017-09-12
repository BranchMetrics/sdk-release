//
//  SmartWhereForDelegateTests.h
//  TuneMarketingConsoleSDK
//
//  Created by Gordon Stewart on 6/28/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

#if IDE_XCODE_8_OR_HIGHER
#import <UserNotifications/UserNotifications.h>
#endif

@interface SmartWhereForDelegateTest : NSObject

- (id)didReceiveLocalNotification:(UILocalNotification*)notification;
- (id)willPresentNotification:(UNNotification *)notification;
- (BOOL)didReceiveNotificationResponse:(UNNotificationResponse *)response;

@end

