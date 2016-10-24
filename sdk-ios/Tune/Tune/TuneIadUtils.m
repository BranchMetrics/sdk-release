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

+ (BOOL)isFakeIadAttribution:(NSDictionary *)dict {
    return [(NSString *)dict[@"iad-campaign-id"] isEqualToString:TUNE_FAKE_IAD_CAMPAIGN_ID]
    || [(NSString *)dict[@"iad-lineitem-id"] isEqualToString:TUNE_FAKE_IAD_CAMPAIGN_ID]
    || [(NSString *)dict[@"iad-creative-id"] isEqualToString:TUNE_FAKE_IAD_CAMPAIGN_ID];
}

@end


#endif
