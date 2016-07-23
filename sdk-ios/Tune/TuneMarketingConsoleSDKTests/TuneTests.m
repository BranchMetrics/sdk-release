//
//  TuneTests.m
//  Tune Tests
//
//  Created by John Bender on 12/17/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Tune+Testing.h"
#import "TuneAnalyticsManager+Testing.h"
#import "TuneBlankAppDelegate.h"
#import "TuneDeviceDetails.h"
#import "TuneEvent+Internal.h"
#import "TuneJSONUtils.h"
#import "TuneKeyStrings.h"
#import "TuneSkyhookCenter+Testing.h"
#import "TuneTestParams.h"
#import "TuneTestsHelper.h"
#import "TuneTracker.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"
#import "TuneManager.h"
#import <CoreSpotlight/CoreSpotlight.h>

#if (TARGET_OS_IOS || TARGET_OS_IPHONE) && !TARGET_OS_TV
#import <iAd/iAd.h>
#endif
#import "TuneXCTestCase.h"

@interface TuneTests : TuneXCTestCase <TuneDelegate> {
    TuneTestParams *params;
    
    BOOL finished;
    BOOL failed;
    TuneErrorCode tuneErrorCode;
    TuneBlankAppDelegate *appDelegate;
    id mockApplication;
    
    BOOL enqueuedSession;
    BOOL enqueuedEvent;
}

@end


@implementation TuneTests

- (void)setUp {
    [super setUp];

    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId wearable:NO];
    [Tune setDelegate:self];
    [Tune setExistingUser:NO];
    // Wait for everything to be set
    waitForQueuesToFinish();
    
    mockApplication = OCMClassMock([UIApplication class]);
    OCMStub(ClassMethod([mockApplication sharedApplication])).andReturn(mockApplication);
    
    finished = NO;
    failed = NO;
    
    tuneErrorCode = -1;
    
    appDelegate = [[TuneBlankAppDelegate alloc] init];
    
    params = [TuneTestParams new];
    
    enqueuedSession = NO;
    enqueuedEvent = NO;
}

- (void)tearDown {
    emptyRequestQueue();
    
    [mockApplication stopMocking];
    
    finished = NO;
    
    [super tearDown];
}

- (void)testInitialization {
    XCTAssertTrue( TRUE );
}


#pragma mark - TuneDelegate Methods

-(void)tuneDidSucceedWithData:(NSData *)data {
    finished = YES;
    failed = NO;
}

- (void)tuneDidFailWithError:(NSError *)error {
    finished = YES;
    failed = YES;
    
    tuneErrorCode = error.code;
}

- (void)tuneEnqueuedRequest:(NSString *)url postData:(NSString *)post {
    enqueuedSession = [url containsString:@"&action=session"];
    enqueuedEvent = [url containsString:@"&action=conversion"];
}


#pragma mark - Install/update

- (void)testInstall {
    [Tune measureSession];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
}

- (void)testUpdate {
    [Tune setExistingUser:YES];
    [Tune measureSession];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
    ASSERT_KEY_VALUE( TUNE_KEY_EXISTING_USER, [@TRUE stringValue] );
}

- (void)testDuplicateOpenIgnored {
    [Tune measureSession];
    waitForQueuesToFinish();
    
    XCTAssertTrue(finished);
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
    
    finished = NO;
    
    [Tune measureSession];
    waitForQueuesToFinish();
    
    XCTAssertTrue(finished);
    XCTAssertTrue(failed);
    XCTAssertEqual(tuneErrorCode, TuneInvalidDuplicateSession, @"Duplicate session request should have been ignored.");
}

- (void)testAllowOpenAfterAppBackgroundForeground {
    [Tune measureSession];
    waitForQueuesToFinish();
    
    XCTAssertTrue(finished);
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidEnterBackgroundNotification object:nil];
    waitFor( 0.2 );
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationWillEnterForegroundNotification object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification object:nil];
    
    finished = NO;
    
    [Tune measureSession];
    waitForQueuesToFinish();
    
    XCTAssertTrue(finished);
    XCTAssertNotEqual(tuneErrorCode, TuneInvalidDuplicateSession, @"First session request fired after the app was re-opened should not have been ignored.");
}

