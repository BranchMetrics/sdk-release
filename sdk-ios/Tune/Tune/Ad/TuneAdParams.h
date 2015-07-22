//
//  TuneAdParams.h
//  Tune
//
//  Created by Harshal Ogale on 7/9/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../TuneAdView.h"
#import "TuneAd.h"

@interface TuneAdParams : NSObject

+ (NSString *)jsonForAdType:(TuneAdType)adType placement:(NSString *)placement metadata:(TuneAdMetadata *)metadata orientations:(TuneAdOrientation)orientations;
+ (NSString *)jsonForAdType:(TuneAdType)adType placement:(NSString *)placement metadata:(TuneAdMetadata *)metadata orientations:(TuneAdOrientation)orientations ad:(TuneAd *)ad;

@end
