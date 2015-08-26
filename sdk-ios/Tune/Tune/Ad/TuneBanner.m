//
//  TuneBanner.m
//  Tune
//
//  Created by John Gu on 6/11/15.
//  Copyright (c) 2015 Tune Inc. All rights reserved.
//

#import "../TuneBanner.h"

#import "../TuneAdMetadata.h"

#import "../Common/TuneKeyStrings.h"
#import "../Common/TuneUtils.h"

#import "TuneAdKeyStrings.h"
#import "TuneAdNetworkHelper.h"
#import "TuneAdSKStoreProductViewController.h"
#import "TuneAdUtilitiesUI.h"
#import "TuneAdUtils.h"
#import "TuneAdView_internal.h"

#import <StoreKit/StoreKit.h>

const NSTimeInterval TUNE_AD_BANNER_FIRST_LOAD_DELAY_DURATION  = 0.2;
const NSTimeInterval TUNE_AD_DURATION_RECHECK_FETCH_COMPLETE   = 1.0;

@interface TuneBanner () <UIWebViewDelegate, UIScrollViewDelegate, SKStoreProductViewControllerDelegate>
{
    /*!
        Enough time has lapsed since last ad update and
        if available, then a new ad banner can now be displayed
     */
    BOOL shouldDisplayAd;
    
    /*!
        Is the app currently active
     */
    BOOL appActive;

    /*!
     App was active previously, i.e., this is not the first app launch
     */
    BOOL appWasActive;
    
    /*!
        Banner update timer
     */
    NSTimer *bannerTimer;
    
    /*!
        Indicates if this is the first banner load call.
     */
    BOOL firstLoad;
    
    /*!
        After load call has the banner timer been started.
     */
    BOOL timerStarted;
    
    /*!
        Is banner currently visible
     */
    BOOL bannerVisible;
}

/*!
 Used to provide custom info to help ad targeting. Once set, all subsequent ad requests for this ad view include this info.
 */
@property (nonatomic, strong) TuneAdMetadata *metadata;

/*!
 Ad view placement info, e.g. "menu_page", "highscores", "game-end".
 */
@property (nonatomic, copy) NSString *placement;

@end


@implementation TuneBanner

#pragma mark - Initialization Methods

+ (instancetype)adViewWithDelegate:(id<TuneAdDelegate>)adViewDelegate
{
    return [TuneBanner adViewWithDelegate:adViewDelegate
                             orientations:[TuneAdView defaultAdOrientation]];
}

+ (instancetype)adViewWithDelegate:(id<TuneAdDelegate>)adViewDelegate
                      orientations:(TuneAdOrientation)allowedOrientations
{
    return [[TuneBanner alloc] initWithDelegate:adViewDelegate
                                   orientations:allowedOrientations];
}

- (instancetype)initWithDelegate:(id<TuneAdDelegate>)adViewDelegate
                    orientations:(TuneAdOrientation)allowedOrientations
{
    self = [super initForAdType:TuneAdTypeBanner
                       delegate:adViewDelegate
                   orientations:allowedOrientations];
    return self;
}


#pragma mark - Public Methods

- (void)displayAd
{
    // if the next ad was successfully fetched
    if(adNext)
    {
        DLog(@"displayAd: network reachable = %d", [TuneUtils isNetworkReachable]);
        
        // make sure this Tune ad view is not transparent
        self.alpha = 1.;
        
        // make sure this Tune ad view is not hidden
        self.hidden = NO;
        
        // allow banner cycling
        appStoreVisible = NO;
        
        [self handleDisplayAd];
        
        // fire new ad impression
        NSString *viewUrl = [TuneAdUtils tuneAdViewUrl:adCurrent];
        [TuneAdNetworkHelper fireUrl:viewUrl ad:adCurrent];
    }
    else
    {
        self.ready = NO;
    }
    
    adReadyForDisplay = NO;
    shouldDisplayAd = NO;
}


#pragma mark - Display Helper Methods

/*!
 Resets state, initiates new ad download. Also starts the refresh timer in case of banners.
 */
- (void)showForPlacement:(NSString *)placement
{
    [self showForPlacement:placement adMetadata:nil];
}

