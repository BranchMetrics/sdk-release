//
//  TuneAdUtilsTests.m
//  Tune
//
//  Created by Harshal Ogale on 9/4/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "../Tune/Ad/TuneAdUtils.h"
#import "../Tune/Common/TuneSettings.h"
#import "../Tune/Common/TuneTracker.h"
#import "../Tune/Common/Tune_internal.h"

@interface TuneAdUtils()

+ (NSString *)urlEncode:(id)value;

@end

@interface TuneAdUtilsTests : XCTestCase

@end

@implementation TuneAdUtilsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testItunesItemIdFromUrl {

    NSString *url = @"https://itunes.apple.com/us/app/hungry-reindeer/id550851506?mt=8";
    NSNumber *actual = [TuneAdUtils itunesItemIdFromUrl:url];
    NSNumber *expected = @550851506;
    XCTAssert([actual isEqualToNumber:expected], @"itunes app id number should have matched, expected = %@, actual = %@", expected, actual);
    
    url = @"http://itunes.apple.com/us/app/candy-crush-soda-saga/id850417475?mt=8&uo=4&at=10ltL";
    actual = [TuneAdUtils itunesItemIdFromUrl:url];
    expected = @850417475;
    XCTAssert([actual isEqualToNumber:expected], @"itunes app id number should have matched, expected = %@, actual = %@", expected, actual);
    
    url = @"itms://itunes.apple.com/us/app/candy-crush-soda-saga/id850417475?mt=8&uo=4";
    actual = [TuneAdUtils itunesItemIdFromUrl:url];
    expected = @850417475;
    XCTAssert([actual isEqualToNumber:expected], @"itunes app id number should have matched, expected = %@, actual = %@", expected, actual);
}

- (void)testItunesItemIdAndTokensFromUrl {

    NSString *url = nil;
    NSDictionary *actual = nil;
    NSDictionary *expected = nil;
    
    url = @"https://itunes.apple.com/us/album/random-access-memories/id617154241?at=123456";
    actual = [TuneAdUtils itunesItemIdAndTokensFromUrl:url];
    expected = @{@"itemId":@617154241, @"at":@"123456"};
    XCTAssert([actual isEqualToDictionary:expected], @"itunes item id, affiliate token, campaign token parsing failed, expected = %@, actual = %@", expected, actual);
    
    url = @"https://itunes.apple.com/us/app/hungry-reindeer/id550851506?mt=8&at=10ltL&ct=journey134";
    actual = [TuneAdUtils itunesItemIdAndTokensFromUrl:url];
    expected = @{@"itemId":@550851506, @"at":@"10ltL", @"ct":@"journey134"};
    XCTAssert([actual isEqualToDictionary:expected], @"itunes item id, affiliate token, campaign token parsing failed, expected = %@, actual = %@", expected, actual);
}

- (void)testDurationDelayForRetry
{
    NSUInteger retry = 0;
    NSTimeInterval expected = 0;
    NSTimeInterval actual = 0;
    
    retry = 0;
    expected = 0;
    actual = [TuneAdUtils durationDelayForRetry:retry];
    XCTAssert(actual == expected, @"unexpected delay duration for %tu retry attempt, expected = %f, actual = %f", retry, expected, actual);
    
    retry = 1;
    expected = 10;
    actual = [TuneAdUtils durationDelayForRetry:retry];
    XCTAssert(actual >= expected && actual <= (expected + expected / 10), @"unexpected delay duration for %tu retry attempt, expected = %f, actual = %f", retry, expected, actual);
    
    retry = 2;
    expected = 20;
    actual = [TuneAdUtils durationDelayForRetry:retry];
    XCTAssert(actual >= expected && actual <= (expected + expected / 10), @"unexpected delay duration for %tu retry attempt, expected = %f, actual = %f", retry, expected, actual);
    
    retry = 3;
    expected = 30;
    actual = [TuneAdUtils durationDelayForRetry:retry];
    XCTAssert(actual >= expected && actual <= (expected + expected / 10), @"unexpected delay duration for %tu retry attempt, expected = %f, actual = %f", retry, expected, actual);
    
    retry = 4;
    expected = 45;
    actual = [TuneAdUtils durationDelayForRetry:retry];
    XCTAssert(actual >= expected && actual <= (expected + expected / 10), @"unexpected delay duration for %tu retry attempt, expected = %f, actual = %f", retry, expected, actual);
    
    retry = 5;
    expected = 60;
    actual = [TuneAdUtils durationDelayForRetry:retry];
    XCTAssert(actual >= expected && actual <= (expected + expected / 10), @"unexpected delay duration for %tu retry attempt, expected = %f, actual = %f", retry, expected, actual);
    
    retry = 6;
    expected = 24*60*60;
    actual = [TuneAdUtils durationDelayForRetry:retry];
    XCTAssert(actual >= expected && actual <= (expected + expected / 10), @"unexpected delay duration for %tu retry attempt, expected = %f, actual = %f", retry, expected, actual);
    
    retry = 7;
    expected = 24*60*60;
    actual = [TuneAdUtils durationDelayForRetry:retry];
    XCTAssert(actual >= expected && actual <= (expected + expected / 10), @"unexpected delay duration for %tu retry attempt, expected = %f, actual = %f", retry, expected, actual);
    
    retry = 18;
    expected = 24*60*60;
    actual = [TuneAdUtils durationDelayForRetry:retry];
    XCTAssert(actual >= expected && actual <= (expected + expected / 10), @"unexpected delay duration for %tu retry attempt, expected = %f, actual = %f", retry, expected, actual);
}

