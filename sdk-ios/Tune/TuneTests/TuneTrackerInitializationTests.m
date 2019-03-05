//
//  TuneTrackerInitializationTests.m
//  Tune
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>


#if (TARGET_OS_IOS || TARGET_OS_IPHONE) && !TARGET_OS_TV
#import <iAd/iAd.h>
#endif

#import "Tune+Testing.h"
#import "TuneEventQueue.h"
#import "TuneEvent+Internal.h"
#import "TuneKeyStrings.h"
#import "TuneEventQueue.h"

#if (TARGET_OS_IOS || TARGET_OS_IPHONE) && !TARGET_OS_TV
#import "TuneManager.h"
#endif

#import "TuneTestParams.h"
#import "TuneTracker.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneUserProfile.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"

#import "TuneXCTestCase.h"

@interface TuneTrackerInitializationTests : TuneXCTestCase <TuneTrackerDelegate>
{
    TuneTestParams *params;
}

@end

@implementation TuneTrackerInitializationTests

- (void)setUp {
    [super setUp];
    
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId];
    [[TuneEventQueue sharedQueue] setUnitTestCallback:^(NSString *trackingUrl, NSString *postData) {
        XCTAssertTrue([params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl);
        if (postData) {
            XCTAssertTrue([params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData);
        }
    }];

    // Wait for everything to be set
    waitForQueuesToFinish();

    params = [TuneTestParams new];
}

- (void)tearDown {
    emptyRequestQueue();
    [[TuneEventQueue sharedQueue] setUnitTestCallback:nil];
    [super tearDown];
}

- (void)testAutodetectJailbroken {
    TuneEvent *event = [TuneEvent eventWithName:@"registration"];
    [Tune measureEvent:event];

    waitForQueuesToFinish();
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_OS_JAILBROKE, @"0" );
}

- (void)testOverrideJailbroken {
    [Tune setJailbroken:YES];

    TuneEvent *event = [TuneEvent eventWithName:@"registration"];
    [Tune measureEvent:event];

    waitForQueuesToFinish();
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE(TUNE_KEY_OS_JAILBROKE, @"1");
}

- (void)testCollectIFV {
    TuneEvent *event = [TuneEvent eventWithName:@"registration"];
    [Tune measureEvent:event];

    waitForQueuesToFinish();
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_IOS_IFV, [[[UIDevice currentDevice] identifierForVendor] UUIDString] );
}

- (void)testSendInstallReceipt {
    static NSString* const eventName = @"fakeEventName";
    NSData *receiptData = [@"fakeReceiptDataString" dataUsingEncoding:NSUTF8StringEncoding];

    [[TuneManager currentManager].userProfile setOpenLogId:nil]; // coerce receipt data into being sent again

    TuneEvent *event = [TuneEvent eventWithName:@"fakeEventName"];
    [Tune measureEvent:event];

    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    XCTAssertTrue( [params checkKeyHasValue:@"testAppleReceipt"], @"no Apple receipt sent" );
    XCTAssertTrue( [params checkAppleReceiptEquals:receiptData], @"Apple receipt value mismatch" );
}

- (void)testStoreUserIds {
    static NSString *const testId = @"testid";
    static NSString* const EMAIL_ID_SHA256 = @"7d77f636df10b5c23bd162948338099fab351c87e9c8a12bd09234a18ce2b209";
    static NSString* const USER_NAME_SHA256 = @"d67fdd0c0e917b0c55cc9480fb7257d00ab33cd832cd88e0eefbcf6626265d49";
    static NSString* const USER_PHONE_SHA256 = @"9260f889a03c3de5a806b802afdcca308513328a90c44988955d8dc13dd93504";

    [TuneUserDefaultsUtils setUserDefaultValue:testId forKey:TUNE_KEY_USER_ID];
    [TuneUserDefaultsUtils setUserDefaultValue:EMAIL_ID_SHA256 forKey:TUNE_KEY_USER_EMAIL_SHA256];
    [TuneUserDefaultsUtils setUserDefaultValue:USER_NAME_SHA256 forKey:TUNE_KEY_USER_NAME_SHA256];
    [TuneUserDefaultsUtils setUserDefaultValue:USER_PHONE_SHA256 forKey:TUNE_KEY_USER_PHONE_SHA256];

    // NOTE: We need to instantiate everything again here since the only time things are loaded from
    //       NSUserDefaults for the UserProfile is on instantiation
    [[TuneManager currentManager] instantiateModules];
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId];
    waitForQueuesToFinish();

    TuneEvent *event = [TuneEvent eventWithName:@"fakeEventName"];
    [Tune measureEvent:event];

    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY(TUNE_KEY_USER_EMAIL_SHA256);
    ASSERT_KEY_VALUE(TUNE_KEY_USER_ID, testId);
    ASSERT_NO_VALUE_FOR_KEY(TUNE_KEY_USER_NAME_SHA256);
    ASSERT_NO_VALUE_FOR_KEY(TUNE_KEY_USER_PHONE_SHA256);
    ASSERT_NO_VALUE_FOR_KEY(TUNE_KEY_USER_EMAIL);
    ASSERT_NO_VALUE_FOR_KEY(TUNE_KEY_USER_NAME);
    ASSERT_NO_VALUE_FOR_KEY(TUNE_KEY_USER_PHONE);
}

// Locale and build collection are required for AdWords attribution
- (void)testLocaleAndBuild {
    NSString *build = [[TuneManager currentManager].userProfile deviceBuild];
    NSString *locale = [[TuneManager currentManager].userProfile locale];

    XCTAssertNotNil(build);
    XCTAssertNotNil(locale);
    XCTAssertTrue([@"en_US" isEqualToString:locale]);
}

@end
