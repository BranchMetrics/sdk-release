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
#import <objc/runtime.h>
#import <CoreSpotlight/CoreSpotlight.h>

@implementation TuneAppDelegate

NSString * const TuneAppDelegateClassNameDefault = @"AppDelegate";
NSString * const TuneAppDelegateClassNameKey   = @"AppDelegateClassName";

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
        
        // Check if class is on swizzle blacklist
        if ([TuneState isDisabledClass:appDelegateClassName]) {
            DebugLog(@"`%@` on Blacklist, Skipping the `UIApplicationDelegate` Swizzle.", appDelegateClassName);
            return;
        }
        
        // Check if class for the app delegate name exists
        Class delegateClass = [TuneUtils getClassFromString:appDelegateClassName];
        if (!delegateClass) {
            WarnLog(@"Class `%@` not found. Please set your UIApplicationDelegate class name in TuneConfiguration.plist for key `%@`",
                    appDelegateClassName,
                    TuneAppDelegateClassNameKey);
            return;
        }
        
        // Commence swizzling!
        
        // NOTE: We are building this selector through concatination since Apple does a static code analysis to see
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
#endif
        [TuneAppDelegate swizzleTheirSelector:@selector(application:handleOpenURL:)
                                     withOurs:@selector(application:tune_handleOpenURL:)
                                          for:delegateClass];
        [TuneAppDelegate swizzleTheirSelector:@selector(application:openURL:sourceApplication:annotation:)
                                     withOurs:@selector(application:tune_openURL:sourceApplication:annotation:)
                                          for:delegateClass];
        
        if([TuneDeviceDetails appIsRunningIniOS9OrAfter]) {
            [TuneAppDelegate swizzleTheirSelector:@selector(application:continueUserActivity:restorationHandler:)
                                         withOurs:@selector(application:tune_continueUserActivity:restorationHandler:)
                                              for:delegateClass];
#if !IDE_XCODE_7_OR_HIGHER
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
#endif
            [TuneAppDelegate swizzleTheirSelector:@selector(application:openURL:options:)
                                         withOurs:@selector(application:tune_openURL:options:)
                                              for:delegateClass];
#if !IDE_XCODE_7_OR_HIGHER
#pragma clang diagnostic pop
#endif
        }
        
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
    
    if (didAddMethod) {
        // If we had to add method, there was no prior implementation, so have swizzled method do a no-op
        Method noOpMethod = class_getClassMethod([self class], @selector(tune_noOp));
        class_addMethod(delegateClass,
                        swizzledSelector,
                        method_getImplementation(noOpMethod),
                        method_getTypeEncoding(noOpMethod));
    } else {
        // If method existed, we just have to add the swizzled version and swap implementations
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
    if (swizzleSuccess) {
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"application:didFailToRegisterForRemoteNotificationsWithError:"];
#endif
        [self application:application tune_didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

+ (void)application:(UIApplication *)application tune_didReceiveRemoteNotification:(NSDictionary *)userInfo {
    InfoLog(@"application:didReceiveRemoteNotification: intercept successful -- %@", NSStringFromClass([self class]));
    
    [TuneAppDelegate handleRecievedMessage:userInfo application:application appDelegate:self];
    
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
    
    [TuneAppDelegate handleRecievedMessage:userInfo application:application appDelegate:self];
    
    if (swizzleSuccess) {
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"application:didReceiveRemoteNotification:fetchCompletionHandler:"];
#endif
        [self application:application tune_didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    }
}

+ (void)application:(UIApplication *)application tune_handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    InfoLog(@"application:handleActionWithIdentifier:forRemoteNotification:completionHandler: intercept successful -- %@", NSStringFromClass([self class]));
    
    TuneNotification *tuneNotification = [TuneAppDelegate buildTuneNotification:userInfo withIdentifier:identifier];
    
    if (tuneNotification) {
        tuneNotification.notificationType = TuneNotificationRemoteInteractiveNotification;
        
        [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TunePushNotificationOpened object:nil userInfo:@{TunePayloadNotification : tuneNotification}];
        
        // Report on campaign
        if (tuneNotification.campaign) {
            [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneCampaignViewed object:self userInfo:@{TunePayloadCampaign : tuneNotification.campaign}];
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
            [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneCampaignViewed object:self userInfo:@{TunePayloadCampaign : tuneNotification.campaign}];
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
    InfoLog(@"application:handleOpenURL: intercept successful -- %@", NSStringFromClass([self class]));
    
    [Tune applicationDidOpenURL:[url absoluteString] sourceApplication:nil];
    
    if (swizzleSuccess) {
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"application:handleOpenURL:"];
#endif
        return [self application:application tune_handleOpenURL:url];
    }
    return NO;
}

+ (BOOL)application:(UIApplication *)application tune_openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    InfoLog(@"application:openURL:sourceApplication:annotation: intercept successful -- %@", NSStringFromClass([self class]));
    
    [Tune applicationDidOpenURL:[url absoluteString] sourceApplication:sourceApplication];
    
    if (swizzleSuccess) {
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"application:openURL:sourceApplication:annotation:"];
#endif
        return [self application:application tune_openURL:url sourceApplication:sourceApplication annotation:annotation];
    }
    return NO;
}

+ (BOOL)application:(UIApplication *)app tune_openURL:(NSURL *)url options:(NSDictionary *)options {
    InfoLog(@"application:openURL:options: intercept successful -- %@", NSStringFromClass([self class]));
    
    [Tune applicationDidOpenURL:[url absoluteString] sourceApplication:nil];
    
    if (swizzleSuccess) {
#if TESTING
        [TuneAppDelegate unitTestingHelper:@"application:openURL:options:"];
#endif
        return [self application:app tune_openURL:url options:options];
    }
    return NO;
}

#pragma mark - UIApplicationDelegate method to handle spotlight search measurement

+ (BOOL)application:(UIApplication *)application tune_continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray *restorableObjects))restorationHandler {
    InfoLog(@"application:continueUserActivity:restorationHandler: intercept successful -- %@", NSStringFromClass([self class]));
#if TARGET_OS_IOS
    if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
        NSString *searchIndexUniqueId = userActivity.userInfo[CSSearchableItemActivityIdentifier];
        [Tune applicationDidOpenURL:searchIndexUniqueId
                  sourceApplication:@"spotlight"];
    } else
#endif
        if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] && userActivity.webpageURL) {
            [Tune applicationDidOpenURL:userActivity.webpageURL.absoluteString
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

+ (void)handleRecievedMessage:(NSDictionary *)userInfo application:(UIApplication *)application appDelegate:(id)appDelegate {
    TuneNotification *tuneNotification = [TuneAppDelegate buildTuneNotification:userInfo.copy withIdentifier:nil];
    
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
            [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneCampaignViewed object:appDelegate userInfo:@{TunePayloadCampaign:tuneNotification.campaign}];
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
