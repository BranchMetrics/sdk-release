//
//  TuneBaseSlideInMessageView.h
//  
//
//  Created by Matt Gowie on 9/3/15.
//
//

#import "TuneBaseInAppMessageView.h"
#import "TuneMessageAction.h"
#import "TuneMessageButton.h"
#import "TuneMessageLabel.h"
#import "TuneMessageImageBundle.h"
#import "TuneSkyhookPayload.h"

@interface TuneBaseSlideInMessageView : TuneBaseInAppMessageView {
    
    // Configuration
    TuneMessageLocationType _locationType;
    CGFloat _statusBarOffset;
    NSNumber *_duration;
    
    // Layout state
    BOOL _lastAninmation;
    
    // Views
    UIView *_containerViewPortrait;
    UIView *_containerViewPortraitUpsideDown;
    UIView *_containerViewLandscapeRight;
    UIView *_containerViewLandscapeLeft;
    
    // Background
    UIColor *_messageBackgroundColor;
    
    // Background Images
    UIImage *_portraitImage;
    UIImage *_landscapeImage;
    
    // Message action
    TuneMessageAction *_phoneAction;
    TuneMessageAction *_tabletAction;
    
    // Message Label
    TuneMessageLabel *_messageLabelPortrait;
    TuneMessageLabel *_messageLabelPortraitUpsideDown;
    TuneMessageLabel *_messageLabelLandscapeRight;
    TuneMessageLabel *_messageLabelLandscapeLeft;
    
    // CTA Image (only for tablet)
    UIImage *_ctaImage;
    TuneMessageButton *_ctaButton;
    
    // Close Button
    UIImageView *_closeButtonImageView;
    UIButton *_closeButtonOverlay;
    BOOL _showCloseButton;
    TuneMessageCloseButtonColor _closeButtonColor;
    
#if TARGET_OS_IOS
    // Orientation
    UIInterfaceOrientation _lastOrientation;
#endif
    // Assets
    TuneMessageImageBundle *_backgroundImageBundle;
}

- (id)initWithLocationType:(TuneMessageLocationType)locationType;

// Show / Dismiss
- (void)show;

#if TARGET_OS_IOS
- (void)showOrientation:(UIInterfaceOrientation)deviceOrientation;
- (void)dismissOrientation:(UIInterfaceOrientation)orientation;
#else
- (void)showPortraitOrientation;
- (void)dismissPortraitOrientation;
#endif

// Asset setters
- (void)setDisplayDuration:(NSNumber *)duration;
- (void)setBackgroundImageWithImageBundle:(TuneMessageImageBundle *)imageBundle;
- (void)setMessageBackgroundColor:(UIColor *)backgroundColor;
- (void)setMessageLabelPortrait:(TuneMessageLabel *)labelModel;
- (void)setMessageLabelPortraitUpsideDown:(TuneMessageLabel *)labelModel;
- (void)setMessageLabelLandscapeRight:(TuneMessageLabel *)labelModel;
- (void)setMessageLabelLandscapeLeft:(TuneMessageLabel *)labelModel;

// Labels
- (void)addMessageLabelToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation withLabelModel:(TuneMessageLabel *)labelModel;

// Close button
- (void)hideCloseButton;
- (void)setCloseButtonColor:(TuneMessageCloseButtonColor)closeButtonColor;
- (void)addCloseButtonToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation;
- (void)addCloseButtonClickOverlayToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation;
- (void)closeButtonTouched;

// CTA Button/Image
- (void)setCTAImage:(UIImage *)imageBundle;
- (void)setCTAButton:(TuneMessageButton *)button;
- (void)addCTAButtonToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation;
- (void)addCTAImageToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation;

// Action setters
- (void)setTabletAction:(TuneMessageAction *)action;
- (void)setPhoneAction:(TuneMessageAction *)action;
- (void)addMessageClickOverlayActionToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation;
- (void)messageClickOverlayTouched:(id)sender;

#if TARGET_OS_IOS
// Layout Containers (Overridden)

- (void)layoutMessageContainerForOrientation:(UIInterfaceOrientation)deviceOrientation;

- (void)layoutBackgroundImageForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation;
- (void)layoutMessageForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation;
- (void)layoutCTAForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation;
- (void)layoutCloseButtonForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation;
- (void)addMessageClickOverlayActionForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation;
- (void)addBackgroundColorForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation;
- (void)buildMessageContainerForOrientation:(UIInterfaceOrientation)deviceOrientation;

#else

- (void)layoutMessageContainer;

- (void)layoutBackgroundImage;
- (void)layoutMessage;
- (void)layoutCTA;
- (void)layoutCloseButton;
- (void)addMessageClickOverlayAction;
- (void)addBackgroundColor;
- (void)buildMessageContainer;

#endif


#if TARGET_OS_IOS

// Orientation

- (void)deviceOrientationDidChange:(TuneSkyhookPayload *)payload;
- (void)handleTransitionToCurrentOrientation:(NSNumber *)currentOrientationAsNSNumber;

#endif

@end
