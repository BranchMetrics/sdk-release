//
//  TuneFullScreenMessage.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/8/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneFullScreenMessage.h"
#import "TuneFullScreenMessageDefaults.h"
#import "TuneFullScreenMessageView.h"
#import "TuneDeviceDetails.h"
#import "TunePointerSet.h"
#import "TuneSkyhookCenter.h"
#import "TuneInAppUtils.h"
#import "TuneInAppMessageConstants.h"

@implementation TuneFullScreenMessage

+ (TuneFullScreenMessage *)buildMessageFromMessageDictionary:(NSDictionary *)messageDictionary {
    TuneFullScreenMessage *messageFactory = [[TuneFullScreenMessage alloc] initWithMessageDictionary:messageDictionary];
    return messageFactory;
}

- (id)initWithMessageDictionary:(NSDictionary *)messageDictionary {
    
    self = [super initWithMessageDictionary:messageDictionary];
    
    if (self) {
        self.visibleViews = [[TunePointerSet alloc] init];
    }
    
    return self;
}

- (BOOL)messageDictionaryHasPrerequisites {
    BOOL hasPrerequisites = YES;
    
    NSDictionary *message = (self.messageDictionary)[@"message"];
    
    NSString *messageTypeString = message[@"messageType"];
    
    if ([messageTypeString length] == 0) {
        ErrorLog(@"Can't find In-App message type");
        hasPrerequisites = NO;
    }
    
    if (![messageTypeString isEqualToString:@"TuneMessageTypeTakeOver"]) {
        ErrorLog(@"Wrong message type");
        hasPrerequisites = NO;
    }
    
    return hasPrerequisites;
}

- (void)_buildAndShowMessage {
    TuneFullScreenMessageView *fullScreenMessageView = [[TuneFullScreenMessageView alloc] init];
    
    fullScreenMessageView.parentMessage = self;
    
    // Message ID
    if (self.messageID) {
        [fullScreenMessageView setMessageID:self.messageID];
    }
    
    // Campaign Step ID
    if (self.campaignStepID) {
        [fullScreenMessageView setCampaignStepID:self.campaignStepID];
    }
    
    // Campaign ID
    if (self.campaign) {
        [fullScreenMessageView setCampaign:self.campaign];
        
        // Record that we saw a campaign id
        [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneCampaignViewed object:nil userInfo:@{TunePayloadCampaign : self.campaign}];
    }
    
    if (self.html) {
        [fullScreenMessageView setHtml:self.html];
    }
    
    if (self.tuneActions) {
        [fullScreenMessageView setTuneActions:self.tuneActions];
    }
    
    #if TARGET_OS_IOS
    if (self.webView) {
        [fullScreenMessageView setWebView:self.webView];
    }
    #endif
    
    // Transition
    if (self.transitionType) {
        [fullScreenMessageView setTransitionType:self.transitionType];
    }
    
    [fullScreenMessageView show];
    
    [self.visibleViews addPointer:(__bridge void *)(fullScreenMessageView)];
}


@end
