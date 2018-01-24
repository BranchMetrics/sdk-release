//
//  TuneNetworkUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 9/2/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import "TuneNetworkUtils.h"

TuneReachability *reachability;

@implementation TuneNetworkUtils

+(void)initialize {
    #if TARGET_OS_IOS
    reachability = [TuneReachability reachabilityForInternetConnection];
    [reachability startNotifier];
    #endif
}

#if TARGET_OS_IOS
+ (TuneNetworkStatus)networkReachabilityStatus {
    return [reachability currentReachabilityStatus];
}
#endif

+ (BOOL)isNetworkReachable {
    BOOL reachable =
    #if !TARGET_OS_IOS
    YES;
    #else
    TuneNotReachable != [self networkReachabilityStatus];
    #endif
    DebugLog(@"TuneNetworkUtils: isNetworkReachable: status = %d", reachable);
    
    return reachable;
}

@end
