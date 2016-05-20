//
//  TuneParametersTests.m
//  Tune
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Tune+Testing.h"
#import "TuneConfigurationKeys.h"
#import "TuneEvent+Internal.h"
#import "TuneKeyStrings.h"
#import "TuneLocation.h"
#import "TuneManager.h"
#import "TuneTestParams.h"
#import "TuneTracker.h"
#import "TuneUserProfile.h"
#import "TuneUserProfileKeys.h"

@interface TuneParametersTests : XCTestCase <TuneDelegate>
{
    TuneTestParams *params;
}

@end

@implementation TuneParametersTests

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
    
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey];
    [Tune setDelegate:self];
    
    waitForQueuesToFinish();
    
    params = [TuneTestParams new];
    
    networkOnline();
}

- (void)tearDown {
    [Tune setCurrencyCode:nil];
    [Tune setPackageName:kTestBundleId];
    [Tune setPluginName:nil];

    emptyRequestQueue();

    [super tearDown];
}


#pragma mark - Age

- (void)testAgeValid {
    static const NSInteger age = 35;
    NSString *expectedAge = [@(age) stringValue];

    [Tune setAge:age];
    
    //startDate = [NSDate date];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_AGE, expectedAge );
}

- (void)testAgeYoung {
    static const NSInteger age = 6;
    NSString *expectedAge = [@(age) stringValue];
    
    [Tune setAge:age];
    
    //startDate = [NSDate date];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_AGE, expectedAge );
}

- (void)testAgeOld {
    static const NSInteger age = 65536;
    NSString *expectedAge = [@(age) stringValue];
    
    [Tune setAge:age];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_AGE, expectedAge );
}

- (void)testAgeZero {
    static const NSInteger age = 0;
    NSString *expectedAge = [@(age) stringValue];
    
    [Tune setAge:age];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_AGE, expectedAge );
}

- (void)testAgeNegative {
    static const NSInteger age = -304;
    NSString *expectedAge = [@(age) stringValue];
    
    [Tune setAge:age];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_AGE, expectedAge );
}


#pragma mark - Gender

- (void)testGenderMale {
    static const TuneGender gender = TuneGenderMale;
    NSString *expectedGender = [@(gender) stringValue];
    
    [Tune setGender:gender];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_GENDER, expectedGender );
}

- (void)testGenderFemale {
    static const TuneGender gender = TuneGenderFemale;
    NSString *expectedGender = [@(gender) stringValue];
    
    [Tune setGender:gender];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_GENDER, expectedGender );
}

- (void)testGenderUnknown {
    static const TuneGender gender = TuneGenderUnknown;
    
    [Tune setGender:gender];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_GENDER );
}

- (void)testGenderLarge {
    static const TuneGender gender = (TuneGender)65536;
    
    [Tune setGender:gender];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_GENDER );
}

- (void)testGenderNegative {
    static const TuneGender gender = (TuneGender)-304;
    
    [Tune setGender:gender];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_GENDER );
}


#pragma mark - Geolocation

