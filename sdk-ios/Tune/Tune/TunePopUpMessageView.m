//
//  TunePopUpMessageView.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/10/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TunePopUpMessageView.h"
#import "TuneMessageOrientationState.h"
#import "TunePopUpMessageDefaults.h"
#import "TuneDeviceDetails.h"
#import "TuneViewUtils.h"
#import "TuneLabelUtils.h"
#import "TuneMessageStyling.h"
#import "TuneAnalyticsConstants.h"
#import "TuneSkyhookCenter.h"

@implementation TunePopUpMessageView

- (id)initWithPopUpMessageEdgeStyle:(TunePopUpMessageEdgeStyle)edgeStyle {
#if TARGET_OS_IOS
    [TuneMessageOrientationState startTrackingOrientation];

    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(deviceOrientationDidChange:)
                                              name:UIApplicationDidChangeStatusBarOrientationNotification
                                            object:nil];
#endif
    _tunePopUpMessageEdgeStyle = edgeStyle;
    
    self = [super init];
    self.backgroundColor = [UIColor clearColor];
    
    [self initBackgroundMask];
    [self adjustBackgroundMaskSizeToFitFrame];
    
    if (self) {
        // Initialization code
        _horizontalPadding = TunePopUpMessageDefaultPaddingHorizontal;
        _transitionType = TunePopUpMessageDefaultTransition;
        _verticalPadding = TunePopUpMessageDefaultPaddingVertical;
        _showCloseButton = NO;
        _closeButtonColor = TunePopUpMessageCloseButtonColorRed;
        _showDropShadow = NO;
    }
    
    return self;
}

- (void)dealloc {
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
}

#if TARGET_OS_IOS

- (void)deviceOrientationDidChange:(TuneSkyhookPayload *)payload {
    if ([TuneDeviceDetails appIsRunningIniOS8OrAfter]) {
        if ([TuneMessageOrientationState currentOrientationIsSupportedByApp]) {
            CGSize currScreenBounds = [TuneMessageOrientationState getCalculatedWindowSizeForCurrentOrientation];
            self.frame = CGRectMake(0,0,currScreenBounds.width,currScreenBounds.height);
            [TuneViewUtils centerHorizontallyAndVerticallyInFrame:self.frame onView:_messageContainer];
        }
    }
    else {
        NSNumber *angle = [TuneMessageOrientationState calculateAngleToRotateView];
        
        if (angle) {
            self.layer.transform = CATransform3DMakeRotation([angle floatValue], 0, 0.0, 1.0);
        }
    }
    
    if (_showCloseButton) {
        [self addCloseButtonOverlayToContainer];
    }
    
    [self adjustBackgroundMaskSizeToFitFrame];
}

#endif

- (void)initBackgroundMask {
    _backgroundMaskView = [[UIView alloc] initWithFrame:self.frame];
    _backgroundMaskView.backgroundColor = [TunePopUpMessageDefaults defaultPopUpBackgroundMaskColor];
    _backgroundMaskView.alpha = 0.65;
    [self addSubview:_backgroundMaskView];
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
    
    _backgroundMaskView.frame = CGRectMake(originX,originY,largerSide,largerSide);
}

#pragma mark - Transition

- (void)setTransitionType:(TuneMessageTransition)transition {
    _transitionType = transition;
}

