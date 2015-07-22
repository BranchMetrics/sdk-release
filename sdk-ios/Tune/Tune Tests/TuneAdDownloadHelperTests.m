//
//  TuneAdDownloadHelperTests.m
//  Tune
//
//  Created by Harshal Ogale on 9/4/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "../Tune/Ad/TuneAdDownloadHelper.h"

#import "../Tune/Tune.h"


@interface TuneAdDownloadHelperTests : XCTestCase <TuneAdDelegate, TuneAdDownloadHelperDelegate>
{
    XCTestExpectation *completionExpectation;

    NSInteger TUNE_AD_TEST_NO_ERROR;
    NSInteger expectedTuneAdError;
}

@end


@implementation TuneAdDownloadHelperTests

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

- (void)testAdDownload {
    NSString * TUNE_ADVERTISER_ID = @"877";
//    NSString * TUNE_CONVERSION_KEY = @"8c14d6bbe466b65211e781d62e301eec";
//    NSString * TUNE_PACKAGE_NAME = @"com.tune.interstitialtest";
    NSString * TUNE_CONVERSION_KEY = @"40c19f41ef0ec2d433f595f0880d39b9";
    NSString * TUNE_PACKAGE_NAME = @"edu.self.AtomicDodgeBallLite";
    
    // initialize Tune by providing advertiser_id and conversion_key
    [Tune initializeWithTuneAdvertiserId:TUNE_ADVERTISER_ID
                       TuneConversionKey:TUNE_CONVERSION_KEY];
    
    // required only if your app's Tune package name is different than the app bundle id
    [Tune setPackageName:TUNE_PACKAGE_NAME];
    
    NSUUID *ifa = [[NSUUID alloc] initWithUUIDString:@"12345678901234567890123456789012"];
    
    // provide IFA to Tune
    [Tune setAppleAdvertisingIdentifier:ifa
             advertisingTrackingEnabled:YES];
    
    TuneAdMetadata *req = [TuneAdMetadata new];
    req.customTargets = @{@"param123":@"value123"};
    
    expectedTuneAdError = TUNE_AD_TEST_NO_ERROR;
    completionExpectation = [self expectationWithDescription:@"interstitial ad fetch"];
    
    TuneInterstitial *interstitial = [TuneInterstitial adViewWithDelegate:self];
    [interstitial cacheForPlacement:@"place1" adMetadata:req];
    
//    TuneAdDownloadHelper *dh = [[TuneAdDownloadHelper alloc] initWithAdView:adView];
//    dh.delegate = self;
//    
//    XCTAssertFalse(dh.fetchAdInProgress, @"fetch request should not have started before fetchAd call");
//    
//    [dh fetchAd];
//    
//    XCTAssertTrue(dh.fetchAdInProgress, @"fetch request should have started after fetchAd call");
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

#pragma mark - TuneAdDownloadHelperDelegate

- (void)downloadFinishedWithAd:(TuneAd *)data
{
    XCTAssertEqual(expectedTuneAdError, TUNE_AD_TEST_NO_ERROR, @"Should not have succeeded, error expected: %zd", expectedTuneAdError);
    
    [completionExpectation fulfill];
}

- (void)downloadFailedWithError:(NSError *)error
{
    DLLog(@"Tune download tester: error = %@", error);
    
    XCTAssertNotEqual(expectedTuneAdError, TUNE_AD_TEST_NO_ERROR, @"Unexpected error: %@", error);
    XCTAssertEqual(expectedTuneAdError, error.code, @"Unexpected error: expected = %zd, actual = %zd", expectedTuneAdError, error.code);
    
    [completionExpectation fulfill];
}

- (void)downloadStartedForAdWithUrl:(NSString *)url data:(NSString *)data
{
    DLLog(@"Tune download tester: fired = %@\n%@", url, data);
}

#pragma mark - TuneAdDelegate

- (void)tuneAdDidFetchAdForView:(id<TuneAdView>)adView
{
    
}

@end