- (void)testLatLongValid {
    static const double lat = 47.;
    static const double lon = -122.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    TuneLocation *location = [TuneLocation new];
    location.latitude = @(lat);
    location.longitude = @(lon);
    [Tune setLocation:location];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongZero {
    static const CGFloat lat = 0.;
    static const CGFloat lon = 0.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    TuneLocation *location = [TuneLocation new];
    location.latitude = @(lat);
    location.longitude = @(lon);
    [Tune setLocation:location];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongSmall {
    static const CGFloat lat = -190.;
    static const CGFloat lon = -190.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    TuneLocation *location = [TuneLocation new];
    location.latitude = @(lat);
    location.longitude = @(lon);
    [Tune setLocation:location];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongVerySmall {
    static const CGFloat lat = -370.;
    static const CGFloat lon = -370.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    TuneLocation *location = [TuneLocation new];
    location.latitude = @(lat);
    location.longitude = @(lon);
    [Tune setLocation:location];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongOneSmall {
    static const CGFloat lat = -190.;
    static const CGFloat lon = 1.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    TuneLocation *location = [TuneLocation new];
    location.latitude = @(lat);
    location.longitude = @(lon);
    [Tune setLocation:location];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongLarge {
    static const CGFloat lat = 190.;
    static const CGFloat lon = 190.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    TuneLocation *location = [TuneLocation new];
    location.latitude = @(lat);
    location.longitude = @(lon);
    [Tune setLocation:location];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongVeryLarge {
    static const CGFloat lat = 370.;
    static const CGFloat lon = 370.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    TuneLocation *location = [TuneLocation new];
    location.latitude = @(lat);
    location.longitude = @(lon);
    [Tune setLocation:location];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongAltValid {
    static const CGFloat lat = 47.;
    static const CGFloat lon = -122.;
    static const CGFloat alt = 41.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    NSString *expectedAlt = [@(alt) stringValue];
    
    TuneLocation *location = [TuneLocation new];
    location.latitude = @(lat);
    location.longitude = @(lon);
    location.altitude = @(alt);
    [Tune setLocation:location];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
    ASSERT_KEY_VALUE( TUNE_KEY_ALTITUDE, expectedAlt );
}

- (void)testLatLongAltZero {
    static const CGFloat lat = 47.;
    static const CGFloat lon = -122.;
    static const CGFloat alt = 0.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    NSString *expectedAlt = [@(alt) stringValue];
    
    TuneLocation *location = [TuneLocation new];
    location.latitude = @(lat);
    location.longitude = @(lon);
    location.altitude = @(alt);
    [Tune setLocation:location];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
    ASSERT_KEY_VALUE( TUNE_KEY_ALTITUDE, expectedAlt );
}

- (void)testLatLongAltVeryLarge {
    static const CGFloat lat = 47.;
    static const CGFloat lon = -122.;
    static const CGFloat alt = 999999.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    NSString *expectedAlt = [@(alt) stringValue];
    
    TuneLocation *location = [TuneLocation new];
    location.latitude = @(lat);
    location.longitude = @(lon);
    location.altitude = @(alt);
    [Tune setLocation:location];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
    ASSERT_KEY_VALUE( TUNE_KEY_ALTITUDE, expectedAlt );
}

- (void)testLatLongAltVerySmall {
    static const CGFloat lat = 47.;
    static const CGFloat lon = -122.;
    static const CGFloat alt = -999999.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    NSString *expectedAlt = [@(alt) stringValue];
    
    TuneLocation *location = [TuneLocation new];
    location.latitude = @(lat);
    location.longitude = @(lon);
    location.altitude = @(alt);
    [Tune setLocation:location];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
    ASSERT_KEY_VALUE( TUNE_KEY_ALTITUDE, expectedAlt );
}


#pragma mark - Currency code

- (void)testCurrencyCode {
    static NSString* const currency = @"CAD";
    
    [Tune setCurrencyCode:currency];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_CURRENCY_CODE, currency );
}

- (void)testCurrencyCodeDefault {
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    // fails because we have no real way to reset sharedManager
    //ASSERT_KEY_VALUE( KEY_CURRENCY_CODE, @"USD" );
}

- (void)testCurrencyCodeEmpty {
    NSString* const currency = TUNE_STRING_EMPTY;
    
    [Tune setCurrencyCode:currency];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_CURRENCY_CODE, currency );
}

- (void)testCurrencyCodeNil {
    [Tune setCurrencyCode:nil];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"currency_code"], @"should not have set currency code" );
}

- (void)testCurrencyCodeLong {
    static NSString* const currency = @"0000000000000000000000000000000000000000000";
    
    [Tune setCurrencyCode:currency];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_CURRENCY_CODE, currency );
}


#pragma mark - Package name

- (void)testPackageName {
    static NSString* const package = @"yourMom";
    
    [Tune setPackageName:package];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_PACKAGE_NAME, package );
}

- (void)testPackageNameEmpty {
    NSString* const package = TUNE_STRING_EMPTY;
    
    [Tune setPackageName:package];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_PACKAGE_NAME, package );
}

- (void)testPackageNil {
    [Tune setPackageName:nil];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"package_name"], @"should not have set package name" );
}

- (void)testPackageName256 {
    static NSString* const package = @"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    
    [Tune setPackageName:package];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_PACKAGE_NAME, package );
}

- (void)testPackageName257 {
    static NSString* const package = @"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    
    [Tune setPackageName:package];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_PACKAGE_NAME, package );
}

