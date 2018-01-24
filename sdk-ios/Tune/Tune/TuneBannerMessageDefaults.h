//
//  TuneBannerMessageDefaults.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessageConstants.h"

@interface TuneBannerMessageDefaults : NSObject

// Size
+ (CGFloat)bannerMessageDefaultHeightByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;

// Location
FOUNDATION_EXPORT TuneMessageLocationType const BannerMessageDefaultLocationType;

@end
