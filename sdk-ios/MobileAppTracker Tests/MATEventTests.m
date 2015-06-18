//
//  MATEventTests.m
//  MobileAppTracker
//
//  Created by Harshal Ogale on 4/27/15.
//  Copyright (c) 2015 HasOffers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <AdSupport/AdSupport.h>
#import "MATTestsHelper.h"
#import "MATTestParams.h"
#import "../MobileAppTracker/MobileAppTracker.h"
#import "../MobileAppTracker/Common/MATKeyStrings.h"
#import "../MobileAppTracker/Common/MATSettings.h"
#import "../MobileAppTracker/Common/MATTracker.h"


@interface MobileAppTracker (MATEventTests)

+ (void)setPluginName:(NSString *)pluginName;

@end

@interface MATEventTests : XCTestCase <MobileAppTrackerDelegate>
{
    MATTestParams *params;
}

@end

@implementation MATEventTests

- (void)setUp
{
    [super setUp];
    
    [MobileAppTracker initializeWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    [MobileAppTracker setDelegate:self];
    
    params = [MATTestParams new];
    
    emptyRequestQueue();
    
    networkOnline();
}

- (void)tearDown
{
    [MobileAppTracker setCurrencyCode:nil];
    [MobileAppTracker setPackageName:kTestBundleId];
    [MobileAppTracker setPluginName:nil];
    
    emptyRequestQueue();
    waitFor( 10. );
    
    [super tearDown];
}

#pragma mark - Event parameters

- (void)testContentType
{
    static NSString* const contentType = @"atrnoeiarsdneiofphyou";
    
    MATEvent *evt = [MATEvent eventWithName:@"purchase"];
    evt.contentType = contentType;
    
    [MobileAppTracker measureEvent:evt];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_EVENT_CONTENT_TYPE, contentType );
}

- (void)testContentId
{
    static NSString* const contentId = @"atrnoeiarsdneiofphyou";
    
    MATEvent *evt = [MATEvent eventWithName:@"purchase"];
    evt.contentId = contentId;
    
    [MobileAppTracker measureEvent:evt];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_EVENT_CONTENT_ID, contentId );
}

- (void)testLevel
{
    static const NSInteger level = 13;
    
    MATEvent *evt = [MATEvent eventWithName:@"purchase"];
    evt.level = level;
    
    [MobileAppTracker measureEvent:evt];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_EVENT_LEVEL, [@(level) stringValue] );
}

- (void)testQuantity
{
    static const NSInteger quantity = 13;
    
    MATEvent *evt = [MATEvent eventWithName:@"purchase"];
    evt.quantity = quantity;
    
    [MobileAppTracker measureEvent:evt];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_EVENT_QUANTITY, [@(quantity) stringValue] );
}

- (void)testSearchString
{
    static NSString* const searchString = @"atrnoeiarsdneiofphyou";
    
    MATEvent *evt = [MATEvent eventWithName:@"purchase"];
    evt.searchString = searchString;
    
    [MobileAppTracker measureEvent:evt];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_EVENT_SEARCH_STRING, searchString );
}

- (void)testRating
{
    static const CGFloat rating = 3.14;
    
    MATEvent *evt = [MATEvent eventWithName:@"purchase"];
    evt.rating = rating;
    
    [MobileAppTracker measureEvent:evt];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_EVENT_RATING, [@(rating) stringValue] );
}

- (void)testDates
{
    NSDate *date1 = [NSDate dateWithTimeIntervalSinceNow:234098];
    NSString *date1String = [NSString stringWithFormat:@"%ld", (long)round( [date1 timeIntervalSince1970] )];
    NSDate *date2 = [NSDate dateWithTimeIntervalSinceNow:890945.23];
    NSString *date2String = [NSString stringWithFormat:@"%ld", (long)round( [date2 timeIntervalSince1970] )];
    
    MATEvent *evt = [MATEvent eventWithName:@"purchase"];
    evt.date1 = date1;
    evt.date2 = date2;
    
    [MobileAppTracker measureEvent:evt];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_EVENT_DATE1, date1String );
    ASSERT_KEY_VALUE( MAT_KEY_EVENT_DATE2, date2String );
}


