//
//  TuneBaseMessageFactory.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneBaseMessageFactory.h"
#import "TuneDateUtils.h"
#import "TuneStringUtils.h"
#import "TuneInAppUtils.h"
#import "TuneBaseInAppMessageView.h"

@implementation TuneBaseMessageFactory

#pragma mark - Initialization

- (id)initWithMessageDictionary:(NSDictionary *)messageDictionary {
    
    if (self) {
        NSMutableDictionary *cleanDictionary = [NSMutableDictionary dictionary];
        [messageDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            if (value && ![value isKindOfClass:[NSNull class]]) {
                cleanDictionary[key] = value;
            }
        }];
        self.messageDictionary = cleanDictionary;
        [self parseMessageDetails];
    }
    return self;
}

- (BOOL)shouldDisplayBasedOnFrequencyModel:(TuneMessageDisplayFrequency *)frequencyModel {
    // Check the dates
    NSDate *now = [NSDate date];
    if (![TuneDateUtils date:now isBetweenDate:self.startDate andEndDate:self.endDate]) {
        return NO;
    }
    
    // Check lifetime limit
    if (self.lifetimeMaximum > 0 && frequencyModel.lifetimeShownCount >= self.lifetimeMaximum) {
        return NO;
    }
    
    // Check display frequency
    switch (self.scope) {
        case TuneMessageFrequencyScopeInstall:
            if (self.limit > 0 && frequencyModel.lifetimeShownCount >= self.limit) {
                // if it has been seen too many times, then no
                return NO;
            }
            break;
        case TuneMessageFrequencyScopeSession:
            if (self.limit > 0 && frequencyModel.numberOfTimesShownThisSession >= self.limit) {
                // If it has been seen too many times this session, then no
                return NO;
            }
            break;
        case TuneMessageFrequencyScopeEvents:
            if (self.limit > 0 && frequencyModel.eventsSeenSinceShown < self.limit) {
                // If the event hasn't happened enough times since last shown, then now
                return NO;
            }
            break;
        case TuneMessageFrequencyScopeDays:
            if (frequencyModel.lastShownDateTime) {
                int numberOfDaysSinceLastShown = [TuneDateUtils daysBetween:frequencyModel.lastShownDateTime and:[NSDate date]];
                if (self.limit > 0 && numberOfDaysSinceLastShown < self.limit) {
                    // If it hasn't been enough days since last shown, then no
                    return NO;
                }
            }
            break;
    }
    
    return YES;
}


