//
//  TuneAdView_internal.h
//  MobileAppTracker
//
//  Created by Harshal Ogale on 8/6/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//


#import <StoreKit/StoreKit.h>

#import "TuneAdView.h"

@class TuneAd;
@class TuneAdMetadata;
@class TuneAdPlacementManager;
@class TuneAdSKStoreProductViewController;


@interface TuneAdView () <UIWebViewDelegate, UIScrollViewDelegate, SKStoreProductViewControllerDelegate>
{
    @protected
    
    /*!
     Ad type of this ad view.
     */
    TuneAdType adType;
    
    /*!
     Dictionary of (placement name, placement view) -- (NSString*, TunePlacementAdQueue)
     */
    NSMutableDictionary *placementAds;
    
    /*!
     First webview to be used to toggle between the current ad and the next pre-fetched ad
     */
    UIWebView *webview1;
    /*!
     Second webview to be used to toggle between the current ad and the next pre-fetched ad
     */
    UIWebView *webview2;
    
    /*!
     The ad currently being displayed
     */
    TuneAd *adCurrent;
    
    /*!
     The next ad to be displayed
     */
    TuneAd *adNext;
    
    /*!
     Ad has been loaded in the background webview and is ready for display
     */
    BOOL adReadyForDisplay;
    
    /*!
     is the in-app store currently visible
     */
    BOOL appStoreVisible;
    
    /*!
     Common error object
     */
    NSError *adError;
    
    /*!
     View controller to be used to present the modal in-app store view controller
     */
    UIViewController *parentViewController;
    
    /*!
     In-app store view controller
     */
    TuneAdSKStoreProductViewController *storeVC;
    
    /*!
     Activity indicator
     */
    UIActivityIndicatorView *activity;
    
    /*!
     Currently active webview.
     */
    NSInteger viewIndex;
    
    /*!
     Instance of a class that manages download and pre-fetch of ads for the given placement.
     */
    TuneAdPlacementManager *pm;
    
    /*!
     Is ad request pending
     */
    BOOL waitingForAd;
}

@property (nonatomic, getter=isReady) BOOL ready;


- (instancetype)initForAdType:(TuneAdType)type
                     delegate:(id<TuneAdDelegate>)adViewDelegate
                 orientations:(TuneAdOrientation)allowedOrientations;

- (void)internalInitForAdType:(TuneAdType)adType;

+ (TuneAdOrientation)defaultAdOrientation;

/*!
 Show the next webview and hide the currently visible webview.
 */
- (void)toggleWebviews;

/*!
 Loads empty html in the webview.
 */
- (void)clearWebview:(UIWebView *)webview;

/*!
 Preloads the currently unused webview with html content of the given ad.
 */
- (void)preloadAd:(TuneAd *)ad;

/*!
 Dismiss activity indicator overlay if it exists.
 */
- (void)dismissActivityOverlay;

- (void)getNextAd:(NSString *)placement metadata:(TuneAdMetadata *)metadata;

/*!
 Resizes ad webview for the new orientation.
 */
- (void)updateWebViewFrameForOrientation:(UIInterfaceOrientation)newOrientation;

/*!
 Handles ad view click action.
 @return YES if the url is being opened in the system browser, NO otherwise
 */
- (BOOL)handleAdClickWithUrl:(NSURL *)url;

- (void)showInAppStoreForAppId:(NSNumber *)itemId
                 campaignToken:(NSString *)cToken
                affiliateToken:(NSString *)aToken
                    requestUrl:(NSURL *)url;

- (void)notifyDidFetchAd:(NSString *)placement;
- (void)notifyClickActionStart:(BOOL)willLeave;
- (void)notifyClickActionEnd;
- (void)notifyClose;
- (void)notifyFailedWithError:(NSError *)error;
- (void)notifyAdRequestWithUrl:(NSString *)url data:(NSString *)data;

@end