#pragma mark - Layout
- (void)layoutPopUpView {
    
    CGFloat messageWidth;
    CGFloat messageHeight;
    
    // Buttons
    _buttonCount = 0;
    if (_ctaButtonModel) {
        _buttonCount++;
    }
    if (_cancelButtonModel) {
        _buttonCount++;
    }
    
    if (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPhone) {
        messageWidth = TunePopUpMessageDefaultWidthOnPhone;
        messageHeight = TunePopUpMessageDefaultHeightOnPhone;
    }
    else {
        messageWidth = TunePopUpMessageDefaultWidthOnTablet;
        messageHeight = TunePopUpMessageDefaultHeightOnTablet;
    }
    
    CGFloat xOrigin = ceil(([UIScreen mainScreen].bounds.size.width - messageWidth)/2);
    CGFloat yOrigin =  ceil(([UIScreen mainScreen].bounds.size.height - messageHeight)/2);
    
    CGRect _messageContainerFrame = CGRectMake(xOrigin, yOrigin, messageWidth, messageHeight + TunePopUpMessageShadowHeight);
    _messageContainer = [[UIView alloc] initWithFrame:_messageContainerFrame];
    [self addSubview:_messageContainer];
    
    _backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, messageWidth, messageHeight)];
    _backgroundView.backgroundColor = [TunePopUpMessageDefaults defaultPopUpBackgroundColor];
    _backgroundView.layer.masksToBounds = YES;
    [_messageContainer addSubview:_backgroundView];
    
    if (_messageBackgroundColor) {
        _backgroundView.backgroundColor = _messageBackgroundColor;
    }
    
    if (_messageBackgroundImageView) {
        [_backgroundView addSubview:_messageBackgroundImageView];
    }
    
    CGFloat currY = _verticalPadding;
    CGFloat contentWidth = _backgroundView.frame.size.width - _horizontalPadding - _horizontalPadding;
    
    // Image view
    if (_messageImageView) {
        _messageImageView.frame = CGRectMake(0, currY, contentWidth, TunePopUpMessageDefaultImageHeight);
        [TuneViewUtils centerHorizontallyInFrame:_backgroundView.frame onView:_messageImageView];
        [TuneViewUtils setY:_verticalPadding onView:_messageImageView];
        [_backgroundView addSubview:_messageImageView];
        currY += _messageImageView.frame.size.height + TunePopUpMessageDefaultContentPadding;
    }
    
    // Headline label
    if (_headlineLabelModel) {
        _headlineLabel = [_headlineLabelModel getUILabelWithFrame:CGRectMake(_horizontalPadding, currY, contentWidth, 400)];
        [TuneLabelUtils adjustFrameHeightToTextHeightOnLabel:_headlineLabel];
        [_backgroundView addSubview:_headlineLabel];
        currY += _headlineLabel.frame.size.height + TunePopUpMessageDefaultContentPadding;
    }
    
    // Message label
    if (_bodyLabelModel) {
        _bodyLabel = [_bodyLabelModel getUILabelWithFrame:CGRectMake(_horizontalPadding, currY, contentWidth, 400)];
        [TuneLabelUtils adjustFrameHeightToTextHeightOnLabel:_bodyLabel];
        [_backgroundView addSubview:_bodyLabel];
        //
        // Commented this out until we officially support the button seperator
        //
        //currY += _bodyLabel.frame.size.height;
    }
    
    // Adjust the screen size
    [self resizeView];
    
    // Close button
    if (_showCloseButton) {
        
        _closeButtonImageView = [[UIImageView alloc] initWithImage:[TuneMessageStyling closeButtonImageByCloseButtonColor:_closeButtonColor]];
        _closeButtonImageView.frame = CGRectMake(TunePopUpMessageDefaultWidthOnPhone - TunePopUpCloseButtonOffset - 35,(-1 * TunePopUpCloseButtonOffset),TunePopUpCloseButtonSize,TunePopUpCloseButtonSize);
        [_closeButtonImageView setContentMode:UIViewContentModeScaleAspectFit];
        
        [_messageContainer addSubview:_closeButtonImageView];
        
        [self addCloseButtonOverlayToContainer];
    }
    
    // Background Image
    if (_messageBackgroundImageView) {
        _messageBackgroundImageView.frame = CGRectMake(0, 0, TunePopUpMessageDefaultWidthOnPhone, TunePopUpMessageDefaultHeightOnPhone);
    }
    
    // Edge style
    if (_tunePopUpMessageEdgeStyle == TunePopUpMessageRoundedCorners) {
        self.layer.cornerRadius = TunePopUpMessageDefaultCornerRadius;
        _backgroundView.layer.cornerRadius = TunePopUpMessageDefaultCornerRadius;
    }
    
    // Shadow
    if (_showDropShadow) {
        _messageContainer.layer.shadowRadius = 5;
        _messageContainer.layer.shadowOffset = CGSizeMake(10, 10);
        _messageContainer.layer.masksToBounds = NO; // NOTE: This has to be NO to do the shadow
        _messageContainer.layer.shadowOpacity = 0.3;
    }
    
    // Content area button
    if ( (_contentAreaAction) || (_buttonCount == 0) ) {
        _contentAreaButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_contentAreaButton layoutIfNeeded];
        _contentAreaButton.backgroundColor = [UIColor clearColor];
        _contentAreaButton.frame = CGRectMake(0,0,_messageContainer.frame.size.width,TunePopUpMessageDefaultHeightOnPhone);
        [_messageContainer addSubview:_contentAreaButton];
        [_contentAreaButton addTarget:self
                               action:@selector(handleContentAreaButtonPressed)
                     forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (_buttonCount > 0) {
        //
        // Commented this out until we officially support the button seperator
        //
        //CGFloat cancelButtonRightXCoordinate = 0;
        
        CGFloat buttonOriginY = _backgroundView.frame.size.height - TunePopUpMessageButtonHeight - 1;
        _buttonContainerView = [[UIView alloc] initWithFrame:CGRectMake(0,buttonOriginY,_backgroundView.frame.size.width,TunePopUpMessageButtonHeight)];
        
        // CTA button
        UIButton *ctaButton = [_ctaButtonModel getUIButtonWithFrame:CGRectMake(0,buttonOriginY,_backgroundView.frame.size.width,TunePopUpMessageButtonHeight)];
        
        [_buttonContainerView addSubview:ctaButton];
        [ctaButton addTarget:self
                      action:@selector(handleCTAButtonPressed)
            forControlEvents:UIControlEventTouchUpInside];
        
        // Cancel button
        if (_cancelButtonModel) {
            UIButton *cancelButton = [_cancelButtonModel getUIButtonWithFrame:CGRectMake(0,buttonOriginY,_backgroundView.frame.size.width,TunePopUpMessageButtonHeight)];
            [cancelButton layoutIfNeeded];
            
            CGFloat buttonWidth = ceil(_backgroundView.frame.size.width / 2);
            cancelButton.frame = CGRectMake(0, TunePopUpMessageButtonBorderWidth, buttonWidth, TunePopUpMessageButtonHeight);
            ctaButton.frame = CGRectMake([TuneViewUtils rightXCoordinateOnView:cancelButton], TunePopUpMessageButtonBorderWidth, buttonWidth, TunePopUpMessageButtonHeight);
            
            //
            // Commented this out until we officially support the button seperator
            //
            //cancelButtonRightXCoordinate = [cancelButton rightXCoordinate];
            
            [cancelButton addTarget:self
                             action:@selector(handleCancelButtonPressed)
                   forControlEvents:UIControlEventTouchUpInside];
            
            [_buttonContainerView addSubview:cancelButton];
        }
        else {
            ctaButton.frame = CGRectMake(0, TunePopUpMessageButtonBorderWidth, _backgroundView.frame.size.width, TunePopUpMessageButtonHeight);
        }
        
        /*
         
         //
         // Commented this out until we officially support the button seperator
         //
         
         if (_buttonMiddleSeparatorColor) {
         UIView *buttonSeperatorView = [[UIView alloc] initWithFrame:CGRectMake(cancelButtonRightXCoordinate, 0 , TunePopUpMessageButtonBorderWidth, TunePopUpMessageButtonHeight + TunePopUpMessageButtonBorderWidth)];
         buttonSeperatorView.backgroundColor = _buttonMiddleSeparatorColor;
         [_buttonContainerView addSubview:buttonSeperatorView];
         }
         
         if (_buttonTopSeparatorColor) {
         UIView *buttonTopView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _backgroundView.frame.size.width, TunePopUpMessageButtonBorderWidth)];
         buttonTopView.backgroundColor = _buttonTopSeparatorColor;
         [_buttonContainerView addSubview:buttonTopView];
         }
         */
        
        [_backgroundView addSubview:_buttonContainerView];
    }
    self.needToLayoutView = NO;
}

