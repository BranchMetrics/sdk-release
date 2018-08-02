//
//  TuneNetworkUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 9/2/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import "TuneNetworkUtils.h"


@implementation TuneNetworkUtils

#if TARGET_OS_IOS
+ (TuneNetworkStatus)networkReachabilityStatus {
    return [[TuneReachability sharedInstance] currentReachabilityStatus];
}
#endif

+ (BOOL)isNetworkReachable {
    BOOL reachable = YES;
    
    #if TARGET_OS_IOS
    reachable = TuneNotReachable != [self networkReachabilityStatus];
    #endif
    
    return reachable;
}

@end
