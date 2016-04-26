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
extern TuneMessageTransition const TunePopUpMessageDefaultTransition;

// Padding
extern int const TunePopUpMessageDefaultPaddingVertical;
extern int const TunePopUpMessageDefaultPaddingHorizontal;
extern int const TunePopUpMessageDefaultContentPadding;

// Shadow
extern int const TunePopUpMessageShadowHeight;

// Size
extern int const TunePopUpMessageDefaultWidthOnPhone;
extern int const TunePopUpMessageDefaultWidthOnTablet;
// These heights exclude the bottom buttons
extern int const TunePopUpMessageDefaultHeightOnPhone;
extern int const TunePopUpMessageDefaultHeightOnTablet;

// Corners
extern int const TunePopUpMessageDefaultCornerRadius;
extern TunePopUpMessageEdgeStyle const TunePopUpMessageDefaultEdgeStyle;

// Buttons
extern int const TunePopUpMessageButtonHeight;
extern int const TunePopUpMessageButtonBorderWidth;

// Image
extern int const TunePopUpMessageDefaultImageHeight;

// Close button
extern int const TunePopUpCloseButtonOffset;
extern int const TunePopUpCloseButtonSize;
extern TuneMessageCloseButtonColor const TunePopUpdateCloseButtonDefaultColor;

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
