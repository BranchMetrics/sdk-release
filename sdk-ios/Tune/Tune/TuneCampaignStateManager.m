//
//  TuneCampaignStateManager.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/11/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneCampaignStateManager.h"
#import "TuneSkyhookCenter.h"
#import "TuneStorageKeys.h"
#import "TuneCampaign.h"
#import "TuneAnalyticsConstants.h"
#import "TuneUserDefaultsUtils.h"

@implementation TuneCampaignStateManager

- (id)initWithTuneManager:(TuneManager *)tuneManager {
    self = [super initWithTuneManager:tuneManager];
    
    if (self) {
        _viewedCampaigns = [[NSDictionary alloc] init];
        _campaignIdsRecordedThisSession = [[NSArray alloc] init];
        _variationIdsRecordedThisSession = [[NSArray alloc] init];
        [self retrieveViewedCampaigns];
        [self campaignHousekeeping];
    }
    
    return self;
}

-(void)bringUp {
    [self registerSkyhooks];
    [self handleSessionStarted:nil];
}

-(void)bringDown {
    [self unregisterSkyhooks];
}

#pragma mark - Skyhook registration

- (void)registerSkyhooks {
    [self unregisterSkyhooks];
    
    // Listen for session started
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleSessionStarted:)
                                              name:TuneSessionManagerSessionDidStart
                                            object:nil
                                          priority:TuneSkyhookPriorityFirst];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleCampaignViewed:)
                                              name:TuneCampaignViewed
                                            object:nil];
}

#pragma mark - Campaign state

- (void)handleCampaignViewed:(TuneSkyhookPayload *)payload {
    TuneCampaign *campaign = (TuneCampaign *)[payload userInfo][TunePayloadCampaign];
    
    if ( (campaign) && (campaign.campaignId) && ([campaign.campaignId length] > 0) && (campaign.variationId) && ([campaign.variationId length] > 0) ) {
        // If it is a test campaign don't bother tracking it.
        if ([campaign isTest]) {
            return;
        }
        
        [campaign markCampaignViewed];
        if (!_viewedCampaigns[campaign.variationId]) {
            [self addViewedCampaignIdToSession:campaign.campaignId];
            [self addViewedVariationIdToSession:campaign.variationId];
        }
        
        // This will overwrite the existing campaign information under the same variation id (it could have been updated)
        NSMutableDictionary *updatedViewedCampaigns = _viewedCampaigns.mutableCopy;
        updatedViewedCampaigns[campaign.variationId] = campaign;
        _viewedCampaigns = [NSDictionary dictionaryWithDictionary:updatedViewedCampaigns];
    }
    
    [self storeViewedCampaigns];
}

- (void)campaignHousekeeping {
    BOOL needToStoreChanges = NO;
    
    for (NSString *variationId in [_viewedCampaigns allKeys]) {
        TuneCampaign *campaign = _viewedCampaigns[variationId];
        
        if (![campaign needToReportCampaignAnalytics]) {
            NSMutableDictionary *updatedViewedCampaigns = _viewedCampaigns.mutableCopy;
            [updatedViewedCampaigns removeObjectForKey:variationId];
            _viewedCampaigns = [NSDictionary dictionaryWithDictionary:updatedViewedCampaigns];
            needToStoreChanges = YES;
        }
    }
    
    if (needToStoreChanges) {
        // Persist udpates
        [self storeViewedCampaigns];
    }
}

#pragma mark - Session tracking
- (void)handleSessionStarted:(TuneSkyhookPayload *)payload {
    _campaignIdsRecordedThisSession = [[NSArray alloc] init];
    _variationIdsRecordedThisSession = [[NSArray alloc] init];
    [self campaignHousekeeping];
    [self addViewedCampaignIdsToSession];
    [self addViewedVariationIdsToSession];
}

- (void)addViewedCampaignIdsToSession {
    for (NSString *variationId in [_viewedCampaigns allKeys]) {
        TuneCampaign *campaign = _viewedCampaigns[variationId];
        
        // Don't record the campaign id if it's already in the session
        // This can happen if you've seen multiple steps of a campaign or received multiple variations in a campaign
        if (![_campaignIdsRecordedThisSession containsObject:campaign.campaignId]) {
            [self addViewedCampaignIdToSession:campaign.campaignId];
            NSMutableArray *updatedRecordedThisSession = _campaignIdsRecordedThisSession.mutableCopy;
            [updatedRecordedThisSession addObject:campaign.campaignId];
            _campaignIdsRecordedThisSession = [NSMutableArray arrayWithArray:updatedRecordedThisSession];
        }
    }
}

- (void)addViewedCampaignIdToSession:(NSString *)campaignId {
    [self queueProfileVariable:TUNE_ANALYTICS_CAMPAIGN_IDENTIFIER withValue:campaignId];
}

- (void)addViewedVariationIdsToSession {
    for (NSString *variationId in [_viewedCampaigns allKeys]) {
        
        // Don't record the variation id if it's already in the session
        // This can happen if you've seen multiple steps of a campaign or received multiple variations in a campaign
        if (![_variationIdsRecordedThisSession containsObject:variationId]) {
            [self addViewedVariationIdToSession:variationId];
            NSMutableArray *updatedRecordedThisSession = _variationIdsRecordedThisSession.mutableCopy;
            [updatedRecordedThisSession addObject:variationId];
            _variationIdsRecordedThisSession = [NSMutableArray arrayWithArray:updatedRecordedThisSession];
        }
    }
}

- (void)addViewedVariationIdToSession:(NSString *)variationId {
    [self queueProfileVariable:TUNE_CAMPAIGN_VARIATION_IDENTIFIER withValue:variationId];
}

- (void)queueProfileVariable:(NSString *)variableName withValue:(NSString *)variableValue {
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionVariableToSet
                                            object:nil
                                          userInfo:@{TunePayloadSessionVariableName:variableName,
                                                     TunePayloadSessionVariableValue:variableValue,
                                                     TunePayloadSessionVariableSaveType:TunePayloadSessionVariableSaveTypeProfile }];
}

#pragma mark - Campaign ID storage
- (void)storeViewedCampaigns {
    NSData *archivedViewedCampaigns = [NSKeyedArchiver archivedDataWithRootObject:_viewedCampaigns];
    [TuneUserDefaultsUtils setUserDefaultValue:archivedViewedCampaigns forKey:TuneViewedCampaignsKey];
}

- (void)retrieveViewedCampaigns {
    NSData *archivedViewedCampaigns = [TuneUserDefaultsUtils userDefaultValueforKey:TuneViewedCampaignsKey];
    if ([archivedViewedCampaigns length] > 0) {
        _viewedCampaigns = [NSKeyedUnarchiver unarchiveObjectWithData:archivedViewedCampaigns];
    }
    else {
        _viewedCampaigns = [[NSDictionary alloc] init];
    }
}

@end
