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
    
    XCTAssertEqual(1, [TuneDateUtils daysBetween:dt and:[dt dateByAddingTimeInterval:86400]]);
    XCTAssertEqual(2, [TuneDateUtils daysBetween:dt and:[dt dateByAddingTimeInterval:86400 * 2]]);
    
    XCTAssertEqual(-1, [TuneDateUtils daysBetween:dt and:[dt dateByAddingTimeInterval:-86400]]);
    XCTAssertEqual(-2, [TuneDateUtils daysBetween:dt and:[dt dateByAddingTimeInterval:-86400 * 2]]);
}

@end
