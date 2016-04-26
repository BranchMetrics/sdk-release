//
//  TuneSwizzleBlacklist.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/26/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneModule.h"

@interface TuneSwizzleBlacklist : NSObject {
    NSSet *_blackList;
}

+ (TuneSwizzleBlacklist *)sharedBlacklist;

+ (void)reset;
+ (BOOL)classIsOnBlackList:(NSString *)className;

@end
