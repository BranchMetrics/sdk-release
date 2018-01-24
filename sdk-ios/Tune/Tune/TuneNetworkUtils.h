//
//  TuneNetworkUtils.h
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 9/2/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneReachability.h"

@interface TuneNetworkUtils : NSObject

+ (BOOL)isNetworkReachable;

#if TARGET_OS_IOS
+ (TuneNetworkStatus)networkReachabilityStatus;
#endif

@end
