//
//  TuneDeviceUtils.h
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 8/19/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TuneDeviceUtils : NSObject

/** Returns the string interface idiom. */
+ (NSString *)artisanInterfaceIdiomString;

+ (BOOL)currentDeviceIsTestFlight;

@end
