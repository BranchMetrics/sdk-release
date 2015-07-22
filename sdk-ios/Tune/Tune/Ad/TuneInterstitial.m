//
//  TuneInterstitial.m
//  Tune
//
//  Created by John Gu on 6/11/15.
//  Copyright (c) 2015 Tune Inc. All rights reserved.
//

#import "../Common/TuneReachability.h"
#import "../Common/TuneSettings.h"
#import "../Common/TuneTracker.h"
#import "../Common/TuneUtils.h"
#import "../Common/Tune_internal.h"
#import "../TuneInterstitial.h"
#import "TuneAd.h"
#import "TuneAdInterstitialVC.h"
#import "TuneAdKeyStrings.h"
#import "TuneAdParams.h"
#import "TuneAdPlacementManager.h"
#import "TuneAdUtilitiesUI.h"
#import "TuneAdUtils.h"
#import "TuneAdNetworkHelper.h"
#import "TuneAdSKStoreProductViewController.h"

#import <QuartzCore/QuartzCore.h>
#import <StoreKit/StoreKit.h>

NSString * TUNE_AD_CLOSE_HTML_CALLBACK                  = @"#close";
const NSInteger TUNE_AD_CLOSE_BUTTON_VIEW_TAG           = 1233217;

UIImage *imageCloseButton;


@interface TuneInterstitial () <UIWebViewDelegate, UIScrollViewDelegate, SKStoreProductViewControllerDelegate>
{
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
        The interstitial ad close button.
     */
    UIButton *closeButton;
    
    /*!
        Has a close button been already added to an interstitial view
     */
    BOOL closeButtonAdded;
    
    /*!
        Is the app currently active
     */
    BOOL appActive;
    
    /*!
        is the in-app store currently visible
     */
    BOOL appStoreVisible;
    
    /*!
        Whether to show the interstitial upon load
     */
    BOOL showOnLoad;
    
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
        View Controller used to show the interstitial ad view.
     */
    TuneAdInterstitialVC *interstitialVC;
    
    /*!
        Instance of a class that manages download and pre-fetch of ads for the given placement.
     */
    TuneAdPlacementManager *pm;
    
    /*!
       Is ad request pending
    */
    BOOL waitingForAd;
}

@end


@implementation TuneInterstitial

#pragma mark - Initialization Methods

+ (void)initialize
{
    if (self == [TuneInterstitial class]) {
        imageCloseButton = [TuneAdUtils closeButtonImage];
    }
}

+ (instancetype)adView
{
    return [TuneInterstitial adViewWithDelegate:nil];
}

+ (instancetype)adViewWithDelegate:(id<TuneAdDelegate>)adViewDelegate
{
    return [TuneInterstitial adViewWithDelegate:adViewDelegate
                                   orientations:[self defaultAdOrientation]];
}

+ (instancetype)adViewWithDelegate:(id<TuneAdDelegate>)adViewDelegate
                      orientations:(TuneAdOrientation)allowedOrientations
{
    return [[TuneInterstitial alloc] initWithDelegate:adViewDelegate
                                         orientations:allowedOrientations];
}

+ (TuneAdOrientation)defaultAdOrientation
{
    UIInterfaceOrientationMask mask = supportedOrientations();
    
    BOOL isLandscape = mask & UIInterfaceOrientationMaskLandscape;
    BOOL isPortrait = mask & UIInterfaceOrientationMaskPortrait || mask & UIInterfaceOrientationMaskPortraitUpsideDown;
    
    TuneAdOrientation defaultOrientation = isLandscape && isPortrait ? TuneAdOrientationAll : (isLandscape ? TuneAdOrientationLandscape : TuneAdOrientationPortrait);
    
    return defaultOrientation;
}

- (instancetype)initWithDelegate:(id<TuneAdDelegate>)adViewDelegate
                    orientations:(TuneAdOrientation)allowedOrientations
{
    CGFloat adViewY = 0.;
    CGFloat adViewH = [UIScreen mainScreen].bounds.size.height;
    
    CGRect frameRect = CGRectMake(0, adViewY, [UIScreen mainScreen].bounds.size.width, adViewH);
    DLog(@"initWithAdType: %@", NSStringFromCGRect(frameRect));
    
    self = [super initWithFrame:frameRect];
    if (self)
    {
        _adOrientations = allowedOrientations;
        _delegate = adViewDelegate;
        
        [self internalInit];
    }
    return self;
}

