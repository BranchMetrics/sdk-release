//
//  ExtensionDelegate.m
//  TestApp_watchos WatchKit Extension
//
//  Created by Harshal Ogale on 10/7/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "ExtensionDelegate.h"

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
    // Perform any final initialization of your application.
    NSLog(@"ExtensionDelegate applicationDidFinishLaunching");
    
    [Tune initializeWithTuneAdvertiserId:TUNE_ADVERTISER_ID
                       tuneConversionKey:TUNE_CONVERSION_KEY
                         tunePackageName:TUNE_PACKAGE_NAME
                                wearable:NO];
    
    [Tune setDelegate:self];
    
#if DEBUG
    [Tune setDebugMode:YES];
    [Tune setAllowDuplicateRequests:YES];
#endif
}

- (void)applicationDidBecomeActive {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"ExtensionDelegate applicationDidBecomeActive");
    
    [Tune measureSession];
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
}


#pragma mark - TuneDelegate Methods

// Tune success callback
- (void)tuneDidSucceedWithData:(NSData *)data
{
    //NSDictionary *dict = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    //NSLog(@"Tune watch success: %@", dict);
    
    NSLog(@"Tune watchos success");
}

// Tune failure callback
- (void)tuneDidFailWithError:(NSError *)error
{
    NSLog(@"Tune watchos error: %@", error);
}

// Tune request enqueued
- (void)tuneEnqueuedActionWithReferenceId:(NSString *)referenceId
{
    NSLog(@"Tune watchos enqueued request: refId = %@", referenceId);
}

@end
