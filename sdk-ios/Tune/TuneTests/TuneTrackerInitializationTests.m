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
#import "TuneEvent+Internal.h"
#import "TuneKeyStrings.h"

#if (TARGET_OS_IOS || TARGET_OS_IPHONE) && !TARGET_OS_TV
#import "TuneManager.h"
#endif

#import "TuneAppToAppTracker.h"
#import "TuneTestParams.h"
#import "TuneTracker.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneUserProfile.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"

#import "TuneXCTestCase.h"



@interface TuneAppToAppTracker()

- (NSString *)buildLinkForTargetBundleId:(NSString*)targetBundleId
                            advertiserId:(NSString*)advertiserId
                              campaignId:(NSString*)campaignId
                             publisherId:(NSString*)publisherId
                              domainName:(NSString*)domainName;
@end



@interface TuneTrackerInitializationTests : TuneXCTestCase <TuneDelegate, TuneTrackerDelegate>
{
    TuneTestParams *params;
}

@property (nonatomic, strong, readwrite) TuneAppToAppTracker *testAppToAppTracker;
@property (nonatomic, strong, readwrite) NSString *testTuneAppToAppTrackerLink;
@property (nonatomic, strong, readwrite) NSString *testTargetBundleId;
@property (nonatomic, strong, readwrite) NSString *testAdvertiserId;
@property (nonatomic, strong, readwrite) NSString *testCampaignId;
@property (nonatomic, strong, readwrite) NSString *testPublisherId;
@property (nonatomic, strong, readwrite) NSString *testDomainName;
@property (nonatomic, strong, readwrite) TuneTracker *testTuneTracker;

@end

@implementation TuneTrackerInitializationTests

- (void)setUp {
    [super setUp];
    
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId wearable:NO];
    [Tune setDelegate:self];
    // Wait for everything to be set
    waitForQueuesToFinish();

    params = [TuneTestParams new];
}

- (void)tearDown {
    emptyRequestQueue();
    
    self.testAppToAppTracker = nil;
    self.testTuneAppToAppTrackerLink = nil;
    self.testTargetBundleId = nil;
    self.testAdvertiserId = nil;
    self.testCampaignId = nil;
    self.testPublisherId = nil;
    self.testDomainName = nil;
    self.testTuneTracker = nil;
    
    [super tearDown];
}

- (void)testAutodetectJailbroken {
    TuneEvent *event = [TuneEvent eventWithName:@"registration"];
    [Tune measureEvent:event];

    waitForQueuesToFinish();
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_OS_JAILBROKE, @"0" );
}

- (void)testNotAutodetectJailbroken {
    [Tune setShouldAutoDetectJailbroken:NO];

    TuneEvent *event = [TuneEvent eventWithName:@"registration"];
    [Tune measureEvent:event];

    waitForQueuesToFinish();
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_OS_JAILBROKE );
}

- (void)testAutogenerateIFV {
    TuneEvent *event = [TuneEvent eventWithName:@"registration"];
    [Tune measureEvent:event];

    waitForQueuesToFinish();
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_IOS_IFV, [[[UIDevice currentDevice] identifierForVendor] UUIDString] );
}

- (void)testNotAutogenerateIFV {
    [Tune setShouldAutoGenerateAppleVendorIdentifier:NO];

    TuneEvent *event = [TuneEvent eventWithName:@"registration"];
    [Tune measureEvent:event];

    waitForQueuesToFinish();
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_IOS_IFV );
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

    static NSString* const EMAIL_ID_MD5 = @"10ae7c7ac7335ceb633761b90d515698";
    static NSString* const EMAIL_ID_SHA1 = @"3be1c5898e7d600b2765f964e27cf0af531c4970";
    static NSString* const EMAIL_ID_SHA256 = @"7d77f636df10b5c23bd162948338099fab351c87e9c8a12bd09234a18ce2b209";

    static NSString* const USER_NAME_MD5 = @"afe107acd2e1b816b5da87f79c90fdc7";
    static NSString* const USER_NAME_SHA1 = @"adc8de6b036aed3455b44abc62639e708d3ffef5";
    static NSString* const USER_NAME_SHA256 = @"d67fdd0c0e917b0c55cc9480fb7257d00ab33cd832cd88e0eefbcf6626265d49";

    static NSString* const USER_PHONE_MD5 = @"3354045a397621cd92406f1f98cde292";
    static NSString* const USER_PHONE_SHA1 = @"1f4a04e5543d8760660bb080226040b987b88d47";
    static NSString* const USER_PHONE_SHA256 = @"9260f889a03c3de5a806b802afdcca308513328a90c44988955d8dc13dd93504";

    [TuneUserDefaultsUtils setUserDefaultValue:testId forKey:TUNE_KEY_USER_ID];
    [TuneUserDefaultsUtils setUserDefaultValue:EMAIL_ID_MD5 forKey:TUNE_KEY_USER_EMAIL_MD5];
    [TuneUserDefaultsUtils setUserDefaultValue:EMAIL_ID_SHA1 forKey:TUNE_KEY_USER_EMAIL_SHA1];
    [TuneUserDefaultsUtils setUserDefaultValue:EMAIL_ID_SHA256 forKey:TUNE_KEY_USER_EMAIL_SHA256];
    [TuneUserDefaultsUtils setUserDefaultValue:USER_NAME_MD5 forKey:TUNE_KEY_USER_NAME_MD5];
    [TuneUserDefaultsUtils setUserDefaultValue:USER_NAME_SHA1 forKey:TUNE_KEY_USER_NAME_SHA1];
    [TuneUserDefaultsUtils setUserDefaultValue:USER_NAME_SHA256 forKey:TUNE_KEY_USER_NAME_SHA256];
    [TuneUserDefaultsUtils setUserDefaultValue:USER_PHONE_MD5 forKey:TUNE_KEY_USER_PHONE_MD5];
    [TuneUserDefaultsUtils setUserDefaultValue:USER_PHONE_SHA1 forKey:TUNE_KEY_USER_PHONE_SHA1];
    [TuneUserDefaultsUtils setUserDefaultValue:USER_PHONE_SHA256 forKey:TUNE_KEY_USER_PHONE_SHA256];

    // NOTE: We need to instantiate everything again here since the only time things are loaded from
    //       NSUserDefaults for the UserProfile is on instantiation
    [[TuneManager currentManager] instantiateModules];
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId wearable:NO];
    [Tune setDelegate:self];
    waitForQueuesToFinish();

    TuneEvent *event = [TuneEvent eventWithName:@"fakeEventName"];
    [Tune measureEvent:event];

    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_MD5, EMAIL_ID_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_SHA1, EMAIL_ID_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_SHA256, EMAIL_ID_SHA256 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_ID, testId );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_MD5, USER_NAME_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_SHA1, USER_NAME_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_SHA256, USER_NAME_SHA256 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_MD5, USER_PHONE_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_SHA1, USER_PHONE_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_SHA256, USER_PHONE_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_EMAIL );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_NAME );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_PHONE );
}