- (void)addCloseButtonOverlayToContainer {
    if (_closeButtonOverlay && _closeButtonOverlay.superview != nil) {
        [_closeButtonOverlay removeFromSuperview];
    }
    
    _closeButtonOverlay = [UIButton buttonWithType:UIButtonTypeCustom];
    [_closeButtonOverlay layoutIfNeeded];
    
    _closeButtonOverlay.backgroundColor = [UIColor clearColor];
    
    CGFloat overlayWidth = _closeButtonImageView.frame.size.width + 20;
    CGFloat overlayHeight = _closeButtonImageView.frame.size.height + 20;
    
    _closeButtonOverlay.frame = CGRectMake(TunePopUpMessageDefaultWidthOnPhone - (overlayWidth), 0, overlayWidth, overlayHeight);

    [_closeButtonOverlay addTarget:self
                           action:@selector(handleCloseButtonPressed)
                 forControlEvents:UIControlEventTouchUpInside];
    [_messageContainer addSubview:_closeButtonOverlay];
}


- (void)setHorizontalPadding:(CGFloat)padding {
    _horizontalPadding = padding;
}

- (void)setVerticalPadding:(CGFloat)padding {
    _verticalPadding = padding;
}

- (void)setBackgroundMaskType:(TuneMessageBackgroundMaskType)maskType {
    _backgroundMaskType = maskType;
}

