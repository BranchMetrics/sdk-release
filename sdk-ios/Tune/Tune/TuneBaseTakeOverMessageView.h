//
//  TuneBaseTakeOverMessageView.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/8/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneBaseInAppMessageView.h"
#import "TuneMessageImageBundle.h"
#import "TuneMessageAction.h"
#import "TuneSkyhookPayload.h"

@interface TuneBaseTakeOverMessageView : TuneBaseInAppMessageView {
    
    // Transition
    TuneMessageTransition _transitionType;
    
    // Background mask
    TuneMessageBackgroundMaskType _backgroundMaskType;
    UIView *_backgroundMaskView;
    
    // Images
    UIImage *_portraitImage;
    UIImage *_landscapeImage;
    
    // Layout state
    BOOL _lastAninmation;
    
    // Views
    UIView *_containerViewPortrait;
    UIView *_containerViewPortraitUpsideDown;
    UIView *_containerViewLandscapeRight;
    UIView *_containerViewLandscapeLeft;
    
    // Message action
    TuneMessageAction *_phoneAction;
    TuneMessageAction *_tabletAction;
    
    // Close button
    TuneMessageCloseButtonColor _closeButtonColor;
    TuneTakeOverMessageCloseButtonLocationType _closeButtonLocationType;
    
#if TARGET_OS_IOS
    // Orientation
    UIDeviceOrientation _lastOrientation;
#endif
    // Assets
    TuneMessageImageBundle *_imageBundle;
}

- (id)init;

- (void)show;

#if TARGET_OS_IOS
- (void)showOrientation:(UIDeviceOrientation)orientation;
- (void)dismissOrientation:(UIDeviceOrientation)orientation;
#else
- (void)showPortraitOrientation;
- (void)dismissPortraitOrientation;
#endif

- (UIView *)buildViewForOrientation:(TuneMessageDeviceOrientation)orientation;

- (void)setBackgroundMaskType:(TuneMessageBackgroundMaskType)maskType;
- (void)setImageWithImageBundle:(TuneMessageImageBundle *)imageBundle;
- (void)setCloseButtonColor:(TuneMessageCloseButtonColor)closeButtonColor;
- (void)setTransitionType:(TuneMessageTransition)transition;
- (void)setPhoneAction:(TuneMessageAction *)action;
- (void)setTabletAction:(TuneMessageAction *)action;

- (void)addCloseButtonToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation;
- (void)addCloseButtonClickOverlayToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation;

- (void)addMessageClickOverlayActionToContainer:(UIView *)container forOrientation:(TuneMessageDeviceOrientation)orientation;

#if TARGET_OS_IOS
- (void)layoutMessageContainerForDeviceOrientation:(UIDeviceOrientation)deviceOrientation;

- (void)addMessageClickOverlayActionForDeviceOrientation:(UIDeviceOrientation)deviceOrientation;


- (void)buildMessageContainerForDeviceOrientation:(UIDeviceOrientation)deviceOrientation;
- (void)layoutCloseButtonForDeviceOrientation:(UIDeviceOrientation)deviceOrientation;
- (void)layoutImageForDeviceOrientation:(UIDeviceOrientation)deviceOrientation;
#else
- (void)layoutMessageContainer;

- (void)addMessageClickOverlayAction;

- (void)buildMessageContainer;
- (void)layoutCloseButton;
- (void)layoutImage;
#endif

#if TARGET_OS_IOS

- (void)deviceOrientationDidChange:(TuneSkyhookPayload *)payload;
- (void)handleTransitionToCurrentOrientation:(NSNumber *)currentOrientationAsNSNumber;

#endif

@end
