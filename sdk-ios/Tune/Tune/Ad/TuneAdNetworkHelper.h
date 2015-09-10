//
//  TuneAdNetworkHelper.h
//  Tune
//
//  Created by Harshal Ogale on 6/6/14.
//  Copyright (c) 2014 Tune Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "../TuneAdView.h"

@class TuneAd;
@class TuneAdMetadata;
@class TuneAdParams;


@interface TuneAdNetworkHelper : NSObject <NSURLConnectionDelegate>

- (void)fireUrl:(NSString *)urlString adType:(TuneAdType)adType placement:(NSString *)placement metadata:(TuneAdMetadata *)metadata orientations:(TuneAdOrientation)orientations ad:(TuneAd *)ad;

+ (void)fireUrl:(NSString *)urlString ad:(TuneAd *)ad;

@end
