//
//  TuneAdUtils.h
//  Tune
//
//  Created by Harshal Ogale on 9/1/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneAd.h"

FOUNDATION_EXPORT const NSString * TUNE_AD_SERVER;

@interface TuneAdUtils : NSObject

+ (NSNumber *)itunesItemIdFromUrl:(NSString *)url;
+ (NSDictionary *)itunesItemIdAndTokensFromUrl:(NSString *)url;

+ (NSString *)tuneAdServerUrl:(TuneAdType)type;
+ (NSString *)tuneAdClickUrl:(TuneAd *)ad;
+ (NSString *)tuneAdViewUrl:(TuneAd *)ad;
+ (NSString *)tuneAdClosedUrl:(TuneAd *)ad;

+ (NSString *)requestQueryParams:(TuneAd *)ad;

+ (UIWebView *)webviewForAdView:(CGSize)size
                webviewDelegate:(id<UIWebViewDelegate>)wd
             scrollviewDelegate:(id<UIScrollViewDelegate>)sd;

+ (NSTimeInterval)durationDelayForRetry:(NSInteger)attempt;

/*!
 Image for interstitial ad native close button.
 */
+ (UIImage*)closeButtonImage;

/*!
 Url-encodes the input string if it's not nil, NULL, otherwise returns an empty string.
 For NSDate objects, returns (long)timeIntervalSince1970.
 */
+ (NSString *)urlEncode:(id)value;

@end
