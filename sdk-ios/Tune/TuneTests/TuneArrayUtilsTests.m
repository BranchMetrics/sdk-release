//
//  TestArrayUtilsTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneArrayUtils.h"
#import "TuneXCTestCase.h"

@interface TuneArrayUtilsTests : TuneXCTestCase

@end

@implementation TuneArrayUtilsTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testAreAllArrayElementsOfTypeReturnsFalseWhenElementsAreNotOfSameType {
    NSArray *array = @[ @"1", @2, @"3" ];
    XCTAssertFalse([TuneArrayUtils areAllElementsOfArray:array ofType:[NSString class]]);
    XCTAssertFalse([TuneArrayUtils areAllElementsOfArray:array ofType:[NSNumber class]]);
}

- (void)testAreAllArrayElementsOfTypeReturnsTrueWhenElementsAreOfSameType {
    NSArray *array = @[ @"1", @"2", @"3" ];
    XCTAssertTrue([TuneArrayUtils areAllElementsOfArray:array ofType:[NSString class]]);
    
    NSArray *array2 = @[ @1, @3, @10 ];
    XCTAssertTrue([TuneArrayUtils areAllElementsOfArray:array2 ofType:[NSNumber class]]);
}

- (void)testArrayContainsString {
    NSArray *array = @[ @"1", @2, @"3" ];
    XCTAssertTrue([TuneArrayUtils array:array containsString:@"1"]);
    XCTAssertFalse([TuneArrayUtils array:array containsString:nil]);
    XCTAssertFalse([TuneArrayUtils array:array containsString:(id)[NSNull null]]);
    XCTAssertFalse([TuneArrayUtils array:array containsString:@"2"]);
    XCTAssertFalse([TuneArrayUtils array:array containsString:(NSString *)@2]);
}

@end
