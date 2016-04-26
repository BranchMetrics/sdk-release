//
//  TuneSlideInMessageDefaults.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneSlideInMessageDefaults.h"

@implementation TuneSlideInMessageDefaults


#pragma mark - Size & Location
+ (CGFloat)slideInMessageDefaultHeightByDeviceOrientation:(TuneMessageDeviceOrientation)orientation {
    CGFloat height = 0;
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
        case TuneMessageOrientationPhonePortrait_568:
        case TuneMessageOrientationPhonePortraitUpsideDown_568:
        case TuneMessageOrientationPhonePortrait_667:
        case TuneMessageOrientationPhonePortraitUpsideDown_667:
        case TuneMessageOrientationPhonePortrait_736:
        case TuneMessageOrientationPhonePortraitUpsideDown_736:
            height = 50;
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            height = 32;
            break;
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
            height = 66;
            break;
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
            height = 66;
            break;
        case TuneMessageOrientationNA:
            break;
    }
    return height;
}

+ (CGFloat)slideInMessageDefaultWidthByDeviceOrientation:(TuneMessageDeviceOrientation)orientation {
    CGFloat width = 0;
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
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

// Location
TuneMessageLocationType const SlideInMessageDefaultLocationType = TuneMessageLocationTop;

#pragma mark - Background

+ (UIColor *)slideInMessageDefaultMessageBackgroundColor {
    return [UIColor blackColor];
}

#pragma mark - Close Button

TuneMessageCloseButtonColor const SlideInMessageDefaultCloseButtonColor = TuneSlideInMessageCloseButtonColorBlack;
BOOL const SlideInMessageDefaultCloseButtonHidden = NO;
CGFloat const SlideInMessageCloseButtonSize = 16;

+ (CGFloat)slideInMessageCloseButtonPaddingByDeviceOrientation:(TuneMessageDeviceOrientation)orientation {
    CGFloat padding = 0;
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
        case TuneMessageOrientationPhonePortrait_568:
        case TuneMessageOrientationPhonePortraitUpsideDown_568:
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
        case TuneMessageOrientationPhonePortrait_667:
        case TuneMessageOrientationPhonePortraitUpsideDown_667:
        case TuneMessageOrientationPhonePortrait_736:
        case TuneMessageOrientationPhonePortraitUpsideDown_736:
            padding = 6;
            break;
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

+ (CGRect)slideInMessageCloseButtonFrameByDeviceOrientation:(TuneMessageDeviceOrientation)orientation {
    CGFloat rightPadding = [TuneSlideInMessageDefaults slideInMessageCloseButtonPaddingByDeviceOrientation:orientation];
    CGFloat topPadding = 0;
    
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
            topPadding = 6;
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            topPadding = ceil(([TuneSlideInMessageDefaults slideInMessageDefaultHeightByDeviceOrientation:orientation] - SlideInMessageCloseButtonSize)/2);
            break;
        case TuneMessageOrientationNA:
            break;
    }
    
    CGRect frame = CGRectMake([TuneSlideInMessageDefaults slideInMessageDefaultWidthByDeviceOrientation:orientation] - rightPadding - SlideInMessageCloseButtonSize, topPadding, SlideInMessageCloseButtonSize, SlideInMessageCloseButtonSize);
    
    return frame;
}

+ (CGRect)slideInMessageCloseButtonClickOverlayFrameByDeviceOrientation:(TuneMessageDeviceOrientation)orientation {
    CGFloat closeButtonClickOverlaySize = 0;
    
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
            closeButtonClickOverlaySize = 36;
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            closeButtonClickOverlaySize = 36;
            break;
        case TuneMessageOrientationNA:
            break;
    }
    
    CGRect frame = CGRectMake([TuneSlideInMessageDefaults slideInMessageDefaultWidthByDeviceOrientation:orientation] - closeButtonClickOverlaySize, 0, closeButtonClickOverlaySize, [TuneSlideInMessageDefaults slideInMessageDefaultHeightByDeviceOrientation:orientation]);
    return frame;
}


#pragma mark - Message Area

+ (UIFont *)slideInMessageDefaultMessageFontByDeviceOrientation:(TuneMessageDeviceOrientation)orientation
{
    UIFont *buttonFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
        case TuneMessageOrientationPhonePortrait_568:
        case TuneMessageOrientationPhonePortraitUpsideDown_568:
        case TuneMessageOrientationPhonePortrait_667:
        case TuneMessageOrientationPhonePortraitUpsideDown_667:
        case TuneMessageOrientationPhonePortrait_736:
        case TuneMessageOrientationPhonePortraitUpsideDown_736:
            buttonFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            buttonFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
            break;
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
            buttonFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:14];
            break;
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
            buttonFont = [UIFont fontWithName:@"HelveticaNeue-Medium" size:20];
            break;
        case TuneMessageOrientationNA:
            break;
    }
    
    return buttonFont;
}

