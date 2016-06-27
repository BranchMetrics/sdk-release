//
//  TuneDeeplink.m
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 9/15/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneDeeplink.h"
#import "TuneAnalyticsConstants.h"
#import "TuneDeepLinkConstants.h"
#import "TuneDeviceDetails.h"
#import "TuneManager.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookConstants.h"
#import "TuneSkyhookPayloadConstants.h"
#import "TuneStringUtils.h"
#import "TuneUserProfile.h"

@implementation TuneDeeplink


- (id)initWithNSURL:(NSURL *)url {
    self = [super init];
    if(self) {
        self.url = url;
        self.action = nil;
        self.campaign = nil;
        self.eventParameters = [[NSMutableDictionary alloc] init];
        [self parseURL];
    }
    return self;
}

#pragma mark - EventType

- (void)determineEventType {
    // Figure out deep link eventType
    if ([self.campaign.campaignSource length] > 0) {
        if ([self.campaign.campaignSource isEqualToString:TuneDeeplinkSourceEmail]) {
            self.eventType = TUNE_EVENT_TYPE_APP_OPENED_BY_URL_FROM_EMAIL;
        } else if ([self.campaign.campaignSource isEqualToString:TuneDeeplinkSourceWeb]) {
            self.eventType = TUNE_EVENT_TYPE_APP_OPENED_BY_URL_FROM_WEB;
        } else if ([self.campaign.campaignSource isEqualToString:TuneDeeplinkSourceSMS]) {
            self.eventType = TUNE_EVENT_TYPE_APP_OPENED_BY_URL_FROM_SMS;
        } else if ([self.campaign.campaignSource isEqualToString:TuneDeeplinkSourceApp]) {
            self.eventType = TUNE_EVENT_TYPE_APP_OPENED_BY_URL_FROM_APP;
        } else if ([self.campaign.campaignSource isEqualToString:TuneDeeplinkSourceAd]) {
            self.eventType = TUNE_EVENT_TYPE_APP_OPENED_BY_URL_FROM_AD;
        } else if ([self.campaign.campaignSource isEqualToString:TuneDeeplinkTodayExtension]) {
            self.eventType = TUNE_EVENT_TYPE_APP_OPENED_BY_URL_FROM_TODAY_EXTENSION;
        } else {
            self.eventType = TUNE_EVENT_TYPE_APP_OPENED_BY_URL;
        }
    } else {
        self.eventType = TUNE_EVENT_TYPE_APP_OPENED_BY_URL;
    }
}

#pragma mark - EventParameters

- (void)parseEventParameters {
    // All the remaining stuff in _parameterDictionary is an event parameter
    for (NSString *key in [_parameterDictionary allKeys]) {
        NSString *value = [self checkForKeyInParameterDictionaryThenRemove:key];
        if ([value length] > 0) {
            [self.eventParameters setValue:value forKey:key];
        }
    }
}

#pragma mark - Parsing logic

- (void)parseURL {
    @try {
        [self buildParameterDictionary];
        
        // Look for a powerhook action
        [self parseDeepAction];
        
        // Look for campaign info
        [self parseCampaign];
        
        // Look for categories
        [self parseCategoryInfo];
        
        // Look for event parameters
        [self parseEventParameters];
        
        // Figure out event type
        [self determineEventType];
    } @catch (NSException *exception) {
        ErrorLog(@"Failed to parse deep link %@", exception.description);
    }
}

- (NSString *)checkForKeyInParameterDictionaryThenRemove:(NSString *)key {
    NSString *value = @"";
    
    if (_parameterDictionary[key]) {
        value = _parameterDictionary[key];
        [_parameterDictionary removeObjectForKey:key];
    }
    
    return value;
}

- (void)parseCampaign {
    // Base campaign info
    NSString *artisanCampaignId = [self checkForKeyInParameterDictionaryThenRemove:TuneDeeplinkArtisanCampaignIDKey];
    NSString *variationId = [self checkForKeyInParameterDictionaryThenRemove:TuneDeeplinkVariationIDKey];
    NSString *timeToReportAnalyticsString = [self checkForKeyInParameterDictionaryThenRemove:TuneDeeplinkTimeToReportAnalyticsKey];
    NSNumber *timeToReportAnalyticsDefault = @(7*60*60*24);
    NSNumber *timeToReportAnalytics;
    if ([timeToReportAnalyticsString length] == 0) {
        timeToReportAnalytics = timeToReportAnalyticsDefault;
    } else {
        @try {
            timeToReportAnalytics = @([timeToReportAnalyticsString intValue]);
        } @catch (NSException *exception) {
            ErrorLog(@"Unable to process time to report analytics defaulting to 7 days: %@", exception.description);
            timeToReportAnalytics = timeToReportAnalyticsDefault;
        }
    }
    
    TuneCampaign *campaign = [[TuneCampaign alloc] initWithCampaignId:artisanCampaignId
                                                          variationId:variationId
                                  andNumberOfSecondsToReportAnalytics:timeToReportAnalytics];
    
    // Source
    NSString *source = [self checkForKeyInParameterDictionaryThenRemove:TuneDeeplinkSourceKey];
    if ([source length] > 0) {
        campaign.campaignSource = source;
    } else {
        campaign.campaignSource = TuneDeeplinkSourceUnknown;
    }
    
    self.campaign = campaign;
}

