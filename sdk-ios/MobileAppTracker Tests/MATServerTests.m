//
//  MATServerTests.m
//  MobileAppTracker
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MATTests.h"
#import "../MobileAppTracker/MobileAppTracker.h"
#import "../MobileAppTracker/Common/MATTracker.h"

@interface MATServerTests : XCTestCase <MobileAppTrackerDelegate>
{
    BOOL callSuccess;
    BOOL callFailed;
    BOOL callFailedDuplicate;
}

@end


@implementation MATServerTests

- (void)setUp
{
    waitFor( 10. ); // wait for previous tests
    
    [super setUp];
    
    callSuccess = NO;
    callFailed = NO;
    callFailedDuplicate = NO;

    [MobileAppTracker setAllowDuplicateRequests:YES];
    [MobileAppTracker initializeWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    [MobileAppTracker setDelegate:self];

    emptyRequestQueue();
}

- (void)tearDown
{
    [super tearDown];

    [MobileAppTracker setAllowDuplicateRequests:NO];
    [MobileAppTracker setDebugMode:NO];

    emptyRequestQueue();
}

- (void)testInstall
{
    [MobileAppTracker measureSession];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( callSuccess, @"measureSession should have succeeded" );
    XCTAssertFalse( callFailed, @"measureSession should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureSession should have succeeded" );
}

- (void)testInstallPostConversion
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    id mat = [[MobileAppTracker class] performSelector:@selector(sharedManager)];
    waitFor( 0.1 ); // let it initialize
    [mat performSelector:@selector(trackInstallPostConversion)];
#pragma clang diagnostic pop
    
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( callSuccess, @"trackInstallPostConversion should have succeeded" );
    XCTAssertFalse( callFailed, @"trackInstallPostConversion should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"trackInstallPostConversion should have succeeded" );
}

- (void)testUpdate
{
    [MobileAppTracker setExistingUser:YES];
    [MobileAppTracker measureSession];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( callSuccess, @"trackUpdate should have succeeded" );
    XCTAssertFalse( callFailed, @"trackUpdate should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"trackUpdate should have succeeded" );
}

- (void)testActionNameEvent
{
    static NSString* const eventName = @"testEventName";
    [MobileAppTracker measureAction:eventName];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( callSuccess, @"measureAction should have succeeded" );
    XCTAssertFalse( callFailed, @"measureAction should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureAction should have succeeded" );
}

- (void)testActionNameEventDuplicate
{
    static NSString* const eventName = @"testEventName";
    [MobileAppTracker measureAction:eventName];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( callSuccess, @"measureAction should have succeeded" );
    XCTAssertFalse( callFailed, @"measureAction should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureAction should have succeeded" );

    [MobileAppTracker setAllowDuplicateRequests:NO];
    waitFor( 5. );

    [MobileAppTracker measureAction:eventName];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertFalse( callSuccess, @"measureAction duplicate should not have succeeded" );
    XCTAssertTrue( callFailed, @"measureAction duplicate should not have succeeded" );
    XCTAssertTrue( callFailedDuplicate, @"measureAction duplicate should not have succeeded" );
}

- (void)testActionNameIdItemsRevenue
{
    static NSString* const eventName = @"testEventName";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static CGFloat revenue = 3.14159;
    static NSString* const currencyCode = @"XXX";
    
    [MobileAppTracker measureAction:eventName
                         eventItems:items
                      revenueAmount:revenue
                       currencyCode:currencyCode];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );

    XCTAssertTrue( callSuccess, @"measureAction with items should have succeeded" );
    XCTAssertFalse( callFailed, @"measureAction with items should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureAction with items should have succeeded" );
}

- (void)testPurchaseDuplicates
{
    [MobileAppTracker setAllowDuplicateRequests:NO];

    [MobileAppTracker measureAction:@"purchase" referenceId:[[NSUUID UUID] UUIDString] revenueAmount:1. currencyCode:@"USD"];
    waitFor( 5. );
    XCTAssertTrue( callSuccess, @"measureAction with revenue should have succeeded" );
    XCTAssertFalse( callFailed, @"measureAction with revenue should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureAction with revenue should have succeeded" );

    callSuccess = NO;
    
    [MobileAppTracker measureAction:@"purchase" referenceId:[[NSUUID UUID] UUIDString] revenueAmount:1. currencyCode:@"USD"];
    waitFor( 5. );
    XCTAssertTrue( callSuccess, @"measureAction with revenue should have succeeded" );
    XCTAssertFalse( callFailed, @"measureAction with revenue should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureAction with revenue should have succeeded" );
}


#pragma mark - MAT delegate

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

// secret functions to test server URLs
- (void)_matURLTestingCallbackWithParamsToBeEncrypted:(NSString*)paramsEncrypted withPlaintextParams:(NSString*)paramsPlaintext
{
    //NSLog( @"plaintext params %@, encrypted params %@\n", paramsPlaintext, paramsEncrypted );
}

- (void)_matSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    //NSLog( @"requesting with url %@ and post data %@\n", trackingUrl, postData );
}

@end
