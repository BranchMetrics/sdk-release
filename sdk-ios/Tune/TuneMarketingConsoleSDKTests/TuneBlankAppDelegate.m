//
//  TuneBlankAppDelegate.m
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/15/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneBlankAppDelegate.h"
#import "Tune.h"

@implementation TuneBlankAppDelegate

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    self.didRegisterCount += 1;
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
}

#if TARGET_OS_IOS
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    self.didReceiveCount += 1;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{
    self.didReceiveLocalCount += 1;
}

#if IDE_XCODE_8_OR_HIGHER
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)())completionHandler {
    self.didReceiveCount += 1;
    completionHandler();
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler{
    self.willPresentCount += 1;
    completionHandler(UNNotificationPresentationOptionNone);
}
#endif
#endif

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray * restorableObjects))restorationHandler {
    self.didContinueCount = 1;
    return YES;
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    self.handleActionCount += 1;
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler {
    self.handleActionCount += 1;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary *)options {
    self.openURLCount += 1;
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    self.openURLCount += 1;
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    self.openURLCount += 1;
    return YES;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    // Initialize Tune so that didOpenURL can be called
    [Tune initializeWithTuneAdvertiserId:@"877"
                       tuneConversionKey:@"8c14d6bbe466b65211e781d62e301eec"];
    
#if TARGET_OS_IOS
    // Register a deep action
    [Tune registerDeepActionWithId:@"myBlankAppDelegatesDeepAction" friendlyName:@"My very first deep action!" data:@{@"message": @"Default string"} andAction:^(NSDictionary *data) {
        // I would like to test that deep action is called, but UIApplication sharedApplication is nil in tests
        self.deepActionCount += 1;
        self.deepActionValue = data[@"message"];
    }];
#endif
}

@end
