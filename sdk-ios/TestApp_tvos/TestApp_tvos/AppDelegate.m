//
//  AppDelegate.m
//  TestApp_tvOS
//
//  Created by Harshal Ogale on 10/7/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "AppDelegate.h"

NSString * const MAT_ADVERTISER_ID  = @"<your_tune_advertiser_id>";
NSString * const MAT_CONVERSION_KEY = @"<your_tune_conversion_key>";
NSString * const MAT_PACKAGE_NAME   = @"<your_tune_package_name>";


@interface AppDelegate () <TuneDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSLog(@"TV AppDelegate didFinishLaunching");
    
    [Tune setDelegate:self];
    
    //[Tune setDebugMode:YES];
    [Tune setAllowDuplicateRequests:YES];
    
    // set your MAT advertiser id and conversion key
    [Tune initializeWithTuneAdvertiserId:MAT_ADVERTISER_ID
                       tuneConversionKey:MAT_CONVERSION_KEY
                         tunePackageName:MAT_PACKAGE_NAME
                                wearable:NO];
    
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
    
    NSLog(@"TV AppDelegate didBecomeActive");
    
    //[Tune measureSession];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - TuneDelegate Methods

// Tune success callback
- (void)tuneDidSucceedWithData:(NSData *)data
{
    NSDictionary *dict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    NSLog(@"Tune tvOS success: %@", dict);
}

// Tune failure callback
- (void)tuneDidFailWithError:(NSError *)error
{
    NSLog(@"Tune tvOS error: %@", error);
}

// Tune request enqueued
- (void)tuneEnqueuedActionWithReferenceId:(NSString *)referenceId
{
    NSLog(@"Tune tvOS enqueued request: refId = %@", referenceId);
}

// Tune deeplink received
- (void)tuneDidReceiveDeeplink:(NSString *)deeplink
{
    NSLog(@"Tune tvOS deferred deeplink = %@", deeplink);
    
    if(deeplink)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:deeplink]];
    }
}

// Tune deeplink request failed
-(void)tuneDidFailDeeplinkWithError:(NSError *)error
{
    NSLog(@"Tune tvOS deeplink error: %@", error);
}

@end