#pragma mark - Event Attributes

- (void)testEventAttributes
{
    static NSString* const attr1 = @"eventAttr1";
    static NSString* const attr2 = @"eventAttr2";
    static NSString* const attr3 = @"eventAttr3";
    static NSString* const attr4 = @"eventAttr4";
    static NSString* const attr5 = @"eventAttr5";
    
    MATEvent *evt = [MATEvent eventWithName:@"registration"];
    evt.attribute1 = attr1;
    evt.attribute2 = attr2;
    evt.attribute3 = attr3;
    evt.attribute4 = attr4;
    evt.attribute5 = attr5;
    
    [MobileAppTracker measureEvent:evt];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB1, attr1 );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB2, attr2 );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB3, attr3 );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB4, attr4 );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB5, attr5 );
}

- (void)testEventAttributesEmpty
{
    NSString* const attr = MAT_STRING_EMPTY;
    
    MATEvent *evt = [MATEvent eventWithName:@"registration"];
    evt.attribute1 = attr;
    evt.attribute2 = attr;
    evt.attribute3 = attr;
    evt.attribute4 = attr;
    evt.attribute5 = attr;
    
    [MobileAppTracker measureEvent:evt];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB1, attr );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB2, attr );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB3, attr );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB4, attr );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB5, attr );
}

- (void)testEventAttributesNil
{
    MATEvent *evt = [MATEvent eventWithName:@"registration"];
    evt.attribute1 = nil;
    evt.attribute2 = nil;
    evt.attribute3 = nil;
    evt.attribute4 = nil;
    evt.attribute5 = nil;
    
    [MobileAppTracker measureEvent:evt];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_ATTRIBUTE_SUB1 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_ATTRIBUTE_SUB2 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_ATTRIBUTE_SUB3 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_ATTRIBUTE_SUB4 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_ATTRIBUTE_SUB5 );
    
}

- (void)testEventAttributesLong
{
    static NSString* const attr1 = @"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001";
    static NSString* const attr2 = @"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002";
    static NSString* const attr3 = @"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003";
    static NSString* const attr4 = @"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004";
    static NSString* const attr5 = @"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005";
    
    MATEvent *evt = [MATEvent eventWithName:@"registration"];
    evt.attribute1 = attr1;
    evt.attribute2 = attr2;
    evt.attribute3 = attr3;
    evt.attribute4 = attr4;
    evt.attribute5 = attr5;
    
    [MobileAppTracker measureEvent:evt];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB1, attr1 );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB2, attr2 );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB3, attr3 );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB4, attr4 );
    ASSERT_KEY_VALUE( MAT_KEY_ATTRIBUTE_SUB5, attr5 );
}

- (void)testEventAttributesCleared
{
    static NSString* const attr1 = @"eventAttr1";
    static NSString* const attr2 = @"eventAttr2";
    static NSString* const attr3 = @"eventAttr3";
    static NSString* const attr4 = @"eventAttr4";
    static NSString* const attr5 = @"eventAttr5";
    
    MATEvent *evt = [MATEvent eventWithName:@"search"];
    evt.attribute1 = attr1;
    evt.attribute2 = attr2;
    evt.attribute3 = attr3;
    evt.attribute4 = attr4;
    evt.attribute5 = attr5;
    
    [MobileAppTracker measureEvent:evt];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_EVENT_ATTRIBUTE_SUB1, attr1 );
    ASSERT_KEY_VALUE( MAT_KEY_EVENT_ATTRIBUTE_SUB2, attr2 );
    ASSERT_KEY_VALUE( MAT_KEY_EVENT_ATTRIBUTE_SUB3, attr3 );
    ASSERT_KEY_VALUE( MAT_KEY_EVENT_ATTRIBUTE_SUB4, attr4 );
    ASSERT_KEY_VALUE( MAT_KEY_EVENT_ATTRIBUTE_SUB5, attr5 );
    
    params = [MATTestParams new];
    [MobileAppTracker measureEventName:@"search"];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_EVENT_ATTRIBUTE_SUB1 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_EVENT_ATTRIBUTE_SUB2 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_EVENT_ATTRIBUTE_SUB3 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_EVENT_ATTRIBUTE_SUB4 );
    ASSERT_NO_VALUE_FOR_KEY( MAT_KEY_EVENT_ATTRIBUTE_SUB5 );
}

