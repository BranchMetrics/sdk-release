//
//  TuneBanner.h
//  Tune
//
//  Created by John Gu on 6/11/15.
//  Copyright (c) 2015 Tune Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TuneAdMetadata.h"

/*!
 Tune ad view used to display banner ads.
 */
@interface TuneBanner : UIView <TuneAdView>

/*!
 Delegate that handles callbacks from TuneAdView
 */
@property (nonatomic, assign) id<TuneAdDelegate> delegate;

/*!
 Allowed orientation(s) for this TuneAdView
 */
@property (nonatomic, assign, setter=setAllowedOrientations:) TuneAdOrientation adOrientations;

/*!
 Flag to check if the next ad is ready for display
 */
@property (nonatomic, getter=isReady, readonly) BOOL ready;


/*!
 Method to create a new ad view with the specified ad type and delegate. This method immediately starts fetching a new ad and sends an appropriate callback to the delegate as soon as the fetch request completes. Defaults to ads with portrait and/or landscape orientation(s) depending on the supported orientations mentioned in Info.plist project settings.
 */
+ (instancetype)adView;

/*!
 Method to create a new ad view with the specified ad type and delegate. This method immediately starts fetching a new ad and sends an appropriate callback to the delegate as soon as the fetch request completes. Defaults to ads with portrait and/or landscape orientation(s) depending on the supported orientations mentioned in Info.plist project settings.
 @param adViewDelegate A delegate used by TuneAdView to post success and failure callbacks
 */
+ (instancetype)adViewWithDelegate:(id<TuneAdDelegate>)adViewDelegate;

/*!
 Method to create a new ad view with the specified ad type, delegate and orientation. This method immediately starts fetching a new ad and sends an appropriate callback to the delegate as soon as the fetch request completes.
 @param adViewDelegate A delegate used by TuneAdView to post success and failure callbacks
 @param allowedOrientations Orientations supported by this ad view, e.g. TuneAdOrientationAll, TuneAdOrientationPortrait, TuneAdOrientationLandscape
 */
+ (instancetype)adViewWithDelegate:(id<TuneAdDelegate>)adViewDelegate
                      orientations:(TuneAdOrientation)allowedOrientations;

/*!
 Method to be called to restart ad loading
 @param placement Ad view placement info, e.g. "menu_page", "highscores", "game-end"
 */
- (void)showForPlacement:(NSString *)placement;

/*!
 Method to be called to restart ad loading
 @param placement Ad view placement info, e.g. "menu_page", "highscores", "game-end"
 @param metadata Properties to be included when requesting ads for an ad view
 */
- (void)showForPlacement:(NSString *)placement adMetadata:(TuneAdMetadata *)metadata;

@end
