//
//  MATTrackerInitializationTests.m
//  MobileAppTracker
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MATTracker.h"
#import "MATSettings.h"
#import "MATTests.h"
#import "MATTestParams.h"

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


-(void) testAutodetectJailbroken
{
    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    [mat trackSession];
    
    waitFor( 0.1 );
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( KEY_OS_JAILBROKE, @"0" );
}

-(void) testNotAutodetectJailbroken
{
    [mat setShouldAutoDetectJailbroken:NO];
    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    [mat trackSession];
    
    waitFor( 0.1 );
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( KEY_OS_JAILBROKE );
}


-(void) testAutogenerateIFV
{
    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    [mat trackSession];
    
    waitFor( 0.1 );
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( KEY_IOS_IFV, [[[UIDevice currentDevice] identifierForVendor] UUIDString] );
}

-(void) testNotAutogenerateIFV
{
    [mat setShouldAutoGenerateAppleVendorIdentifier:NO];
    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    [mat trackSession];
    
    waitFor( 0.1 );
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( KEY_IOS_IFV );
}


#pragma mark - MAT delegate

/*
-(void) mobileAppTrackerDidSucceedWithData:(NSData *)data
{
    //NSLog( @"test received success with %@\n", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] );
    callSuccess = TRUE;
}

-(void) mobileAppTrackerDidFailWithError:(NSError *)error
{
    callFailed = TRUE;
    
    NSString *serverString = [error localizedDescription];
    
    if( [serverString rangeOfString:@"Duplicate request detected."].location != NSNotFound )
        callFailedDuplicate = TRUE;
    else
        NSLog( @"test received failure with %@\n", error );
}
 */

// secret functions to test server URLs
-(void) _matURLTestingCallbackWithParamsToBeEncrypted:(NSString*)paramsEncrypted withPlaintextParams:(NSString*)paramsPlaintext
{
    XCTAssertTrue( [params extractParamsString:paramsPlaintext], @"couldn't extract unencrypted params: %@", paramsPlaintext );
    XCTAssertTrue( [params extractParamsString:paramsEncrypted], @"couldn't extract encypted params: %@", paramsEncrypted );
}

-(void) _matSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    XCTAssertTrue( [queryString extractParamsString:trackingUrl], @"couldn't extract from tracking URL %@", trackingUrl );
    if( postData ) {
        XCTAssertTrue( [params extractParamsJSON:postData], @"couldn't extract POST JSON: %@", postData );
        XCTAssertTrue( [queryString extractParamsJSON:postData], @"couldn't extract POST JSON %@", postData );
    }
    //NSLog( @"%@", trackingUrl );
}

@end