- (void)testTuneAdServerUrl
{
    NSString *expected = nil;
    NSString *actual = nil;
    
    TuneSettings *tuneParams = [[Tune sharedManager] parameters];
    [tuneParams setAdvertiserId:@"12345"];
    
    expected = @"https://12345.request.aa.tuneapi.com/api/v1/ads/request?context[type]=banner";
    actual = [TuneAdUtils tuneAdServerUrl:TuneAdTypeBanner];
    XCTAssert([actual isEqualToString:expected], @"incorrect server url for banner ad request, expected = %@, actual = %@", expected, actual);
    
    expected = @"https://12345.request.aa.tuneapi.com/api/v1/ads/request?context[type]=interstitial";
    actual = [TuneAdUtils tuneAdServerUrl:TuneAdTypeInterstitial];
    XCTAssert([actual isEqualToString:expected], @"incorrect server url for interstitial ad request, expected = %@, actual = %@", expected, actual);
}

- (void)testTuneAdClickViewCloseUrls
{
    NSString *expected = nil;
    NSString *actual = nil;
    
    TuneSettings *tuneParams = [[Tune sharedManager] parameters];
    [tuneParams setAdvertiserId:@"12345"];
    
    TuneAd *ad = [[TuneAd alloc] init];
    ad.type = TuneAdTypeBanner;
    ad.html = @"<!DOCTYPE html><html><body>ad html body</body></html>";
    ad.duration = 11.f;
    ad.usesNativeCloseButton = YES;
    ad.color            = @"#123456";
    ad.requestId        = @"f09f6bb4-24bf-4141-878a-f973becf45bc";
    ad.refs             = @{@"siteId":@"2960",@"siteName":@"Atomic Dodge Ball",@"advertiserId":@"877",@"subPublisherId":@"877",@"subPublisherName":@"MAT Demo Account",@"subSiteId":@"2962",@"subSiteName":@"Atomic Dodge Ball Lite",@"subCampaignId":@"48",@"subCampaignName":@"Atomic Dodge Ball",@"subAdgroupId":@"50",@"subAdgroupName":@"Atomic Dodge Ball",@"subAdId":@"48",@"subAdName":@"Atomic Dodge Ball"};
    
    expected = @"https://12345.click.aa.tuneapi.com/api/v1/ads/click?action=click&requestId=f09f6bb4-24bf-4141-878a-f973becf45bc";
    actual = [TuneAdUtils tuneAdClickUrl:ad];
    XCTAssert([actual isEqualToString:expected], @"incorrect click ad url, expected = %@, actual = %@", expected, actual);
    
    expected = @"https://12345.event.aa.tuneapi.com/api/v1/ads/event?action=view&requestId=f09f6bb4-24bf-4141-878a-f973becf45bc";
    actual = [TuneAdUtils tuneAdViewUrl:ad];
    XCTAssert([actual isEqualToString:expected], @"incorrect view ad url, expected = %@, actual = %@", expected, actual);
    
    expected = @"https://12345.event.aa.tuneapi.com/api/v1/ads/event?action=close&requestId=f09f6bb4-24bf-4141-878a-f973becf45bc";
    actual = [TuneAdUtils tuneAdClosedUrl:ad];
    XCTAssert([actual isEqualToString:expected], @"incorrect close ad url, expected = %@, actual = %@", expected, actual);
}

- (void)testRequestQueryParams
{
    NSString *expected = nil;
    NSString *actual = nil;
    
    TuneSettings *tuneParams = [[Tune sharedManager] parameters];
    [tuneParams setAdvertiserId:@"12345"];
    
    TuneAd *ad = [[TuneAd alloc] init];
    ad.type = TuneAdTypeBanner;
    ad.html = @"<!DOCTYPE html><html><body>ad html body</body></html>";
    ad.duration = 11.f;
    ad.usesNativeCloseButton = YES;
    ad.color            = @"#123456";
    ad.requestId        = @"f09f6bb4-24bf-4141-878a-f973becf45bc";
    ad.refs             = @{@"siteId":@"2960",@"siteName":@"Atomic Dodge Ball",@"advertiserId":@"877",@"subPublisherId":@"877",@"subPublisherName":@"MAT Demo Account",@"subSiteId":@"2962",@"subSiteName":@"Atomic Dodge Ball Lite",@"subCampaignId":@"48",@"subCampaignName":@"Atomic Dodge Ball",@"subAdgroupId":@"50",@"subAdgroupName":@"Atomic Dodge Ball",@"subAdId":@"48",@"subAdName":@"Atomic Dodge Ball"};
    
    expected = @"requestId=f09f6bb4-24bf-4141-878a-f973becf45bc";
    actual = [TuneAdUtils requestQueryParams:ad];
    XCTAssert([actual isEqualToString:expected], @"incorrect request id query param and value, expected = %@, actual = %@", expected, actual);
}

- (void)testUrlEncode
{
    id input = nil;
    NSString * expected = nil;
    NSString * actual = nil;
    
    input = nil;
    expected = TUNE_STRING_EMPTY;
    actual = [TuneAdUtils urlEncode:input];
    XCTAssert([actual isEqualToString:expected], @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
    
    input = [NSNull null];
    expected = TUNE_STRING_EMPTY;
    actual = [TuneAdUtils urlEncode:input];
    XCTAssert([actual isEqualToString:expected], @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
    
    input = @123.456;
    expected = @"123.456";
    actual = [TuneAdUtils urlEncode:input];
    XCTAssert([actual isEqualToString:expected], @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
    
    input = @"abc.pqr@xyz.com";
    expected = @"abc.pqr%40xyz.com";
    actual = [TuneAdUtils urlEncode:input];
    XCTAssert([actual isEqualToString:expected], @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
    
    input = [NSDate dateWithTimeIntervalSince1970:1420099201];
    expected = @"1420099201";
    actual = [TuneAdUtils urlEncode:input];
    XCTAssert([actual isEqualToString:expected], @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
}

@end