+ (CGFloat)slideInMessageDefaultMessageAreaWidthByDeviceOrientation:(TuneMessageDeviceOrientation)orientation
{
    CGFloat width = 0;
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
        case TuneMessageOrientationPhonePortrait_568:
        case TuneMessageOrientationPhonePortraitUpsideDown_568:
            width = 272; // 320 - 48
            break;
        case TuneMessageOrientationPhonePortrait_667:
        case TuneMessageOrientationPhonePortraitUpsideDown_667:
            width = 327; // 375 - 48
            break;
        case TuneMessageOrientationPhonePortrait_736:
        case TuneMessageOrientationPhonePortraitUpsideDown_736:
            width = 366; // 414 - 48
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
            width = 424; // 480 - 56
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
            width = 512; // 568 - 56
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
            width = 611; // 667 - 56
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            width = 680; // 736 - 56
            break;
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
            width = 513;
            break;
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
            width = 769;
            break;
        case TuneMessageOrientationNA:
            break;
    }
    
    return width;
}

+ (CGFloat)slideInMessageDefaultMessageAreaHorizontalPaddingByDeviceOrientation:(TuneMessageDeviceOrientation)orientation
{
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
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
            padding = 20;
            break;
        case TuneMessageOrientationNA:
            break;
    }
    
    return padding;
}


+ (CGFloat)slideInMesasgeDefaultMessageNumberOfLinesByDeviceOrientation:(TuneMessageDeviceOrientation)orientation {
    CGFloat numberOfLines = 0;
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
        case TuneMessageOrientationPhonePortrait_568:
        case TuneMessageOrientationPhonePortraitUpsideDown_568:
        case TuneMessageOrientationPhonePortrait_667:
        case TuneMessageOrientationPhonePortraitUpsideDown_667:
        case TuneMessageOrientationPhonePortrait_736:
        case TuneMessageOrientationPhonePortraitUpsideDown_736:
            numberOfLines = 2;
            break;
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            numberOfLines = 2;
            break;
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
            numberOfLines = 2;
            break;
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
            numberOfLines = 2;
            break;
        case TuneMessageOrientationNA:
            break;
    }
    
    return numberOfLines;
    
}

+ (UIColor *)slideInMesasgeDefaultMessageTextColor {
    return [UIColor whiteColor];
}

+ (int)slideInMessageDefaultMessageTextAlignment {
    return NSTextAlignmentLeft;
}

#pragma mark - CTA Image & Button
// NOTE: This is only used on tablets

+ (UIFont *)slideInMessageDefaultButtonFont {
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
}

+ (UIColor *)slideInMessageDefaultButtonTextColor {
    return [UIColor whiteColor];
}


+ (UIColor *)slideInMessageDefaultButtonBackgroundColor {
    return [UIColor blackColor];
}

+ (CGRect)slideInMessageCTAButtonFrameByDeviceOrientation:(TuneMessageDeviceOrientation)orientation {
    CGFloat xOrigin = 0;
    CGFloat yOrigin  = 0;
    CGFloat closeButtonPadding = [TuneSlideInMessageDefaults slideInMessageCloseButtonPaddingByDeviceOrientation:orientation];
    CGFloat horizontalPadding = [TuneSlideInMessageDefaults slideInMessageDefaultMessageAreaHorizontalPaddingByDeviceOrientation:orientation];
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
        case TuneMessageOrientationPhonePortrait_568:
        case TuneMessageOrientationPhonePortraitUpsideDown_568:
        case TuneMessageOrientationPhonePortrait_667:
        case TuneMessageOrientationPhonePortraitUpsideDown_667:
        case TuneMessageOrientationPhonePortrait_736:
        case TuneMessageOrientationPhonePortraitUpsideDown_736:
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            // Not applicable to phone
            break;
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
            xOrigin = [TuneSlideInMessageDefaults slideInMessageDefaultWidthByDeviceOrientation:orientation] - (closeButtonPadding * 2) - SlideInMessageCloseButtonSize - horizontalPadding - [TuneSlideInMessageDefaults slideInMessageDefaultCTAImageAreaWidthByDeviceOrientation:orientation];
            yOrigin = 14;
            break;
        case TuneMessageOrientationNA:
            break;
    }
    
    return CGRectMake(xOrigin, yOrigin, [TuneSlideInMessageDefaults slideInMessageDefaultCTAImageAreaWidthByDeviceOrientation:orientation], [TuneSlideInMessageDefaults slideInMessageCTAButtonHeightByDeviceOrientation:orientation]);
}

