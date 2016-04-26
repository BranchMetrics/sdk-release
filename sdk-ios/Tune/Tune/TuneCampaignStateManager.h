//
//  TuneCampaignStateManager.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/11/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneModule.h"

@interface TuneCampaignStateManager : TuneModule {
    NSDictionary *_viewedCampaigns;
    NSArray *_campaignIdsRecordedThisSession;
    NSArray *_variationIdsRecordedThisSession;
}

@end
