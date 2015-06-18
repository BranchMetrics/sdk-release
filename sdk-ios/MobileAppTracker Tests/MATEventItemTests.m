//
//  MATEventItemTests.m
//  MobileAppTracker
//
//  Created by Harshal Ogale on 1/24/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MATTestsHelper.h"
#import "MATTestParams.h"
#import "../MobileAppTracker/Common/MobileAppTracker_internal.h"
#import "../MobileAppTracker/Common/MATTracker.h"
#import "../MobileAppTracker/Common/MATKeyStrings.h"

@interface MATEventItemTests : XCTestCase <MobileAppTrackerDelegate>
{
    MATTestParams *params;
}

@end

@implementation MATEventItemTests

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

#pragma mark - MATEventItem Tests

- (void)testActionEventIdItems
{
    NSInteger eventId = 931661820;
    NSString *strEventId = [@(eventId) stringValue];
    
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSUInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    
    MATEvent *evt = [MATEvent eventWithId:eventId];
    evt.eventItems = items;
    
    [MobileAppTracker measureEvent:evt];
    
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
    
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.eventItems = items;
    
    [MobileAppTracker measureEvent:evt];
    
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertTrue( [params checkNoDataItems], @"should not send dictionary event items" );
}

- (void)testActionEventNameItemsReference
{
    static NSString* const eventName = @"103";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSUInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static NSString* const referenceId = @"abcdefg";
    
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.eventItems = items;
    evt.refId = referenceId;
    
    [MobileAppTracker measureEvent:evt];
    
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
    static NSUInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.eventItems = items;
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    
    [MobileAppTracker measureEvent:evt];
    
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
    static NSUInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static NSString* const referenceId = @"abcdefg";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.eventItems = items;
    evt.refId = referenceId;
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    
    [MobileAppTracker measureEvent:evt];
    
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
    static NSUInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static NSString* const referenceId = @"abcdefg";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    static NSInteger const transactionState = 98101;
    NSString *expectedTransactionState = [@(transactionState) stringValue];
    
    MATEvent *evt = [MATEvent eventWithId:eventId];
    evt.eventItems = items;
    evt.refId = referenceId;
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    evt.transactionState = transactionState;
    
    [MobileAppTracker measureEvent:evt];
    
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
    static NSUInteger const itemQuantity = 42;
    MATEventItem *item = [MATEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static NSString* const referenceId = @"abcdefg";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    static NSInteger const transactionState = 98101;
    NSString *expectedTransactionState = [@(transactionState) stringValue];
    NSData *receiptData = [@"myEventReceipt" dataUsingEncoding:NSUTF8StringEncoding];
    
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.eventItems = items;
    evt.refId = referenceId;
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    evt.transactionState = transactionState;
    evt.receipt = receiptData;
    
    [MobileAppTracker measureEvent:evt];
    
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


#pragma mark - MobileAppTracker delegate

// secret functions to test server URLs
- (void)_matSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
