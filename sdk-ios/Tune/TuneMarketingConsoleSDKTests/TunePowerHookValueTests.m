//
//  TunePowerHookValueTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 7/28/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "DictionaryLoader.h"
#import "TunePowerHookValue.h"
#import "TuneDateUtils.h"

@protocol TunePowerHookValueTestsSelectors <NSObject>
-(BOOL) hasExperimentValue;
@end

@interface TunePowerHookValueTests : XCTestCase {
    NSMutableDictionary *dict;
}

@end


@implementation TunePowerHookValueTests

- (void)setUp
{
    [super setUp];
    
    RESET_EVERYTHING();
    
    dict = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePowerHookValueTests"].mutableCopy;
    
    dict[@"power_hooks"][@"couponDiscount"][@"experiment_value"] = @"0.30";
    dict[@"power_hooks"][@"couponDiscount"][@"start_date"] = @"";
    dict[@"power_hooks"][@"couponDiscount"][@"end_date"] = @"";
    dict[@"power_hooks"][@"couponDiscount"][@"variation_id"] = @"524f0a02e206e7efae000004";
    dict[@"power_hooks"][@"couponDiscount"][@"experiment_id"] = @"524f0a02e206e7efae000099";
}

- (void)testDescriptionInObjectAndDictionary {
    dict[@"power_hooks"][@"couponDiscount"][@"description"] = @"SHRED";
    TunePowerHookValue *ph = [[TunePowerHookValue alloc] initWithDictionary:dict[@"power_hooks"][@"couponDiscount"]];
    
    XCTAssertNotNil(ph.phookDescription);
    XCTAssertEqual(ph.phookDescription, @"SHRED");
    
    NSDictionary *phDictionary = [ph toDictionary];
    
    XCTAssertEqual(phDictionary[POWERHOOKVALUE_DESCRIPTION], @"SHRED");
}

- (void)testApprovedValuesInObjectAndDictionary {
    NSArray *values = @[ @"YES", @"NO", @"MAYBE" ];
    dict[@"power_hooks"][@"couponDiscount"][POWERHOOKVALUE_APPROVED_VALUES] = values;
    TunePowerHookValue *ph = [[TunePowerHookValue alloc] initWithDictionary:dict[@"power_hooks"][@"couponDiscount"]];
    
    XCTAssertNotNil(ph.approvedValues);
    XCTAssertEqual(ph.approvedValues, values);
    
    NSDictionary *phDictionary = [ph toDictionary];
    
    XCTAssertEqual(phDictionary[POWERHOOKVALUE_APPROVED_VALUES], values);
}

#pragma mark - Experiment / No Experiment Values

- (void)testNoExperiment {
    dict = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePowerHookValueTests"].mutableCopy;
    
    TunePowerHookValue *ph = [[TunePowerHookValue alloc] initWithDictionary:dict[@"power_hooks"][@"couponDiscount"]];
    
    BOOL hasExperimentValue = [ph performSelector:@selector(hasExperimentValue)] != nil;
    
    XCTAssertFalse(hasExperimentValue, @"Power Hook value, we do not have an experiment value");
    XCTAssertFalse([ph isExperimentRunning], @"Power Hook value, experiment is not running");
}

- (void)testWithExperimentNotActive {
    [self setStartEndDatesInPowerHookStartDays:2 endDays:5 dict:dict];
    
    TunePowerHookValue *ph = [[TunePowerHookValue alloc] initWithDictionary:dict[@"power_hooks"][@"couponDiscount"]];
    
    BOOL hasExperimentValue = [ph performSelector:@selector(hasExperimentValue)] != nil;
    
    XCTAssertTrue(hasExperimentValue, @"Power Hook value, we have an experiment value");
    XCTAssertFalse([ph isExperimentRunning], @"Power Hook value, experiment is not running");
}

- (void)testWithExperimentActive {
    [self setStartEndDatesInPowerHookStartDays:-2 endDays:5 dict:dict];
    
    TunePowerHookValue *ph = [[TunePowerHookValue alloc]initWithDictionary:dict[@"power_hooks"][@"couponDiscount"]];
    
    BOOL hasExperimentValue = [ph performSelector:@selector(hasExperimentValue)] != nil;
    
    XCTAssertTrue(hasExperimentValue, @"Power Hook value, we have an experiment value");
    XCTAssertTrue([ph isExperimentRunning], @"Power Hook value, experiment is running");
}

- (void)testWithExperimentExpired {
    [self setStartEndDatesInPowerHookStartDays:-5 endDays:-2 dict:dict];
    
    TunePowerHookValue *ph = [[TunePowerHookValue alloc]initWithDictionary:dict[@"power_hooks"][@"couponDiscount"]];
    
    BOOL hasExperimentValue = [ph performSelector:@selector(hasExperimentValue)] != nil;
    
    XCTAssertTrue(hasExperimentValue, @"Power Hook value, we have an experiment value");
    XCTAssertFalse([ph isExperimentRunning], @"Power Hook value, experiment is not running");
}

- (void)setStartEndDatesInPowerHookStartDays:(int)startDays endDays:(int)endDays dict:(NSMutableDictionary *)dictionary {
    NSDate *now = [NSDate date];
    NSString *startDate = [[TuneDateUtils dateFormatterIso8601UTC] stringFromDate:[now dateByAddingTimeInterval:60*60*24*startDays]];
    NSString *endDate = [[TuneDateUtils dateFormatterIso8601UTC] stringFromDate:[now dateByAddingTimeInterval:60*60*24*endDays]];
    
    dictionary[@"power_hooks"][@"couponDiscount"][@"start_date"] = startDate;
    dictionary[@"power_hooks"][@"couponDiscount"][@"end_date"] = endDate;
}


@end
