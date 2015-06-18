//
//  MATTrackerInitializationTests.m
//  MobileAppTracker
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MATTestsHelper.h"
#import "MATTestParams.h"
#import "../MobileAppTracker/Common/MATSettings.h"
#import "../MobileAppTracker/Common/MATTracker.h"
#import "../MobileAppTracker/Common/MATUtils.h"

@interface MATTrackerInitializationTests : XCTestCase <MobileAppTrackerDelegate, MATSettingsDelegate>
{
    MATTestParams *params;
    MATTestParams *queryString;
    
    MATTracker *mat;
}

@end

@implementation MATTrackerInitializationTests

- (void)setUp
{
    [super setUp];

    mat = [MATTracker new];
    mat.delegate = self;
    mat.parameters.delegate = self;

    params = [MATTestParams new];
    queryString = [MATTestParams new];
    
    emptyRequestQueue();
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testAutodetectJailbroken
{
    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    
    MATEvent *event = [MATEvent eventWithName:@"registration"];
    [mat measureEvent:event];
    
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_OS_JAILBROKE, @"0" );
}

- (void)testNotAutodetectJailbroken
{
    [mat setShouldAutoDetectJailbroken:NO];
    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    MATEvent *event = [MATEvent eventWithName:@"registration"];
    [mat measureEvent:event];
    
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_OS_JAILBROKE );
}

- (void)testAutogenerateIFV
{
    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    MATEvent *event = [MATEvent eventWithName:@"registration"];
    [mat measureEvent:event];
    
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_IOS_IFV, [[[UIDevice currentDevice] identifierForVendor] UUIDString] );
}

- (void)testNotAutogenerateIFV
{
    [mat setShouldAutoGenerateAppleVendorIdentifier:NO];
    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    MATEvent *event = [MATEvent eventWithName:@"registration"];
    [mat measureEvent:event];
    
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_IOS_IFV );
}

- (void)testSendInstallReceipt
{
    static NSString* const eventName = @"fakeEventName";
    NSData *receiptData = [@"fakeReceiptDataString" dataUsingEncoding:NSUTF8StringEncoding];
    
    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    mat.parameters.openLogId = nil; // coerce receipt data into being sent again
    
    MATEvent *event = [MATEvent eventWithName:@"fakeEventName"];
    [mat measureEvent:event];
    waitFor( 1. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName );
    XCTAssertTrue( [params checkKeyHasValue:@"testAppleReceipt"], @"no Apple receipt sent" );
    XCTAssertTrue( [params checkAppleReceiptEquals:receiptData], @"Apple receipt value mismatch" );
}

- (void)testStoreUserIds
{
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
    
    [MATUtils setUserDefaultValue:testId forKey:MAT_KEY_USER_ID];
    [MATUtils setUserDefaultValue:EMAIL_ID_MD5 forKey:MAT_KEY_USER_EMAIL_MD5];
    [MATUtils setUserDefaultValue:EMAIL_ID_SHA1 forKey:MAT_KEY_USER_EMAIL_SHA1];
    [MATUtils setUserDefaultValue:EMAIL_ID_SHA256 forKey:MAT_KEY_USER_EMAIL_SHA256];
    [MATUtils setUserDefaultValue:USER_NAME_MD5 forKey:MAT_KEY_USER_NAME_MD5];
    [MATUtils setUserDefaultValue:USER_NAME_SHA1 forKey:MAT_KEY_USER_NAME_SHA1];
    [MATUtils setUserDefaultValue:USER_NAME_SHA256 forKey:MAT_KEY_USER_NAME_SHA256];
    [MATUtils setUserDefaultValue:USER_PHONE_MD5 forKey:MAT_KEY_USER_PHONE_MD5];
    [MATUtils setUserDefaultValue:USER_PHONE_SHA1 forKey:MAT_KEY_USER_PHONE_SHA1];
    [MATUtils setUserDefaultValue:USER_PHONE_SHA256 forKey:MAT_KEY_USER_PHONE_SHA256];
    
    mat = [MATTracker new];
    mat.delegate = self;
    mat.parameters.delegate = self;

    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    MATEvent *event = [MATEvent eventWithName:@"fakeEventName"];
    [mat measureEvent:event];
    waitFor( 1. );

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_USER_EMAIL_MD5, EMAIL_ID_MD5 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_EMAIL_SHA1, EMAIL_ID_SHA1 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_EMAIL_SHA256, EMAIL_ID_SHA256 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_ID, testId );
    ASSERT_KEY_VALUE( MAT_KEY_USER_NAME_MD5, USER_NAME_MD5 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_NAME_SHA1, USER_NAME_SHA1 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_NAME_SHA256, USER_NAME_SHA256 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_PHONE_MD5, USER_PHONE_MD5 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_PHONE_SHA1, USER_PHONE_SHA1 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_PHONE_SHA256, USER_PHONE_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_EMAIL );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_NAME );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_PHONE );
}


#pragma mark - MAT delegate

/*
- (void)mobileAppTrackerDidSucceedWithData:(NSData *)data
{
    //NSLog( @"test received success with %@\n", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] );
    callSuccess = YES;
    callFailed = NO;
}

- (void)mobileAppTrackerDidFailWithError:(NSError *)error
{
    callFailed = YES;
    callSuccess = NO;
    
    NSString *serverString = [error localizedDescription];
    
    if( [serverString rangeOfString:@"Duplicate request detected."].location != NSNotFound )
        callFailedDuplicate = YES;
    else
        NSLog( @"test received failure with %@\n", error );
}
 */

// secret functions to test server URLs
- (void)_matSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
