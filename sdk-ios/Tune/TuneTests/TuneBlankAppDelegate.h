//
//  TuneBlankAppDelegate.h
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/15/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <UserNotifications/UserNotifications.h>

@interface TuneBlankAppDelegate : UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate>

@property (nonatomic) int didRegisterCount;
@property (nonatomic) int didReceiveCount;
@property (nonatomic) int didReceiveLocalCount;
@property (nonatomic) int didContinueCount;
@property (nonatomic) int handleActionCount;
@property (nonatomic) int willPresentCount;
@property (nonatomic) int openURLCount;

@end
