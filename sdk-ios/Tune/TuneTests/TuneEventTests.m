//
//  TuneEventTests.m
//  Tune
//
//  Created by Harshal Ogale on 4/27/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <AdSupport/AdSupport.h>

#import "Tune+Testing.h"
#import "TuneAnalyticsVariable.h"
#import "TuneEvent+Internal.h"
#import "TuneEventKeys.h"
#import "TuneKeyStrings.h"
#import "TuneLog.h"
#import "TuneManager.h"
#import "TuneNetworkUtils.h"
#import "TuneTestParams.h"
#import "TuneTracker.h"
#import "TuneXCTestCase.h"

#import <OCMock/OCMock.h>

@interface TuneEventTests : TuneXCTestCase <TuneDelegate> {
    TuneTestParams *params;
    id classMockTuneNetworkUtils;
}

@end

@implementation TuneEventTests

- (void)setUp {
    [super setUp];

    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId];
    [Tune setDelegate:self];
    
    // Wait for everything to be set
    waitForQueuesToFinish();
    
    params = [TuneTestParams new];
    
    __block BOOL forcedNetworkStatus = YES;
    classMockTuneNetworkUtils = OCMClassMock([TuneNetworkUtils class]);
    OCMStub(ClassMethod([classMockTuneNetworkUtils isNetworkReachable])).andDo(^(NSInvocation *invocation) {
        [invocation setReturnValue:&forcedNetworkStatus];
    });
}

- (void)tearDown {
    TuneLog.shared.logBlock = nil;
    [classMockTuneNetworkUtils stopMocking];
    emptyRequestQueue();
    TuneLog.shared.logBlock = nil;
    
    [super tearDown];
}

#pragma mark - Event parameters

- (void)testNilEventName {
    __block BOOL logCalled = NO;
    
    TuneLog.shared.logBlock = ^(NSString *message) {
        if ([message containsString:@"ERROR"]) {
            XCTAssertTrue([message containsString:@"Event name cannot be nil."]);
        }
        logCalled = YES;
    };
    
    NSString *eventName = nil;
    TuneEvent *evt = [TuneEvent eventWithName:eventName];
    [Tune measureEvent:evt];
    waitForQueuesToFinish();
    
    XCTAssert(logCalled);
}


- (void)testEmptyEventName {
    __block BOOL logCalled = NO;
    
    TuneLog.shared.logBlock = ^(NSString *message) {
        if ([message containsString:@"ERROR"]) {
            XCTAssertTrue([message containsString:@"Event name cannot be empty."]);
        }
        logCalled = YES;
    };
    
    NSString *eventName = @"";
    TuneEvent *evt = [TuneEvent eventWithName:eventName];
    [Tune measureEvent:evt];
    waitForQueuesToFinish();

    XCTAssert(logCalled);
}

- (void)testContentType {
    NSString *contentType = @"atrnoeiarsdneiofphyou";

    TuneEvent *evt = [TuneEvent eventWithName:@"purchase"];
    evt.contentType = contentType;

    [Tune measureEvent:evt];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_EVENT_CONTENT_TYPE, contentType );
}

- (void)testContentId {
    NSString *contentId = @"atrnoeiarsdneiofphyou";

    TuneEvent *evt = [TuneEvent eventWithName:@"purchase"];
    evt.contentId = contentId;

    [Tune measureEvent:evt];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_EVENT_CONTENT_ID, contentId );
}

- (void)testLevel {
    NSInteger level = 13;

    TuneEvent *evt = [TuneEvent eventWithName:@"purchase"];
    evt.level = level;

    [Tune measureEvent:evt];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_EVENT_LEVEL, [@(level) stringValue] );
    XCTAssertTrue([evt.levelObject isEqualToNumber:@(level)]);
}

- (void)testQuantity {
    NSInteger quantity = 13;

    TuneEvent *evt = [TuneEvent eventWithName:@"purchase"];
    evt.quantity = quantity;

    [Tune measureEvent:evt];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_EVENT_QUANTITY, [@(quantity) stringValue] );
    XCTAssertTrue([evt.quantityObject isEqualToNumber:@(quantity)]);
}

- (void)testSearchString {
    NSString *searchString = @"atrnoeiarsdneiofphyou";

    TuneEvent *evt = [TuneEvent eventWithName:@"purchase"];
    evt.searchString = searchString;

    [Tune measureEvent:evt];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_EVENT_SEARCH_STRING, searchString );
}

- (void)testRating {
    CGFloat rating = 3.14;

    TuneEvent *evt = [TuneEvent eventWithName:@"purchase"];
    evt.rating = rating;

    [Tune measureEvent:evt];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_EVENT_RATING, [@(rating) stringValue] );
}

