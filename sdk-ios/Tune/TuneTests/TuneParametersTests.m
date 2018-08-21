//
//  TuneParametersTests.m
//  Tune
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Tune+Testing.h"
#import "TuneEventQueue.h"
#import "TuneEvent+Internal.h"
#import "TuneKeyStrings.h"
#import "TuneManager.h"
#import "TuneNetworkUtils.h"
#import "TuneTestParams.h"
#import "TuneTracker.h"
#import "TuneUserProfile.h"
#import "TuneUserProfileKeys.h"
#import "TuneXCTestCase.h"
#import "TuneHttpUtils.h"

#import <OCMock/OCMock.h>

@interface TuneParametersTests : TuneXCTestCase <TuneDelegate> {
    TuneTestParams *params;
    id httpUtilsMock;
    id classMockTuneNetworkUtils;
}

@end

@implementation TuneParametersTests

- (void)setUp {
    [super setUp];

    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId];
    [[TuneEventQueue sharedQueue] setUnitTestCallback:^(NSString *trackingUrl, NSString *postData) {
        XCTAssertTrue([params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl);
        if (postData) {
            XCTAssertTrue([params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData);
        }
    }];
    
    waitForQueuesToFinish();
    
    params = [TuneTestParams new];
    
    __block BOOL forcedNetworkStatus = YES;
    classMockTuneNetworkUtils = OCMClassMock([TuneNetworkUtils class]);
    OCMStub(ClassMethod([classMockTuneNetworkUtils isNetworkReachable])).andDo(^(NSInvocation *invocation) {
        [invocation setReturnValue:&forcedNetworkStatus];
    });
    
    httpUtilsMock = OCMClassMock([TuneHttpUtils class]);
    
    NSHTTPURLResponse *dummyResp = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://www.tune.com"] statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
    NSError *dummyError = nil;
    OCMStub(ClassMethod([httpUtilsMock addIdentifyingHeaders:OCMOCK_ANY])).andDo(^(NSInvocation *invocation) {
        NSLog(@"mock TuneHttpUtils: ignoring addIdentifyingHeaders: call");
    });
    OCMStub(ClassMethod([httpUtilsMock sendSynchronousRequest:OCMOCK_ANY response:[OCMArg setTo:dummyResp] error:[OCMArg setTo:dummyError]])).andDo(^(NSInvocation *invocation) {
        NSLog(@"mock TuneHttpUtils: ignoring sendSynchronousRequest:response:error: call");
    });
}

- (void)tearDown {
    [Tune setPluginName:nil];

    [classMockTuneNetworkUtils stopMocking];
    [httpUtilsMock stopMocking];
    
    emptyRequestQueue();
    [[TuneEventQueue sharedQueue] setUnitTestCallback:nil];
    
    [super tearDown];
}


#pragma mark - Age

- (void)testAgeValid {
    NSInteger age = 35;
    NSString *expectedAge = [@(age) stringValue];

    [Tune setAge:age];
    
    //startDate = [NSDate date];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_AGE, expectedAge );
}

- (void)testAgeYoung {
    NSInteger age = 6;
    NSString *expectedAge = [@(age) stringValue];
    
    [Tune setAge:age];
    
    //startDate = [NSDate date];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    // redaction removes some of the default values.  Also not sure why we're checking all of them when age is the item under test
    //XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_AGE, expectedAge );
}

- (void)testAgeOld {
    NSInteger age = 65536;
    NSString *expectedAge = [@(age) stringValue];
    
    [Tune setAge:age];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_AGE, expectedAge );
}

- (void)testAgeZero {
    NSInteger age = 0;
    NSString *expectedAge = [@(age) stringValue];
    
    [Tune setAge:age];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    // redaction removes some of the default values.  Also not sure why we're checking all of them when age is the item under test
    //XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_AGE, expectedAge );
}

- (void)testAgeNegative {
    NSInteger age = -304;
    NSString *expectedAge = [@(age) stringValue];
    
    [Tune setAge:age];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    // redaction removes some of the default values.  Also not sure why we're checking all of them when age is the item under test
    //XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_AGE, expectedAge );
}


#pragma mark - Gender

- (void)testGenderMale {
    TuneGender gender = TuneGenderMale;
    NSString *expectedGender = [@(gender) stringValue];
    
    [Tune setGender:gender];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_GENDER, expectedGender );
}

- (void)testGenderFemale {
    TuneGender gender = TuneGenderFemale;
    NSString *expectedGender = [@(gender) stringValue];
    
    [Tune setGender:gender];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_GENDER, expectedGender );
}

- (void)testGenderUnknown {
    TuneGender gender = TuneGenderUnknown;
    
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
    TuneGender gender = (TuneGender)-304;
    
    [Tune setGender:gender];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_GENDER );
}


