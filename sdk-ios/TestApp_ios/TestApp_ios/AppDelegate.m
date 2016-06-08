//
//  AppDelegate.m
//  TestApp
//
//  Created by Harshal Ogale on 9/29/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "AppDelegate.h"

@import AdSupport;
@import CoreTelephony;
@import Tune;
@import MobileCoreServices;
@import iAd;
@import Security;
@import StoreKit;
@import SystemConfiguration;

NSString * const TUNE_ADVERTISER_ID  = @"877";
NSString * const TUNE_CONVERSION_KEY = @"40c19f41ef0ec2d433f595f0880d39b9";
NSString * const TUNE_PACKAGE_NAME   = @"edu.self.AtomicDodgeBallLite";

@interface AppDelegate () <TuneDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [Tune initializeWithTuneAdvertiserId:TUNE_ADVERTISER_ID
                       tuneConversionKey:TUNE_CONVERSION_KEY
                         tunePackageName:TUNE_PACKAGE_NAME
                                wearable:NO];
    
    [Tune setDelegate:self];
    
    [Tune setDebugMode:YES];
    
    [Tune checkForDeferredDeeplink:self];
    
    [Tune startAppToAppMeasurement:@"abc" advertiserId:@"877" offerId:@"12345" publisherId:@"321" redirect:YES];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"applicationDidBecomeActive:");
    
    [Tune measureSession];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(id)annotation {
    NSLog(@"application:openURL:sourceApplication: %@", url.absoluteString);
    
    [Tune applicationDidOpenURL:url.absoluteString sourceApplication:sourceApplication];
    
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options {
    NSLog(@"application:openURL:options: %@", url.absoluteString);
    
    NSString *sourceApplication = options[UIApplicationLaunchOptionsSourceApplicationKey];
    
    [Tune applicationDidOpenURL:url.absoluteString sourceApplication:sourceApplication];
    
    return YES;
}


#pragma mark - TuneDelegate Methods

// Tune success callback
- (void)tuneDidSucceedWithData:(NSData *)data {
    NSLog(@"Tune ios success");
//    NSDictionary *dict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
//    
//    NSLog(@"Tune ios success: %@", dict);
}

// Tune failure callback
- (void)tuneDidFailWithError:(NSError *)error {
    NSLog(@"Tune ios error: %@", error);
}

// Tune request enqueued
- (void)tuneEnqueuedActionWithReferenceId:(NSString *)referenceId {
    NSLog(@"Tune ios enqueued request: refId = %@", referenceId);
}

// Tune deeplink received
- (void)tuneDidReceiveDeeplink:(NSString *)deeplink {
    NSLog(@"Tune ios deferred deeplink = %@", deeplink);
    
    if(deeplink)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:deeplink]];
    }
}

// Tune deeplink request failed
-(void)tuneDidFailDeeplinkWithError:(NSError *)error
{
    NSLog(@"Tune ios deeplink error: %@", error);
}

@end
