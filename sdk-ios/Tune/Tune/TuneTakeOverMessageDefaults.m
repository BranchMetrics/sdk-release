//
//  TuneTakeOverMessageDefaults.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/8/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneTakeOverMessageDefaults.h"

@implementation TuneTakeOverMessageDefaults

#pragma mark - Size
+ (CGFloat)takeOverMessageDefaultHeightByDeviceOrientation:(TuneMessageDeviceOrientation)orientation {
    CGFloat height = 0;
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
            height = 480;
            break;
        case TuneMessageOrientationPhonePortrait_568:
        case TuneMessageOrientationPhonePortraitUpsideDown_568:
            height = 568;
            break;
        case TuneMessageOrientationPhonePortrait_667:
        case TuneMessageOrientationPhonePortraitUpsideDown_667:
            height = 667;
            break;
        case TuneMessageOrientationPhonePortrait_736:
        case TuneMessageOrientationPhonePortraitUpsideDown_736:
            height = 736;
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
            height = 320;
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
            height = 320;
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
            height = 375;
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            height = 414;
            break;
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
            height = 1024;
            break;
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
            height = 768;
            break;
        case TuneMessageOrientationNA:
            break;
    }
    return height;
}

+ (CGFloat)takeOverMessageDefaultWidthByDeviceOrientation:(TuneMessageDeviceOrientation)orientation {
    CGFloat width = 0;
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
            width = 320;
            break;
        case TuneMessageOrientationPhonePortrait_568:
        case TuneMessageOrientationPhonePortraitUpsideDown_568:
            width = 320;
            break;
        case TuneMessageOrientationPhonePortrait_667:
        case TuneMessageOrientationPhonePortraitUpsideDown_667:
            width = 375;
            break;
        case TuneMessageOrientationPhonePortrait_736:
        case TuneMessageOrientationPhonePortraitUpsideDown_736:
            width = 414;
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
            width = 480;
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
            width = 568;
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
            width = 667;
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            width = 736;
            break;
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
            width = 768;
            break;
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
            width = 1024;
            break;
        case TuneMessageOrientationNA:
            break;
    }
    
    return width;
}

#pragma mark - Background Mask
TuneMessageBackgroundMaskType const TakeOverMessageDefaultBackgroundMaskColor = TuneMessageBackgroundMaskTypeLight;


#pragma mark - Close Button

TuneMessageCloseButtonColor const TakeOverMessageDefaultCloseButtonColor = TuneTakeOverMessageCloseButtonColorBlack;
TuneTakeOverMessageCloseButtonLocationType const TuneTakeOverMessageDefaultCloseButtonLocation = TuneTakeOverMessageCloseButtonLocationRight;

CGFloat const TakeOverMessageCloseButtonSize = 25;

+ (CGFloat)takeOverMessageCloseButtonPaddingByDeviceOrientation:(TuneMessageDeviceOrientation)orientation {
    CGFloat padding = 0;
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
        case TuneMessageOrientationPhonePortrait_568:
        case TuneMessageOrientationPhonePortraitUpsideDown_568:
        case TuneMessageOrientationPhonePortrait_667:
        case TuneMessageOrientationPhonePortraitUpsideDown_667:
        case TuneMessageOrientationPhonePortrait_736:
        case TuneMessageOrientationPhonePortraitUpsideDown_736:
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            padding = 10;
            break;
        case TuneMessageOrientationNA:
            break;
    }
    
    return padding;
}

+ (CGRect)takeOverMessageCloseButtonFrameByDeviceOrientation:(TuneMessageDeviceOrientation)orientation
                                      andCloseButtonLocation:(TuneTakeOverMessageCloseButtonLocationType)closeButtonLocation {
    CGFloat padding = [TuneTakeOverMessageDefaults takeOverMessageCloseButtonPaddingByDeviceOrientation:orientation];
    CGFloat statusBarOffset = 0;
    
#if TARGET_OS_IOS
    statusBarOffset = [UIApplication sharedApplication].statusBarHidden ? 0 : 10;
#endif
    
    CGRect frame;
    if (closeButtonLocation == TuneTakeOverMessageCloseButtonLocationRight) {
        frame = CGRectMake([TuneTakeOverMessageDefaults takeOverMessageDefaultWidthByDeviceOrientation:orientation] - padding - TakeOverMessageCloseButtonSize, padding + statusBarOffset, TakeOverMessageCloseButtonSize, TakeOverMessageCloseButtonSize);
    }
    else {
        frame = CGRectMake(padding, padding + statusBarOffset, TakeOverMessageCloseButtonSize, TakeOverMessageCloseButtonSize);
    }
    
    return frame;
}

+ (CGRect)takeOverMessageCloseButtonClickOverlayFrameByDeviceOrientation:(TuneMessageDeviceOrientation)orientation
                                                  andCloseButtonLocation:(TuneTakeOverMessageCloseButtonLocationType)closeButtonLocation {
    CGFloat closeButtonClickOverlaySize = 45;
    CGRect frame;
    if (closeButtonLocation == TuneTakeOverMessageCloseButtonLocationRight) {
        frame = CGRectMake([TuneTakeOverMessageDefaults takeOverMessageDefaultWidthByDeviceOrientation:orientation] - closeButtonClickOverlaySize, 0, closeButtonClickOverlaySize, closeButtonClickOverlaySize);
    }
    else {
        frame = CGRectMake(0, 0, closeButtonClickOverlaySize, closeButtonClickOverlaySize);
    }
    
    return frame;
}

#pragma mark - Transition
TuneMessageTransition const DefaultTakeOverTransitionType = TuneMessageTransitionFromTop;

@end
