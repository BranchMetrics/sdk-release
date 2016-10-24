//
//  TuneIadAttributionTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 9/30/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneXCTestCase.h"
#import "Tune+Testing.h"
#import "TuneAnalyticsManager+Testing.h"
#import "TuneDeviceDetails.h"
#import "TuneEvent+Internal.h"
#import "TuneIadUtils.h"
#import "TuneJSONUtils.h"
#import "TuneKeyStrings.h"
#import "TuneSkyhookCenter+Testing.h"
#import "TuneTestParams.h"
#import "TuneTestsHelper.h"
#import "TuneTracker.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"
#import "TuneManager.h"

#import <OCMock/OCMock.h>

#if !TARGET_OS_TV && !TARGET_OS_WATCH
#import <iAd/iAd.h>
#endif

@interface TuneIadAttributionTests : TuneXCTestCase <TuneDelegate> {
    TuneTestParams *params;
    
    id classMockTuneIadUtils;
    id classMockUIApplication;
    id classMockADClient;
    
    id classADClient;
    
    NSString *enqueuedRequestPostData;
    
    NSString *webRequestPostData;
}

@end

@implementation TuneIadAttributionTests

- (void)setUp {
    [super setUp];
    
    classADClient = NSClassFromString(@"ADClient");
    
    BOOL success = nil != classADClient;
    
    if (success) {
        classMockADClient = OCMClassMock(classADClient);
        OCMStub(ClassMethod([classMockADClient sharedClient])).andReturn(classMockADClient);
    } else {
        XCTFail("ADClient class not available");
    }
    
    classMockUIApplication = OCMClassMock([UIApplication class]);
    OCMStub(ClassMethod([classMockUIApplication sharedApplication])).andReturn(classMockUIApplication);
    
    classMockTuneIadUtils = OCMClassMock([TuneIadUtils class]);
    OCMStub([classMockTuneIadUtils shouldCheckIadAttribution]).andReturn(YES);
    
    params = [TuneTestParams new];
    
    enqueuedRequestPostData = nil;
    
    webRequestPostData = nil;
}

- (void)setupCommon {
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId wearable:NO];
    [Tune setDelegate:self];
    [Tune setExistingUser:NO];
    // Wait for everything to be set
    waitForQueuesToFinish();
}

- (void)setupCommonAndMockADClientRequestAttrib:(BOOL)shouldMockMethod shouldDelayIadResponse:(BOOL)shouldDelay {
    if (shouldMockMethod) {
        // actual response from production test app
        NSDictionary *attributionDetails = @{@"Version3.1":@{
                                                     @"iad-attribution":@"true",
                                                     @"iad-campaign-id":@"15222869",
                                                     @"iad-campaign-name":@"atomic new 13",
                                                     @"iad-click-date":@"2016-03-23T07:55:00Z",
                                                     @"iad-conversion-date":@"2016-03-23T07:55:50Z",
                                                     @"iad-creative-id":@"226713",
                                                     @"iad-creative-name":@"ad new",
                                                     @"iad-lineitem-id":@"15325601",
                                                     @"iad-lineitem-name":@"2000 banner",
                                                     @"iad-org-name":@"TUNE, Inc.",
                                                     @"iad-keyword":@"dodgeball"}
                                             };
        
        NSError *error = nil;
        
        OCMStub([classMockADClient requestAttributionDetailsWithBlock:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
            void (^passedBlock)( NSDictionary *dictAttr, NSError *objError );
            [invocation getArgument:&passedBlock atIndex:2];
            if (shouldDelay) {
                waitFor(1.5);
            }
            passedBlock(attributionDetails, error);
        });
    }
    
    [self setupCommon];
}

- (void)tearDown {
    emptyRequestQueue();
    
    [classMockTuneIadUtils stopMocking];
    [classMockUIApplication stopMocking];
    [classMockADClient stopMocking];
    
    [super tearDown];
}

#pragma mark - TuneDelegate Methods

-(void)tuneDidSucceedWithData:(NSData *)data {
}

- (void)tuneDidFailWithError:(NSError *)error {
}

- (void)tuneEnqueuedRequest:(NSString *)url postData:(NSString *)post {
    enqueuedRequestPostData = post;
}

#pragma mark -

#if !TARGET_OS_TV && !TARGET_OS_WATCH

- (void)testCheckIadAttributioniOS9 {
    [self setupCommonAndMockADClientRequestAttrib:YES shouldDelayIadResponse:NO];
    
    if([classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_ATTRIBUTION, [@true stringValue]);
        
        XCTAssertNotNil(enqueuedRequestPostData);
        NSDictionary *dict = nil;
        if(enqueuedRequestPostData) {
            NSError *jsonError;
            dict = [NSJSONSerialization JSONObjectWithData:[enqueuedRequestPostData dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];
        }
        
        XCTAssertNotNil(dict);
        XCTAssertNotNil(dict[@"iad"]);
        XCTAssertNotNil(dict[@"iad"][@"Version3.1"]);
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-attribution"], @"true");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-campaign-id"], @"15222869");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-campaign-name"], @"atomic new 13");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-creative-id"], @"226713");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-creative-name"], @"ad new");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-lineitem-id"], @"15325601");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-lineitem-name"], @"2000 banner");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-org-name"], @"TUNE, Inc.");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-keyword"], @"dodgeball");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-click-date"], @"2016-03-23T07:55:00Z");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-conversion-date"], @"2016-03-23T07:55:50Z");
        
        [classMockADClient stopMocking];
    }
}

