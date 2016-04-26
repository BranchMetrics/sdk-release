//
//  TuneMessageDisplayFrequency.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneMessageDisplayFrequency : NSObject

@property (nonatomic, copy) NSString *campaignID;
@property (nonatomic, copy) NSString *eventMD5;
@property (strong, nonatomic) NSDate *lastShownDateTime;
@property (nonatomic) int lifetimeShownCount;
@property (nonatomic) int eventsSeenSinceShown;
@property (nonatomic) int numberOfTimesShownThisSession;

- (id)initWithCampaignID:(NSString *)campaignID eventMD5:(NSString *)eventMD5;

- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;

@end
