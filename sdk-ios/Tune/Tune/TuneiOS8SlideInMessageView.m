//
//  TuneiOS8SlideInMessageView.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneiOS8SlideInMessageView.h"
#import "TuneSlideInMessageDefaults.h"
#import "TuneDeviceDetails.h"
#import "TuneAnalyticsConstants.h"
#import "TuneMessageOrientationState.h"
#import "TuneMessageStyling.h"
#import "TuneViewUtils.h"

@implementation TuneiOS8SlideInMessageView

#pragma  mark - Messages

#if TARGET_OS_IOS

- (void)layoutMessageForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            if (_messageLabelPortrait) {
                [self addMessageLabelToContainer:_containerViewPortrait forOrientation:self.portraitType withLabelModel:_messageLabelPortrait];
            }
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            if (_messageLabelPortraitUpsideDown) {
                [self addMessageLabelToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType withLabelModel:_messageLabelPortraitUpsideDown];
            }
            break;
        case UIDeviceOrientationLandscapeLeft:
            if (_messageLabelLandscapeLeft) {
                [self addMessageLabelToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType withLabelModel:_messageLabelLandscapeLeft];
            }
            break;
        case UIDeviceOrientationLandscapeRight:
            if (_messageLabelLandscapeRight) {
                [self addMessageLabelToContainer:_containerViewLandscapeRight forOrientation:self.landscapeRightType withLabelModel:_messageLabelLandscapeRight];
            }
            break;
        default:
            break;
    }
}

#else

- (void)layoutMessage {

    [self addMessageLabelToContainer:_containerViewPortrait forOrientation:self.portraitType withLabelModel:_messageLabelPortrait];
}

#endif

#pragma mark - CTA Image & Button

#if TARGET_OS_IOS

