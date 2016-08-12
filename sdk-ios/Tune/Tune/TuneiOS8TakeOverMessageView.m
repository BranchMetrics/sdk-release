//
//  TuneiOS8TakeOverMessageView.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/8/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneiOS8TakeOverMessageView.h"
#import "TuneDeviceDetails.h"
#import "TuneViewUtils.h"
#import "TuneMessageStyling.h"
#import "TuneMessageOrientationState.h"

@implementation TuneiOS8TakeOverMessageView

#pragma mark - Show

- (void)show {
    [self buildBackgroundMask];
    
    [super show];
}

#pragma mark - Background Mask

- (void)updateBackgroundMask {
    CGFloat largerSide = fmax(self.frame.size.width,self.frame.size.height);
    _backgroundMaskView.frame = CGRectMake(0,0, largerSide, largerSide);
}

- (void)buildBackgroundMask {
    _backgroundMaskView = [[UIView alloc] initWithFrame:self.frame];
    _backgroundMaskView.alpha = 0.65;
    
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
    
    [self addSubview:_backgroundMaskView];
}


#pragma mark - Close Button

- (void)layoutCloseButtonForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
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


#pragma mark - Layout

- (void)buildMessageContainerForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    
    if (![TuneDeviceDetails orientationIsSupportedByApp:deviceOrientation]) {
        return;
    }
    
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            _containerViewPortrait = [self buildViewForOrientation:self.portraitType];
            [TuneViewUtils setX:0 onView:_containerViewPortrait];
            [TuneViewUtils setY:0 onView:_containerViewPortrait];
            _containerViewPortrait.hidden = YES;
            [self addSubview:_containerViewPortrait];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            _containerViewPortraitUpsideDown = [self buildViewForOrientation:self.portraitUpsideDownType];
            [TuneViewUtils setX:0 onView:_containerViewPortraitUpsideDown];
            [TuneViewUtils setY:0 onView:_containerViewPortraitUpsideDown];
            _containerViewPortraitUpsideDown.hidden = YES;
            [self addSubview:_containerViewPortraitUpsideDown];
            break;
        case UIDeviceOrientationLandscapeLeft:
            _containerViewLandscapeLeft = [self buildViewForOrientation:self.landscapeLeftType];
            [TuneViewUtils setX:0 onView:_containerViewLandscapeLeft];
            [TuneViewUtils setY:0 onView:_containerViewLandscapeLeft];
            _containerViewLandscapeLeft.hidden = YES;
            [self addSubview:_containerViewLandscapeLeft];
            break;
        case UIDeviceOrientationLandscapeRight:
            _containerViewLandscapeRight = [self buildViewForOrientation:self.landscapeLeftType];
            [TuneViewUtils setX:0 onView:_containerViewLandscapeRight];
            [TuneViewUtils setY:0 onView:_containerViewLandscapeRight];
            _containerViewLandscapeRight.hidden = YES;
            [self addSubview:_containerViewLandscapeRight];
            break;
        default:
            break;
    }
}

- (void)addMessageClickOverlayActionForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            [self addMessageClickOverlayActionToContainer:_containerViewPortrait forOrientation:self.portraitType];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            [self addMessageClickOverlayActionToContainer:_containerViewPortraitUpsideDown forOrientation:self.portraitUpsideDownType];;
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

#pragma mark - Images

- (UIImageView *)buildImageViewFromImage:(UIImage *)image andContainerSize:(CGSize)containerSize {
    UIImageView *backgroundImageView = [[UIImageView alloc] initWithImage:image];
    [backgroundImageView setFrame:CGRectMake(0, 0, containerSize.width, containerSize.height)];
    [backgroundImageView setContentMode:UIViewContentModeScaleAspectFit];
    return backgroundImageView;
}

