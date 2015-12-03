//
//  TuneAutoParameterizationTests.m
//  Tune
//
//  Created by John Bender on 12/19/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AdSupport/AdSupport.h>
#import "TuneTestsHelper.h"
#import "TuneTestParams.h"
#import "../Tune/Tune.h"
#import "../Tune/Common/TuneKeyStrings.h"

@interface TuneAutoParameterizationTests : XCTestCase <TuneDelegate>
{
    TuneTestParams *params;
    
    BOOL finished;
}

@end


@implementation TuneAutoParameterizationTests

- (void)setUp
{
    [super setUp];
    
    finished = NO;
    
    params = [TuneTestParams new];

    emptyRequestQueue();
}

- (void)tearDown
{
    finished = NO;
    
    [Tune setAppleVendorIdentifier:[[UIDevice currentDevice] identifierForVendor]];
    [Tune setAppleAdvertisingIdentifier:[[ASIdentifierManager sharedManager] advertisingIdentifier]
             advertisingTrackingEnabled:[[ASIdentifierManager sharedManager] isAdvertisingTrackingEnabled]];

    emptyRequestQueue();
    
    [super tearDown];
}

- (void)commonSetup
{
    networkOnline();
    
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey];
    [Tune setDelegate:self];
}

#pragma mark - TuneDelegate Methods

- (void)tuneDidSucceedWithData:(NSData *)data
{
    finished = YES;
}

- (void)tuneDidFailWithError:(NSError *)error
{
    finished = YES;
}


#pragma mark - IFV

- (void)testChangeIFV
{
    [self commonSetup];
    NSUUID *newIfv = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
    
    [Tune setAppleVendorIdentifier:newIfv];
    [Tune measureEventName:@"registration"];
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_IOS_IFV, [newIfv UUIDString] );
}

- (void)testIFVTrueNil
{
    [self commonSetup];
    [Tune setAppleVendorIdentifier:nil];
    [Tune measureEventName:@"registration"];
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

- (void)testIFVEmpty
{
    [self commonSetup];
    [Tune setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:@""]];
    [Tune measureEventName:@"registration"];
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

- (void)testIFVGarbage
{
    [self commonSetup];
    [Tune setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:@"abc"]];
    [Tune measureEventName:@"registration"];
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

- (void)testIFVLong
{
    [self commonSetup];
    [Tune setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:@"0000000000000000000000000000000000000000000000000000000000000000000000"]];
    [Tune measureEventName:@"registration"];
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

- (void)testIFVZero
{
    [self commonSetup];
    [Tune setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:TUNE_KEY_GUID_EMPTY]];
    [Tune measureEventName:@"registration"];
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_IOS_IFV, TUNE_KEY_GUID_EMPTY );
}

- (void)testNoAutoGenerateIFV
{
    // turning off auto-generate IFV should clear a previously user-defined IFV
    
    [self commonSetup];
    NSUUID *newIfv = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
    
    [Tune setAppleVendorIdentifier:newIfv];
    [Tune setShouldAutoGenerateAppleVendorIdentifier:NO];
    [Tune measureEventName:@"registration"];
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}


#pragma mark - IFA

- (void)testChangeIFA
{
    [self commonSetup];
    NSUUID *newIfa = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
    
    [Tune setAppleAdvertisingIdentifier:newIfa advertisingTrackingEnabled:YES];
    [Tune measureEventName:@"registration"];
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_IOS_IFA, [newIfa UUIDString] );
}

- (void)testIFATrueNil
{
    [self commonSetup];
    [Tune setAppleAdvertisingIdentifier:nil
             advertisingTrackingEnabled:YES];
    [Tune measureEventName:@"registration"];
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifa"], @"should not have set an IFA (%@)", [params valueForKey:@"ios_ifa"] );
}

- (void)testIFAEmpty
{
    [self commonSetup];
    [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:@""]
             advertisingTrackingEnabled:YES];
    [Tune measureEventName:@"registration"];
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifa"], @"should not have set an IFA (%@)", [params valueForKey:@"ios_ifa"] );
}

- (void)testIFAGarbage
{
    [self commonSetup];
    [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:@"abc"]
             advertisingTrackingEnabled:YES];
    [Tune measureEventName:@"registration"];
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifa"], @"should not have set an IFA (%@)", [params valueForKey:@"ios_ifa"] );
}

- (void)testIFAZero
{
    [self commonSetup];
    [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:TUNE_KEY_GUID_EMPTY]
             advertisingTrackingEnabled:YES];
    [Tune measureEventName:@"registration"];
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_IOS_IFA, TUNE_KEY_GUID_EMPTY );
}


#pragma mark - Tune delegate

// secret functions to test server URLs
- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
