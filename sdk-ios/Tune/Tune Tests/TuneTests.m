//
//  TuneTests.m
//  Tune Tests
//
//  Created by John Bender on 12/17/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneTestsHelper.h"
#import "TuneTestParams.h"
#import "../Tune/Tune.h"
#import "../Tune/TuneEvent.h"
#import "../Tune/Common/TuneKeyStrings.h"
#import "../Tune/Common/TuneTracker.h"


@interface TuneTests : XCTestCase <TuneDelegate>
{
    TuneTestParams *params;
}

@end


@implementation TuneTests

- (void)setUp
{
    [super setUp];
    
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey];
    [Tune setDelegate:self];
    [Tune setExistingUser:NO];
    
    params = [TuneTestParams new];
    
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
    [Tune measureSession];
    waitFor( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
}

- (void)testUpdate
{
    [Tune setExistingUser:YES];
    [Tune measureSession];
    waitFor( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
    ASSERT_KEY_VALUE( TUNE_KEY_EXISTING_USER, [@TRUE stringValue] );
}

- (void)testInstallPostConversion
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    id tune = [[Tune class] performSelector:@selector(sharedManager)];
    waitFor( 1. );
    [tune performSelector:@selector(measureInstallPostConversion)];
#pragma clang diagnostic pop
    
    waitFor( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_INSTALL );
    ASSERT_KEY_VALUE( TUNE_KEY_POST_CONVERSION, @"1" );
}

- (void)testURLOpen
{
    static NSString* const openUrl = @"myapp://something/something?some=stuff&something=else";
    static NSString* const sourceApplication = @"Mail";
    [Tune applicationDidOpenURL:openUrl sourceApplication:sourceApplication];
    
    [Tune measureSession];
    waitFor( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
    ASSERT_KEY_VALUE( TUNE_KEY_REFERRAL_URL, openUrl );
    ASSERT_KEY_VALUE( TUNE_KEY_REFERRAL_SOURCE, sourceApplication );
}


#pragma mark - Arbitrary actions

- (void)testActionNameEvent
{
    static NSString* const eventName = @"testEventName";
    [Tune measureEventName:eventName];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventId
{
    NSInteger eventId = 931661820;
    NSString *strEventId = [@(eventId) stringValue];
    
    [Tune measureEventId:eventId];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testActionEventNameAllDigits
{
    static NSString* const eventName = @"103";
    [Tune measureEventName:eventName];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testActionEventIdReference
{
    NSInteger eventId = 931661820;
    NSString *strEventId = [@(eventId) stringValue];
    
    static NSString* const referenceId = @"abcdefg";
    
    TuneEvent *evt = [TuneEvent eventWithId:eventId];
    evt.refId = referenceId;
    
    [Tune measureEvent:evt];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_KEY_VALUE( TUNE_KEY_REF_ID, referenceId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testActionEventNameRevenueCurrency
{
    static NSString* const eventName = @"103";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    
    TuneEvent *evt = [TuneEvent eventWithName:eventName];
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    
    [Tune measureEvent:evt];
    
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_KEY_VALUE( TUNE_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( TUNE_KEY_CURRENCY_CODE, currencyCode );
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
    
    TuneEvent *evt = [TuneEvent eventWithId:eventId];
    evt.refId = referenceId;
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    
    [Tune measureEvent:evt];
    
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_ID, strEventId );
    ASSERT_KEY_VALUE( TUNE_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( TUNE_KEY_CURRENCY_CODE, currencyCode );
    ASSERT_KEY_VALUE( TUNE_KEY_REF_ID, referenceId );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testEventNameSpaces
{
    static NSString* const eventName = @"test event name";
    [Tune measureEventName:eventName];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testEventNameApostrophe
{
    static NSString* const eventName = @"I'm an event name";
    [Tune measureEventName:eventName];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


#pragma mark - Reserved actions

- (void)testInstallActionEvent
{
    [Tune measureEventName:TUNE_EVENT_INSTALL];
    waitFor( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testUpdateActionEvent
{
    [Tune measureEventName:TUNE_EVENT_UPDATE];
    waitFor( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testCloseActionEvent
{
    [Tune measureEventName:TUNE_EVENT_CLOSE];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkIsEmpty], @"'%@' action should be ignored", TUNE_EVENT_CLOSE );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
}

- (void)testOpenActionEvent
{
    [Tune measureEventName:TUNE_EVENT_OPEN];
    waitFor( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION);
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

- (void)testSessionActionEvent
{
    [Tune measureEventName:TUNE_EVENT_SESSION];
    waitFor( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION);
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_name" );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

// "click" events are treated the same as arbitrary event names
- (void)testClickActionEvent
{
    [Tune measureEventName:TUNE_EVENT_CLICK];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, TUNE_EVENT_CLICK );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

// "conversion" events are treated the same as arbitrary event names
- (void)testConversionActionEvent
{
    [Tune measureEventName:TUNE_EVENT_CONVERSION];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, TUNE_EVENT_CONVERSION );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

// "registration" events are treated the same as arbitrary event names
- (void)testRegistrationActionEvent
{
    static NSString* const eventName = @"registration";
    
    [Tune measureEventName:eventName];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}

// "purchase" events are treated the same as arbitrary event names
- (void)testPurchaseActionEvent
{
    static NSString* const eventName = @"purchase";
    static CGFloat revenue = 3.14159;
    NSString *expectedRevenue = [@(revenue) stringValue];
    static NSString* const currencyCode = @"XXX";
    
    TuneEvent *evt = [TuneEvent eventWithName:eventName];
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    
    [Tune measureEvent:evt];
    
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName );
    ASSERT_KEY_VALUE( TUNE_KEY_REVENUE, expectedRevenue );
    ASSERT_KEY_VALUE( TUNE_KEY_CURRENCY_CODE, currencyCode );
}

- (void)testTwoEvents
{
    static NSString* const eventName1 = @"testEventName1";
    [Tune measureEventName:eventName1];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName1 );
    
    params = [TuneTestParams new];
    
    static NSString* const eventName2 = @"testEventName2";
    [Tune measureEventName:eventName2];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_CONVERSION );
    ASSERT_KEY_VALUE( TUNE_KEY_SITE_EVENT_NAME, eventName2 );
    ASSERT_NO_VALUE_FOR_KEY( @"site_event_id" );
}


#pragma mark - Tune delegate

// secret functions to test server URLs
- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
