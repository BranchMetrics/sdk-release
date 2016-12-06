//
//  TuneTakeOverMessageView.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/8/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneTakeOverMessageView.h"
#import "TuneDeviceDetails.h"
#import "TuneViewUtils.h"
#import "TuneMessageStyling.h"
#import "TuneMessageOrientationState.h"

@implementation TuneTakeOverMessageView

#pragma mark - Show

- (void)show {
    if (self.needToLayoutView) {
#if TARGET_OS_IOS
        [self layoutMessageContainerForDeviceOrientation:[TuneMessageOrientationState getCurrentOrientation]];
#else
        [self layoutMessageContainer];
#endif
    }
    
    [super show];
}

#pragma mark - Close Button

#if TARGET_OS_IOS

- (void)layoutCloseButtonForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
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

#else

- (void)layoutCloseButton {
    // button images
    [self addCloseButtonToContainer:_containerViewPortrait forOrientation:self.portraitType];
    
    // button click overlays
    [self addCloseButtonClickOverlayToContainer:_containerViewPortrait forOrientation:self.portraitType];
}

#endif

#pragma mark - Layout

#if TARGET_OS_IOS

- (void)buildMessageContainerForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    // Landscape Left
    if ([TuneDeviceDetails orientationIsSupportedByApp:UIInterfaceOrientationLandscapeRight]) {
        _containerViewLandscapeLeft = [self buildViewForOrientation:self.landscapeLeftType];
        _containerViewLandscapeLeft.layer.transform = CATransform3DMakeRotation((M_PI_2), 0, 0.0, 1.0);
        [TuneViewUtils setX:0 onView:_containerViewLandscapeLeft];
        [TuneViewUtils setY:0 onView:_containerViewLandscapeLeft];
        _containerViewLandscapeLeft.hidden = YES;
        [self addSubview:_containerViewLandscapeLeft];
    }
    
    // Landscape Right
    if ([TuneDeviceDetails orientationIsSupportedByApp:UIInterfaceOrientationLandscapeLeft]) {
        _containerViewLandscapeRight = [self buildViewForOrientation:self.landscapeLeftType];
        _containerViewLandscapeRight.layer.transform = CATransform3DMakeRotation((M_PI_2 * -1), 0, 0.0, 1.0);
        [TuneViewUtils setX:0 onView:_containerViewLandscapeRight];
        [TuneViewUtils setY:0 onView:_containerViewLandscapeRight];
        _containerViewLandscapeRight.hidden = YES;
        [self addSubview:_containerViewLandscapeRight];
    }
    
    // Portrait
    if ([TuneDeviceDetails orientationIsSupportedByApp:UIInterfaceOrientationPortrait]) {
        _containerViewPortrait = [self buildViewForOrientation:self.portraitType];
        [TuneViewUtils setX:0 onView:_containerViewPortrait];
        [TuneViewUtils setY:0 onView:_containerViewPortrait];
        _containerViewPortrait.hidden = YES;
        [self addSubview:_containerViewPortrait];
    }
    
    // Portrait Upside Down
    if ([TuneDeviceDetails orientationIsSupportedByApp:UIInterfaceOrientationPortraitUpsideDown]) {
        _containerViewPortraitUpsideDown = [self buildViewForOrientation:self.portraitUpsideDownType];
        _containerViewPortraitUpsideDown.layer.transform = CATransform3DMakeRotation((M_PI_2 * 2 * -1), 0, 0.0, 1.0);
        [TuneViewUtils setX:0 onView:_containerViewPortraitUpsideDown];
        [TuneViewUtils setY:0 onView:_containerViewPortraitUpsideDown];
        _containerViewPortraitUpsideDown.hidden = YES;
        [self addSubview:_containerViewPortraitUpsideDown];
    }
}

- (void)addMessageClickOverlayActionForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    [self addMessageClickOverlayActionToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
    [self addMessageClickOverlayActionToContainer:_containerViewLandscapeRight forOrientation:self.landscapeRightType];
    [self addMessageClickOverlayActionToContainer:_containerViewPortrait forOrientation:self.portraitType];
    [self addMessageClickOverlayActionToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
}

#else

- (void)buildMessageContainer {
    _containerViewPortrait = [self buildViewForOrientation:self.portraitType];
    [TuneViewUtils setX:0 onView:_containerViewPortrait];
    [TuneViewUtils setY:0 onView:_containerViewPortrait];
    _containerViewPortrait.hidden = YES;
    [self addSubview:_containerViewPortrait];
}

- (void)addMessageClickOverlayAction {
    [self addMessageClickOverlayActionToContainer:_containerViewPortrait forOrientation:self.portraitType];
}

#endif

#pragma mark - Images

#if TARGET_OS_IOS

- (void)layoutImageForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    
    // Do we have a portrait image?
    if (_portraitImage) {
        if (_containerViewPortrait) {
            UIImageView *imageViewPortrait = [[UIImageView alloc] initWithImage:_portraitImage];
            imageViewPortrait.frame = CGRectMake(0,0,_containerViewPortrait.frame.size.width,_containerViewPortrait.frame.size.height);
            [imageViewPortrait setContentMode:UIViewContentModeScaleAspectFit];
            [TuneViewUtils centerHorizontallyAndVerticallyInFrame:imageViewPortrait.frame onView:imageViewPortrait];
            [_containerViewPortrait addSubview:imageViewPortrait];
        }
        
        if (_containerViewPortraitUpsideDown) {
            UIImageView *imageViewPortraitUpsideDown = [[UIImageView alloc] initWithImage:_portraitImage];
            imageViewPortraitUpsideDown.frame = CGRectMake(0,0,_containerViewPortraitUpsideDown.frame.size.width,_containerViewPortraitUpsideDown.frame.size.height);
            [imageViewPortraitUpsideDown setContentMode:UIViewContentModeScaleAspectFit];
            [TuneViewUtils centerHorizontallyAndVerticallyInFrame:imageViewPortraitUpsideDown.frame onView:imageViewPortraitUpsideDown];
            [_containerViewPortraitUpsideDown addSubview:imageViewPortraitUpsideDown];
        }
    }
    
    // Do we have a landscape image?
    if (_landscapeImage) {
        if (_containerViewLandscapeRight) {
            UIImageView *imageViewLandscapeRight = [[UIImageView alloc] initWithImage:_landscapeImage];
            // yes, width->height and height->width, because this is rotated
            imageViewLandscapeRight.frame = CGRectMake(0,0,_containerViewLandscapeRight.frame.size.height,_containerViewLandscapeRight.frame.size.width);
            [imageViewLandscapeRight setContentMode:UIViewContentModeScaleAspectFit];
            [TuneViewUtils centerHorizontallyAndVerticallyInFrame:imageViewLandscapeRight.frame onView:imageViewLandscapeRight];
            [_containerViewLandscapeRight addSubview:imageViewLandscapeRight];
        }
        
        if (_containerViewLandscapeLeft) {
            UIImageView *imageViewLandscapeLeft = [[UIImageView alloc] initWithImage:_landscapeImage];
            // yes, width->height and height->width, because this is rotated
            imageViewLandscapeLeft.frame = CGRectMake(0,0,_containerViewLandscapeLeft.frame.size.height,_containerViewLandscapeLeft.frame.size.width);
            [imageViewLandscapeLeft setContentMode:UIViewContentModeScaleAspectFit];
            [TuneViewUtils centerHorizontallyAndVerticallyInFrame:imageViewLandscapeLeft.frame onView:imageViewLandscapeLeft];
            [_containerViewLandscapeLeft addSubview:imageViewLandscapeLeft];
        }
    }
}

#else

- (void)layoutImage {
    
    // Do we have a portrait image?
    if (_portraitImage) {
        if (_containerViewPortrait) {
            UIImageView *imageViewPortrait = [[UIImageView alloc] initWithImage:_portraitImage];
            imageViewPortrait.frame = CGRectMake(0,0,_containerViewPortrait.frame.size.width,_containerViewPortrait.frame.size.height);
            [imageViewPortrait setContentMode:UIViewContentModeScaleAspectFit];
            [TuneViewUtils centerHorizontallyAndVerticallyInFrame:imageViewPortrait.frame onView:imageViewPortrait];
            [_containerViewPortrait addSubview:imageViewPortrait];
        }
    }
}

#endif

#pragma mark - Transition

#if TARGET_OS_IOS

