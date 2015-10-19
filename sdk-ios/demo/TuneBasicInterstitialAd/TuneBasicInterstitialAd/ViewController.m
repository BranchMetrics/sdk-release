//
//  ViewController.m
//  TuneBasicInterstitialAd
//
//  Created by Harshal Ogale on 11/18/14.
//  Copyright (c) 2014 TUNE Inc. All rights reserved.
//

#import "ViewController.h"

@import MobileAppTracker;


@interface ViewController () <TuneAdDelegate>

- (IBAction)showAdAction:(id)sender;

@end

TuneInterstitial *interstitial;

static NSArray *arrPlacements;

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self createAdView];
}

- (IBAction)showAdAction:(id)sender
{
    [self showInterstitialAd];
}


#pragma mark - TuneAdView Methods

- (void)createAdView
{
    NSLog(@"createAdView");
    
    // create a TUNE ad interstitial view
    interstitial = [TuneInterstitial adViewWithDelegate:self];
    
    TuneAdMetadata *metadata = [TuneAdMetadata new];
    metadata.debugMode = YES;
    
    arrPlacements = @[@"place1", @"place2", @"place3"];
    [interstitial cacheForPlacement:arrPlacements[0] adMetadata:metadata];
    [interstitial cacheForPlacement:arrPlacements[1] adMetadata:metadata];
    [interstitial cacheForPlacement:arrPlacements[2] adMetadata:metadata];
}

- (void)showInterstitialAd
{
    NSLog(@"showInterstitialAd: adview ready = %d", interstitial.isReady);
    // provide a view controller instance to allow the Interstitial ad to be presented
    NSString *newPlacement = arrPlacements[rand() % arrPlacements.count];
    [interstitial showForPlacement:newPlacement viewController:self];
}


#pragma mark - TuneAdDelegate Methods

- (void)tuneAdDidCloseForView:(TuneAdView *)adView
{
    NSLog(@"tuneAdDidClose");
}

- (void)tuneAdDidFetchAdForView:(TuneAdView *)adView placement:(NSString *)placement
{
    NSLog(@"tuneAdDidFetchAd");
}

- (void)tuneAdDidFailWithError:(NSError *)error forView:(TuneAdView *)adView
{
    // Ref: TuneAdView.TuneAdError enum for the list of known error codes
    // Ref: Troubleshooting steps for info on how to handle some of these error codes
    NSLog(@"tuneAdDidFailWithError: %@", error);
}

- (void)tuneAdDidFireRequestWithUrl:(NSString *)url data:(NSString *)data forView:(TuneAdView *)adView
{
    NSLog(@"tuneAdDidFireRequestWithUrl:data:forView:");
    //NSLog(@"tuneAdDidFireRequestWithUrl:data:forView: url = %@, data = %@", url, data);
}

- (void)tuneAdDidStartActionForView:(TuneAdView *)adView willLeaveApplication:(BOOL)willLeave
{
    NSLog(@"tuneAdDidStartActionForView:willLeaveApplication: willLeave = %d", willLeave);
}

- (void)tuneAdDidEndActionForView:(TuneAdView *)adView
{
    NSLog(@"tuneAdDidEndActionForView");
}

@end
