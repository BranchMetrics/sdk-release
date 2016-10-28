//
//  TuneBaseTakeOverMessageView.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/8/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneBaseTakeOverMessageView.h"
#import "TuneTakeOverMessageDefaults.h"
#import "TuneMessageOrientationState.h"
#import "TuneMessageStyling.h"
#import "TuneAnalyticsConstants.h"
#import "TuneDeviceDetails.h"
#import "TuneSkyhookCenter.h"

@implementation TuneBaseTakeOverMessageView

#pragma mark - Initialization

- (id)init {
    
#if TARGET_OS_IOS
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(deviceOrientationDidChange:)
                                              name:UIApplicationDidChangeStatusBarOrientationNotification
                                            object:nil];
#endif
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        [self initDefaults];
    }
    
    return self;
}

- (void)dealloc {
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
}

- (void)initDefaults {
    _lastAninmation = NO;
    _transitionType = DefaultTakeOverTransitionType;
    _closeButtonLocationType = TuneTakeOverMessageDefaultCloseButtonLocation;
}

#pragma mark - Show / Dismiss

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
        [self performSelector:@selector(removeTakeOverMessageFromWindow) withObject:nil afterDelay:0.5];
    }
}

- (void)removeTakeOverMessageFromWindow {
    [self removeFromSuperview];
    _lastAninmation = NO;
    self.needToAddToUIWindow = YES;
}

#pragma mark - Background Mask

- (void)updateBackgroundMask {
    CGFloat largerSide = fmax(self.frame.size.width,self.frame.size.height);
    _backgroundMaskView.frame = CGRectMake(0,0,largerSide,largerSide);
}

- (void)setBackgroundMaskType:(TuneMessageBackgroundMaskType)backgroundMaskType {
    _backgroundMaskType = backgroundMaskType;
}

#pragma mark - Close Button

- (void)setCloseButtonColor:(TuneMessageCloseButtonColor)closeButtonColor {
    _closeButtonColor = closeButtonColor;
}

- (void)setCloseButtonLocationType:(TuneTakeOverMessageCloseButtonLocationType)closeButtonLocationType  {
    _closeButtonLocationType = closeButtonLocationType;
}

- (void)addCloseButtonToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation {
    if (container) {
        UIImageView *closeButtonImageView = [[UIImageView alloc] initWithImage:[TuneMessageStyling closeButtonImageByCloseButtonColor:_closeButtonColor]];
        closeButtonImageView.frame = [TuneTakeOverMessageDefaults takeOverMessageCloseButtonFrameByDeviceOrientation:orientation andCloseButtonLocation:_closeButtonLocationType];
        [container addSubview:closeButtonImageView];
    }
}

- (void)addCloseButtonClickOverlayToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation {
    if (container) {
        UIButton *clickOverlay = [UIButton buttonWithType:UIButtonTypeCustom];
        [clickOverlay layoutIfNeeded];
        clickOverlay.frame = [TuneTakeOverMessageDefaults takeOverMessageCloseButtonClickOverlayFrameByDeviceOrientation:orientation andCloseButtonLocation:_closeButtonLocationType];
        clickOverlay.backgroundColor = [UIColor clearColor];
        clickOverlay.userInteractionEnabled = YES;
        [clickOverlay addTarget:self action:@selector(closeButtonTouched) forControlEvents:UIControlEventTouchUpInside];
        [container addSubview:clickOverlay];
    }
}

- (void)closeButtonTouched {
    [self recordMessageDismissedWithAction:TUNE_IN_APP_MESSAGE_ACTION_CLOSE_BUTTON_PRESSED];
    [self dismiss];
}

#pragma mark - Layout

#if TARGET_OS_IOS
- (void)layoutMessageContainerForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    [self buildMessageContainerForDeviceOrientation:deviceOrientation];
    [self layoutImageForDeviceOrientation:deviceOrientation];
    [self layoutCloseButtonForDeviceOrientation:deviceOrientation];
    [self addMessageClickOverlayActionForDeviceOrientation:deviceOrientation];
    [self updateBackgroundMask];
    self.needToLayoutView = NO;
}
#else
- (void)layoutMessageContainer {
    [self buildMessageContainer];
    [self layoutImage];
    [self layoutCloseButton];
    [self addMessageClickOverlayAction];
    [self updateBackgroundMask];
    self.needToLayoutView = NO;
}
#endif