#if (TARGET_OS_IOS || TARGET_OS_IPHONE) && !TARGET_OS_TV
- (void)testWearableDevice {
    [[TuneManager currentManager].userProfile setWearable:@(YES)];

    TuneEvent *event = [TuneEvent eventWithName:@"fakeEventName"];
    [Tune measureEvent:event];

    waitForQueuesToFinish();
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"device_form", @"wearable" );
}
#endif

// Locale and build collection are required for AdWords attribution
- (void)testLocaleAndBuild {
    NSString *build = [[TuneManager currentManager].userProfile deviceBuild];
    NSString *locale = [[TuneManager currentManager].userProfile locale];

    XCTAssertNotNil(build);
    XCTAssertNotNil(locale);
    XCTAssertTrue([@"en_US" isEqualToString:locale]);
}

- (void) testProdEventShouldNotUseDebugEndpoint {
    [Tune setDebugMode:NO];
    self.testAppToAppTracker = [TuneAppToAppTracker new];
    self.testTuneTracker = [TuneTracker new];
    
    TuneEvent *testEvent = [TuneEvent eventWithName:@"fakeEventName"];
    NSString *testTrackingLink;
    NSString *testEncryptParams;
    
    self.testTuneAppToAppTrackerLink = [self.testAppToAppTracker buildLinkForTargetBundleId:self.testTargetBundleId advertiserId:self.testAdvertiserId campaignId:self.testCampaignId publisherId:self.testPublisherId domainName:self.testDomainName];
    
    [self.testTuneTracker urlStringForEvent:testEvent
                          trackingLink:&testTrackingLink
                         encryptParams:&testEncryptParams];
    
    XCTAssertFalse( [self.testTuneAppToAppTrackerLink containsString:@"debug.engine.mobileapptracking.com"] );
    XCTAssertFalse( [testTrackingLink containsString:@"debug.engine.mobileapptracking.com"] );
    XCTAssertFalse( [testTrackingLink containsString:@"debug=1"] );
}

- (void) testDebugEventShouldNotUseDebugEndpointAndUseDebugFlagAsApplicable {
    [Tune setDebugMode:YES];
    self.testAppToAppTracker = [TuneAppToAppTracker new];
    self.testTuneTracker = [TuneTracker new];
    
    TuneEvent *testEvent = [TuneEvent eventWithName:@"fakeEventName"];
    NSString *testTrackingLink;
    NSString *testEncryptParams;
    
    self.testTuneAppToAppTrackerLink = [self.testAppToAppTracker buildLinkForTargetBundleId:self.testTargetBundleId advertiserId:self.testAdvertiserId campaignId:self.testCampaignId publisherId:self.testPublisherId domainName:self.testDomainName];
    
    [self.testTuneTracker urlStringForEvent:testEvent
                          trackingLink:&testTrackingLink
                         encryptParams:&testEncryptParams];
    
    XCTAssertFalse( [self.testTuneAppToAppTrackerLink containsString:@"debug.engine.mobileapptracking.com"] );
    XCTAssertFalse( [testTrackingLink containsString:@"debug.engine.mobileapptracking.com"] );
    XCTAssertTrue( [testTrackingLink containsString:@"debug=1"] );
}

#pragma mark - Tune delegate

// secret functions to test server URLs
- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData {
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
