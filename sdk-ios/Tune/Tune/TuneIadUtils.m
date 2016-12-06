//
//  TuneIadUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 9/30/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import "TuneIadUtils.h"
#import "TuneKeyStrings.h"
#import "TuneManager.h"
#import "TuneUserProfile.h"
#import "TuneUserDefaultsUtils.h"

#if USE_IAD

@implementation TuneIadUtils

+ (BOOL)shouldCheckIadAttribution {
    return [UIApplication sharedApplication] && [ADClient sharedClient]
    && [[TuneManager currentManager].userProfile iadAttribution] == nil
    && [TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_IAD_ATTRIBUTION_CHECKED] == nil;
}

@end

#endif
