//
//  TuneDeepActionManagerTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 10/1/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneSkyhookCenter.h"
#import "TuneDeepActionManager+Testing.h"

@interface TuneDeepActionManagerTests : XCTestCase {
    TuneDeepActionManager *deepActionManager;
}

@end

@implementation TuneDeepActionManagerTests

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
    
    deepActionManager = [TuneManager currentManager].deepActionManager;
}

- (void)tearDown {
    deepActionManager = nil;
    
    [super tearDown];
}

/* The tests here are currently very light because the places where the Deep Actions are triggered are neigh-impossible to simulate via tests.
 */

- (void)testDeepActionTriggered {
    __block NSUInteger i = 0;
    [deepActionManager registerDeepActionWithId:@"testAction"
                                   friendlyName:@"A sample test action!"
                                    description:nil
                                           data:@{}
                                 approvedValues:nil
                                      andAction:^(NSDictionary *extra_data){
                                          i += 1;
                                      }];
    XCTAssertTrue(i == 0, @"Got: %lu", (unsigned long)i);
    NSDictionary *payload = @{ TunePayloadDeepActionId: @"testAction",
                               TunePayloadDeepActionData: @{} };
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneDeepActionTriggered object:nil userInfo:payload];
    XCTAssertTrue(i == 1, @"Got: %lu", (unsigned long)i);
}

- (void)testDictionaryProperlyOverrides {
    __block NSString *result;
    [deepActionManager registerDeepActionWithId:@"testAction"
                                   friendlyName:@"A sample test action!"
                                    description:nil
                                           data:@{@"i": @"foo", @"j": @"bar"}
                                 approvedValues:nil
                                      andAction:^(NSDictionary *extra_data){
                                          result = [NSString stringWithFormat:@"%@%@", extra_data[@"i"], extra_data[@"j"]];
                                      }];
    
    NSDictionary *payload = @{ TunePayloadDeepActionId: @"testAction",
                               TunePayloadDeepActionData: @{@"i": @"bing", @"j": @"bang"} };
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneDeepActionTriggered object:nil userInfo:payload];
    XCTAssertTrue([result isEqualToString:@"bingbang"], @"Got: %@", result);
    
    payload = @{ TunePayloadDeepActionId: @"testAction",
                 TunePayloadDeepActionData: @{} };
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneDeepActionTriggered object:nil userInfo:payload];
    XCTAssertTrue([result isEqualToString:@"foobar"], @"Got: %@", result);
    
    payload = @{ TunePayloadDeepActionId: @"testAction",
                 TunePayloadDeepActionData: @{@"i": @"bing"} };
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneDeepActionTriggered object:nil userInfo:payload];
    XCTAssertTrue([result isEqualToString:@"bingbar"], @"Got: %@", result);
    
    payload = @{ TunePayloadDeepActionId: @"testAction",
                 TunePayloadDeepActionData: @{@"j": @"bang"} };
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneDeepActionTriggered object:nil userInfo:payload];
    XCTAssertTrue([result isEqualToString:@"foobang"], @"Got: %@", result);
}

@end
