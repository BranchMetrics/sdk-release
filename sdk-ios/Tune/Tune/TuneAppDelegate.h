//
//  TuneAppDelegate.h
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/2/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#if IDE_XCODE_8_OR_HIGHER
#import <UserNotifications/UserNotifications.h>
#endif

@interface TuneAppDelegate : NSObject

#if !TARGET_OS_WATCH
+ (BOOL)application:(UIApplication *)application tune_continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray *restorableObjects))restorationHandler;

+ (void)application:(UIApplication *)application tune_didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

+ (void)application:(UIApplication *)application tune_didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

#if TARGET_OS_IOS
+ (void)application:(UIApplication *)application tune_didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

+ (void)application:(UIApplication *)application tune_handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)(void))completionHandler;

+ (void)application:(UIApplication *)application tune_handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)(void))completionHandler;

+ (void)userNotificationCenter:(id)center tune_didReceiveNotificationResponse:(id)response withCompletionHandler:(void(^)(void))completionHandler;

+ (void)userNotificationCenter:(id)center tune_willPresentNotification:(id)notification withCompletionHandler:(void (^)(NSUInteger))completionHandler;

+ (void)application:(UIApplication *)application tune_didReceiveLocalNotification:(UILocalNotification *)notification;
#endif

+ (BOOL)application:(UIApplication *)application tune_handleOpenURL:(NSURL *)url;

+ (BOOL)application:(UIApplication *)application tune_openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

#if IDE_XCODE_7_OR_HIGHER
+ (BOOL)application:(UIApplication *)app tune_openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options;
#else
+ (BOOL)application:(UIApplication *)app tune_openURL:(NSURL *)url options:(NSDictionary *)options;
#endif

#endif

@end
