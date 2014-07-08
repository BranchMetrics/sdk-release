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
    
    [MobileAppTracker initializeWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
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
    [MobileAppTracker measureSession];
    waitFor( 6. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION );
}

-(void) testUpdate
{
    [MobileAppTracker setExistingUser:TRUE];
    [MobileAppTracker measureSession];
    waitFor( 6. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION );
    ASSERT_KEY_VALUE( @"existing_user", [@TRUE stringValue] );
}


-(void) testInstallPostConversion
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    id mat = [[MobileAppTracker class] performSelector:@selector(sharedManager)];
    waitFor( 1. );
    [mat performSelector:@selector(trackInstallPostConversion)];
#pragma clang diagnostic pop
    
    waitFor( 6. );
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_INSTALL );
    ASSERT_KEY_VALUE( @"post_conversion", @"1" );
}


-(void) testURLOpen
{
    static NSString* const openUrl = @"myapp://something/something?some=stuff&something=else";
    static NSString* const sourceApplication = @"Mail";
    [MobileAppTracker applicationDidOpenURL:openUrl sourceApplication:sourceApplication];

    [MobileAppTracker measureSession];
    waitFor( 6. );

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION );
    ASSERT_KEY_VALUE( @"referral_url", openUrl );
    ASSERT_KEY_VALUE( @"referral_source", sourceApplication );
}


#pragma mark - Arbitrary actions

-(void) testActionNameEvent
{
    static NSString* const eventName = @"testEventName";
    [MobileAppTracker measureAction:eventName];
    waitFor( 3. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_name", eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

-(void) testActionNameId
{
    static NSString* const eventName = @"103";
    [MobileAppTracker measureAction:eventName];
    waitFor( 3. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_id", eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}


-(void) testActionNameIdReference
{
    static NSString* const eventName = @"103";
    static NSString* const referenceId = @"abcdefg";
    [MobileAppTracker measureAction:eventName referenceId:referenceId];
    waitFor( 3. );
    
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
    [MobileAppTracker measureAction:eventName revenueAmount:revenue currencyCode:currencyCode];
    waitFor( 3. );
    
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

    [MobileAppTracker measureAction:eventName
                        referenceId:referenceId
                      revenueAmount:revenue
                       currencyCode:currencyCode];
    waitFor( 3. );
    
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
    
    [MobileAppTracker measureAction:eventName eventItems:items];
    waitFor( 3. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
}


-(void) testActionNameIdItemsDictionary
{
    static NSString* const eventName = @"103";
    NSArray *items = @[@{@"quantity":@1.415}];
    
    [MobileAppTracker measureAction:eventName eventItems:items];
    waitFor( 3. );

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

    [MobileAppTracker measureAction:eventName eventItems:items referenceId:referenceId];
    waitFor( 3. );
    
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
    
    [MobileAppTracker measureAction:eventName
                         eventItems:items
                      revenueAmount:revenue
                       currencyCode:currencyCode];
    waitFor( 3. );
    
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

    [MobileAppTracker measureAction:eventName
                         eventItems:items
                        referenceId:referenceId
                      revenueAmount:revenue
                       currencyCode:currencyCode];
    waitFor( 3. );
    
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
    
    [MobileAppTracker measureAction:eventName
                         eventItems:items
                        referenceId:referenceId
                      revenueAmount:revenue
                       currencyCode:currencyCode
                   transactionState:transactionState];
    waitFor( 3. );
    
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

    [MobileAppTracker measureAction:eventName
                         eventItems:items
                        referenceId:referenceId
                      revenueAmount:revenue
                       currencyCode:currencyCode
                   transactionState:transactionState
                            receipt:receiptData];
    waitFor( 3. );
    
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
    [MobileAppTracker measureAction:eventName];
    waitFor( 3. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_name", eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


#pragma mark - Reserved actions

-(void) testInstallActionEvent
{
    [MobileAppTracker measureAction:EVENT_INSTALL];
    waitFor( 6. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}


-(void) testUpdateActionEvent
{
    [MobileAppTracker measureAction:EVENT_UPDATE];
    waitFor( 6. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}


-(void) testCloseActionEvent
{
    [MobileAppTracker measureAction:EVENT_CLOSE];
    waitFor( 3. );
    
    XCTAssertTrue( [params checkIsEmpty], @"'%@' action should be ignored", EVENT_CLOSE );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}


-(void) testOpenActionEvent
{
    [MobileAppTracker measureAction:EVENT_OPEN];
    waitFor( 6. );

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION);
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


-(void) testSessionActionEvent
{
    [MobileAppTracker measureAction:EVENT_SESSION];
    waitFor( 6. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION);
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


// "click" events are treated the same as arbitrary event names
-(void) testClickActionEvent
{
    [MobileAppTracker measureAction:EVENT_CLICK];
    waitFor( 3. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_name", EVENT_CLICK );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


// "conversion" events are treated the same as arbitrary event names
-(void) testConversionActionEvent
{
    [MobileAppTracker measureAction:EVENT_CONVERSION];
    waitFor( 3. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_name", EVENT_CONVERSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


// "registration" events are treated the same as arbitrary event names
-(void) testRegistrationActionEvent
{
    static NSString* const eventName = @"registration";
    
    [MobileAppTracker measureAction:eventName];
    waitFor( 3. );
    
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

    [MobileAppTracker measureAction:eventName revenueAmount:revenue currencyCode:currencyCode];
    waitFor( 3. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_name", eventName );
    ASSERT_KEY_VALUE( @"revenue", expectedRevenue );
    ASSERT_KEY_VALUE( @"currency_code", currencyCode );
}


-(void) testTwoEvents
{
    [MobileAppTracker measureSession];
    waitFor( 6. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_SESSION );

    params = [MATTestParams new];
    
    static NSString* const eventName = @"testEventName";
    [MobileAppTracker measureAction:eventName];
    waitFor( 3. );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( @"action", EVENT_CONVERSION );
    ASSERT_KEY_VALUE( @"site_event_name", eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


#pragma mark - MAT delegate

// secret functions to test server URLs
-(void) _matSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    XCTAssertTrue( [params extractParamsString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsJSON:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
