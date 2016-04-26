//
//  TuneBaseInAppMessageView.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneBaseInAppMessageView.h"
#import "TuneDeviceDetails.h"
#import "TuneAnalyticsConstants.h"
#import "TuneAnalyticsVariable.h"
#import "TuneSkyhookCenter.h"

@implementation TuneBaseInAppMessageView

#pragma mark - UIView Override

- (id)init {
    
    self = [super initWithFrame:CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height)];
    
    if (self) {
        self.needToLayoutView = YES;
        self.needToAddToUIWindow = YES;
        
        [self findDeviceSpecificOrientations];
    }
    
    return self;
}

// NOTE: this will allow us to click through the clear part of the view but allow us to have an action on the message itself
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *v in self.subviews) {
        CGPoint localPoint = [v convertPoint:point fromView:self];
        if (v.alpha > 0.01 && ![v isHidden] && v.userInteractionEnabled && [v pointInside:localPoint withEvent:event])
            return YES;
    }
    return NO;
}

- (void)findDeviceSpecificOrientations {
    self.landscapeLeftType = [TuneDeviceDetails getLandscapeLeftForDevice];
    self.landscapeRightType = [TuneDeviceDetails getLandscapeRightForDevice];
    self.portraitType = [TuneDeviceDetails getPortraitForDevice];
    self.portraitUpsideDownType = [TuneDeviceDetails getPortraitUpsideDownForDevice];
}

- (void)setMessageID:(NSString *)messageID {
    _messageID = messageID;
}

- (void)setCampaignStepID:(NSString *)campaignStepID {
    _campaignStepID = campaignStepID;
}

- (void)setCampaign:(TuneCampaign *)campaign {
    _campaign = campaign;
}

- (void)recordMessageShown {

    // Mark the time that we showed the message
    _messageShownTimestamp = [NSDate date];
    
    // TODO: We're already attaching the Campaign ID and Message ID to the session... Should we also attach the Step ID to the session or is this good enough?
    TuneAnalyticsVariable *campaignStepVariable = [TuneAnalyticsVariable analyticsVariableWithName:TUNE_CAMPAIGN_STEP_IDENTIFIER value:_campaignStepID];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneInAppMessageShown object:nil userInfo:@{TunePayloadInAppMessageID: _messageID, TunePayloadCampaignStep: campaignStepVariable}];
}

- (void)recordMessageDismissedWithAction:(NSString *)dismissedAction {
    // Mark the dismissed time
    NSDate *messageDismissedTimestamp = [NSDate date];
    
    // Determine how long message was displayed
    NSNumber *secondsDisplayed = @0;
    
    if ( (_messageShownTimestamp) && (messageDismissedTimestamp) ) {
        NSTimeInterval intervalBetweenShownAndDismissed = [messageDismissedTimestamp timeIntervalSinceDate:_messageShownTimestamp];
        secondsDisplayed = @(intervalBetweenShownAndDismissed);
        if ([secondsDisplayed intValue] < 1) {
            secondsDisplayed = @1;
        }
    }
    
    // Record analytics event
    TuneAnalyticsVariable *campaignStepVariable = [TuneAnalyticsVariable analyticsVariableWithName:TUNE_CAMPAIGN_STEP_IDENTIFIER value:_campaignStepID];
    TuneAnalyticsVariable *secondsDisplayedVariable = [TuneAnalyticsVariable analyticsVariableWithName:TUNE_IN_APP_MESSAGE_SECONDS_DISPLAYED value:@([secondsDisplayed intValue]) type:TuneAnalyticsVariableNumberType];

    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneInAppMessageDismissed
                                            object:nil
                                          userInfo:@{TunePayloadInAppMessageID: _messageID,
                                                     TunePayloadInAppMessageDismissedAction: dismissedAction,
                                                     TunePayloadCampaignStep: campaignStepVariable,
                                                     TunePayloadInAppMessageSecondsDisplayed: secondsDisplayedVariable}];
}

- (void)dismissAndWait {
    [self performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:YES];
}

- (void)dismiss {
    [NSException raise:@"Missing Base Message View Method" format:@"dismiss"];
}

@end