- (void)layoutCTAForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    if (![TuneDeviceDetails runningOnPhone]) {
        if (_ctaButton) {
            switch (deviceOrientation) {
                case UIDeviceOrientationPortrait:
                    [self addCTAButtonToContainer:_containerViewPortrait forOrientation:self.portraitType];
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
                    [self addCTAButtonToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
                    break;
                case UIDeviceOrientationLandscapeLeft:
                    [self addCTAButtonToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
                    break;
                case UIDeviceOrientationLandscapeRight:
                    [self addCTAButtonToContainer:_containerViewLandscapeRight forOrientation:self.landscapeRightType];
                    break;
                default:
                    break;
            }
        }
        else if (_ctaImage) {
            switch (deviceOrientation) {
                case UIDeviceOrientationPortrait:
                    [self addCTAImageToContainer:_containerViewPortrait forOrientation:self.portraitType];
                    break;
                case UIDeviceOrientationPortraitUpsideDown:
                    [self addCTAImageToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
                    break;
                case UIDeviceOrientationLandscapeLeft:
                    [self addCTAImageToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
                    break;
                case UIDeviceOrientationLandscapeRight:
                    [self addCTAImageToContainer:_containerViewLandscapeRight forOrientation:self.landscapeRightType];
                    break;
                default:
                    break;
            }
        }
    }
}

#else

- (void)layoutCTA {
    if (![TuneDeviceDetails runningOnPhone]) {
        if (_ctaButton) {
            [self addCTAButtonToContainer:_containerViewPortrait forOrientation:self.portraitType];
        }
        else if (_ctaImage) {
            [self addCTAImageToContainer:_containerViewPortrait forOrientation:self.portraitType];
        }
    }
}

#endif

#pragma mark - Close Buttons

#if TARGET_OS_IOS

- (void)layoutCloseButtonForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    if (_showCloseButton) {
        switch (deviceOrientation) {
            case UIDeviceOrientationPortrait:
                [self addCloseButtonToContainer:_containerViewPortrait forOrientation:self.portraitType];
                [self addCloseButtonClickOverlayToContainer:_containerViewPortrait forOrientation:self.portraitType];
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                [self addCloseButtonToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
                [self addCloseButtonClickOverlayToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
                break;
            case UIDeviceOrientationLandscapeLeft:
                [self addCloseButtonToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
                [self addCloseButtonClickOverlayToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
                break;
            case UIDeviceOrientationLandscapeRight:
                [self addCloseButtonToContainer:_containerViewLandscapeRight forOrientation:self.landscapeRightType];
                [self addCloseButtonClickOverlayToContainer:_containerViewLandscapeRight forOrientation:self.landscapeRightType];
                break;
            default:
                break;
        }
    }
}

#else

- (void)layoutCloseButton {
    if (_showCloseButton) {
        [self addCloseButtonToContainer:_containerViewPortrait forOrientation:self.portraitType];
        [self addCloseButtonClickOverlayToContainer:_containerViewPortrait forOrientation:self.portraitType];
    }
}

#endif

#pragma mark - Message Actions


#if TARGET_OS_IOS

- (void)addMessageClickOverlayActionForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            [self addMessageClickOverlayActionToContainer:_containerViewPortrait forOrientation:self.portraitType];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            [self addMessageClickOverlayActionToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
            break;
        case UIDeviceOrientationLandscapeLeft:
            [self addMessageClickOverlayActionToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
            break;
        case UIDeviceOrientationLandscapeRight:
            [self addMessageClickOverlayActionToContainer:_containerViewLandscapeRight forOrientation:self.landscapeRightType];
            break;
        default:
            break;
    }
}

#else

- (void)addMessageClickOverlayAction {
    [self addMessageClickOverlayActionToContainer:_containerViewPortrait forOrientation:self.portraitType];
}

#endif

#pragma mark - Background Images & Color

- (UIImageView *)buildBackgroundImageViewFromImage:(UIImage *)image andContainerSize:(CGSize)containerSize {
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:image];
    backgroundImageView.frame = CGRectMake(0,0,containerSize.width,containerSize.height);
    [backgroundImageView setContentMode:UIViewContentModeScaleAspectFill];
    return backgroundImageView;
}

#if TARGET_OS_IOS

- (void)layoutBackgroundImageForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            if (_portraitImage) {
                UIImageView *backgroundImageView = [self buildBackgroundImageViewFromImage:_portraitImage andContainerSize:_containerViewPortrait.frame.size];
                [_containerViewPortrait addSubview:backgroundImageView];
            }
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            if (_portraitImage) {
                UIImageView *backgroundImageView = [self buildBackgroundImageViewFromImage:_portraitImage andContainerSize:_containerViewPortraitUpsideDown.frame.size];
                [_containerViewPortraitUpsideDown addSubview:backgroundImageView];
            }
            break;
        case UIDeviceOrientationLandscapeLeft:
            if (_landscapeImage) {
                UIImageView *backgroundImageView = [self buildBackgroundImageViewFromImage:_landscapeImage andContainerSize:_containerViewLandscapeLeft.frame.size];
                [_containerViewLandscapeLeft addSubview:backgroundImageView];
            }
            break;
        case UIDeviceOrientationLandscapeRight:
            if (_landscapeImage) {
                UIImageView *backgroundImageView = [self buildBackgroundImageViewFromImage:_landscapeImage andContainerSize:_containerViewLandscapeRight.frame.size];
                [_containerViewLandscapeRight addSubview:backgroundImageView];
            }
            break;
        default:
            break;
    }
}

- (void)addBackgroundColorForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            _containerViewPortrait.backgroundColor = _messageBackgroundColor;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            _containerViewPortraitUpsideDown.backgroundColor = _messageBackgroundColor;
            break;
        case UIDeviceOrientationLandscapeLeft:
            _containerViewLandscapeLeft.backgroundColor = _messageBackgroundColor;
            break;
        case UIDeviceOrientationLandscapeRight:
            _containerViewLandscapeRight.backgroundColor = _messageBackgroundColor;
            break;
        default:
            break;
    }
}

#else

- (void)layoutBackgroundImage {
    
    if (_portraitImage) {
        UIImageView *backgroundImageView = [self buildBackgroundImageViewFromImage:_portraitImage andContainerSize:_containerViewPortrait.frame.size];
        [_containerViewPortrait addSubview:backgroundImageView];
    }
}

- (void)addBackgroundColor {
    _containerViewPortrait.backgroundColor = _messageBackgroundColor;
}

#endif

#pragma mark - Containers

#if TARGET_OS_IOS

- (void)buildMessageContainerForOrientation:(UIDeviceOrientation)deviceOrientation {
    
    if (![TuneDeviceDetails orientationIsSupportedByApp:deviceOrientation]) {
        return;
    }
    else {
        // Create containers and position them
        switch (deviceOrientation) {
            case UIDeviceOrientationPortrait:
                _containerViewPortrait = [self buildViewForOrientation:self.portraitType];
                _containerViewPortrait.hidden = YES;
                
                if (_locationType == TuneMessageLocationTop) {
                    [TuneViewUtils setY:_statusBarOffset onView:_containerViewPortrait];
                }
                else {
                    [TuneViewUtils setY:([UIScreen mainScreen].bounds.size.height - _containerViewPortrait.frame.size.height) onView:_containerViewPortrait];
                }
                
                [self addSubview:_containerViewPortrait];
                break;
            case UIDeviceOrientationPortraitUpsideDown:
                _containerViewPortraitUpsideDown = [self buildViewForOrientation:self.portraitUpsideDownType];
                _containerViewPortraitUpsideDown.hidden = YES;
                
                if (_locationType == TuneMessageLocationTop) {
                    [TuneViewUtils setY:_statusBarOffset onView:_containerViewPortraitUpsideDown];
                }
                else {
                    [TuneViewUtils setY:([UIScreen mainScreen].bounds.size.height - _containerViewPortraitUpsideDown.frame.size.height) onView:_containerViewPortraitUpsideDown];
                }
                
                [self addSubview:_containerViewPortraitUpsideDown];
                break;
            case UIDeviceOrientationLandscapeLeft:
                _containerViewLandscapeLeft = [self buildViewForOrientation:self.landscapeLeftType];
                _containerViewLandscapeLeft.hidden = YES;
                
                if (_locationType == TuneMessageLocationTop) {
                    [TuneViewUtils setY:_statusBarOffset onView:_containerViewLandscapeLeft];
                }
                else {
                    [TuneViewUtils setY:([UIScreen mainScreen].bounds.size.height - _containerViewLandscapeLeft.frame.size.height) onView:_containerViewLandscapeLeft];
                }
                
                [self addSubview:_containerViewLandscapeLeft];
                break;
            case UIDeviceOrientationLandscapeRight:
                _containerViewLandscapeRight = [self buildViewForOrientation:self.landscapeLeftType];
                _containerViewLandscapeRight.hidden = YES;
                
                if (_locationType == TuneMessageLocationTop) {
                    [TuneViewUtils setY:_statusBarOffset onView:_containerViewLandscapeRight];
                }
                else {
                    [TuneViewUtils setY:([UIScreen mainScreen].bounds.size.height - _containerViewLandscapeRight.frame.size.height) onView:_containerViewLandscapeRight];
                }
                
                [self addSubview:_containerViewLandscapeRight];
                break;
            default:
                break;
        }
    }
}

#else

- (void)buildMessageContainer {
    
    _containerViewPortrait = [self buildViewForOrientation:self.portraitType];
    _containerViewPortrait.hidden = YES;
    
    if (_locationType == TuneMessageLocationTop) {
        [TuneViewUtils setY:_statusBarOffset onView:_containerViewPortrait];
    }
    else {
        [TuneViewUtils setY:([UIScreen mainScreen].bounds.size.height - _containerViewPortrait.frame.size.height) onView:_containerViewPortrait];
    }
    
    [self addSubview:_containerViewPortrait];
}

#endif

#pragma mark - Orientation related methods

#if TARGET_OS_IOS

- (TuneMessageDeviceOrientation)getCurrentTuneOrientationForUIDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    
    TuneMessageDeviceOrientation currentTuneDeviceOrientation = TuneMessageOrientationNA;
    
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            currentTuneDeviceOrientation = self.portraitType;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            currentTuneDeviceOrientation = self.portraitUpsideDownType;
            break;
        case UIDeviceOrientationLandscapeLeft:
            currentTuneDeviceOrientation = self.landscapeLeftType;
            break;
        case UIDeviceOrientationLandscapeRight:
            currentTuneDeviceOrientation = self.landscapeRightType;
            break;
        default:
            break;
    }
    
    return currentTuneDeviceOrientation;
}

