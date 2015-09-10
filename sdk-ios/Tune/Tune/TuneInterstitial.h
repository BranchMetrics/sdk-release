//
//  TuneInterstitial.h
//  Tune
//
//  Created by John Gu on 6/11/15.
//  Copyright (c) 2015 Tune Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TuneAdView.h"

@class TuneAdMetadata;

@protocol TuneAdDelegate;

/*!
 Tune ad view used to display interstitial ads.
 */
@interface TuneInterstitial : TuneAdView

/*!
 Method to create a new ad view. Defaults to ads with portrait and/or landscape orientation(s) depending on the supported orientations mentioned in Info.plist project settings.
 */
+ (instancetype)adView;

/*!
 Method to create a new ad view with the specified delegate. Defaults to ads with portrait and/or landscape orientation(s) depending on the supported orientations mentioned in Info.plist project settings.
 @param adViewDelegate A delegate used by TuneAdView to post success and failure callbacks
 */
+ (instancetype)adViewWithDelegate:(id<TuneAdDelegate>)adViewDelegate;

/*!
 Method to create a new ad view with the specified delegate and orientation.
 @param adViewDelegate A delegate used by TuneAdView to post success and failure callbacks
 @param allowedOrientations Orientations supported by this ad view, e.g. TuneAdOrientationAll, TuneAdOrientationPortrait, TuneAdOrientationLandscape
 */
+ (instancetype)adViewWithDelegate:(id<TuneAdDelegate>)adViewDelegate
                      orientations:(TuneAdOrientation)allowedOrientations;

/*!
 Method to be called to cache ads for the given placement
 @param placement Ad view placement info, e.g. "menu_page", "highscores", "game-end"
 */
- (void)cacheForPlacement:(NSString *)placement;

/*!
 Method to be called to cache ads for the given placement and metadata
 @param placement Ad view placement info, e.g. "menu_page", "highscores", "game-end"
 @param metadata Properties to be included when requesting ads for an ad view
 */
- (void)cacheForPlacement:(NSString *)placement adMetadata:(TuneAdMetadata *)metadata;

/*!
 Method to be called to display the next interstitial ad using the provided view controller. If a previously cached ad is not available, then a new ad will be requested and displayed.
 @param placement Ad view placement info, e.g. "menu_page", "highscores", "game-end"
 @param viewController View Controller to be used to display the interstitial ad
 */
- (void)showForPlacement:(NSString *)placement viewController:(UIViewController *)viewController;

/*!
 Method to be called to display the next interstitial ad using the provided view controller. If a previously cached ad is not available, then a new ad will be requested and displayed.
 @param placement Ad view placement info, e.g. "menu_page", "highscores", "game-end"
 @param viewController View Controller to be used to display the interstitial ad
 @param metadata Properties to be included when requesting ads for an ad view
 */
- (void)showForPlacement:(NSString *)placement viewController:(UIViewController *)viewController adMetadata:(TuneAdMetadata *)metadata;

@end
