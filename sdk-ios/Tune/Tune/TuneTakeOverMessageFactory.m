//
//  TuneTakeOverMessageFactory.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/8/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneTakeOverMessageFactory.h"
#import "TuneDeviceDetails.h"
#import "TunePointerSet.h"
#import "TuneSkyhookCenter.h"
#import "TuneInAppUtils.h"
#import "TuneMessageImageBundle.h"
#import "TuneInAppMessageConstants.h"
#import "TuneTakeOverMessageDefaults.h"
#import "TuneTakeOverMessageView.h"
#if TARGET_OS_IOS
#import "TuneiOS8TakeOverMessageView.h"
#endif

@implementation TuneTakeOverMessageFactory

+ (TuneTakeOverMessageFactory *)buildMessageFromMessageDictionary:(NSDictionary *)messageDictionary {
    TuneTakeOverMessageFactory *messageFactory = [[TuneTakeOverMessageFactory alloc] initWithMessageDictionary:messageDictionary];
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
                    [self addImageURLForProperty:@"phonePortraitBackgroundImage-480" inMessageDictionary:message];
                }
                else if ([TuneDeviceDetails runningOn568HeightPhone]) {
                    [self addImageURLForProperty:@"phonePortraitBackgroundImage-568" inMessageDictionary:message];
                }
                else if ([TuneDeviceDetails runningOn667HeightPhone]) {
                    [self addImageURLForProperty:@"phonePortraitBackgroundImage-667" inMessageDictionary:message];
                }
                else if ([TuneDeviceDetails runningOn736HeightPhone]) {
                    [self addImageURLForProperty:@"phonePortraitBackgroundImage-736" inMessageDictionary:message];
                }
            }
        }
        else {
            // Tablet images
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
    
    if ([messageTypeString length] == 0) {
        ErrorLog(@"Can't find In-App message type");
        hasPrerequisites = NO;
    }
    
    if (![messageTypeString isEqualToString:@"TuneMessageTypeTakeOver"]) {
        ErrorLog(@"Wrong message type");
        hasPrerequisites = NO;
    }
    
    // Make sure there's an image. We can't show it without it.
    if (!(message[@"phonePortraitBackgroundImage-480"] ||
          message[@"phonePortraitBackgroundImage-568"] ||
          message[@"phonePortraitBackgroundImage-667"] ||
          message[@"phonePortraitBackgroundImage-736"] ||
          message[@"phoneLandscapeBackgroundImage-480"] ||
          message[@"phoneLandscapeBackgroundImage-568"] ||
          message[@"phoneLandscapeBackgroundImage-667"] ||
          message[@"phoneLandscapeBackgroundImage-736"] ||
          message[@"tabletPortraitBackgroundImage"] ||
          message[@"tabletLandscapeBackgroundImage"])) {
        hasPrerequisites = NO;
    }
    return hasPrerequisites;
}

- (void)_buildAndShowMessage {
    NSDictionary *message = (self.messageDictionary)[@"message"];
    
    id takeOverMessageView;
    
#if TARGET_OS_IOS
    if ([TuneDeviceDetails appIsRunningIniOS8OrAfter])
        takeOverMessageView = (TuneiOS8TakeOverMessageView *)[[TuneiOS8TakeOverMessageView alloc] init];
    else
#endif
        takeOverMessageView = (TuneTakeOverMessageView *)[[TuneTakeOverMessageView alloc] init];
    
    // Message ID
    if (self.messageID) {
        [takeOverMessageView setMessageID:self.messageID];
    }
    
    // Campaign Step ID
    if (self.campaignStepID) {
        [takeOverMessageView setCampaignStepID:self.campaignStepID];
    }
    
    // Campaign ID
    if (self.campaign) {
        [takeOverMessageView setCampaign:self.campaign];
        
        // Record that we saw a campaign id
        [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneCampaignViewed object:nil userInfo:@{TunePayloadCampaign : self.campaign}];
    }
    
    // if background images, build a bundle
    if (message[@"phonePortraitBackgroundImage-480"] ||
        message[@"phonePortraitBackgroundImage-568"] ||
        message[@"phonePortraitBackgroundImage-667"] ||
        message[@"phonePortraitBackgroundImage-736"] ||
        message[@"phoneLandscapeBackgroundImage-480"] ||
        message[@"phoneLandscapeBackgroundImage-568"] ||
        message[@"phoneLandscapeBackgroundImage-667"] ||
        message[@"phoneLandscapeBackgroundImage-736"] ||
        message[@"tabletPortraitBackgroundImage"] ||
        message[@"tabletLandscapeBackgroundImage"]) {
        TuneMessageImageBundle *imageBundle = [[TuneMessageImageBundle alloc] initWithTakeOverMessageDictionary:message];
        [takeOverMessageView setImageWithImageBundle:imageBundle];
    }
    
    // Actions
    NSDictionary *actions = message[@"actions"];
    if (actions) {
        [takeOverMessageView setPhoneAction:[TuneInAppUtils getActionFromDictionary:actions[@"phone"]]];
        [takeOverMessageView setTabletAction:[TuneInAppUtils getActionFromDictionary:actions[@"tablet"]]];
    }
    
    // Transition
    if (message[@"transition"]) {
        TuneMessageTransition transition = [TuneInAppUtils getTransitionFromDictionary:message];
        [takeOverMessageView setTransitionType:transition];
    }
    
    // Close button color
    [takeOverMessageView setCloseButtonColor:[TuneInAppUtils getMessageCloseButtonColorFromDictionary:message withDefaultColor:TakeOverMessageDefaultCloseButtonColor]];
    
    // Mask type
    [takeOverMessageView setBackgroundMaskType:[TuneInAppUtils getMessageBackgroundMaskTypeFromDictionary:message]];
    
    
    [takeOverMessageView show];
    
    [self.visibleViews addPointer:(__bridge void *)(takeOverMessageView)];
}


@end