/*!
 Resets state, initiates new ad download. Also starts the refresh timer in case of banners.
 @param placement new placement string value to set, ignored if nil
 @param metadata used to provide custom info to help ad targeting. Once set, all subsequent ad requests for this ad view include this info.
 */
- (void)showForPlacement:(NSString *)placement adMetadata:(TuneAdMetadata *)metadata
{
    DLog(@"showForPlacement: placement = %@", placement);
    
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
        self.placement = placement;
        self.metadata = metadata;
    
        DLog(@"pass1: first call to getNextAd");
        [self getNextAd];
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
    
    // to start with, allow ad to be displayed as soon as it is ready
    shouldDisplayAd = YES;
    
//#if TESTING
//    // When unit-testing UIApplicationDidBecomeActiveNotification notification 
//    // is not received, hence we explicitly set the appActive flag.
//    appActive = YES;
//#endif
    appActive = YES;
    
    // stop banner timer
    if(bannerTimer)
    {
        [bannerTimer invalidate];
        bannerTimer = nil;
    }
    
    timerStarted = NO;
    
    adReadyForDisplay = NO;
    
    //appStoreVisible = NO;
}

/*!
 Displays next available ad.
 */
- (void)handleDisplayAd
{
    DLog(@"handleDisplayAd");

    // show next available ad
    [self toggleWebviews];
    
    [self updateWebViewFrameForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
}

- (void)getNextAd
{
    [super getNextAd:self.placement metadata:self.metadata];
}

/*!
 Preloads the currently unused webview with html content of the given ad.
 */
- (void)preloadAd:(TuneAd *)ad
{
    [super preloadAd:ad];
    
    if (!timerStarted && !appStoreVisible) {
        DLog(@"kick start banner timer");
        [self bannerTimerFired];
        timerStarted = YES;
    }
}


#pragma mark - Notification Handlers

- (void)handleNetworkChange:(NSNotification *)notice
{
    DLog(@"TuneBanner: network reachable = %d, appActive = %d", [TuneUtils isNetworkReachable], appWasActive);
    
    if(appWasActive && [TuneUtils isNetworkReachable])
    {
        DLog(@"TuneBanner: calling re-load");
        [self showForPlacement:self.placement adMetadata:self.metadata];
    }
}

- (void)handleAppBecameActive:(NSNotification *)notice
{
    DLog(@"TuneBanner: app became active: was active = %d", appWasActive);
    
    appActive = YES;
    
    if(appWasActive)
    {
        DLog(@"TuneBanner: handleAppBecameActive: calling load");
        [self showForPlacement:self.placement adMetadata:self.metadata];
    }
    
    appWasActive = YES;
}

- (void)handleAppWillResignActive:(NSNotification *)notice
{
    DLog(@"TuneBanner: app will resign active");
    
    appActive = NO;
    
    if(bannerTimer)
    {
        [bannerTimer invalidate];
        bannerTimer = nil;
    }
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
        
        adReadyForDisplay = YES;
        
        DLog(@"webview ad preload complete: banner currently visible = %d", bannerVisible );
            
        if(!bannerVisible)
        {
            [bannerTimer invalidate];
            [self bannerTimerFired];
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
        
        // ad was tapped, initiate action
        [self handleAdClickWithUrl:url];
        
        shouldContinueRequest = NO;
    }
    
    return shouldContinueRequest;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DLLog(@"pass11 webView = %d, didFailLoadWithError = %@", webView == webview1 ? 1 : 2, error);
    
    adReadyForDisplay = NO;
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
                                       // present the store view controller only if superVC is part of the view hierarchy
                                       if(superVC.view.window)
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
                                           
                                           appStoreVisible = NO;
                                           
                                           [self notifyClickActionEnd];
                                       }
                                   }
                                   else
                                   {
                                       DLog(@"storeVC load failed, will leave app");
                                       
                                       // since the in-app store view failed to load after ad click,
                                       // let the delegate know that an external app will be opened
                                       [self notifyClickActionStart:YES];
                                       
                                       // the in-app store view failed to launch,
                                       // open the request url using external app through UIApplication.openURL
                                       [[UIApplication sharedApplication] openURL:url];
                                       
                                       [self dismissActivityOverlay];
                                       
                                       appStoreVisible = NO;
                                   }
                               }
                           }
         ];
    }
}


