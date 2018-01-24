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
#import "TuneInAppMessageAction.h"
#import "TuneMessageStyling.h"
#import "TuneModalMessageView.h"
#import "TuneSkyhookCenter.h"

@implementation TuneBaseInAppMessageView

#pragma mark - UIView Override

- (id)init {
    
    self = [super initWithFrame:CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.bounds.size.width, [UIApplication sharedApplication].keyWindow.bounds.size.height)];
    
    if (self) {
        self.needToLayoutView = YES;
        self.needToAddToUIWindow = YES;
        
        self.indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.indicator.color = UIColor.grayColor;
        
        // Create a close button
        self.closeButton = [[TuneCloseButton alloc] init];
        [self.closeButton setParentMessageView:self];
        
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
    #if TARGET_OS_IOS
    self.statusBarOffset = [UIApplication sharedApplication].statusBarHidden ? 0 : 20;
    #else
    self.statusBarOffset = 0;
    #endif
}

- (void)recordMessageShown {

    // Mark the time that we showed the message
    _messageShownTimestamp = [NSDate date];
    
    // TODO: We're already attaching the Campaign ID and Message ID to the session... Should we also attach the Step ID to the session or is this good enough?
    TuneAnalyticsVariable *campaignStepVariable = [TuneAnalyticsVariable analyticsVariableWithName:TUNE_CAMPAIGN_STEP_IDENTIFIER value:_campaignStepID];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneInAppMessageShown object:nil userInfo:@{TunePayloadInAppMessageID: _messageID, TunePayloadCampaignStep: campaignStepVariable}];
    
    // Execute "onDisplay" Tune Action if it exists
    TuneInAppMessageAction *tuneAction = [self.tuneActions objectForKey:TUNE_IN_APP_MESSAGE_ONDISPLAY_ACTION];
    if (tuneAction) {
        // Execute the action
        [tuneAction performAction];
    }
}

- (void)recordMessageDismissedWithUnspecifiedAction:(NSString *)unspecifiedAction {
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
    TuneAnalyticsVariable *unspecifiedActionVariable = [TuneAnalyticsVariable analyticsVariableWithName:TUNE_IN_APP_MESSAGE_UNSPECIFIED_ACTION_NAME value:unspecifiedAction];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneInAppMessageDismissedWithUnspecifiedAction
                                            object:nil
                                          userInfo:@{TunePayloadInAppMessageID: _messageID,
                                                     TunePayloadInAppMessageDismissedAction: unspecifiedActionVariable,
                                                     TunePayloadCampaignStep: campaignStepVariable,
                                                     TunePayloadInAppMessageSecondsDisplayed: secondsDisplayedVariable}];
    
    // Execute "onDismiss" Tune Action if it exists
    TuneInAppMessageAction *tuneAction = [self.tuneActions objectForKey:TUNE_IN_APP_MESSAGE_ONDISMISS_ACTION];
    if (tuneAction) {
        // Execute the action
        [tuneAction performAction];
    }
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
    
    // Execute "onDismiss" Tune Action if it exists
    TuneInAppMessageAction *tuneAction = [self.tuneActions objectForKey:TUNE_IN_APP_MESSAGE_ONDISMISS_ACTION];
    if (tuneAction) {
        // Execute the action
        [tuneAction performAction];
    }
}

- (void)dismissAndWait {
    [self performSelectorOnMainThread:@selector(dismiss) withObject:nil waitUntilDone:YES];
}

- (void)dismiss {
    [NSException raise:@"Missing Base Message View Method" format:@"dismiss"];
}

#pragma mark - WKNavigationDelegate Methods

#if TARGET_OS_IOS
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.parentMessage.webViewLoaded = YES;
    self.webView.hidden = NO;
    [self.indicator stopAnimating];
    self.closeButton.hidden = YES;
    
    // Play the transition in on the WebView for full screens and banners, but not modals
    if (![self isKindOfClass:[TuneModalMessageView class]]) {
        CATransition *transition = [TuneMessageStyling messageTransitionInWithType:self.transitionType withEaseIn:NO];
        [self.webView.layer removeAllAnimations];
        [self.webView.layer addAnimation:transition forKey:kCATransition];
        [UIView commitAnimations];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if ([navigationAction.request.URL.absoluteString isEqualToString:@"about:blank"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }
    
    if ([navigationAction.request.URL.scheme isEqualToString:TUNE_ACTION_SCHEME]) {
        NSString *actionName = navigationAction.request.URL.host;
        
        if ([actionName isEqualToString:TUNE_IN_APP_MESSAGE_DISMISS_ACTION]) {
            // "dismiss" is a special Tune Action name that will log a close
            [self recordMessageDismissedWithAction:TUNE_IN_APP_MESSAGE_ACTION_CLOSE_BUTTON_PRESSED];
        } else {
            TuneInAppMessageAction *tuneAction = [self.tuneActions objectForKey:actionName];
            if (tuneAction) {
                // Log a Tune Action event with action name
                [self recordMessageDismissedWithAction:actionName];
                
                // Execute the action
                [tuneAction performAction];
            } else {
                // If the Tune Action name was not found in playlist, log an unspecified action event with action name
                [self recordMessageDismissedWithUnspecifiedAction:actionName];
            }
        }
        
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        // If the action is an external url, log an unspecified action event with url
        [self recordMessageDismissedWithUnspecifiedAction:navigationAction.request.URL.absoluteString];
        
        // Allow the WebView to navigate to that url
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    
    [self dismiss];
}
#endif

@end