- (void)testDates {
    NSDate *date1 = [NSDate dateWithTimeIntervalSinceNow:234098];
    NSString *date1String = [NSString stringWithFormat:@"%ld", (long)round( [date1 timeIntervalSince1970] )];
    NSDate *date2 = [NSDate dateWithTimeIntervalSinceNow:890945.23];
    NSString *date2String = [NSString stringWithFormat:@"%ld", (long)round( [date2 timeIntervalSince1970] )];

    TuneEvent *evt = [TuneEvent eventWithName:@"purchase"];
    evt.date1 = date1;
    evt.date2 = date2;

    [Tune measureEvent:evt];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_EVENT_DATE1, date1String );
    ASSERT_KEY_VALUE( TUNE_KEY_EVENT_DATE2, date2String );
}


#pragma mark - Event Attributes

- (void)testEventAttributes {
    NSString *attr1 = @"eventAttr1";
    NSString *attr2 = @"eventAttr2";
    NSString *attr3 = @"eventAttr3";
    NSString *attr4 = @"eventAttr4";
    NSString *attr5 = @"eventAttr5";

    TuneEvent *evt = [TuneEvent eventWithName:@"registration"];
    evt.attribute1 = attr1;
    evt.attribute2 = attr2;
    evt.attribute3 = attr3;
    evt.attribute4 = attr4;
    evt.attribute5 = attr5;

    [Tune measureEvent:evt];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB1, attr1 );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB2, attr2 );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB3, attr3 );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB4, attr4 );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB5, attr5 );
}

- (void)testEventAttributesEmpty {
    NSString *attr = TUNE_STRING_EMPTY;

    TuneEvent *evt = [TuneEvent eventWithName:@"registration"];
    evt.attribute1 = attr;
    evt.attribute2 = attr;
    evt.attribute3 = attr;
    evt.attribute4 = attr;
    evt.attribute5 = attr;

    [Tune measureEvent:evt];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB1, attr );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB2, attr );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB3, attr );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB4, attr );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB5, attr );
}

- (void)testEventAttributesNil {
    TuneEvent *evt = [TuneEvent eventWithName:@"registration"];
    evt.attribute1 = nil;
    evt.attribute2 = nil;
    evt.attribute3 = nil;
    evt.attribute4 = nil;
    evt.attribute5 = nil;

    [Tune measureEvent:evt];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_ATTRIBUTE_SUB1 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_ATTRIBUTE_SUB2 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_ATTRIBUTE_SUB3 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_ATTRIBUTE_SUB4 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_ATTRIBUTE_SUB5 );

}

- (void)testEventAttributesLong {
    NSString *attr1 = @"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001";
    NSString *attr2 = @"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002";
    NSString *attr3 = @"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003";
    NSString *attr4 = @"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004";
    NSString *attr5 = @"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005";

    TuneEvent *evt = [TuneEvent eventWithName:@"registration"];
    evt.attribute1 = attr1;
    evt.attribute2 = attr2;
    evt.attribute3 = attr3;
    evt.attribute4 = attr4;
    evt.attribute5 = attr5;

    [Tune measureEvent:evt];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB1, attr1 );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB2, attr2 );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB3, attr3 );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB4, attr4 );
    ASSERT_KEY_VALUE( TUNE_KEY_ATTRIBUTE_SUB5, attr5 );
}

- (void)testEventAttributesCleared {
    NSString *attr1 = @"eventAttr1";
    NSString *attr2 = @"eventAttr2";
    NSString *attr3 = @"eventAttr3";
    NSString *attr4 = @"eventAttr4";
    NSString *attr5 = @"eventAttr5";

    TuneEvent *evt = [TuneEvent eventWithName:@"search"];
    evt.attribute1 = attr1;
    evt.attribute2 = attr2;
    evt.attribute3 = attr3;
    evt.attribute4 = attr4;
    evt.attribute5 = attr5;

    [Tune measureEvent:evt];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_EVENT_ATTRIBUTE_SUB1, attr1 );
    ASSERT_KEY_VALUE( TUNE_KEY_EVENT_ATTRIBUTE_SUB2, attr2 );
    ASSERT_KEY_VALUE( TUNE_KEY_EVENT_ATTRIBUTE_SUB3, attr3 );
    ASSERT_KEY_VALUE( TUNE_KEY_EVENT_ATTRIBUTE_SUB4, attr4 );
    ASSERT_KEY_VALUE( TUNE_KEY_EVENT_ATTRIBUTE_SUB5, attr5 );

    params = [TuneTestParams new];
    [Tune measureEventName:@"search"];
    waitForQueuesToFinish();

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_EVENT_ATTRIBUTE_SUB1 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_EVENT_ATTRIBUTE_SUB2 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_EVENT_ATTRIBUTE_SUB3 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_EVENT_ATTRIBUTE_SUB4 );
    ASSERT_NO_VALUE_FOR_KEY( TUNE_KEY_EVENT_ATTRIBUTE_SUB5 );
}