- (void)testIgnoreFakeIadAttributioniOS9 {
    [self setupCommon];
    
    if([classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        // actual response from production test app
        NSDictionary *attributionDetails = @{@"Version3.1":@{
                                                     @"iad-adgroup-name":@"AdGroupName",
                                                     @"iad-adgroup-id":@"1234567890",
                                                     @"iad-attribution":@"true",
                                                     @"iad-campaign-id":@"1234567890",
                                                     @"iad-campaign-name":@"CampaignName",
                                                     @"iad-click-date":@"2016-08-09T22:13:23Z",
                                                     @"iad-conversion-date":@"2016-08-09T22:13:23Z",
                                                     @"iad-creative-id":@"1234567890",
                                                     @"iad-creative-name":@"CreativeName",
                                                     @"iad-keyword":@"Keyword",
                                                     @"iad-lineitem-id":@"1234567890",
                                                     @"iad-lineitem-name":@"LineName",
                                                     @"iad-org-name":@"OrgName"}
                                             };
        
        NSError *error = nil;
        
        OCMStub([classMockADClient requestAttributionDetailsWithBlock:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
            void (^passedBlock)( NSDictionary *dictAttr, NSError *objError );
            [invocation getArgument:&passedBlock atIndex:2];
            passedBlock(attributionDetails, error);
        });
        
        [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId wearable:NO];
        [Tune setDelegate:self];
        [Tune setExistingUser:NO];
        // Wait for everything to be set
        waitForQueuesToFinish();
        
        [Tune measureSession];
        waitForQueuesToFinish();
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( TUNE_KEY_ACTION, @"session" );
        
        [Tune measureEventName:@"event1"];
        waitForQueuesToFinish();
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( TUNE_KEY_ACTION, @"conversion" );
        
        if(webRequestPostData) {
            NSError *jsonError;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[webRequestPostData dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];
            XCTAssertNil(dict[@"iad"]);
        }
        
        ASSERT_KEY_VALUE(TUNE_KEY_IAD_ATTRIBUTION, [@NO stringValue] );
        ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_PUBLISHER_SUB_CAMPAIGN_REF );
        ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_PUBLISHER_SUB_CAMPAIGN_NAME );
        ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_PUBLISHER_SUB_PLACEMENT_REF );
        ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_PUBLISHER_SUB_PLACEMENT_NAME );
        ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_PUBLISHER_SUB_AD_REF );
        ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_PUBLISHER_SUB_AD_NAME );
        ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_PUBLISHER_SUB_PUBLISHER_REF );
        ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_PUBLISHER_SUB_KEYWORD_REF );
        
        [classMockADClient stopMocking];
    }
}

- (void)testCheckIadAttributioniOS8 {
    [self setupCommon];
    
    if([classADClient instancesRespondToSelector:@selector(lookupAdConversionDetails:)]) {
        id classMockTuneUtils = OCMClassMock([TuneUtils class]);
        OCMStub(ClassMethod([classMockTuneUtils object:classMockADClient respondsToSelector:@selector(requestAttributionDetailsWithBlock:)])).andReturn(NO);
        OCMStub(ClassMethod([classMockTuneUtils objectOrNull:[OCMArg any]])).andForwardToRealObject();
        
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
        NSDate *purchaseDate = [formatter dateFromString:@"2016-03-23T07:45:50Z"];
        NSDate *impressionDate = [formatter dateFromString:@"2016-03-23T07:55:50Z"];
        
        OCMStub([classMockADClient lookupAdConversionDetails:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
            void (^passedBlock)( NSDate *dtAppPurchase, NSDate *dtIAdImpression );
            [invocation getArgument:&passedBlock atIndex:2];
            passedBlock(purchaseDate, impressionDate);
        });
        
        [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId wearable:NO];
        [Tune setDelegate:self];
        [Tune setExistingUser:NO];
        // Wait for everything to be set
        waitForQueuesToFinish();
        
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_ATTRIBUTION, [@true stringValue]);
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_IMPRESSION_DATE, [@([impressionDate timeIntervalSince1970]) stringValue]);
        
        [classMockADClient stopMocking];
        [classMockTuneUtils stopMocking];
    }
}

