//
//  TuneAdView.m
//  MobileAppTracker
//
//  Created by Harshal Ogale on 8/6/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//


#import "TuneAdView_internal.h"

#import "Tune_internal.h"
#import "TuneAd.h"
#import "TuneAdKeyStrings.h"
#import "TuneAdMetadata.h"
#import "TuneAdNetworkHelper.h"
#import "TuneAdPlacementManager.h"
#import "TuneAdSKStoreProductViewController.h"
#import "TuneAdUtilitiesUI.h"
#import "TuneAdUtils.h"
#import "TuneKeyStrings.h"
#import "TuneReachability.h"
#import "TuneSettings.h"
#import "TuneTracker.h"
#import "TuneUtils.h"


@implementation TuneAdView


#pragma mark - Init Methods

- (instancetype)initForAdType:(TuneAdType)type
                     delegate:(id<TuneAdDelegate>)adViewDelegate
                 orientations:(TuneAdOrientation)allowedOrientations
{
    CGFloat adViewY = TuneAdTypeBanner == type ? [UIScreen mainScreen].bounds.size.height : 0.;
    CGFloat adViewH = TuneAdTypeBanner == type ? [TuneAd bannerHeightPortrait] : [UIScreen mainScreen].bounds.size.height;
    
    CGRect frameRect = CGRectMake(0, adViewY, [UIScreen mainScreen].bounds.size.width, adViewH);
    
    self = [super initWithFrame:frameRect];
    if (self)
    {
        adType = type;
        _adOrientations = allowedOrientations;
        _delegate = adViewDelegate;
        
        [self internalInitForAdType:adType];
    }
    return self;
}

- (void)internalInitForAdType:(TuneAdType)type
{
    adType = type;
    
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
    // app-launch the appDidBecomeActive notification does not get fired
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // begin generating device orientation change notifications
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        // listen for device rotation change notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(statusBarOrientationWillChange:)
                                                     name:UIApplicationWillChangeStatusBarOrientationNotification
                                                   object:nil];
        
        if(TuneAdTypeBanner == adType)
        {
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
        }
    });
}


#pragma mark -

- (void)getNextAd:(NSString *)placement metadata:(TuneAdMetadata *)metadata
{
    waitingForAd = YES;
    
    DLog(@"requesting ad for placement = %@", placement);
    
    // handle request-fired callback from placement manager
    void(^requestHandler)(NSString *, NSString *) = ^(NSString *url, NSString *data) {
        DLog(@"TuneAdView: getNextAd: placement manager requestHandler");
        
        [self notifyAdRequestWithUrl:url data:data];
    };
    
    // handle request-fired callback from placement manager
    void(^completionHandler)(TuneAd*, NSError*) = ^(TuneAd* ad, NSError* error) {
        DLog(@"TuneAdView: getNextAd: placement manager completionHandler");
        
        if(ad)
        {
            waitingForAd = NO;
            
            DLog(@"adview: pl mgr: completionHandler: adNext set");
            
            adNext = ad;
            
            DLog(@"adview: pl mgr: completionHandler: preload ad in webview");
            
            // preload ad in the next available webview
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
    };
    
    // request a new ad from the placement manager
    [pm adForAdType:adType
          placement:placement
           metadata:metadata
       orientations:self.adOrientations
     requestHandler:requestHandler
  completionHandler:completionHandler];
}


#pragma mark -

+ (TuneAdOrientation)defaultAdOrientation
{
    UIInterfaceOrientationMask mask = supportedOrientations();
    
    BOOL isLandscape = mask & UIInterfaceOrientationMaskLandscape;
    BOOL isPortrait = mask & UIInterfaceOrientationMaskPortrait || mask & UIInterfaceOrientationMaskPortraitUpsideDown;
    
    TuneAdOrientation defaultOrientation = isLandscape && isPortrait ? TuneAdOrientationAll : (isLandscape ? TuneAdOrientationLandscape : TuneAdOrientationPortrait);
    
    return defaultOrientation;
}


#pragma mark -

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

- (void)clearWebview:(UIWebView *)webview
{
    [webview loadHTMLString:TUNE_STRING_EMPTY baseURL:nil];
}


#pragma mark -

- (void)preloadAd:(TuneAd *)ad
{
    // find out the webview that's currently not visible
    UIWebView *nextWebView = 1 == viewIndex ? webview2 : webview1;
    
    DLog(@"TuneAdView preloadAd: webview = %d, adNext.html.length = %d", 1 == viewIndex ? 2 : 1, (int)ad.html.length);
    
#if DEBUG
    if([ad.html length] == 0)
    {
        DLog(@"!!!! invalid ad html !!!!");
    }
#endif
    
    // load the next ad in the currently invisible webview
    [nextWebView loadHTMLString:ad.html baseURL:nil];
}


#pragma mark - WebView Helper - UIScrollViewDelegate Methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    // disable UIWebView zoom
    return nil;
}


