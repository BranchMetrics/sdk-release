//
//  TuneDateUtilsTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 3/8/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TuneDateUtils.h"
#import "TuneXCTestCase.h"

@interface TuneDateUtilsTests : TuneXCTestCase

@end

@implementation TuneDateUtilsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testDateIsBetween {
    NSDate *dt = [NSDate date];
    
    XCTAssertTrue([TuneDateUtils date:dt isBetweenDate:dt andEndDate:dt]);
    
    XCTAssertTrue([TuneDateUtils date:dt isBetweenDate:[dt dateByAddingTimeInterval:-120] andEndDate:[dt dateByAddingTimeInterval:120]]);
    XCTAssertTrue([TuneDateUtils date:[dt dateByAddingTimeInterval:120] isBetweenDate:[dt dateByAddingTimeInterval:-120] andEndDate:[dt dateByAddingTimeInterval:120]]);
    XCTAssertTrue([TuneDateUtils date:[dt dateByAddingTimeInterval:-120] isBetweenDate:[dt dateByAddingTimeInterval:-120] andEndDate:[dt dateByAddingTimeInterval:120]]);
    XCTAssertFalse([TuneDateUtils date:[dt dateByAddingTimeInterval:120.1] isBetweenDate:[dt dateByAddingTimeInterval:-120] andEndDate:[dt dateByAddingTimeInterval:120]]);
    XCTAssertFalse([TuneDateUtils date:[dt dateByAddingTimeInterval:-120.1] isBetweenDate:[dt dateByAddingTimeInterval:-120] andEndDate:[dt dateByAddingTimeInterval:120]]);
}

- (void)testDaysBetween {
    NSDate *dt = [NSDate date];
    
    XCTAssertEqual(0, [TuneDateUtils daysBetween:dt and:dt]);
    
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 1;
    
    NSDateComponents *twoDayComponent = [[NSDateComponents alloc] init];
    twoDayComponent.day = 2;
    
    NSDateComponents *dayAgoComponent = [[NSDateComponents alloc] init];
    dayAgoComponent.day = -1;
    
    NSDateComponents *twoDaysAgoComponent = [[NSDateComponents alloc] init];
    twoDaysAgoComponent.day = -2;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *oneDayLater = [calendar dateByAddingComponents:dayComponent toDate:dt options:0];
    NSDate *twoDaysLater = [calendar dateByAddingComponents:twoDayComponent toDate:dt options:0];
    NSDate *oneDayAgo = [calendar dateByAddingComponents:dayAgoComponent toDate:dt options:0];
    NSDate *twoDaysAgo = [calendar dateByAddingComponents:twoDaysAgoComponent toDate:dt options:0];
    
    XCTAssertEqual(1, [TuneDateUtils daysBetween:dt and:oneDayLater]);
    XCTAssertEqual(2, [TuneDateUtils daysBetween:dt and:twoDaysLater]);
    
    XCTAssertEqual(-1, [TuneDateUtils daysBetween:dt and:oneDayAgo]);
    XCTAssertEqual(-2, [TuneDateUtils daysBetween:dt and:twoDaysAgo]);
}

@end