- (void)internalInit
{
    self.backgroundColor = [UIColor blackColor];
    
    // set to 2, so that webview1 is used by default
    viewIndex = 2;
    
    webview1 = [TuneAdUtils webviewForAdView:self.frame.size webviewDelegate:self scrollviewDelegate:self];
    webview2 = [TuneAdUtils webviewForAdView:self.frame.size webviewDelegate:self scrollviewDelegate:self];
    
    pm = [TuneAdPlacementManager new];
    
    // add both the webviews to the ad view
    [self addSubview:webview2];
    [self addSubview:webview1];
    
    // Delay setting notification handlers, to make sure that on first
    // app-launch the appDidBecomActive notification does not get fired
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // list for network reachability notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNetworkChange:)
                                                     name:kTuneReachabilityChangedNotification
                                                   object:nil];
        
        // listen for app-became-active notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAppBecameActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        
        // listen for app-will-resign-active notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAppWillResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        // begin generating device orientation change notifications
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        // listen for device rotation change notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(statusBarOrientationWillChange:)
                                                     name:UIApplicationWillChangeStatusBarOrientationNotification
                                                   object:nil];
    });
}


#pragma mark - Public Methods

- (void)displayAd:(NSString *)placement metadata:(TuneAdMetadata *)metadata
{
    // if the next ad was successfully fetched
    if(adNext)
    {
        DLog(@"displayAd: network reachable = %d", [TuneUtils isNetworkReachable]);
        
        [self handleDisplayAd:placement metadata:metadata];
        
        // fire new ad impression
        NSString *viewUrl = [TuneAdUtils tuneAdViewUrl:adCurrent];
        [TuneAdNetworkHelper fireUrl:viewUrl ad:adCurrent];
    }
    else
    {
        // Fetch an ad and show it upon ad load
        showOnLoad = true;
        [self cacheForPlacement:placement adMetadata:metadata];
        _ready = NO;
    }
}

- (void)showForPlacement:(NSString *)placement viewController:(UIViewController *)vc
{
    [self showForPlacement:placement viewController:vc adMetadata:nil];
}

- (void)showForPlacement:(NSString *)placement viewController:(UIViewController *)vc adMetadata:(TuneAdMetadata *)metadata
{
    DLog(@"presentFromViewController");
    
    parentViewController = vc;
    
    [self displayAd:placement metadata:metadata];
}


#pragma mark - Display Helper Methods

/*!
 Resets state, initiates new ad download. Also starts the refresh timer in case of banners.
 */
- (void)cacheForPlacement:(NSString *)placement
{
    [self cacheForPlacement:placement adMetadata:nil];
}

/*!
 Resets state, initiates new ad download. Also starts the refresh timer in case of banners.
 @param placement new placement string value to set, ignored if nil
 @param metadata used to provide custom info to help ad targeting. Once set, all subsequent ad requests for this ad view include this info.
 */
- (void)cacheForPlacement:(NSString *)placement adMetadata:(TuneAdMetadata *)metadata
{
    DLog(@"loadForPlacement: placement = %@", placement);
    
    [self reset];
    
    // placement string must be a non-nil string,
    // otherwise send an error notification to the delegate
    if(nil == placement)
    {
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:TUNE_AD_KEY_TuneAdErrorInvalidPlacement forKey:NSLocalizedFailureReasonErrorKey];
        [errorDetails setValue:@"Placement string value cannot be nil." forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:TUNE_AD_KEY_TuneAdErrorDomain code:TuneAdErrorInvalidPlacement userInfo:errorDetails];
        [self notifyFailedWithError:error];
    }
    else
    {
        DLog(@"pass1: first call to getNextAd");
        [self getNextAd:placement metadata:metadata];
    }
}

/*!
 Resets state
 */
- (void)reset
{
    DLog(@"reset adview: %d", appStoreVisible);
    // to start with, use webview1
    //viewIndex = 1;
    
//#if TESTING
//    // When unit-testing UIApplicationDidBecomeActiveNotification notification 
//    // is not received, hence we explicitly set the appActive flag.
//    appActive = YES;
//#endif
    appActive = YES;
    
    closeButtonAdded = NO;
    
    //appStoreVisible = NO;
}

/*!
 Show the next webview and hide the currently visible webview.
 */
