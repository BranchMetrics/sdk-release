//
//  TuneBaseSlideInMessageView.m
//  
//
//  Created by Matt Gowie on 9/3/15.
//
//

#import "TuneBaseSlideInMessageView.h"
#import "TuneSlideInMessageDefaults.h"
#import "TuneDeviceDetails.h"
#import "TuneMessageOrientationState.h"
#import "TuneInAppMessageConstants.h"
#import "TuneAnalyticsConstants.h"
#import "TuneMessageStyling.h"
#import "TuneViewUtils.h"
#import "TuneSkyhookCenter.h"

@implementation TuneBaseSlideInMessageView

#pragma mark - Initialization

- (id)initWithLocationType:(TuneMessageLocationType)locationType {
    
#if TARGET_OS_IOS
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(deviceOrientationDidChange:)
                                              name:UIDeviceOrientationDidChangeNotification
                                            object:nil];
#endif
    
    self = [super init];
    
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        
        _locationType = locationType;
        
#if TARGET_OS_IOS
        _statusBarOffset = [UIApplication sharedApplication].statusBarHidden ? 0 : 20;
#else
        _statusBarOffset = 0;
#endif
        
        [self initDefaults];
    }
    
    return self;
}

- (void)dealloc {
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
}

- (void)initDefaults {
    _showCloseButton = !SlideInMessageDefaultCloseButtonHidden;
    _lastAninmation = NO;
    _messageBackgroundColor = [TuneSlideInMessageDefaults slideInMessageDefaultMessageBackgroundColor];
    _closeButtonColor = SlideInMessageDefaultCloseButtonColor;
}

#if TARGET_OS_IOS

- (void)layoutMessageContainerForOrientation:(UIDeviceOrientation)deviceOrientation {
    [self buildMessageContainerForOrientation:deviceOrientation];
    [self addBackgroundColorForDeviceOrientation:deviceOrientation];
    [self layoutBackgroundImageForDeviceOrientation:deviceOrientation];
    [self layoutCTAForDeviceOrientation:deviceOrientation];
    [self layoutCloseButtonForDeviceOrientation:deviceOrientation];
    [self layoutMessageForDeviceOrientation:deviceOrientation];
    [self addMessageClickOverlayActionForDeviceOrientation:deviceOrientation];
    
    // This is not used for this type of slide-in. We build the views if the containers are nil.
    self.needToLayoutView = NO;
}

#else

- (void)layoutMessageContainer {
    [self buildMessageContainer];
    [self addBackgroundColor];
    [self layoutBackgroundImage];
    [self layoutCTA];
    [self layoutCloseButton];
    [self layoutMessage];
    [self addMessageClickOverlayAction];
    
    // This is not used for this type of slide-in. We build the views if the containers are nil.
    self.needToLayoutView = NO;
}

#endif

#pragma mark - Show

- (void)show {
    if (self.needToAddToUIWindow) {
        [[[UIApplication sharedApplication] keyWindow] addSubview:self];
        self.needToAddToUIWindow = NO;
    }
    
#if TARGET_OS_IOS
    _lastOrientation = [TuneMessageOrientationState getCurrentOrientation];
    
    [self showOrientation:_lastOrientation];
#else
    [self showPortraitOrientation];
#endif
    
    [self recordMessageShown];
    
    if ([_duration floatValue] > 0)
    {
        [self performSelector:@selector(markDismissedAfterDurationAndDismiss) withObject:nil afterDelay:[_duration floatValue]];
    }
}

#pragma mark - Dismiss

- (void)markDismissedAfterDurationAndDismiss {
    [self recordMessageDismissedWithAction:TUNE_IN_APP_MESSAGE_ACTION_DISMISSED_AFTER_DURATION];
    [self dismiss];
}

- (void)dismiss {
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
    // this allows us to catch the last animation
    _lastAninmation = YES;
#if TARGET_OS_IOS
    [self dismissOrientation:_lastOrientation];
#else
    [self dismissPortraitOrientation];
#endif
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    // This is the final animation remove from superview
    if (_lastAninmation) {
        [self performSelector:@selector(removeSlideInMessageFromWindow) withObject:nil afterDelay:0.5];
    }
}