- (void)testPackageName1000 {
    static NSString* const package = @"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

    [Tune setPackageName:package];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_PACKAGE_NAME, package );
}


#pragma mark - Plugin name

- (void)testPluginNameInvalid {
    static NSString* const plugin = @"yourMom";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:TUNE_KEY_SDK_PLUGIN], @"should have no value for sdk_plugin" );
}

- (void)testPluginNameEmpty {
    NSString* const plugin = TUNE_STRING_EMPTY;

    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:TUNE_KEY_SDK_PLUGIN], @"should have no value for sdk_plugin" );
}

- (void)testPluginNameNil {
    [Tune setPluginName:nil];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:TUNE_KEY_SDK_PLUGIN], @"should have no value for sdk_plugin" );
}

- (void)testPluginNameAir {
    static NSString* const plugin = @"air";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNameAirUppercase {
    static NSString* const plugin = @"AIR";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:TUNE_KEY_SDK_PLUGIN], @"should have no value for sdk_plugin" );
}

- (void)testPluginNameCocos {
    static NSString* const plugin = @"cocos2dx";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNameMarmalade {
    static NSString* const plugin = @"marmalade";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNamePhoneGap {
    static NSString* const plugin = @"phonegap";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNameTitanium {
    static NSString* const plugin = @"titanium";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNameUnity {
    static NSString* const plugin = @"unity";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNameXamarin {
    static NSString* const plugin = @"xamarin";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_SDK_PLUGIN, plugin );
}


#pragma mark - User identifiers

- (void)testTrusteTPID {
    static NSString* const ID = @"testId";
    
    [Tune setTRUSTeId:ID];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_TRUSTE_TPID, ID );
}

- (void)testExistingUser {
    [Tune setExistingUser:YES];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_EXISTING_USER, [@TRUE stringValue] );
}

- (void)testUserEmail {
    static NSString* const EMAIL_ID = @"tempUserEmail@tempUserCompany.com";
    static NSString* const EMAIL_ID_MD5 = @"d76acab60fbd9bf136f79dafb6e79a3b";
    static NSString* const EMAIL_ID_SHA1 = @"e6c76b523cee03fd0dfea0d769a40d1a798dd522";
    static NSString* const EMAIL_ID_SHA256 = @"f2bcbd4dd2b172c1dad72b0ff850e2295b01392ceab45491e97fc9e093b42d30";
    
    [Tune setUserEmail:EMAIL_ID];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_MD5, EMAIL_ID_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_SHA1, EMAIL_ID_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_SHA256, EMAIL_ID_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_EMAIL );
    
    TuneAnalyticsVariable *var = nil;
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_EMAIL_MD5];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashMD5Type);
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_EMAIL_SHA1];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashSHA1Type);
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_EMAIL_SHA256];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashSHA256Type);
}

- (void)testUserEmailEmpty {
    NSString* const USER_EMAIL = TUNE_STRING_EMPTY; // empty
    static NSString* const USER_EMAIL_MD5 = @"d41d8cd98f00b204e9800998ecf8427e";
    static NSString* const USER_EMAIL_SHA1 = @"da39a3ee5e6b4b0d3255bfef95601890afd80709";
    static NSString* const USER_EMAIL_SHA256 = @"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
    
    [Tune setUserEmail:USER_EMAIL];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_MD5, USER_EMAIL_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_SHA1, USER_EMAIL_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_SHA256, USER_EMAIL_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_EMAIL );
    
    TuneAnalyticsVariable *var = nil;
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_EMAIL_MD5];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashMD5Type);
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_EMAIL_SHA1];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashSHA1Type);
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_EMAIL_SHA256];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashSHA256Type);
}

- (void)testUserEmailNil {
    static NSString* const USER_EMAIL = nil;
    
    [Tune setUserEmail:USER_EMAIL];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_EMAIL_MD5 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_EMAIL_SHA1 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_EMAIL_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_EMAIL );
}

- (void)testUserId {
    static NSString* const USER_ID = @"testId";
    
    [Tune setUserId:USER_ID];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_ID, USER_ID );
}

