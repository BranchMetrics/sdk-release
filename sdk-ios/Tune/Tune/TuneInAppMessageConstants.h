//
//  TuneInAppMessageConstants.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

enum TuneMessageTransition {
    TuneMessageTransitionFromTop = 1,
    TuneMessageTransitionFromBottom,
    TuneMessageTransitionFromLeft,
    TuneMessageTransitionFromRight,
    TuneMessageTransitionFadeIn,
    TuneMessageTransitionNone
};
typedef enum TuneMessageTransition TuneMessageTransition;

enum TuneMessageLocationType {
    TuneMessageLocationTop = 1,
    TuneMessageLocationBottom,
    TuneMessageLocationCentered,
    TuneMessageLocationCustom,
};
typedef enum TuneMessageLocationType TuneMessageLocationType;

enum TuneMessageType {
    TuneMessageTypeSlideIn = 1,
    TuneMessageTypePopup,
    TuneMessageTypeTakeOver
};
typedef enum TuneMessageType TuneMessageType;

enum TuneMessageButtonType {
    TuneMessageButtonTypeNA = 1,
    TuneMessageButtonTypeCta,
    TuneMessageButtonTypeCancel,
};
typedef enum TuneMessageButtonType TuneMessageButtonType;

enum TuneTapBehavior {
    TuneTapBehaviorPowerHook = 1,
    TuneTapBehaviorURL,
    TuneTapBehaviorDismiss
};
typedef enum TuneTapBehavior TuneTapBehavior;

enum TuneMessageDeviceOrientation {
    TuneMessageOrientationPhonePortrait_480 = 1,
    TuneMessageOrientationPhonePortraitUpsideDown_480,
    TuneMessageOrientationPhonePortrait_568,
    TuneMessageOrientationPhonePortraitUpsideDown_568,
    TuneMessageOrientationPhonePortrait_667,
    TuneMessageOrientationPhonePortraitUpsideDown_667,
    TuneMessageOrientationPhonePortrait_736,
    TuneMessageOrientationPhonePortraitUpsideDown_736,
    TuneMessageOrientationPhoneLandscapeLeft_480,
    TuneMessageOrientationPhoneLandscapeLeft_568,
    TuneMessageOrientationPhoneLandscapeLeft_667,
    TuneMessageOrientationPhoneLandscapeLeft_736,
    TuneMessageOrientationPhoneLandscapeRight_480,
    TuneMessageOrientationPhoneLandscapeRight_568,
    TuneMessageOrientationPhoneLandscapeRight_667,
    TuneMessageOrientationPhoneLandscapeRight_736,
    TuneMessageOrientationTabletPortrait,
    TuneMessageOrientationTabletPortraitUpsideDown,
    TuneMessageOrientationTabletLandscapeLeft,
    TuneMessageOrientationTabletLandscapeRight,
    TuneMessageOrientationNA
};
typedef enum TuneMessageDeviceOrientation TuneMessageDeviceOrientation;

enum TuneMessageCloseButtonColor {
    TunePopUpMessageCloseButtonColorRed = 1,
    TunePopUpMessageCloseButtonColorBlack,
    TuneSlideInMessageCloseButtonColorWhite,
    TuneSlideInMessageCloseButtonColorBlack,
    TuneTakeOverMessageCloseButtonColorRed,
    TuneTakeOverMessageCloseButtonColorBlack
};
typedef enum TuneMessageCloseButtonColor TuneMessageCloseButtonColor;

enum TuneMessageBackgroundMaskType {
    TuneMessageBackgroundMaskTypeLight = 1,
    TuneMessageBackgroundMaskTypeDark,
    TuneMessageBackgroundMaskTypeBlur,
    TuneMessageBackgroundMaskTypeNone
};
typedef enum TuneMessageBackgroundMaskType TuneMessageBackgroundMaskType;

enum TuneTakeOverMessageCloseButtonLocationType {
    TuneTakeOverMessageCloseButtonLocationLeft = 1,
    TuneTakeOverMessageCloseButtonLocationRight
};
typedef enum TuneTakeOverMessageCloseButtonLocationType TuneTakeOverMessageCloseButtonLocationType;

enum TunePopUpMessageEdgeStyle {
    TunePopUpMessageSquareCorners = 1,
    TunePopUpMessageRoundedCorners
};
typedef enum TunePopUpMessageEdgeStyle TunePopUpMessageEdgeStyle;


@interface TuneInAppMessageConstants : NSObject

@end
