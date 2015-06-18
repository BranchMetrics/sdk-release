//
//  MATParametersTests.m
//  MobileAppTracker
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AdSupport/AdSupport.h>
#import "MATTestsHelper.h"
#import "MATTestParams.h"
#import "../MobileAppTracker/MobileAppTracker.h"
#import "../MobileAppTracker/Common/MATKeyStrings.h"
#import "../MobileAppTracker/Common/MATSettings.h"
#import "../MobileAppTracker/Common/MATTracker.h"

@interface MobileAppTracker (MATParametersTests)

+ (void)setPluginName:(NSString *)pluginName;

@end

@interface MATParametersTests : XCTestCase <MobileAppTrackerDelegate>
{
    MATTestParams *params;
}

@end

@implementation MATParametersTests

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


#pragma mark - Age

- (void)testAgeValid
{
    static const NSInteger age = 35;
    NSString *expectedAge = [@(age) stringValue];
    
    [MobileAppTracker setAge:age];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_AGE, expectedAge );
}

- (void)testAgeYoung
{
    static const NSInteger age = 6;
    NSString *expectedAge = [@(age) stringValue];
    
    [MobileAppTracker setAge:age];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_AGE, expectedAge );
}

- (void)testAgeOld
{
    static const NSInteger age = 65536;
    NSString *expectedAge = [@(age) stringValue];
    
    [MobileAppTracker setAge:age];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_AGE, expectedAge );
}

- (void)testAgeZero
{
    static const NSInteger age = 0;
    NSString *expectedAge = [@(age) stringValue];
    
    [MobileAppTracker setAge:age];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_AGE, expectedAge );
}

- (void)testAgeNegative
{
    static const NSInteger age = -304;
    NSString *expectedAge = [@(age) stringValue];
    
    [MobileAppTracker setAge:age];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_AGE, expectedAge );
}


#pragma mark - Gender

- (void)testGenderMale
{
    static const MATGender gender = MATGenderMale;
    NSString *expectedGender = [@(gender) stringValue];
    
    [MobileAppTracker setGender:gender];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_GENDER, expectedGender );
}

- (void)testGenderFemale
{
    static const MATGender gender = MATGenderFemale;
    NSString *expectedGender = [@(gender) stringValue];
    
    [MobileAppTracker setGender:gender];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_GENDER, expectedGender );
}

- (void)testGenderMaleBackwardCompatible
{
    static const MATGender gender = MAT_GENDER_MALE;
    NSString *expectedGender = [NSString stringWithFormat:@"%d", (int)gender];
    
    [MobileAppTracker setGender:gender];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_GENDER, expectedGender );
}

- (void)testGenderFemaleBackwardCompatible
{
    static const MATGender gender = MAT_GENDER_FEMALE;
    NSString *expectedGender = [NSString stringWithFormat:@"%d", (int)gender];
    
    [MobileAppTracker setGender:gender];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_GENDER, expectedGender );
}

- (void)testGenderLarge
{
    static const MATGender gender = (MATGender)65536;
    NSString *expectedGender = [@(MATGenderMale) stringValue];
    
    [MobileAppTracker setGender:gender];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_GENDER, expectedGender );
}

- (void)testGenderNegative
{
    static const MATGender gender = (MATGender)-304;
    NSString *expectedGender = [@(MATGenderMale) stringValue];
    
    [MobileAppTracker setGender:gender];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_GENDER, expectedGender );
}


#pragma mark - Geolocation