- (void)toggleWebviews
{
    DLog(@"toggleWebviews");
    
    // get current webview
    UIWebView *current = 1 == viewIndex ? webview1 : webview2;
    
    // move webview so that it appears behind its sibling views
    [self sendSubviewToBack:current];
    
    // toggle webview index
    viewIndex = 1 == viewIndex ? 2 : 1;
    
    // set the current ad to the next pre-fetched ad
    adCurrent = adNext;
    
    // clear the next ad
    adNext = nil;
}

/*!
 Loads empty html in the webview.
 */
- (void)clearWebview:(UIWebView *)webview
{
    DLog(@"clearWebview: %d", webview1 == webview ? 1 : 2);
    [webview loadHTMLString:TUNE_STRING_EMPTY baseURL:nil];
}

/*!
 For an interstitial view, adds a close button if one does not exist. No-op for banner view.
 */
- (void)addCloseButton
{
    BOOL shouldAdd = adNext.usesNativeCloseButton && !closeButtonAdded;
    
    // add a close button if this is an interstitial view that requires
    // a native close button and the close button has not already been added
    if(shouldAdd)
    {
        // set the flag to note that the close button has been added
        closeButtonAdded = YES;
        
        // add a close button over the interstitial ad
        closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        [closeButton setImage:imageCloseButton forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
        [closeButton setTag:TUNE_AD_CLOSE_BUTTON_VIEW_TAG];
        closeButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        [self addSubview:closeButton];
    }
}

/*!
 Displays next available ad. In case of interstitials, initiates a new ad prefetch.
 */
- (void)handleDisplayAd:(NSString *)placement metadata:(TuneAdMetadata *)metadata
{
    DLog(@"handleDisplayAd");
    
    // make sure this Tune ad view is not transparent
    self.alpha = 1.;
    
    // make sure this Tune ad view is not hidden
    self.hidden = NO;
    
    // allow banner cycling
    appStoreVisible = NO;
    
    [self addCloseButton];
    
    if(parentViewController.view.window)
    {
        // width, height adjusted for current interface orientation
        CGRect bounds = [self screenBoundsForStatusBarOrientation];
        
        DLog(@"ad window orientation = %ld, screenBounds = %@", (long)[[UIApplication sharedApplication] statusBarOrientation],  NSStringFromCGRect(bounds));
            
        webview1.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
        webview2.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
        
        // make sure the webviews are visible
        webview1.hidden = NO;
        webview2.hidden = NO;
            
        // show next available ad
        [self toggleWebviews];
            
        interstitialVC = [[TuneAdInterstitialVC alloc] initWithAdView:self];
            
        [parentViewController presentViewController:interstitialVC animated:YES completion:nil];
            
        if([TuneUtils isNetworkReachable] && placement != nil)
        {
            DLog(@"handleDisplayAd: call getNextAd: placement = %@", self.placement);
            [self getNextAd:placement metadata:metadata];
        }
        else
        {
            _ready = NO;
        }
    }
#if DEBUG
    else
    {
        DLog(@"parent view controller not visible, skip interstitial display");
    }
#endif
}

- (void)getNextAd:(NSString *)placement metadata:(TuneAdMetadata *)metadata
{
    waitingForAd = YES;
    
    DLog(@"requesting ad for placement = %@", self.placement);
    
    [pm adForAdType:TuneAdTypeInterstitial
          placement:placement
           metadata:metadata
       orientations:self.adOrientations
  completionHandler:^(TuneAd *ad, NSError *error) {
      
      if(ad)
      {
          waitingForAd = NO;
          
          DLog(@"adview: pl mgr: completionHandler: adNext set");
          
          adNext = ad;
          
          DLog(@"adview: pl mgr: completionHandler: preload ad in webview");
          
          // preload in the next available webview
          [self preloadAd:ad];
      }
      else
      {
          DLog(@"adview: pl mgr: error = %@", error);
          
          waitingForAd = NO;
      
          // TODO: consider if special handling of network error is required
          // TODO: check if this is a network error
          BOOL isNetworkError = NO;
          
          if(isNetworkError)
          {
              // in case of interstitial ads, let the delegate know that the network is currently unreachable
              
              NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
              [errorDetails setValue:TUNE_AD_KEY_TuneAdErrorNetworkNotReachable forKey:NSLocalizedFailureReasonErrorKey];
              [errorDetails setValue:@"The network is currently unreachable." forKey:NSLocalizedDescriptionKey];
              
              error = [NSError errorWithDomain:TUNE_AD_KEY_TuneAdErrorDomain code:TuneAdErrorNetworkNotReachable userInfo:errorDetails];
          }
          
          [self notifyFailedWithError:error];
      }
  }];
}

/*!
 Preloads the currently unused webview with html content of the given ad.
 */
- (void)preloadAd:(TuneAd *)ad
{
    // find out the webview that's currently not visible
    UIWebView *nextWebView = 1 == viewIndex ? webview2 : webview1;
    
    DLog(@"preloadAd: webview = %d, adNext.html.length = %d", 1 == viewIndex ? 2 : 1, (int)ad.html.length);
    
#if DEBUG
    if([ad.html length] == 0)
    {
        DLog(@"!!!! invalid ad html !!!!");
    }
#endif
    
    // load the next ad in the currently invisible webview
    [nextWebView loadHTMLString:ad.html baseURL:nil];
    
    DLog(@"preloadAd: timerStarted    = %d", timerStarted);
    DLog(@"preloadAd: appStoreVisible = %d", appStoreVisible);
}


#pragma mark - Interstitial Close Action

/*!
 Handles in-app store view close action.
 */
- (void)handleStoreViewClosing
{
    [self dismissActivityOverlay];
    
    appStoreVisible = NO;
}

/*!
 Handles ad view close action.
 */
- (void)closeAction
{
    [self dismissInterstitial];
    
    [self dismissActivityOverlay];
    
    appStoreVisible = NO;
    
    [self notifyClose];
}

/*!
 Dismiss activity indicator overlay if it exists.
 */
- (void)dismissActivityOverlay
{
    if(activity)
    {
        [activity removeFromSuperview];
        activity = nil;
    }
}

/*!
 Dismiss interstitial view controller.
 */
- (void)dismissInterstitial
{
    DLog(@"dismissInterstitial");
    
    UIViewController *vc = parentViewController;
    [vc dismissViewControllerAnimated:YES completion:nil];
        
    // remove the close button from the ad view
    [[self viewWithTag:TUNE_AD_CLOSE_BUTTON_VIEW_TAG] removeFromSuperview];
        
    closeButtonAdded = NO;
        
    // fire ad closed event
    NSString *closeUrl = [TuneAdUtils tuneAdClosedUrl:adCurrent];
    [TuneAdNetworkHelper fireUrl:closeUrl ad:adCurrent];
}


#pragma mark - View Rotation

/*!
 Resizes ad webview for the new orientation.
 */
- (void)updateWebViewFrameForOrientation:(UIInterfaceOrientation)newOrientation
{
    TuneSettings *tuneParams = [[Tune sharedManager] parameters];
    
    CGFloat portraitWidth = [[tuneParams screenWidth] floatValue];
    CGFloat portraitHeight = [[tuneParams screenHeight] floatValue];
    
    CGRect bounds = CGRectZero;
    
    if (UIInterfaceOrientationIsLandscape(newOrientation))
    {
        bounds.size = CGSizeMake(portraitHeight, portraitWidth);
    }
    else
    {
        bounds.size = CGSizeMake(portraitWidth, portraitHeight);
    }
    
    webview1.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
    webview2.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
    
    if(activity)
    {
        activity.center = CGPointMake(bounds.size.width / 2, bounds.size.height / 2);
    }
}


#pragma mark - Notification Handlers

- (void)handleAppBecameActive:(NSNotification *)notice
{
    DLog(@"app became active: was active = %d", appActive);
    
    BOOL appWasActive = appActive;
    
    appActive = YES;
    
    if(appWasActive)
    {
        DLog(@"handleAppBecameActive: calling load");
        //[self load];
    }
}

- (void)handleAppWillResignActive:(NSNotification *)notice
{
    DLog(@"app will resign active");
    
    appActive = NO;
}

- (void)statusBarOrientationWillChange:(NSNotification *)notification
{
    NSNumber *numOrientation = notification.userInfo[UIApplicationStatusBarOrientationUserInfoKey];
    UIInterfaceOrientation orientation = numOrientation.intValue;
    
    DLog(@"new status bar orientation = %d", (int)orientation);
    
    // update view size depending on current interface orientation
    [self updateWebViewFrameForOrientation:orientation];
}


#pragma mark - UIWebViewDelegate Methods

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    DLLog(@"webViewDidFinishLoad:");
    
    NSString *html = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
    
    // ignore the clear webview actions
    if (![html isEqualToString:TUNE_STRING_EMPTY])
    {
        DLog(@"webview ad preload complete: webview = %d", webView == webview1 ? 1 : 2 );
        
        DLog(@"calling notifyDidFetchAd");
        [self notifyDidFetchAd];
        
        // Display the ad if it was lazy-loaded
        if (showOnLoad)
        {
            showOnLoad = false;
            [self handleDisplayAd:nil metadata:nil];
        }
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL shouldContinueRequest = YES;

    if (UIWebViewNavigationTypeLinkClicked == navigationType)
    {
        // handle ad view tapped
        
        DLog(@"webview url clicked: request = %@", [[request URL] absoluteString]);
        
        NSURL *url = [request URL];
        
        if([self isCloseButtonUrl:url])
        {
            // close button was tapped on the ad
            
            DLog(@"webview html close callback received");
            
            [self closeAction];
        }
        else
        {
            // ad was tapped, initiate action
            
            [self handleAdClickWithUrl:url];
        }
        
        shouldContinueRequest = NO;
    }
    
    return shouldContinueRequest;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DLLog(@"pass11 webView = %d, didFailLoadWithError = %@", webView == webview1 ? 1 : 2, error);
    
    // only notify delegate for interstitial ads
    // also ignore the NSURLErrorCancelled caused if the webview is reloaded when it has not finished loading the previous request
    if(NSURLErrorCancelled != error.code)
    {
        [self notifyFailedWithError:error];
    }
}


#pragma mark - WebView Helper - UIScrollViewDelegate Methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    // disable UIWebView zoom
    return nil;
}


