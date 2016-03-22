//
//  ViewController.m
//  TestApp
//
//  Created by Harshal Ogale on 9/29/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "ViewController.h"

@import MobileAppTracker;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)sessionButtonTapped:(id)sender {
    [Tune measureSession];
}

- (IBAction)eventButtonTapped:(id)sender {
    [Tune measureEventName:@"event1"];
}

- (IBAction)event2ButtonTapped:(id)sender {
    [Tune measureEventName:@"event2"];
}

- (IBAction)deeplinkButtonTapped:(id)sender {
    [Tune applicationDidOpenURL:@"mytestapp://mytestitem3/mytestitem4" sourceApplication:@"com.somecompany1.someapp1"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"view will appear");
}

@end