- (void)removeSlideInMessageFromWindow {
    [self removeFromSuperview];
    _lastAninmation = NO;
    self.needToAddToUIWindow = YES;
}

#pragma mark - Setters

- (void)setDisplayDuration:(NSNumber *)duration {
    _duration = duration;
}

- (void)setMessageLabelPortrait:(TuneMessageLabel *)labelModel {
    _messageLabelPortrait = labelModel;
}

- (void)setMessageLabelPortraitUpsideDown:(TuneMessageLabel *)labelModel{
    _messageLabelPortraitUpsideDown = labelModel;
}

- (void)setMessageLabelLandscapeRight:(TuneMessageLabel *)labelModel{
    _messageLabelLandscapeRight = labelModel;
}

- (void)setMessageLabelLandscapeLeft:(TuneMessageLabel *)labelModel{
    _messageLabelLandscapeLeft = labelModel;
}

- (void)setCTAImage:(UIImage *)image {
    _ctaImage = image;
}

- (void)setCTAButton:(TuneMessageButton *)button {
    _ctaButton = button;
}

#pragma mark - Message Labels

- (void)addMessageLabelToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation withLabelModel:(TuneMessageLabel *)labelModel {
    CGRect closeButtonClickOverlayFrame = [TuneSlideInMessageDefaults slideInMessageCloseButtonClickOverlayFrameByDeviceOrientation:orientation];
    CGFloat horizontalPadding = [TuneSlideInMessageDefaults slideInMessageDefaultMessageAreaHorizontalPaddingByDeviceOrientation:orientation];
    CGFloat totalMessageWidth = [TuneSlideInMessageDefaults slideInMessageDefaultWidthByDeviceOrientation:orientation];
    
    
    CGFloat ctaImageAreaWidth = 0;
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
        case TuneMessageOrientationPhonePortrait_568:
        case TuneMessageOrientationPhonePortraitUpsideDown_568:
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
        case TuneMessageOrientationPhonePortrait_667:
        case TuneMessageOrientationPhonePortraitUpsideDown_667:
        case TuneMessageOrientationPhonePortrait_736:
        case TuneMessageOrientationPhonePortraitUpsideDown_736:
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            ctaImageAreaWidth = 0;
            break;
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
            if (_ctaImage) {
                ctaImageAreaWidth = [TuneSlideInMessageDefaults slideInMessageDefaultCTAImageAreaWidthByDeviceOrientation:orientation] + (horizontalPadding *2);
            }
            else {
                ctaImageAreaWidth = 0;
            }
            break;
        case TuneMessageOrientationNA:
            break;
    }
    
    CGFloat messageLabelWidth = totalMessageWidth - closeButtonClickOverlayFrame.size.width - (horizontalPadding * 2) - ctaImageAreaWidth;
    CGFloat messageLabelHeight = [TuneSlideInMessageDefaults slideInMessageDefaultHeightByDeviceOrientation:orientation];
    
    UILabel *messageLabel = [labelModel getUILabelWithFrame:CGRectMake(horizontalPadding, 0, messageLabelWidth, messageLabelHeight)];
    messageLabel.numberOfLines = [TuneSlideInMessageDefaults slideInMesasgeDefaultMessageNumberOfLinesByDeviceOrientation:orientation];
    
    [container addSubview:messageLabel];
}

#pragma mark - CTA Button

- (void)addCTAButtonToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation {
    UIView *ctaButtonView = [[UIView alloc] initWithFrame:[TuneSlideInMessageDefaults slideInMessageCTAButtonFrameByDeviceOrientation:orientation]];
    ctaButtonView.backgroundColor = _ctaButton.buttonColor;
    if (_ctaButton.backgroundImage) {
        UIImageView *ctaImageView = [[UIImageView alloc] initWithImage:_ctaButton.backgroundImage];
        ctaImageView.frame = CGRectMake(0,0, ctaButtonView.frame.size.width, ctaButtonView.frame.size.height);
        [ctaButtonView addSubview:ctaImageView];
    }
    UILabel *ctaButtonLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, ctaButtonView.frame.size.width - 10, ctaButtonView.frame.size.height)];
    ctaButtonLabel.font = _ctaButton.title.font;
    ctaButtonLabel.adjustsFontSizeToFitWidth = YES;
    ctaButtonLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
    ctaButtonLabel.textColor = _ctaButton.title.textColor;
    ctaButtonLabel.text = _ctaButton.title.text;
    ctaButtonLabel.textAlignment = NSTextAlignmentCenter;
    [ctaButtonView addSubview:ctaButtonLabel];
    [container addSubview:ctaButtonView];
}

