//
//  TuneAppDelegate.m
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/2/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneAppDelegate.h"

#import "Tune+Internal.h"
#import "TuneAnalyticsConstants.h"
#import "TuneDeeplink.h"
#import "TuneDeviceDetails.h"
#import "TuneFileManager.h"
#import "TuneNotification.h"
#import "TuneNotificationProcessing.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookConstants.h"
#import "TuneSkyhookPayloadConstants.h"
#import "TuneState.h"
#import "TuneSwizzleBlacklist.h"
#import "TuneUtils.h"
#import "TuneDeviceUtils.h"
#import "TuneSmartWhereHelper.h"
#import <objc/runtime.h>
#import <CoreSpotlight/CoreSpotlight.h>

@implementation TuneAppDelegate

NSString * const TuneAppDelegateClassNameDefault              = @"AppDelegate";
NSString * const TuneAppDelegateClassNameKey                  = @"AppDelegateClassName";

NSString * const TuneUserNotificationDelegateClassNameDefault = @"AppDelegate";
NSString * const TuneUserNotificationDelegateClassNameKey     = @"UserNotificationDelegateClassName";

NSString * const TuneShowDelegateWarningsKey                  = @"ShowDelegateWarnings";
BOOL const TuneShowDelegateWarningsDefault                    = YES;

// If swizzle succeeded
BOOL swizzleSuccess = NO;

+ (void)load {
    // Check if TMA is disabled
    if ([TuneState isTMADisabled]) { return; }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Check if global swizzle is disabled
        if ([TuneState isSwizzleDisabled]) {
            DebugLog(@"Skipping the `UIApplicationDelegate` Swizzle.");
            return;
        }
        
        // Read custom UIApplicationDelegate class name from local configuration plist,
        // if not found then by default use "AppDelegate" class name to swizzle on
        NSString *appDelegateClassName = [[TuneFileManager loadLocalConfigurationFromDisk] valueForKey:TuneAppDelegateClassNameKey] ?: TuneAppDelegateClassNameDefault;
        NSString *userNotificationDelegateClassName = [[TuneFileManager loadLocalConfigurationFromDisk] valueForKey:TuneUserNotificationDelegateClassNameKey] ?: TuneUserNotificationDelegateClassNameDefault;
        
        // Read whether AppDelegate warnings should be shown from local configuration plist,
        // if not found then show by default
        BOOL showDelegateWarnings = [[TuneFileManager loadLocalConfigurationFromDisk] valueForKey:TuneShowDelegateWarningsKey] != nil ? [[[TuneFileManager loadLocalConfigurationFromDisk] valueForKey:TuneShowDelegateWarningsKey] boolValue] : TuneShowDelegateWarningsDefault;
        
        // Check if class is on swizzle blacklist
        if ([TuneState isDisabledClass:appDelegateClassName]) {
            DebugLog(@"`%@` on Blacklist, Skipping the `UIApplicationDelegate` Swizzle.", appDelegateClassName);
            return;
        }
        
        // Check if class for the app delegate name exists
        Class delegateClass = [TuneUtils getClassFromString:appDelegateClassName];
        if (!delegateClass) {
            if (showDelegateWarnings) {
                WarnLog(@"Class `%@` not found. Please set your UIApplicationDelegate class name in TuneConfiguration.plist for key `%@`",
                        appDelegateClassName,
                        TuneAppDelegateClassNameKey);
            }
            return;
        }
        
        // Check if class for the user notification delegate name exists
        Class userNotificationDelegateClass = [TuneUtils getClassFromString:userNotificationDelegateClassName];
        if (!userNotificationDelegateClass && !delegateClass) {
            if (showDelegateWarnings) {
                WarnLog(@"Class `%@` not found. Please set your UNUserNotificationCenterDelegate class name in TuneConfiguration.plist for key `%@`",
                        userNotificationDelegateClassName,
                        TuneUserNotificationDelegateClassNameKey);
            }
            return;
        }
        
        // Commence swizzling!
        
        // NOTE: We are building this selector through concatenation since Apple does a static code analysis to see
        //        if this selector exists. If it does, Apple will then send out a warning email if push is not enabled.
        //        Since we only swizzle as an opt-in for explicitly handling push messages, we felt it was appropriate
        //        to not trigger the warning email through this selector.
        [TuneAppDelegate swizzleTheirSelector:NSSelectorFromString([[@"application:" stringByAppendingString:@"didRegisterFor"] stringByAppendingString:@"RemoteNotificationsWithDeviceToken:"])
                                     withOurs:@selector(application:tune_didRegisterForRemoteNotificationsWithDeviceToken:)
                                          for:delegateClass];
        [TuneAppDelegate swizzleTheirSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)
                                     withOurs:@selector(application:tune_didFailToRegisterForRemoteNotificationsWithError:)
                                          for:delegateClass];
        [TuneAppDelegate swizzleTheirSelector:@selector(application:didReceiveRemoteNotification:)
                                     withOurs:@selector(application:tune_didReceiveRemoteNotification:)
                                          for:delegateClass];
