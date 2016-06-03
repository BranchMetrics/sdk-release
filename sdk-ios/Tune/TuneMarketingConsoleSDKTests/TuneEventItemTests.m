//
//  TuneEventItemTests.m
//  Tune
//
//  Created by Harshal Ogale on 1/24/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Tune+Testing.h"
#import "TuneAnalyticsItem.h"
#import "TuneAnalyticsVariable.h"
#import "TuneEvent+Internal.h"
#import "TuneEventItem+Internal.h"
#import "TuneEventKeys.h"
#import "TuneKeyStrings.h"
#import "TuneLocation.h"
#import "TuneTestParams.h"
#import "TuneTracker.h"
#import "TuneUserProfileKeys.h"
#import "TuneManager.h"

#import "TuneXCTestCase.h"

@interface TuneEventItemTests : TuneXCTestCase <TuneDelegate> {
    TuneTestParams *params;
}

@end

@implementation TuneEventItemTests

- (void)setUp {
    [super setUp];

    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey];
    [Tune setDelegate:self];
    [Tune setExistingUser:NO];
    
    params = [TuneTestParams new];
    
    waitForQueuesToFinish();
}

- (void)tearDown {
    emptyRequestQueue();
    [super tearDown];
}

#pragma mark - TuneEventItem Tests