#pragma mark - Geolocation

- (void)testLatLongValid {
    double lat = 47.;
    double lon = -122.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    [Tune setLocationWithLatitude:@(lat) longitude:@(lon) altitude:nil];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongZero {
    CGFloat lat = 0.;
    CGFloat lon = 0.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    [Tune setLocationWithLatitude:@(lat) longitude:@(lon) altitude:nil];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongSmall {
    CGFloat lat = -190.;
    CGFloat lon = -190.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    [Tune setLocationWithLatitude:@(lat) longitude:@(lon) altitude:nil];
    
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
    
    [Tune setLocationWithLatitude:@(lat) longitude:@(lon) altitude:nil];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongOneSmall {
    CGFloat lat = -190.;
    CGFloat lon = 1.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    [Tune setLocationWithLatitude:@(lat) longitude:@(lon) altitude:nil];
    
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
    
    [Tune setLocationWithLatitude:@(lat) longitude:@(lon) altitude:nil];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongVeryLarge {
    CGFloat lat = 370.;
    CGFloat lon = 370.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    
    [Tune setLocationWithLatitude:@(lat) longitude:@(lon) altitude:nil];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
}

- (void)testLatLongAltValid {
    CGFloat lat = 47.;
    CGFloat lon = -122.;
    CGFloat alt = 41.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    NSString *expectedAlt = [@(alt) stringValue];
    
    [Tune setLocationWithLatitude:@(lat) longitude:@(lon) altitude:@(alt)];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
    ASSERT_KEY_VALUE( TUNE_KEY_ALTITUDE, expectedAlt );
}

- (void)testLatLongAltZero {
    CGFloat lat = 47.;
    CGFloat lon = -122.;
    CGFloat alt = 0.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    NSString *expectedAlt = [@(alt) stringValue];
    
    [Tune setLocationWithLatitude:@(lat) longitude:@(lon) altitude:@(alt)];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
    ASSERT_KEY_VALUE( TUNE_KEY_ALTITUDE, expectedAlt );
}

- (void)testLatLongAltVeryLarge {
    CGFloat lat = 47.;
    CGFloat lon = -122.;
    CGFloat alt = 999999.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    NSString *expectedAlt = [@(alt) stringValue];
    
    [Tune setLocationWithLatitude:@(lat) longitude:@(lon) altitude:@(alt)];

    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
    ASSERT_KEY_VALUE( TUNE_KEY_ALTITUDE, expectedAlt );
}

- (void)testLatLongAltVerySmall {
    CGFloat lat = 47.;
    CGFloat lon = -122.;
    CGFloat alt = -999999.;
    NSString *expectedLat = [@(lat) stringValue];
    NSString *expectedLon = [@(lon) stringValue];
    NSString *expectedAlt = [@(alt) stringValue];
    
    [Tune setLocationWithLatitude:@(lat) longitude:@(lon) altitude:@(alt)];
    
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_LATITUDE, expectedLat );
    ASSERT_KEY_VALUE( TUNE_KEY_LONGITUDE, expectedLon );
    ASSERT_KEY_VALUE( TUNE_KEY_ALTITUDE, expectedAlt );
}

#pragma mark - Plugin name

- (void)testPluginNameInvalid {
    NSString *plugin = @"yourMom";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:TUNE_KEY_SDK_PLUGIN], @"should have no value for sdk_plugin" );
}

- (void)testPluginNameEmpty {
    NSString *plugin = TUNE_STRING_EMPTY;

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
    NSString *plugin = @"air";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNameAirUppercase {
    NSString *plugin = @"AIR";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:TUNE_KEY_SDK_PLUGIN], @"should have no value for sdk_plugin" );
}