#if TARGET_OS_IOS
        if ([TuneDeviceUtils hasBackgroundNotificationEnabled]) {
            [TuneAppDelegate swizzleTheirSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)
                                         withOurs:@selector(application:tune_didReceiveRemoteNotification:fetchCompletionHandler:)
                                              for:delegateClass];
        }

        [TuneAppDelegate swizzleTheirSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:)
                                     withOurs:@selector(application:tune_handleActionWithIdentifier:forRemoteNotification:completionHandler:)
                                          for:delegateClass];
        [TuneAppDelegate swizzleTheirSelector:@selector(application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:)
                                     withOurs:@selector(application:tune_handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:)
                                          for:delegateClass];
        
        if([TuneDeviceDetails appIsRunningIniOS10OrAfter]) {
            [TuneAppDelegate swizzleTheirSelector:NSSelectorFromString(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:")
                                         withOurs:@selector(userNotificationCenter:tune_didReceiveNotificationResponse:withCompletionHandler:)
                                              for:userNotificationDelegateClass];
            [TuneAppDelegate swizzleTheirSelector:NSSelectorFromString(@"userNotificationCenter:willPresentNotification:withCompletionHandler:")
                                         withOurs:@selector(userNotificationCenter:tune_willPresentNotification:withCompletionHandler:)
                                              for:userNotificationDelegateClass];
        }
        
        [TuneAppDelegate swizzleTheirSelector:@selector(application:didReceiveLocalNotification:)
                                     withOurs:@selector(application:tune_didReceiveLocalNotification:)
                                          for:delegateClass];
#endif
        swizzleSuccess = YES;
    });
}