- (TuneMessageTransition)getTransitionTypeForOrientation:(UIInterfaceOrientation)orientation {
    TuneMessageTransition rotationTransitionType = _transitionType;
    
    switch (_transitionType) {
        case TuneMessageTransitionFadeIn:
            rotationTransitionType = TuneMessageTransitionFadeIn;
            break;
        case TuneMessageTransitionFromTop:
            switch (orientation) {
                case UIInterfaceOrientationPortrait:
                    break;
                case UIInterfaceOrientationPortraitUpsideDown:
                    rotationTransitionType = TuneMessageTransitionFromBottom;
                    break;
                case UIInterfaceOrientationLandscapeRight:
                    rotationTransitionType = TuneMessageTransitionFromRight;
                    break;
                case UIInterfaceOrientationLandscapeLeft:
                    rotationTransitionType = TuneMessageTransitionFromLeft;
                    break;
                default:
                    break;
            }
            break;
        case TuneMessageTransitionFromBottom:
            switch (orientation) {
                case UIInterfaceOrientationPortrait:
                    break;
                case UIInterfaceOrientationPortraitUpsideDown:
                    rotationTransitionType = TuneMessageTransitionFromTop;
                    break;
                case UIInterfaceOrientationLandscapeRight:
                    rotationTransitionType = TuneMessageTransitionFromLeft;
                    break;
                case UIInterfaceOrientationLandscapeLeft:
                    rotationTransitionType = TuneMessageTransitionFromRight;
                    break;
                default:
                    break;
            }
            break;
        case TuneMessageTransitionFromRight:
            switch (orientation) {
                case UIInterfaceOrientationPortrait:
                    break;
                case UIInterfaceOrientationPortraitUpsideDown:
                    rotationTransitionType = TuneMessageTransitionFromRight;
                    break;
                case UIInterfaceOrientationLandscapeRight:
                    rotationTransitionType = TuneMessageTransitionFromTop;
                    break;
                case UIInterfaceOrientationLandscapeLeft:
                    rotationTransitionType = TuneMessageTransitionFromBottom;
                    break;
                default:
                    break;
            }
            break;
        case TuneMessageTransitionFromLeft:
            switch (orientation) {
                case UIInterfaceOrientationPortrait:
                    break;
                case UIInterfaceOrientationPortraitUpsideDown:
                    rotationTransitionType = TuneMessageTransitionFromLeft;
                    break;
                case UIInterfaceOrientationLandscapeRight:
                    rotationTransitionType = TuneMessageTransitionFromBottom;
                    break;
                case UIInterfaceOrientationLandscapeLeft:
                    rotationTransitionType = TuneMessageTransitionFromTop;
                    break;
                default:
                    break;
            }
            break;
        case TuneMessageTransitionNone:
            rotationTransitionType = TuneMessageTransitionFadeIn;
            break;
    }
    
    return rotationTransitionType;
}

#else

- (TuneMessageTransition)getTransitionType {
    return _transitionType;
}

#endif

#pragma mark - Orientation Handling 

#if TARGET_OS_IOS

- (void)showOrientation:(UIInterfaceOrientation)orientation {
    [self.layer removeAllAnimations];
    CATransition *transition = [TuneMessageStyling messageTransitionInWithType:[self getTransitionTypeForOrientation:orientation] withEaseIn:NO];
    
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
    CATransition *transition = [TuneMessageStyling messageTransitionOutWithType:[self getTransitionTypeForOrientation:orientation] withEaseIn:YES];
    
    if (_lastAninmation) {
        transition.delegate = self;
        CATransition *maskTransition = [TuneMessageStyling messageBackgroundMaskTransition];
        [_backgroundMaskView.layer addAnimation:maskTransition forKey:kCATransition];
        _backgroundMaskView.hidden = YES;
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

- (void)showPortraitOrientation {
    [self.layer removeAllAnimations];
    CATransition *transition = [TuneMessageStyling messageTransitionInWithType:[self getTransitionType] withEaseIn:NO];
    
    [_containerViewPortrait.layer removeAllAnimations];
    [_containerViewPortrait.layer addAnimation:transition forKey:kCATransition];
    _containerViewPortrait.hidden = NO;
    
    [UIView commitAnimations];
}

- (void)dismissPortraitOrientation {
    [self.layer removeAllAnimations];
    CATransition *transition = [TuneMessageStyling messageTransitionOutWithType:[self getTransitionType] withEaseIn:YES];
    
    if (_lastAninmation) {
        transition.delegate = self;
        CATransition *maskTransition = [TuneMessageStyling messageBackgroundMaskTransition];
        [_backgroundMaskView.layer addAnimation:maskTransition forKey:kCATransition];
        _backgroundMaskView.hidden = YES;
    }
    
    [_containerViewPortrait.layer removeAllAnimations];
    [_containerViewPortrait.layer addAnimation:transition forKey:kCATransition];
    _containerViewPortrait.hidden = YES;
    
    [UIView commitAnimations];
}

#endif


#if TARGET_OS_IOS
- (void)deviceOrientationDidChange:(TuneSkyhookPayload *)payload {
    UIInterfaceOrientation currentOrientation = [TuneMessageOrientationState getCurrentOrientation];
    
    if (currentOrientation == _lastOrientation) {
        // Do nothing
    }
    else {
        if ([TuneDeviceDetails orientationIsSupportedByApp:currentOrientation]) {
            _backgroundMaskView.hidden = NO;
            [self dismissOrientation:_lastOrientation];
            [self performSelector:@selector(handleTransitionToCurrentOrientation:) withObject:@(currentOrientation) afterDelay:0.2];
        } else {
            _backgroundMaskView.hidden = YES;
        }
    }
    
}
#endif

@end
