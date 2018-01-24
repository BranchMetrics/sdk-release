//
//  TuneBannerMessage.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneBannerMessage.h"
#import "TuneDeviceDetails.h"
#import "TuneInAppUtils.h"
#import "TuneMessageOrientationState.h"
#import "TunePointerSet.h"
#import "TuneInAppMessageConstants.h"
#import "TuneBannerMessageView.h"
#import "TuneBannerMessageDefaults.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookConstants.h"

@implementation TuneBannerMessage

+ (TuneBannerMessage *)buildMessageFromMessageDictionary:(NSDictionary *)messageDictionary {
    TuneBannerMessage *messageFactory = [[TuneBannerMessage alloc] initWithMessageDictionary:messageDictionary];
    return messageFactory;
}

- (id)initWithMessageDictionary:(NSDictionary *)messageDictionary {
    self = [super initWithMessageDictionary:messageDictionary];
    
    if (self) {
        NSDictionary *message = (self.messageDictionary)[@"message"];
        
        self.messageLocationType = [TuneInAppUtils getLocationTypeByString:message[@"messageLocationType"]];
        
        self.duration = [TuneInAppUtils getMessageDurationFromDictionary:message];

        self.visibleViews = [[TunePointerSet alloc] init];
    }
    
    return self;
}

- (BOOL)messageDictionaryHasPrerequisites {
    BOOL hasPrerequisites = YES;
    
    NSDictionary *message = (self.messageDictionary)[@"message"];
    
    NSString *messageTypeString = message[@"messageType"];
    NSString *messageLocationString = message[@"messageLocationType"];
    
    if ([messageTypeString length] == 0) {
        ErrorLog(@"Can't find In-App message type");
        hasPrerequisites = NO;
    }
    
    if ([messageLocationString length] == 0) {
        ErrorLog(@"Can't find In-App message location");
        hasPrerequisites = NO;
    }
    
    if (![messageTypeString isEqualToString:@"TuneMessageTypeSlideIn"]) {
        ErrorLog(@"Wrong message type");
        hasPrerequisites = NO;
    }
    
    return hasPrerequisites;
}

- (void)_buildAndShowMessage {
    TuneBannerMessageView *bannerMessageView = [[TuneBannerMessageView alloc] initWithLocationType:self.messageLocationType];

    bannerMessageView.parentMessage = self;
    
    // Message ID
    if (self.messageID) {
        [bannerMessageView setMessageID:self.messageID];
    }
    
    // Campaign Step ID
    if (self.campaignStepID) {
        [bannerMessageView setCampaignStepID:self.campaignStepID];
    }
    
    // Campaign ID
    if (self.campaign) {
        [bannerMessageView setCampaign:self.campaign];
        
        // Record that we saw a campaign id
        [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneCampaignViewed object:nil userInfo:@{TunePayloadCampaign : self.campaign}];
    }
    
    if (self.html) {
        [bannerMessageView setHtml:self.html];
    }
    
    if (self.tuneActions) {
        [bannerMessageView setTuneActions:self.tuneActions];
    }
    
    #if TARGET_OS_IOS
    if (self.webView) {
        [bannerMessageView setWebView:self.webView];
    }
    #endif
    
    // Transition
    if (self.transitionType) {
        [bannerMessageView setTransitionType:self.transitionType];
    }
    
    // duration
    if (self.duration) {
        [bannerMessageView setDuration:self.duration];
    } else {
        [bannerMessageView setDuration:@0];
    }
    
    [bannerMessageView show];
    
    [self.visibleViews addPointer:(__bridge void *)(bannerMessageView)];
}



@end
