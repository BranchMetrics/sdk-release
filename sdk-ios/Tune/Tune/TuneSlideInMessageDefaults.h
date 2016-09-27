//
//  TuneSlideInMessageDefaults.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessageConstants.h"

@interface TuneSlideInMessageDefaults : NSObject

// Size
+ (CGFloat)slideInMessageDefaultHeightByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;
+ (CGFloat)slideInMessageDefaultWidthByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;

// Location
FOUNDATION_EXPORT TuneMessageLocationType const SlideInMessageDefaultLocationType;

// Background Color
+ (UIColor *)slideInMessageDefaultMessageBackgroundColor;

// Close button
FOUNDATION_EXPORT TuneMessageCloseButtonColor const SlideInMessageDefaultCloseButtonColor;
FOUNDATION_EXPORT BOOL const SlideInMessageDefaultCloseButtonHidden;
FOUNDATION_EXPORT CGFloat const SlideInMessageCloseButtonSize;
+ (CGFloat)slideInMessageCloseButtonPaddingByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;
+ (CGRect)slideInMessageCloseButtonFrameByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;
+ (CGRect)slideInMessageCloseButtonClickOverlayFrameByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;

// Message Area
+ (UIFont *)slideInMessageDefaultMessageFontByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;
+ (CGFloat)slideInMessageDefaultMessageAreaWidthByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;
+ (CGFloat)slideInMessageDefaultMessageAreaHorizontalPaddingByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;
+ (CGFloat)slideInMesasgeDefaultMessageNumberOfLinesByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;
+ (UIColor *)slideInMesasgeDefaultMessageTextColor;
+ (int)slideInMessageDefaultMessageTextAlignment;

// CTA Image
+ (UIFont *)slideInMessageDefaultButtonFont;
+ (UIColor *)slideInMessageDefaultButtonTextColor;
+ (UIColor *)slideInMessageDefaultButtonBackgroundColor;
+ (CGRect)slideInMessageCTAButtonFrameByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;
+ (CGFloat)slideInMessageCTAButtonHeightByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;
+ (CGRect)slideInMessageCTAImageFrameByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;
+ (CGFloat)slideInMessageDefaultCTAImageAreaWidthByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;
+ (CGFloat)slideInMessageDefaultCTAImageAreaHeightByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;

@end
