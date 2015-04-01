//
//  MobileAppTracker_Tests.m
//  MobileAppTracker Tests
//
//  Created by John Bender on 12/17/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MATTests.h"
#import "MATTestParams.h"
#import "../MobileAppTracker/MobileAppTracker.h"
#import "../MobileAppTracker/Common/MATTracker.h"
#import "../MobileAppTracker/Common/MATKeyStrings.h"

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

- (void)testInstall
{
    [MobileAppTracker measureSession];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_SESSION );
}

- (void)testUpdate
{
    [MobileAppTracker setExistingUser:YES];
    [MobileAppTracker measureSession];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_SESSION );
    ASSERT_KEY_VALUE( MAT_KEY_EXISTING_USER, [@TRUE stringValue] );
}

- (void)testInstallPostConversion
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    id mat = [[MobileAppTracker class] performSelector:@selector(sharedManager)];
    waitFor( 1. );
    [mat performSelector:@selector(trackInstallPostConversion)];
#pragma clang diagnostic pop
    
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_INSTALL );
    ASSERT_KEY_VALUE( MAT_KEY_POST_CONVERSION, @"1" );
}

- (void)testURLOpen
{
    static NSString* const openUrl = @"myapp://something/something?some=stuff&something=else";
    static NSString* const sourceApplication = @"Mail";
    [MobileAppTracker applicationDidOpenURL:openUrl sourceApplication:sourceApplication];

    [MobileAppTracker measureSession];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_SESSION );
    ASSERT_KEY_VALUE( MAT_KEY_REFERRAL_URL, openUrl );
    ASSERT_KEY_VALUE( MAT_KEY_REFERRAL_SOURCE, sourceApplication );
}


#pragma mark - Arbitrary actions