- (void)testInstallPostConversion {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    id tune = [[Tune class] performSelector:@selector(sharedManager)];
    waitFor( 1. );
    [tune performSelector:@selector(measureInstallPostConversion)];
#pragma clang diagnostic pop
    
    waitForQueuesToFinish();
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_INSTALL );
    ASSERT_KEY_VALUE( TUNE_KEY_POST_CONVERSION, @"1" );
}

- (void)testUrlOpen {
    static NSString* const openUrl = @"myapp://something/something?some=stuff&something=else";
    static NSString* const sourceApplication = @"Mail";
    [Tune applicationDidOpenURL:openUrl sourceApplication:sourceApplication];
    
    [Tune measureSession];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
    ASSERT_KEY_VALUE( TUNE_KEY_REFERRAL_URL, openUrl );
    ASSERT_KEY_VALUE( TUNE_KEY_REFERRAL_SOURCE, sourceApplication );
}

#if (TARGET_OS_IOS || TARGET_OS_IPHONE) && !TARGET_OS_TV
- (void)testContinueUserActivityWeb {
    if([TuneDeviceDetails appIsRunningIniOS9OrAfter]) {
        static NSString *openUrl = @"http://www.mycompany.com/mypage1";
        static NSString *sourceApplication = @"web";
        
        NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
        activity.webpageURL = [NSURL URLWithString:openUrl];
        activity.userInfo = @{};
        
        [appDelegate application:(UIApplication *)mockApplication continueUserActivity:activity restorationHandler:^(NSArray * restorableObjects) {}];
        
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
        ASSERT_KEY_VALUE( TUNE_KEY_REFERRAL_URL, openUrl );
        ASSERT_KEY_VALUE( TUNE_KEY_REFERRAL_SOURCE, sourceApplication );
    }
}

- (void)testContinueUserActivitySpotlight {
    if([TuneDeviceDetails appIsRunningIniOS9OrAfter]) {
        NSString *openUrl = @"myapp://mypage2";
        NSString *sourceApplication = @"spotlight";
        NSDictionary *userInfo = @{CSSearchableItemActivityIdentifier:openUrl};
        
        NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:CSSearchableItemActionType];
        activity.userInfo = userInfo;
        
        [appDelegate application:(UIApplication *)mockApplication continueUserActivity:activity restorationHandler:^(NSArray * restorableObjects) {}];
        
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
        ASSERT_KEY_VALUE( TUNE_KEY_REFERRAL_URL, openUrl );
        ASSERT_KEY_VALUE( TUNE_KEY_REFERRAL_SOURCE, sourceApplication );
    }
}
#endif