- (void)testUserName {
    static NSString* const USER_NAME = @"testName";
    static NSString* const USER_NAME_MD5 = @"f0f7b7b21cfd4f60934753232a0049f6";
    static NSString* const USER_NAME_SHA1 = @"0025dd9f850ce7889cf3e79e64328d0c4957751a";
    static NSString* const USER_NAME_SHA256 = @"4278d90b65ee634b960c9e026e4295f8f4fd8d3f29785548552afdc71ef4b495";
    
    [Tune setUserName:USER_NAME];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_MD5, USER_NAME_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_SHA1, USER_NAME_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_SHA256, USER_NAME_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_NAME );
    
    TuneAnalyticsVariable *var = nil;
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_NAME_MD5];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashMD5Type);
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_NAME_SHA1];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashSHA1Type);
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_NAME_SHA256];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashSHA256Type);
}

- (void)testUserNameEmpty {
    NSString* const USER_NAME = TUNE_STRING_EMPTY; // empty
    static NSString* const USER_NAME_MD5 = @"d41d8cd98f00b204e9800998ecf8427e";
    static NSString* const USER_NAME_SHA1 = @"da39a3ee5e6b4b0d3255bfef95601890afd80709";
    static NSString* const USER_NAME_SHA256 = @"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
    
    [Tune setUserName:USER_NAME];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_MD5, USER_NAME_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_SHA1, USER_NAME_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_SHA256, USER_NAME_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_NAME );
    
    TuneAnalyticsVariable *var = nil;
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_NAME_MD5];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashMD5Type);
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_NAME_SHA1];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashSHA1Type);
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_NAME_SHA256];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashSHA256Type);
}

- (void)testUserNameNil {
    static NSString* const USER_NAME = nil;
    
    [Tune setUserName:USER_NAME];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_NAME_MD5 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_NAME_SHA1 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_NAME_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_NAME );
}

- (void)testPhoneNumber {
    static NSString* const USER_PHONE = @"1234567890";
    static NSString* const USER_PHONE_MD5 = @"e807f1fcf82d132f9bb018ca6738a19f";
    static NSString* const USER_PHONE_SHA1 = @"01b307acba4f54f55aafc33bb06bbbf6ca803e9a";
    static NSString* const USER_PHONE_SHA256 = @"c775e7b757ede630cd0aa1113bd102661ab38829ca52a6422ab782862f268646";
    
    [Tune setPhoneNumber:USER_PHONE];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_MD5, USER_PHONE_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_SHA1, USER_PHONE_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_SHA256, USER_PHONE_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_PHONE );
    
    TuneAnalyticsVariable *var = nil;
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_PHONE_MD5];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashMD5Type);
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_PHONE_SHA1];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashSHA1Type);
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_PHONE_SHA256];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashSHA256Type);
}

- (void)testPhoneNumberEmpty {
    NSString* const USER_PHONE = TUNE_STRING_EMPTY; // empty
    static NSString* const USER_PHONE_MD5 = @"d41d8cd98f00b204e9800998ecf8427e";
    static NSString* const USER_PHONE_SHA1 = @"da39a3ee5e6b4b0d3255bfef95601890afd80709";
    static NSString* const USER_PHONE_SHA256 = @"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
    
    [Tune setPhoneNumber:USER_PHONE];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_MD5, USER_PHONE_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_SHA1, USER_PHONE_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_SHA256, USER_PHONE_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_PHONE );
    
    TuneAnalyticsVariable *var = nil;
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_PHONE_MD5];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashMD5Type);
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_PHONE_SHA1];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashSHA1Type);
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_PHONE_SHA256];
    XCTAssertFalse(var.shouldAutoHash);
    XCTAssertTrue(var.hashType == TuneAnalyticsVariableHashSHA256Type);
}

- (void)testPhoneNumberNil {
    static NSString* const USER_PHONE = nil;
    
    [Tune setPhoneNumber:USER_PHONE];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_PHONE_MD5 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_PHONE_SHA1 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_PHONE_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_PHONE );
}

