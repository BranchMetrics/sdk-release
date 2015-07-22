//
//  BannerViewController.h
//  TuneAdDemo
//
//  Created by Harshal Ogale on 5/21/14.
//  Copyright (c) 2014 HasOffers Inc. All rights reserved.
//

@import UIKit;

@interface BannerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIButton *btnToggle;

- (IBAction)toggleBanner:(id)sender;

@end
