//
//  TuneModalMessageView.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/10/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneModalMessageView.h"
#import "TuneMessageOrientationState.h"
#import "TuneModalMessageDefaults.h"
#import "TuneDeviceDetails.h"
#import "TuneViewUtils.h"
#import "TuneLabelUtils.h"
#import "TuneMessageStyling.h"
#import "TuneAnalyticsConstants.h"
#import "TuneSkyhookCenter.h"

@implementation TuneModalMessageView

- (id)initWithPopUpMessageEdgeStyle:(TuneModalMessageEdgeStyle)edgeStyle {
    #if TARGET_OS_IOS
    [TuneMessageOrientationState startTrackingOrientation];

    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(deviceOrientationDidChange:)
                                              name:UIApplicationDidChangeStatusBarOrientationNotification
                                            object:nil];
    #endif
    self.edgeStyle = edgeStyle;
    
    self = [super init];
    self.backgroundColor = [UIColor clearColor];
    
    [self initBackgroundMask];
    [self adjustBackgroundMaskSizeToFitFrame];
    
    if (self) {
        // Initialization code
        self.transitionType = TuneModalMessageDefaultTransition;
    }
    
    return self;
}

- (void)dealloc {
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
}

#if TARGET_OS_IOS
- (void)deviceOrientationDidChange:(TuneSkyhookPayload *)payload {
    if ([TuneMessageOrientationState currentOrientationIsSupportedByApp]) {
        // Resize modal window on orientation change to not exceed screen bounds
        int messageWidth = MIN([self.width intValue], [UIApplication sharedApplication].keyWindow.bounds.size.width);
        int messageHeight = MIN([self.height intValue], [UIApplication sharedApplication].keyWindow.bounds.size.height);
        CGFloat xOrigin = ceil(([UIApplication sharedApplication].keyWindow.bounds.size.width - messageWidth)/2);
        CGFloat yOrigin =  ceil(([UIApplication sharedApplication].keyWindow.bounds.size.height - messageHeight)/2);
        self.messageContainer.frame = CGRectMake(xOrigin, yOrigin, messageWidth, messageHeight);
        
        CGSize currScreenBounds = [TuneMessageOrientationState getCalculatedWindowSizeForCurrentOrientation];
        self.frame = CGRectMake(0, 0, currScreenBounds.width, currScreenBounds.height);
        [TuneViewUtils centerHorizontallyAndVerticallyInFrame:self.frame onView:_messageContainer];
    }
    
    [self adjustBackgroundMaskSizeToFitFrame];
}
#endif

- (void)initBackgroundMask {
    self.backgroundMaskView = [[UIView alloc] initWithFrame:self.frame];
    self.backgroundMaskView.backgroundColor = [TuneModalMessageDefaults defaultModalBackgroundMaskColor];
    self.backgroundMaskView.alpha = 0.65;
    [self addSubview:self.backgroundMaskView];
}

- (void)adjustBackgroundMaskSizeToFitFrame {
    CGFloat largerSide = fmax(self.frame.size.width,self.frame.size.height);
    
    CGFloat originX = 0;
    CGFloat originY = 0;
    
    // adjust background positioning for iOS7 devices in landscape
    if (![TuneDeviceDetails appIsRunningIniOS8OrAfter]) {
        originX = -self.frame.origin.y; // YES these are swapped x-> y because iOS7 landscape is like that
        originY = -self.frame.origin.x; // when in portrait on iOS 7 the origin is 0,0, so it's okay
    }
    
    self.backgroundMaskView.frame = CGRectMake(originX,originY,largerSide,largerSide);
}

#pragma mark - Layout
- (void)layoutPopUpView {
    
    int messageWidth = MIN([self.width intValue], [UIApplication sharedApplication].keyWindow.bounds.size.width);
    int messageHeight = MIN([self.height intValue], [UIApplication sharedApplication].keyWindow.bounds.size.height);
    
    CGFloat xOrigin = ceil(([UIApplication sharedApplication].keyWindow.bounds.size.width - messageWidth)/2);
    CGFloat yOrigin =  ceil(([UIApplication sharedApplication].keyWindow.bounds.size.height - messageHeight)/2);
    
    CGRect _messageContainerFrame = CGRectMake(xOrigin, yOrigin, messageWidth, messageHeight);
    self.messageContainer = [[UIView alloc] initWithFrame:_messageContainerFrame];
    [self addSubview:self.messageContainer];
    
    self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, messageWidth, messageHeight)];
    self.backgroundView.backgroundColor = [TuneModalMessageDefaults defaultModalBackgroundColor];
    self.backgroundView.layer.masksToBounds = YES;
    [self.messageContainer addSubview:self.backgroundView];
    
    // Adjust the screen size
    [self resizeView];
    
    // Edge style
    if (self.edgeStyle == TuneModalMessageRoundedCorners) {
        self.messageContainer.layer.cornerRadius = TuneModalMessageDefaultCornerRadius;
        self.messageContainer.layer.masksToBounds = YES;
    }
    