+ (void)swizzleTheirSelector:(SEL)originalSelector withOurs:(SEL)swizzledSelector for:(Class)delegateClass {
    Method originalMethod = class_getInstanceMethod(delegateClass, originalSelector);
    Method swizzledMethod = class_getClassMethod([self class], swizzledSelector);
    
    // Add original method in case it was not registered
    BOOL didAddMethod =
    class_addMethod(delegateClass,
                    originalSelector,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    // Check whether method was added (class did not implement it)
    // and whether class_getInstanceMethod is NULL (superclass did not implement it either)
    if (didAddMethod && originalMethod == NULL) {
        // If we successfully added method, and there was no superclass implementation,
        // have swizzled method do a no-op
        Method noOpMethod = class_getClassMethod([self class], @selector(tune_noOp));
        class_addMethod(delegateClass,
                        swizzledSelector,
                        method_getImplementation(noOpMethod),
                        method_getTypeEncoding(noOpMethod));
    } else {
        // If method existed in class or superclass, we just have to add the swizzled version and swap implementations
        class_addMethod(delegateClass,
                        swizzledSelector,
                        method_getImplementation(originalMethod),
                        method_getTypeEncoding(originalMethod));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}


#pragma mark - UIApplicationDelegate methods for handling remote notifications

+ (void)application:(UIApplication *)application tune_didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    InfoLog(@"application:didRegisterForRemoteNotificationsWithDeviceToken: intercept successful -- %@", NSStringFromClass([self class]));
    
    // Convert deviceToken into string
    NSString *deviceTokenString = [NSString stringWithFormat:@"%@",deviceToken];
    deviceTokenString = [deviceTokenString stringByReplacingOccurrencesOfString:@"<" withString:@""];
    deviceTokenString = [deviceTokenString stringByReplacingOccurrencesOfString:@">" withString:@""];
    deviceTokenString = [deviceTokenString stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    // Send out a skyhook to register deviceToken
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneRegisteredForRemoteNotificationsWithDeviceToken object:self userInfo:@{@"deviceToken" : deviceTokenString}];

    // Do not remove this NSLog -- it is how our customers know they have wired up Tune for Push correctly
    NSLog(@"Tune Push Registration Succeeded with Device Token: %@", deviceTokenString);

    // Only invoke original method if swizzle succeeded, otherwise it'll infinite loop
    if (swizzleSuccess) {
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"application:didRegisterForRemoteNotificationsWithDeviceToken:"];
#endif
        [self application:application tune_didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

+ (void)application:(UIApplication *)application tune_didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    InfoLog(@"application:didFailToRegisterForRemoteNotificationsWithError: intercept successful -- %@", NSStringFromClass([self class]));
    
    DebugLog(@"Failed To Register Device For Push %@", error.description);
    
    // Send out a skyhook for failure to register device for remote notifications
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneFailedToRegisterForRemoteNotifications object:self userInfo:@{@"error" : error}];
    
    if (swizzleSuccess) {
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"application:didFailToRegisterForRemoteNotificationsWithError:"];
#endif
        [self application:application tune_didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

+ (void)application:(UIApplication *)application tune_didReceiveRemoteNotification:(NSDictionary *)userInfo {
    InfoLog(@"application:didReceiveRemoteNotification: intercept successful -- %@", NSStringFromClass([self class]));
    
    [TuneAppDelegate handleReceivedMessage:userInfo application:application];
    
    if (swizzleSuccess) {
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"application:didReceiveRemoteNotification:"];
#endif
        [self application:application tune_didReceiveRemoteNotification:userInfo];
    }
}

#if TARGET_OS_IOS

+ (void)application:(UIApplication *)application tune_didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    InfoLog(@"application:didReceiveRemoteNotification:fetchCompletionHandler: intercept successful -- %@", NSStringFromClass([self class]));
    
    [TuneAppDelegate handleReceivedMessage:userInfo application:application];
    
    if (swizzleSuccess) {
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"application:didReceiveRemoteNotification:fetchCompletionHandler:"];
#endif
        [self application:application tune_didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    }
}

+ (void)application:(UIApplication *)application tune_didReceiveLocalNotification:(UILocalNotification *)notification{
    InfoLog(@"application:didReceiveLocalNotification: intercept successful -- %@", NSStringFromClass([self class]));
    
    [TuneAppDelegate handleLocalNotification:notification application:application];
    
    if (swizzleSuccess) {
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"application:didReceiveLocalNotification:"];
#endif
        [self application:application tune_didReceiveLocalNotification:notification];
    }
}

#pragma mark - UNUserNotificationCenter Methods

