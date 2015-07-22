//
//  BannerViewController.m
//  TuneAdDemo
//
//  Created by Harshal Ogale on 5/21/14.
//  Copyright (c) 2014 HasOffers Inc. All rights reserved.
//

#import "BannerViewController.h"
#import "AppDelegate.h"

@import MobileAppTracker;


//#import <Tune/TuneAdView.h>
//#import <Tune/Tune.h>
//#import <Tune/TuneEventItem.h>

@interface BannerViewController () <TuneAdDelegate>

@property (nonatomic, strong) TuneBanner *bannerView;

@end

BOOL visible = NO;
BOOL disableBanner = NO;

@implementation BannerViewController

@synthesize contentView, bannerView, contentViewBottomConstraint, btnToggle;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
    {
        [self setEdgesForExtendedLayout:UIRectEdgeNone];
    }
    
    self.contentView.layer.borderWidth = 10.0f;
    self.contentView.layer.borderColor = [UIColor redColor].CGColor;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    NSString *advId = [[[[Tune class] performSelector:@selector(sharedManager)] performSelector:@selector(parameters)] performSelector:@selector(advertiserId)];
    NSString *convKey = [[[[Tune class] performSelector:@selector(sharedManager)] performSelector:@selector(parameters)] performSelector:@selector(conversionKey)];
    NSString *pkg = [[[[Tune class] performSelector:@selector(sharedManager)] performSelector:@selector(parameters)] performSelector:@selector(packageName)];
#pragma clang diagnostic pop
    
    if (advId && convKey && pkg) {
        //NSLog(@"BVC: init: adv = %@, key = %@, pkg = %@", advId, convKey, pkg);
        
        [self createAdView];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetAdView) name:@"TuneAdDemoServerChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetAdView) name:@"TuneAdDemoAdvertiserChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createAdView) name:@"TuneAdDemoAppChanged" object:nil];
    
    btnToggle.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self layoutAnimated:NO];
}

- (void)viewDidLayoutSubviews
{
    [self layoutAnimated:[UIView areAnimationsEnabled]];
}

- (void)layoutAnimated:(BOOL)animated
{
    CGRect contentFrame = self.view.bounds;
    
    // all we need to do is ask the banner for a size that fits into the layout area we are using
    CGSize sizeForBanner = [self.bannerView sizeThatFits:contentFrame.size];
    
    // compute the ad banner frame
    CGRect bannerFrame = self.bannerView.frame;
    
    CGFloat heightForBanner = 0.;
    
    if (!disableBanner && self.bannerView.isReady)
    {   
        // bring the ad into view
        contentFrame.size.height -= sizeForBanner.height;   // shrink down content frame to fit the banner below it
        bannerFrame.origin.y = contentFrame.size.height;
        bannerFrame.size.height = sizeForBanner.height;
        bannerFrame.size.width = sizeForBanner.width;
        
        // if the ad is available and loaded, make space available at the bottom of the content view
        heightForBanner = sizeForBanner.height;
    }
    else
    {
        // hide the banner off screen further off the bottom
        bannerFrame.origin.y = [[UIScreen mainScreen] bounds].size.height;
        
        // if the ad banner is not ready, let the content view consume the full height available
        heightForBanner = 0.;
    }
    
    // update the content view height as appropriate
    self.contentViewBottomConstraint.constant = heightForBanner;
    
    // re-layout the current view
    [self.view setNeedsLayout];
    
    // animate the change in frame size of the main view and the banner view
    [UIView animateWithDuration:animated ? 0.25 : 0.0 animations:^{
        self.contentView.frame = contentFrame;
        [self.contentView layoutIfNeeded];
        self.bannerView.frame = bannerFrame;
    }];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// iOS 8+
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self layoutAnimated:YES];
}

// iOS < 8.0 alternative for viewWillTransitionToSize:withTransitionCoordinator:
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self layoutAnimated:YES];
}

- (IBAction)toggleBanner:(id)sender
{
    disableBanner = !disableBanner;
    
    [self layoutAnimated:YES];
    
    if(!disableBanner && self.bannerView.isReady)
    {
        AppDelegate *ad = [UIApplication sharedApplication].delegate;
        
        TuneAdMetadata *meta = [TuneAdMetadata new];
        meta.debugMode = ad.tuneAdViewDebugMode;
        
        [self.bannerView showForPlacement:@"tab1" adMetadata:meta];
    }
}

#pragma Handle Notifications

- (void)resetAdView
{
    if(self.bannerView)
    {
        self.bannerView.delegate = nil;
        [self.bannerView removeFromSuperview];
        self.bannerView = nil;
    }
}

- (void)createAdView
{
    NSLog(@"BannerVC createAdView");
    
    [self resetAdView];
    
    AppDelegate *ad = [UIApplication sharedApplication].delegate;
    
    TuneAdMetadata *meta = [TuneAdMetadata new];
    meta.debugMode = ad.tuneAdViewDebugMode;
    
    // create a Tune ad banner view
    self.bannerView = [TuneBanner adViewWithDelegate:self];
    [self.bannerView showForPlacement:@"tab1" adMetadata:meta];
    [self.view addSubview:self.bannerView];
}

#pragma mark - TuneAdDelegate

- (void)tuneAdDidFetchAdForView:(id<TuneAdView>)adView
{
    NSLog(@"BannerVC tuneAdDidFetchAd");
    
    [self writeToConsole:@"Banner fetched"];
    
    if(!disableBanner && self.bannerView.isReady)
    {
        [self layoutAnimated:YES];
    }
}

- (void)tuneAdDidFailWithError:(NSError *)error forView:(id<TuneAdView>)adView
{
    NSLog(@"BannerVC tuneAdDidFailWithError: %@", error);
    
    [self layoutAnimated:YES];
    
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

@end
