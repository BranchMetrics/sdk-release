//
//  TuneCampaign.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneCampaign : NSObject {
    NSDate *_timestampToStopReportingAnalytics;
}

@property (nonatomic, copy) NSString *campaignId;
@property (nonatomic, copy) NSString *campaignSource;
@property (nonatomic, copy) NSString *variationId;
@property (strong, nonatomic) NSDate *lastViewed;
@property (strong, nonatomic) NSNumber *numberOfSecondsToReportAnalytics;

- (id)initWithCampaignId:(NSString *)campaignId
             variationId:(NSString *)variationId
andNumberOfSecondsToReportAnalytics:(NSNumber*)numberOfSecondsToReportAnalytics;

- (id)initWithNotificationUserInfo:(NSDictionary *)userInfo;

- (void)markCampaignViewed;
- (BOOL)needToReportCampaignAnalytics;

- (BOOL)isTest;

- (NSDictionary *)toDictionary;

+ (NSString *)parseCampaignIdFromPlaylistDictionary:(NSDictionary *)dictionary;
+ (NSNumber *)parseNumberOfSecondsToReportAnalyticsFromPlaylistDictionary:(NSDictionary *)dictionary;

+ (NSString *)parseCampaignIdFromNotificationDictionary:(NSDictionary *)dictionary;
+ (NSNumber *)parseNumberOfSecondsToReportAnalyticsFromNotificationDictionary:(NSDictionary *)dictionary;

@end
