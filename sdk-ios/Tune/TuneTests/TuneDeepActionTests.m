//
//  TuneDeepActionTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 10/1/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneDeepAction.h"
#import "TuneXCTestCase.h"

@interface TuneDeepActionTests : TuneXCTestCase

@end

@implementation TuneDeepActionTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testValidateApprovedValues {
    NSDictionary *input = nil;
  
    input = @{};
    XCTAssertFalse([TuneDeepAction validateApprovedValues:input], @"Giving an empty dictionary should return false.");
    
    input = @{@1 : @[@"foobar", @"bingbang"]};
    XCTAssertFalse([TuneDeepAction validateApprovedValues:input], @"Giving a non-string for a key should return false.");
    
    input = @{@"key" : @"value"};
    XCTAssertFalse([TuneDeepAction validateApprovedValues:input], @"Giving a non-array for the value should return false.");
    
    input = @{@"key" : @[]};
    XCTAssertFalse([TuneDeepAction validateApprovedValues:input], @"Passing an empty array should return false.");
    
    input = @{@"key" : @[@"string", @45]};
    XCTAssertFalse([TuneDeepAction validateApprovedValues:input], @"Passing a non-string in the array should return false.");
    
    input = @{@"key" : @[@"value1"]};
    XCTAssertTrue([TuneDeepAction validateApprovedValues:input], @"Passing a single value into the array should return true.");
    
    input = @{@"key" : @[@"value1", @"value23"]};
    XCTAssertTrue([TuneDeepAction validateApprovedValues:input], @"Passing multiple values into the array should return true.");
}

@end