- (void)testLatLongValid
{
    static const double lat = 47.;
    static const double lon = -122.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    [MobileAppTracker setLatitude:lat longitude:lon];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( MAT_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongZero
{
    static const CGFloat lat = 0.;
    static const CGFloat lon = 0.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    [MobileAppTracker setLatitude:lat longitude:lon];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( MAT_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongSmall
{
    static const CGFloat lat = -190.;
    static const CGFloat lon = -190.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    [MobileAppTracker setLatitude:lat longitude:lon];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( MAT_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongVerySmall
{
    static const CGFloat lat = -370.;
    static const CGFloat lon = -370.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    [MobileAppTracker setLatitude:lat longitude:lon];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( MAT_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongOneSmall
{
    static const CGFloat lat = -190.;
    static const CGFloat lon = 1.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    [MobileAppTracker setLatitude:lat longitude:lon];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( MAT_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongLarge
{
    static const CGFloat lat = 190.;
    static const CGFloat lon = 190.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    [MobileAppTracker setLatitude:lat longitude:lon];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( MAT_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongVeryLarge
{
    static const CGFloat lat = 370.;
    static const CGFloat lon = 370.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    [MobileAppTracker setLatitude:lat longitude:lon];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( MAT_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongAltValid
{
    static const CGFloat lat = 47.;
    static const CGFloat lon = -122.;
    static const CGFloat alt = 41.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    NSString *expectedAlt = [@(alt) stringValue];
    
    [MobileAppTracker setLatitude:lat longitude:lon altitude:alt];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( MAT_KEY_LONGITUDE, expectedLon );
    ASSERT_KEY_VALUE( MAT_KEY_ALTITUDE, expectedAlt );
}

- (void)testLatLongAltZero
{
    static const CGFloat lat = 47.;
    static const CGFloat lon = -122.;
    static const CGFloat alt = 0.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    NSString *expectedAlt = [@(alt) stringValue];
    
    [MobileAppTracker setLatitude:lat longitude:lon altitude:alt];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( MAT_KEY_LONGITUDE, expectedLon );
    ASSERT_KEY_VALUE( MAT_KEY_ALTITUDE, expectedAlt );
}

- (void)testLatLongAltVeryLarge
{
    static const CGFloat lat = 47.;
    static const CGFloat lon = -122.;
    static const CGFloat alt = 999999.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    NSString *expectedAlt = [@(alt) stringValue];
    
    [MobileAppTracker setLatitude:lat longitude:lon altitude:alt];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( MAT_KEY_LONGITUDE, expectedLon );
    ASSERT_KEY_VALUE( MAT_KEY_ALTITUDE, expectedAlt );
}

- (void)testLatLongAltVerySmall
{
    static const CGFloat lat = 47.;
    static const CGFloat lon = -122.;
    static const CGFloat alt = -999999.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    NSString *expectedAlt = [@(alt) stringValue];
    
    [MobileAppTracker setLatitude:lat longitude:lon altitude:alt];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( MAT_KEY_LONGITUDE, expectedLon );
    ASSERT_KEY_VALUE( MAT_KEY_ALTITUDE, expectedAlt );
}


#pragma mark - Currency code

- (void)testCurrencyCode
{
    static NSString* const currency = @"CAD";
    
    [MobileAppTracker setCurrencyCode:currency];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_CURRENCY_CODE, currency );
}

- (void)testCurrencyCodeDefault
{
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    // fails because we have no real way to reset sharedManager
    //ASSERT_KEY_VALUE( KEY_CURRENCY_CODE, @"USD" );
}

- (void)testCurrencyCodeEmpty
{
    NSString* const currency = MAT_STRING_EMPTY;
    
    [MobileAppTracker setCurrencyCode:currency];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_CURRENCY_CODE, currency );
}

- (void)testCurrencyCodeNil
{
    [MobileAppTracker setCurrencyCode:nil];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"currency_code"], @"should not have set currency code" );
}

- (void)testCurrencyCodeLong
{
    static NSString* const currency = @"0000000000000000000000000000000000000000000";
    
    [MobileAppTracker setCurrencyCode:currency];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_CURRENCY_CODE, currency );
}


#pragma mark - Package name

- (void)testPackageName
{
    static NSString* const package = @"yourMom";
    
    [MobileAppTracker setPackageName:package];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_PACKAGE_NAME, package );
}

- (void)testPackageNameEmpty
{
    NSString* const package = MAT_STRING_EMPTY;
    
    [MobileAppTracker setPackageName:package];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_PACKAGE_NAME, package );
}

- (void)testPackageNil
{
    [MobileAppTracker setPackageName:nil];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"package_name"], @"should not have set package name" );
}

- (void)testPackageName256
{
    static NSString* const package = @"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    
    [MobileAppTracker setPackageName:package];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_PACKAGE_NAME, package );
}

- (void)testPackageName257
{
    static NSString* const package = @"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    
    [MobileAppTracker setPackageName:package];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_PACKAGE_NAME, package );
}

- (void)testPackageName1000
{
    static NSString* const package = @"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    
    [MobileAppTracker setPackageName:package];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_PACKAGE_NAME, package );
}


#pragma mark - Plugin name

- (void)testPluginNameInvalid
{
    static NSString* const plugin = @"yourMom";
    
    [MobileAppTracker setPluginName:plugin];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:MAT_KEY_SDK_PLUGIN], @"should have no value for sdk_plugin" );
}

