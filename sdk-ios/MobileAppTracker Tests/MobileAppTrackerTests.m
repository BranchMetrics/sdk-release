//
//  MobileAppTrackerTests.m
//  MobileAppTracker Tests
//
//  Created by John Bender on 12/17/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MATTestsHelper.h"
#import "MATTestParams.h"
#import "../MobileAppTracker/MobileAppTracker.h"
#import "../MobileAppTracker/Common/MATTracker.h"
#import "../MobileAppTracker/Common/MATKeyStrings.h"

@interface MATTests : XCTestCase <MobileAppTrackerDelegate>
{
    MATTestParams *params;
}

@end


@implementation MATTests

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
    [mat performSelector:@selector(measureInstallPostConversion)];
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
    [MobileAppTracker measureEventName:eventName];
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
    
    [MobileAppTracker measureEventId:eventId];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testActionEventNameAllDigits
{
    static NSString* const eventName = @"103";
    [MobileAppTracker measureEventName:eventName];
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
    
    MATEvent *evt = [MATEvent eventWithId:eventId];
    evt.refId = referenceId;
    
    [MobileAppTracker measureEvent:evt];
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
    
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    
    [MobileAppTracker measureEvent:evt];
    
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
    
    MATEvent *evt = [MATEvent eventWithId:eventId];
    evt.refId = referenceId;
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    
    [MobileAppTracker measureEvent:evt];
    
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_KEY_VALUE( MAT_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( MAT_KEY_CURRENCY_CODE, currencyCode );
    ASSERT_KEY_VALUE( MAT_KEY_REF_ID, referenceId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testEventNameSpaces
{
    static NSString* const eventName = @"test event name";
    [MobileAppTracker measureEventName:eventName];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testEventNameApostrophe
{
    static NSString* const eventName = @"I'm an event name";
    [MobileAppTracker measureEventName:eventName];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


#pragma mark - Reserved actions

- (void)testInstallActionEvent
{
    [MobileAppTracker measureEventName:MAT_EVENT_INSTALL];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_SESSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testUpdateActionEvent
{
    [MobileAppTracker measureEventName:MAT_EVENT_UPDATE];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_SESSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testCloseActionEvent
{
    [MobileAppTracker measureEventName:MAT_EVENT_CLOSE];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkIsEmpty], @"'%@' action should be ignored", MAT_EVENT_CLOSE );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testOpenActionEvent
{
    [MobileAppTracker measureEventName:MAT_EVENT_OPEN];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_SESSION);
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testSessionActionEvent
{
    [MobileAppTracker measureEventName:MAT_EVENT_SESSION];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_SESSION);
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

// "click" events are treated the same as arbitrary event names
- (void)testClickActionEvent
{
    [MobileAppTracker measureEventName:MAT_EVENT_CLICK];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, MAT_EVENT_CLICK );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

// "conversion" events are treated the same as arbitrary event names
- (void)testConversionActionEvent
{
    [MobileAppTracker measureEventName:MAT_EVENT_CONVERSION];
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
    
    [MobileAppTracker measureEventName:eventName];
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
    
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    
    [MobileAppTracker measureEvent:evt];
    
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
    [MobileAppTracker measureEventName:eventName1];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName1 );
    
    params = [MATTestParams new];
    
    static NSString* const eventName2 = @"testEventName2";
    [MobileAppTracker measureEventName:eventName2];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( MAT_KEY_SITE_EVENT_NAME, eventName2 );
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
