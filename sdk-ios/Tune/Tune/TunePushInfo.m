//
//  TunePushInfo.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 6/9/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import "TunePushInfo+Internal.h"

#import "TuneNotification.h"

@implementation TunePushInfo

- (instancetype)initWithNotification:(TuneNotification *)tuneNotification {
    self = [self init];
    
    if (self) {
        self.campaignId = tuneNotification.campaign.campaignId;
        self.pushId = tuneNotification.campaign.variationId;
        NSMutableDictionary *userInfo = [tuneNotification.userInfo mutableCopy];
        [userInfo removeObjectForKey:@"ANA"];
        [userInfo removeObjectForKey:@"ARTPID"];
        [userInfo removeObjectForKey:@"CAMPAIGN_ID"];
        [userInfo removeObjectForKey:@"LENGTH_TO_REPORT"];
        [userInfo removeObjectForKey:@"aps"];
        self.extrasPayload = [userInfo copy];
    }
    return self;
}


@end