#pragma mark - In-App Store Helper Method

/*!
 Opens an in-app store view if the provided params can be handled, otherwise lets the system handle the url.
 */
- (void)showInAppStoreForAppId:(NSNumber *)itemId
                 campaignToken:(NSString *)cToken
                affiliateToken:(NSString *)aToken
                    requestUrl:(NSURL *)url
{
    DLog(@"webview open in-app store: itemId = %@, ct = %@, at = %@, url = %@", itemId, cToken, aToken, url);
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    parameters[SKStoreProductParameterITunesItemIdentifier] = itemId;
    
#ifdef __IPHONE_8_0
    
    if(aToken)
    {
        parameters[SKStoreProductParameterAffiliateToken] = aToken;
    }
    
    if(cToken)
    {
        parameters[SKStoreProductParameterCampaignToken] = cToken;
    }
    
#endif
    
    // width, height adjusted for current device orientation
    CGRect bounds = [self screenBoundsForStatusBarOrientation];
    
    UIViewController *superVC = firstAvailableUIViewController(self);
    
    DLog(@"show in-app store using firstAvailableViewController = %@, parentViewController = %@", superVC, parentViewController);
    
    // open the iTunes App Store link in-app using SKStoreProductViewController
    storeVC = [[TuneAdSKStoreProductViewController alloc] init];
    storeVC.view.frame = bounds;
    storeVC.delegate = self;
    
    // remove any old activity overlay remaining from previous ad click action
    [self dismissActivityOverlay];
    
    activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activity startAnimating];
    activity.frame = CGRectMake(0, 0, 44, 44);
    activity.center = CGPointMake(bounds.size.width / 2, bounds.size.height / 2);
    
    [self.window addSubview:activity];
    
    DLog(@"storeVC load: network reachable = %d", [TuneUtils isNetworkReachable]);
    
    if([TuneUtils isNetworkReachable])
    {
        [storeVC loadProductWithParameters:parameters
                           completionBlock:^(BOOL result, NSError *error) {
                               
                               DLog(@"in-app store view load: result = %d, error = %@, appStoreVisible = %d", result, error, appStoreVisible);
                               
                               // ignore the callback if a new ad has already been displayed
                               if(appStoreVisible)
                               {
                                   if (result)
                                   {
                                       // once the in-app store view is visible, hide the Tune ad view, so that when the
                                       // in-app store view is closed, the user app view shows up at once
                                       
                                       DLog(@"in-app store view load: hide webviews");
                                           
                                       webview1.hidden = YES;
                                       webview2.hidden = YES;
                                           
                                       interstitialVC.view.backgroundColor = [UIColor clearColor];
                                       
                                       [closeButton removeFromSuperview];
                                       
                                       // present the store view controller only if superVC is part of the view hierarchy
                                       if(superVC.view.window && (interstitialVC && !interstitialVC.disabled))
                                       {
                                           [superVC presentViewController:storeVC animated:YES completion:^{
                                               DLog(@"store vc presented");
                                               
                                               [self dismissActivityOverlay];
                                           }];
                                       }
                                       else
                                       {
                                           DLog(@"cannot show store view controller, since the superVC view controller is not part of the view hierarchy");
                                           
                                           [self dismissActivityOverlay];
                                           
                                           // close the interstitial ad
                                           [self dismissInterstitial];
                                           
                                           appStoreVisible = NO;
                                           
                                           [self notifyClickActionEnd];
                                       }
                                   }
                                   else
                                   {
                                       interstitialVC.view.backgroundColor = [UIColor clearColor];
                                       
                                       DLog(@"storeVC load failed, will leave app");
                                       
                                       // since the in-app store view failed to load after ad click,
                                       // let the delegate know that an external app will be opened
                                       [self notifyClickActionStart:YES];
                                       
                                       // the in-app store view failed to launch,
                                       // open the request url using external app through UIApplication.openURL
                                       [[UIApplication sharedApplication] openURL:url];
                                       
                                       // close the interstitial ad
                                       [self dismissInterstitial];
                                       
                                       [self dismissActivityOverlay];
                                       
                                       appStoreVisible = NO;
                                   }
                               }
                           }
         ];
    }
}


