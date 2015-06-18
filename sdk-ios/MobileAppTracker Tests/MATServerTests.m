//
//  MATServerTests.m
//  MobileAppTracker
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MATTestsHelper.h"
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
    [mat performSelector:@selector(measureInstallPostConversion)];
#pragma clang diagnostic pop
    
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( callSuccess, @"measureInstallPostConversion should have succeeded" );
    XCTAssertFalse( callFailed, @"measureInstallPostConversion should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureInstallPostConversion should have succeeded" );
}

- (void)testUpdate
{
    [MobileAppTracker setExistingUser:YES];
    [MobileAppTracker measureSession];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( callSuccess, @"update session event should have succeeded" );
    XCTAssertFalse( callFailed, @"update session event should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"update session event should have succeeded" );
}

- (void)testActionNameEvent
{
    static NSString* const eventName = @"testEventName";
    [MobileAppTracker measureEventName:eventName];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( callSuccess, @"measureEventName should have succeeded" );
    XCTAssertFalse( callFailed, @"measureEventName should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureEventName should have succeeded" );
}

- (void)testActionNameEventDuplicate
{
    static NSString* const eventName = @"testEventName";
    [MobileAppTracker measureEventName:eventName];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( callSuccess, @"measureEventName should have succeeded" );
    XCTAssertFalse( callFailed, @"measureEventName should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureEventName should have succeeded" );

    [MobileAppTracker setAllowDuplicateRequests:NO];
    waitFor( 5. );

    [MobileAppTracker measureEventName:eventName];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertFalse( callSuccess, @"measureEventName duplicate should not have succeeded" );
    XCTAssertTrue( callFailed, @"measureEventName duplicate should not have succeeded" );
    XCTAssertTrue( callFailedDuplicate, @"measureEventName duplicate should not have succeeded" );
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
    
    MATEvent *event1 = [MATEvent eventWithName:eventName];
    event1.eventItems = items;
    event1.revenue = revenue;
    event1.currencyCode = currencyCode;
    [MobileAppTracker measureEvent:event1];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );

    XCTAssertTrue( callSuccess, @"measureEvent with items should have succeeded" );
    XCTAssertFalse( callFailed, @"measureEvent with items should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureEvent with items should have succeeded" );
}

- (void)testPurchaseDuplicates
{
    [MobileAppTracker setAllowDuplicateRequests:NO];

    MATEvent *event1 = [MATEvent eventWithName:@"purchase"];
    event1.refId = [[NSUUID UUID] UUIDString];
    event1.revenue = 1.;
    event1.currencyCode = @"USD";
    [MobileAppTracker measureEvent:event1];
    waitFor( 5. );
    XCTAssertTrue( callSuccess, @"measureEvent with revenue should have succeeded" );
    XCTAssertFalse( callFailed, @"measureEvent with revenue should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureEvent with revenue should have succeeded" );

    callSuccess = NO;
    
    MATEvent *event2 = [MATEvent eventWithName:@"purchase"];
    event2.refId = [[NSUUID UUID] UUIDString];
    event2.revenue = 1.;
    event2.currencyCode = @"USD";
    [MobileAppTracker measureEvent:event2];
    waitFor( 5. );
    XCTAssertTrue( callSuccess, @"measureEvent with revenue should have succeeded" );
    XCTAssertFalse( callFailed, @"measureEvent with revenue should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureEvent with revenue should have succeeded" );
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
