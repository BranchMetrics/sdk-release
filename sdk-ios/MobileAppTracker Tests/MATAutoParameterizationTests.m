//
//  MATAutoParameterizationTests.m
//  MobileAppTracker
//
//  Created by John Bender on 12/19/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AdSupport/AdSupport.h>
#import <MobileAppTracker/MobileAppTracker.h>
#import "MATTests.h"
#import "MATTestParams.h"

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


-(void) commonSetup
{
    [MobileAppTracker startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    MobileAppTracker.delegate = self;
}


#pragma mark - IFV

-(void) testChangeIFV
{
    [self commonSetup];
    NSUUID *newIfv = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
    
    [MobileAppTracker setAppleVendorIdentifier:newIfv];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"ios_ifv", [newIfv UUIDString] );
}

-(void) testIFVNil
{
    [self commonSetup];
    [MobileAppTracker setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:nil]];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"ios_ifv", @"00000000-0000-0000-0000-000000000000" );
}

-(void) testIFVTrueNil
{
    [self commonSetup];
    [MobileAppTracker setAppleVendorIdentifier:nil];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

-(void) testIFVEmpty
{
    [self commonSetup];
    [MobileAppTracker setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:@""]];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

-(void) testIFVGarbage
{
    [self commonSetup];
    [MobileAppTracker setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:@"abc"]];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

-(void) testIFVLong
{
    [self commonSetup];
    [MobileAppTracker setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:@"0000000000000000000000000000000000000000000000000000000000000000000000"]];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

-(void) testIFVZero
{
    [self commonSetup];
    [MobileAppTracker setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"]];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"ios_ifv", @"00000000-0000-0000-0000-000000000000" );
}

-(void) testNoAutoGenerateIFV
{
    // turning off auto-generate IFV should clear a previously user-defined IFV
    
    [self commonSetup];
    NSUUID *newIfv = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
    
    [MobileAppTracker setAppleVendorIdentifier:newIfv];
    [MobileAppTracker setShouldAutoGenerateAppleVendorIdentifier:NO];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}


#pragma mark - IFA

-(void) testChangeIFA
{
    [self commonSetup];
    NSUUID *newIfa = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
    
    [MobileAppTracker setAppleAdvertisingIdentifier:newIfa advertisingTrackingEnabled:YES];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"ios_ifa", [newIfa UUIDString] );
}

-(void) testIFANil
{
    [self commonSetup];
    [MobileAppTracker setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:nil]
                         advertisingTrackingEnabled:YES];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"ios_ifa", @"00000000-0000-0000-0000-000000000000" );
}

-(void) testIFATrueNil
{
    [self commonSetup];
    [MobileAppTracker setAppleAdvertisingIdentifier:nil
                         advertisingTrackingEnabled:YES];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifa"], @"should not have set an IFA (%@)", [params valueForKey:@"ios_ifa"] );
}

-(void) testIFAEmpty
{
    [self commonSetup];
    [MobileAppTracker setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:@""]
                         advertisingTrackingEnabled:YES];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifa"], @"should not have set an IFA (%@)", [params valueForKey:@"ios_ifa"] );
}

-(void) testIFAGarbage
{
    [self commonSetup];
    [MobileAppTracker setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:@"abc"]
                         advertisingTrackingEnabled:YES];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifa"], @"should not have set an IFA (%@)", [params valueForKey:@"ios_ifa"] );
}

-(void) testIFAZero
{
    [self commonSetup];
    [MobileAppTracker setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:@"00000000-0000-0000-0000-000000000000"]
                         advertisingTrackingEnabled:YES];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"ios_ifa", @"00000000-0000-0000-0000-000000000000" );
}

// what happens if we change some of these values before calling startTracker?
// need a way to stop/reset tracker first - #172

/*
 - (void)setAppAdTracking:(BOOL)enable;
 - (void)setJailbroken:(BOOL)yesorno;
 - (void)setShouldAutoDetectJailbroken:(BOOL)yesorno;
 - (void)setShouldAutoGenerateAppleAdvertisingIdentifier:(BOOL)yesorno;
 - (void)setShouldAutoGenerateAppleVendorIdentifier:(BOOL)yesorno;
 */

#pragma mark - MAT delegate

// secret functions to test server URLs
-(void) _matURLTestingCallbackWithParamsToBeEncrypted:(NSString*)paramsEncrypted withPlaintextParams:(NSString*)paramsPlaintext
{
    XCTAssertTrue( [params extractParamsString:paramsPlaintext], @"couldn't extract unencrypted params: %@", paramsPlaintext );
    XCTAssertTrue( [params extractParamsString:paramsEncrypted], @"couldn't extract encypted params: %@", paramsEncrypted );
}

-(void) _matSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    if( postData )
        XCTAssertTrue( [params extractParamsJSON:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