- (void)testActionNameEvent
{
    static NSString* const eventName = @"testEventName";
    [MobileAppTracker measureAction:eventName];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventId
{
    NSInteger eventId = 931661820;
    NSString *strEventId = [@(eventId) stringValue];
    
    [MobileAppTracker measureActionWithEventId:eventId];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testActionEventNameAllDigits
{
    static NSString* const eventName = @"103";
    [MobileAppTracker measureAction:eventName];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventIdReference
{
    NSInteger eventId = 931661820;
    NSString *strEventId = [@(eventId) stringValue];
    
    static NSString* const referenceId = @"abcdefg";
    [MobileAppTracker measureActionWithEventId:eventId referenceId:referenceId];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_KEY_VALUE( MAT_KEY_REF_ID, referenceId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testActionEventNameRevenueCurrency
{
    static NSString* const eventName = @"103";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    [MobileAppTracker measureAction:eventName revenueAmount:revenue currencyCode:currencyCode];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_KEY_VALUE( MAT_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( MAT_KEY_CURRENCY_CODE, currencyCode );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventIdReferenceRevenue
{
    NSInteger eventId = 931661820;
    NSString *strEventId = [@(eventId) stringValue];
    
    static NSString* const referenceId = @"abcdefg";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";

    [MobileAppTracker measureActionWithEventId:eventId
                                   referenceId:referenceId
                                 revenueAmount:revenue
                                  currencyCode:currencyCode];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_KEY_VALUE( MAT_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( MAT_KEY_CURRENCY_CODE, currencyCode );
    ASSERT_KEY_VALUE( MAT_KEY_REF_ID, referenceId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testActionEventIdItems
{
    NSInteger eventId = 931661820;
    NSString *strEventId = [@(eventId) stringValue];
    
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    
    [MobileAppTracker measureActionWithEventId:eventId eventItems:items];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
}


- (void)testActionEventNameItemsDictionary
{
    static NSString* const eventName = @"103";
    NSArray *items = @[@{@"quantity":@1.415}];
    
    [MobileAppTracker measureAction:eventName eventItems:items];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertTrue( [params checkNoDataItems], @"should not send dictionary event items" );
}


- (void)testActionEventNameItemsReference
{
    static NSString* const eventName = @"103";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static NSString* const referenceId = @"abcdefg";

    [MobileAppTracker measureAction:eventName eventItems:items referenceId:referenceId];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
    ASSERT_KEY_VALUE( MAT_KEY_REF_ID, referenceId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventNameItemsRevenue
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
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_KEY_VALUE( MAT_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( MAT_KEY_CURRENCY_CODE, currencyCode );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventNameItemsReferenceRevenue
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
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_KEY_VALUE( MAT_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( MAT_KEY_CURRENCY_CODE, currencyCode );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
    ASSERT_KEY_VALUE( MAT_KEY_REF_ID, referenceId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventIdItemsRevenueTransaction
{
    NSInteger eventId = 931661820;
    NSString *strEventId = [@(eventId) stringValue];
    
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
    
    [MobileAppTracker measureActionWithEventId:eventId
                                    eventItems:items
                                   referenceId:referenceId
                                 revenueAmount:revenue
                                  currencyCode:currencyCode
                              transactionState:transactionState];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_KEY_VALUE( MAT_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( MAT_KEY_CURRENCY_CODE, currencyCode );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
    ASSERT_KEY_VALUE( MAT_KEY_REF_ID, referenceId );
    ASSERT_KEY_VALUE( MAT_KEY_IOS_PURCHASE_STATUS, expectedTransactionState );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testActionEventNameItemsRevenueTransactionReceipt
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
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_KEY_VALUE( MAT_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( MAT_KEY_CURRENCY_CODE, currencyCode );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
    ASSERT_KEY_VALUE( MAT_KEY_REF_ID, referenceId );
    ASSERT_KEY_VALUE( MAT_KEY_IOS_PURCHASE_STATUS, expectedTransactionState );
    XCTAssertTrue( [params checkReceiptEquals:receiptData], @"receipt data not equal" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


- (void)testEventNameSpaces
{
    static NSString* const eventName = @"test event name";
    [MobileAppTracker measureAction:eventName];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testEventNameApostrophe
{
    static NSString* const eventName = @"I'm an event name";
    [MobileAppTracker measureAction:eventName];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


#pragma mark - Reserved actions

- (void)testInstallActionEvent
{
    [MobileAppTracker measureAction:MAT_EVENT_INSTALL];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_SESSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testUpdateActionEvent
{
    [MobileAppTracker measureAction:MAT_EVENT_UPDATE];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_SESSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testCloseActionEvent
{
    [MobileAppTracker measureAction:MAT_EVENT_CLOSE];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkIsEmpty], @"'%@' action should be ignored", MAT_EVENT_CLOSE );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testOpenActionEvent
{
    [MobileAppTracker measureAction:MAT_EVENT_OPEN];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_SESSION);
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testSessionActionEvent
{
    [MobileAppTracker measureAction:MAT_EVENT_SESSION];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_SESSION);
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

// "click" events are treated the same as arbitrary event names
- (void)testClickActionEvent
{
    [MobileAppTracker measureAction:MAT_EVENT_CLICK];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, MAT_EVENT_CLICK );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

// "conversion" events are treated the same as arbitrary event names
- (void)testConversionActionEvent
{
    [MobileAppTracker measureAction:MAT_EVENT_CONVERSION];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, MAT_EVENT_CONVERSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


// "registration" events are treated the same as arbitrary event names
- (void)testRegistrationActionEvent
{
    static NSString* const eventName = @"registration";
    
    [MobileAppTracker measureAction:eventName];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

// "purchase" events are treated the same as arbitrary event names
- (void)testPurchaseActionEvent
{
    static NSString* const eventName = @"purchase";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";

    [MobileAppTracker measureAction:eventName revenueAmount:revenue currencyCode:currencyCode];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_KEY_VALUE( MAT_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( MAT_KEY_CURRENCY_CODE, currencyCode );
}

- (void)testTwoEvents
{
    static NSString* const eventName1 = @"testEventName1";
    [MobileAppTracker measureAction:eventName1];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName1 );

    params = [MATTestParams new];
    
    static NSString* const eventName2 = @"testEventName2";
    [MobileAppTracker measureAction:eventName2];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName2 );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


#pragma mark - MAT delegate

// secret functions to test server URLs
- (void)_matSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    XCTAssertTrue( [params extractParamsString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsJSON:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