- (void)addCTAImageToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation {
    UIImageView *ctaImageView = [[UIImageView alloc] initWithImage:_ctaImage];
    ctaImageView.frame = [TuneSlideInMessageDefaults slideInMessageCTAImageFrameByDeviceOrientation:orientation];
    [container addSubview:ctaImageView];
}

#pragma mark - Close Button

- (void)hideCloseButton {
    _showCloseButton = NO;
}

- (void)setCloseButtonColor:(TuneMessageCloseButtonColor)closeButtonColor {
    _closeButtonColor = closeButtonColor;
}

- (void)addCloseButtonToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation {
    UIImageView *closeButtonImageView = [[UIImageView alloc] initWithImage:[TuneMessageStyling closeButtonImageByCloseButtonColor:_closeButtonColor]];
    closeButtonImageView.frame = [TuneSlideInMessageDefaults slideInMessageCloseButtonFrameByDeviceOrientation:orientation];
    [container addSubview:closeButtonImageView];
}

- (void)addCloseButtonClickOverlayToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation {
    UIButton *clickOverlay = [UIButton buttonWithType:UIButtonTypeCustom];
    [clickOverlay layoutIfNeeded];
    clickOverlay.frame = [TuneSlideInMessageDefaults slideInMessageCloseButtonClickOverlayFrameByDeviceOrientation:orientation];
    clickOverlay.backgroundColor = [UIColor clearColor];
    clickOverlay.userInteractionEnabled = YES;
    [clickOverlay addTarget:self action:@selector(closeButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:clickOverlay];
}

- (void)closeButtonTouched {
    [self recordMessageDismissedWithAction:TUNE_IN_APP_MESSAGE_ACTION_CLOSE_BUTTON_PRESSED];
    [self dismiss];
}

#pragma mark - Action

- (void)setTabletAction:(TuneMessageAction *)action {
    _tabletAction = action;
}

- (void)setPhoneAction:(TuneMessageAction *)action {
    _phoneAction = action;
}

- (void)addMessageClickOverlayActionToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation {
    UIButton *clickOverlay = [UIButton buttonWithType:UIButtonTypeCustom];
    [clickOverlay layoutIfNeeded];
    
    CGRect closeButtonClickOverlayFrame = CGRectZero;
    if (_showCloseButton) {
        closeButtonClickOverlayFrame = [TuneSlideInMessageDefaults slideInMessageCloseButtonClickOverlayFrameByDeviceOrientation:orientation];
    }
    
    // Calculate frame
    CGFloat clickOverlayWidth = [TuneSlideInMessageDefaults slideInMessageDefaultWidthByDeviceOrientation:orientation] - closeButtonClickOverlayFrame.size.width;
    CGFloat clickOverlayHeight = [TuneSlideInMessageDefaults slideInMessageDefaultHeightByDeviceOrientation:orientation];
    
    clickOverlay.frame = CGRectMake(0, 0, clickOverlayWidth, clickOverlayHeight);
    clickOverlay.backgroundColor = [UIColor clearColor];
    [clickOverlay addTarget:self action:@selector(messageClickOverlayTouched:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:clickOverlay];
}

- (void)messageClickOverlayTouched:(id)sender {
    [self recordMessageDismissedWithAction:TUNE_IN_APP_MESSAGE_ACTION_MESSAGE_PRESSED];
    
    if ([TuneDeviceDetails runningOnPhone]) {
        if (_phoneAction) {
            [_phoneAction performAction];
        }
    }
    else {
        if (_tabletAction) {
            [_tabletAction performAction];
        }
    }
    [self dismiss];
}

#pragma mark - Background Images + Color

- (void)setBackgroundImageWithImageBundle:(TuneMessageImageBundle *)imageBundle {
    _backgroundImageBundle = imageBundle;
    [self setBackgroundImagesFromImageBundle];
}

- (void)setMessageBackgroundColor:(UIColor *)color {
    _messageBackgroundColor = color;
}

- (void)setBackgroundImagesFromImageBundle {
    if ([TuneDeviceDetails runningOnPhone]) {
        if (_backgroundImageBundle.phonePortraitImage) {
            _portraitImage =_backgroundImageBundle.phonePortraitImage;
        }
        
        if (_backgroundImageBundle.phoneLandscapeImage) {
            _landscapeImage = _backgroundImageBundle.phoneLandscapeImage;
        }
    }
    else {
        if (_backgroundImageBundle.tabletPortraitImage) {
            _portraitImage = _backgroundImageBundle.tabletPortraitImage;
        }
        
        if (_backgroundImageBundle.tabletLandscapeImage) {
            _landscapeImage = _backgroundImageBundle.tabletLandscapeImage;
        }
    }
}

#pragma mark - Orientation

#if TARGET_OS_IOS

- (void)handleTransitionToCurrentOrientation:(NSNumber *)currentOrientationAsNSNumber {
    UIDeviceOrientation currentOrientation = [currentOrientationAsNSNumber intValue];
    [self showOrientation:currentOrientation];
    _lastOrientation = currentOrientation;
}

#endif

#pragma mark - Overriden by Subclass

#if TARGET_OS_IOS

- (void)showOrientation:(UIDeviceOrientation)deviceOrientation {
    ErrorLog(@"showOrientation: should not be called on the base class");
}

- (void)addMessageClickOverlayActionForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    ErrorLog(@"addMessageClickOverlayActionForDeviceOrientation: should not be called on the base class");
}

- (void)deviceOrientationDidChange:(TuneSkyhookPayload *)payload {
    ErrorLog(@"deviceOrientationDidChange: should not be called on the base class");
}

- (void)dismissOrientation:(UIDeviceOrientation)orientation {
    ErrorLog(@"dismissOrientation: should not be called on the base class");
}

- (void)buildMessageContainerForOrientation:(UIDeviceOrientation)deviceOrientation {
    ErrorLog(@"buildMessageContainerForOrientation: should not be called on the base class");
}

- (void)layoutCTAForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    ErrorLog(@"layoutCTAForDeviceOrientation: should not be called on the base class");
}

