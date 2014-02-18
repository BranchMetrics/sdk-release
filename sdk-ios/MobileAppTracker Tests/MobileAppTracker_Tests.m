//
//  MobileAppTracker_Tests.m
//  MobileAppTracker Tests
//
//  Created by John Bender on 12/17/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MobileAppTracker/MobileAppTracker.h>
#import "MATTests.h"
#import "MATTestParams.h"
#import "MATRequestsQueue.h"
#import "MATConnectionManager.h"

@interface MobileAppTracker_Tests : XCTestCase <MobileAppTrackerDelegate>
{
    MATTestParams *params;
}

@end


@implementation MobileAppTracker_Tests

- (void)setUp
{
    [super setUp];
    
    [MobileAppTracker startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    [MobileAppTracker setDelegate:self];
    [MobileAppTracker setExistingUser:NO];

    params = [MATTestParams new];

    emptyRequestQueue();
}

- (void)tearDown
{
    [super tearDown];

    emptyRequestQueue();
}


- (void)testInitialization
{
    XCTAssertTrue( TRUE );
}


#pragma mark - Install/update

-(void) testInstall
{
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION );
}

-(void) testInstallWithReference
{
    static NSString* const referenceId = @"abcdefg";
    [MobileAppTracker trackSessionWithReferenceId:referenceId];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION );
    ASSERT_KEY_VALUE( @"advertiser_ref_id", referenceId );
}

-(void) testUpdate
{
    [MobileAppTracker setExistingUser:TRUE];
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION );
    ASSERT_KEY_VALUE( @"existing_user", [@TRUE stringValue] );
}


-(void) testInstallPostConversion
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    MobileAppTracker *mat = [[MobileAppTracker class] performSelector:@selector(sharedManager)];
    [mat performSelector:@selector(trackSessionPostConversionWithReferenceId:) withObject:nil];
#pragma clang diagnostic pop
    
    waitFor( 0.1 );
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION );
    ASSERT_KEY_VALUE( @"post_conversion", @"1" );
}


-(void) testURLOpen
{
    static NSString* const openUrl = @"myapp://something/something?some=stuff&something=else";
    static NSString* const sourceApplication = @"Mail";
    [MobileAppTracker applicationDidOpenURL:openUrl sourceApplication:sourceApplication];

    [MobileAppTracker trackSession];
    waitFor( 0.1 );

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION );
    ASSERT_KEY_VALUE( @"referral_url", openUrl );
    ASSERT_KEY_VALUE( @"referral_source", sourceApplication );
}


#pragma mark - Arbitrary actions

