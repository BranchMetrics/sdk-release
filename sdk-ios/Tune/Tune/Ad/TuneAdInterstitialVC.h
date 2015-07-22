//
//  TuneAdInterstitialVC.h
//  Tune
//
//  Created by Harshal Ogale on 5/28/14.
//  Copyright (c) 2014 Tune Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../TuneAdView.h"
#import "../TuneInterstitial.h"

@interface TuneAdInterstitialVC : UIViewController

@property (nonatomic, assign) BOOL disabled;

- (id)initWithAdView:(TuneInterstitial *)ad;

@end