+ (void)userNotificationCenter:(id)center tune_didReceiveNotificationResponse:(id)response withCompletionHandler:(void(^)())completionHandler {
    InfoLog(@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler: intercept successful -- %@", NSStringFromClass([self class]));
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    SEL selNotification = NSSelectorFromString(@"notification");
    SEL selRequest = NSSelectorFromString(@"request");
    SEL selContent = NSSelectorFromString(@"content");
    SEL selUserInfo = NSSelectorFromString(@"userInfo");
    SEL selActionIdentifier = NSSelectorFromString(@"actionIdentifier");
    
    [TuneAppDelegate handleReceivedMessage:[[[[response performSelector:selNotification] performSelector:selRequest] performSelector:selContent] performSelector:selUserInfo]
                               application:[UIApplication sharedApplication]
                                identifier:[response performSelector:selActionIdentifier]];
    
    if ([TuneSmartWhereHelper isSmartWhereAvailable]){
        TuneSmartWhereHelper *tuneSmartWhereHelper = [TuneSmartWhereHelper getInstance];
        @try{
            SEL selReceiveNotificationResponse = NSSelectorFromString(@"didReceiveNotificationResponse:");
            [[tuneSmartWhereHelper getSmartWhere] performSelector:selReceiveNotificationResponse withObject:response];
        }@catch(NSException* e){
            DebugLog(@"Failed to process notification response. %@", e.description);
        }
    }
    
#pragma clang diagnostic pop
    
    if (swizzleSuccess) {
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"];
#endif
        [self userNotificationCenter:center tune_didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
    }
}


+ (void)userNotificationCenter:(id)center tune_willPresentNotification:(id)notification withCompletionHandler:(void (^)(NSUInteger))completionHandler{
    InfoLog(@"userNotificationCenter:willPresentNotification:withCompletionHandler: intercept successful -- %@", NSStringFromClass([self class]));
    __block UNNotificationPresentationOptions presentationOptions = UNNotificationPresentationOptionNone;

    if (swizzleSuccess) {
#if IDE_XCODE_8_OR_HIGHER
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([TuneSmartWhereHelper isSmartWhereAvailable]){
            TuneSmartWhereHelper *tuneSmartWhereHelper = [TuneSmartWhereHelper getInstance];
            @try{
                SEL selWillPresentNotification = NSSelectorFromString(@"willPresentNotification:");
                id swNotification = [[tuneSmartWhereHelper getSmartWhere] performSelector:selWillPresentNotification withObject:notification];
                if (swNotification != nil){
                    presentationOptions = (UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
                }
            }@catch(NSException* e){
                DebugLog(@"Failed to process notification response. %@", e.description);
            }
        }
#pragma clang diagnostic pop
#endif
        
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"userNotificationCenter:willPresentNotification:withCompletionHandler:"];
#endif
        
        [self userNotificationCenter:center tune_willPresentNotification:notification withCompletionHandler:^(UNNotificationPresentationOptions options){
            presentationOptions = options;
        }];
        
        completionHandler(presentationOptions);
    }
}

#pragma mark -

+ (void)application:(UIApplication *)application tune_handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    InfoLog(@"application:handleActionWithIdentifier:forRemoteNotification:completionHandler: intercept successful -- %@", NSStringFromClass([self class]));
    
    TuneNotification *tuneNotification = [TuneAppDelegate buildTuneNotification:userInfo withIdentifier:identifier];
    
    if (tuneNotification) {
        tuneNotification.notificationType = TuneNotificationRemoteInteractiveNotification;
        
        [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TunePushNotificationOpened object:nil userInfo:@{TunePayloadNotification : tuneNotification}];
        
        // Report on campaign
        if (tuneNotification.campaign) {
            [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneCampaignViewed object:nil userInfo:@{TunePayloadCampaign : tuneNotification.campaign}];
        }
    }
    
    if (swizzleSuccess) {
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"application:handleActionWithIdentifier:forRemoteNotification:completionHandler:"];
#endif
        [self application:application tune_handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:completionHandler];
    }
}

+ (void)application:(UIApplication *)application tune_handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler {
    InfoLog(@"application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler: intercept successful -- %@", NSStringFromClass([self class]));
    
    TuneNotification *tuneNotification = [TuneAppDelegate buildTuneNotification:userInfo withIdentifier:identifier];
    
    if (tuneNotification) {
        tuneNotification.notificationType = TuneNotificationRemoteInteractiveNotification;
        
        [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TunePushNotificationOpened object:nil userInfo:@{TunePayloadNotification : tuneNotification}];
        
        // Report on campaign
        if (tuneNotification.campaign) {
            [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneCampaignViewed object:nil userInfo:@{TunePayloadCampaign : tuneNotification.campaign}];
        }
    }
    
    if (swizzleSuccess) {
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:"];
#endif
        [self application:application tune_handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo completionHandler:completionHandler];
    }
}

#endif

#pragma mark - UIApplicationDelegate methods for handling deeplinks

+ (BOOL)application:(UIApplication *)application tune_handleOpenURL:(NSURL *)url {
#if TESTING
    [TuneAppDelegate unitTestingHelper:@"application:handleOpenURL:"];
#endif
    
    return [Tune handleOpenURL:url sourceApplication:nil];;
}

+ (BOOL)application:(UIApplication *)application tune_openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
#if TESTING
    [TuneAppDelegate unitTestingHelper:@"application:openURL:sourceApplication:annotation:"];
#endif
    
    return [Tune handleOpenURL:url sourceApplication:sourceApplication];;
}

+ (BOOL)application:(UIApplication *)app tune_openURL:(NSURL *)url options:(NSDictionary *)options {
#if TESTING
    [TuneAppDelegate unitTestingHelper:@"application:openURL:options:"];
#endif

    return [Tune handleOpenURL:url options:options];
}

#pragma mark - UIApplicationDelegate method to handle spotlight search measurement

