//
//  MATAutoParameterizationTests.m
//  MobileAppTracker
//
//  Created by John Bender on 12/19/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AdSupport/AdSupport.h>
#import "MATTestsHelper.h"
#import "MATTestParams.h"
#import "../MobileAppTracker/MobileAppTracker.h"

@interface MATAutoParameterizationTests : XCTestCase <MobileAppTrackerDelegate>
{
    MATTestParams *params;
}

@end


@implementation MATAutoParameterizationTests

- (void)setUp
{
    [super setUp];

    params = [MATTestParams new];

    emptyRequestQueue();
}

- (void)tearDown
{
    [super tearDown];

    [MobileAppTracker setAppleVendorIdentifier:[[UIDevice currentDevice] identifierForVendor]];
    [MobileAppTracker setAppleAdvertisingIdentifier:[[ASIdentifierManager sharedManager] advertisingIdentifier]
                         advertisingTrackingEnabled:[[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]];

    emptyRequestQueue();
}

- (void)commonSetup
{
    networkOnline();
    
    [MobileAppTracker initializeWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    MobileAppTracker.delegate = self;
}


#pragma mark - IFV

- (void)testChangeIFV
{
    [self commonSetup];
    NSUUID *newIfv = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
    
    [MobileAppTracker setAppleVendorIdentifier:newIfv];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_IOS_IFV, [newIfv UUIDString] );
}

- (void)testIFVNil
{
    [self commonSetup];
    [MobileAppTracker setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:nil]];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_IOS_IFV, @"00000000-0000-0000-0000-000000000000" );
}

- (void)testIFVTrueNil
{
    [self commonSetup];
    [MobileAppTracker setAppleVendorIdentifier:nil];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

- (void)testIFVEmpty
{
    [self commonSetup];
    [MobileAppTracker setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:@""]];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

- (void)testIFVGarbage
{
    [self commonSetup];
    [MobileAppTracker setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:@"abc"]];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

- (void)testIFVLong
{
    [self commonSetup];
    [MobileAppTracker setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:@"0000000000000000000000000000000000000000000000000000000000000000000000"]];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

- (void)testIFVZero
{
    [self commonSetup];
    [MobileAppTracker setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"]];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_IOS_IFV, @"00000000-0000-0000-0000-000000000000" );
}

- (void)testNoAutoGenerateIFV
{
    // turning off auto-generate IFV should clear a previously user-defined IFV
    
    [self commonSetup];
    NSUUID *newIfv = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
    
    [MobileAppTracker setAppleVendorIdentifier:newIfv];
    [MobileAppTracker setShouldAutoGenerateAppleVendorIdentifier:NO];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}


#pragma mark - IFA

- (void)testChangeIFA
{
    [self commonSetup];
    NSUUID *newIfa = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
    
    [MobileAppTracker setAppleAdvertisingIdentifier:newIfa advertisingTrackingEnabled:YES];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_IOS_IFA, [newIfa UUIDString] );
}

- (void)testIFANil
{
    [self commonSetup];
    [MobileAppTracker setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:nil]
                         advertisingTrackingEnabled:YES];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_IOS_IFA, @"00000000-0000-0000-0000-000000000000" );
}

- (void)testIFATrueNil
{
    [self commonSetup];
    [MobileAppTracker setAppleAdvertisingIdentifier:nil
                         advertisingTrackingEnabled:YES];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifa"], @"should not have set an IFA (%@)", [params valueForKey:@"ios_ifa"] );
}

- (void)testIFAEmpty
{
    [self commonSetup];
    [MobileAppTracker setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:@""]
                         advertisingTrackingEnabled:YES];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifa"], @"should not have set an IFA (%@)", [params valueForKey:@"ios_ifa"] );
}

- (void)testIFAGarbage
{
    [self commonSetup];
    [MobileAppTracker setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:@"abc"]
                         advertisingTrackingEnabled:YES];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifa"], @"should not have set an IFA (%@)", [params valueForKey:@"ios_ifa"] );
}

- (void)testIFAZero
{
    [self commonSetup];
    [MobileAppTracker setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"]
                         advertisingTrackingEnabled:YES];
    [MobileAppTracker measureEventName:@"registration"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_IOS_IFA, @"00000000-0000-0000-0000-000000000000" );
}


#pragma mark - MAT delegate

// secret functions to test server URLs
- (void)_matSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