- (void)testActionEventIdItems {
    NSInteger eventId = 931661820;
    NSString *strEventId = [@(eventId) stringValue];
    
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSUInteger const itemQuantity = 42;
    TuneEventItem *item = [TuneEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    
    TuneEvent *evt = [TuneEvent eventWithId:eventId];
    evt.eventItems = items;
    
    [Tune measureEvent:evt];
    
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
}

- (void)testActionEventNameItemsDictionary {
    static NSString* const eventName = @"103";
    NSArray *items = @[@{@"quantity":@1.415}];
    
    TuneEvent *evt = [TuneEvent eventWithName:eventName];
    evt.eventItems = items;
    
    [Tune measureEvent:evt];
    
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertTrue( [params checkNoDataItems], @"should not send dictionary event items" );
}

- (void)testActionEventNameItemsReference {
    static NSString* const eventName = @"103";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSUInteger const itemQuantity = 42;
    TuneEventItem *item = [TuneEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static NSString* const referenceId = @"abcdefg";
    
    TuneEvent *evt = [TuneEvent eventWithName:eventName];
    evt.eventItems = items;
    evt.refId = referenceId;
    
    [Tune measureEvent:evt];
    
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
    ASSERT_KEY_VALUE( TUNE_KEY_REF_ID, referenceId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventNameItemsRevenue {
    static NSString* const eventName = @"103";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSUInteger const itemQuantity = 42;
    TuneEventItem *item = [TuneEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    
    TuneEvent *evt = [TuneEvent eventWithName:eventName];
    evt.eventItems = items;
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    
    [Tune measureEvent:evt];
    
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_KEY_VALUE( TUNE_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( TUNE_KEY_CURRENCY_CODE, currencyCode );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventNameItemsReferenceRevenue {
    static NSString* const eventName = @"103";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSUInteger const itemQuantity = 42;
    TuneEventItem *item = [TuneEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static NSString* const referenceId = @"abcdefg";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    
    TuneEvent *evt = [TuneEvent eventWithName:eventName];
    evt.eventItems = items;
    evt.refId = referenceId;
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    
    [Tune measureEvent:evt];
    
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_KEY_VALUE( TUNE_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( TUNE_KEY_CURRENCY_CODE, currencyCode );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
    ASSERT_KEY_VALUE( TUNE_KEY_REF_ID, referenceId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventIdItemsRevenueTransaction {
    NSInteger eventId = 931661820;
    NSString *strEventId = [@(eventId) stringValue];
    
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSUInteger const itemQuantity = 42;
    TuneEventItem *item = [TuneEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static NSString* const referenceId = @"abcdefg";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    static NSInteger const transactionState = 98101;
    NSString *expectedTransactionState = [@(transactionState) stringValue];
    
    TuneEvent *evt = [TuneEvent eventWithId:eventId];
    evt.eventItems = items;
    evt.refId = referenceId;
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    evt.transactionState = transactionState;
    
    [Tune measureEvent:evt];
    
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_KEY_VALUE( TUNE_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( TUNE_KEY_CURRENCY_CODE, currencyCode );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
    ASSERT_KEY_VALUE( TUNE_KEY_REF_ID, referenceId );
    ASSERT_KEY_VALUE( TUNE_KEY_IOS_PURCHASE_STATUS, expectedTransactionState );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testActionEventNameItemsRevenueTransactionReceipt {
    static NSString* const eventName = @"103";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSUInteger const itemQuantity = 42;
    TuneEventItem *item = [TuneEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static NSString* const referenceId = @"abcdefg";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    static NSInteger const transactionState = 98101;
    NSString *expectedTransactionState = [@(transactionState) stringValue];
    NSData *receiptData = [@"myEventReceipt" dataUsingEncoding:NSUTF8StringEncoding];
    
    TuneEvent *evt = [TuneEvent eventWithName:eventName];
    evt.eventItems = items;
    evt.refId = referenceId;
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    evt.transactionState = transactionState;
    evt.receipt = receiptData;
    
    [Tune measureEvent:evt];
    
    waitForQueuesToFinish();
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_KEY_VALUE( TUNE_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( TUNE_KEY_CURRENCY_CODE, currencyCode );
    XCTAssertTrue( [params checkDataItems:items], @"event items not equal" );
    ASSERT_KEY_VALUE( TUNE_KEY_REF_ID, referenceId );
    ASSERT_KEY_VALUE( TUNE_KEY_IOS_PURCHASE_STATUS, expectedTransactionState );
    XCTAssertTrue( [params checkReceiptEquals:receiptData], @"receipt data not equal" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testConversionToTuneAnalyticsItem {
    TuneEventItem *tuneEventItem = [TuneEventItem eventItemWithName:@"foobar" unitPrice:2.5 quantity:10];
    tuneEventItem.attribute1 = @"bingbang";
    
    TuneAnalyticsItem *item = [TuneAnalyticsItem analyticsItemFromTuneEventItem:tuneEventItem];
    
    XCTAssertTrue([item.item isEqualToString:@"foobar"], @"Value check failed: %@", item.item);
    XCTAssertTrue([item.revenue isEqualToString:@"25"], @"Value check failed: %@", item.revenue);
    XCTAssertTrue([item.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:TUNE_KEY_EVENT_ATTRIBUTE_SUB1 value:@"bingbang"]]);
}

- (void)testAddTag {
    TuneEventItem *tuneEventItem = [TuneEventItem eventItemWithName:@"foobar" unitPrice:2.5 quantity:10];
    [tuneEventItem addTag:@"stringValue" withStringValue:@"value"];
    [tuneEventItem addTag:@"booleanValue" withBooleanValue:@(1)];
    [tuneEventItem addTag:@"datetimeValue" withDateTimeValue:[NSDate dateWithTimeIntervalSince1970:0]];
    [tuneEventItem addTag:@"numberValue" withNumberValue:@(10)];
    TuneLocation *loc = [TuneLocation alloc];
    loc.longitude = @(50.2);
    loc.latitude = @(60.9);
    [tuneEventItem addTag:@"geolocationValue" withGeolocationValue:loc];
    [tuneEventItem addTag:@"versionValue" withVersionValue:@"6.6.7"];
    
    TuneAnalyticsItem *item = [TuneAnalyticsItem analyticsItemFromTuneEventItem:tuneEventItem];
    
    XCTAssertTrue([item.item isEqualToString:@"foobar"], @"Value check failed: %@", item.item);
    XCTAssertTrue([item.revenue isEqualToString:@"25"], @"Value check failed: %@", item.revenue);
    XCTAssertTrue([item.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"stringValue" value:@"value"]]);
    XCTAssertTrue([item.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"booleanValue" value:@(1) type:TuneAnalyticsVariableBooleanType]]);
    XCTAssertTrue([item.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"datetimeValue" value:[NSDate dateWithTimeIntervalSince1970:0] type:TuneAnalyticsVariableDateTimeType]]);
    XCTAssertTrue([item.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"numberValue" value:@(10) type:TuneAnalyticsVariableNumberType]]);
    XCTAssertTrue([item.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"geolocationValue" value:loc type:TuneAnalyticsVariableCoordinateType]]);
    XCTAssertTrue([item.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"versionValue" value:@"6.6.7" type:TuneAnalyticsVariableVersionType]]);
}

- (void)testPreventAddingTagsThatMatchAttributes {
    TuneEventItem *tuneEventItem = [TuneEventItem eventItemWithName:@"foobar" unitPrice:2.5 quantity:10];
    [tuneEventItem addTag:@"attribute_sub1" withStringValue:@"value"];
    [tuneEventItem addTag:@"attribute_sub2" withStringValue:@"value"];
    [tuneEventItem addTag:@"attribute_sub3" withStringValue:@"value"];
    [tuneEventItem addTag:@"attribute_sub4" withStringValue:@"value"];
    [tuneEventItem addTag:@"attribute_sub5" withStringValue:@"value"];
    
    TuneAnalyticsItem *item = [TuneAnalyticsItem analyticsItemFromTuneEventItem:tuneEventItem];

    XCTAssertFalse([item.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"attribute_sub1" value:@"value"]]);
    XCTAssertFalse([item.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"attribute_sub2" value:@"value"]]);
    XCTAssertFalse([item.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"attribute_sub3" value:@"value"]]);
    XCTAssertFalse([item.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"attribute_sub4" value:@"value"]]);
    XCTAssertFalse([item.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"attribute_sub5" value:@"value"]]);
}

- (void)testPreventAddingCustomTagsStartingWithTune {
    TuneEventItem *tuneEventItem = [TuneEventItem eventItemWithName:@"foobar" unitPrice:2.5 quantity:10];
    [tuneEventItem addTag:@"TUNE_whatever" withStringValue:@"value"];
    [tuneEventItem addTag:@"Tune_whatever" withStringValue:@"value"];
    
    TuneAnalyticsItem *item = [TuneAnalyticsItem analyticsItemFromTuneEventItem:tuneEventItem];
    
    XCTAssertFalse([item.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"TUNE_whatever" value:@"value"]]);
    XCTAssertTrue([item.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"Tune_whatever" value:@"value"]]);
}

#pragma mark - Tune delegate

// secret functions to test server URLs
- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData {
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
