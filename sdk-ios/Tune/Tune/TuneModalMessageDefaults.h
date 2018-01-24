//
//  TuneModalMessageDefaults.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/10/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessageConstants.h"

@interface TuneModalMessageDefaults : NSObject

// Transition
FOUNDATION_EXPORT TuneMessageTransition const TuneModalMessageDefaultTransition;

// Padding
FOUNDATION_EXPORT int const TuneModalMessageDefaultPaddingVertical;
FOUNDATION_EXPORT int const TuneModalMessageDefaultPaddingHorizontal;
FOUNDATION_EXPORT int const TuneModalMessageDefaultContentPadding;

// Shadow
FOUNDATION_EXPORT int const TuneModalMessageShadowHeight;

// Size
FOUNDATION_EXPORT int const TuneModalMessageDefaultWidthOnPhone;
FOUNDATION_EXPORT int const TuneModalMessageDefaultWidthOnTablet;
// These heights exclude the bottom buttons
FOUNDATION_EXPORT int const TuneModalMessageDefaultHeightOnPhone;
FOUNDATION_EXPORT int const TuneModalMessageDefaultHeightOnTablet;

// Corners
FOUNDATION_EXPORT int const TuneModalMessageDefaultCornerRadius;
FOUNDATION_EXPORT TuneModalMessageEdgeStyle const TuneModalMessageDefaultEdgeStyle;

// Background color
+ (UIColor *)defaultModalBackgroundColor;
+ (UIColor *)defaultModalBackgroundMaskColor;


@end
