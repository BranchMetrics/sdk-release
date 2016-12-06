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

- (void)layoutMessageForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    
    switch (deviceOrientation) {
        case UIInterfaceOrientationPortrait:
            if (_messageLabelPortrait) {
                [self addMessageLabelToContainer:_containerViewPortrait forOrientation:self.portraitType withLabelModel:_messageLabelPortrait];
            }
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            if (_messageLabelPortraitUpsideDown) {
                [self addMessageLabelToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType withLabelModel:_messageLabelPortraitUpsideDown];
            }
            break;
        case UIInterfaceOrientationLandscapeRight:
            if (_messageLabelLandscapeLeft) {
                [self addMessageLabelToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType withLabelModel:_messageLabelLandscapeLeft];
            }
            break;
        case UIInterfaceOrientationLandscapeLeft:
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

- (void)layoutCTAForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    if (![TuneDeviceDetails runningOnPhone]) {
        if (_ctaButton) {
            switch (deviceOrientation) {
                case UIInterfaceOrientationPortrait:
                    [self addCTAButtonToContainer:_containerViewPortrait forOrientation:self.portraitType];
                    break;
                case UIInterfaceOrientationPortraitUpsideDown:
                    [self addCTAButtonToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
                    break;
                case UIInterfaceOrientationLandscapeRight:
                    [self addCTAButtonToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
                    break;
                case UIInterfaceOrientationLandscapeLeft:
                    [self addCTAButtonToContainer:_containerViewLandscapeRight forOrientation:self.landscapeRightType];
                    break;
                default:
                    break;
            }
        }
        else if (_ctaImage) {
            switch (deviceOrientation) {
                case UIInterfaceOrientationPortrait:
                    [self addCTAImageToContainer:_containerViewPortrait forOrientation:self.portraitType];
                    break;
                case UIInterfaceOrientationPortraitUpsideDown:
                    [self addCTAImageToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
                    break;
                case UIInterfaceOrientationLandscapeRight:
                    [self addCTAImageToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
                    break;
                case UIInterfaceOrientationLandscapeLeft:
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

- (void)layoutCloseButtonForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    if (_showCloseButton) {
        switch (deviceOrientation) {
            case UIInterfaceOrientationPortrait:
                [self addCloseButtonToContainer:_containerViewPortrait forOrientation:self.portraitType];
                [self addCloseButtonClickOverlayToContainer:_containerViewPortrait forOrientation:self.portraitType];
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                [self addCloseButtonToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
                [self addCloseButtonClickOverlayToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
                break;
            case UIInterfaceOrientationLandscapeRight:
                [self addCloseButtonToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
                [self addCloseButtonClickOverlayToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
                break;
            case UIInterfaceOrientationLandscapeLeft:
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

- (void)addMessageClickOverlayActionForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    switch (deviceOrientation) {
        case UIInterfaceOrientationPortrait:
            [self addMessageClickOverlayActionToContainer:_containerViewPortrait forOrientation:self.portraitType];
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            [self addMessageClickOverlayActionToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];
            break;
        case UIInterfaceOrientationLandscapeRight:
            [self addMessageClickOverlayActionToContainer:_containerViewLandscapeLeft forOrientation:self.landscapeLeftType];
            break;
        case UIInterfaceOrientationLandscapeLeft:
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

- (void)layoutBackgroundImageForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    
    switch (deviceOrientation) {
        case UIInterfaceOrientationPortrait:
            if (_portraitImage) {
                UIImageView *backgroundImageView = [self buildBackgroundImageViewFromImage:_portraitImage andContainerSize:_containerViewPortrait.frame.size];
                [_containerViewPortrait addSubview:backgroundImageView];
            }
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            if (_portraitImage) {
                UIImageView *backgroundImageView = [self buildBackgroundImageViewFromImage:_portraitImage andContainerSize:_containerViewPortraitUpsideDown.frame.size];
                [_containerViewPortraitUpsideDown addSubview:backgroundImageView];
            }
            break;
        case UIInterfaceOrientationLandscapeRight:
            if (_landscapeImage) {
                UIImageView *backgroundImageView = [self buildBackgroundImageViewFromImage:_landscapeImage andContainerSize:_containerViewLandscapeLeft.frame.size];
                [_containerViewLandscapeLeft addSubview:backgroundImageView];
            }
            break;
        case UIInterfaceOrientationLandscapeLeft:
            if (_landscapeImage) {
                UIImageView *backgroundImageView = [self buildBackgroundImageViewFromImage:_landscapeImage andContainerSize:_containerViewLandscapeRight.frame.size];
                [_containerViewLandscapeRight addSubview:backgroundImageView];
            }
            break;
        default:
            break;
    }
}

- (void)addBackgroundColorForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    switch (deviceOrientation) {
        case UIInterfaceOrientationPortrait:
            _containerViewPortrait.backgroundColor = _messageBackgroundColor;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            _containerViewPortraitUpsideDown.backgroundColor = _messageBackgroundColor;
            break;
        case UIInterfaceOrientationLandscapeRight:
            _containerViewLandscapeLeft.backgroundColor = _messageBackgroundColor;
            break;
        case UIInterfaceOrientationLandscapeLeft:
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

- (void)buildMessageContainerForOrientation:(UIInterfaceOrientation)deviceOrientation {
    
    if (![TuneDeviceDetails orientationIsSupportedByApp:deviceOrientation]) {
        return;
    }
    else {
        // Create containers and position them
        switch (deviceOrientation) {
            case UIInterfaceOrientationPortrait:
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
            case UIInterfaceOrientationPortraitUpsideDown:
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
            case UIInterfaceOrientationLandscapeRight:
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
            case UIInterfaceOrientationLandscapeLeft:
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
        case UIDeviceOrientationLandscapeRight:
            currentTuneDeviceOrientation = self.landscapeLeftType;
            break;
        case UIDeviceOrientationLandscapeLeft:
            currentTuneDeviceOrientation = self.landscapeRightType;
            break;
        default:
            break;
    }
    
    return currentTuneDeviceOrientation;
}

- (TuneMessageTransition)getTransitionByOrientation:(UIInterfaceOrientation)orientation {
    
    TuneMessageTransition transition = TuneMessageTransitionFromTop;
    
    if (_locationType == TuneMessageLocationTop) {
        return transition;
    }
    else {
        return [TuneMessageStyling reverseTransitionForType:transition];
    }
}


- (void)showOrientation:(UIInterfaceOrientation)deviceOrientation {
    [self.layer removeAllAnimations];
    CATransition *transition = [TuneMessageStyling messageTransitionInWithType:[self getTransitionByOrientation:deviceOrientation] withEaseIn:NO];
    
    switch (deviceOrientation) {
        case UIInterfaceOrientationPortrait:
            // Build view if needed
            if (!_containerViewPortrait) {
                [self layoutMessageContainerForOrientation:UIInterfaceOrientationPortrait];
            }
            
            [_containerViewPortrait.layer removeAllAnimations];
            [_containerViewPortrait.layer addAnimation:transition forKey:kCATransition];
            _containerViewPortrait.hidden = NO;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            // Build view if needed
            if (!_containerViewPortraitUpsideDown) {
                [self layoutMessageContainerForOrientation:UIInterfaceOrientationPortraitUpsideDown];
            }
            
            [_containerViewPortraitUpsideDown.layer removeAllAnimations];
            [_containerViewPortraitUpsideDown.layer addAnimation:transition forKey:kCATransition];
            _containerViewPortraitUpsideDown.hidden = NO;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            // Build view if needed
            if (!_containerViewLandscapeLeft) {
                [self layoutMessageContainerForOrientation:UIInterfaceOrientationLandscapeLeft];
            }
            
            [_containerViewLandscapeLeft.layer removeAllAnimations];
            [_containerViewLandscapeLeft.layer addAnimation:transition forKey:kCATransition];
            _containerViewLandscapeLeft.hidden = NO;
            break;
        case UIInterfaceOrientationLandscapeRight:
            // Build view if needed
            if (!_containerViewLandscapeRight) {
                [self layoutMessageContainerForOrientation:UIInterfaceOrientationLandscapeRight];
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
        case UIInterfaceOrientationLandscapeLeft:
            [_containerViewLandscapeLeft.layer removeAllAnimations];
            [_containerViewLandscapeLeft.layer addAnimation:transition forKey:kCATransition];
            _containerViewLandscapeLeft.hidden = YES;
            break;
        case UIInterfaceOrientationLandscapeRight:
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
    UIInterfaceOrientation currentOrientation = [TuneMessageOrientationState getCurrentOrientation];
    
    
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