- (void)addBackgroundColorForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    ErrorLog(@"addBackgroundColorForDeviceOrientation: should not be called on the base class");
}

- (void)layoutBackgroundImageForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    ErrorLog(@"layoutBackgroundImageForDeviceOrientation: should not be called on the base class");
}

- (void)layoutMessageForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    ErrorLog(@"layoutMessageForDeviceOrientation: should not be called on the base class");
}

- (void)layoutCloseButtonForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    ErrorLog(@"layoutCloseButtonForDeviceOrientation: should not be called on the base class");
}

#else

- (void)showPortraitOrientation {
    ErrorLog(@"showPortraitOrientation: should not be called on the base class");
}

- (void)addMessageClickOverlayAction {
    ErrorLog(@"addMessageClickOverlayAction: should not be called on the base class");
}

- (void)dismissPortraitOrientation {
    ErrorLog(@"dismissPortraitOrientation: should not be called on the base class");
}

- (void)buildMessageContainer {
    ErrorLog(@"buildMessageContainer: should not be called on the base class");
}

- (void)layoutCTA {
    ErrorLog(@"layoutCTA: should not be called on the base class");
}

- (void)addBackgroundColor {
    ErrorLog(@"addBackgroundColor: should not be called on the base class");
}

- (void)layoutBackgroundImage {
    ErrorLog(@"layoutBackgroundImage: should not be called on the base class");
}

- (void)layoutMessage {
    ErrorLog(@"layoutMessage: should not be called on the base class");
}

- (void)layoutCloseButton {
    ErrorLog(@"layoutCloseButton: should not be called on the base class");
}

#endif

@end
