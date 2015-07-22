//
//  InterstitialViewController.m
//  TuneAdDemo
//
//  Created by Harshal Ogale on 5/21/14.
//  Copyright (c) 2014 HasOffers Inc. All rights reserved.
//

#import "InterstitialViewController.h"
#import "AppDelegate.h"

@import MobileAppTracker;
//#import <Tune/TuneAdView.h>
//#import <Tune/Tune.h>


@interface InterstitialViewController () <TuneAdDelegate>

@property (nonatomic, strong) TuneInterstitial *adView;

@end

BOOL shouldShowAd = NO;

@implementation InterstitialViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
    
    [self resetAdView];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    NSString *advId = [[[[Tune class] performSelector:@selector(sharedManager)] performSelector:@selector(parameters)] performSelector:@selector(advertiserId)];
    NSString *convKey = [[[[Tune class] performSelector:@selector(sharedManager)] performSelector:@selector(parameters)] performSelector:@selector(conversionKey)];
    NSString *pkg = [[[[Tune class] performSelector:@selector(sharedManager)] performSelector:@selector(parameters)] performSelector:@selector(packageName)];
#pragma clang diagnostic pop
    
    if (advId && convKey && pkg) {
        //NSLog(@"IVC: init: adv = %@, key = %@, pkg = %@", advId, convKey, pkg);
        
        [self createAdView];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetAdView) name:@"TuneAdDemoServerChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetAdView) name:@"TuneAdDemoAdvertiserChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createAdView) name:@"TuneAdDemoAppChanged" object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - TuneAdDelegate

- (void)tuneAdDidCloseForView:(id<TuneAdView>)adView
{
    NSLog(@"InterstitialVC tuneAdDidClose");
    
    [self writeToConsole:@"Interstitial closed"];
}

- (void)tuneAdDidFetchAdForView:(id<TuneAdView>)adView
{
    NSLog(@"InterstitialVC tuneAdDidFetchAd");
    
    [self writeToConsole:@"Interstitial fetched"];
    
    if(shouldShowAd)
    {
        shouldShowAd = NO;
        [self.adView showForPlacement:@"tab2" viewController:self];
    }
}

- (void)tuneAdDidFailWithError:(NSError *)error forView:(id<TuneAdView>)adView
{
    NSLog(@"InterstitialVC tuneAdDidFailWithError: %@", error);
    
    [self writeToConsole:error];
}

-(void)tuneAdDidFireRequestWithUrl:(NSString *)url data:(NSString *)data forView:(id<TuneAdView>)adView
{
    NSLog(@"tuneAdDidFireRequestWithUrl:\nurl = %@,\ndata = %@", url, data);
    
    [self writeToConsole:@{@"url":url,@"data":data}];
}

- (void)writeToConsole:(id)object
{
    NSDictionary *dict = @{@"object":object};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TuneAdDemoNewLogText"
                                                        object:nil
                                                      userInfo:dict];
}

#pragma mark - Button Action Methods

- (IBAction)showInterstitialAd:(id)sender 
{
    NSLog(@"InterstitialVC showInterstitialAd: button clicked, adview ready = %d", self.adView.isReady);
    shouldShowAd = YES;
    [self.adView showForPlacement:@"tab2" viewController:self];
}

#pragma mark - Handle Notifications

- (void)resetAdView
{
    NSLog(@"InterstitialVC: resetAdView");
    
    if(self.adView)
    {
        self.adView.delegate = nil;
        [self.adView removeFromSuperview];
        self.adView = nil;
    }
}

- (void)createAdView
{
    NSLog(@"InterstitialVC: createAdView");
    
    [self resetAdView];
    
    AppDelegate *ad = [UIApplication sharedApplication].delegate;
    
    TuneAdMetadata *meta = [[TuneAdMetadata alloc] init];
    meta.debugMode = ad.tuneAdViewDebugMode;
    
    // create a Tune ad interstitial view
    self.adView = [TuneInterstitial adViewWithDelegate:self];
    [self.adView cacheForPlacement:@"tab2" adMetadata:meta];
    
    [self.view addSubview:self.adView];
    self.adView.hidden = YES;
}

@end
