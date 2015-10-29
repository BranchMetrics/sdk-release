//
//  TuneAdViewTests.m
//  Tune
//
//  Created by Harshal Ogale on 9/4/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "../Tune/Tune.h"
#import "../Tune/TuneAdView.h"
#import "../Tune/TuneBanner.h"
#import "../Tune/TuneInterstitial.h"
#import "../Tune/Common/TuneUtils.h"

@interface TuneAdViewTests : XCTestCase <TuneAdDelegate>
{
    XCTestExpectation *completionExpectation;
    
    NSInteger TUNE_AD_TEST_NO_ERROR;
    NSInteger expectedTuneAdError;
}

@end


@implementation TuneAdViewTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    TUNE_AD_TEST_NO_ERROR = -123454321;
    expectedTuneAdError = TUNE_AD_TEST_NO_ERROR;
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testInterstitialAd {
    
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
    
    // Interstitial
    expectedTuneAdError = TUNE_AD_TEST_NO_ERROR;
    completionExpectation = [self expectationWithDescription:@"interstitial ad fetch"];
    
    // create ad view
    TuneInterstitial *interstitial = [TuneInterstitial adViewWithDelegate:self];
    [interstitial cacheForPlacement:@"place1"];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testBannerAd {
    
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
    
    // Banner
    expectedTuneAdError = TUNE_AD_TEST_NO_ERROR;
    completionExpectation = [self expectationWithDescription:@"banner ad fetch"];
    
    // create ad view
    TuneBanner *banner = [TuneBanner adViewWithDelegate:self];
    [banner showForPlacement:@"place1"];
    
    // add the banner view to a dummy window, to allow banner functioning
    UIWindow *tempWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 768, 1024 )];
    UIView *tempView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
    [tempWindow addSubview:tempView];
    [tempView addSubview:banner];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testAdRequest {
    
    NSString * TUNE_ADVERTISER_ID = @"877";
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
    
    // ad request
    TuneAdMetadata *req = [[TuneAdMetadata alloc] init];
    [req setKeywords:@[@"keyword1", @"second keyword"]];
    [req setCustomTargets:@{@"target1":@"value1", @"target2":@"value2", @"target3":@"value3"}];
    
    // Interstitial
    expectedTuneAdError = TUNE_AD_TEST_NO_ERROR;
    completionExpectation = [self expectationWithDescription:@"interstitial ad request fetch"];
    
    // create ad view
    TuneInterstitial *interstitial = [TuneInterstitial adViewWithDelegate:self];
    [interstitial cacheForPlacement:@"place1" adMetadata:req];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    
    // Banner
    expectedTuneAdError = TUNE_AD_TEST_NO_ERROR;
    completionExpectation = [self expectationWithDescription:@"banner ad request fetch"];
    
    // create ad view
    TuneBanner *banner = [TuneBanner adViewWithDelegate:self];
    [banner showForPlacement:@"place1" adMetadata:req];
    
    // add the banner view to a dummy window, to allow banner functioning
    UIWindow *tempWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 768, 1024 )];
    UIView *tempView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
    [tempWindow addSubview:tempView];
    [tempView addSubview:banner];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}


#pragma mark - TuneAdError Tests

