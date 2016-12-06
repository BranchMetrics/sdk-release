//
//  TuneSlideInMessageView.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/3/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneSlideInMessageView.h"
#import "TuneSlideInMessageDefaults.h"
#import "TuneDeviceDetails.h"
#import "TuneMessageOrientationState.h"
#import "TuneInAppMessageConstants.h"
#import "TuneAnalyticsConstants.h"
#import "TuneMessageStyling.h"
#import "TuneViewUtils.h"

@implementation TuneSlideInMessageView

#pragma  mark - Messages

#if TARGET_OS_IOS
- (void)layoutMessageForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    [self layoutMessage];
}
#endif

- (void)layoutMessage {
    if (_messageLabelPortrait) {
        [self addMessageLabelToContainer:_containerViewPortrait forOrientation:self.portraitType withLabelModel:_messageLabelPortrait];
    }
    
    if (_messageLabelPortraitUpsideDown) {
        [self addMessageLabelToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType withLabelModel:_messageLabelPortraitUpsideDown];
    }
    
    if (_messageLabelLandscapeLeft) {
        [self addMessageLabelToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType withLabelModel:_messageLabelLandscapeLeft];
    }
    
    if (_messageLabelLandscapeRight) {
        [self addMessageLabelToContainer:_containerViewLandscapeRight forOrientation:self.landscapeRightType withLabelModel:_messageLabelLandscapeRight];
    }
}


#pragma mark - CTA Image & Button

#if TARGET_OS_IOS
- (void)layoutCTAForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    [self layoutCTA];
}
#endif

