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
#import "TuneEvent+Internal.h"
#import "TuneIadUtils.h"
#import "TuneLog.h"
#import "TuneKeyStrings.h"
#import "TuneSkyhookCenter+Testing.h"
#import "TuneTestParams.h"
#import "TuneTestsHelper.h"
#import "TuneTracker.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"
#import "TuneManager.h"

#import <OCMock/OCMock.h>

#if TARGET_OS_IOS
#import <iAd/iAd.h>
#endif

@interface TuneIadAttributionTests : TuneXCTestCase <TuneDelegate> {
    TuneTestParams *params;
    
    id classMockTuneIadUtils;
    id classMockUIApplication;
    id classMockADClient;
    id classMockTuneUtils;
    id classMockTuneUserDefaultUtils;

    id classADClient;
    
    id mockTuneTracker;
    
    NSString *enqueuedRequestPostData;
    
    NSString *webRequestPostData;
    
    XCTestExpectation *expectationInstall;
    
    NSDictionary *attributionDetailsIAdTrue;
    NSDictionary *attributionDetailsIadFalse;
}

@end

@interface TuneTracker (Testing)

- (void)checkIadAttribution:(void (^)(BOOL iadAttributed, BOOL adTrackingEnabled, NSDate *impressionDate, NSDictionary *attributionInfo))attributionBlock;
- (void)checkIadAttributionAfterDelay:(NSTimeInterval)delay;
- (void)handleIadAttributionInfo:(BOOL)iadAttributed adTrackingEnabled:(BOOL)adTrackingEnabled impressionDate:(NSDate *)impressionDate attributionInfo:(NSDictionary *)attributionInfo;
- (void)measureInstallPostConversion;

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
    
    classMockTuneUtils = OCMClassMock([TuneUtils class]);
    
    classMockTuneUserDefaultUtils = OCMClassMock([TuneUserDefaultsUtils class]);
    
    mockTuneTracker = OCMPartialMock([TuneTracker sharedInstance]);
    
    params = [TuneTestParams new];
    
    enqueuedRequestPostData = nil;
    
    webRequestPostData = nil;
    
    attributionDetailsIAdTrue = @{@"Version3.1":@{
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
    
    attributionDetailsIadFalse = @{@"Version3.1":@{@"iad-attribution":@"false"}};
}

- (void)setupCommon {
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        if ([message containsString:@"EVENT QUEUE"]) {
            enqueuedRequestPostData = message;
        }
    };
    
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId];
    [Tune setDelegate:self];
    [Tune setExistingUser:NO];
    // Wait for everything to be set
    waitForQueuesToFinish();
}

- (void)setupCommonAndMockADClientRequestAttrib:(BOOL)shouldMockMethod shouldDelayIadResponse:(BOOL)shouldDelay {
    if (shouldMockMethod) {
        NSError *error = nil;
        
        OCMStub([classMockADClient requestAttributionDetailsWithBlock:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
            void (^passedBlock)( NSDictionary *dictAttr, NSError *objError );
            [invocation getArgument:&passedBlock atIndex:2];
            if (shouldDelay) {
                waitFor(1.5);
            }
            passedBlock(attributionDetailsIAdTrue, error);
        });
    }
    
    [self setupCommon];
}

- (void)tearDown {
    emptyRequestQueue();
    
    [classMockTuneIadUtils stopMocking];
    [classMockUIApplication stopMocking];
    [classMockADClient stopMocking];
    [classMockTuneUtils stopMocking];
    [classMockTuneUserDefaultUtils stopMocking];
    [mockTuneTracker stopMocking];
    
    TuneLog.shared.verbose = NO;
    TuneLog.shared.logBlock = nil;
    
    [super tearDown];
}

#if !TARGET_OS_TV && !TARGET_OS_WATCH

