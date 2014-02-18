//
//  MATServerTests.m
//  MobileAppTracker
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MobileAppTracker/MobileAppTracker.h>
#import "MATTests.h"

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
    waitFor( 10. ); // wait for previous tests - not necessary when we can reset the sharedManager
    
    [super setUp];
    
    callSuccess = FALSE;
    callFailed = FALSE;
    callFailedDuplicate = FALSE;

    [MobileAppTracker setAllowDuplicateRequests:YES];
    [MobileAppTracker startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
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


-(void) testInstall
{
    [MobileAppTracker trackSession];
    waitFor( 6. );
    XCTAssertTrue( callSuccess, @"trackSession should have succeeded" );
    XCTAssertFalse( callFailed, @"trackSession should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"trackSession should have succeeded" );
}


/* JAB 1/29/14: duplicates not being rejected now for some reason...
-(void) testInstallDuplicate
{
    [MobileAppTracker trackSession];
    waitFor( 10. );
    XCTAssertTrue( callSuccess, @"trackSession should have succeeded" );
    XCTAssertFalse( callFailed, @"trackSession should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"trackSession should have succeeded" );

    callSuccess = FALSE;
    [MobileAppTracker setAllowDuplicateRequests:NO];

    [MobileAppTracker trackSession];
    waitFor( 10. );
    XCTAssertFalse( callSuccess, @"trackSession duplicate should not have succeeded" );
    XCTAssertTrue( callFailed, @"trackSession duplicate should not have succeeded" );
    XCTAssertTrue( callFailedDuplicate, @"trackSession duplicate should not have succeeded" );
}
 */


-(void) testInstallPostConversion
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    MobileAppTracker *mat = [[MobileAppTracker class] performSelector:@selector(sharedManager)];
    [mat performSelector:@selector(trackSessionPostConversionWithReferenceId:) withObject:nil];
#pragma clang diagnostic pop
    
    waitFor( 6. );
    XCTAssertTrue( callSuccess, @"trackSessionPostConversion should have succeeded" );
    XCTAssertFalse( callFailed, @"trackSessionPostConversion should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"trackSessionPostConversion should have succeeded" );
}


-(void) testUpdate
{
    [MobileAppTracker setExistingUser:YES];
    [MobileAppTracker trackSession];
    waitFor( 6. );
    XCTAssertTrue( callSuccess, @"trackUpdate should have succeeded" );
    XCTAssertFalse( callFailed, @"trackUpdate should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"trackUpdate should have succeeded" );
}


-(void) testActionNameEvent
{
    static NSString* const eventName = @"testEventName";
    [MobileAppTracker trackActionForEventIdOrName:eventName];
    waitFor( 6. );
    XCTAssertTrue( callSuccess, @"trackAction should have succeeded" );
    XCTAssertFalse( callFailed, @"trackAction should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"trackAction should have succeeded" );
}


/* JAB 1/29/14: duplicates not being rejected now for some reason...
-(void) testActionNameEventDuplicate
{
    static NSString* const eventName = @"testEventName";
    [MobileAppTracker trackActionForEventIdOrName:eventName];
    waitFor( 1. );
    XCTAssertTrue( callSuccess, @"trackAction should have succeeded" );
    XCTAssertFalse( callFailed, @"trackAction should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"trackAction should have succeeded" );

    callSuccess = FALSE;
    [MobileAppTracker setAllowDuplicateRequests:NO];
    waitFor( 5. );

    [MobileAppTracker trackActionForEventIdOrName:eventName];
    waitFor( 1. );
    XCTAssertFalse( callSuccess, @"trackAction duplicate should not have succeeded" );
    XCTAssertTrue( callFailed, @"trackAction duplicate should not have succeeded" );
    XCTAssertTrue( callFailedDuplicate, @"trackAction duplicate should not have succeeded" );
}
*/


-(void) testActionNameIdItemsRevenue
{
    static NSString* const eventName = @"testEventName";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static CGFloat revenue = 3.14159;
    static NSString* const currencyCode = @"XXX";
    
    [MobileAppTracker trackActionForEventIdOrName:eventName
                                       eventItems:items
                                    revenueAmount:revenue
                                     currencyCode:currencyCode];
    waitFor( 1. );

    XCTAssertTrue( callSuccess, @"trackAction with items should have succeeded" );
    XCTAssertFalse( callFailed, @"trackAction with items should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"trackAction with items should have succeeded" );
}


-(void) testPurchaseDuplicates
{
    [MobileAppTracker setAllowDuplicateRequests:NO];

    [MobileAppTracker trackActionForEventIdOrName:@"purchase" referenceId:@"sword" revenueAmount:1. currencyCode:@"USD"];
    waitFor( 1. );
    XCTAssertTrue( callSuccess, @"trackAction with items should have succeeded" );
    XCTAssertFalse( callFailed, @"trackAction with items should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"trackAction with items should have succeeded" );

    callSuccess = FALSE;
    
    [MobileAppTracker trackActionForEventIdOrName:@"purchase" referenceId:@"sword" revenueAmount:1. currencyCode:@"USD"];
    waitFor( 1. );
    XCTAssertTrue( callSuccess, @"trackAction with items should have succeeded" );
    XCTAssertFalse( callFailed, @"trackAction with items should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"trackAction with items should have succeeded" );
}



#pragma mark - MAT delegate

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

// secret functions to test server URLs
/*
-(void) _matURLTestingCallbackWithParamsToBeEncrypted:(NSString*)paramsEncrypted withPlaintextParams:(NSString*)paramsPlaintext
{
    NSLog( @"plaintext params %@, encrypted params %@\n", paramsPlaintext, paramsEncrypted );
}

-(void) _matSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    NSLog( @"requesting with url %@ and post data %@\n", trackingUrl, postData );
}
*/

@end