+ (CGFloat)slideInMessageCTAButtonHeightByDeviceOrientation:(TuneMessageDeviceOrientation)orientation {
    CGFloat height = 0;
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
        case TuneMessageOrientationPhonePortrait_568:
        case TuneMessageOrientationPhonePortraitUpsideDown_568:
        case TuneMessageOrientationPhonePortrait_667:
        case TuneMessageOrientationPhonePortraitUpsideDown_667:
        case TuneMessageOrientationPhonePortrait_736:
        case TuneMessageOrientationPhonePortraitUpsideDown_736:
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            // Not applicable to phone
            height = 0;
            break;
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
            height = 38;
            break;
        case TuneMessageOrientationNA:
            break;
    }
    
    return height;
}

+ (CGRect)slideInMessageCTAImageFrameByDeviceOrientation:(TuneMessageDeviceOrientation)orientation {
    
    CGFloat xOrigin = 0;
    CGFloat yOrigin  = 0;
    CGFloat closeButtonPadding = [TuneSlideInMessageDefaults slideInMessageCloseButtonPaddingByDeviceOrientation:orientation];
    CGFloat horizontalPadding = [TuneSlideInMessageDefaults slideInMessageDefaultMessageAreaHorizontalPaddingByDeviceOrientation:orientation];
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
        case TuneMessageOrientationPhonePortrait_568:
        case TuneMessageOrientationPhonePortraitUpsideDown_568:
        case TuneMessageOrientationPhonePortrait_667:
        case TuneMessageOrientationPhonePortraitUpsideDown_667:
        case TuneMessageOrientationPhonePortrait_736:
        case TuneMessageOrientationPhonePortraitUpsideDown_736:
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            // Not applicable to phone
            break;
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
            xOrigin = [TuneSlideInMessageDefaults slideInMessageDefaultWidthByDeviceOrientation:orientation] - (closeButtonPadding * 2) - SlideInMessageCloseButtonSize - horizontalPadding - [TuneSlideInMessageDefaults slideInMessageDefaultCTAImageAreaWidthByDeviceOrientation:orientation];
            break;
        case TuneMessageOrientationNA:
            break;
    }
    
    return CGRectMake(xOrigin, yOrigin, [TuneSlideInMessageDefaults slideInMessageDefaultCTAImageAreaWidthByDeviceOrientation:orientation], [TuneSlideInMessageDefaults slideInMessageDefaultCTAImageAreaHeightByDeviceOrientation:orientation]);
}

+ (CGFloat)slideInMessageDefaultCTAImageAreaWidthByDeviceOrientation:(TuneMessageDeviceOrientation)orientation
{
    CGFloat width = 0;
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
        case TuneMessageOrientationPhonePortrait_568:
        case TuneMessageOrientationPhonePortraitUpsideDown_568:
        case TuneMessageOrientationPhonePortrait_667:
        case TuneMessageOrientationPhonePortraitUpsideDown_667:
        case TuneMessageOrientationPhonePortrait_736:
        case TuneMessageOrientationPhonePortraitUpsideDown_736:
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            // Not applicable to phone
            width = 0;
            break;
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
            width = 147;
            break;
        case TuneMessageOrientationNA:
            break;
    }
    
    return width;
}


+ (CGFloat)slideInMessageDefaultCTAImageAreaHeightByDeviceOrientation:(TuneMessageDeviceOrientation)orientation
{
    CGFloat height = 0;
    
    switch (orientation) {
        case TuneMessageOrientationPhonePortrait_480:
        case TuneMessageOrientationPhonePortraitUpsideDown_480:
        case TuneMessageOrientationPhonePortrait_568:
        case TuneMessageOrientationPhonePortraitUpsideDown_568:
        case TuneMessageOrientationPhonePortrait_667:
        case TuneMessageOrientationPhonePortraitUpsideDown_667:
        case TuneMessageOrientationPhonePortrait_736:
        case TuneMessageOrientationPhonePortraitUpsideDown_736:
        case TuneMessageOrientationPhoneLandscapeLeft_480:
        case TuneMessageOrientationPhoneLandscapeRight_480:
        case TuneMessageOrientationPhoneLandscapeLeft_568:
        case TuneMessageOrientationPhoneLandscapeRight_568:
        case TuneMessageOrientationPhoneLandscapeLeft_667:
        case TuneMessageOrientationPhoneLandscapeRight_667:
        case TuneMessageOrientationPhoneLandscapeLeft_736:
        case TuneMessageOrientationPhoneLandscapeRight_736:
            // Not applicable to phone
            height = 0;
            break;
        case TuneMessageOrientationTabletPortrait:
        case TuneMessageOrientationTabletPortraitUpsideDown:
        case TuneMessageOrientationTabletLandscapeLeft:
        case TuneMessageOrientationTabletLandscapeRight:
            height = 66;
            break;
        case TuneMessageOrientationNA:
            break;
    }
    
    return height;
}


@end
