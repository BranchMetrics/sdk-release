//
//  TuneAdParamsTests.m
//  Tune
//
//  Created by Harshal Ogale on 9/4/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "TuneTestsHelper.h"

#import "../Tune/Tune.h"
#import "../Tune/TuneInterstitial.h"
#import "../Tune/Ad/TuneAdParams.h"

@interface TuneAdParamsTests : XCTestCase

@end

@implementation TuneAdParamsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    NSString * TUNE_ADVERTISER_ID = @"877";
    //NSString * TUNE_CONVERSION_KEY = @"8c14d6bbe466b65211e781d62e301eec";
    //NSString * TUNE_PACKAGE_NAME = @"com.tune.interstitialtest";
    NSString * TUNE_CONVERSION_KEY = @"40c19f41ef0ec2d433f595f0880d39b9";
    NSString * TUNE_PACKAGE_NAME = @"edu.self.AtomicDodgeBallLite";
    
    // initialize Tune by providing advertiser_id and conversion_key
    [Tune initializeWithTuneAdvertiserId:TUNE_ADVERTISER_ID
                       tuneConversionKey:TUNE_CONVERSION_KEY];
    
    // required only if your app's Tune package name is different than the app bundle id
    [Tune setPackageName:TUNE_PACKAGE_NAME];
    
    NSUUID *ifa = [[NSUUID alloc] initWithUUIDString:@"12345678901234567890123456789012"];
    
    // provide IFA to Tune
    [Tune setAppleAdvertisingIdentifier:ifa
             advertisingTrackingEnabled:YES];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testJsonForView
{
    TuneInterstitial *interstitial = [TuneInterstitial adView];
    [interstitial cacheForPlacement:@"main_menu"];
    
    NSString *actual = [TuneAdParams jsonForAdType:TuneAdTypeInterstitial placement:@"main_menu" metadata:nil orientations:TuneAdOrientationAll];
    
    NSLog(@"actual = %@", actual);
    
    // TODO: assign value to 'expected'
//    NSString *expected = nil;
//    
//    XCTAssertEqual(actual, expected, @"Incorrect JSON encoding of params.");
}

- (void)testJsonForViewAndAd
{
    NSString *actual = [TuneAdParams jsonForAdType:TuneAdTypeInterstitial placement:@"main_menu" metadata:nil orientations:TuneAdOrientationAll];
    
    NSLog(@"actual = %@", actual);
    
    // TODO: assign value to 'expected'
//    NSString *expected = nil;
//    
//    XCTAssertEqual(actual, expected, @"Incorrect JSON encoding of params.");
}

@end