- (void)testPluginNameCocos {
    NSString *plugin = @"cocos2dx";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNameMarmalade {
    NSString *plugin = @"marmalade";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNamePhoneGap {
    NSString *plugin = @"phonegap";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNameTitanium {
    NSString *plugin = @"titanium";
    
    [Tune setPluginName:plugin];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_SDK_PLUGIN, plugin );
}

- (void)testPluginNameUnity {
    NSString *plugin = @"unity";
    
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

- (void)testExistingUser {
    [Tune setExistingUser:YES];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_EXISTING_USER, [@TRUE stringValue] );
}

- (void)testUserEmail {
    NSString *EMAIL_ID = @"tempUserEmail@tempUserCompany.com";
    NSString *EMAIL_ID_MD5 = @"d76acab60fbd9bf136f79dafb6e79a3b";
    NSString *EMAIL_ID_SHA1 = @"e6c76b523cee03fd0dfea0d769a40d1a798dd522";
    NSString *EMAIL_ID_SHA256 = @"f2bcbd4dd2b172c1dad72b0ff850e2295b01392ceab45491e97fc9e093b42d30";
    
    [Tune setUserEmail:EMAIL_ID];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_MD5, EMAIL_ID_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_SHA1, EMAIL_ID_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_SHA256, EMAIL_ID_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_EMAIL );
    
    TuneAnalyticsVariable *var = nil;
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_EMAIL];
    XCTAssertNil(var);
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
    NSString *USER_EMAIL = TUNE_STRING_EMPTY; // empty
    NSString *USER_EMAIL_MD5 = @"d41d8cd98f00b204e9800998ecf8427e";
    NSString *USER_EMAIL_SHA1 = @"da39a3ee5e6b4b0d3255bfef95601890afd80709";
    NSString *USER_EMAIL_SHA256 = @"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
    
    [Tune setUserEmail:USER_EMAIL];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_MD5, USER_EMAIL_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_SHA1, USER_EMAIL_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_EMAIL_SHA256, USER_EMAIL_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_EMAIL );
    
    TuneAnalyticsVariable *var = nil;
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_EMAIL];
    XCTAssertNil(var);
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
    NSString *USER_EMAIL = nil;
    
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
    NSString *USER_ID = @"testId";
    
    [Tune setUserId:USER_ID];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_ID, USER_ID );
}

- (void)testUserName {
    NSString *USER_NAME = @"testName";
    NSString *USER_NAME_MD5 = @"f0f7b7b21cfd4f60934753232a0049f6";
    NSString *USER_NAME_SHA1 = @"0025dd9f850ce7889cf3e79e64328d0c4957751a";
    NSString *USER_NAME_SHA256 = @"4278d90b65ee634b960c9e026e4295f8f4fd8d3f29785548552afdc71ef4b495";
    
    [Tune setUserName:USER_NAME];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_MD5, USER_NAME_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_SHA1, USER_NAME_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_SHA256, USER_NAME_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_NAME );
    
    TuneAnalyticsVariable *var = nil;
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_NAME];
    XCTAssertNil(var);
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
    NSString *USER_NAME = TUNE_STRING_EMPTY; // empty
    NSString *USER_NAME_MD5 = @"d41d8cd98f00b204e9800998ecf8427e";
    NSString *USER_NAME_SHA1 = @"da39a3ee5e6b4b0d3255bfef95601890afd80709";
    NSString *USER_NAME_SHA256 = @"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
    
    [Tune setUserName:USER_NAME];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_MD5, USER_NAME_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_SHA1, USER_NAME_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_NAME_SHA256, USER_NAME_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_NAME );
    
    TuneAnalyticsVariable *var = nil;
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_NAME];
    XCTAssertNil(var);
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
    NSString *USER_NAME = nil;
    
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
    NSString *USER_PHONE = @"1234567890";
    NSString *USER_PHONE_MD5 = @"e807f1fcf82d132f9bb018ca6738a19f";
    NSString *USER_PHONE_SHA1 = @"01b307acba4f54f55aafc33bb06bbbf6ca803e9a";
    NSString *USER_PHONE_SHA256 = @"c775e7b757ede630cd0aa1113bd102661ab38829ca52a6422ab782862f268646";
    
    [Tune setPhoneNumber:USER_PHONE];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_MD5, USER_PHONE_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_SHA1, USER_PHONE_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_SHA256, USER_PHONE_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_PHONE );
    
    TuneAnalyticsVariable *var = nil;
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_PHONE];
    XCTAssertNil(var);
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
    NSString *USER_PHONE = TUNE_STRING_EMPTY; // empty
    NSString *USER_PHONE_MD5 = @"d41d8cd98f00b204e9800998ecf8427e";
    NSString *USER_PHONE_SHA1 = @"da39a3ee5e6b4b0d3255bfef95601890afd80709";
    NSString *USER_PHONE_SHA256 = @"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
    
    [Tune setPhoneNumber:USER_PHONE];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_MD5, USER_PHONE_MD5 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_SHA1, USER_PHONE_SHA1 );
    ASSERT_KEY_VALUE( TUNE_KEY_USER_PHONE_SHA256, USER_PHONE_SHA256 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_USER_PHONE );
    
    TuneAnalyticsVariable *var = nil;
    var = [[TuneManager currentManager].userProfile getProfileVariable:TUNE_KEY_USER_PHONE];
    XCTAssertNil(var);
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
    NSString *USER_PHONE = nil;
    
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
    NSString *ID = @"testId";
    
    [Tune setFacebookUserId:ID];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_FACEBOOK_USER_ID, ID );
}

- (void)testTwitterUserId {
    NSString *ID = @"testId";
    
    [Tune setTwitterUserId:ID];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_TWITTER_USER_ID, ID );
}

- (void)testGoogleUserId {
    NSString *ID = @"testId";
    
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

@end