- (void)testCheckIadAttributioniOS9 {
    [self setupCommonAndMockADClientRequestAttrib:YES shouldDelayIadResponse:NO];
    
    if([classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        [[[mockTuneTracker expect] andForwardToRealObject] checkIadAttributionAfterDelay:0];
        [[mockTuneTracker reject] measureInstallPostConversion];
        [[[mockTuneTracker expect] andForwardToRealObject] handleIadAttributionInfo:YES adTrackingEnabled:YES impressionDate:OCMOCK_ANY attributionInfo:OCMOCK_ANY];
        
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( @"action", @"session" );
        ASSERT_NO_VALUE_FOR_KEY( @"iad_attribution" );
        
        XCTAssertNotNil(enqueuedRequestPostData);
        XCTAssert([enqueuedRequestPostData containsString:@"Version3.1"]);
        XCTAssert([enqueuedRequestPostData containsString:@"TUNE, Inc."]);

        [mockTuneTracker verify];
    }
}

- (void)testCheckIadAttributioniOS8 {
    [self setupCommon];
    
    if([classADClient instancesRespondToSelector:@selector(lookupAdConversionDetails:)]) {
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
        
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( @"action", @"session" );
        ASSERT_KEY_VALUE( @"iad_attribution", [@true stringValue]);
        ASSERT_KEY_VALUE( @"impression_datetime", [@([impressionDate timeIntervalSince1970]) stringValue]);
    }
}

- (void)testCheckIadAttributioniOS7 {
    [self setupCommon];
    
    if([classADClient instancesRespondToSelector:@selector(determineAppInstallationAttributionWithCompletionHandler:)]) {
        OCMStub(ClassMethod([classMockTuneUtils object:classMockADClient respondsToSelector:@selector(requestAttributionDetailsWithBlock:)])).andReturn(NO);
        OCMStub(ClassMethod([classMockTuneUtils object:classMockADClient respondsToSelector:@selector(lookupAdConversionDetails:)])).andReturn(NO);
        OCMStub(ClassMethod([classMockTuneUtils objectOrNull:[OCMArg any]])).andForwardToRealObject();
        
        BOOL attributed = YES;
        
        OCMStub([classMockADClient determineAppInstallationAttributionWithCompletionHandler:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
            void (^passedBlock)( BOOL appInstallationWasAttributedToiAd );
            [invocation getArgument:&passedBlock atIndex:2];
            passedBlock( attributed );
        });
        
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( @"action", @"session" );
        ASSERT_KEY_VALUE( @"iad_attribution", [@true stringValue]);
    }
}

- (void)testIadAttributionTrue_installPostConversion {
    [self setupCommonAndMockADClientRequestAttrib:YES shouldDelayIadResponse:YES];
    
    if([classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        expectationInstall = [self expectationWithDescription:@"InstallPostConversionEnqueued"];
        
        [[[mockTuneTracker expect] andForwardToRealObject] checkIadAttributionAfterDelay:0];
        [[[mockTuneTracker expect] andForwardToRealObject] measureInstallPostConversion];
        [[[mockTuneTracker expect] andForwardToRealObject] handleIadAttributionInfo:YES adTrackingEnabled:YES impressionDate:OCMOCK_ANY attributionInfo:OCMOCK_ANY];
        
        [Tune measureSession];
        waitForQueuesToFinish();
        
        [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable errorExp) {
            if (errorExp) {
                NSLog(@"XCTestExpectation error = %@", errorExp);
            }
            XCTAssertNil(errorExp);
            
            ASSERT_KEY_VALUE(@"action", @"install");
            
            XCTAssertNotNil(enqueuedRequestPostData);
            XCTAssert([enqueuedRequestPostData containsString:@"Version3.1"]);
            XCTAssert([enqueuedRequestPostData containsString:@"TUNE, Inc."]);
        }];
        
        [mockTuneTracker verify];
    }
}

- (void)testIadAttributionFalse_requestRetried {
    [self setupCommon];
    
    if([classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        NSError *error = nil;
        
        __block XCTestExpectation *expectation1 = [self expectationWithDescription:@"method to check iAd attribution after delay called"];
        
        // Return "iad-attribution" "false" response when TuneTracker.checkIadAttribution: method is called
        OCMStub([classMockADClient requestAttributionDetailsWithBlock:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
            void (^passedBlock)( NSDictionary *dictAttr, NSError *objError );
            [invocation getArgument:&passedBlock atIndex:2];
            passedBlock(attributionDetailsIadFalse, error);
        });
        
        [[mockTuneTracker reject] measureInstallPostConversion];
        [[[mockTuneTracker expect] andDo:^(NSInvocation *invocation) {
            [expectation1 fulfill];
        }] checkIadAttributionAfterDelay:5.];
        
        [[[[classMockTuneUtils stub] classMethod] andReturn:[NSDate dateWithTimeIntervalSinceNow:-20.]] installDate];
        
        // Call measureSession
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( @"action", @"session" );
        
        [self customWaitForExpectations];
        
        [mockTuneTracker verify];
    }
}

- (void)testIadAttributionFalse_maxAttempts {
    [self setupCommon];
    
    if([classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        NSError *error = nil;
        
        __block XCTestExpectation *expectation1 = [self expectationWithDescription:@"install post_conversion event fired"];
        
        // Return "iad-attribution" "false" response when TuneTracker.checkIadAttribution: method is called
        OCMStub([classMockADClient requestAttributionDetailsWithBlock:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
            void (^passedBlock)( NSDictionary *dictAttr, NSError *objError );
            [invocation getArgument:&passedBlock atIndex:2];
            passedBlock(attributionDetailsIadFalse, error);
        });
        
        [[mockTuneTracker reject] checkIadAttributionAfterDelay:5.];
        [[[mockTuneTracker expect] andDo:^(NSInvocation *invocation) {
            XCTAssertEqual(11, [[TuneUserDefaultsUtils userDefaultValueforKey:@"iad_request_attempt"] intValue]);
            [expectation1 fulfill];
        }] measureInstallPostConversion];
        
        [[[mockTuneTracker expect] andForwardToRealObject] handleIadAttributionInfo:NO adTrackingEnabled:YES impressionDate:OCMOCK_ANY attributionInfo:OCMOCK_ANY];
        
        [[[[classMockTuneUtils stub] classMethod] andReturn:[NSDate dateWithTimeIntervalSinceNow:-120]] installDate];
        
        [TuneUserDefaultsUtils setUserDefaultValue:@(10) forKey:@"iad_request_attempt"];
        
        // Call measureSession
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( @"action", @"session" );
        
        [self customWaitForExpectations];
        
        [mockTuneTracker verify];
    }
}

- (void)testIadAttributionFalse_lessThanMaxAttempts_maxTimeInterval {
    [self setupCommon];
    
    if([classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        NSError *error = nil;
        
        __block XCTestExpectation *expectation1 = [self expectationWithDescription:@"install post_conversion event fired"];
        
        // Return "iad-attribution" "false" response when TuneTracker.checkIadAttribution: method is called
        OCMStub([classMockADClient requestAttributionDetailsWithBlock:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
            void (^passedBlock)( NSDictionary *dictAttr, NSError *objError );
            [invocation getArgument:&passedBlock atIndex:2];
            passedBlock(attributionDetailsIadFalse, error);
        });
        
        [[mockTuneTracker reject] checkIadAttributionAfterDelay:60.];
        [[[mockTuneTracker expect] andDo:^(NSInvocation *invocation) {
            XCTAssertEqual(2, [[TuneUserDefaultsUtils userDefaultValueforKey:@"iad_request_attempt"] intValue]);
            [expectation1 fulfill];
        }] measureInstallPostConversion];
        
        [[[mockTuneTracker expect] andForwardToRealObject] handleIadAttributionInfo:NO adTrackingEnabled:YES impressionDate:OCMOCK_ANY attributionInfo:OCMOCK_ANY];
        
        [[[[classMockTuneUtils stub] classMethod] andReturn:[NSDate dateWithTimeIntervalSinceNow:-400]] installDate];
        
        [TuneUserDefaultsUtils setUserDefaultValue:@(1) forKey:@"iad_request_attempt"];
        
        // Call measureSession
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( @"action", @"session" );
        
        [self customWaitForExpectations];
        
        [mockTuneTracker verify];
    }
}

- (void)testNoIadCheckAndEventUpdateForNonSessionEvent {
    [self setupCommonAndMockADClientRequestAttrib:YES shouldDelayIadResponse:NO];
    
    if([classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        [Tune measureEventName:@"event1"];
        waitForQueuesToFinish();
        
        ASSERT_KEY_VALUE( @"action", @"conversion" );
        ASSERT_KEY_VALUE( @"site_event_name", @"event1" );
        ASSERT_NO_VALUE_FOR_KEY( @"iad_attribution" );
        XCTAssertNotNil(enqueuedRequestPostData);
        
        XCTAssert(![enqueuedRequestPostData containsString:@"iad\":{\"Version"]);
        
        enqueuedRequestPostData = nil;
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertNotNil(enqueuedRequestPostData);
        XCTAssert([enqueuedRequestPostData containsString:@"iad\":{\"Version"]);
    }
}

- (void)testIadAttributionFalseThenTrueAfterDelay_requestRetried {
    [self setupCommon];
    
    if([classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        __block int checkIadWithDelayIteration = -1;
        
        [[[[classMockTuneUtils stub] classMethod] andReturn:[NSDate dateWithTimeIntervalSinceNow:-20.]] installDate];
        
        __block XCTestExpectation *expectation1 = [self expectationWithDescription:@"install post_conversion event fired"];
        
        [[[mockTuneTracker stub] andDo:^(NSInvocation *invocation) {
            XCTAssertEqualObjects(@(3), [TuneUserDefaultsUtils userDefaultValueforKey:@"iad_request_attempt"]);
            [expectation1 fulfill];
        }] measureInstallPostConversion];
        
        // call checkIadAttributionAfterDelay: with delay 0
        [[[[mockTuneTracker stub] ignoringNonObjectArgs] andDo:^(NSInvocation *invocation) {
            // extract first argument "delay" from invocation
            NSTimeInterval delay;
            [invocation getArgument:&delay atIndex:2];
            ++checkIadWithDelayIteration;
            
            if (0 == checkIadWithDelayIteration) {
                XCTAssertEqual(delay, 0.);
                waitFor(0.8);
                [mockTuneTracker handleIadAttributionInfo:NO adTrackingEnabled:YES impressionDate:nil attributionInfo:attributionDetailsIadFalse];
            } else if (1 == checkIadWithDelayIteration) {
                XCTAssertEqual(delay, 5.);
                waitFor(0.2);
                [mockTuneTracker handleIadAttributionInfo:NO adTrackingEnabled:YES impressionDate:nil attributionInfo:attributionDetailsIadFalse];
            } else if (2 == checkIadWithDelayIteration) {
                XCTAssertEqual(delay, 5.);
                waitFor(0.2);
                [mockTuneTracker handleIadAttributionInfo:YES adTrackingEnabled:YES impressionDate:[NSDate dateWithTimeIntervalSinceNow:-600] attributionInfo:attributionDetailsIAdTrue];
            } else {
                XCTFail(@"unexpected call to TuneTracker.checkIadAttributionAfterDelay: method");
            }
        }] checkIadAttributionAfterDelay:-1];
        
        [Tune measureSession];
        waitForQueuesToFinish();
        
        [self customWaitForExpectations];
    }
}

- (void)testIadAttributionIsRetriedAtCorrectIntervals {
    [self setupCommon];
    
    if([classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        // First Search Ads request goes out 12s after initial install
        [[[[classMockTuneUtils stub] classMethod] andReturn:[NSDate dateWithTimeIntervalSinceNow:-12.0]] installDate];
        
        __block XCTestExpectation *expectation1 = [self expectationWithDescription:@"install post_conversion event fired"];
        
        // Max of 10 requests will be retried if Search Ads starts at 12s (would be 11 requests if it started at 2s)
        [[[mockTuneTracker stub] andDo:^(NSInvocation *invocation) {
            XCTAssertEqualObjects(@(10), [TuneUserDefaultsUtils userDefaultValueforKey:@"iad_request_attempt"]);
            [expectation1 fulfill];
        }] measureInstallPostConversion];
        
        __block NSDate *lastRequest = [NSDate date];
        
        // call checkIadAttributionAfterDelay: with delay 0
        [[[[mockTuneTracker stub] ignoringNonObjectArgs] andDo:^(NSInvocation *invocation) {
            // extract first argument "delay" from invocation
            NSTimeInterval delay;
            [invocation getArgument:&delay atIndex:2];
            
            // Mock TuneUserDefaultUtils' iAd request timestamp value to be current time + all delays so far
            lastRequest = [lastRequest dateByAddingTimeInterval:delay];
            OCMStub(ClassMethod([classMockTuneUserDefaultUtils userDefaultValueforKey:TUNE_KEY_IAD_REQUEST_TIMESTAMP])).andDo(^(NSInvocation *invoke) {
                [invoke setReturnValue:&lastRequest];
            });
            
            NSTimeInterval lastRequestTimeDiffSinceAppInstall = [[TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_IAD_REQUEST_TIMESTAMP] timeIntervalSinceDate:[TuneUtils installDate]];
            
            if (lastRequestTimeDiffSinceAppInstall > 300) {
                // Over 300s since initial install, which is our max, stop retrying
                XCTAssertEqual(delay, 60.);
                waitFor(0.2);
                [mockTuneTracker handleIadAttributionInfo:YES adTrackingEnabled:YES impressionDate:[NSDate dateWithTimeIntervalSinceNow:-600] attributionInfo:attributionDetailsIAdTrue];
            } else if (lastRequestTimeDiffSinceAppInstall < 13) {
                // Initial request at ~12s shouldn't have any delay on it
                XCTAssertEqual(delay, 0);
                waitFor(0.2);
                [mockTuneTracker handleIadAttributionInfo:NO adTrackingEnabled:YES impressionDate:nil attributionInfo:attributionDetailsIadFalse];
            } else if (lastRequestTimeDiffSinceAppInstall < 33) {
                // 5s delay between requests until 30s has passed
                XCTAssertEqual(delay, 5.);
                waitFor(0.2);
                [mockTuneTracker handleIadAttributionInfo:NO adTrackingEnabled:YES impressionDate:nil attributionInfo:attributionDetailsIadFalse];
            } else if (lastRequestTimeDiffSinceAppInstall < 63) {
                // 30s delay between requests that occur between 30s and 60s elapsed time
                XCTAssertEqual(delay, 30.);
                waitFor(0.2);
                [mockTuneTracker handleIadAttributionInfo:NO adTrackingEnabled:YES impressionDate:nil attributionInfo:attributionDetailsIadFalse];
            } else {
                // 60s delay between requests beyond 60s
                XCTAssertEqual(delay, 60.);
                waitFor(0.2);
                [mockTuneTracker handleIadAttributionInfo:NO adTrackingEnabled:YES impressionDate:nil attributionInfo:attributionDetailsIadFalse];
            }
        }] checkIadAttributionAfterDelay:-1];
        
        [Tune measureSession];
        waitForQueuesToFinish();
        
        [self customWaitForExpectations];
    }
}

// This test causes unit tests to fail compilation on iOS 8.  It must be commented out.
- (void)testIadAttribution_LimitAdTracking {
    [self setupCommon];
    
    if([classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        NSError *error = [NSError errorWithDomain:ADClientErrorDomain code:ADClientErrorLimitAdTracking userInfo:nil];
        
        __block XCTestExpectation *expectation1 = [self expectationWithDescription:@"ADClient handleIadAttributionInfo: called"];
        
        // Return "iad-attribution" "false" response when TuneTracker.checkIadAttribution: method is called
        OCMStub([classMockADClient requestAttributionDetailsWithBlock:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
            void (^passedBlock)( NSDictionary *dictAttr, NSError *objError );
            [invocation getArgument:&passedBlock atIndex:2];
            passedBlock(nil, error);
        });
        
        [[[mockTuneTracker expect] andForwardToRealObject] checkIadAttributionAfterDelay:0.];
        
        [[[[mockTuneTracker stub] andDo:^(NSInvocation *invocation) {
            BOOL isAttributed;
            BOOL isAdTrackingEnabled;
            [invocation getArgument:&isAttributed atIndex:2];
            [invocation getArgument:&isAdTrackingEnabled atIndex:3];
            XCTAssertFalse(isAttributed);
            XCTAssertFalse(isAdTrackingEnabled);
            [expectation1 fulfill];
        }] andForwardToRealObject] handleIadAttributionInfo:NO adTrackingEnabled:NO impressionDate:OCMOCK_ANY attributionInfo:OCMOCK_ANY];
        
        [[mockTuneTracker reject] checkIadAttributionAfterDelay:60.];
        [[mockTuneTracker reject] measureInstallPostConversion];
        
        [[[[classMockTuneUtils stub] classMethod] andReturn:[NSDate dateWithTimeIntervalSinceNow:-20.]] installDate];
        
        // Call measureSession
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( @"action", @"session" );
        
        [self customWaitForExpectations];
        
        [mockTuneTracker verify];
    }
}

#endif

#pragma makr - Helper Method

- (void)customWaitForExpectations {
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable errorExp) {
        if (errorExp) {
            NSLog(@"XCTestExpectation error = %@", errorExp);
        }
        XCTAssertNil(errorExp);
    }];
}

#pragma mark - Internal Tune delegate

// secret functions to test server URLs
- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData {
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    
    if( postData ) {
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
        webRequestPostData = postData;
    }
    
    if (expectationInstall && [params.params[@"action"] isEqualToString:@"install"]) {
        [expectationInstall fulfill];
    }
}

@end
