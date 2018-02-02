//
//  TuneBlankViewController.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/28/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneBlankViewController.h"

@interface TuneBlankViewController ()

@end

@implementation TuneBlankViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.viewWillAppearCount += 1;
}


@end