- (void)testDeferredDeepLink {
    [Tune measureSession];
    
    // wait 0.5 sec to simulate deferred deep link fetch delay
    waitFor(0.5);
    
    static NSString* const openUrl = @"adblite://ng?integration=facebook&sub_site=Instagram&sub_campaign=Atomic%20Dodge%20Ball%20Lite%201&sub_adgroup=US%2018%2B&sub_ad=Challenge%20Friends%20Blue";
    static NSString* const sourceApplication = nil;
    [Tune applicationDidOpenURL:openUrl sourceApplication:sourceApplication];
    
    waitFor(0.5);
    
    waitFor1( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
    ASSERT_KEY_VALUE( TUNE_KEY_REFERRAL_URL, openUrl );
    ASSERT_NO_VALUE_FOR_KEY(TUNE_KEY_REFERRAL_SOURCE);
}

#if (TARGET_OS_IOS || TARGET_OS_IPHONE) && !TARGET_OS_TV

// NOTE: Temporarily stopped pending TRAC-1061
- (void)testCheckIadAttributioniOS9 {
    id classADClient = NSClassFromString(@"ADClient");
    
    if(classADClient && [classADClient instancesRespondToSelector:@selector(requestAttributionDetailsWithBlock:)]) {
        id classMockUIApplication = OCMClassMock([UIApplication class]);
        OCMStub(ClassMethod([classMockUIApplication sharedApplication])).andReturn(classMockUIApplication);
        
        id classMockADClient = OCMClassMock(classADClient);
        OCMStub(ClassMethod([classMockADClient sharedClient])).andReturn(classMockADClient);
        
//        // sample response from iAd Attribution v3 API document
//        NSDictionary *attributionDetails1 = @{@"Version3.1":@{
//                                                      @"iad-attribution" : @true,
//                                                      @"iad-campaign-id" : @"15292426",
//                                                      @"iad-campaign-name" : @"TestCA2",
//                                                      @"iad-conversion-date" : @"2015-08-19T17:18:07Z",
//                                                      @"iad-creative-id" : @"90841",
//                                                      @"iad-creative-name" : @"BoxFlip_iPad",
//                                                      @"iad-impression-date" : @"2015-08-19T17:17:00Z",
//                                                      @"iad-lineitem-id" : @"15307675",
//                                                      @"iad-lineitem-name" : @"TestCA2_L1",
//                                                      @"iad-org-name" : @"Zion_1412_org1"}};
        
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
                                                     @"iad-org-name":@"TUNE, Inc."}
                                             };
        
        NSError *error = nil;
        
        OCMStub([classMockADClient requestAttributionDetailsWithBlock:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
            void (^passedBlock)( NSDictionary *dictAttr, NSError *objError );
            [invocation getArgument:&passedBlock atIndex:2];
            
            passedBlock(attributionDetails, error);
        });
        
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_INSTALL );
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_ATTRIBUTION, [@true stringValue]);
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_CAMPAIGN_ID, @"15222869");
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_CAMPAIGN_NAME, @"atomic new 13");
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_CREATIVE_ID, @"226713");
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_CREATIVE_NAME, @"ad new");
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_LINE_ID, @"15325601");
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_LINE_NAME, @"2000 banner");
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_CAMPAIGN_ORG_NAME, @"TUNE, Inc.");
        
        // other iAd params currently ignored by Measurement Engine
        //ASSERT_KEY_VALUE( TUNE_KEY_IAD_CLICK_DATE, @"2016-03-23T07:55:00Z");
        //ASSERT_KEY_VALUE( TUNE_KEY_IAD_CONVERSION_DATE, @"2016-03-23T07:55:50Z");
        
        [classMockUIApplication stopMocking];
        [classMockADClient stopMocking];
    }
}

- (void)testCheckIadAttributioniOS8 {
    id classADClient = NSClassFromString(@"ADClient");
    
    if(classADClient && [classADClient instancesRespondToSelector:@selector(lookupAdConversionDetails:)]) {
        id classMockUIApplication = OCMClassMock([UIApplication class]);
        OCMStub(ClassMethod([classMockUIApplication sharedApplication])).andReturn(classMockUIApplication);
        
        id classMockADClient = OCMClassMock(classADClient);
        OCMStub(ClassMethod([classMockADClient sharedClient])).andReturn(classMockADClient);
        
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
        
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_INSTALL );
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_ATTRIBUTION, [@true stringValue]);
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_IMPRESSION_DATE, [@([impressionDate timeIntervalSince1970]) stringValue]);
        
        [classMockUIApplication stopMocking];
        [classMockADClient stopMocking];
        [classMockTuneUtils stopMocking];
    }
}

- (void)testCheckIadAttributioniOS7 {
    id classADClient = NSClassFromString(@"ADClient");
    
    if(classADClient && [classADClient instancesRespondToSelector:@selector(determineAppInstallationAttributionWithCompletionHandler:)]) {
        id classMockUIApplication = OCMClassMock([UIApplication class]);
        OCMStub(ClassMethod([classMockUIApplication sharedApplication])).andReturn(classMockUIApplication);
        
        id classMockADClient = OCMClassMock(classADClient);
        OCMStub(ClassMethod([classMockADClient sharedClient])).andReturn(classMockADClient);
        
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
        
        [Tune measureSession];
        waitForQueuesToFinish();
        
        XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
        ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_INSTALL );
        ASSERT_KEY_VALUE( TUNE_KEY_IAD_ATTRIBUTION, [@true stringValue]);
        
        [classMockUIApplication stopMocking];
        [classMockADClient stopMocking];
        [classMockTuneUtils stopMocking];
    }
}
#endif

#pragma mark - Arbitrary actions

