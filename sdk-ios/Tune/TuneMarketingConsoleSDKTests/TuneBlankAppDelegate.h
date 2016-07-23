//
//  TuneBlankAppDelegate.h
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/15/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

#if IDE_XCODE_8_OR_HIGHER
#import <UserNotifications/UserNotifications.h>
#endif

#if IDE_XCODE_8_OR_HIGHER
@interface TuneBlankAppDelegate : UIResponder <UIApplicationDelegate, UNUserNotificationCenterDelegate>
#else
@interface TuneBlankAppDelegate : UIResponder <UIApplicationDelegate>
#endif

@property (nonatomic) int didRegisterCount;
@property (nonatomic) int didReceiveCount;
@property (nonatomic) int didContinueCount;
@property (nonatomic) int handleActionCount;
@property (nonatomic) int openURLCount;
@property (nonatomic) int deepActionCount;
@property (nonatomic) NSString *deepActionValue;

@end
