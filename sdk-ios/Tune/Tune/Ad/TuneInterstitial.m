//
//  TuneInterstitial.m
//  Tune
//
//  Created by John Gu on 6/11/15.
//  Copyright (c) 2015 Tune Inc. All rights reserved.
//

#import "../TuneInterstitial.h"

#import "../Common/Tune_internal.h"
#import "../Common/TuneKeyStrings.h"
#import "../Common/TuneReachability.h"
#import "../Common/TuneSettings.h"
#import "../Common/TuneTracker.h"
#import "../Common/TuneUtils.h"

#import "TuneAdInterstitialVC.h"
#import "TuneAdKeyStrings.h"
#import "TuneAdMetadata.h"
#import "TuneAdNetworkHelper.h"
#import "TuneAdSKStoreProductViewController.h"
#import "TuneAdUtilitiesUI.h"
#import "TuneAdUtils.h"
#import "TuneAdView_internal.h"

#import <StoreKit/StoreKit.h>

NSString * TUNE_AD_CLOSE_HTML_CALLBACK                  = @"#close";
const NSInteger TUNE_AD_CLOSE_BUTTON_VIEW_TAG           = 1233217;

UIImage *imageCloseButton;


@interface TuneInterstitial () <UIWebViewDelegate, UIScrollViewDelegate, SKStoreProductViewControllerDelegate>
{    
    /*!
        The interstitial ad close button.
     */
    UIButton *closeButton;
    
    /*!
        Has a close button been already added to an interstitial view
     */
    BOOL closeButtonAdded;
    
    /*!
        Whether to show the interstitial upon load
     */
    BOOL showOnLoad;
    
    /*!
        View Controller used to show the interstitial ad view.
     */
    TuneAdInterstitialVC *interstitialVC;
}

@end


@implementation TuneInterstitial

#pragma mark - Initialization Methods

+ (void)initialize
{
    imageCloseButton = [TuneAdUtils closeButtonImage];
}

+ (instancetype)adView
{
    return [TuneInterstitial adViewWithDelegate:nil];
}

+ (instancetype)adViewWithDelegate:(id<TuneAdDelegate>)adViewDelegate
{
    return [TuneInterstitial adViewWithDelegate:adViewDelegate
                                   orientations:[TuneAdView defaultAdOrientation]];
}

+ (instancetype)adViewWithDelegate:(id<TuneAdDelegate>)adViewDelegate
                      orientations:(TuneAdOrientation)allowedOrientations
{
    return [[TuneInterstitial alloc] initWithDelegate:adViewDelegate
                                         orientations:allowedOrientations];
}

- (instancetype)initWithDelegate:(id<TuneAdDelegate>)adViewDelegate
                    orientations:(TuneAdOrientation)allowedOrientations
{
    self = [super initForAdType:TuneAdTypeInterstitial
                       delegate:adViewDelegate
                   orientations:allowedOrientations];
    return self;
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
        self.ready = NO;
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
    DLog(@"cacheForPlacement: placement = %@", placement);
    
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
        CGRect bounds = [TuneUtils screenBoundsForStatusBarOrientation];
        
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
            DLog(@"handleDisplayAd: call getNextAd: placement = %@", placement);
            [self getNextAd:placement metadata:metadata];
        }
        else
        {
            self.ready = NO;
        }
    }
#if DEBUG
    else
    {
        DLog(@"parent view controller not visible, skip interstitial display");
    }
#endif
}


#pragma mark - Interstitial Close Action

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


#pragma mark - UIWebViewDelegate Methods

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    DLLog(@"webViewDidFinishLoad:");
    
    NSString *html = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
    
    // ignore the clear webview actions
    if (![html isEqualToString:TUNE_STRING_EMPTY])
    {
        DLog(@"webview ad preload complete: webview = %d", webView == webview1 ? 1 : 2 );
        
        // Display the ad if it was lazy-loaded
        if (showOnLoad)
        {
            showOnLoad = false;
            [self handleDisplayAd:nil metadata:nil];
        }
        
        DLog(@"calling notifyDidFetchAd: %@", adCurrent.placement);
        [self notifyDidFetchAd:adCurrent.placement];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL shouldContinueRequest = YES;

    if (UIWebViewNavigationTypeLinkClicked == navigationType)
    {
        // handle ad view tapped
        
        DLLog(@"webview url clicked: request = %@", [[request URL] absoluteString]);
        
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
    CGRect bounds = [TuneUtils screenBoundsForStatusBarOrientation];
    
    UIViewController *superVC = firstAvailableUIViewController(self);
    
    DLog(@"show in-app store using firstAvailableViewController = %@, parentViewController = %@", superVC, parentViewController);
    
    // open the iTunes App Store link in-app using SKStoreProductViewController
    storeVC = [TuneAdSKStoreProductViewController new];
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
- (BOOL)handleAdClickWithUrl:(NSURL *)url
{
    BOOL openedExternally = [super handleAdClickWithUrl:url];
    if(openedExternally)
    {
        // close the interstitial ad
        [self dismissInterstitial];
    }
    
    return openedExternally;
}


#pragma mark - SKStoreProductViewControllerDelegate Methods

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    DLog(@"in-app store view finished");
    
    // dismiss the modal store view controller; message is automatically passed to the parent view controller
    [viewController dismissViewControllerAnimated:YES completion:nil];
    
    // again start cycling banner ads
    appStoreVisible = NO;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self notifyClickActionEnd];
        
        [self dismissInterstitial];
        
        [self dismissActivityOverlay];
    });
}


#pragma mark - Debug Description

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> adType = %ld, adOrientations = %ld, ready = %d, delegate = %p", [self class], self, (long)TuneAdTypeInterstitial, (long)self.adOrientations, self.ready, self.delegate];
}

@end