- (void)testNoMatchingAdsError {
    
    NSString * TUNE_ADVERTISER_ID = @"877";
    NSString * TUNE_CONVERSION_KEY = @"8c14d6bbe466b65211e781d62e301eec";
    NSString * TUNE_PACKAGE_NAME = @"com.tune.interstitialtest";
    
    // initialize Tune by providing advertiser_id and conversion_key
    [Tune initializeWithTuneAdvertiserId:TUNE_ADVERTISER_ID
                       tuneConversionKey:TUNE_CONVERSION_KEY];
    
    // required only if your app's Tune package name is different than the app bundle id
    [Tune setPackageName:TUNE_PACKAGE_NAME];
    
    NSUUID *ifa = [[NSUUID alloc] initWithUUIDString:@"12345678901234567890123456789012"];
    
    // provide IFA to Tune
    [Tune setAppleAdvertisingIdentifier:ifa
             advertisingTrackingEnabled:YES];
    
    // ad request
    TuneAdMetadata *req = [TuneAdMetadata new];
    [req setCustomTargets:@{@"gender":@"male",@"dummyParam":@"dummyValue"}];
    
    // Interstitial
    expectedTuneAdError = TuneAdErrorNoMatchingAds;
    completionExpectation = [self expectationWithDescription:@"interstitial no matching ad error test"];
    
    // create ad view
    TuneInterstitial *interstitial = [TuneInterstitial adViewWithDelegate:self];
    [interstitial cacheForPlacement:@"main_menu" adMetadata:req];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    
    // Banner
    expectedTuneAdError = TuneAdErrorNoMatchingAds;
    completionExpectation = [self expectationWithDescription:@"banner no matching ad error test"];
    
    // create ad view
    TuneBanner *banner = [TuneBanner adViewWithDelegate:self];
    [banner showForPlacement:@"main_menu" adMetadata:req];
    
    // add the banner view to a dummy window, to allow banner functioning
    UIWindow *tempWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 768, 1024 )];
    UIView *tempView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
    [tempWindow addSubview:tempView];
    [tempView addSubview:banner];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testNoSuitableSiteError {
    
    NSString * TUNE_ADVERTISER_ID = @"877";
    NSString * TUNE_CONVERSION_KEY = @"12345678ef0ec2d433f595f087651234";
    NSString * TUNE_PACKAGE_NAME = @"com.dummy.dummySite12321312";
    
    // initialize Tune by providing advertiser_id and conversion_key
    [Tune initializeWithTuneAdvertiserId:TUNE_ADVERTISER_ID
                       tuneConversionKey:TUNE_CONVERSION_KEY];
    
    // required only if your app's Tune package name is different than the app bundle id
    [Tune setPackageName:TUNE_PACKAGE_NAME];
    
    NSUUID *ifa = [[NSUUID alloc] initWithUUIDString:@"12345678901234567890123456789012"];
    
    // provide IFA to Tune
    [Tune setAppleAdvertisingIdentifier:ifa
             advertisingTrackingEnabled:YES];
    
    // Interstitial
    expectedTuneAdError = TuneAdErrorNoMatchingSites;
    completionExpectation = [self expectationWithDescription:@"interstitial no suitable site error test"];
    
    // create ad view
    TuneInterstitial *interstitial = [TuneInterstitial adViewWithDelegate:self];
    [interstitial cacheForPlacement:@"place1"];
    
    [self waitForExpectationsWithTimeout:60.0 handler:nil];
    
    // Banner
    expectedTuneAdError = TuneAdErrorNoMatchingSites;
    completionExpectation = [self expectationWithDescription:@"banner no suitable site error test"];
    
    // create ad view
    TuneBanner *banner = [TuneBanner adViewWithDelegate:self];
    [banner showForPlacement:@"place1"];
    
    // add the banner view to a dummy window, to allow banner functioning
    UIWindow *tempWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 768, 1024 )];
    UIView *tempView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
    [tempWindow addSubview:tempView];
    [tempView addSubview:banner];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testUnknownAdvertiserError {
    
    NSString * TUNE_ADVERTISER_ID = @"32165498745";
    NSString * TUNE_CONVERSION_KEY = @"8c14d6bbe466b65211e781d62e301eec";
    NSString * TUNE_PACKAGE_NAME = @"com.tune.interstitialtest";
    
    // initialize Tune by providing advertiser_id and conversion_key
    [Tune initializeWithTuneAdvertiserId:TUNE_ADVERTISER_ID
                       tuneConversionKey:TUNE_CONVERSION_KEY];
    
    // required only if your app's Tune package name is different than the app bundle id
    [Tune setPackageName:TUNE_PACKAGE_NAME];
    
    NSUUID *ifa = [[NSUUID alloc] initWithUUIDString:@"12345678901234567890123456789012"];
    
    // provide IFA to Tune
    [Tune setAppleAdvertisingIdentifier:ifa
             advertisingTrackingEnabled:YES];
    
    // Interstitial
    expectedTuneAdError = TuneAdErrorUnknownAdvertiser;
    completionExpectation = [self expectationWithDescription:@"interstitial unknown advertiser error test"];
    
    // create ad view
    TuneInterstitial *interstitial = [TuneInterstitial adViewWithDelegate:self];
    [interstitial cacheForPlacement:@"place1"];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
    
    // Banner
    expectedTuneAdError = TuneAdErrorUnknownAdvertiser;
    completionExpectation = [self expectationWithDescription:@"banner unknown advertiser error test"];
    
    // create ad view
    TuneBanner *banner = [TuneBanner adViewWithDelegate:self];
    [banner showForPlacement:@"place1"];
    
    // add the banner view to a dummy window, to allow banner functioning
    UIWindow *tempWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 768, 1024 )];
    UIView *tempView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
    [tempWindow addSubview:tempView];
    [tempView addSubview:banner];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testNetworkNotReachable
{
    NSString * TUNE_ADVERTISER_ID = @"877";
    NSString * TUNE_CONVERSION_KEY = @"8c14d6bbe466b65211e781d62e301eec";
    NSString * TUNE_PACKAGE_NAME = @"com.tune.interstitialtest";
    
    // override network status
    [TuneUtils overrideNetworkReachability:[@NO stringValue]];
    
    // initialize Tune by providing advertiser_id and conversion_key
    [Tune initializeWithTuneAdvertiserId:TUNE_ADVERTISER_ID
                       tuneConversionKey:TUNE_CONVERSION_KEY];
    
    // required only if your app's Tune package name is different than the app bundle id
    [Tune setPackageName:TUNE_PACKAGE_NAME];
    
    NSUUID *ifa = [[NSUUID alloc] initWithUUIDString:@"12345678901234567890123456789012"];
    
    // provide IFA to Tune
    [Tune setAppleAdvertisingIdentifier:ifa
             advertisingTrackingEnabled:YES];
    
    // Interstitial
    expectedTuneAdError = TuneAdErrorNetworkNotReachable;
    completionExpectation = [self expectationWithDescription:@"interstitial network not reachable error test"];
    
    // create ad view
    TuneInterstitial *interstitial = [TuneInterstitial adViewWithDelegate:self];
    [interstitial cacheForPlacement:@"place1"];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    // Banner
    expectedTuneAdError = TuneAdErrorNetworkNotReachable;
    completionExpectation = [self expectationWithDescription:@"banner network not reachable error test"];
    
    // create ad view
    TuneBanner *banner = [TuneBanner adViewWithDelegate:self];
    [banner showForPlacement:@"place1"];
    
    // add the banner view to a dummy window, to allow banner functioning
    UIWindow *tempWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 768, 1024 )];
    UIView *tempView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
    [tempWindow addSubview:tempView];
    [tempView addSubview:banner];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    // remove network status override
    [TuneUtils overrideNetworkReachability:nil];
}


#pragma mark - TuneAdDelegate Methods

- (void)tuneAdDidFetchAdForView:(TuneAdView *)adView placement:(NSString *)placement
{
    XCTAssertEqual(expectedTuneAdError, TUNE_AD_TEST_NO_ERROR, @"Should not have succeeded");
    
    [completionExpectation fulfill];
}

- (void)tuneAdDidFailWithError:(NSError *)error forView:(TuneAdView *)adView
{
    //NSLog(@"error = %@", error);
    
    XCTAssertEqual(expectedTuneAdError, error.code, @"Unexpected error");
    
    [completionExpectation fulfill];
}

- (void)tuneAdDidStartActionForView:(TuneAdView *)adView willLeaveApplication:(BOOL)willLeave
{
    // empty
}

- (void)tuneAdDidEndActionForView:(TuneAdView *)adView
{
    // empty
}

- (void)tuneAdDidCloseForView:(TuneAdView *)adView
{
    // empty
}

- (void)tuneAdDidFireRequestWithUrl:(NSString *)url data:(NSString *)data forView:(TuneAdView *)adView
{
    //NSLog(@"%@\n%@", url, data);
}

@end