- (void)testPredefinedEventStrings {
    NSString *strAchievementUnlocked = @"achievement_unlocked";
    NSString *strAddedPaymentInfo = @"added_payment_info";
    NSString *strAddToCart = @"add_to_cart";
    NSString *strAddToWishlist = @"add_to_wishlist";
    NSString *strCheckoutInitiated = @"checkout_initiated";
    NSString *strContentView = @"content_view";
    NSString *strInvite = @"invite";
    NSString *strLevelAchieved = @"level_achieved";
    NSString *strLogin = @"login";
    NSString *strPurchase = @"purchase";
    NSString *strRated = @"rated";
    NSString *strRegistration = @"registration";
    NSString *strReservation = @"reservation";
    NSString *strSearch = @"search";
    NSString *strShare = @"share";
    NSString *strSpentCredits = @"spent_credits";
    NSString *strTutorialComplete = @"tutorial_complete";

    XCTAssertTrue([TUNE_EVENT_ACHIEVEMENT_UNLOCKED isEqualToString:strAchievementUnlocked]);
    XCTAssertTrue([TUNE_EVENT_ADD_TO_CART isEqualToString:strAddToCart]);
    XCTAssertTrue([TUNE_EVENT_ADD_TO_WISHLIST isEqualToString:strAddToWishlist]);
    XCTAssertTrue([TUNE_EVENT_ADDED_PAYMENT_INFO isEqualToString:strAddedPaymentInfo]);
    XCTAssertTrue([TUNE_EVENT_CHECKOUT_INITIATED isEqualToString:strCheckoutInitiated]);
    XCTAssertTrue([TUNE_EVENT_CONTENT_VIEW isEqualToString:strContentView]);
    XCTAssertTrue([TUNE_EVENT_INVITE isEqualToString:strInvite]);
    XCTAssertTrue([TUNE_EVENT_LEVEL_ACHIEVED isEqualToString:strLevelAchieved]);
    XCTAssertTrue([TUNE_EVENT_LOGIN isEqualToString:strLogin]);
    XCTAssertTrue([TUNE_EVENT_PURCHASE isEqualToString:strPurchase]);
    XCTAssertTrue([TUNE_EVENT_RATED isEqualToString:strRated]);
    XCTAssertTrue([TUNE_EVENT_REGISTRATION isEqualToString:strRegistration]);
    XCTAssertTrue([TUNE_EVENT_RESERVATION isEqualToString:strReservation]);
    XCTAssertTrue([TUNE_EVENT_SEARCH isEqualToString:strSearch]);
    XCTAssertTrue([TUNE_EVENT_SHARE isEqualToString:strShare]);
    XCTAssertTrue([TUNE_EVENT_SPENT_CREDITS isEqualToString:strSpentCredits]);
    XCTAssertTrue([TUNE_EVENT_TUTORIAL_COMPLETE isEqualToString:strTutorialComplete]);
}

- (void) testHiddenNumberSetters {
    TuneEvent *event = [TuneEvent eventWithName:@"search"];

    XCTAssertTrue(event.eventIdObject == nil);
    XCTAssertTrue(event.revenueObject == nil);
    XCTAssertTrue(event.transactionStateObject == nil);
    XCTAssertTrue(event.ratingObject == nil);
    XCTAssertTrue(event.levelObject == nil);
    XCTAssertTrue(event.quantityObject == nil);

    event.revenue = -100;
    event.rating = 5;
    event.level = 100;
    event.quantity = 2;

    XCTAssertTrue(event.eventIdObject == nil);
    XCTAssertTrue([event.revenueObject isEqualToNumber:@(-100)]);
    XCTAssertTrue([event.ratingObject isEqualToNumber:@(5)]);
    XCTAssertTrue([event.levelObject isEqualToNumber:@(100)]);
    XCTAssertTrue([event.quantityObject isEqualToNumber:@(2)]);
}


#pragma mark - Tune delegate

// secret functions to test server URLs
- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData {
    XCTAssertTrue( [params extractParamsFromQueryString:trackingUrl], @"couldn't extract params from URL: %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
