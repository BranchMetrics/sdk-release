//
//  TuneDeviceUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 8/19/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneDeviceUtils.h"
#import "TuneUtils.h"

#include <sys/sysctl.h>

@implementation TuneDeviceUtils

#if !TARGET_OS_WATCH
+ (NSString *)artisanInterfaceIdiomString {
    switch (UI_USER_INTERFACE_IDIOM()) {
        case UIUserInterfaceIdiomPad:
            return @"iPad";
            break;
        case UIUserInterfaceIdiomPhone:
            return @"iPhone";
            break;
        case UIUserInterfaceIdiomUnspecified:
            return @"iPhone";
            break;
        default:
            return @"iPhone";
    }
}
#endif

+ (BOOL)currentDeviceIsTestFlight {
    BOOL hasEmbeddedMobileProvision = [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"] != nil;
    BOOL isSandboxReceipt = [[[[NSBundle mainBundle] appStoreReceiptURL] lastPathComponent] isEqualToString:@"sandboxReceipt"];
    BOOL isTestFlight = isSandboxReceipt && !hasEmbeddedMobileProvision;
    
    return isTestFlight;
}

@end