- (void)layoutImageForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            if (_portraitImage) {
                UIImageView *backgroundImageView = [self buildImageViewFromImage:_portraitImage andContainerSize:_containerViewPortrait.frame.size];

                [TuneViewUtils centerHorizontallyAndVerticallyInFrame:_containerViewPortrait.frame onView:backgroundImageView];
                [_containerViewPortrait addSubview:backgroundImageView];
            }
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            if (_portraitImage) {
                UIImageView *backgroundImageView = [self buildImageViewFromImage:_portraitImage andContainerSize:_containerViewPortraitUpsideDown.frame.size];
                [TuneViewUtils centerHorizontallyAndVerticallyInFrame:_containerViewPortraitUpsideDown.frame onView:backgroundImageView];
                [_containerViewPortraitUpsideDown addSubview:backgroundImageView];
            }
            break;
        case UIDeviceOrientationLandscapeLeft:
            if (_landscapeImage) {
                UIImageView *backgroundImageView = [self buildImageViewFromImage:_landscapeImage andContainerSize:_containerViewLandscapeLeft.frame.size];
                [TuneViewUtils centerHorizontallyAndVerticallyInFrame:_containerViewLandscapeLeft.frame onView:backgroundImageView];
                [_containerViewLandscapeLeft addSubview:backgroundImageView];
            }
            break;
        case UIDeviceOrientationLandscapeRight:
            if (_landscapeImage) {
                UIImageView *backgroundImageView = [self buildImageViewFromImage:_landscapeImage andContainerSize:_containerViewLandscapeRight.frame.size];
                [TuneViewUtils centerHorizontallyAndVerticallyInFrame:_containerViewLandscapeRight.frame onView:backgroundImageView];
                [_containerViewLandscapeRight addSubview:backgroundImageView];
            }
            break;
        default:
            break;
    }
}


#pragma mark - Transition

- (TuneMessageTransition)getTransitionTypeForOrientation:(UIDeviceOrientation)orientation {
    return _transitionType;
}


#pragma mark - Orientation Handling 

- (void)showOrientation:(UIDeviceOrientation)orientation {
    [self.layer removeAllAnimations];
    CATransition *transition = [TuneMessageStyling messageTransitionInWithType:[self getTransitionTypeForOrientation:orientation] withEaseIn:NO];
    
    _containerViewPortrait.hidden = YES;
    _containerViewPortraitUpsideDown.hidden = YES;
    _containerViewLandscapeLeft.hidden = YES;
    _containerViewLandscapeRight.hidden = YES;
    
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            if (!_containerViewPortrait) {
                [self layoutMessageContainerForDeviceOrientation:orientation];
            }
            
            [_containerViewPortrait.layer removeAllAnimations];
            [_containerViewPortrait.layer addAnimation:transition forKey:kCATransition];
            _containerViewPortrait.hidden = NO;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            if (!_containerViewPortraitUpsideDown) {
                [self layoutMessageContainerForDeviceOrientation:orientation];
            }
            
            [_containerViewPortraitUpsideDown.layer removeAllAnimations];
            [_containerViewPortraitUpsideDown.layer addAnimation:transition forKey:kCATransition];
            _containerViewPortraitUpsideDown.hidden = NO;
            break;
        case UIDeviceOrientationLandscapeLeft:
            if (!_containerViewLandscapeLeft) {
                [self layoutMessageContainerForDeviceOrientation:orientation];
            }
            [_containerViewLandscapeLeft.layer removeAllAnimations];
            [_containerViewLandscapeLeft.layer addAnimation:transition forKey:kCATransition];
            _containerViewLandscapeLeft.hidden = NO;
            break;
        case UIDeviceOrientationLandscapeRight:
            if (!_containerViewLandscapeRight) {
                [self layoutMessageContainerForDeviceOrientation:orientation];
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
    CATransition *transition = [TuneMessageStyling messageTransitionOutWithType:[self getTransitionTypeForOrientation:orientation] withEaseIn:YES];
    
    if (_lastAninmation) {
        transition.delegate = self;
        CATransition *maskTransition = [TuneMessageStyling messageBackgroundMaskTransition];
        [_backgroundMaskView.layer addAnimation:maskTransition forKey:kCATransition];
        _backgroundMaskView.hidden = YES;
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

- (void)deviceOrientationDidChange:(TuneSkyhookPayload *)payload {
    UIDeviceOrientation currentDeviceOrientation = [TuneMessageOrientationState getCurrentOrientation];
    
    if (currentDeviceOrientation == _lastOrientation) {
        // Do nothing
    } else {
        if ([TuneDeviceDetails orientationIsSupportedByApp:currentDeviceOrientation]) {
            self.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
            [self updateBackgroundMask];
            [self dismissOrientation:_lastOrientation];
            [self performSelector:@selector(handleTransitionToCurrentOrientation:) withObject:@(currentDeviceOrientation) afterDelay:0.2];
        }
    }
}

@end
