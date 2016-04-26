//
//  TunePopUpMessageView.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/10/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneBaseInAppMessageView.h"
#import "TuneMessageButton.h"
#import "TuneMessageLabel.h"
#import "TuneMessageAction.h"

@interface TunePopUpMessageView : TuneBaseInAppMessageView {
    
    TunePopUpMessageEdgeStyle _tunePopUpMessageEdgeStyle;
    TuneMessageTransition _transitionType;
    
    UIButton *_backgroundMaskButton;
    UIView *_backgroundMaskView;
    TuneMessageBackgroundMaskType _backgroundMaskType;
    BOOL _showDropShadow;
    UIColor *_messageBackgroundColor;
    UIImageView *_messageBackgroundImageView;
    
    UIView *_messageContainer;
    UIView *_backgroundView;
    UIView *_buttonContainerView;
    int _horizontalPadding;
    int _verticalPadding;
    
    // Content Area
    TuneMessageLabel *_headlineLabelModel;
    UILabel *_headlineLabel;
    TuneMessageLabel *_bodyLabelModel;
    UILabel *_bodyLabel;
    
    TuneMessageAction *_contentAreaAction;
    UIButton *_contentAreaButton;
    
    UIImageView *_messageImageView;
    
    // Action buttons
    int _buttonCount;
    UIColor *_buttonTopSeparatorColor;
    UIColor *_buttonMiddleSeparatorColor;
    
    // CTA & cancel buttons
    TuneMessageButton *_ctaButtonModel;
    TuneMessageButton *_cancelButtonModel;
    
    // Close button
    BOOL _showCloseButton;
    TuneMessageCloseButtonColor _closeButtonColor;
    UIImageView *_closeButtonImageView;
    UIButton *_closeButtonOverlay;
}

- (id)initWithPopUpMessageEdgeStyle:(TunePopUpMessageEdgeStyle)edgeStyle;
- (void)show;
- (void)setBackgroundMaskType:(TuneMessageBackgroundMaskType)maskType;
- (void)showDropShadow;

- (void)setContentAreaAction:(TuneMessageAction *)action;

- (void)setHeadlineLabel:(TuneMessageLabel *)headlineLabel;
- (void)setBodyLabel:(TuneMessageLabel *)bodyLabel;
- (void)setCTAButton:(TuneMessageButton *)ctaButton;
- (void)setCancelbutton:(TuneMessageButton *)cancelButton;

- (void)setMessageBackgroundColor:(UIColor *)backgroundColor;

- (void)setHorizontalPadding:(CGFloat)padding;
- (void)setVerticalPadding:(CGFloat)padding;

- (void)setButtonTopSeparatorColor:(UIColor *)color;
- (void)setButtonMiddleSeparatorColor:(UIColor *)color;

- (void)setImage:(UIImage *)image;
- (void)setBackgroundImage:(UIImage *)image;

// Close button (only when there's no buttons)
- (void)showCloseButton;
- (void)setCloseButtonColor:(TuneMessageCloseButtonColor)closeButtonColor;

- (void)setTransitionType:(TuneMessageTransition)transition;

@end
