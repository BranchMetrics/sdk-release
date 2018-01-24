//
//  TuneModalMessageDefaults.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/10/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneModalMessageDefaults.h"
#import "TuneInAppUtils.h"

@implementation TuneModalMessageDefaults

// Transition
TuneMessageTransition const TuneModalMessageDefaultTransition = TuneMessageTransitionFadeIn;

// Padding
int const TuneModalMessageDefaultPaddingVertical = 25;
int const TuneModalMessageDefaultPaddingHorizontal = 20;
int const TuneModalMessageDefaultContentPadding = 10;

// Shadow
int const TuneModalMessageShadowHeight = 5;

// Size
int const TuneModalMessageDefaultWidthOnPhone = 300;
int const TuneModalMessageDefaultWidthOnTablet = 300;
// These heights exclude the bottom buttons
int const TuneModalMessageDefaultHeightOnPhone = 300;
int const TuneModalMessageDefaultHeightOnTablet = 300;

// Corners
int const TuneModalMessageDefaultCornerRadius = 10;
TuneModalMessageEdgeStyle const TuneModalMessageDefaultEdgeStyle = TuneModalMessageRoundedCorners;

// Background Color
+ (UIColor *)defaultModalBackgroundColor {
    return [TuneInAppUtils colorWithString:@"FFFFFF"];
}

// Background Mask Color
+ (UIColor *)defaultModalBackgroundMaskColor {
    return [TuneInAppUtils colorWithString:@"FFFFFF"];
}

@end
