//
//  TuneDeviceUtils.h
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 8/19/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IOS
BOOL tune_isPad();
#endif


@interface TuneDeviceUtils : NSObject

+ (BOOL)hasBackgroundNotificationEnabled;

/** Returns the hardware identifier string for the current device,
 e.g. "iPhone2,1" */
+ (NSString *)artisanHardwareIdentifier;

#if !TARGET_OS_WATCH
/** Returns the interface idiom for the app. */
+ (UIUserInterfaceIdiom)artisanInterfaceIdiom;
#endif

/** Returns the string interface idiom. */
+ (NSString *)artisanInterfaceIdiomString;

+ (NSString *)artisanIOSVersionString;

+ (BOOL)currentDeviceIsIpadSimulator;
+ (BOOL)currentDeviceIsIphoneSimulator;
+ (BOOL)currentDeviceIsSimulator;

@end
