//
//  TuneDeviceUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 8/19/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneDeviceUtils.h"
#import "TuneDeviceDetails.h"
#import "TuneUtils.h"

#include <sys/sysctl.h>


#if TARGET_OS_IOS
//-----------------------------------------------------------------------------
// BOOL tune_isPad()
//-----------------------------------------------------------------------------
BOOL tune_isPad() {
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}
#endif


@implementation TuneDeviceUtils

+ (BOOL)hasBackgroundNotificationEnabled {
#if TESTING
    return YES;
#else
    NSDictionary *infoPlistDict = [[TuneUtils currentBundle] infoDictionary];
    if (infoPlistDict[@"UIBackgroundModes"] != nil) {
        for (NSString *value in infoPlistDict[@"UIBackgroundModes"]) {
            if ([value isEqualToString:@"remote-notification"]) {
                return YES;
            }
        }
    }
    return NO;
#endif
}

// From http://iphonedevsdk.com/discussion/comment/111621/#Comment_111621
+ (NSString *)artisanHardwareIdentifier {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = @(machine);
    free(machine);
    
    return platform;
}

#if !TARGET_OS_WATCH
+ (UIUserInterfaceIdiom)artisanInterfaceIdiom {
    return UI_USER_INTERFACE_IDIOM();
}

+ (NSString *)artisanInterfaceIdiomString {
    switch ([self artisanInterfaceIdiom]) {
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

+ (NSString *)artisanIOSVersionString {
    return [[[UIDevice currentDevice] systemVersion] stringByReplacingOccurrencesOfString:@"." withString:@"_"];
}

#pragma mark -

+ (BOOL)currentDeviceIsIpadSimulator {
    return [[[UIDevice currentDevice] model] isEqualToString:@"iPad Simulator"];
}

+ (BOOL)currentDeviceIsIphoneSimulator {
    return [[[UIDevice currentDevice] model] isEqualToString:@"iPhone Simulator"];
}

+ (BOOL)currentDeviceIsSimulator {
    return ([self currentDeviceIsIphoneSimulator] || [self currentDeviceIsIpadSimulator]);
}

+ (BOOL)currentDeviceIsTestFlight {
    BOOL isTestFlight = NO;
    if ([TuneDeviceDetails appIsRunningIniOS7OrAfter]) {
        BOOL hasEmbeddedMobileProvision = [[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"] != nil;
        BOOL isSandboxReceipt = [[[[NSBundle mainBundle] appStoreReceiptURL] lastPathComponent] isEqualToString:@"sandboxReceipt"];
        isTestFlight = isSandboxReceipt && !hasEmbeddedMobileProvision;
    }
    return isTestFlight;
}

@end
