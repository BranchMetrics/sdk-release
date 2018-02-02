//
//  TuneAutoParameterizationTests.m
//  Tune
//
//  Created by John Bender on 12/19/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AdSupport/AdSupport.h>
#import "TuneTestParams.h"
#import "Tune+Testing.h"
#import "TuneKeyStrings.h"
#import "TuneTestParams.h"
#import "TuneUserProfileKeys.h"
#import "TuneManager.h"
#import "TuneXCTestCase.h"

@interface TuneAutoParameterizationTests : TuneXCTestCase <TuneDelegate> {
    TuneTestParams *params;
    
    BOOL finished;
}

@end


@implementation TuneAutoParameterizationTests

- (void)setUp {
    [super setUp];

    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId wearable:NO];
    [Tune setDelegate:self];

    params = [TuneTestParams new];

    emptyRequestQueue();
}

- (void)tearDown {
    emptyRequestQueue();
    
    [super tearDown];
}

#pragma mark - IFV

- (void)testChangeIFV {
    NSUUID *newIfv = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
    
    [Tune setAppleVendorIdentifier:newIfv];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_IOS_IFV, [newIfv UUIDString] );
}

- (void)testIFVTrueNil {
    [Tune setAppleVendorIdentifier:nil];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

- (void)testIFVEmpty {
    [Tune setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:@""]];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

- (void)testIFVGarbage {
    [Tune setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:@"abc"]];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

- (void)testIFVLong {
    [Tune setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:@"0000000000000000000000000000000000000000000000000000000000000000000000"]];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}

- (void)testIFVZero {
    [Tune setAppleVendorIdentifier:[[NSUUID alloc] initWithUUIDString:TUNE_KEY_GUID_EMPTY]];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_IOS_IFV, TUNE_KEY_GUID_EMPTY );
}

- (void)testNoAutoGenerateIFV {
    // turning off auto-generate IFV should clear a previously user-defined IFV
    
    NSUUID *newIfv = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
    
    [Tune setAppleVendorIdentifier:newIfv];
    [Tune setShouldAutoGenerateAppleVendorIdentifier:NO];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertFalse( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifv"], @"should not have set an IFV (%@)", [params valueForKey:@"ios_ifv"] );
}


#pragma mark - IFA

- (void)testChangeIFA {
    NSUUID *newIfa = [[NSUUID alloc] initWithUUIDString:@"68753A44-4D6F-1226-9C60-0050E4C00067"];
    
    [Tune setAppleAdvertisingIdentifier:newIfa advertisingTrackingEnabled:YES];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_IOS_IFA, [newIfa UUIDString] );
}

- (void)testIFATrueNil {
    [Tune setAppleAdvertisingIdentifier:nil
             advertisingTrackingEnabled:YES];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifa"], @"should not have set an IFA (%@)", [params valueForKey:@"ios_ifa"] );
}

- (void)testIFAEmpty {
    [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:@""]
             advertisingTrackingEnabled:YES];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifa"], @"should not have set an IFA (%@)", [params valueForKey:@"ios_ifa"] );
}

- (void)testIFAGarbage {
    [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:@"abc"]
             advertisingTrackingEnabled:YES];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check should have failed: %@", params );
    XCTAssertFalse( [params checkKeyHasValue:@"ios_ifa"], @"should not have set an IFA (%@)", [params valueForKey:@"ios_ifa"] );
}

- (void)testIFAZero {
    [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:TUNE_KEY_GUID_EMPTY]
             advertisingTrackingEnabled:YES];
    [Tune measureEventName:@"registration"];
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_IOS_IFA );
}


#pragma mark - Tune delegate

// secret functions to test server URLs
- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData {
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
