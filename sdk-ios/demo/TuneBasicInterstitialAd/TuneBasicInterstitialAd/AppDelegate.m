//
//  AppDelegate.m
//  TuneBasicInterstitialAd
//
//  Created by Harshal Ogale on 11/18/14.
//  Copyright (c) 2014 TUNE Inc. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

NSString * const TUNE_ADVERTISER_ID = @"877";
NSString * const TUNE_CONVERSION_KEY = @"40c19f41ef0ec2d433f595f0880d39b9";
NSString * const TUNE_PACKAGE_NAME = @"edu.self.AtomicDodgeBallLite";


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // initialize Tune by providing advertiser_id and conversion_key
    [Tune initializeWithTuneAdvertiserId:TUNE_ADVERTISER_ID
                       TuneConversionKey:TUNE_CONVERSION_KEY];
    
    // required only if your app's TUNE package name is different than the app bundle id
    [Tune setPackageName:TUNE_PACKAGE_NAME];
    
    return YES;
}

@end
