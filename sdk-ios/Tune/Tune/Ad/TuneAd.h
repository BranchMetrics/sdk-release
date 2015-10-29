//
//  TuneAd.h
//  Tune
//
//  Created by Harshal Ogale on 5/14/14.
//  Copyright (c) 2014 Tune Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "TuneAdView.h"

@class TuneAdMetadata;

@interface TuneAd : NSObject

FOUNDATION_EXPORT const CGFloat TUNE_AD_DEFAULT_BANNER_HEIGHT_IPHONE_PORTRAIT;
FOUNDATION_EXPORT const CGFloat TUNE_AD_DEFAULT_BANNER_HEIGHT_IPHONE_LANDSCAPE;
FOUNDATION_EXPORT const CGFloat TUNE_AD_DEFAULT_BANNER_HEIGHT_IPAD_PORTRAIT;
FOUNDATION_EXPORT const CGFloat TUNE_AD_DEFAULT_BANNER_HEIGHT_IPAD_LANDSCAPE;

FOUNDATION_EXPORT const NSTimeInterval TUNE_AD_DEFAULT_BANNER_CYCLE_DURATION;

@property (nonatomic, assign) TuneAdType type; // locally assigned
@property (nonatomic, copy) NSString *placement; // locally assigned
@property (nonatomic, copy) TuneAdMetadata *metadata; // locally assigned
@property (nonatomic, assign) TuneAdOrientation orientations;

@property (nonatomic, assign) CGFloat duration;
@property (nonatomic, assign) BOOL usesNativeCloseButton;

@property (nonatomic, copy) NSString *color;
@property (nonatomic, copy) NSString *html;
@property (nonatomic, copy) NSDictionary *refs;
@property (nonatomic, copy) NSString *requestId;

+ (instancetype)adBannerFromDictionary:(NSDictionary *)dict placement:(NSString *)placement metadata:(TuneAdMetadata *)metadata orientations:(TuneAdOrientation)orientations;
+ (instancetype)adInterstitialFromDictionary:(NSDictionary *)dict placement:(NSString *)placement metadata:(TuneAdMetadata *)metadata orientations:(TuneAdOrientation)orientations;
+ (instancetype)ad:(TuneAdType)adType placement:(NSString *)placement metadata:(TuneAdMetadata *)metadata orientations:(TuneAdOrientation)orientations fromDictionary:(NSDictionary *)dict;

+ (CGFloat)bannerHeightPortrait;
+ (CGFloat)bannerHeightLandscape;

@end