- (void)testPluginNameEmpty
{
    NSString* const plugin = MAT_STRING_EMPTY;
    
    [MobileAppTracker setPluginName:plugin];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:MAT_KEY_SDK_PLUGIN], @"should have no value for sdk_plugin" );
}

- (void)testPluginNameNil
{
    [MobileAppTracker setPluginName:nil];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:MAT_KEY_SDK_PLUGIN], @"should have no value for sdk_plugin" );
}

- (void)testPluginNameAir
{
    static NSString* const plugin = @"air";
    
    [MobileAppTracker setPluginName:plugin];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNameAirUppercase
{
    static NSString* const plugin = @"AIR";
    
    [MobileAppTracker setPluginName:plugin];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:MAT_KEY_SDK_PLUGIN], @"should have no value for sdk_plugin" );
}

- (void)testPluginNameCocos
{
    static NSString* const plugin = @"cocos2dx";
    
    [MobileAppTracker setPluginName:plugin];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNameMarmalade
{
    static NSString* const plugin = @"marmalade";
    
    [MobileAppTracker setPluginName:plugin];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNamePhoneGap
{
    static NSString* const plugin = @"phonegap";
    
    [MobileAppTracker setPluginName:plugin];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNameTitanium
{
    static NSString* const plugin = @"titanium";
    
    [MobileAppTracker setPluginName:plugin];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNameUnity
{
    static NSString* const plugin = @"unity";
    
    [MobileAppTracker setPluginName:plugin];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNameXamarin
{
    static NSString* const plugin = @"xamarin";
    
    [MobileAppTracker setPluginName:plugin];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_SDK_PLUGIN, plugin );
}


#pragma mark - User identifiers

- (void)testSiteId
{
    static NSString* const ID = @"testId";
    
    [MobileAppTracker setSiteId:ID];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_ID, ID );
}

- (void)testTrusteTPID
{
    static NSString* const ID = @"testId";
    
    [MobileAppTracker setTRUSTeId:ID];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_ID, ID );
}

- (void)testExistingUser
{
    [MobileAppTracker setExistingUser:YES];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_EXISTING_USER, [@TRUE stringValue] );
}

- (void)testUserEmail
{
    static NSString* const EMAIL_ID = @"tempUserEmail@tempUserCompany.com";
    static NSString* const EMAIL_ID_MD5 = @"d76acab60fbd9bf136f79dafb6e79a3b";
    static NSString* const EMAIL_ID_SHA1 = @"e6c76b523cee03fd0dfea0d769a40d1a798dd522";
    static NSString* const EMAIL_ID_SHA256 = @"f2bcbd4dd2b172c1dad72b0ff850e2295b01392ceab45491e97fc9e093b42d30";
    
    [MobileAppTracker setUserEmail:EMAIL_ID];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_USER_EMAIL_MD5, EMAIL_ID_MD5 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_EMAIL_SHA1, EMAIL_ID_SHA1 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_EMAIL_SHA256, EMAIL_ID_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_EMAIL );
}

- (void)testUserEmailEmpty
{
    NSString* const USER_EMAIL = MAT_STRING_EMPTY; // empty
    static NSString* const USER_EMAIL_MD5 = @"d41d8cd98f00b204e9800998ecf8427e";
    static NSString* const USER_EMAIL_SHA1 = @"da39a3ee5e6b4b0d3255bfef95601890afd80709";
    static NSString* const USER_EMAIL_SHA256 = @"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
    
    [MobileAppTracker setUserEmail:USER_EMAIL];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_USER_EMAIL_MD5, USER_EMAIL_MD5 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_EMAIL_SHA1, USER_EMAIL_SHA1 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_EMAIL_SHA256, USER_EMAIL_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_EMAIL );
}

- (void)testUserEmailNil
{
    static NSString* const USER_EMAIL = nil;
    
    [MobileAppTracker setUserEmail:USER_EMAIL];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_EMAIL_MD5 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_EMAIL_SHA1 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_EMAIL_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_EMAIL );
}

- (void)testUserId
{
    static NSString* const USER_ID = @"testId";
    
    [MobileAppTracker setUserId:USER_ID];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_USER_ID, USER_ID );
}