- (void)testPhoneNumberNonEnglishCharacters {
    TuneUserProfile *userProfile = [TuneManager currentManager].userProfile;

    NSString *expected = nil;
    NSString *input = nil;
    NSString *actual = nil;
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"1234567890"; // normal English
    [Tune setPhoneNumber:input];
    waitFor(0.1);
    actual = userProfile.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"+123-456.7890"; // English with symbols
    [Tune setPhoneNumber:input];
    waitFor(0.1);
    actual = userProfile.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"637c0f48d8b173fff8cad875f8f9fc53"; // MD5 hash of "0033111223355"
    input = @"00 33 1 11 22 33 55"; // English numbers with spaces
    [Tune setPhoneNumber:input];
    waitFor(0.1);
    actual = userProfile.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"637c0f48d8b173fff8cad875f8f9fc53"; // MD5 hash of "0033111223355"
    input = @"00-33-1-11-22-33-55"; // English numbers with hyphens
    [Tune setPhoneNumber:input];
    waitFor(0.1);
    actual = userProfile.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"१२३४५६७८९०"; // Devanagari
    [Tune setPhoneNumber:input];
    waitFor(0.1);
    actual = userProfile.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"+१२३.४५६.७८९०"; // Devanagari with symbols
    [Tune setPhoneNumber:input];
    waitFor(0.1);
    actual = userProfile.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"١٢٣٤٥٦٧٨٩٠"; // Arabic
    [Tune setPhoneNumber:input];
    waitFor(0.1);
    actual = userProfile.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"(١٢٣)٤٥٦-٧.٨.٩ ٠"; // Arabic with symbols
    [Tune setPhoneNumber:input];
    waitFor(0.1);
    actual = userProfile.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"၁၂-၃၄-၅၆၇.၈၉ ၀"; // Burmese with symbols
    [Tune setPhoneNumber:input];
    waitFor(0.1);
    actual = userProfile.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"１２３４５６７８９０"; // Full-width characters
    [Tune setPhoneNumber:input];
    waitFor(0.1);
    actual = userProfile.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"(１２３)４５６-７８９０"; // Full-width characters with symbols
    [Tune setPhoneNumber:input];
    waitFor(0.1);
    actual = userProfile.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
}

- (void)testFacebookUserId {
    static NSString* const ID = @"testId";
    
    [Tune setFacebookUserId:ID];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_FACEBOOK_USER_ID, ID );
}

- (void)testTwitterUserId {
    static NSString* const ID = @"testId";
    
    [Tune setTwitterUserId:ID];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_TWITTER_USER_ID, ID );
}

- (void)testGoogleUserId {
    static NSString* const ID = @"testId";
    
    [Tune setGoogleUserId:ID];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_GOOGLE_USER_ID, ID );
}

- (void)testPayingUser {
    [Tune setPayingUser:YES];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_IS_PAYING_USER, [@TRUE stringValue] );
    XCTAssertTrue( [Tune isPayingUser], @"should be a paying user" );
}

- (void)testPayingUserAutomatic {
    [Tune setPayingUser:NO];
    
    TuneEvent *evt = [TuneEvent eventWithName:@"testEvent"];
    evt.revenue = 1.;
    evt.currencyCode = @"USD";
    
    [Tune measureEvent:evt];
    
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_IS_PAYING_USER, [@TRUE stringValue] );
    XCTAssertTrue( [Tune isPayingUser], @"should be a paying user" );
}

- (void)testPayingUserFalse {
    [Tune setPayingUser:NO];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_IS_PAYING_USER, [@FALSE stringValue] );
    XCTAssertFalse( [Tune isPayingUser], @"should not be a paying user" );
}

#if TARGET_OS_IOS

// TODO: move this to new class for internal params testing
#pragma mark - iAd attribution

- (void)testiAdAttribution {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    TuneUserProfile *userProfile = [TuneManager currentManager].userProfile;
#pragma clang diagnostic pop
    
    [userProfile setIadAttribution:@(TRUE)];

    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_IAD_ATTRIBUTION, [@(TRUE) stringValue] );
}


- (void)testiAdAttributionAppendTrue {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    TuneUserProfile *userProfile = [TuneManager currentManager].userProfile;
#pragma clang diagnostic pop
    
    [userProfile setIadAttribution:nil];
    
    [Tune measureSession];
    
    [userProfile setIadAttribution:@(TRUE)];

    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertTrue( [params checkKey:TUNE_KEY_IAD_ATTRIBUTION isEqualToValue:[@(TRUE) stringValue]],
                   @"should have set iad_attribution to true" );
}

#endif


#pragma mark - Tune delegate

// secret functions to test server URLs
- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