- (void)testActionNameEvent {
    static NSString* const eventName = @"testEventName";
    [Tune measureEventName:eventName];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventId {
    NSInteger eventId = 931661820;
    NSString *strEventId = [@(eventId) stringValue];
    
    [Tune measureEventId:eventId];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testActionEventNameAllDigits {
    static NSString* const eventName = @"103";
    [Tune measureEventName:eventName];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventIdReference {
    NSInteger eventId = 931661820;
    NSString *strEventId = [@(eventId) stringValue];
    
    static NSString* const referenceId = @"abcdefg";
    
    TuneEvent *evt = [TuneEvent eventWithId:eventId];
    evt.refId = referenceId;
    
    [Tune measureEvent:evt];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_KEY_VALUE( TUNE_KEY_REF_ID, referenceId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testActionEventNameRevenueCurrency {
    static NSString* const eventName = @"103";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    
    TuneEvent *evt = [TuneEvent eventWithName:eventName];
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    
    [Tune measureEvent:evt];
    
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_KEY_VALUE( TUNE_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( TUNE_KEY_CURRENCY_CODE, currencyCode );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventIdReferenceRevenue {
    NSInteger eventId = 931661820;
    NSString *strEventId = [@(eventId) stringValue];
    
    static NSString* const referenceId = @"abcdefg";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    
    TuneEvent *evt = [TuneEvent eventWithId:eventId];
    evt.refId = referenceId;
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    
    [Tune measureEvent:evt];
    
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_KEY_VALUE( TUNE_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( TUNE_KEY_CURRENCY_CODE, currencyCode );
    ASSERT_KEY_VALUE( TUNE_KEY_REF_ID, referenceId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testEventNameSpaces {
    static NSString* const eventName = @"test event name";
    [Tune measureEventName:eventName];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testEventNameApostrophe {
    static NSString* const eventName = @"I'm an event name";
    [Tune measureEventName:eventName];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


#pragma mark - Reserved actions

- (void)testInstallActionEvent {
    [Tune measureEventName:TUNE_EVENT_INSTALL];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testUpdateActionEvent {
    [Tune measureEventName:TUNE_EVENT_UPDATE];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testCloseActionEvent {
    [Tune measureEventName:TUNE_EVENT_CLOSE];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkIsEmpty], @"'%@' action should be ignored", TUNE_EVENT_CLOSE );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testOpenActionEvent {
    [Tune measureEventName:TUNE_EVENT_OPEN];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION);
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testSessionActionEvent {
    [Tune measureEventName:TUNE_EVENT_SESSION];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION);
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

// "click" events are treated the same as arbitrary event names
- (void)testClickActionEvent {
    [Tune measureEventName:TUNE_EVENT_CLICK];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, TUNE_EVENT_CLICK );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

// "conversion" events are treated the same as arbitrary event names
- (void)testConversionActionEvent {
    [Tune measureEventName:TUNE_EVENT_CONVERSION];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, TUNE_EVENT_CONVERSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

// "registration" events are treated the same as arbitrary event names
- (void)testRegistrationActionEvent {
    static NSString* const eventName = @"registration";
    
    [Tune measureEventName:eventName];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

// "purchase" events are treated the same as arbitrary event names
- (void)testPurchaseActionEvent {
    static NSString* const eventName = @"purchase";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    
    TuneEvent *evt = [TuneEvent eventWithName:eventName];
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    
    [Tune measureEvent:evt];
    
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_KEY_VALUE( TUNE_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( TUNE_KEY_CURRENCY_CODE, currencyCode );
}

- (void)testTwoEvents {
    static NSString* const eventName1 = @"testEventName1";
    [Tune measureEventName:eventName1];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName1 );
    
    params = [TuneTestParams new];
    
    static NSString* const eventName2 = @"testEventName2";
    [Tune measureEventName:eventName2];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName2 );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testRequestEnqueuedCallback {
    enqueuedSession = NO;
    enqueuedEvent = YES;
    [Tune measureSession];
    waitForQueuesToFinish();
    XCTAssertTrue( enqueuedSession );
    XCTAssertFalse( enqueuedEvent );
    
    enqueuedSession = YES;
    enqueuedEvent = NO;
    static NSString* const eventName1 = @"testEventName1";
    [Tune measureEventName:eventName1];
    waitForQueuesToFinish();
    XCTAssertFalse( enqueuedSession );
    XCTAssertTrue( enqueuedEvent );
}


#pragma mark - Tune delegate

// secret functions to test server URLs
- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData {
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
