//
//  TuneCampaign.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneCampaign.h"
#import "TuneAnalyticsConstants.h"

@implementation TuneCampaign

#pragma mark - Initialization

- (id)initWithCampaignId:(NSString *)campaignId
             variationId:(NSString *)variationId
andNumberOfSecondsToReportAnalytics:(NSNumber*)numberOfSecondsToReportAnalytics {
    
    if ((campaignId) && (variationId) &&
        (numberOfSecondsToReportAnalytics) &&
        ([numberOfSecondsToReportAnalytics intValue] > 0) ) {
        self = [super init];
        if (self) {
            self.campaignId = campaignId;
            self.variationId = variationId;
            self.numberOfSecondsToReportAnalytics = numberOfSecondsToReportAnalytics;
        }
        return self;
    } else {
        return nil;
    }
}

- (id)initWithNotificationUserInfo:(NSDictionary *)userInfo {
    self = [super init];
    if (self) {
        
        // Look for campaign info
        NSString *tunePushId = @"";
        NSString *campaignId = @"";
        
        // Find Tune Push ID if present
        if (userInfo[TUNE_PUSH_NOTIFICATION_ID]) {
            tunePushId = userInfo[TUNE_PUSH_NOTIFICATION_ID];
            self.variationId = tunePushId;
        }
        
        // Find Tune Campaign ID if present
        campaignId = [TuneCampaign parseCampaignIdFromNotificationDictionary:userInfo];
        
        if (campaignId) {
            NSNumber *numberOfSecondsToReportAnalytics = [TuneCampaign parseNumberOfSecondsToReportAnalyticsFromNotificationDictionary:userInfo];
            
            return [[TuneCampaign alloc] initWithCampaignId:campaignId
                                                variationId:tunePushId
                        andNumberOfSecondsToReportAnalytics:numberOfSecondsToReportAnalytics];
        }
        else {
            return self;
        }
    }
    else {
        return nil;
    }
}

#pragma mark - Dictionary Parsing

+ (NSString *)parseCampaignIdFromPlaylistDictionary:(NSDictionary *)dictionary {
    return [self parseCampaignIdFromDictionary:dictionary withKey:@"campaignID"];
}

+ (NSNumber *)parseNumberOfSecondsToReportAnalyticsFromPlaylistDictionary:(NSDictionary *)dictionary {
    return [self parseNumberOfSecondsToReportAnalyticsFromDictionary:dictionary withKey:@"lengthOfTimeToReport"];
}

+ (NSString *)parseCampaignIdFromNotificationDictionary:(NSDictionary *)dictionary {
    return [self parseCampaignIdFromDictionary:dictionary withKey:TUNE_CAMPAIGN_IDENTIFIER];
}

+ (NSNumber *)parseNumberOfSecondsToReportAnalyticsFromNotificationDictionary:(NSDictionary *)dictionary {
    return [self parseNumberOfSecondsToReportAnalyticsFromDictionary:dictionary withKey:@"LENGTH_TO_REPORT"];
}

+ (NSString *)parseCampaignIdFromDictionary:(NSDictionary *)dictionary withKey:(NSString *)key {
    NSString *campaignId = nil;
    
    if (dictionary[key]) {
        campaignId = dictionary[key];
    }
    
    return campaignId;
}

+ (NSNumber *)parseNumberOfSecondsToReportAnalyticsFromDictionary:(NSDictionary *)dictionary withKey:(NSString *)key {
    NSNumber *numberOfSecondsToReportAnalytics = @0;
    
    if (dictionary[key]) {
        @try {
            NSString *numberOfSecondsToReportAnalyticsString = dictionary[key];
            numberOfSecondsToReportAnalytics = @([numberOfSecondsToReportAnalyticsString integerValue]);
        } @catch (NSException *exception) {
            ErrorLog(@"Parsing lengthOfTimeToReport failed: %@", exception.description);
        }
    }
    
    return numberOfSecondsToReportAnalytics;
}

- (BOOL)isTest {
    return [self.variationId isEqualToString:@"TEST_MESSAGE"];
}

#pragma mark - toDictionary

- (NSDictionary *)toDictionary {
    NSMutableDictionary *campaignDictionary = [[NSMutableDictionary alloc] init];
    @try {
        if (self.campaignId) {
            campaignDictionary[TUNE_ANALYTICS_CAMPAIGN_IDENTIFIER] = self.campaignId;
        }
        
        if (self.variationId) {
            campaignDictionary[TUNE_CAMPAIGN_VARIATION_IDENTIFIER] = self.variationId;
        }
    } @catch (NSException *exception) {
        ErrorLog(@"%@",exception);
    }
    return [NSDictionary dictionaryWithDictionary:campaignDictionary];
}

#pragma mark - Reporting Analytics

- (void)calculateTimestampToStopReportingAnalytics {
    if (self.numberOfSecondsToReportAnalytics && self.lastViewed) {
        _timestampToStopReportingAnalytics = [self.lastViewed dateByAddingTimeInterval:[self.numberOfSecondsToReportAnalytics integerValue]];
    }
}

- (void)markCampaignViewed {
    self.lastViewed = [NSDate date];
    [self calculateTimestampToStopReportingAnalytics];
}

- (BOOL)needToReportCampaignAnalytics {
    // is _timestampToStopReportingAnalytics in the past?
    return _timestampToStopReportingAnalytics && [_timestampToStopReportingAnalytics timeIntervalSinceDate:[NSDate date]] > 0;
}

#pragma mark - NSCoding

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.campaignId forKey:@"campaignId"];
    [encoder encodeObject:self.campaignSource forKey:@"campaignSource"];
    [encoder encodeObject:self.variationId forKey:@"variationId"];
    [encoder encodeObject:self.lastViewed forKey:@"lastViewed"];
    [encoder encodeObject:self.numberOfSecondsToReportAnalytics forKey:@"numberOfSecondsToReportAnalytics"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        self.campaignId = [decoder decodeObjectForKey:@"campaignId"];
        self.campaignSource = [decoder decodeObjectForKey:@"campaignSource"];
        self.variationId = [decoder decodeObjectForKey:@"variationId"];
        self.lastViewed = [decoder decodeObjectForKey:@"lastViewed"];
        self.numberOfSecondsToReportAnalytics = [decoder decodeObjectForKey:@"numberOfSecondsToReportAnalytics"];
        [self calculateTimestampToStopReportingAnalytics];
    }
    return self;
}

@end