- (void)parseMessageDetails {
    // Message ID
    NSString *messageID = (self.messageDictionary)[@"messageID"];
    if (messageID) {
        self.messageID = messageID;
    }
    
    // Campaign Step ID
    NSString *campaignStepID = (self.messageDictionary)[@"campaignStepID"];
    if (campaignStepID) {
        self.campaignStepID = campaignStepID;
    }
    
    // campaign
    NSString *campaignId = [TuneCampaign parseCampaignIdFromPlaylistDictionary:self.messageDictionary];
    NSNumber *numberOfSecondsToReportAnalytics = [TuneCampaign parseNumberOfSecondsToReportAnalyticsFromPlaylistDictionary:self.messageDictionary];
    self.campaign = [[TuneCampaign alloc] initWithCampaignId:campaignId
                                                      variationId:messageID
                              andNumberOfSecondsToReportAnalytics:numberOfSecondsToReportAnalytics];
    
    // startDate
    NSString *startDateString = (self.messageDictionary)[@"startDate"];
    if (![startDateString isEqual:[NSNull null]] && startDateString) {
        self.startDate = [[TuneDateUtils dateFormatterIso8601] dateFromString:startDateString];
    }
    
    // endDate
    NSString *endDateString = (self.messageDictionary)[@"endDate"];
    if (![endDateString isEqual:[NSNull null]] &&  endDateString) {
        self.endDate = [[TuneDateUtils dateFormatterIso8601] dateFromString:endDateString];
    }
    
    NSDictionary *displayFrequency = (self.messageDictionary)[@"displayFrequency"];
    
    // limit
    NSString *limitString = displayFrequency[@"limit"];
    if (![limitString isEqual:[NSNull null]] && limitString) {
        @try {
            self.limit = [limitString intValue];
        }
        @catch (NSException *exception) {
            ErrorLog(@"Error parsing message display frequency limit: %@", exception.description);
            self.limit = 0;
        }
    }
    
    // scope
    NSString *scopeString = displayFrequency[@"scope"];
    if (![scopeString isEqual:[NSNull null]] && scopeString) {
        if ([scopeString isEqualToString:@"INSTALL"]) {
            self.scope = TuneMessageFrequencyScopeInstall;
        } else if ([scopeString isEqualToString:@"SESSION"]) {
            self.scope = TuneMessageFrequencyScopeSession;
        } else if ([scopeString isEqualToString:@"DAYS"]) {
            self.scope = TuneMessageFrequencyScopeDays;
        } else if ([scopeString isEqualToString:@"EVENTS"]) {
            self.scope = TuneMessageFrequencyScopeEvents;
        } else {
            ErrorLog(@"Error parsing message display frequency scope. Unknown type: %@", scopeString);
            self.scope = TuneMessageFrequencyScopeInstall;
        }
    }
    
    // lifetimeMaximum
    NSString *lifetimeMaximumString = displayFrequency[@"lifetimeMaximum"];
    if (![lifetimeMaximumString isEqual:[NSNull null]] && lifetimeMaximumString) {
        @try {
            self.lifetimeMaximum = [lifetimeMaximumString intValue];
        }
        @catch (NSException *exception) {
            ErrorLog(@"Error parsing message display frequency lifetimeMaximum: %@", exception.description);
            self.lifetimeMaximum = 0;
        }
    }
}

#pragma mark - Base Methods

- (void)addImageURLForProperty:(NSString *)property inMessageDictionary:(NSDictionary *)message {
    NSDictionary *imageDictionary = message[property];
    if (imageDictionary != nil) {
        NSString *imageUrl = [TuneInAppUtils getScreenAppropriateValueFromDictionary:imageDictionary];
        if (imageUrl != nil) {
            [self.images setValue:@NO forKey:imageUrl];
        }
    }
}

- (NSString *)getMessageID {
    return self.messageID;
}

- (NSString *)getCampaignStepID {
    return self.campaignStepID;
}

- (NSDictionary *)toDictionary {
    return self.messageDictionary;
}

- (void)acquireImagesWithDispatchGroup:(dispatch_group_t)group {
    __block NSMutableDictionary *_imageDictionary = self.images;
    [TuneInAppUtils downloadImages:_imageDictionary withDispatchGroup:group];
}

- (BOOL)hasAllAssets {
    BOOL hasAllAssets = YES;
    for (NSNumber *result in self.images.allValues) {
        hasAllAssets &= [result boolValue];
    }
    return hasAllAssets;
}

- (void)buildAndShowMessage {
    if ([self messageDictionaryHasPrerequisites]) {

        @try{
            [self _buildAndShowMessage];
        } @catch (NSException *exception) {
            ErrorLog(@"Error trying to show Tune In-App Message %@", exception.description);
        }
    }
}

- (void)dismissMessage {
    if (self.visibleViews.count == 0) { return; }
    for (id object in [self.visibleViews allObjects]) {
        TuneBaseInAppMessageView *view = (TuneBaseInAppMessageView *)object;
        if (view) {
            [view dismissAndWait];
        }
    }
    self.visibleViews = [[TunePointerSet alloc] init];
}

- (NSString *)getTriggerEvent {
    NSString *triggerEvent = nil;
    if (self.messageDictionary != nil) {
        triggerEvent = (self.messageDictionary)[@"triggerEvent"];
    }
    return triggerEvent;
}

- (BOOL)messageDictionaryHasPrerequisites {
    [NSException raise:@"Missing Base Message Factory Method" format:@"messageDictionaryHasPrerequisites"];
    return NO;
}

- (void)_buildAndShowMessage {
    [NSException raise:@"Missing Base Message Factory Method" format:@"_buildAndShowMessage"];
}

@end