#pragma mark - View Rotation

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
    
    if(TuneAdTypeBanner == adType)
    {
        CGFloat newBannerHeight = UIInterfaceOrientationIsLandscape(newOrientation) ? [TuneAd bannerHeightLandscape] : [TuneAd bannerHeightPortrait];
        bounds.size = CGSizeMake(bounds.size.width, newBannerHeight);
        
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, bounds.size.width, newBannerHeight);
    }
    
    webview1.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
    webview2.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
    
    if(activity)
    {
        activity.center = CGPointMake(bounds.size.width / 2, bounds.size.height / 2);
    }
}


#pragma mark -

- (BOOL)handleAdClickWithUrl:(NSURL *)url
{
    BOOL openedExternally = NO;
    
    DRLog(@"handleAdClickWithUrl: appStoreVisible = %d", appStoreVisible);
    
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
            
            openedExternally = YES;
        }
        
        // now that the ad has been clicked, fire the ad click url
        // regardless if the target app download page is displayed or not
        // since we do not have a way to detect if the external browser
        // was successful in opening the click url
        NSString *clickUrl = [TuneAdUtils tuneAdClickUrl:adCurrent];
        [TuneAdNetworkHelper fireUrl:clickUrl ad:adCurrent];
    }
    
    return openedExternally;
}

- (void)showInAppStoreForAppId:(NSNumber *)itemId
                 campaignToken:(NSString *)cToken
                affiliateToken:(NSString *)aToken
                    requestUrl:(NSURL *)url
{
    // empty placeholder implementation
}

/*!
 Handles in-app store view close action.
 */
- (void)handleStoreViewClosing
{
    [self dismissActivityOverlay];
    
    appStoreVisible = NO;
}


#pragma mark -

- (void)dismissActivityOverlay
{
    if(activity)
    {
        [activity removeFromSuperview];
        activity = nil;
    }
}


#pragma mark - Notification Handlers

- (void)statusBarOrientationWillChange:(NSNotification *)notification
{
    NSNumber *numOrientation = notification.userInfo[UIApplicationStatusBarOrientationUserInfoKey];
    UIInterfaceOrientation orientation = numOrientation.intValue;
    
    // update view size depending on current interface orientation
    [self updateWebViewFrameForOrientation:orientation];
}

- (void)handleNetworkChange:(NSNotification *)notice
{
    // empty placeholder implementation
}

- (void)handleAppBecameActive:(NSNotification *)notice
{
    // empty placeholder implementation
}

- (void)handleAppWillResignActive:(NSNotification *)notice
{
    // empty placeholder implementation
}


#pragma mark - Object Dealloc Cleanup

- (void)dealloc
{
    [self dismissActivityOverlay];
    
    webview1.delegate = nil;
    webview2.delegate = nil;
    
    // now that the TuneAdView object is being released,
    // remove all notification observers
    [webview1 stopLoading];
    [webview2 stopLoading];

    webview1 = nil;
    webview2 = nil;
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
#if !TARGET_OS_WATCH
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kTuneReachabilityChangedNotification object:nil];
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}


#pragma mark - Override UIView method

- (CGSize)sizeThatFits:(CGSize)size
{
    //DLog(@"sizeThatFits: %@ --> %@", NSStringFromCGSize(size), NSStringFromCGSize(webview1.frame.size));
    
    return webview1.frame.size;
}


#pragma mark - Delegate Callback Helper Methods

- (void)notifyDidFetchAd:(NSString *)placement
{
    _ready = YES;
    
    [self.delegate tuneAdDidFetchAdForView:self placement:placement];
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
