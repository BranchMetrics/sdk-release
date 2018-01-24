//
//  TuneBannerMessageDefaults.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneBannerMessageDefaults.h"

@implementation TuneBannerMessageDefaults


#pragma mark - Size & Location
+ (CGFloat)bannerMessageDefaultHeightByDeviceOrientation:(TuneMessageDeviceOrientation)orientation {
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

// Location
TuneMessageLocationType const BannerMessageDefaultLocationType = TuneMessageLocationTop;

@end
