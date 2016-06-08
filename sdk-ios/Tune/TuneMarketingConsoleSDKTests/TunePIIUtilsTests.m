//
//  TunePIIUtilsTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/1/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "TunePIIUtils.h"
#import "TuneAnalyticsVariable.h"
#import "TuneConfiguration.h"
#import "TuneConfigurationKeys.h"
#import "Tune+Testing.h"
#import "TuneManager.h"
#import "TuneXCTestCase.h"

@interface TunePIIUtilsTests : TuneXCTestCase

@end

@implementation TunePIIUtilsTests

- (void)setUp {
    [super setUp];

    NSDictionary *config = @{TUNE_TMA_PII_FILTERS_NSSTRING: @[@"^[1-9][0-9]{5,50}$",@"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}$"]};
    [Tune initializeWithTuneAdvertiserId:@"foobar" tuneConversionKey:@"bingband" tunePackageName:@"com.foo" wearable:NO configuration:config];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testPIIFilter {
    TuneAnalyticsVariable *var = [TuneAnalyticsVariable analyticsVariableWithName:@"foobar" value:@"123456789"];
    NSArray *converted = [var toArrayOfDicts];
    NSArray *expected = @[ @{ @"name" : @"foobar", @"value" : @"25f9e794323b453885f5181f1b624d0b", @"type" : @"string", @"hash": @"md5"},
                           @{ @"name" : @"foobar", @"value" : @"f7c3bc1d808e04732adf679965ccc34ca7ae3441", @"type" : @"string", @"hash": @"sha1"},
                           @{ @"name" : @"foobar", @"value" : @"15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225", @"type" : @"string", @"hash": @"sha256"}
                         ];
    XCTAssertTrue([converted isEqualToArray:expected]);
    
    var = [TuneAnalyticsVariable analyticsVariableWithName:@"foobar" value:@(123456789) type:TuneAnalyticsVariableNumberType];
    converted = [var toArrayOfDicts];
    expected = @[ @{ @"name" : @"foobar", @"value" : @"25f9e794323b453885f5181f1b624d0b", @"type" : @"float", @"hash": @"md5"},
                  @{ @"name" : @"foobar", @"value" : @"f7c3bc1d808e04732adf679965ccc34ca7ae3441", @"type" : @"float", @"hash": @"sha1"},
                  @{ @"name" : @"foobar", @"value" : @"15e2b0d3c33891ebb0f1ef609ec419420c20e320ce94c65fbc8c3312448eb225", @"type" : @"float", @"hash": @"sha256"}
                ];
    XCTAssertTrue([converted isEqualToArray:expected]);
    
    
    var = [TuneAnalyticsVariable analyticsVariableWithName:@"foobar" value:@"jim@tune.com"];
    converted = [var toArrayOfDicts];
    expected = @[ @{ @"name" : @"foobar", @"value" : @"bb128b6d08dcaf039590d759e16422a8", @"type" : @"string", @"hash": @"md5"},
                  @{ @"name" : @"foobar", @"value" : @"8fb1db891bea45aab362b50560677461b74a6bb5", @"type" : @"string", @"hash": @"sha1"},
                  @{ @"name" : @"foobar", @"value" : @"6c74f7487195814eaabde0b45566f69a517223d9b404470085828bc2f74602c9", @"type" : @"string", @"hash": @"sha256"}
                ];
    XCTAssertTrue([converted isEqualToArray:expected]);
    
    var = [TuneAnalyticsVariable analyticsVariableWithName:@"foobar" value:@"All Good"];
    converted = [var toArrayOfDicts];
    expected = @[ @{ @"name" : @"foobar", @"value" : @"All Good", @"type" : @"string"} ];
    XCTAssertTrue([converted isEqualToArray:expected]);
}

- (void)testPIIFilterOnNil {
    TuneAnalyticsVariable *var = [TuneAnalyticsVariable analyticsVariableWithName:@"foobar" value:nil];
    NSArray *converted = [var toArrayOfDicts];
    NSArray *expected = @[ @{ @"name" : @"foobar", @"value" : [NSNull null], @"type" : @"string"} ];
    XCTAssertTrue([converted isEqualToArray:expected]);
}

@end
