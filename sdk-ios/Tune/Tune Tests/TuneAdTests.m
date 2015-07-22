//
//  TuneAdTests.m
//  Tune
//
//  Created by Harshal Ogale on 9/4/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <StoreKit/StoreKit.h>
#import "../Tune/Ad/TuneAd.h"

@interface TuneAdTests : XCTestCase

@end

@implementation TuneAdTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAdBannerFromDictionary
{
    TuneAd *ad = [[TuneAd alloc] init];
    ad.type = TuneAdTypeBanner;
    ad.html = @"<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width\"></head><style>html,body,a{display:block;width:100%;height:100%;margin:0;padding:0}a{background:#000 url(http://877.media.aa.tuneapi.com/877/kosg40ytehqfflxr.png) no-repeat center center;background-size:contain}</style><body><a id=\"a\" href=\"http://itunes.apple.com/us/app/atomic-dodge-ball/id550852584\"></a><script>(window.onresize=function(){document.getElementById('a').style.backgroundImage='url('+( (window.innerWidth / window.innerHeight > 1 && window.innerWidth / window.innerHeight < 5) || window.innerWidth / window.innerHeight > 15 ?'http://877.media.aa.tuneapi.com/877/6ehl9uglxcelv7vi.png':'http://877.media.aa.tuneapi.com/877/kosg40ytehqfflxr.png')+')'})();var l=new Image(),p=new Image();l.src='http://877.media.aa.tuneapi.com/877/6ehl9uglxcelv7vi.png';p.src='http://877.media.aa.tuneapi.com/877/kosg40ytehqfflxr.png';</script></body></html>";
    ad.duration = 11.f;
    ad.usesNativeCloseButton = YES;
    ad.color            = @"#123456";
    ad.requestId        = @"f09f6bb4-24bf-4141-878a-f973becf45bc";
    ad.refs             = @{@"siteId":@"2960",@"siteName":@"Atomic Dodge Ball",@"advertiserId":@"877",@"subPublisherId":@"877",@"subPublisherName":@"MAT Demo Account",@"subSiteId":@"2962",@"subSiteName":@"Atomic Dodge Ball Lite",@"subCampaignId":@"48",@"subCampaignName":@"Atomic Dodge Ball",@"subAdgroupId":@"50",@"subAdgroupName":@"Atomic Dodge Ball",@"subAdId":@"48",@"subAdName":@"Atomic Dodge Ball"};
    
    NSString *strResponseData = @"{\"landscape\":\"http://877.media.aa.tuneapi.com/877/6ehl9uglxcelv7vi.png\",\"portrait\":\"http://877.media.aa.tuneapi.com/877/kosg40ytehqfflxr.png\",\"size\":\"contain\",\"color\":\"#123456\",\"duration\":11,\"close\":\"native\",\"url\":\"http://itunes.apple.com/us/app/atomic-dodge-ball/id550852584\",\"html\":\"<!DOCTYPE html><html lang=\\\"en\\\"><head><meta charset=\\\"utf-8\\\"><meta name=\\\"viewport\\\" content=\\\"width=device-width\\\"></head><style>html,body,a{display:block;width:100%;height:100%;margin:0;padding:0}a{background:#000 url(http://877.media.aa.tuneapi.com/877/kosg40ytehqfflxr.png) no-repeat center center;background-size:contain}</style><body><a id=\\\"a\\\" href=\\\"http://itunes.apple.com/us/app/atomic-dodge-ball/id550852584\\\"></a><script>(window.onresize=function(){document.getElementById('a').style.backgroundImage='url('+( (window.innerWidth / window.innerHeight > 1 && window.innerWidth / window.innerHeight < 5) || window.innerWidth / window.innerHeight > 15 ?'http://877.media.aa.tuneapi.com/877/6ehl9uglxcelv7vi.png':'http://877.media.aa.tuneapi.com/877/kosg40ytehqfflxr.png')+')'})();var l=new Image(),p=new Image();l.src='http://877.media.aa.tuneapi.com/877/6ehl9uglxcelv7vi.png';p.src='http://877.media.aa.tuneapi.com/877/kosg40ytehqfflxr.png';</script></body></html>\",\"refs\":{\"siteId\":\"2960\",\"siteName\":\"Atomic Dodge Ball\",\"advertiserId\":\"877\",\"subPublisherId\":\"877\",\"subPublisherName\":\"MAT Demo Account\",\"subSiteId\":\"2962\",\"subSiteName\":\"Atomic Dodge Ball Lite\",\"subCampaignId\":\"48\",\"subCampaignName\":\"Atomic Dodge Ball\",\"subAdgroupId\":\"50\",\"subAdgroupName\":\"Atomic Dodge Ball\",\"subAdId\":\"48\",\"subAdName\":\"Atomic Dodge Ball\"},\"requestId\":\"f09f6bb4-24bf-4141-878a-f973becf45bc\"}";
    
    NSData *responseData = [strResponseData dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    
    TuneAd *actual = [TuneAd ad:TuneAdTypeBanner placement:@"dashboard" metadata:nil orientations:TuneAdOrientationLandscape fromDictionary:dict];
    
    XCTAssert(actual.type == ad.type, @"ad type should have matched, expected = %d, actual = %d", (int)ad.type, (int)actual.type);
    XCTAssert(actual.duration == ad.duration, @"ad duration should have matched, expected = %f, actual = %f", (CGFloat)ad.duration, (CGFloat)actual.type);
    XCTAssert(actual.usesNativeCloseButton == ad.usesNativeCloseButton, @"ad usesNativeCloseButton should have matched, expected = %d, actual = %d", ad.usesNativeCloseButton, actual.usesNativeCloseButton);
    XCTAssert([actual.html isEqualToString:ad.html], @"ad html should have matched, expected = %@, actual = %@", ad.html, actual.html);
    XCTAssert([actual.color isEqualToString:ad.color], @"ad color should have matched, expected = %@, actual = %@", ad.color, actual.color);
    XCTAssert([actual.requestId isEqualToString:ad.requestId], @"ad requestId should have matched, expected = %@, actual = %@", ad.requestId, actual.requestId);
    XCTAssert([actual.refs isEqualToDictionary:ad.refs], @"ad refs should have matched, expected = %@, actual = %@", ad.refs, actual.refs);
}

@end
