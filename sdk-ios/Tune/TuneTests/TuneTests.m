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
#import "TuneEventQueue.h"
#import "TuneBlankAppDelegate.h"
#import "TuneDeviceDetails.h"
#import "TuneEvent+Internal.h"
#import "TuneKeyStrings.h"
#import "TuneLog.h"
#import "TuneSkyhookCenter+Testing.h"
#import "TuneTestParams.h"
#import "TuneTestsHelper.h"
#import "TuneTracker.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"
#import "TuneManager.h"
#import <CoreSpotlight/CoreSpotlight.h>

#import "TuneXCTestCase.h"

@interface TuneTracker()
+ (NSTimeInterval)sessionQueuingDelay;
@end

@interface TuneTests : TuneXCTestCase <TuneDelegate> {
    TuneTestParams *params;
    TuneBlankAppDelegate *appDelegate;
    id mockApplication;
    
    NSString *webRequestPostData;
}

@end


@implementation TuneTests

- (void)setUp {
    [super setUp];
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId];
    [[TuneEventQueue sharedQueue] setUnitTestCallback:^(NSString *trackingUrl, NSString *postData) {
        XCTAssertTrue([params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl);
        if (postData) {
            XCTAssertTrue([params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData);
        }
    }];
    
    [Tune setExistingUser:NO];
    // Wait for everything to be set
    waitForQueuesToFinish();
    
    mockApplication = OCMClassMock([UIApplication class]);
    OCMStub(ClassMethod([mockApplication sharedApplication])).andReturn(mockApplication);
    appDelegate = [[TuneBlankAppDelegate alloc] init];
    
    params = [TuneTestParams new];
    
    webRequestPostData = nil;
}

- (void)tearDown {
    TuneLog.shared.logBlock = nil;
    TuneLog.shared.verbose = NO;
    
    emptyRequestQueue();
    [[TuneEventQueue sharedQueue] setUnitTestCallback:nil];
    
    [mockApplication stopMocking];
    [super tearDown];
}

- (void)testInitialization {
    XCTAssertTrue( TRUE );
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
    __block int errorCalls = 0;
    TuneLog.shared.logBlock = ^(NSString *message) {
        if ([message containsString:@"ERROR"]) {
            XCTAssert([message containsString:@"ERROR: tune_error_duplicate_session Ignoring duplicate \"session\" event measurement call in the same session"]);
            errorCalls++;
        }
    };
    
    [Tune measureSession];
    waitForQueuesToFinish();
    
    XCTAssert(errorCalls == 0);
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
    
    [Tune measureSession];
    waitForQueuesToFinish();
    
    XCTAssert(errorCalls == 1);
}

- (void)testAllowOpenAfterAppBackgroundForeground {
    TuneLog.shared.logBlock = ^(NSString *message) {
        if ([message containsString:@"First session request fired after the app was re-opened should not have been ignored."]) {
            XCTFail(@"Should not have been called");
        }
    };
    
    [Tune measureSession];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );

    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidEnterBackgroundNotification object:nil];
    waitFor( 0.2 );
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationWillEnterForegroundNotification object:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification object:nil];

    [Tune measureSession];
    waitForQueuesToFinish();
}

- (void)testInstallPostConversion {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    id tune = [[TuneTracker class] performSelector:@selector(sharedInstance)];
    waitFor( 1. );
    [tune performSelector:@selector(measureInstallPostConversion)];
#pragma clang diagnostic pop
    
    waitForQueuesToFinish();
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_INSTALL );
    ASSERT_KEY_VALUE( TUNE_KEY_POST_CONVERSION, @"1" );
}

- (void)testUrlOpen {
    NSString *openUrl = @"myapp://something/something?some=stuff&something=else";
    NSString *sourceApplication = @"Mail";
    [Tune handleOpenURL:[NSURL URLWithString:openUrl] sourceApplication:sourceApplication];
    
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
        NSString *openUrl = @"http://www.mycompany.com/mypage1";
        NSString *sourceApplication = @"web";
        
        NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
        userActivity.webpageURL = [NSURL URLWithString:openUrl];
        userActivity.userInfo = @{};
        
        [Tune handleContinueUserActivity:userActivity restorationHandler:nil];
        
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
        
        NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:CSSearchableItemActionType];
        userActivity.userInfo = userInfo;
        
        [Tune handleContinueUserActivity:userActivity restorationHandler:nil];
        
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

    NSString *openUrl = @"adblite://ng?integration=facebook&sub_site=Instagram&sub_campaign=Atomic%20Dodge%20Ball%20Lite%201&sub_adgroup=US%2018%2B&sub_ad=Challenge%20Friends%20Blue";
    
    NSString *sourceApplication = nil;
    [Tune handleOpenURL:[NSURL URLWithString:openUrl] sourceApplication:sourceApplication];

    waitFor(0.5);
    BOOL finished = NO;
    
    waitFor1([TuneTracker sessionQueuingDelay] + TUNE_TEST_NETWORK_REQUEST_DURATION, &finished);

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
    ASSERT_KEY_VALUE( TUNE_KEY_REFERRAL_URL, openUrl );
    ASSERT_NO_VALUE_FOR_KEY(TUNE_KEY_REFERRAL_SOURCE);
}


#pragma mark - Arbitrary actions

- (void)testActionNameEvent {
    NSString *eventName = @"testEventName";
    [Tune measureEventName:eventName];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventNameAllDigits {
    NSString *eventName = @"103";
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
    
    NSString *referenceId = @"abcdefg";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    TuneEvent *evt = [TuneEvent eventWithId:eventId];
#pragma clang diagnostic pop
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
    NSString *eventName = @"103";
    CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    NSString *currencyCode = @"XXX";
    
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
    
    NSString *referenceId = @"abcdefg";
    CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    NSString *currencyCode = @"XXX";
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    TuneEvent *evt = [TuneEvent eventWithId:eventId];
#pragma clang diagnostic pop
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
    NSString *eventName = @"test event name";
    [Tune measureEventName:eventName];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testEventNameApostrophe {
    NSString *eventName = @"I'm an event name";
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
    NSString *eventName = @"registration";
    
    [Tune measureEventName:eventName];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

// "purchase" events are treated the same as arbitrary event names
- (void)testPurchaseActionEvent {
    NSString *eventName = @"purchase";
    CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    NSString *currencyCode = @"XXX";
    
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
    NSString *eventName1 = @"testEventName1";
    [Tune measureEventName:eventName1];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName1 );
    
    params = [TuneTestParams new];
    
    NSString *eventName2 = @"testEventName2";
    [Tune measureEventName:eventName2];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName2 );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testRequestEnqueuedCallback {
    __block BOOL isSessionQueued = NO;
    __block BOOL isEventNamedQueued = NO;
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        if ([message containsString:@"action=session"]) {
            isSessionQueued = YES;
        } else if ([message containsString:@"site_event_name=testEventName1"]) {
            isEventNamedQueued = YES;
        }
    };
    
    [Tune measureSession];
    waitForQueuesToFinish();
    
    XCTAssertTrue(isSessionQueued);
    
    NSString *eventName1 = @"testEventName1";
    [Tune measureEventName:eventName1];
    waitForQueuesToFinish();

    XCTAssertTrue(isEventNamedQueued);
}

@end