-(void) testActionNameEvent
{
    static NSString* const eventName = @"testEventName";
    [MobileAppTracker trackActionForEventIdOrName:eventName];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_name", eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

-(void) testActionNameId
{
    static NSString* const eventName = @"103";
    [MobileAppTracker trackActionForEventIdOrName:eventName];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_id", eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}


-(void) testActionNameIdReference
{
    static NSString* const eventName = @"103";
    static NSString* const referenceId = @"abcdefg";
    [MobileAppTracker trackActionForEventIdOrName:eventName referenceId:referenceId];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_id", eventName );
    ASSERT_KEY_VALUE( @"advertiser_ref_id", referenceId );
}

-(void) testActionNameIdRevenueCurrency
{
    static NSString* const eventName = @"103";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    [MobileAppTracker trackActionForEventIdOrName:eventName
                                    revenueAmount:revenue
                                     currencyCode:currencyCode];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_id", eventName );
    ASSERT_KEY_VALUE( @"revenue", expectedRevenue );
    ASSERT_KEY_VALUE( @"currency_code", currencyCode );
}

-(void) testActionNameIdReferenceRevenue
{
    static NSString* const eventName = @"103";
    static NSString* const referenceId = @"abcdefg";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";

    [MobileAppTracker trackActionForEventIdOrName:eventName
                                      referenceId:referenceId
                                    revenueAmount:revenue
                                     currencyCode:currencyCode];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_id", eventName );
    ASSERT_KEY_VALUE( @"revenue", expectedRevenue );
    ASSERT_KEY_VALUE( @"currency_code", currencyCode );
    ASSERT_KEY_VALUE( @"advertiser_ref_id", referenceId );
}

 -(void) testActionNameIdItems
{
    static NSString* const eventName = @"103";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    
    [MobileAppTracker trackActionForEventIdOrName:eventName eventItems:items];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
}


-(void) testActionNameIdItemsDictionary
{
    static NSString* const eventName = @"103";
    NSArray *items = @[@{@"quantity":@1.415}];
    
    [MobileAppTracker trackActionForEventIdOrName:eventName eventItems:items];
    waitFor( 0.1 );

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertTrue( [params checkNoDataItems], @"should not send dictionary event items" );
}


-(void) testActionNameIdItemsReference
{
    static NSString* const eventName = @"103";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static NSString* const referenceId = @"abcdefg";

    [MobileAppTracker trackActionForEventIdOrName:eventName
                                       eventItems:items
                                      referenceId:referenceId];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
    ASSERT_KEY_VALUE( @"advertiser_ref_id", referenceId );
}

-(void) testActionNameIdItemsRevenue
{
    static NSString* const eventName = @"103";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    
    [MobileAppTracker trackActionForEventIdOrName:eventName
                                       eventItems:items
                                    revenueAmount:revenue
                                     currencyCode:currencyCode];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_id", eventName );
    ASSERT_KEY_VALUE( @"revenue", expectedRevenue );
    ASSERT_KEY_VALUE( @"currency_code", currencyCode );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
}

-(void) testActionNameIdItemsReferenceRevenue
{
    static NSString* const eventName = @"103";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static NSString* const referenceId = @"abcdefg";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";

    [MobileAppTracker trackActionForEventIdOrName:eventName
                                       eventItems:items
                                      referenceId:referenceId
                                    revenueAmount:revenue
                                     currencyCode:currencyCode];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_id", eventName );
    ASSERT_KEY_VALUE( @"revenue", expectedRevenue );
    ASSERT_KEY_VALUE( @"currency_code", currencyCode );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
    ASSERT_KEY_VALUE( @"advertiser_ref_id", referenceId );
}

-(void) testActionNameIdItemsRevenueTransaction
{
    static NSString* const eventName = @"103";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static NSString* const referenceId = @"abcdefg";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    static NSInteger const transactionState = 98101;
    NSString *expectedTransactionState = [NSString stringWithFormat:@"%d", (int)transactionState];
    
    [MobileAppTracker trackActionForEventIdOrName:eventName
                                       eventItems:items
                                      referenceId:referenceId
                                    revenueAmount:revenue
                                     currencyCode:currencyCode
                                 transactionState:transactionState];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_id", eventName );
    ASSERT_KEY_VALUE( @"revenue", expectedRevenue );
    ASSERT_KEY_VALUE( @"currency_code", currencyCode );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
    ASSERT_KEY_VALUE( @"advertiser_ref_id", referenceId );
    ASSERT_KEY_VALUE( @"ios_purchase_status", expectedTransactionState );
}

-(void) testActionNameIdItemsRevenueTransactionReceipt
{
    static NSString* const eventName = @"103";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static NSString* const referenceId = @"abcdefg";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    static NSInteger const transactionState = 98101;
    NSString *expectedTransactionState = [NSString stringWithFormat:@"%d", (int)transactionState];
    NSData *receiptData = [@"myEventReceipt" dataUsingEncoding:NSUTF8StringEncoding];

    [MobileAppTracker trackActionForEventIdOrName:eventName
                                       eventItems:items
                                      referenceId:referenceId
                                    revenueAmount:revenue
                                     currencyCode:currencyCode
                                 transactionState:transactionState
                                          receipt:receiptData];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_id", eventName );
    ASSERT_KEY_VALUE( @"revenue", expectedRevenue );
    ASSERT_KEY_VALUE( @"currency_code", currencyCode );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
    ASSERT_KEY_VALUE( @"advertiser_ref_id", referenceId );
    ASSERT_KEY_VALUE( @"ios_purchase_status", expectedTransactionState );
    XCTAssertTrue( [params checkReceiptEquals:receiptData], @"receipt data not equal" );
}


-(void) testEventNameSpaces
{
    static NSString* const eventName = @"test event name";
    [MobileAppTracker trackActionForEventIdOrName:eventName];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_name", eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


#pragma mark - Reserved actions

-(void) testInstallActionEvent
{
    [MobileAppTracker trackActionForEventIdOrName:EVENT_INSTALL];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}


-(void) testUpdateActionEvent
{
    [MobileAppTracker trackActionForEventIdOrName:EVENT_UPDATE];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}


-(void) testCloseActionEvent
{
    [MobileAppTracker trackActionForEventIdOrName:EVENT_CLOSE];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkIsEmpty], @"'%@' action should be ignored", EVENT_CLOSE );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}


-(void) testOpenActionEvent
{
    [MobileAppTracker trackActionForEventIdOrName:EVENT_OPEN];
    waitFor( 0.1 );

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION);
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


-(void) testSessionActionEvent
{
    [MobileAppTracker trackActionForEventIdOrName:EVENT_SESSION];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION);
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


// "click" events are treated the same as arbitrary event names
-(void) testClickActionEvent
{
    [MobileAppTracker trackActionForEventIdOrName:EVENT_CLICK];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_name", EVENT_CLICK );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


// "conversion" events are treated the same as arbitrary event names
-(void) testConversionActionEvent
{
    [MobileAppTracker trackActionForEventIdOrName:EVENT_CONVERSION];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_name", EVENT_CONVERSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


// "registration" events are treated the same as arbitrary event names
-(void) testRegistrationActionEvent
{
    static NSString* const eventName = @"registration";
    
    [MobileAppTracker trackActionForEventIdOrName:eventName];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_name", eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


// "purchase" events are treated the same as arbitrary event names
-(void) testPurchaseActionEvent
{
    static NSString* const eventName = @"purchase";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";

    [MobileAppTracker trackActionForEventIdOrName:eventName
                                    revenueAmount:revenue
                                     currencyCode:currencyCode];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_name", eventName );
    ASSERT_KEY_VALUE( @"revenue", expectedRevenue );
    ASSERT_KEY_VALUE( @"currency_code", currencyCode );
}


-(void) testTwoEvents
{
    [MobileAppTracker trackSession];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION );

    params = [MATTestParams new];
    
    static NSString* const eventName = @"testEventName";
    [MobileAppTracker trackActionForEventIdOrName:eventName];
    waitFor( 0.1 );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_name", eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


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
    //NSLog( @"%@", trackingUrl );
}

@end
