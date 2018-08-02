//
//  TuneDeviceDetails.m
//  In-App Messaging Test App
//
//  Created by Scott Wasserman on 7/17/14.
//  Copyright (c) 2014 Tune Mobile. All rights reserved.
//

#import "TuneDeviceDetails.h"
#import "TuneUtils.h"

@implementation TuneDeviceDetails

#if !TARGET_OS_WATCH
+ (BOOL)appIsRunningIniOS9OrAfter {
    return [self appIsRunningIniOSVersionOrAfter:9.0];
}

+ (BOOL)appIsRunningIniOS10OrAfter {
    return [self appIsRunningIniOSVersionOrAfter:10.0];
}

+ (BOOL)appIsRunningIniOSVersionOrAfter:(CGFloat)version {
    return [[UIDevice currentDevice].systemVersion floatValue] >= version;
}
#endif

@end
