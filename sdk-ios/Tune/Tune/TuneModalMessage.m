//
//  TuneModalMessage.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/10/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneModalMessage.h"
#import "TunePointerSet.h"
#import "TuneMessageStyling.h"
#import "TuneInAppMessageConstants.h"
#import "TuneInAppUtils.h"
#import "TuneModalMessageDefaults.h"
#import "TuneModalMessageView.h"
#import "TuneSkyhookCenter.h"

@implementation TuneModalMessage

+ (TuneModalMessage *)buildMessageFromMessageDictionary:(NSDictionary *)messageDictionary {
    TuneModalMessage *messageFactory = [[TuneModalMessage alloc] initWithMessageDictionary:messageDictionary] ;
    return messageFactory;
}

- (id)initWithMessageDictionary:(NSDictionary *)messageDictionary {
    self = [super initWithMessageDictionary:messageDictionary];
    
    if (self) {
        NSDictionary *message = (self.messageDictionary)[@"message"];
        
        // Read edge style from playlist
        self.edgeStyle = TuneModalMessageDefaultEdgeStyle;
        NSString *edgeStyleString = message[@"edgeStyle"];
        if ([TuneInAppUtils propertyIsNotEmpty:edgeStyleString]) {
            if ([edgeStyleString isEqualToString:@"TunePopUpMessageRoundedCorners"]) {
                self.edgeStyle = TuneModalMessageRoundedCorners;
            } else if ([edgeStyleString isEqualToString:@"TunePopUpMessageSquareCorners"]) {
                self.edgeStyle = TuneModalMessageSquareCorners;
            }
        }
        
        // Width and height
        if ([message objectForKey:@"width"]) {
            self.width = message[@"width"];
        } else {
            self.width = [NSNumber numberWithInt: TuneModalMessageDefaultWidthOnPhone];
        }
        if ([message objectForKey:@"height"]) {
            self.height = message[@"height"];
        } else {
            self.height = [NSNumber numberWithInt: TuneModalMessageDefaultHeightOnPhone];
        }
        
        // Mask type
        self.backgroundMaskType = [TuneInAppUtils getMessageBackgroundMaskTypeFromDictionary:message];
        
        #if TARGET_OS_IOS
        // Set the WebView frame on the main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            // Use min of screen size or width/height
            int minWidth = MIN([self.width intValue], [UIApplication sharedApplication].keyWindow.bounds.size.width);
            int minHeight = MIN([self.height intValue], [UIApplication sharedApplication].keyWindow.bounds.size.height);
            self.webView.frame = CGRectMake(0, 0, minWidth, minHeight);
        });
        #endif

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
    
    if (![messageTypeString isEqualToString:@"TuneMessageTypePopUp"]) {
        ErrorLog(@"Wrong In-App message type");
        hasPrerequisites = NO;
    }
    
    return hasPrerequisites;
}

- (void)_buildAndShowMessage {
    // Init the modal message view
    TuneModalMessageView *modalMessageView = [[TuneModalMessageView alloc] initWithPopUpMessageEdgeStyle:self.edgeStyle];
    
    modalMessageView.parentMessage = self;
    
    // Modal width and height
    if (self.width) {
        [modalMessageView setWidth:self.width];
    }
    if (self.height) {
        [modalMessageView setHeight:self.height];
    }
    
    // Message ID
    if (self.messageID) {
        [modalMessageView setMessageID:self.messageID];
    }
    
    // Campaign Step ID
    if (self.campaignStepID) {
        [modalMessageView setCampaignStepID:self.campaignStepID];
    }
    
    // Campaign ID
    if (self.campaign) {
        [modalMessageView setCampaign:self.campaign];
        
        // Record that we saw a campaign id
        [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneCampaignViewed object:nil userInfo:@{TunePayloadCampaign : self.campaign}];
    }
    
    // Message HTML
    if (self.html) {
        [modalMessageView setHtml:self.html];
    }
    
    // Tune Actions
    if (self.tuneActions) {
        [modalMessageView setTuneActions:self.tuneActions];
    }
    
    // Mask type
    if (self.backgroundMaskType) {
        [modalMessageView setBackgroundMaskType:self.backgroundMaskType];
    }
    
    #if TARGET_OS_IOS
    if (self.webView) {
        [modalMessageView setWebView:self.webView];
    }
    #endif
    
    // Transition
    if (self.transitionType) {
        [modalMessageView setTransitionType:self.transitionType];
    }
    
    [modalMessageView show];
    
    [self.visibleViews addPointer:(__bridge void *)(modalMessageView)];
}

@end
