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

/*!
 Parent class that provides common functionality for Banner and Interstitial ad view classes.
 */
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
     Indicates if the in-app store is currently visible
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
     Indicates if an ad request is pending
     */
    BOOL waitingForAd;
}

/*!
 Indicates whether an ad is ready to be displayed.
 */
@property (nonatomic, getter=isReady) BOOL ready;


/*!
 Creates and returns a new ad view for showing ads of the specified type for the given orientations.
 @param type type of the ad -- Banner, Interstitial, etc.
 @param adViewDelegate a delegate that can handle the ad view callbacks
 @param allowedOrientations the orientations to be supported by the ad view
 */
- (instancetype)initForAdType:(TuneAdType)type
                     delegate:(id<TuneAdDelegate>)adViewDelegate
                 orientations:(TuneAdOrientation)allowedOrientations;

/*!
 Creates and returns a new ad view for showing ads of the specified type.
 @param type type of the ad -- Banner, Interstitial, etc.
 */
- (void)internalInitForAdType:(TuneAdType)type;

/*!
 A method that returns orientations that this app supports by default, as mentioned in the info.plist.
 */
+ (TuneAdOrientation)defaultAdOrientation;

/*!
 Show the next webview and hide the currently visible webview.
 */
- (void)toggleWebviews;

/*!
 Loads empty html in the webview.
 @param webview the UIWebView to be cleared by loading an empty html string
 */
- (void)clearWebview:(UIWebView *)webview;

/*!
 Preloads the currently unused webview with html content of the given ad.
 @param ad an ad instance
 */
- (void)preloadAd:(TuneAd *)ad;

/*!
 Dismiss activity indicator overlay if it exists.
 */
- (void)dismissActivityOverlay;

/*!
 Method to request a new ad for the given placement and metadata.
 @param placement name of the placement
 @param metadata data to be included with the ad request
 */
- (void)getNextAd:(NSString *)placement metadata:(TuneAdMetadata *)metadata;

/*!
 Resizes ad webview for the new orientation.
 @param newOrientation the new orientation of the ad view
 */
- (void)updateWebViewFrameForOrientation:(UIInterfaceOrientation)newOrientation;

/*!
 Handles ad view click action.
 @param url URL to be opened in response to the ad click
 @return YES if the url is being opened in the system browser, NO otherwise
 */
- (BOOL)handleAdClickWithUrl:(NSURL *)url;

/*!
 Subclasses need to implement this abstract method and handle in-app app store view display. This class only provides an empty placeholder implementation.
 @param itemId Apple iTunes Id of the app being advertised
 @param cToken Apple iTunes Campaign Token
 @param aToken Apple iTunes Affiliate Token
 */
- (void)showInAppStoreForAppId:(NSNumber *)itemId
                 campaignToken:(NSString *)cToken
                affiliateToken:(NSString *)aToken
                    requestUrl:(NSURL *)url;

/*!
 Helper method to notify the delegate that an ad has been successfully fetched.
 @param placement name of the placement
 */
- (void)notifyDidFetchAd:(NSString *)placement;

/*!
 Helper method to notify the delegate that an ad has been clicked.
 @param willLeave YES if a different app is being launched as a result of the ad click, NO otherwise
 */
- (void)notifyClickActionStart:(BOOL)willLeave;

/*!
 Helper method to notify the delegate that the action initiated by an ad click has ended.
 */
- (void)notifyClickActionEnd;

/*!
 Helper method to notify the delegate that an interstitial ad has been closed by the user by clicking the close icon.
 */
- (void)notifyClose;

/*!
 Helper method to notify the delegate that an ad fetch failed.
 @param error error object with details about the error
 */
- (void)notifyFailedWithError:(NSError *)error;

/*!
 Helper method to notify the delegate that an ad fetch request was fired.
 @param url ad request url
 @param data data included with the ad request
 */
- (void)notifyAdRequestWithUrl:(NSString *)url data:(NSString *)data;

@end