- (void)parseCategoryInfo {
    NSString *category = [self checkForKeyInParameterDictionaryThenRemove:TuneDeeplinkCategoryKey];
    if ([category length] > 0) {
        [self.eventParameters setValue:category forKey:TUNE_CATEGORY_PARAMETER];
    }
}

- (void)parseDeepAction {
    @try {
        if (_parameterDictionary[TuneDeeplinkDeepActionNameKey]) {
            NSString *deepActionName = _parameterDictionary[TuneDeeplinkDeepActionNameKey];
            [_parameterDictionary removeObjectForKey:TuneDeeplinkDeepActionNameKey];
            
            // Look for parameters
            NSMutableDictionary *deepActionData = [[NSMutableDictionary alloc] init];
            for (NSString *key in [_parameterDictionary allKeys]) {
                NSString *value = _parameterDictionary[key];
                
                if ([key hasPrefix:TuneDeeplinkDeepActionDataKey]) {
                    [_parameterDictionary removeObjectForKey:key];
                    NSString *deepActionDataKey = [key stringByReplacingOccurrencesOfString:TuneDeeplinkDeepActionDataKey withString:@""];
                    deepActionData[deepActionDataKey] = value;
                }
            }
            
            if ([deepActionName length] > 0) {
                self.action = [[TuneMessageAction alloc] init];
                self.action.deepActionName = deepActionName;
                self.action.deepActionData = deepActionData;
            }
        }
    } @catch (NSException *exception) {
        ErrorLog(@"An exception occured while processing a url-based artisan action: %@",exception.description);
    }
}

#pragma mark - Create ParameterDictionary

- (void)buildParameterDictionary {
    NSString *resourceSpecifier = [self.url resourceSpecifier];
    
    NSArray *resourceSpecifierSplit = [resourceSpecifier componentsSeparatedByString:@"?"];
    _parameterDictionary = [[NSMutableDictionary alloc] init];
    
    if ([resourceSpecifierSplit count] > 1 && resourceSpecifier) {
        // We have some parameters
        NSString *rawParametersString = [resourceSpecifierSplit lastObject];
        if ([rawParametersString length] > 0 && rawParametersString) {
            // Looks for campaign info in parameters
            NSArray *splitParameterBlocks = [rawParametersString componentsSeparatedByString:@"&"];
            
            for (NSString *keyValuePair in splitParameterBlocks) {
                NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
                // Make sure that there is a "="-separated key-value pair before reading
                if ([pairComponents count] > 1) {
                    NSString *key = pairComponents[0];
                    
                    NSString *value = pairComponents[1];
                    value = [TuneStringUtils removePercentEncoding:value];
                    value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
                    
                    [_parameterDictionary setValue:value forKey:key];
                }
            }
        }
    }
}

#pragma mark - Skyhooks

- (void)processAnalytics {
    // report on app open
    [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneAppOpenedFromURL object:nil userInfo:@{TunePayloadDeeplink:self}];
    
    if (self.campaign) {
        // send campaign info to campaign
        [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneCampaignViewed object:self userInfo:@{TunePayloadCampaign:self.campaign}];
    }
}

- (void)executeAction {
    if (self.action) {
        // send a queued deep action to execute
        NSDictionary *payload = @{TunePayloadDeepActionId : self.action.deepActionName,
                                  TunePayloadDeepActionData : self.action.deepActionData};
        [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneDeepActionTriggered object:nil userInfo:payload];
    }
}

#pragma mark - Static processing of deep links

+ (void)processDeeplinkURL:(NSURL *)url {
    TuneDeeplink *deeplink = [[TuneDeeplink alloc] initWithNSURL:url];

    [deeplink processAnalytics];
    [deeplink executeAction];
}

@end
