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
#import "TuneEventQueue.h"
#import "TuneKeyStrings.h"
#import "TuneLog.h"
#import "TuneNetworkUtils.h"
#import "TunePreloadData.h"
#import "TuneTestParams.h"
#import "TuneTracker.h"
#import "TuneUserProfileKeys.h"
#import "TuneXCTestCase.h"

#import <OCMock/OCMock.h>

@interface TunePreloadDataTests : TuneXCTestCase <TuneDelegate> {
    TuneTestParams *params;
    id classMockTuneNetworkUtils;
}

@end


@implementation TunePreloadDataTests

- (void)setUp {
    [super setUp];

    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId];
    [[TuneEventQueue sharedQueue] setUnitTestCallback:^(NSString *trackingUrl, NSString *postData) {
        XCTAssertTrue([params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl);
        if (postData) {
            XCTAssertTrue([params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData);
        }
    }];
    
    params = [TuneTestParams new];
    emptyRequestQueue();
    
    __block BOOL forcedNetworkStatus = YES;
    classMockTuneNetworkUtils = OCMClassMock([TuneNetworkUtils class]);
    OCMStub(ClassMethod([classMockTuneNetworkUtils isNetworkReachable])).andDo(^(NSInvocation *invocation) {
        [invocation setReturnValue:&forcedNetworkStatus];
    });
}

- (void)tearDown {
    TuneLog.shared.verbose = NO;
    TuneLog.shared.logBlock = nil;
    
    [Tune setPluginName:nil];
    
    [classMockTuneNetworkUtils stopMocking];
    
    emptyRequestQueue();
    [[TuneEventQueue sharedQueue] setUnitTestCallback:nil];
    
    [super tearDown];
}

#pragma mark - Event parameters

- (void)testInvalidPublisherId {
    __block BOOL logCalled = NO;
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        logCalled = YES;
    };

    TunePreloadData *pd = [TunePreloadData preloadDataWithPublisherId:@"incorrect_publisher_id"];
    [Tune setPreloadedAppData:pd];
    [Tune measureEventName:@"event1"];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_PRELOAD_DATA, [@(YES) stringValue]);

    XCTAssert(logCalled);
}

- (void)testValidPublisherId {
    __block BOOL logCalled = NO;
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        logCalled = YES;
    };
    
    TunePreloadData *pd = [TunePreloadData preloadDataWithPublisherId:@"112233"];
    [Tune setPreloadedAppData:pd];
    [Tune measureEventName:@"event2"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_PRELOAD_DATA, [@(YES) stringValue]);

    XCTAssert(logCalled);
}

- (void)testPreloadDataParams {
    __block BOOL logCalled = NO;
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        logCalled = YES;
    };
    
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
    
    [Tune setPreloadedAppData:pd];
    [Tune measureEventName:@"event1"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_PRELOAD_DATA, [@(YES) stringValue]);

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
    
    XCTAssert(logCalled);
}

@end