- (UIView *)buildViewForOrientation:(TuneMessageDeviceOrientation)orientation {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                            [TuneTakeOverMessageDefaults takeOverMessageDefaultWidthByDeviceOrientation:orientation],
                                                            [TuneTakeOverMessageDefaults takeOverMessageDefaultHeightByDeviceOrientation:orientation])];
    return view;
}

#pragma mark - Click Actions

- (void)addMessageClickOverlayActionToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation {
    UIButton *clickOverlay = [UIButton buttonWithType:UIButtonTypeCustom];
    [clickOverlay layoutIfNeeded];
    CGRect closeButtonClickOverlayFrame = closeButtonClickOverlayFrame = [TuneTakeOverMessageDefaults takeOverMessageCloseButtonClickOverlayFrameByDeviceOrientation:orientation andCloseButtonLocation:_closeButtonLocationType];
    
    // Calculate frame
    CGFloat clickOverlayWidth = [TuneTakeOverMessageDefaults takeOverMessageDefaultWidthByDeviceOrientation:orientation] - closeButtonClickOverlayFrame.size.width;
    CGFloat clickOverlayHeight = [TuneTakeOverMessageDefaults takeOverMessageDefaultHeightByDeviceOrientation:orientation];
    
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

- (void)setPhoneAction:(TuneMessageAction *)action {
    _phoneAction = action;
}

- (void)setTabletAction:(TuneMessageAction *)action {
    _tabletAction = action;
}

#pragma mark - Images

- (void)setImageWithImageBundle:(TuneMessageImageBundle *)imageBundle {
    _imageBundle = imageBundle;
    [self setImagesFromImageBundle];
}

- (void)setImagesFromImageBundle {
    if ([TuneDeviceDetails runningOnPhone]) {
        if (_imageBundle.phonePortraitImage) {
            _portraitImage =_imageBundle.phonePortraitImage;
        }
        
        if (_imageBundle.phoneLandscapeImage) {
            _landscapeImage = _imageBundle.phoneLandscapeImage;
        }
    }
    else {
        if (_imageBundle.tabletPortraitImage) {
            _portraitImage = _imageBundle.tabletPortraitImage;
        }
        
        if (_imageBundle.tabletLandscapeImage) {
            _landscapeImage = _imageBundle.tabletLandscapeImage;
        }
    }
}

#pragma mark - Transition

- (void)setTransitionType:(TuneMessageTransition)transitionType {
    _transitionType = transitionType;
}

#pragma mark - Orientation Handling

#if TARGET_OS_IOS

- (void)handleTransitionToCurrentOrientation:(NSNumber *)currentOrientationAsNSNumber {
    UIInterfaceOrientation currentOrientation = [currentOrientationAsNSNumber intValue];
    [self showOrientation:currentOrientation];
    _lastOrientation = currentOrientation;
}

#endif

#pragma mark - Overridden By Subclasses

#if TARGET_OS_IOS

- (void)showOrientation:(UIInterfaceOrientation)orientation {
    ErrorLog(@"showOrientation: should not be called on the base class");
}

- (void)deviceOrientationDidChange:(TuneSkyhookPayload *)payload {
    ErrorLog(@"deviceOrientationDidChange: should not be called on the base class");
}

- (void)dismissOrientation:(UIInterfaceOrientation)orientation {
    ErrorLog(@"dismissOrientation: should not be called on the base class");
}

- (void)addMessageClickOverlayActionForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    ErrorLog(@"addMessageClickOverlayActionForDeviceOrientation: should not be called on the base class");
}

- (void)buildMessageContainerForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    ErrorLog(@"buildMessageContainerForDeviceOrientation: should not be called on the base class");
}

- (void)layoutCloseButtonForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    ErrorLog(@"layoutCloseButtonForDeviceOrientation: should not be called on the base class");
}

- (void)layoutImageForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    ErrorLog(@"layoutImageForDeviceOrientation: should not be called on the base class");
}

#else

- (void)showPortraitOrientation {
    ErrorLog(@"showPortraitOrientation: should not be called on the base class");
}

- (void)dismissPortraitOrientation {
    ErrorLog(@"dismissPortraitOrientation: should not be called on the base class");
}

- (void)addMessageClickOverlayAction {
    ErrorLog(@"addMessageClickOverlayAction: should not be called on the base class");
}

- (void)buildMessageContainer {
    ErrorLog(@"buildMessageContainer: should not be called on the base class");
}

- (void)layoutCloseButton {
    ErrorLog(@"layoutCloseButton: should not be called on the base class");
}

- (void)layoutImage {
    ErrorLog(@"layoutImage: should not be called on the base class");
}

#endif

@end