- (void)showDropShadow {
    _showDropShadow = YES;
}

- (void)applyBackgroundMaskColor {
    if (_backgroundMaskType == TuneMessageBackgroundMaskTypeDark) {
        _backgroundMaskView.backgroundColor = [UIColor blackColor];
    }
    else if (_backgroundMaskType == TuneMessageBackgroundMaskTypeLight) {
        _backgroundMaskView.backgroundColor = [UIColor whiteColor];
    }
    else if (_backgroundMaskType == TuneMessageBackgroundMaskTypeBlur) {
        // NOTE: This isn't supported yet. 
        _backgroundMaskView.backgroundColor = [UIColor whiteColor];
    }
    else if (_backgroundMaskType == TuneMessageBackgroundMaskTypeNone) {
        _backgroundMaskView.backgroundColor = [UIColor clearColor];
    }
}

- (void)resizeView {
    
    // Adjust size of view and backgroundView to fit text
    CGFloat totalContentAreaSize = TunePopUpMessageDefaultHeightOnPhone;
    CGFloat totalMessageSizeWithButton = totalContentAreaSize;
    if (_buttonCount > 0) {
        totalMessageSizeWithButton += TunePopUpMessageButtonHeight;
    }
    
    if (totalMessageSizeWithButton > (TunePopUpMessageDefaultHeightOnPhone + TunePopUpMessageButtonHeight)) {
        totalMessageSizeWithButton = TunePopUpMessageDefaultHeightOnPhone + TunePopUpMessageButtonHeight;
    }
    
    [TuneViewUtils setHeight:totalMessageSizeWithButton onView:_backgroundView];
    [TuneViewUtils setHeight:totalMessageSizeWithButton onView:_messageContainer];
    
    // Center vertically
    CGFloat viewOrigin = ceil(([UIScreen mainScreen].bounds.size.height - totalMessageSizeWithButton)/2);
    [TuneViewUtils setY:viewOrigin onView:_messageContainer];
    
}

#pragma mark - Content Area

- (void)setHeadlineLabel:(TuneMessageLabel *)headlineLabel {
    _headlineLabelModel = headlineLabel;
}

- (void)setBodyLabel:(TuneMessageLabel *)bodyLabel {
    _bodyLabelModel = bodyLabel;
}

- (void)setContentAreaAction:(TuneMessageAction *)action {
    _contentAreaAction = action;
}


- (void)setImage:(UIImage *)image {
    _messageImageView = [[UIImageView alloc] initWithImage:image];
    _messageImageView.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)setBackgroundImage:(UIImage *)image {
    _messageBackgroundImageView = [[UIImageView alloc] initWithImage:image];
    _messageBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
}

- (UIImageView *)getBackgroundImageView {
    return _messageBackgroundImageView;
}

- (void)setMessageBackgroundColor:(UIColor *)backgroundColor {
    _messageBackgroundColor = backgroundColor;
}

#pragma mark - CTA & Cancel button

- (void)setCTAButton:(TuneMessageButton *)ctaButton {
    _ctaButtonModel = ctaButton;
}