- (void)testPredefinedEventStrings
{
    static NSString *const strAchievementUnlocked = @"achievement_unlocked";
    static NSString *const strAddedPaymentInfo = @"added_payment_info";
    static NSString *const strAddToCart = @"add_to_cart";
    static NSString *const strAddToWishlist = @"add_to_wishlist";
    static NSString *const strCheckoutInitiated = @"checkout_initiated";
    static NSString *const strContentView = @"content_view";
    static NSString *const strInvite = @"invite";
    static NSString *const strLevelAchieved = @"level_achieved";
    static NSString *const strLogin = @"login";
    static NSString *const strPurchase = @"purchase";
    static NSString *const strRated = @"rated";
    static NSString *const strRegistration = @"registration";
    static NSString *const strReservation = @"reservation";
    static NSString *const strSearch = @"search";
    static NSString *const strShare = @"share";
    static NSString *const strSpentCredits = @"spent_credits";
    static NSString *const strTutorialComplete = @"tutorial_complete";
    
    XCTAssertEqual(MAT_EVENT_ACHIEVEMENT_UNLOCKED, strAchievementUnlocked, @"Pre-defined event should have matched \"%@\"", strAchievementUnlocked);
    XCTAssertEqual(MAT_EVENT_ADD_TO_CART, strAddToCart, @"Pre-defined event should have matched \"%@\"", strAddToCart);
    XCTAssertEqual(MAT_EVENT_ADD_TO_WISHLIST, strAddToWishlist, @"Pre-defined event should have matched \"%@\"", strAddToWishlist);
    XCTAssertEqual(MAT_EVENT_ADDED_PAYMENT_INFO, strAddedPaymentInfo, @"Pre-defined event should have matched \"%@\"", strAddedPaymentInfo);
    XCTAssertEqual(MAT_EVENT_CHECKOUT_INITIATED, strCheckoutInitiated, @"Pre-defined event should have matched \"%@\"", strCheckoutInitiated);
    XCTAssertEqual(MAT_EVENT_CONTENT_VIEW, strContentView, @"Pre-defined event should have matched \"%@\"", strContentView);
    XCTAssertEqual(MAT_EVENT_INVITE, strInvite, @"Pre-defined event should have matched \"%@\"", strInvite);
    XCTAssertEqual(MAT_EVENT_LEVEL_ACHIEVED, strLevelAchieved, @"Pre-defined event should have matched \"%@\"", strLevelAchieved);
    XCTAssertEqual(MAT_EVENT_LOGIN, strLogin, @"Pre-defined event should have matched \"%@\"", strLogin);
    XCTAssertEqual(MAT_EVENT_PURCHASE, strPurchase, @"Pre-defined event should have matched \"%@\"", strPurchase);
    XCTAssertEqual(MAT_EVENT_RATED, strRated, @"Pre-defined event should have matched \"%@\"", strRated);
    XCTAssertEqual(MAT_EVENT_REGISTRATION, strRegistration, @"Pre-defined event should have matched \"%@\"", strRegistration);
    XCTAssertEqual(MAT_EVENT_RESERVATION, strReservation, @"Pre-defined event should have matched \"%@\"", strReservation);
    XCTAssertEqual(MAT_EVENT_SEARCH, strSearch, @"Pre-defined event should have matched \"%@\"", strSearch);
    XCTAssertEqual(MAT_EVENT_SHARE, strShare, @"Pre-defined event should have matched \"%@\"", strShare);
    XCTAssertEqual(MAT_EVENT_SPENT_CREDITS, strSpentCredits, @"Pre-defined event should have matched \"%@\"", strSpentCredits);
    XCTAssertEqual(MAT_EVENT_TUTORIAL_COMPLETE, strTutorialComplete, @"Pre-defined event should have matched \"%@\"", strTutorialComplete);
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