#pragma mark - Ad Helper Methods

/*!
 Checks if the url is for the ad close button.
 */
- (BOOL)isCloseButtonUrl:(NSURL *)url
{
    NSString *strUrl = [url absoluteString];
    
    return (strUrl.length >= TUNE_AD_CLOSE_HTML_CALLBACK.length
            && [[strUrl substringFromIndex:strUrl.length - TUNE_AD_CLOSE_HTML_CALLBACK.length] isEqualToString:TUNE_AD_CLOSE_HTML_CALLBACK]);
}

/*!
 Handles ad view click action.
 */
- (void)handleAdClickWithUrl:(NSURL *)url
{
    DLog(@"appStoreVisible = %d", appStoreVisible);
    
    // when app store is already visible, ignore webview click action
    if(!appStoreVisible)
    {
        // mark the flag to stop cycling banner ads while the in-app store view is visible
        appStoreVisible = YES;
        
        // We take into consideration some of the the optional params that can be included in the App Store url: "at", "ct"
        // ref: http://blog.georiot.com/2013/12/06/parameter-cheat-sheet-for-itunes-and-app-store-links/
        
        // For iOS < 8.0, if the App Store link contains query params "at" or "ct"
        // then do not use SKStoreProductViewController, open the link using default browser,
        // since prior to iOS 8.0, the affiliate token and campaign token params cannot be passed to the SKStoreProductViewController.
        // ref: https://developer.apple.com/library/prerelease/ios/documentation/StoreKit/Reference/SKITunesProductViewController_Ref/index.html
        
        BOOL isSimulator = [[[UIDevice currentDevice] model] hasSuffix:@"Simulator"];
        
        // only if the in-app store is available on this device
        BOOL isSkStoreAvailable = nil != [SKStoreProductViewController class] && !isSimulator;
        
        NSString *strUrl = [url absoluteString];
        NSDictionary *dictItemUrl = isSkStoreAvailable ? [TuneAdUtils itunesItemIdAndTokensFromUrl:strUrl] : nil;
        
        NSNumber *itemId = dictItemUrl[@"itemId"];
        NSString *aToken = dictItemUrl[@"at"];
        NSString *cToken = dictItemUrl[@"ct"];
        
        // do not open the iTunes store link in an in-app store view if the url contains "at" or "ct" params and iOS version is < 8.0
        BOOL showInAppStore = [TuneUtils isNetworkReachable] && isSkStoreAvailable && itemId && ((!aToken && !cToken) || SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"));
        
        DLog(@"should showInAppStore = %d", showInAppStore);
        
        // let the delegate know that the ad was clicked
        [self notifyClickActionStart:!showInAppStore];
        
        // if the link can be opened in the in-app store
        if(showInAppStore)
        {
            [self showInAppStoreForAppId:itemId
                           campaignToken:cToken
                          affiliateToken:aToken
                              requestUrl:url];
        }
        else
        {
            // this link cannot be opened in the in-app store view, open it using the default browser
            
            DLog(@"webview: open in default browser: cur ad type = %ld", (long)adCurrent.type);
            
            //  open the non-app store link in the default internet browser
            [[UIApplication sharedApplication] openURL:url];
            
            DLog(@"webview: close interstitial ad");
            
            // close the interstitial ad
            [self dismissInterstitial];
        }
        
        // now that the ad has been clicked, fire the ad click url
        // regardless if the target app download page is displayed or not
        // since we do not have a way to detect if the external browser
        // was successful in opening the click url
        NSString *clickUrl = [TuneAdUtils tuneAdClickUrl:adCurrent];
        [TuneAdNetworkHelper fireUrl:clickUrl ad:adCurrent];
    }
}


#pragma mark - View Helper Methods

/*!
 Determine width, height of the main screen depending on the current status bar orientation.
 Ref: http://stackoverflow.com/a/14809642
 */
- (CGRect)screenBoundsForStatusBarOrientation
{
    TuneSettings *tuneParams = [[Tune sharedManager] parameters];
    
    // screen portrait bounds
    CGRect bounds = CGRectMake(0, 0, [[tuneParams screenWidth] floatValue], [[tuneParams screenHeight] floatValue]);
    
    // if current orientation is landscape, then swap the width, height
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]))
    {
        bounds.size = CGSizeMake(bounds.size.height, bounds.size.width);
    }
    
    return bounds;
}


