//
//  TuneDeviceDetails.h
//  In-App Messaging Test App
//
//  Created by Scott Wasserman on 7/17/14.
//  Copyright (c) 2014 Tune Mobile. All rights reserved.
//

#import "TuneInAppMessageConstants.h"

@interface TuneDeviceDetails : NSObject {
    NSArray *_supportedOrientations;
    BOOL _canRunOniPhone;
    BOOL _canRunOniPad;
    BOOL _canRunOnTV;
    BOOL _canRunOnWatch;
}

+ (TuneDeviceDetails *)sharedDetails;

#if TARGET_OS_IOS
+ (NSArray *)getSupportedDeviceOrientations;
+ (NSString *)getDeviceOrientationString:(UIDeviceOrientation)orientation;
+ (UIDeviceOrientation)getUIDeviceOrientationFromString:(NSString *)orientationString;
#endif

/**
 *  Get the supported device types as a pipe-delimited string. The values will be iPhone and/or iPad, so if this is a universal app this will return a string like @"iPhone|iPad"
 *
 *  This is used for sending capabilities back to Tune
 */
+ (NSString *)getSupportedDeviceTypesString;

/**
 *  Get the supported device orientations as a pipe-delimited string. Converts the values to Portrait, UpsideDown, LandscapeLeft, LandscapeRight
 *
 *  This is used for sending capabilities back to Tune
 */
+ (NSString *)getSupportedDeviceOrientationsString;

+ (BOOL)runningOnPhone;
+ (BOOL)runningOnTablet;
+ (BOOL)runningOnTV;

+ (BOOL)runningOn480HeightPhone;
+ (BOOL)runningOn568HeightPhone;
+ (BOOL)runningOn667HeightPhone;
+ (BOOL)runningOn736HeightPhone;

+ (BOOL)appCanRunOniPhone;
+ (BOOL)appCanRunOniPad;
+ (BOOL)appCanRunOnTV;
+ (BOOL)appCanRunOnWatch;

+ (BOOL)appSupportsLandscape;
+ (BOOL)appSupportsPortrait;

#pragma mark - Retina Checks

+ (BOOL)isRetina;

#pragma mark - Checking iOS Version

#if !TARGET_OS_WATCH
+ (BOOL)appIsRunningIniOS6OrBefore;
+ (BOOL)appIsRunningIniOS7;
+ (BOOL)appIsRunningIniOS7OrAfter;
+ (BOOL)appIsRunningIniOS8OrAfter;
+ (BOOL)appIsRunningIniOS9OrAfter;
+ (BOOL)appIsRunningIniOSVersionOrAfter:(CGFloat)version;
#endif

#if TARGET_OS_IOS
+ (BOOL)orientationIsSupportedByApp:(UIDeviceOrientation)orientation;
#endif

+ (TuneMessageDeviceOrientation)getPortraitForDevice;
+ (TuneMessageDeviceOrientation)getPortraitUpsideDownForDevice;
+ (TuneMessageDeviceOrientation)getLandscapeLeftForDevice;
+ (TuneMessageDeviceOrientation)getLandscapeRightForDevice;

@end
