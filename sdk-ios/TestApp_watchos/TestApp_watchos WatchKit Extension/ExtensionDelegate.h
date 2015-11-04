//
//  ExtensionDelegate.h
//  TestApp_watchos WatchKit Extension
//
//  Created by Harshal Ogale on 10/7/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@import MobileAppTracker_watchos;

@import MobileCoreServices;

NSString * const TUNE_ADVERTISER_ID  = @"877";
NSString * const TUNE_CONVERSION_KEY = @"40c19f41ef0ec2d433f595f0880d39b9";
NSString * const TUNE_PACKAGE_NAME   = @"edu.self.AtomicDodgeBallLite";

@interface ExtensionDelegate : NSObject <WKExtensionDelegate, TuneDelegate>

@end
