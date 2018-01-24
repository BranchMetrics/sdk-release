//
//  TuneInAppMessage.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessage.h"

#import "TuneBannerMessage.h"
#import "TuneFullScreenMessage.h"
#import "TuneModalMessage.h"

#import "TuneDateUtils.h"
#import "TuneStringUtils.h"
#import "TuneInAppUtils.h"
#import "TuneBaseInAppMessageView.h"

@implementation TuneInAppMessage

#pragma mark - Initialization

- (id)initWithMessageDictionary:(NSDictionary *)messageDictionary {
    self = [super init];
    if (self) {
        NSMutableDictionary *cleanDictionary = [NSMutableDictionary dictionary];
        [messageDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            if (value && ![value isKindOfClass:[NSNull class]]) {
                cleanDictionary[key] = value;
            }
        }];
        self.messageDictionary = cleanDictionary;
        self.visible = NO;
        [self parseMessageDetails];
    }
    return self;
}

- (BOOL)shouldDisplayBasedOnFrequencyModel:(TuneMessageDisplayFrequency *)frequencyModel {
    BOOL shouldDisplay = YES;
    
    // Check the dates
    if (![TuneDateUtils date:[NSDate date] isBetweenDate:self.startDate andEndDate:self.endDate]) {
        shouldDisplay = NO;
    }
    // Check lifetime limit
    else if (self.lifetimeMaximum > 0 && frequencyModel.lifetimeShownCount >= self.lifetimeMaximum) {
        shouldDisplay = NO;
    } else {
        // Check display frequency
        switch (self.scope) {
            case TuneMessageFrequencyScopeInstall:
                if (self.limit > 0 && frequencyModel.lifetimeShownCount >= self.limit) {
                    // if it has been seen too many times, then no
                    shouldDisplay = NO;
                }
                break;
            case TuneMessageFrequencyScopeSession:
                if (self.limit > 0 && frequencyModel.numberOfTimesShownThisSession >= self.limit) {
                    // If it has been seen too many times this session, then no
                    shouldDisplay = NO;
                }
                break;
            case TuneMessageFrequencyScopeEvents:
                if (self.limit > 0 && frequencyModel.eventsSeenSinceShown < self.limit) {
                    // If the event hasn't happened enough times since last shown, then now
                    shouldDisplay = NO;
                }
                break;
            case TuneMessageFrequencyScopeDays:
                if (frequencyModel.lastShownDateTime) {
                    int numberOfDaysSinceLastShown = [TuneDateUtils daysBetween:frequencyModel.lastShownDateTime and:[NSDate date]];
                    if (self.limit > 0 && numberOfDaysSinceLastShown < self.limit) {
                        // If it hasn't been enough days since last shown, then no
                        shouldDisplay = NO;
                    }
                }
                break;
        }
    }
    
    return shouldDisplay;
}

+ (TuneInAppMessage *)buildMessageFromMessageDictionary:(NSDictionary *)messageDictionary {
    NSDictionary *message = messageDictionary[@"message"];
    
    if (message) {
        NSString *messageTypeString = message[@"messageType"];
        
        if ([messageTypeString isEqualToString:@"TuneMessageTypeSlideIn"]) {
            return [TuneBannerMessage buildMessageFromMessageDictionary:messageDictionary];
        } else if ([messageTypeString isEqualToString:@"TuneMessageTypePopUp"]) {
            return [TuneModalMessage buildMessageFromMessageDictionary:messageDictionary];
        } else if ([messageTypeString isEqualToString:@"TuneMessageTypeTakeOver"]) {
            return [TuneFullScreenMessage buildMessageFromMessageDictionary:messageDictionary];
        }
    }
    
    return nil;
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
    
    // Trigger event
    NSString *triggerEvent = (self.messageDictionary)[@"triggerEvent"];
    if (triggerEvent) {
        self.triggerEvent = triggerEvent;
    }
    
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
        } @catch (NSException *exception) {
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
        } @catch (NSException *exception) {
            ErrorLog(@"Error parsing message display frequency lifetimeMaximum: %@", exception.description);
            self.lifetimeMaximum = 0;
        }
    }
    
    NSDictionary *message = (self.messageDictionary)[@"message"];
    
    // HTML
    NSString *htmlString = message[@"html"];
    if (htmlString) {
        self.html = htmlString;

        #if TARGET_OS_IOS
        // Create the WebView
        dispatch_async(dispatch_get_main_queue(), ^{
            self.webViewLoaded = NO;
            
            self.webView = [[WKWebView alloc] init];
            self.webView.scrollView.bounces = NO;
            self.webView.scrollView.scrollEnabled = YES;
            self.webView.contentMode = UIViewContentModeCenter;
            self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.webView.hidden = YES;
            self.webView.navigationDelegate = self;
            [self.webView loadHTMLString:self.html baseURL:nil];
        });
        #endif
        
    }
    
    // Tune Actions
    NSDictionary *tuneActionsJson = message[@"actions"];
    
    NSMutableDictionary *tuneActions = [[NSMutableDictionary alloc] init];
    
    if (tuneActions) {
        // Convert actions JSON to NSDictionary of String, TuneMessageAction
        for (id actionName in tuneActionsJson) {
            TuneInAppMessageAction *tuneAction = [[TuneInAppMessageAction alloc] init];
            tuneAction.actionName = actionName;
            
            NSDictionary *actionJson = [tuneActionsJson objectForKey:actionName];
            
            NSString *type = [actionJson objectForKey:@"type"];
            if ([type isEqualToString:@"deeplink"]) {
                tuneAction.type = TuneActionTypeDeeplink;
                tuneAction.url = [actionJson objectForKey:@"link"];
            } else if ([type isEqualToString:@"deepAction"]) {
                tuneAction.type = TuneActionTypeDeepAction;
                tuneAction.deepActionName = [actionJson objectForKey:@"id"];
                tuneAction.deepActionData = [actionJson objectForKey:@"data"];
            } else if ([type isEqualToString:@"close"]) {
                tuneAction.type = TuneActionTypeClose;
            }
            
            [tuneActions setObject:tuneAction forKey:actionName];
        }
        
        self.tuneActions = tuneActions;
    }
    
    if (message[@"transition"]) {
        TuneMessageTransition transition = [TuneInAppUtils getTransitionFromDictionary:message];
        self.transitionType = transition;
    }
}

#pragma mark - Base Methods

- (NSDictionary *)toDictionary {
    return self.messageDictionary;
}

- (void)display {
    if ([self messageDictionaryHasPrerequisites]) {
        @try {
            self.visible = YES;
            [self _buildAndShowMessage];
        } @catch (NSException *exception) {
            ErrorLog(@"Error trying to show Tune In-App Message %@", exception.description);
        }
    }
}

- (void)dismiss {
    if (self.visibleViews.count == 0) { return; }
    for (id object in [self.visibleViews allObjects]) {
        TuneBaseInAppMessageView *view = (TuneBaseInAppMessageView *)object;
        if (view) {
            [view dismissAndWait];
        }
    }
    self.visible = NO;
    self.visibleViews = [[TunePointerSet alloc] init];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (BOOL)messageDictionaryHasPrerequisites {
    [NSException raise:@"Missing Base Message Factory Method" format:@"messageDictionaryHasPrerequisites"];
    return NO;
}

- (void)_buildAndShowMessage {
    [NSException raise:@"Missing Base Message Factory Method" format:@"_buildAndShowMessage"];
}

#pragma mark - WKNavigationDelegate Methods

#if TARGET_OS_IOS
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.webViewLoaded = YES;
}
#endif

@end
