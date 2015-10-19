//
//  ViewController.m
//  TuneBasicBannerAd
//
//  Created by Harshal Ogale on 10/14/14.
//  Copyright (c) 2014 TUNE Inc. All rights reserved.
//

#import "ViewController.h"

@import MobileAppTracker;

@interface ViewController () <TuneAdDelegate>

@end

TuneBanner *banner;

static NSArray *arrPlacements;

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    banner = [TuneBanner adViewWithDelegate:self];
    [self.view addSubview:banner];
    
    arrPlacements = @[@"place1", @"place2", @"place3"];
    [banner showForPlacement:@"place1"];
    [NSTimer scheduledTimerWithTimeInterval:5. target:self selector:@selector(timerFired) userInfo:nil repeats:YES];
}

- (void)timerFired
{
    NSLog(@"timerFired: calling updatePlacement");
    [self updatePlacement];
}

- (void)updatePlacement
{
    NSString *newPlacement = arrPlacements[rand() % arrPlacements.count];
    NSLog(@"updatePlacement: new placement = %@", newPlacement);
    [banner showForPlacement:newPlacement];
}

- (void)viewDidLayoutSubviews
{
    [self layoutAnimated:[UIView areAnimationsEnabled]];
}

- (void)layoutAnimated:(BOOL)animated
{
    // TODO: add code to adjust your existing content view(s) and reposition the banner view depending upon ad availability
    
    // all we need to do is ask the banner for a size that fits into the layout area we are using
    CGSize sizeForBanner = [banner sizeThatFits:self.view.bounds.size];
    
    // compute the ad banner frame
    CGRect bannerFrame = banner.frame;
    
    if (banner.isReady)
    {
        // bring the ad into view
        bannerFrame.origin.y = self.view.frame.size.height - sizeForBanner.height;
        bannerFrame.size.height = sizeForBanner.height;
        bannerFrame.size.width = sizeForBanner.width;
    }
    else
    {
        // hide the banner off screen further off the bottom
        bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
    }
    
    // re-layout the current view
    [self.view setNeedsLayout];
    
    // animate the change in frame size of the main view and the banner view
    [UIView animateWithDuration:animated ? 0.25 : 0.0 animations:^{
        banner.frame = bannerFrame;
    }];
}


#pragma mark - TuneAdDelegate Methods

- (void)tuneAdDidFetchAdForView:(TuneAdView *)adView placement:(NSString *)placement
{
    NSLog(@"tuneAdDidFetchAdForView");
    
    [self layoutAnimated:YES];
}

- (void)tuneAdDidFailWithError:(NSError *)error forView:(TuneAdView *)adView
{
    NSLog(@"tuneAdDidFailWithError: %@", error);
    
    [self layoutAnimated:YES];
}

-(void)tuneAdDidFireRequestWithUrl:(NSString *)url data:(NSString *)data forView:(TuneAdView *)adView
{
    NSLog(@"tuneAdDidFireRequest: url = %@, data = %@", url, data);
}

- (void)tuneAdDidStartActionForView:(TuneAdView *)adView willLeaveApplication:(BOOL)willLeave
{
    NSLog(@"tuneAdDidStartActionForView: willLeaveApplication = %d", willLeave);
}

- (void)tuneAdDidEndActionForView:(TuneAdView *)adView
{
    NSLog(@"tuneAdDidEndActionForView");
}

@end