#pragma mark - Delegate Callback Helper Methods

- (void)notifyDidFetchAd
{
    DLog(@"notifyDidFetchAd");
    
    _ready = YES;
    
    [self.delegate tuneAdDidFetchAdForView:self];
}

- (void)notifyClickActionStart:(BOOL)willLeave
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(tuneAdDidStartActionForView:willLeaveApplication:)])
    {
        [self.delegate tuneAdDidStartActionForView:self willLeaveApplication:willLeave];
    }
}

- (void)notifyClickActionEnd
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(tuneAdDidEndActionForView:)])
    {
        [self.delegate tuneAdDidEndActionForView:self];
    }
}

- (void)notifyClose
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(tuneAdDidCloseForView:)])
    {
        [self.delegate tuneAdDidCloseForView:self];
    }
}

- (void)notifyFailedWithError:(NSError *)error
{
    _ready = NO;
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(tuneAdDidFailWithError:forView:)])
    {
        [self.delegate tuneAdDidFailWithError:error forView:self];
    }
}

- (void)notifyAdRequestWithUrl:(NSString *)url data:(NSString *)data
{
    if(self.delegate && [self.delegate respondsToSelector:@selector(tuneAdDidFireRequestWithUrl:data:forView:)])
    {
        [self.delegate tuneAdDidFireRequestWithUrl:url data:data forView:self];
    }
}