#if TARGET_OS_IOS
    // Add the WebView to the message container
    self.webView.navigationDelegate = self;
    [self.messageContainer addSubview:self.webView];
    
    // Start by showing activity indicator
    if (self.parentMessage.webViewLoaded) {
        self.webView.hidden = NO;
    } else {
        // Add activity indicator to view
        self.indicator.center = self.messageContainer.center;
        [self addSubview:self.indicator];
        [self bringSubviewToFront:self.indicator];
        [self.indicator startAnimating];
        
        // Set close button position
        CGRect closeButtonFrame = self.closeButton.frame;
        CGFloat xPosition = CGRectGetWidth(self.frame) - CGRectGetWidth(closeButtonFrame) - 16;
        closeButtonFrame.origin = CGPointMake(ceil(xPosition), self.statusBarOffset + 16.0);
        self.closeButton.frame = closeButtonFrame;
        self.closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        // Add close button after 1s
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            if (!self.parentMessage.webViewLoaded) {
                // Add close button to view
                [self addSubview:self.closeButton];
                [self bringSubviewToFront:self.closeButton];
            }
        });
    }
#endif
    
    self.needToLayoutView = NO;
}

- (void)applyBackgroundMaskColor {
    if (self.backgroundMaskType == TuneMessageBackgroundMaskTypeDark) {
        self.backgroundMaskView.backgroundColor = [UIColor blackColor];
    }
    else if (self.backgroundMaskType == TuneMessageBackgroundMaskTypeLight) {
        self.backgroundMaskView.backgroundColor = [UIColor whiteColor];
    }
    else if (self.backgroundMaskType == TuneMessageBackgroundMaskTypeBlur) {
        // NOTE: This isn't supported yet. 
        self.backgroundMaskView.backgroundColor = [UIColor whiteColor];
    }
    else if (self.backgroundMaskType == TuneMessageBackgroundMaskTypeNone) {
        self.backgroundMaskView.backgroundColor = [UIColor clearColor];
    }
}

- (void)resizeView {
    // Adjust size of view and backgroundView to fit text
    int messageHeight = MIN([self.height intValue], [UIApplication sharedApplication].keyWindow.bounds.size.height);
    
    [TuneViewUtils setHeight:messageHeight onView:_backgroundView];
    [TuneViewUtils setHeight:messageHeight onView:_messageContainer];
    
    // Center vertically
    CGFloat viewOrigin = ceil(([UIApplication sharedApplication].keyWindow.bounds.size.height - messageHeight)/2);
    [TuneViewUtils setY:viewOrigin onView:_messageContainer];
}

#pragma mark - Control logic

- (void)show {
    if (self.needToLayoutView) {
        [self layoutPopUpView];
    }
    else {
        // Just make sure it's the right size
        [self resizeView];
    }
    
    if (self.needToAddToUIWindow) {
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        
        [window addSubview:self];
        self.needToAddToUIWindow = NO;
    }
    
    [self applyBackgroundMaskColor];
    
    if (self.transitionType != TuneMessageTransitionNone) {
        [self.messageContainer.layer removeAllAnimations];
        [self.backgroundMaskView.layer removeAllAnimations];
        
        CATransition *messageTransition = [TuneMessageStyling messageTransitionInWithType:self.transitionType];
        [self.messageContainer.layer addAnimation:messageTransition forKey:kCATransition];
        CATransition *maskTransition = [TuneMessageStyling messageBackgroundMaskTransition];
        [self.backgroundMaskView.layer addAnimation:maskTransition forKey:kCATransition];
        
        [UIView commitAnimations];
        
        self.frame = CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.bounds.size.width, [UIApplication sharedApplication].keyWindow.bounds.size.height);
        [TuneViewUtils centerHorizontallyAndVerticallyInFrame:self.frame onView:_messageContainer];
        
        // Mark the time that the message was show after the animation finishes
        [self performSelector:@selector(recordMessageShown) withObject:nil afterDelay:maskTransition.duration];
    } else {
        // Mark the time that the message was show
        [self recordMessageShown];
    }
}

- (void)dismiss {
    self.parentMessage.visible = NO;
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
    
    if (!self.messageContainer.hidden) {
        self.messageContainer.hidden = YES;
        self.backgroundMaskView.hidden = YES;
        
        if (self.transitionType == TuneMessageTransitionNone) {
            [self removePopUpMessageFromWindow];
        }
        else {
            // Reverse transition
            [self.messageContainer.layer removeAllAnimations];
            [self.backgroundMaskView.layer removeAllAnimations];
            
            CATransition *messageTransition = [TuneMessageStyling messageTransitionOutWithType:self.transitionType];
            [self.messageContainer.layer addAnimation:messageTransition forKey:kCATransition];
            CATransition *maskTransition = [TuneMessageStyling messageBackgroundMaskTransition];
            [self.backgroundMaskView.layer addAnimation:maskTransition forKey:kCATransition];
            
            
            [UIView commitAnimations];
            [self performSelector:@selector(removePopUpMessageFromWindow) withObject:nil afterDelay:messageTransition.duration];
        }
    }
}

- (void)removePopUpMessageFromWindow {
    [self removeFromSuperview];
}

@end
