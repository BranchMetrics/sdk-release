//
//  TunePopUpMessageDefaults.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/10/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessageConstants.h"

@interface TunePopUpMessageDefaults : NSObject

// Transition
FOUNDATION_EXPORT TuneMessageTransition const TunePopUpMessageDefaultTransition;

// Padding
FOUNDATION_EXPORT int const TunePopUpMessageDefaultPaddingVertical;
FOUNDATION_EXPORT int const TunePopUpMessageDefaultPaddingHorizontal;
FOUNDATION_EXPORT int const TunePopUpMessageDefaultContentPadding;

// Shadow
FOUNDATION_EXPORT int const TunePopUpMessageShadowHeight;

// Size
FOUNDATION_EXPORT int const TunePopUpMessageDefaultWidthOnPhone;
FOUNDATION_EXPORT int const TunePopUpMessageDefaultWidthOnTablet;
// These heights exclude the bottom buttons
FOUNDATION_EXPORT int const TunePopUpMessageDefaultHeightOnPhone;
FOUNDATION_EXPORT int const TunePopUpMessageDefaultHeightOnTablet;

// Corners
FOUNDATION_EXPORT int const TunePopUpMessageDefaultCornerRadius;
FOUNDATION_EXPORT TunePopUpMessageEdgeStyle const TunePopUpMessageDefaultEdgeStyle;

// Buttons
FOUNDATION_EXPORT int const TunePopUpMessageButtonHeight;
FOUNDATION_EXPORT int const TunePopUpMessageButtonBorderWidth;

// Image
FOUNDATION_EXPORT int const TunePopUpMessageDefaultImageHeight;

// Close button
FOUNDATION_EXPORT int const TunePopUpCloseButtonOffset;
FOUNDATION_EXPORT int const TunePopUpCloseButtonSize;
FOUNDATION_EXPORT TuneMessageCloseButtonColor const TunePopUpdateCloseButtonDefaultColor;

// Background color
+ (UIColor *)defaultPopUpBackgroundColor;
+ (UIColor *)defaultPopUpBackgroundMaskColor;

// Headline text
+ (UIFont *)popUpMessageDefaultHeadlineFont;
+ (UIColor *)popUpMesasgeDefaultHeadlineTextColor;
+ (int)popUpMessageDefaultHeadlineTextAlignment;

// Body text
+ (UIFont *)popUpMessageDefaultBodyFont;
+ (UIColor *)popUpMesasgeDefaultBodyTextColor;
+ (int)popUpMessageDefaultBodyTextAlignment;


// CtaButton text
+ (UIFont *)popUpMessageDefaultCtaButtonFont;
+ (UIColor *)popUpMessageDefaultCtaButtonTextColor;
+ (UIColor *)popUpMessageDefaultCtaButtonBackgroundColor;

// CancelButton text
+ (UIFont *)popUpMessageDefaultCancelButtonFont;
+ (UIColor *)popUpMessageDefaultCancelButtonTextColor;
+ (UIColor *)popUpMessageDefaultCancelButtonBackgroundColor;

@end