- (void)testUserName
{
    static NSString* const USER_NAME = @"testName";
    static NSString* const USER_NAME_MD5 = @"f0f7b7b21cfd4f60934753232a0049f6";
    static NSString* const USER_NAME_SHA1 = @"0025dd9f850ce7889cf3e79e64328d0c4957751a";
    static NSString* const USER_NAME_SHA256 = @"4278d90b65ee634b960c9e026e4295f8f4fd8d3f29785548552afdc71ef4b495";
    
    [MobileAppTracker setUserName:USER_NAME];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_USER_NAME_MD5, USER_NAME_MD5 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_NAME_SHA1, USER_NAME_SHA1 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_NAME_SHA256, USER_NAME_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_NAME );
}

- (void)testUserNameEmpty
{
    NSString* const USER_NAME = MAT_STRING_EMPTY; // empty
    static NSString* const USER_NAME_MD5 = @"d41d8cd98f00b204e9800998ecf8427e";
    static NSString* const USER_NAME_SHA1 = @"da39a3ee5e6b4b0d3255bfef95601890afd80709";
    static NSString* const USER_NAME_SHA256 = @"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
    
    [MobileAppTracker setUserName:USER_NAME];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_USER_NAME_MD5, USER_NAME_MD5 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_NAME_SHA1, USER_NAME_SHA1 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_NAME_SHA256, USER_NAME_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_NAME );
}

- (void)testUserNameNil
{
    static NSString* const USER_NAME = nil;
    
    [MobileAppTracker setUserName:USER_NAME];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_NAME_MD5 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_NAME_SHA1 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_NAME_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_NAME );
}

- (void)testPhoneNumber
{
    static NSString* const USER_PHONE = @"1234567890";
    static NSString* const USER_PHONE_MD5 = @"e807f1fcf82d132f9bb018ca6738a19f";
    static NSString* const USER_PHONE_SHA1 = @"01b307acba4f54f55aafc33bb06bbbf6ca803e9a";
    static NSString* const USER_PHONE_SHA256 = @"c775e7b757ede630cd0aa1113bd102661ab38829ca52a6422ab782862f268646";
    
    [MobileAppTracker setPhoneNumber:USER_PHONE];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_USER_PHONE_MD5, USER_PHONE_MD5 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_PHONE_SHA1, USER_PHONE_SHA1 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_PHONE_SHA256, USER_PHONE_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_PHONE );
}

- (void)testPhoneNumberEmpty
{
    NSString* const USER_PHONE = MAT_STRING_EMPTY; // empty
    static NSString* const USER_PHONE_MD5 = @"d41d8cd98f00b204e9800998ecf8427e";
    static NSString* const USER_PHONE_SHA1 = @"da39a3ee5e6b4b0d3255bfef95601890afd80709";
    static NSString* const USER_PHONE_SHA256 = @"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
    
    [MobileAppTracker setPhoneNumber:USER_PHONE];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_USER_PHONE_MD5, USER_PHONE_MD5 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_PHONE_SHA1, USER_PHONE_SHA1 );
    ASSERT_KEY_VALUE( MAT_KEY_USER_PHONE_SHA256, USER_PHONE_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_PHONE );
}

- (void)testPhoneNumberNil
{
    static NSString* const USER_PHONE = nil;
    
    [MobileAppTracker setPhoneNumber:USER_PHONE];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_PHONE_MD5 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_PHONE_SHA1 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_PHONE_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_USER_PHONE );
}

- (void)testPhoneNumberNonEnglishCharacters
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    id mat = [[MobileAppTracker class] performSelector:@selector(sharedManager)];
    MATSettings *sharedParams = [mat performSelector:@selector(parameters)];
