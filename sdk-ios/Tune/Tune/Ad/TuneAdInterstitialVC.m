//
//  TuneAdInterstitialVC.m
//  Tune
//
//  Created by Harshal Ogale on 5/28/14.
//  Copyright (c) 2014 Tune Inc. All rights reserved.
//

#import "TuneAdInterstitialVC.h"

#import "../TuneInterstitial.h"

@interface TuneAdInterstitialVC ()

@property (nonatomic, weak) TuneInterstitial *adView;

@end

@implementation TuneAdInterstitialVC

- (id)initWithAdView:(TuneInterstitial *)ad
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Custom initialization
        self.adView = ad;
        self.view.backgroundColor = [UIColor blackColor];
        
        if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
        {
            // iOS 7
            [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
        }
        else
        {
            // iOS 6
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        }
        
        _disabled = NO;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _disabled = NO;
    
    if (![self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
    {
        // iOS 6
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _disabled = YES;
    
    if (![self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)])
    {
        // iOS 6
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.adView];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UIInterfaceOrientationMask mask;
    
    switch (self.adView.adOrientations) {
        case TuneAdOrientationPortrait:
            mask = UIInterfaceOrientationMaskPortrait;
            break;
        case TuneAdOrientationLandscape:
            mask = UIInterfaceOrientationMaskLandscape;
            break;
        default:
            mask = UIInterfaceOrientationMaskAll;
            break;
    }
    
    return mask;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
