//
//  TunePopUpMessageDefaults.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/10/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TunePopUpMessageDefaults.h"
#import "TuneInAppUtils.h"

@implementation TunePopUpMessageDefaults

// Transition
TuneMessageTransition const TunePopUpMessageDefaultTransition = TuneMessageTransitionFadeIn;

// Padding
int const TunePopUpMessageDefaultPaddingVertical = 25;
int const TunePopUpMessageDefaultPaddingHorizontal = 20;
int const TunePopUpMessageDefaultContentPadding = 10;

// Shadow
int const TunePopUpMessageShadowHeight = 5;

// Size
int const TunePopUpMessageDefaultWidthOnPhone = 300;
int const TunePopUpMessageDefaultWidthOnTablet = 300;
// These heights exclude the bottom buttons
int const TunePopUpMessageDefaultHeightOnPhone = 250;
int const TunePopUpMessageDefaultHeightOnTablet = 250;

// Corners
int const TunePopUpMessageDefaultCornerRadius = 10;
TunePopUpMessageEdgeStyle const TunePopUpMessageDefaultEdgeStyle = TunePopUpMessageRoundedCorners;

// Buttons
int const TunePopUpMessageButtonHeight = 55;
int const TunePopUpMessageButtonBorderWidth = 1;

// Image
int const TunePopUpMessageDefaultImageHeight = 100;

// Close button
int const TunePopUpCloseButtonOffset = -5;
int const TunePopUpCloseButtonSize = 25;
TuneMessageCloseButtonColor const TunePopUpdateCloseButtonDefaultColor = TunePopUpMessageCloseButtonColorRed;

// Background Color
+ (UIColor *)defaultPopUpBackgroundColor {
    return [TuneInAppUtils colorWithString:@"FFFFFF"];
}

// Background Mask Color
+ (UIColor *)defaultPopUpBackgroundMaskColor {
    return [TuneInAppUtils colorWithString:@"FFFFFF"];
}

// Headline text
+ (UIFont *)popUpMessageDefaultHeadlineFont {
    return  [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
}

+ (UIColor *)popUpMesasgeDefaultHeadlineTextColor {
    return [TuneInAppUtils colorWithString:@"333333"];
}

+ (int)popUpMessageDefaultHeadlineTextAlignment {
    return NSTextAlignmentCenter;
}

// Body text
+ (UIFont *)popUpMessageDefaultBodyFont {
    return  [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
}

+ (UIColor *)popUpMesasgeDefaultBodyTextColor {
    return [TuneInAppUtils colorWithString:@"333333"];
}

+ (int)popUpMessageDefaultBodyTextAlignment {
    return NSTextAlignmentCenter;
}

// Cta Button text
+ (UIFont *)popUpMessageDefaultCtaButtonFont {
    return [UIFont fontWithName:@"HelveticaNeue-Medium" size:16];
}

+ (UIColor *)popUpMessageDefaultCtaButtonTextColor {
    return [UIColor whiteColor];
}

+ (UIColor *)popUpMessageDefaultCtaButtonBackgroundColor {
    return [TuneInAppUtils colorWithString:@"#557ebf"];
}
// Cta Button text
+ (UIFont *)popUpMessageDefaultCancelButtonFont {
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
}

+ (UIColor *)popUpMessageDefaultCancelButtonTextColor {
    return [TuneInAppUtils colorWithString:@"#333333"];
}

+ (UIColor *)popUpMessageDefaultCancelButtonBackgroundColor {
    return [TuneInAppUtils colorWithString:@"#f6f6f6"];
}

@end