#pragma clang diagnostic pop
    
    NSString* expected = nil;
    NSString *input = nil;
    NSString *actual = nil;
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"1234567890"; // normal English
    [MobileAppTracker setPhoneNumber:input];
    waitFor(0.1);
    actual = sharedParams.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"+123-456.7890"; // English with symbols
    [MobileAppTracker setPhoneNumber:input];
    waitFor(0.1);
    actual = sharedParams.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"637c0f48d8b173fff8cad875f8f9fc53"; // MD5 hash of "0033111223355"
    input = @"00 33 1 11 22 33 55"; // English numbers with spaces
    [MobileAppTracker setPhoneNumber:input];
    waitFor(0.1);
    actual = sharedParams.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"637c0f48d8b173fff8cad875f8f9fc53"; // MD5 hash of "0033111223355"
    input = @"00-33-1-11-22-33-55"; // English numbers with hyphens
    [MobileAppTracker setPhoneNumber:input];
    waitFor(0.1);
    actual = sharedParams.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"१२३४५६७८९०"; // Devanagari
    [MobileAppTracker setPhoneNumber:input];
    waitFor(0.1);
    actual = sharedParams.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"+१२३.४५६.७८९०"; // Devanagari with symbols
    [MobileAppTracker setPhoneNumber:input];
    waitFor(0.1);
    actual = sharedParams.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"١٢٣٤٥٦٧٨٩٠"; // Arabic
    [MobileAppTracker setPhoneNumber:input];
    waitFor(0.1);
    actual = sharedParams.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"(١٢٣)٤٥٦-٧.٨.٩ ٠"; // Arabic with symbols
    [MobileAppTracker setPhoneNumber:input];
    waitFor(0.1);
    actual = sharedParams.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"၁၂-၃၄-၅၆၇.၈၉ ၀"; // Burmese with symbols
    [MobileAppTracker setPhoneNumber:input];
    waitFor(0.1);
    actual = sharedParams.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"１２３４５６７８９０"; // Full-width characters
    [MobileAppTracker setPhoneNumber:input];
    waitFor(0.1);
    actual = sharedParams.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
    
    expected = @"e807f1fcf82d132f9bb018ca6738a19f"; // MD5 hash of "1234567890"
    input = @"(１２３)４５６-７８９０"; // Full-width characters with symbols
    [MobileAppTracker setPhoneNumber:input];
    waitFor(0.1);
    actual = sharedParams.phoneNumberMd5;
    XCTAssertEqualObjects(expected, actual, @"Phone number MD5 hash values should have matched");
}

- (void)testFacebookUserId
{
    static NSString* const ID = @"testId";
    
    [MobileAppTracker setFacebookUserId:ID];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_FACEBOOK_USER_ID, ID );
}

- (void)testTwitterUserId
{
    static NSString* const ID = @"testId";
    
    [MobileAppTracker setTwitterUserId:ID];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_TWITTER_USER_ID, ID );
}

- (void)testGoogleUserId
{
    static NSString* const ID = @"testId";
    
    [MobileAppTracker setGoogleUserId:ID];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_GOOGLE_USER_ID, ID );
}

- (void)testPayingUser
{
    [MobileAppTracker setPayingUser:YES];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_IS_PAYING_USER, [@TRUE stringValue] );
    XCTAssertTrue( [MobileAppTracker isPayingUser], @"should be a paying user" );
}

- (void)testPayingUserAutomatic
{
    [MobileAppTracker setPayingUser:NO];
    
    MATEvent *evt = [MATEvent eventWithName:@"testEvent"];
    evt.revenue = 1.;
    evt.currencyCode = @"USD";
    
    [MobileAppTracker measureEvent:evt];
    
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_IS_PAYING_USER, [@TRUE stringValue] );
    XCTAssertTrue( [MobileAppTracker isPayingUser], @"should be a paying user" );
}

- (void)testPayingUserFalse
{
    [MobileAppTracker setPayingUser:NO];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_IS_PAYING_USER, [@FALSE stringValue] );
    XCTAssertFalse( [MobileAppTracker isPayingUser], @"should not be a paying user" );
}


// TODO: move this to new class for internal params testing
#pragma mark - iAd attribution

- (void)testiAdAttribution
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    id mat = [[MobileAppTracker class] performSelector:@selector(sharedManager)];
    MATSettings *sharedParams = [mat performSelector:@selector(parameters)];
#pragma clang diagnostic pop
    
    sharedParams.iadAttribution = @(TRUE);
    
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_IAD_ATTRIBUTION, [@(TRUE) stringValue] );
}


- (void)testiAdAttributionAppendTrue
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    id mat = [[MobileAppTracker class] performSelector:@selector(sharedManager)];
    MATSettings *settings = [mat performSelector:@selector(parameters)];
#pragma clang diagnostic pop
    
    double iAdCallbackDelay = 2.;
    
    settings.iadAttribution = nil;
    [MobileAppTracker measureSession];
    waitFor( iAdCallbackDelay );
    
    settings.iadAttribution = @TRUE;
    waitFor( MAT_SESSION_QUEUING_DELAY - iAdCallbackDelay + MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertTrue( [params checkKey:MAT_KEY_IAD_ATTRIBUTION isEqualToValue:[@(TRUE) stringValue]],
                  @"should have set iad_attribution to true" );
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