- (TuneMessageTransition)getTransitionByOrientation:(UIDeviceOrientation)orientation {
    
    TuneMessageTransition transition = TuneMessageTransitionFromTop;
    
    if (_locationType == TuneMessageLocationTop) {
        return transition;
    }
    else {
        return [TuneMessageStyling reverseTransitionForType:transition];
    }
}


- (void)showOrientation:(UIDeviceOrientation)deviceOrientation {
    [self.layer removeAllAnimations];
    CATransition *transition = [TuneMessageStyling messageTransitionInWithType:[self getTransitionByOrientation:deviceOrientation] withEaseIn:NO];
    
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            // Build view if needed
            if (!_containerViewPortrait) {
                [self layoutMessageContainerForOrientation:deviceOrientation];
            }
            
            [_containerViewPortrait.layer removeAllAnimations];
            [_containerViewPortrait.layer addAnimation:transition forKey:kCATransition];
            _containerViewPortrait.hidden = NO;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            // Build view if needed
            if (!_containerViewPortraitUpsideDown) {
                [self layoutMessageContainerForOrientation:deviceOrientation];
            }
            
            [_containerViewPortraitUpsideDown.layer removeAllAnimations];
            [_containerViewPortraitUpsideDown.layer addAnimation:transition forKey:kCATransition];
            _containerViewPortraitUpsideDown.hidden = NO;
            break;
        case UIDeviceOrientationLandscapeLeft:
            // Build view if needed
            if (!_containerViewLandscapeLeft) {
                [self layoutMessageContainerForOrientation:deviceOrientation];
            }
            
            [_containerViewLandscapeLeft.layer removeAllAnimations];
            [_containerViewLandscapeLeft.layer addAnimation:transition forKey:kCATransition];
            _containerViewLandscapeLeft.hidden = NO;
            break;
        case UIDeviceOrientationLandscapeRight:
            // Build view if needed
            if (!_containerViewLandscapeRight) {
                [self layoutMessageContainerForOrientation:deviceOrientation];
            }
            
            [_containerViewLandscapeRight.layer removeAllAnimations];
            [_containerViewLandscapeRight.layer addAnimation:transition forKey:kCATransition];
            _containerViewLandscapeRight.hidden = NO;
            break;
        default:
            break;
    }
    
    [UIView commitAnimations];
}

