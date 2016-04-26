//
//  TunePopUpMessageFactory.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/10/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TunePopUpMessageFactory.h"
#import "TunePointerSet.h"
#import "TuneMessageStyling.h"
#import "TuneInAppMessageConstants.h"
#import "TunePopUpMessageDefaults.h"
#import "TuneInAppUtils.h"
#import "TunePopUpMessageView.h"
#import "TuneSkyhookCenter.h"

@implementation TunePopUpMessageFactory

+ (TunePopUpMessageFactory *)buildMessageFromMessageDictionary:(NSDictionary *)messageDictionary {
    TunePopUpMessageFactory *messageFactory = [[TunePopUpMessageFactory alloc] initWithMessageDictionary:messageDictionary] ;
    return messageFactory;
}

- (id)initWithMessageDictionary:(NSDictionary *)messageDictionary {
    self = [super initWithMessageDictionary:messageDictionary];
    
    if (self) {
        // Collect image urls
        self.images = [[NSMutableDictionary alloc] init];
        NSDictionary *message = (self.messageDictionary)[@"message"];
        
        [self addImageURLForProperty:@"backgroundImage" inMessageDictionary:message];
        [self addImageURLForProperty:@"image" inMessageDictionary:message];
        
        NSDictionary *ctaButtonDictionary = message[@"ctaButton"];
        [self addImageURLForProperty:@"backgroundImage" inMessageDictionary:ctaButtonDictionary];
        
        NSDictionary *cancelButtonDictionary = message[@"cancelButton"];
        [self addImageURLForProperty:@"backgroundImage" inMessageDictionary:cancelButtonDictionary];
        
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
    
    NSDictionary *message = (self.messageDictionary)[@"message"];
    
    // edgeStyle
    NSString *edgeStyleString = message[@"edgeStyle"];
    TunePopUpMessageEdgeStyle edgeStyle = TunePopUpMessageSquareCorners;
    if ([TuneInAppUtils propertyIsNotEmpty:edgeStyleString]) {
        if ([edgeStyleString isEqualToString:@"TunePopUpMessageRoundedCorners"]) {
            edgeStyle = TunePopUpMessageRoundedCorners;
        }
        else if ([edgeStyleString isEqualToString:@"TunePopUpMessageSquareCorners"]) {
            edgeStyle = TunePopUpMessageSquareCorners;
        }
    }
    else {
        edgeStyle = TunePopUpMessageDefaultEdgeStyle;
    }
    
    // Init the pop up message view
    TunePopUpMessageView *popUpMessageView = [[TunePopUpMessageView alloc] initWithPopUpMessageEdgeStyle:edgeStyle];
    
    // Message ID
    if (self.messageID) {
        [popUpMessageView setMessageID:self.messageID];
    }
    
    // Campaign Step ID
    if (self.campaignStepID) {
        [popUpMessageView setCampaignStepID:self.campaignStepID];
    }
    
    // Campaign ID
    if (self.campaign) {
        [popUpMessageView setCampaign:self.campaign];
        
        // Record that we saw a campaign id
        [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneCampaignViewed object:nil userInfo:@{TunePayloadCampaign : self.campaign}];
    }
    
    // Close button
    if ([TuneInAppUtils propertyIsNotEmpty:message[@"showCloseButton"] ]) {
        BOOL showCloseButtonString = [message[@"showCloseButton"] boolValue];
        if (showCloseButtonString) {
            [popUpMessageView showCloseButton];
        }
    }
    [popUpMessageView setCloseButtonColor:[TuneInAppUtils getMessageCloseButtonColorFromDictionary:message withDefaultColor:TunePopUpdateCloseButtonDefaultColor]];
    
    // Vertical padding
    if ([TuneInAppUtils propertyIsNotEmpty:message[@"verticalPadding"]]) {
        NSNumber *verticalPadding = [TuneInAppUtils getNumberValue:message[@"verticalPadding"]];
        [popUpMessageView setVerticalPadding:[verticalPadding intValue]];
    }
    
    // Horizontal padding
    if ([TuneInAppUtils propertyIsNotEmpty:message[@"horizontalPadding"]]) {
        NSNumber *horizontalPadding = [TuneInAppUtils getNumberValue:message[@"horizontalPadding"]];
        [popUpMessageView setHorizontalPadding:[horizontalPadding intValue]];
    }
    
    // Background color
    UIColor *backgroundColor = [TuneInAppUtils buildUIColorFromProperty:message[@"backgroundColor"]];
    if (backgroundColor) {
        [popUpMessageView setMessageBackgroundColor:backgroundColor];
    }
    
    // Mask type
    [popUpMessageView setBackgroundMaskType:[TuneInAppUtils getMessageBackgroundMaskTypeFromDictionary:message]];
    
    // Drop shadow
    NSString *showDropShadowString = message[@"showDropShadow"];
    if ([TuneInAppUtils propertyIsNotEmpty:showDropShadowString]) {
        if ([showDropShadowString isEqualToString:@"YES"]) {
            [popUpMessageView showDropShadow];
        }
    }
    
    // image
    NSDictionary *imageDictionary = message[@"image"];
    if (imageDictionary) {
        UIImage *image = [TuneInAppUtils getScreenAppropriateImageFromDictionary:imageDictionary];
        if (image != nil) {
            [popUpMessageView setImage:image];
        }
    }
    
    // background image
    NSDictionary *backgroundImageDictionary = message[@"backgroundImage"];
    if (backgroundImageDictionary) {
        UIImage *image = [TuneInAppUtils getScreenAppropriateImageFromDictionary:backgroundImageDictionary];
        if (image != nil) {
            [popUpMessageView setBackgroundImage:image];
        }
    }
    
    // headline
    NSDictionary *headlineDictionary = message[@"headline"];
    TuneMessageLabel *headlineLabel = [[TuneMessageLabel alloc] initWithHeadlineLabelDictionary:headlineDictionary messageType:TuneMessageTypePopup];
    [popUpMessageView setHeadlineLabel:headlineLabel];
    
    // body
    NSDictionary *bodyDictionary = message[@"body"];
    TuneMessageLabel *bodyLabel = [[TuneMessageLabel alloc] initWithLabelDictionary:bodyDictionary andMessageType:TuneMessageTypePopup];
    [popUpMessageView setBodyLabel:bodyLabel];
    
    // Button separators
    NSString *buttonTopSeparatorColorString = message[@"buttonTopSeparatorColor"];
    if ([TuneInAppUtils propertyIsNotEmpty:buttonTopSeparatorColorString]) {
        UIColor *buttonTopSeparatorColor = [TuneInAppUtils colorWithString:buttonTopSeparatorColorString];
        if (buttonTopSeparatorColor) {
            [popUpMessageView setButtonTopSeparatorColor:buttonTopSeparatorColor];
        }
    }
    NSString *buttonMiddleSeparatorColorString = message[@"buttonMiddleSeparatorColor"];
    if ([TuneInAppUtils propertyIsNotEmpty:buttonMiddleSeparatorColorString]) {
        UIColor *buttonMiddleSeparatorColor = [TuneInAppUtils colorWithString:buttonMiddleSeparatorColorString];
        if (buttonMiddleSeparatorColor) {
            [popUpMessageView setButtonMiddleSeparatorColor:buttonMiddleSeparatorColor];
        }
    }
    
    // CTA button
    NSDictionary *ctaButtonDictionary = message[@"ctaButton"];
    if (ctaButtonDictionary) {
        TuneMessageButton *ctaButton = [[TuneMessageButton alloc] initWithButtonlDictionary:ctaButtonDictionary andMessageType:TuneMessageTypePopup andMessageButtonType:TuneMessageButtonTypeCta];
        [popUpMessageView setCTAButton:ctaButton];
    }
    
    // Cancel button
    NSDictionary *cancelButtonDictionary = message[@"cancelButton"];
    if (cancelButtonDictionary) {
        TuneMessageButton *cancelButton = [[TuneMessageButton alloc] initWithButtonlDictionary:cancelButtonDictionary andMessageType:TuneMessageTypePopup andMessageButtonType:TuneMessageButtonTypeCancel];
        [popUpMessageView setCancelbutton:cancelButton];
    }
    
    // Content area action
    [popUpMessageView setContentAreaAction:[TuneInAppUtils getDeviceAppropriateActionFromDictionary:message[@"contentAreaAction"]]];
    
    
    // Transition
    if (message[@"transition"]) {
        TuneMessageTransition transition = [TuneInAppUtils getTransitionFromDictionary:message];
        [popUpMessageView setTransitionType:transition];
    }
    
    [popUpMessageView show];
    
    [self.visibleViews addPointer:(__bridge void *)(popUpMessageView)];
}

@end
