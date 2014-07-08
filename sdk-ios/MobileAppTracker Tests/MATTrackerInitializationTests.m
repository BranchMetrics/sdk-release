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
    [mat trackActionForEventIdOrName:@"registration"];
    
    waitFor( 3. );
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( KEY_OS_JAILBROKE, @"0" );
}

-(void) testNotAutodetectJailbroken
{
    [mat setShouldAutoDetectJailbroken:NO];
    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    [mat trackActionForEventIdOrName:@"registration"];
    
    waitFor( 3. );
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( KEY_OS_JAILBROKE );
}


-(void) testAutogenerateIFV
{
    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    [mat trackActionForEventIdOrName:@"registration"];
    
    waitFor( 3. );
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( KEY_IOS_IFV, [[[UIDevice currentDevice] identifierForVendor] UUIDString] );
}

-(void) testNotAutogenerateIFV
{
    [mat setShouldAutoGenerateAppleVendorIdentifier:NO];
    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    [mat trackActionForEventIdOrName:@"registration"];
    
    waitFor( 3. );
    XCTAssertFalse( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( KEY_IOS_IFV );
}


-(void) testSendInstallReceipt
{
    static NSString* const eventName = @"fakeEventName";
    NSData *receiptData = [@"fakeReceiptDataString" dataUsingEncoding:NSUTF8StringEncoding];
    
    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    mat.parameters.openLogId = nil; // coerce receipt data into being sent again
    
    [mat trackActionForEventIdOrName:@"fakeEventName"];
    waitFor( 1. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"site_event_name", eventName );
    XCTAssertTrue( [params checkKeyHasValue:@"testAppleReceipt"], @"no Apple receipt sent" );
    XCTAssertTrue( [params checkAppleReceiptEquals:receiptData], @"Apple receipt value mismatch" );
}


-(void) testStoreUserIds
{
    static NSString *const testEmail = @"testemail";
    static NSString *const testId = @"testid";
    static NSString *const testName = @"testname";
    
    [MATUtils setUserDefaultValue:testEmail forKey:KEY_USER_EMAIL];
    [MATUtils setUserDefaultValue:testId forKey:KEY_USER_ID];
    [MATUtils setUserDefaultValue:testName forKey:KEY_USER_NAME];
    
    mat = [MATTracker new];
    mat.delegate = self;
    mat.parameters.delegate = self;

    [mat startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    [mat trackActionForEventIdOrName:@"fakeEventName"];
    waitFor( 1. );

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( KEY_USER_EMAIL, testEmail );
    ASSERT_KEY_VALUE( KEY_USER_ID, testId );
    ASSERT_KEY_VALUE( KEY_USER_NAME, testName );
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
-(void) _matSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    XCTAssertTrue( [params extractParamsString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsJSON:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