- (void)layoutCTA {
    if (![TuneDeviceDetails runningOnPhone]) {
        if (_ctaButton) {
            [self addCTAButtonToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
            [self addCTAButtonToContainer:_containerViewLandscapeRight forOrientation:self.landscapeRightType];
            [self addCTAButtonToContainer:_containerViewPortrait forOrientation:self.portraitType];
            [self addCTAButtonToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
        }
        else if (_ctaImage) {
            [self addCTAImageToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
            [self addCTAImageToContainer:_containerViewLandscapeRight forOrientation:self.landscapeRightType];
            [self addCTAImageToContainer:_containerViewPortrait forOrientation:self.portraitType];
            [self addCTAImageToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
        }
    }
}

#pragma mark - Show / Dismiss

- (void)show {
    if (self.needToLayoutView) {
#if TARGET_OS_IOS
        [self layoutMessageContainerForOrientation:[TuneMessageOrientationState getCurrentOrientation]];
#else
        [self layoutMessageContainer];
#endif
    }
    
    [super show];
}

#pragma mark - Close Buttons

#if TARGET_OS_IOS
- (void)layoutCloseButtonForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    [self layoutCloseButton];
}
#endif

- (void)layoutCloseButton {
    if (_showCloseButton) {
        // button images
        [self addCloseButtonToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
        [self addCloseButtonToContainer:_containerViewLandscapeRight forOrientation:self.landscapeRightType];
        [self addCloseButtonToContainer:_containerViewPortrait forOrientation:self.portraitType];
        [self addCloseButtonToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
        
        // button click overlays
        [self addCloseButtonClickOverlayToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
        [self addCloseButtonClickOverlayToContainer:_containerViewLandscapeRight forOrientation:self.landscapeRightType];
        [self addCloseButtonClickOverlayToContainer:_containerViewPortrait forOrientation:self.portraitType];
        [self addCloseButtonClickOverlayToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
    }
}

#pragma mark - Message Actions

- (void)setTabletAction:(TuneMessageAction *)action {
    _tabletAction = action;
}

- (void)setPhoneAction:(TuneMessageAction *)action {
    _phoneAction = action;
}

- (void)addMessageClickOverlayAction {
    [self addMessageClickOverlayActionToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
    [self addMessageClickOverlayActionToContainer:_containerViewLandscapeRight forOrientation:self.landscapeRightType];
    [self addMessageClickOverlayActionToContainer:_containerViewPortrait forOrientation:self.portraitType];
    [self addMessageClickOverlayActionToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
}

#pragma mark - Background Images & Color

#if TARGET_OS_IOS
- (void)addBackgroundColorForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    [self addBackgroundColor];
}
#endif

- (void)addBackgroundColor {
    _containerViewLandscapeLeft.backgroundColor = _messageBackgroundColor;
    _containerViewLandscapeRight.backgroundColor = _messageBackgroundColor;
    _containerViewPortrait.backgroundColor = _messageBackgroundColor;
    _containerViewPortraitUpsideDown.backgroundColor = _messageBackgroundColor;
}

#if TARGET_OS_IOS
- (void)layoutBackgroundImageForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    [self layoutBackgroundImage];
}
#endif

- (void)layoutBackgroundImage {
    // Do we have a portrait image?
    if (_portraitImage) {
        UIImageView *backgroundImageViewPortrait = [[UIImageView alloc] initWithImage:_portraitImage];
        backgroundImageViewPortrait.frame = CGRectMake(0,0,_containerViewPortrait.frame.size.width,_containerViewPortrait.frame.size.height);
        [backgroundImageViewPortrait setContentMode:UIViewContentModeScaleAspectFill];
        
        UIImageView *backgroundImageViewPortraitUpsideDown = [[UIImageView alloc] initWithImage:_portraitImage];
        backgroundImageViewPortraitUpsideDown.frame = CGRectMake(0,0,_containerViewPortraitUpsideDown.frame.size.width,_containerViewPortraitUpsideDown.frame.size.height);
        [backgroundImageViewPortraitUpsideDown setContentMode:UIViewContentModeScaleAspectFill];
        
        if (_containerViewPortrait) {
            [_containerViewPortrait addSubview:backgroundImageViewPortrait];
        }
        
        if (_containerViewPortraitUpsideDown) {
            [_containerViewPortraitUpsideDown addSubview:backgroundImageViewPortraitUpsideDown];
        }
    }
    
    // Do we have a landscape image?
    if (_landscapeImage) {
        UIImageView *backgroundImageViewLandscapeRight = [[UIImageView alloc] initWithImage:_landscapeImage];
        backgroundImageViewLandscapeRight.frame = CGRectMake(0,0,_containerViewLandscapeRight.frame.size.height,_containerViewLandscapeRight.frame.size.width);
        [backgroundImageViewLandscapeRight setContentMode:UIViewContentModeScaleAspectFill];
        
        UIImageView *backgroundImageViewLandscapeLeft = [[UIImageView alloc] initWithImage:_landscapeImage];
        backgroundImageViewLandscapeLeft.frame = CGRectMake(0,0,_containerViewLandscapeLeft.frame.size.height,_containerViewLandscapeLeft.frame.size.width);
        [backgroundImageViewLandscapeLeft setContentMode:UIViewContentModeScaleAspectFill];
        
        if (_containerViewLandscapeRight) {
            [_containerViewLandscapeRight addSubview:backgroundImageViewLandscapeRight];
        }
        
        if (_containerViewLandscapeLeft) {
            [_containerViewLandscapeLeft addSubview:backgroundImageViewLandscapeLeft];
        }
    }
}

#pragma mark - Containers

#if TARGET_OS_IOS

- (void)buildMessageContainerForOrientation:(UIInterfaceOrientation)deviceOrientation {
    // Landscape Left
    if ([TuneDeviceDetails orientationIsSupportedByApp:UIInterfaceOrientationLandscapeRight]) {
        _containerViewLandscapeLeft = [self buildViewForOrientation:self.landscapeLeftType];
        _containerViewLandscapeLeft.layer.transform = CATransform3DMakeRotation((M_PI_2), 0, 0.0, 1.0);
        
        // Screen Positioning
        if (_locationType == TuneMessageLocationTop) {
            [TuneViewUtils setX:([UIScreen mainScreen].bounds.size.width - _containerViewLandscapeLeft.frame.size.width - _statusBarOffset) onView:_containerViewLandscapeLeft];
            [TuneViewUtils setY:0 onView:_containerViewLandscapeLeft];
        }
        else {
            [TuneViewUtils setX:0 onView:_containerViewLandscapeLeft];
            [TuneViewUtils setY:0 onView:_containerViewLandscapeLeft];
        }
        _containerViewLandscapeLeft.hidden = YES;
        [self addSubview:_containerViewLandscapeLeft];
    }
    
    // Landscape Right
    if ([TuneDeviceDetails orientationIsSupportedByApp:UIInterfaceOrientationLandscapeLeft]) {
        _containerViewLandscapeRight = [self buildViewForOrientation:self.landscapeLeftType];
        _containerViewLandscapeRight.layer.transform = CATransform3DMakeRotation((M_PI_2 * -1), 0, 0.0, 1.0);
        
        // Screen Positioning
        if (_locationType == TuneMessageLocationTop) {
            [TuneViewUtils setX:_statusBarOffset onView:_containerViewLandscapeRight];
            [TuneViewUtils setY:0 onView:_containerViewLandscapeRight];
        }
        else {
            [TuneViewUtils setX:([UIScreen mainScreen].bounds.size.width - _containerViewLandscapeRight.frame.size.width) onView:_containerViewLandscapeRight];
            [TuneViewUtils setY:0 onView:_containerViewLandscapeRight];
        }
        _containerViewLandscapeRight.hidden = YES;
        [self addSubview:_containerViewLandscapeRight];
    }
    
    // Portrait
    if ([TuneDeviceDetails orientationIsSupportedByApp:UIInterfaceOrientationPortrait]) {
        _containerViewPortrait = [self buildViewForOrientation:self.portraitType];
        
        // Screen Positioning
        if (_locationType == TuneMessageLocationTop) {
            [TuneViewUtils setX:0 onView:_containerViewPortrait];
            [TuneViewUtils setY:_statusBarOffset onView:_containerViewPortrait];
        }
        else {
            [TuneViewUtils setX:0 onView:_containerViewPortrait];
            [TuneViewUtils setY:([UIScreen mainScreen].bounds.size.height - _containerViewPortrait.frame.size.height) onView:_containerViewPortrait];
        }
        _containerViewPortrait.hidden = YES;
        [self addSubview:_containerViewPortrait];
    }
    
    // Portrait Upside Down
    if ([TuneDeviceDetails orientationIsSupportedByApp:UIInterfaceOrientationPortraitUpsideDown]) {
        _containerViewPortraitUpsideDown = [self buildViewForOrientation:self.portraitUpsideDownType];
        _containerViewPortraitUpsideDown.layer.transform = CATransform3DMakeRotation((M_PI_2 * 2 * -1), 0, 0.0, 1.0);
        
        // Screen Positioning
        if (_locationType == TuneMessageLocationTop) {
            [TuneViewUtils setX:0 onView:_containerViewPortraitUpsideDown];
            [TuneViewUtils setY:([UIScreen mainScreen].bounds.size.height - _containerViewPortraitUpsideDown.frame.size.height - _statusBarOffset) onView:_containerViewPortraitUpsideDown];
        }
        else {
            [TuneViewUtils setX:0 onView:_containerViewPortraitUpsideDown];
            [TuneViewUtils setY:0 onView:_containerViewPortraitUpsideDown];
        }
        _containerViewPortraitUpsideDown.hidden = YES;
        [self addSubview:_containerViewPortraitUpsideDown];
    }
}

#else

- (void)buildMessageContainer {
    _containerViewPortrait = [self buildViewForOrientation:self.portraitType];
    
    // Screen Positioning
    if (_locationType == TuneMessageLocationTop) {
        [TuneViewUtils setX:0 onView:_containerViewPortrait];
        [TuneViewUtils setY:_statusBarOffset onView:_containerViewPortrait];
    }
    else {
        [TuneViewUtils setX:0 onView:_containerViewPortrait];
        [TuneViewUtils setY:([UIScreen mainScreen].bounds.size.height - _containerViewPortrait.frame.size.height) onView:_containerViewPortrait];
    }
    _containerViewPortrait.hidden = YES;
    [self addSubview:_containerViewPortrait];
}

#endif

#pragma mark - Orientation related methods

#if TARGET_OS_IOS

- (TuneMessageTransition)getTransitionByOrientation:(UIInterfaceOrientation)orientation {
    TuneMessageTransition transition = TuneMessageTransitionNone;
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            transition = TuneMessageTransitionFromTop;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            transition = TuneMessageTransitionFromBottom;
            break;
        case UIInterfaceOrientationLandscapeRight:
            transition = TuneMessageTransitionFromRight;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            transition = TuneMessageTransitionFromLeft;
            break;
        default:
            break;
    }
    
    if (_locationType == TuneMessageLocationTop) {
        return transition;
    }
    else {
        return [TuneMessageStyling reverseTransitionForType:transition];
    }
}

- (void)showOrientation:(UIInterfaceOrientation)orientation {
    [self.layer removeAllAnimations];
    CATransition *transition = [TuneMessageStyling messageTransitionInWithType:[self getTransitionByOrientation:orientation] withEaseIn:NO];
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            [_containerViewPortrait.layer removeAllAnimations];
            [_containerViewPortrait.layer addAnimation:transition forKey:kCATransition];
            _containerViewPortrait.hidden = NO;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            [_containerViewPortraitUpsideDown.layer removeAllAnimations];
            [_containerViewPortraitUpsideDown.layer addAnimation:transition forKey:kCATransition];
            _containerViewPortraitUpsideDown.hidden = NO;
            break;
        case UIInterfaceOrientationLandscapeRight:
            transition.duration = 0.45;
            [_containerViewLandscapeLeft.layer removeAllAnimations];
            [_containerViewLandscapeLeft.layer addAnimation:transition forKey:kCATransition];
            _containerViewLandscapeLeft.hidden = NO;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            transition.duration = 0.45;
            [_containerViewLandscapeRight.layer removeAllAnimations];
            [_containerViewLandscapeRight.layer addAnimation:transition forKey:kCATransition];
            _containerViewLandscapeRight.hidden = NO;
            break;
        default:
            break;
    }
    
    [UIView commitAnimations];
}

- (void)dismissOrientation:(UIInterfaceOrientation)orientation {
    [self.layer removeAllAnimations];
    CATransition *transition = [TuneMessageStyling messageTransitionOutWithType:[self getTransitionByOrientation:orientation] withEaseIn:YES];
    
    if (_lastAninmation) {
        transition.delegate = self;
    }
    
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            [_containerViewPortrait.layer removeAllAnimations];
            [_containerViewPortrait.layer addAnimation:transition forKey:kCATransition];
            _containerViewPortrait.hidden = YES;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            [_containerViewPortraitUpsideDown.layer removeAllAnimations];
            [_containerViewPortraitUpsideDown.layer addAnimation:transition forKey:kCATransition];
            _containerViewPortraitUpsideDown.hidden = YES;
            break;
        case UIInterfaceOrientationLandscapeRight:
            transition.duration = 0.45;
            [_containerViewLandscapeLeft.layer removeAllAnimations];
            [_containerViewLandscapeLeft.layer addAnimation:transition forKey:kCATransition];
            _containerViewLandscapeLeft.hidden = YES;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            transition.duration = 0.45;
            [_containerViewLandscapeRight.layer removeAllAnimations];
            [_containerViewLandscapeRight.layer addAnimation:transition forKey:kCATransition];
            _containerViewLandscapeRight.hidden = YES;
            break;
        default:
            break;
    }
    
    [UIView commitAnimations];
}

#else

- (TuneMessageTransition)getTransition {
    return TuneMessageTransitionFromTop;
}

- (void)showPortraitOrientation {
    [self.layer removeAllAnimations];
    CATransition *transition = [TuneMessageStyling messageTransitionInWithType:[self getTransition] withEaseIn:NO];
    
    [_containerViewPortrait.layer removeAllAnimations];
    [_containerViewPortrait.layer addAnimation:transition forKey:kCATransition];
    _containerViewPortrait.hidden = NO;
    
    [UIView commitAnimations];
}

- (void)dismissPortraitOrientation {
    [self.layer removeAllAnimations];
    CATransition *transition = [TuneMessageStyling messageTransitionOutWithType:[self getTransition] withEaseIn:YES];
    
    if (_lastAninmation) {
        transition.delegate = self;
    }
    
    [_containerViewPortrait.layer removeAllAnimations];
    [_containerViewPortrait.layer addAnimation:transition forKey:kCATransition];
    _containerViewPortrait.hidden = YES;
    
    [UIView commitAnimations];
}

#endif

#if TARGET_OS_IOS

- (void)deviceOrientationDidChange:(TuneSkyhookPayload *)payload {
    UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (currentOrientation == _lastOrientation) {
        // Do nothing
    }
    else {
        if ([TuneDeviceDetails orientationIsSupportedByApp:currentOrientation]) {
            [self dismissOrientation:_lastOrientation];
            
            [self performSelector:@selector(handleTransitionToCurrentOrientation:) withObject:@(currentOrientation) afterDelay:0.2];
        }
    }
    
}

#endif

- (UIView *)buildViewForOrientation:(TuneMessageDeviceOrientation)orientation {
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                    [TuneSlideInMessageDefaults slideInMessageDefaultWidthByDeviceOrientation:orientation],
                                                    [TuneSlideInMessageDefaults slideInMessageDefaultHeightByDeviceOrientation:orientation])];
}


@end
