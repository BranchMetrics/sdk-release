//
//  TunePreloadDataTests.m
//  Tune
//
//  Created by Harshal Ogale on 4/27/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <AdSupport/AdSupport.h>

#import "Tune+Testing.h"
#import "TuneKeyStrings.h"
#import "TunePreloadData.h"
#import "TuneTestParams.h"
#import "TuneTracker.h"
#import "TuneUserProfileKeys.h"

@interface TunePreloadDataTests : XCTestCase <TuneDelegate>
{
    BOOL callSuccess;
    BOOL callFailed;
    
    TuneTestParams *params;
}

@end


@implementation TunePreloadDataTests

- (void)setUp
{
    [super setUp];
    
    RESET_EVERYTHING();
    
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey];
    [Tune setDelegate:self];
    
    params = [TuneTestParams new];
    
    emptyRequestQueue();
    
    networkOnline();
}

- (void)tearDown
{
    [Tune setCurrencyCode:nil];
    [Tune setPackageName:kTestBundleId];
    [Tune setPluginName:nil];
    
    emptyRequestQueue();
    
    [super tearDown];
}

#pragma mark - Event parameters

//- (void)testInvalidPublisherId
//{
//    TunePreloadData *pd = [TunePreloadData preloadDataWithPublisherId:@"incorrect_publisher_id"];
//    [Tune setPreloadData:pd];
//    [Tune measureEventName:@"event1"];
//    waitForQueuesToFinish();
//    
//    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
//    ASSERT_KEY_VALUE( TUNE_KEY_PRELOAD_DATA, [@(YES) stringValue]);
//    XCTAssertTrue( callFailed, @"preload data request with invalid publisher id should have failed" );
//    XCTAssertFalse( callSuccess, @"preload data request with invalid publisher id should have failed" );
//}

- (void)testValidPublisherId {
    TunePreloadData *pd = [TunePreloadData preloadDataWithPublisherId:@"112233"];
    [Tune setPreloadData:pd];
    [Tune measureEventName:@"event2"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_PRELOAD_DATA, [@(YES) stringValue]);
    XCTAssertFalse( callFailed, @"preload data request with valid publisher id should have succeeded" );
    XCTAssertTrue( callSuccess, @"preload data request with valid publisher id should have succeeded" );
}

- (void)testPreloadDataParams {
    TunePreloadData *pd = [TunePreloadData preloadDataWithPublisherId:@"112233"];
    pd.offerId = @"offer_id";
    pd.agencyId = @"agency_id";
    pd.publisherReferenceId = @"publisher_ref_id";
    pd.publisherSub1 = @"pub_sub1";
    pd.publisherSub2 = @"pub_sub2";
    pd.publisherSub3 = @"pub_sub3";
    pd.publisherSub4 = @"pub_sub4";
    pd.publisherSub5 = @"pub_sub5";
    pd.publisherSubAd = @"pub_sub_ad";
    pd.publisherSubAdgroup = @"pub_sub_adgroup";
    pd.publisherSubCampaign = @"pub_sub_campaign";
    pd.publisherSubKeyword = @"pub_sub_keyword";
    pd.publisherSubPublisher = @"pub_sub_publisher";
    pd.publisherSubSite = @"pub_sub_site";
    pd.advertiserSubAd = @"ad_sub_ad";
    pd.advertiserSubAdgroup = @"ad_sub_adgroup";
    pd.advertiserSubCampaign = @"ad_sub_campaign";
    pd.advertiserSubKeyword = @"ad_sub_keyword";
    pd.advertiserSubPublisher = @"ad_sub_publisher";
    pd.advertiserSubSite = @"ad_sub_site";
    
    [Tune setPreloadData:pd];
    [Tune measureEventName:@"event1"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_PRELOAD_DATA, [@(YES) stringValue]);
    XCTAssertFalse( callFailed, @"preload data request with valid publisher id should have succeeded" );
    XCTAssertTrue( callSuccess, @"preload data request with valid publisher id should have succeeded" );
    
    ASSERT_KEY_VALUE( TUNE_KEY_PUBLISHER_ID, @"112233" );
    ASSERT_KEY_VALUE( TUNE_KEY_OFFER_ID, @"offer_id" );
    ASSERT_KEY_VALUE( TUNE_KEY_AGENCY_ID, @"agency_id" );
    ASSERT_KEY_VALUE( TUNE_KEY_PUBLISHER_REF_ID, @"publisher_ref_id" );
    ASSERT_KEY_VALUE( TUNE_KEY_PUBLISHER_SUB1, @"pub_sub1" );
    ASSERT_KEY_VALUE( TUNE_KEY_PUBLISHER_SUB2, @"pub_sub2" );
    ASSERT_KEY_VALUE( TUNE_KEY_PUBLISHER_SUB3, @"pub_sub3" );
    ASSERT_KEY_VALUE( TUNE_KEY_PUBLISHER_SUB4, @"pub_sub4" );
    ASSERT_KEY_VALUE( TUNE_KEY_PUBLISHER_SUB5, @"pub_sub5" );
    ASSERT_KEY_VALUE( TUNE_KEY_PUBLISHER_SUB_AD, @"pub_sub_ad" );
    ASSERT_KEY_VALUE( TUNE_KEY_PUBLISHER_SUB_ADGROUP, @"pub_sub_adgroup" );
    ASSERT_KEY_VALUE( TUNE_KEY_PUBLISHER_SUB_CAMPAIGN, @"pub_sub_campaign" );
    ASSERT_KEY_VALUE( TUNE_KEY_PUBLISHER_SUB_KEYWORD, @"pub_sub_keyword" );
    ASSERT_KEY_VALUE( TUNE_KEY_PUBLISHER_SUB_PUBLISHER, @"pub_sub_publisher" );
    ASSERT_KEY_VALUE( TUNE_KEY_PUBLISHER_SUB_SITE, @"pub_sub_site" );
    ASSERT_KEY_VALUE( TUNE_KEY_ADVERTISER_SUB_AD, @"ad_sub_ad" );
    ASSERT_KEY_VALUE( TUNE_KEY_ADVERTISER_SUB_ADGROUP, @"ad_sub_adgroup" );
    ASSERT_KEY_VALUE( TUNE_KEY_ADVERTISER_SUB_CAMPAIGN, @"ad_sub_campaign" );
    ASSERT_KEY_VALUE( TUNE_KEY_ADVERTISER_SUB_KEYWORD, @"ad_sub_keyword" );
    ASSERT_KEY_VALUE( TUNE_KEY_ADVERTISER_SUB_PUBLISHER, @"ad_sub_publisher" );
    ASSERT_KEY_VALUE( TUNE_KEY_ADVERTISER_SUB_SITE, @"ad_sub_site" );
}


#pragma mark - Tune delegate

- (void)tuneDidSucceedWithData:(NSData *)data
{
    //NSLog( @"TunePreloadDataTests: test received success with %@\n", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] );
    callSuccess = YES;
    callFailed = NO;
}

- (void)tuneDidFailWithError:(NSError *)error
{
    //NSLog( @"TunePreloadDataTests: test received failure with %@\n", error );
    callFailed = YES;
    callSuccess = NO;
}


#pragma mark - Tune delegate

// secret functions to test server URLs
- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