- (void)dismissOrientation:(UIDeviceOrientation)orientation {
    
    
    [self.layer removeAllAnimations];
    CATransition *transition = [TuneMessageStyling messageTransitionOutWithType:[self getTransitionByOrientation:orientation] withEaseIn:YES];
    
    if (_lastAninmation) {
        transition.delegate = self;
    }
    
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            [_containerViewPortrait.layer removeAllAnimations];
            [_containerViewPortrait.layer addAnimation:transition forKey:kCATransition];
            _containerViewPortrait.hidden = YES;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            [_containerViewPortraitUpsideDown.layer removeAllAnimations];
            [_containerViewPortraitUpsideDown.layer addAnimation:transition forKey:kCATransition];
            _containerViewPortraitUpsideDown.hidden = YES;
            break;
        case UIDeviceOrientationLandscapeLeft:
            [_containerViewLandscapeLeft.layer removeAllAnimations];
            [_containerViewLandscapeLeft.layer addAnimation:transition forKey:kCATransition];
            _containerViewLandscapeLeft.hidden = YES;
            break;
        case UIDeviceOrientationLandscapeRight:
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

- (TuneMessageDeviceOrientation)getCurrentTuneOrientation {
    
    return self.portraitType;
}

- (TuneMessageTransition)getTransition {
    
    TuneMessageTransition transition = TuneMessageTransitionFromTop;
    
    if (_locationType == TuneMessageLocationTop) {
        return transition;
    }
    else {
        return [TuneMessageStyling reverseTransitionForType:transition];
    }
}


- (void)showPortraitOrientation {
    [self.layer removeAllAnimations];
    CATransition *transition = [TuneMessageStyling messageTransitionInWithType:[self getTransition] withEaseIn:NO];
    
    // Build view if needed
    if (!_containerViewPortrait) {
        [self layoutMessageContainer];
    }
    
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
    UIDeviceOrientation currentOrientation = [TuneMessageOrientationState getCurrentOrientation];
    
    
    if (currentOrientation == _lastOrientation) {
        // Do nothing
    }
    else {
        if ([TuneDeviceDetails orientationIsSupportedByApp:currentOrientation]) {
            self.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
            [self dismissOrientation:_lastOrientation];
            
            [self performSelector:@selector(handleTransitionToCurrentOrientation:) withObject:@(currentOrientation) afterDelay:0.2];
        }
    }
    
}

#endif

- (UIView *)buildViewForOrientation:(TuneMessageDeviceOrientation)orientation {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0,
                                                            [TuneSlideInMessageDefaults slideInMessageDefaultWidthByDeviceOrientation:orientation],
                                                            [TuneSlideInMessageDefaults slideInMessageDefaultHeightByDeviceOrientation:orientation])];
    view.backgroundColor = [UIColor clearColor];
    return view;
}


@end