+ (BOOL)application:(UIApplication *)application tune_continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray *restorableObjects))restorationHandler {
    InfoLog(@"application:continueUserActivity:restorationHandler: intercept successful -- %@", NSStringFromClass([self class]));
#if TARGET_OS_IOS
    if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
        NSString *searchIndexUniqueId = userActivity.userInfo[CSSearchableItemActivityIdentifier];
        [Tune handleOpenURL:[NSURL URLWithString:searchIndexUniqueId]
          sourceApplication:@"spotlight"];
    } else
#endif
        if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] && userActivity.webpageURL) {
            [Tune handleOpenURL:userActivity.webpageURL
              sourceApplication:@"web"];
        }
    
    if (swizzleSuccess) {
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"application:continueUserActivity:restorationHandler:"];
#endif
        return [self application:application tune_continueUserActivity:userActivity restorationHandler:restorationHandler];
    }
    return NO;
}

#pragma mark - Tune no-op function for auto-implemented missing methods

+ (void)tune_noOp {
    DebugLog(@"Entered Tune No-Op from Swizzle");
}

#pragma mark - Helper functions

#if !TARGET_OS_TV
+ (void)handleLocalNotification:(UILocalNotification *)notification application: (UIApplication *)application{
    if ([TuneSmartWhereHelper isSmartWhereAvailable]){
        TuneSmartWhereHelper *tuneSmartWhereHelper = [TuneSmartWhereHelper getInstance];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        @try{
            [[tuneSmartWhereHelper getSmartWhere] performSelector:@selector(didReceiveLocalNotification:) withObject:notification];
        }@catch(NSException* e){
            DebugLog(@"Failed to process local notification. %@", e.description);
        }
#pragma clang diagnostic pop
    }
}
#endif

+ (void)handleReceivedMessage:(NSDictionary *)userInfo application:(UIApplication *)application {
    [self handleReceivedMessage:userInfo application:application identifier:nil];
}

+ (void)handleReceivedMessage:(NSDictionary *)userInfo application:(UIApplication *)application identifier:(NSString *)identifier {
    TuneNotification *tuneNotification = [TuneAppDelegate buildTuneNotification:userInfo.copy withIdentifier:identifier];
    
    if (tuneNotification) {
        if ([application applicationState] != UIApplicationStateActive) {
            // User Tapped notification while app was in background
            // Send analytics event with NotificationOpened action
            // NOTE: The KPIs for push campaigns depend on this to calculate the open rate
            TuneNotification *tuneNotificationOpened = [TuneNotificationProcessing processUserInfoFromNotification:userInfo withIdentifier:nil];
            tuneNotificationOpened.analyticsReportingAction = TUNE_EVENT_ACTION_NOTIFICATION_OPENED;
            tuneNotificationOpened.notificationType = TuneNotificationRemoteNotification;
            
            [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TunePushNotificationOpened object:nil userInfo:@{TunePayloadNotification:tuneNotificationOpened}];
        }
        
        // Send analytics event with actual push action
        tuneNotification.notificationType = TuneNotificationRemoteNotification;
        
        [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TunePushNotificationOpened object:nil userInfo:@{TunePayloadNotification:tuneNotification}];
        
        // Report on campaign
        if (tuneNotification.campaign) {
            [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneCampaignViewed object:nil userInfo:@{TunePayloadCampaign:tuneNotification.campaign}];
        }
    }
}

+ (TuneNotification *)buildTuneNotification:(NSDictionary *)userInfo withIdentifier:(NSString *)identifier {
    TuneNotification *tuneNotification = nil;
    
    if ([userInfo objectForKey:TUNE_PUSH_NOTIFICATION_ID]) {
        tuneNotification = [TuneNotificationProcessing processUserInfoFromNotification:userInfo withIdentifier:identifier];
        
        // Perform action associated with the notification
        if (tuneNotification.actionAfterOpened) {
            [tuneNotification.actionAfterOpened performAction];
        }
    }
    
    return tuneNotification;
}

#if TESTING
+ (void)unitTestingHelper:(NSString *)message {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [NSClassFromString(@"TuneAppDelegateTests") performSelector:@selector(_tuneSuperSecretTestingCallbackSwizzleCalled:) withObject:message];
#pragma clang diagnostic pop
}
#endif

@end