- (void)testCheckIadAttributioniOS7 {
    [self setupCommon];
    
    if([classADClient instancesRespondToSelector:@selector(determineAppInstallationAttributionWithCompletionHandler:)]) {
        id classMockTuneUtils = OCMClassMock([TuneUtils class]);
        OCMStub(ClassMethod([classMockTuneUtils object:classMockADClient respondsToSelector:@selector(requestAttributionDetailsWithBlock:)])).andReturn(NO);
        OCMStub(ClassMethod([classMockTuneUtils object:classMockADClient respondsToSelector:@selector(lookupAdConversionDetails:)])).andReturn(NO);
        OCMStub(ClassMethod([classMockTuneUtils objectOrNull:[OCMArg any]])).andForwardToRealObject();
        
        BOOL attributed = YES;
        
        OCMStub([classMockADClient determineAppInstallationAttributionWithCompletionHandler:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
            void (^passedBlock)( BOOL appInstallationWasAttributedToiAd );
            [invocation getArgument:&passedBlock atIndex:2];
            passedBlock( attributed );
        });
        
        [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId wearable:NO];
        [Tune setDelegate:self];
        [Tune setExistingUser:NO];
        // Wait for everything to be set
        waitForQueuesToFinish();
        
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_ATTRIBUTION, [@true stringValue]);
        
        [classMockADClient stopMocking];
        [classMockTuneUtils stopMocking];
    }
}

- (void)testMeasureSessionWithIadAttributionInfo {
    [self setupCommonAndMockADClientRequestAttrib:YES shouldDelayIadResponse:NO];
    
    if([classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        [Tune measureSession];
        waitForQueuesToFinish();
        
        ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_ATTRIBUTION, [@true stringValue]);
        
        XCTAssertNotNil(enqueuedRequestPostData);
        NSDictionary *dict = nil;
        if(enqueuedRequestPostData) {
            NSError *jsonError;
            dict = [NSJSONSerialization JSONObjectWithData:[enqueuedRequestPostData dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];
        }
        
        XCTAssertNotNil(dict);
        XCTAssertNotNil(dict[@"iad"]);
        XCTAssertNotNil(dict[@"iad"][@"Version3.1"]);
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-attribution"], @"true");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-campaign-id"], @"15222869");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-campaign-name"], @"atomic new 13");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-creative-id"], @"226713");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-creative-name"], @"ad new");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-lineitem-id"], @"15325601");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-lineitem-name"], @"2000 banner");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-org-name"], @"TUNE, Inc.");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-keyword"], @"dodgeball");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-click-date"], @"2016-03-23T07:55:00Z");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-conversion-date"], @"2016-03-23T07:55:50Z");
    }
}

- (void)testMeasureInstallPostConversionWithIadAttributionInfo {
    [self setupCommonAndMockADClientRequestAttrib:YES shouldDelayIadResponse:YES];
    
    if([classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        [Tune measureSession];
        waitForQueuesToFinish();
        
        ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_INSTALL );
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_ATTRIBUTION, [@true stringValue]);
        
        XCTAssertNotNil(enqueuedRequestPostData);
        NSDictionary *dict = nil;
        if(enqueuedRequestPostData) {
            NSError *jsonError;
            dict = [NSJSONSerialization JSONObjectWithData:[enqueuedRequestPostData dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];
        }
        
        XCTAssertNotNil(dict);
        XCTAssertNotNil(dict[@"iad"]);
        XCTAssertNotNil(dict[@"iad"][@"Version3.1"]);
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-attribution"], @"true");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-campaign-id"], @"15222869");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-campaign-name"], @"atomic new 13");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-creative-id"], @"226713");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-creative-name"], @"ad new");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-lineitem-id"], @"15325601");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-lineitem-name"], @"2000 banner");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-org-name"], @"TUNE, Inc.");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-keyword"], @"dodgeball");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-click-date"], @"2016-03-23T07:55:00Z");
        XCTAssertEqualObjects(dict[@"iad"][@"Version3.1"][@"iad-conversion-date"], @"2016-03-23T07:55:50Z");
    }
}

- (void)testNoIadCheckAndEventUpdateForNonSessionEvent {
    [self setupCommonAndMockADClientRequestAttrib:YES shouldDelayIadResponse:NO];
    
    if([classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        [Tune measureEventName:@"event1"];
        waitForQueuesToFinish();
        
        ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
        ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_IAD_ATTRIBUTION );
        XCTAssertNotNil(enqueuedRequestPostData);
        NSDictionary *dict = nil;
        if(enqueuedRequestPostData) {
            NSError *jsonError;
            dict = [NSJSONSerialization JSONObjectWithData:[enqueuedRequestPostData dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];
        }
        
        XCTAssertNil(dict[@"iad"]);
        
        enqueuedRequestPostData = nil;
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertNotNil(enqueuedRequestPostData);
        dict = nil;
        if(enqueuedRequestPostData) {
            NSError *jsonError;
            dict = [NSJSONSerialization JSONObjectWithData:[enqueuedRequestPostData dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&jsonError];
        }
        
        XCTAssertNotNil(dict[@"iad"]);
    }
}

#endif

#pragma mark - Internal Tune delegate

// secret functions to test server URLs
- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData {
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData ) {
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
        webRequestPostData = postData;
    }
}

@end