#pragma mark - Banner Timer

/*!
 Cycles banner ad when the banner refresh timer fires.
 */
- (void)bannerTimerFired
{
    DLog(@"bannerTimerFired: appActive = %d", appActive);
    
    shouldDisplayAd = YES;
    bannerVisible = NO;
    
    // continue only if app is currently active
    if(appActive)
    {
        // if in-app app-store is visible, then do nothing,
        // timer will be restarted when app-active notification is received
        if(!appStoreVisible)
        {
            //DLog(@"store not visible");
            
            NSTimeInterval nextTimerDuration = TUNE_AD_DEFAULT_BANNER_CYCLE_DURATION;
            
            // if next ad has been loaded in the background webview and is ready for display, then notify the delegate
            if(adReadyForDisplay)
            {
                DLog(@"bannerTimerFired: ad is ready, calling displayAd");
                
                bannerVisible = YES;
                
                // display available ad
                [self displayAd];
                
                DLog(@"notify delegate ad ready");
                
                // notify the delegate that the banner ad has been updated
                [self notifyDidFetchAd:adCurrent.placement];
                
                DLog(@"pass3: calling getNextAd");
                [self getNextAd];
                
                // set the banner update timer duration as suggested by the current ad
                nextTimerDuration = adCurrent.duration;
            }
            else
            {
                // next banner ad is currently not ready
                
                DLog(@"ad NOT ready, waitingForAd = %d, adNext = %@", waitingForAd, adNext);
                
                // an ad fetch network request is currently in progress OR
                // the ad is being loaded in a webview, so we wait a little longer
                if(waitingForAd || (adNext && [TuneUtils isNetworkReachable]))
                {
                    nextTimerDuration = TUNE_AD_DURATION_RECHECK_FETCH_COMPLETE;
                }
                else
                {
                    NSError *error = nil;
                    
                    if(![TuneUtils isNetworkReachable])
                    {
                        // let the delegate know that no ad inventory is currently available
                        
                        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
                        [errorDetails setValue:TUNE_AD_KEY_TuneAdErrorNetworkNotReachable forKey:NSLocalizedFailureReasonErrorKey];
                        [errorDetails setValue:@"The network is currently unreachable." forKey:NSLocalizedDescriptionKey];
                        error = [NSError errorWithDomain:TUNE_AD_KEY_TuneAdErrorDomain code:TuneAdErrorNetworkNotReachable userInfo:errorDetails];
                    }
                    else if(adError)
                    {
                        error = adError;
                    }
                    else
                    {
                        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
                        [errorDetails setValue:TUNE_AD_KEY_TuneAdErrorUnknown forKey:NSLocalizedFailureReasonErrorKey];
                        [errorDetails setValue:@"Unknow error, ads are currently not available." forKey:NSLocalizedDescriptionKey];
                        error = [NSError errorWithDomain:TUNE_AD_KEY_TuneAdErrorDomain code:TuneAdErrorUnknown userInfo:errorDetails];
                    }
                    
                    DLog(@"pass14 error = %@", error);
                    
                    [self notifyFailedWithError:error];
                    
                    DLog(@"pass4: calling getNextAd");
                    [self getNextAd];
                }
            }
            
            DLog(@"new timer = %f", nextTimerDuration);
            
            [bannerTimer invalidate];
            bannerTimer = [NSTimer scheduledTimerWithTimeInterval:nextTimerDuration target:self selector:@selector(bannerTimerFired) userInfo:nil repeats:NO];
        }
        else
        {
            DLog(@"app store visible, skip banner cycle");
        }
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
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.001*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        
        [self notifyClickActionEnd];
        
        [self dismissActivityOverlay];
        
        DLog(@"calling bannerTimerFired");
        [self bannerTimerFired];
    });
}


#pragma mark - Debug Description

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> adType = %ld, adOrientations = %ld, ready = %d, delegate = %p", [self class], self, (long)TuneAdTypeBanner, (long)self.adOrientations, self.ready, self.delegate];
}

@end
