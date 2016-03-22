//
//  ViewController.m
//  TestApp_tvOS
//
//  Created by Harshal Ogale on 10/7/15.
//  Copyright © 2015 Tune. All rights reserved.
//
#import "ViewController.h"

@import AdSupport;
@import MobileAppTracker_tvOS;

@import CoreLocation;

@interface ViewController () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

CLLocationManager *singleLocationManager;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //NSLog(@"tv ifa = %@", [[ASIdentifierManager sharedManager] advertisingIdentifier]);
    
    NSLog(@"TV ViewController loaded");
    
    // location manager without requestWhenInUseAuthorization, delegate or startUpdatingLocation
    singleLocationManager = [CLLocationManager new];
    
    // location manager with requestWhenInUseAuthorization, delegate and startUpdatingLocation
    self.locationManager = [CLLocationManager new];
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager stopUpdatingLocation];
    [self.locationManager setDelegate:self];
}

-(void)viewDidAppear:(BOOL)animated
{
    NSLog(@"TV ViewController didAppear");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tapClick:(id)sender
{
    NSLog(@"click fired");
    
    NSURL *urlClick = [NSURL URLWithString:@"<insert_a_measurement_url>"];
    
    [[[NSURLSession sharedSession] dataTaskWithURL:urlClick completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSLog(@"click response: response = %@, error = %@", response, error);
        if(response.URL)
        {
            [[UIApplication sharedApplication] openURL:response.URL];
        }
    }] resume];
}

- (IBAction)tapSession:(id)sender
{
    NSLog(@"session fired from TV app");
    
    [Tune measureSession];
}

- (IBAction)tapEvent:(id)sender
{
    NSLog(@"event fired from TV app");
    
    TuneEvent *event1 = [TuneEvent eventWithName:@"event1"];
    event1.refId = @"ref1";
    
    [Tune measureEvent:event1];
}

@end