#pragma mark - SKStoreProductViewControllerDelegate Methods

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    DLog(@"in-app store view finished");
    
    // dismiss the modal store view controller; message is automatically passed to the parent view controller
    [viewController dismissViewControllerAnimated:YES completion:nil];
    
    // again start cycling banner ads
    appStoreVisible = NO;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.001*NSEC_PER_SEC), dispatch_get_current_queue(), ^{
        
        [self notifyClickActionEnd];
        
        [self dismissInterstitial];
        
        [self dismissActivityOverlay];
    });
}


#pragma mark - Object Dealloc Cleanup

- (void)dealloc
{
    // now that the TuneAdView object is being released,
    // remove all notification observers
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTuneReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}


#pragma mark - Debug Description

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> adType = %ld, adOrientations = %ld, ready = %d, delegate = %p", [self class], self, (long)TuneAdTypeInterstitial, (long)self.adOrientations, self.ready, self.delegate];
}


#pragma mark - Override UIView method

- (CGSize)sizeThatFits:(CGSize)size
{
    //DLog(@"sizeThatFits: %@ --> %@", NSStringFromCGSize(size), NSStringFromCGSize(webview1.frame.size));
    
    return webview1.frame.size;
}


#if DEBUG

#pragma mark - Helper Methods for Testing

+ (void)setTuneAdServer:(NSString *)serverDomain
{
    //DLog(@"setTuneAdServer: %@", serverDomain);
    TUNE_AD_SERVER = serverDomain;
}

+ (NSString *)tuneAdServer
{
    return (NSString *)TUNE_AD_SERVER;
}

#endif

@end
