//
//  MATPreloadDataTests.m
//  MobileAppTracker
//
//  Created by Harshal Ogale on 4/27/15.
//  Copyright (c) 2015 HasOffers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <AdSupport/AdSupport.h>
#import "MATTestsHelper.h"
#import "MATTestParams.h"
#import "../MobileAppTracker/MobileAppTracker.h"
#import "../MobileAppTracker/Common/MATKeyStrings.h"
#import "../MobileAppTracker/Common/MATSettings.h"
#import "../MobileAppTracker/Common/MATTracker.h"

@interface MobileAppTracker (MATPreloadDataTests)

+ (void)setPluginName:(NSString *)pluginName;

@end

@interface MATPreloadDataTests : XCTestCase <MobileAppTrackerDelegate>
{
    BOOL callSuccess;
    BOOL callFailed;
    
    MATTestParams *params;
}

@end


@implementation MATPreloadDataTests

- (void)setUp
{
    [super setUp];
    
    [MobileAppTracker initializeWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    [MobileAppTracker setDelegate:self];
    
    params = [MATTestParams new];
    
    emptyRequestQueue();
    
    networkOnline();
}

- (void)tearDown
{
    [MobileAppTracker setCurrencyCode:nil];
    [MobileAppTracker setPackageName:kTestBundleId];
    [MobileAppTracker setPluginName:nil];
    
    emptyRequestQueue();
    waitFor( 10. );
    
    [super tearDown];
}

#pragma mark - Event parameters

- (void)testInvalidPublisherId
{
    MATPreloadData *pd = [MATPreloadData preloadDataWithPublisherId:@"incorrect_publisher_id"];
    [MobileAppTracker setPreloadData:pd];
    [MobileAppTracker measureEventName:@"event1"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_PRELOAD_DATA, [@(YES) stringValue]);
    XCTAssertTrue( callFailed, @"preload data request with invalid publisher id should have failed" );
    XCTAssertFalse( callSuccess, @"preload data request with invalid publisher id should have failed" );
}

- (void)testValidPublisherId
{
    MATPreloadData *pd = [MATPreloadData preloadDataWithPublisherId:@"112233"];
    [MobileAppTracker setPreloadData:pd];
    [MobileAppTracker measureEventName:@"event2"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_PRELOAD_DATA, [@(YES) stringValue]);
    XCTAssertFalse( callFailed, @"preload data request with valid publisher id should have succeeded" );
    XCTAssertTrue( callSuccess, @"preload data request with valid publisher id should have succeeded" );
}

- (void)testPreloadDataParams
{
    MATPreloadData *pd = [MATPreloadData preloadDataWithPublisherId:@"112233"];
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
    
    [MobileAppTracker setPreloadData:pd];
    [MobileAppTracker measureEventName:@"event1"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_PRELOAD_DATA, [@(YES) stringValue]);
    XCTAssertFalse( callFailed, @"preload data request with valid publisher id should have succeeded" );
    XCTAssertTrue( callSuccess, @"preload data request with valid publisher id should have succeeded" );
    
    ASSERT_KEY_VALUE( MAT_KEY_PUBLISHER_ID, @"112233" );
    ASSERT_KEY_VALUE( MAT_KEY_OFFER_ID, @"offer_id" );
    ASSERT_KEY_VALUE( MAT_KEY_AGENCY_ID, @"agency_id" );
    ASSERT_KEY_VALUE( MAT_KEY_PUBLISHER_REF_ID, @"publisher_ref_id" );
    ASSERT_KEY_VALUE( MAT_KEY_PUBLISHER_SUB1, @"pub_sub1" );
    ASSERT_KEY_VALUE( MAT_KEY_PUBLISHER_SUB2, @"pub_sub2" );
    ASSERT_KEY_VALUE( MAT_KEY_PUBLISHER_SUB3, @"pub_sub3" );
    ASSERT_KEY_VALUE( MAT_KEY_PUBLISHER_SUB4, @"pub_sub4" );
    ASSERT_KEY_VALUE( MAT_KEY_PUBLISHER_SUB5, @"pub_sub5" );
    ASSERT_KEY_VALUE( MAT_KEY_PUBLISHER_SUB_AD, @"pub_sub_ad" );
    ASSERT_KEY_VALUE( MAT_KEY_PUBLISHER_SUB_ADGROUP, @"pub_sub_adgroup" );
    ASSERT_KEY_VALUE( MAT_KEY_PUBLISHER_SUB_CAMPAIGN, @"pub_sub_campaign" );
    ASSERT_KEY_VALUE( MAT_KEY_PUBLISHER_SUB_KEYWORD, @"pub_sub_keyword" );
    ASSERT_KEY_VALUE( MAT_KEY_PUBLISHER_SUB_PUBLISHER, @"pub_sub_publisher" );
    ASSERT_KEY_VALUE( MAT_KEY_PUBLISHER_SUB_SITE, @"pub_sub_site" );
    ASSERT_KEY_VALUE( MAT_KEY_ADVERTISER_SUB_AD, @"ad_sub_ad" );
    ASSERT_KEY_VALUE( MAT_KEY_ADVERTISER_SUB_ADGROUP, @"ad_sub_adgroup" );
    ASSERT_KEY_VALUE( MAT_KEY_ADVERTISER_SUB_CAMPAIGN, @"ad_sub_campaign" );
    ASSERT_KEY_VALUE( MAT_KEY_ADVERTISER_SUB_KEYWORD, @"ad_sub_keyword" );
    ASSERT_KEY_VALUE( MAT_KEY_ADVERTISER_SUB_PUBLISHER, @"ad_sub_publisher" );
    ASSERT_KEY_VALUE( MAT_KEY_ADVERTISER_SUB_SITE, @"ad_sub_site" );
}


#pragma mark - MobileAppTracker delegate

- (void)mobileAppTrackerDidSucceedWithData:(NSData *)data
{
    //NSLog( @"MATPreloadDataTests: test received success with %@\n", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] );
    callSuccess = YES;
    callFailed = NO;
}

- (void)mobileAppTrackerDidFailWithError:(NSError *)error
{
    //NSLog( @"MATPreloadDataTests: test received failure with %@\n", error );
    callFailed = YES;
    callSuccess = NO;
}


#pragma mark - MobileAppTracker delegate

// secret functions to test server URLs
- (void)_matSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
}

@end