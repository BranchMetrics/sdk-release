//
//  TuneSlideInMessageFactory.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneSlideInMessageFactory.h"
#import "TuneDeviceDetails.h"
#import "TuneInAppUtils.h"
#import "TunePointerSet.h"
#import "TuneInAppMessageConstants.h"
#import "TuneiOS8SlideInMessageView.h"
#import "TuneSlideInMessageView.h"
#import "TuneSlideInMessageDefaults.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookConstants.h"

@implementation TuneSlideInMessageFactory

+ (TuneSlideInMessageFactory *)buildMessageFromMessageDictionary:(NSDictionary *)messageDictionary {
    TuneSlideInMessageFactory *messageFactory = [[TuneSlideInMessageFactory alloc] initWithMessageDictionary:messageDictionary];
    return messageFactory;
}

- (id)initWithMessageDictionary:(NSDictionary *)messageDictionary {
    self = [super initWithMessageDictionary:messageDictionary];
    
    if (self) {
        // Collect image urls
        self.images = [[NSMutableDictionary alloc] init];
        NSDictionary *message = (self.messageDictionary)[@"message"];
        
        if ([TuneDeviceDetails runningOnPhone]) {
            // Phone images
            if ([TuneDeviceDetails appSupportsLandscape]) {
                if ([TuneDeviceDetails runningOn480HeightPhone]) {
                    [self addImageURLForProperty:@"phoneLandscapeBackgroundImage-480" inMessageDictionary:message];
                }
                else if ([TuneDeviceDetails runningOn568HeightPhone]) {
                    [self addImageURLForProperty:@"phoneLandscapeBackgroundImage-568" inMessageDictionary:message];
                }
                else if ([TuneDeviceDetails runningOn667HeightPhone]) {
                    [self addImageURLForProperty:@"phoneLandscapeBackgroundImage-667" inMessageDictionary:message];
                }
                else if ([TuneDeviceDetails runningOn736HeightPhone]) {
                    [self addImageURLForProperty:@"phoneLandscapeBackgroundImage-736" inMessageDictionary:message];
                }
            }
            
            if ([TuneDeviceDetails appSupportsPortrait]) {
                
                if ([TuneDeviceDetails runningOn480HeightPhone]) {
                    [self addImageURLForProperty:@"phonePortraitBackgroundImage" inMessageDictionary:message];
                }
                else if ([TuneDeviceDetails runningOn568HeightPhone]) {
                    [self addImageURLForProperty:@"phonePortraitBackgroundImage" inMessageDictionary:message];
                }
                else if ([TuneDeviceDetails runningOn667HeightPhone]) {
                    [self addImageURLForProperty:@"phonePortraitBackgroundImage-667" inMessageDictionary:message];
                }
                else if ([TuneDeviceDetails runningOn736HeightPhone]) {
                    [self addImageURLForProperty:@"phonePortraitBackgroundImage-736" inMessageDictionary:message];
                }
            }
        } else {
            // Tablet images
            [self addImageURLForProperty:@"tabletCTAImage" inMessageDictionary:message];
            
            if ([TuneInAppUtils propertyIsNotEmpty:message[@"tabletCTAButton"]]) {
                NSDictionary *tabletCtaButton = message[@"tabletCTAButton"];
                if ([TuneInAppUtils propertyIsNotEmpty:tabletCtaButton[@"backgroundImage"]]) {
                    [self addImageURLForProperty:@"backgroundImage" inMessageDictionary:tabletCtaButton];
                }
            }
            
            if ([TuneDeviceDetails appSupportsPortrait]) {
                [self addImageURLForProperty:@"tabletPortraitBackgroundImage" inMessageDictionary:message];
            }
            
            if ([TuneDeviceDetails appSupportsLandscape]) {
                [self addImageURLForProperty:@"tabletLandscapeBackgroundImage" inMessageDictionary:message];
            }
        }
        
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

- (BOOL)dictionaryDoesNotHaveImageOrMessagePrerequisite:(NSDictionary *)messageDictionary
                                       forImageProperty:(NSString *)imageProperty
                                      andMessageProperty:(NSString *)messageProperty {
    NSString *imageName = [TuneInAppUtils getScreenAppropriateValueFromDictionary:messageDictionary[imageProperty]];
    NSString *messageText = [TuneInAppUtils getScreenAppropriateValueFromDictionary:messageDictionary[messageDictionary]];
    
    if (!imageName) {
        imageName = @"";
    }
    
    if (!messageText) {
        messageText = @"";
    }
    
    return ([imageName isEqualToString:@""] && [messageText isEqualToString:@""]);
}

- (void)_buildAndShowMessage {
    NSDictionary *message = (self.messageDictionary)[@"message"];
    
    TuneMessageLocationType messageLocationType = [TuneInAppUtils getLocationTypeByString:message[@"messageLocationType"]];
    
    id slideInMessageView;
    
    if ([TuneDeviceDetails appIsRunningIniOS8OrAfter]) {
        slideInMessageView = (TuneiOS8SlideInMessageView *)[[TuneiOS8SlideInMessageView alloc] initWithLocationType:messageLocationType];
    } else {
        slideInMessageView = (TuneSlideInMessageView *)[[TuneSlideInMessageView alloc] initWithLocationType:messageLocationType];
    }

    // Message ID
    if (self.messageID) {
        [slideInMessageView setMessageID:self.messageID];
    }
    
    // Campaign Step ID
    if (self.campaignStepID) {
        [slideInMessageView setCampaignStepID:self.campaignStepID];
    }
    
    // Campaign ID
    if (self.campaign) {
        [slideInMessageView setCampaign:self.campaign];
        
        // Record that we saw a campaign id
        [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneCampaignViewed object:nil userInfo:@{TunePayloadCampaign : self.campaign}];
    }
    
    // duration
    if (message[@"duration"]) {
        NSNumber *duration = [TuneInAppUtils getMessageDurationFromDictionary:message];
        [slideInMessageView setDisplayDuration:duration];
    } else {
        [slideInMessageView setDisplayDuration:@0];
    }
    
    // if background images, build a bundle
    if (message[@"phoneLandscapeBackgroundImage-480"] ||
        message[@"phoneLandscapeBackgroundImage-568"] ||
        message[@"phoneLandscapeBackgroundImage-667"] ||
        message[@"phoneLandscapeBackgroundImage-736"] ||
        message[@"phonePortraitBackgroundImage"] ||
        message[@"phonePortraitBackgroundImage-667"] ||
        message[@"phonePortraitBackgroundImage-736"] ||
        message[@"tabletPortraitBackgroundImage"] ||
        message[@"tabletLandscapeBackgroundImage"]) {
        TuneMessageImageBundle *backgroundImageBundle = [[TuneMessageImageBundle alloc] initWithSlideInMessageDictionary:message];
        [slideInMessageView setBackgroundImageWithImageBundle:backgroundImageBundle];
    }
    
    // Hide close button?
    NSString *showCloseButton = message[@"showCloseButton"];
    if (![showCloseButton boolValue]) {
        [slideInMessageView hideCloseButton];
    }
    
    // Close button color
    [slideInMessageView setCloseButtonColor:[TuneInAppUtils getMessageCloseButtonColorFromDictionary:message withDefaultColor:SlideInMessageDefaultCloseButtonColor]];
    
    // Background color
    UIColor *backgroundColor = [TuneInAppUtils buildUIColorFromProperty:message[@"backgroundColor"]];
    if (backgroundColor) {
        [slideInMessageView setMessageBackgroundColor:backgroundColor];
    }
    
    // Action
    NSDictionary *actions = message[@"actions"];
    if (actions) {
        TuneMessageAction *phoneAction = [TuneInAppUtils getActionFromDictionary:actions[@"phone"]];
        TuneMessageAction *tabletAction = [TuneInAppUtils getActionFromDictionary:actions[@"tablet"]];
        [slideInMessageView setPhoneAction:phoneAction];
        [slideInMessageView setTabletAction:tabletAction];
    }
    
    // Messages
    if ([TuneDeviceDetails runningOnPhone]) {
        if (message[@"phonePortraitMessage"]) {
            TuneMessageLabel *phonePortraitMessageLabel = [[TuneMessageLabel alloc] initWithLabelDictionary:message[@"phonePortraitMessage"] andMessageType:TuneMessageTypeSlideIn];
            
            [slideInMessageView setMessageLabelPortrait:phonePortraitMessageLabel];
            
            TuneMessageLabel *phonePortraitUpsideDownMessageLabel = [[TuneMessageLabel alloc] initWithLabelDictionary:message[@"phonePortraitMessage"] andMessageType:TuneMessageTypeSlideIn];
            
            [slideInMessageView setMessageLabelPortraitUpsideDown:phonePortraitUpsideDownMessageLabel];
        }
        
        if (message[@"phoneLandscapeMessage"]) {
            TuneMessageLabel *phoneLandscapeLeftMessageLabel = [[TuneMessageLabel alloc] initWithLabelDictionary:message[@"phoneLandscapeMessage"] andMessageType:TuneMessageTypeSlideIn];
            
            [slideInMessageView setMessageLabelLandscapeLeft:phoneLandscapeLeftMessageLabel];
            
            TuneMessageLabel *phoneLandscapeRightMessageLabel = [[TuneMessageLabel alloc] initWithLabelDictionary:message[@"phoneLandscapeMessage"] andMessageType:TuneMessageTypeSlideIn];
            
            [slideInMessageView setMessageLabelLandscapeRight:phoneLandscapeRightMessageLabel];
        }
        
    } else {
        if (message[@"tabletPortraitMessage"]) {
            TuneMessageLabel *tabletPortraitMessageLabel = [[TuneMessageLabel alloc] initWithLabelDictionary:message[@"tabletPortraitMessage"] messageType:TuneMessageTypeSlideIn andOrientation:TuneMessageOrientationTabletPortrait];
            
            [slideInMessageView setMessageLabelPortrait:tabletPortraitMessageLabel];
            
            TuneMessageLabel *tabletPortraitUpsideDownMessageLabel = [[TuneMessageLabel alloc] initWithLabelDictionary:message[@"tabletPortraitMessage"] messageType:TuneMessageTypeSlideIn andOrientation:TuneMessageOrientationTabletPortrait];
            
            [slideInMessageView setMessageLabelPortraitUpsideDown:tabletPortraitUpsideDownMessageLabel];
        }
        
        if (message[@"tabletLandscapeMessage"]) {
            TuneMessageLabel *tabletLandscapeLeftMessageLabel = [[TuneMessageLabel alloc] initWithLabelDictionary:message[@"tabletLandscapeMessage"] messageType:TuneMessageTypeSlideIn andOrientation:TuneMessageOrientationTabletLandscapeLeft];
            
            [slideInMessageView setMessageLabelLandscapeLeft:tabletLandscapeLeftMessageLabel];
            
            TuneMessageLabel *tabletLandscapeRightMessageLabel = [[TuneMessageLabel alloc] initWithLabelDictionary:message[@"tabletLandscapeMessage"] messageType:TuneMessageTypeSlideIn andOrientation:TuneMessageOrientationTabletLandscapeRight];
            
            [slideInMessageView setMessageLabelLandscapeRight:tabletLandscapeRightMessageLabel];
        }
    }
    
    // CTA Image
    if (message[@"tabletCTAImage"]) {
        NSString *ctaImageName = [TuneInAppUtils getScreenAppropriateValueFromDictionary:message[@"tabletCTAImage"]];
        
        if ([ctaImageName length] > 0) {
            @try {
                [slideInMessageView setCTAImage:[TuneInAppUtils getScreenAppropriateImageFromDictionary:message[@"tabletCTAImage"]]];
            } @catch (NSException *exception) {
                // Nothing
            }
        }
    }
    
    // CTA Button
    if (message[@"tabletCTAButton"]) {
        TuneMessageButton *buttonModel = [[TuneMessageButton alloc] initWithButtonlDictionary:message[@"tabletCTAButton"] andMessageType:TuneMessageTypeSlideIn];
        if (buttonModel) {
            [slideInMessageView setCTAButton:buttonModel];
        }
    }
    
    [slideInMessageView show];
    
    [self.visibleViews addPointer:(__bridge void *)(slideInMessageView)];
}



@end