- (void)setCancelbutton:(TuneMessageButton *)cancelButton {
    _cancelButtonModel = cancelButton;
}

// Separator
- (void)setButtonTopSeparatorColor:(UIColor *)color {
    _buttonTopSeparatorColor = color;
}

- (void)setButtonMiddleSeparatorColor:(UIColor *)color {
    _buttonMiddleSeparatorColor = color;
}

#pragma mark - Close button

- (void)showCloseButton {
    _showCloseButton = YES;
}

- (void)setCloseButtonColor:(TuneMessageCloseButtonColor)closeButtonColor {
    _closeButtonColor = closeButtonColor;
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
    
    if (_transitionType != TuneMessageTransitionNone) {
        [_messageContainer.layer removeAllAnimations];
        [_backgroundMaskView.layer removeAllAnimations];
        
        CATransition *messageTransition = [TuneMessageStyling messageTransitionInWithType:_transitionType];
        [_messageContainer.layer addAnimation:messageTransition forKey:kCATransition];
        CATransition *maskTransition = [TuneMessageStyling messageBackgroundMaskTransition];
        [_backgroundMaskView.layer addAnimation:maskTransition forKey:kCATransition];
        
        [UIView commitAnimations];
        
        if ([TuneDeviceDetails appIsRunningIniOS8OrAfter]) {
            self.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
            [TuneViewUtils centerHorizontallyAndVerticallyInFrame:self.frame onView:_messageContainer];
        }
        else {
            // just in case the devices isn't in portrait when this is first show, let's check if we need to rotate
            NSNumber *angle = [TuneMessageOrientationState calculateAngleToRotateViewFromPortrait];
            if (angle) {
                self.layer.transform = CATransform3DMakeRotation([angle floatValue], 0, 0.0, 1.0);
                [self adjustBackgroundMaskSizeToFitFrame];
            }
        }
        
        // Mark the time that the message was show after the animation finishes
        [self performSelector:@selector(recordMessageShown) withObject:nil afterDelay:maskTransition.duration];
    }
}

- (void)handleCloseButtonPressed {
    [self recordMessageDismissedWithAction:TUNE_IN_APP_MESSAGE_ACTION_CLOSE_BUTTON_PRESSED];
    [self dismiss];
}

- (void)handleContentAreaButtonPressed {
    [self recordMessageDismissedWithAction:TUNE_IN_APP_MESSAGE_ACTION_CONTENT_AREA_PRESSED];
    if (_contentAreaAction) {
        [_contentAreaAction performAction];
    }
    [self dismiss];
}

- (void)handleCTAButtonPressed {
    [self recordMessageDismissedWithAction:TUNE_IN_APP_MESSAGE_ACTION_CTA_BUTTON_PRESSED];
    [_ctaButtonModel.action performAction];
    [self dismiss];
}

- (void)handleCancelButtonPressed {
    [self recordMessageDismissedWithAction:TUNE_IN_APP_MESSAGE_ACTION_CANCEL_BUTTON_PRESSED];
    [_cancelButtonModel.action performAction];
    [self dismiss];
}

- (void)dismiss {
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
    
    if (!_messageContainer.hidden) {
        
        _messageContainer.hidden = YES;
        _backgroundMaskView.hidden = YES;
        
        if (_transitionType == TuneMessageTransitionNone) {
            [self removePopUpMessageFromWindow];
        }
        else {
            // Reverse transition
            [_messageContainer.layer removeAllAnimations];
            [_backgroundMaskView.layer removeAllAnimations];
            
            CATransition *messageTransition = [TuneMessageStyling messageTransitionOutWithType:_transitionType];
            [_messageContainer.layer addAnimation:messageTransition forKey:kCATransition];
            CATransition *maskTransition = [TuneMessageStyling messageBackgroundMaskTransition];
            [_backgroundMaskView.layer addAnimation:maskTransition forKey:kCATransition];
            
            
            [UIView commitAnimations];
            [self performSelector:@selector(removePopUpMessageFromWindow) withObject:nil afterDelay:messageTransition.duration];
        }
    }
}

- (void)removePopUpMessageFromWindow {
    [self removeFromSuperview];
}

@end
