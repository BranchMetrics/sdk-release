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
    TuneMessageTypeBanner = 1,
    TuneMessageTypeModal,
    TuneMessageTypeFullScreen
};
typedef enum TuneMessageType TuneMessageType;

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

enum TuneMessageBackgroundMaskType {
    TuneMessageBackgroundMaskTypeLight = 1,
    TuneMessageBackgroundMaskTypeDark,
    TuneMessageBackgroundMaskTypeBlur,
    TuneMessageBackgroundMaskTypeNone
};
typedef enum TuneMessageBackgroundMaskType TuneMessageBackgroundMaskType;

enum TuneModalMessageEdgeStyle {
    TuneModalMessageSquareCorners = 1,
    TuneModalMessageRoundedCorners
};
typedef enum TuneModalMessageEdgeStyle TuneModalMessageEdgeStyle;


@interface TuneInAppMessageConstants : NSObject

@end
