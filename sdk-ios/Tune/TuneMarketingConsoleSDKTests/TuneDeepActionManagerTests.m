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
#import "TuneXCTestCase.h"

@interface TuneDeepActionManagerTests : TuneXCTestCase {
    TuneDeepActionManager *deepActionManager;
}

@end

@implementation TuneDeepActionManagerTests

- (void)setUp {
    [super setUp];

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

- (void)testExecuteDeepActionInvalidActionName {
    __block NSUInteger i = 0;
    __block NSMutableString *str = @"abc".mutableCopy;
    __block BOOL isMainThread = NO;
    [deepActionManager registerDeepActionWithId:@"testAction"
                                   friendlyName:@"A sample test action!"
                                    description:nil
                                           data:@{}
                                 approvedValues:nil
                                      andAction:^(NSDictionary *extra_data) {
                                          i += 1;
                                          if (extra_data[@"suffix"]) {
                                              [str appendString:extra_data[@"suffix"]];
                                          }
                                          isMainThread = [NSThread isMainThread];
                                      }];
    
    XCTAssertEqual(i, 0);
    
    [deepActionManager executeDeepActionWithId:@"incorrectAction" andData:nil];
    XCTAssertEqual(i, 0);
}

- (void)testExecuteDeepActionNilData {
    __block NSUInteger i = 0;
    __block NSMutableString *str = @"abc".mutableCopy;
    __block BOOL isMainThread = NO;
    [deepActionManager registerDeepActionWithId:@"testAction"
                                   friendlyName:@"A sample test action!"
                                    description:nil
                                           data:@{}
                                 approvedValues:nil
                                      andAction:^(NSDictionary *extra_data) {
                                          i += 1;
                                          if (extra_data[@"suffix"]) {
                                              [str appendString:extra_data[@"suffix"]];
                                          }
                                          isMainThread = [NSThread isMainThread];
                                      }];
    
    XCTAssertEqual(i, 0);
    
    isMainThread = NO;
    [deepActionManager executeDeepActionWithId:@"testAction" andData:nil];
    XCTAssertEqual(i, 1);
    XCTAssertTrue(isMainThread);
}

- (void)testExecuteDeepActionEmptyData {
    __block NSUInteger i = 0;
    __block NSMutableString *str = @"abc".mutableCopy;
    __block BOOL isMainThread = NO;
    [deepActionManager registerDeepActionWithId:@"testAction"
                                   friendlyName:@"A sample test action!"
                                    description:nil
                                           data:@{}
                                 approvedValues:nil
                                      andAction:^(NSDictionary *extra_data) {
                                          i += 1;
                                          if (extra_data[@"suffix"]) {
                                              [str appendString:extra_data[@"suffix"]];
                                          }
                                          isMainThread = [NSThread isMainThread];
                                      }];
    
    XCTAssertEqual(i, 0);
    
    isMainThread = NO;
    [deepActionManager executeDeepActionWithId:@"testAction" andData:@{}];
    XCTAssertEqual(i, 1);
    XCTAssertTrue(isMainThread);
}

- (void)testExecuteDeepActionNormalStringData {
    __block NSUInteger i = 0;
    __block NSMutableString *str = @"abc".mutableCopy;
    __block BOOL isMainThread = NO;
    [deepActionManager registerDeepActionWithId:@"testAction"
                                   friendlyName:@"A sample test action!"
                                    description:nil
                                           data:@{}
                                 approvedValues:nil
                                      andAction:^(NSDictionary *extra_data) {
                                          i += 1;
                                          if (extra_data[@"suffix"]) {
                                              [str appendString:extra_data[@"suffix"]];
                                          }
                                          isMainThread = [NSThread isMainThread];
                                      }];
    
    XCTAssertEqual(i, 0);
    
    isMainThread = NO;
    XCTAssertEqualObjects(str, @"abc");
    [deepActionManager executeDeepActionWithId:@"testAction" andData:@{@"suffix":@"def"}];
    XCTAssertEqual(i, 1);
    XCTAssertEqualObjects(str, @"abcdef");
    XCTAssertTrue(isMainThread);
}

- (void)testExecuteDeepActionDataOverride {
    __block NSUInteger i = 0;
    __block NSMutableString *str = @"abc".mutableCopy;
    __block BOOL isMainThread = NO;
    [deepActionManager registerDeepActionWithId:@"testAction"
                                   friendlyName:@"A sample test action!"
                                    description:nil
                                           data:@{@"prefix":@"123", @"suffix":@"xyz"}
                                 approvedValues:nil
                                      andAction:^(NSDictionary *extra_data) {
                                          i += 1;
                                          if (extra_data[@"prefix"]) {
                                              [str insertString:extra_data[@"prefix"] atIndex:0];
                                          }
                                          if (extra_data[@"suffix"]) {
                                              [str appendString:extra_data[@"suffix"]];
                                          }
                                          isMainThread = [NSThread isMainThread];
                                      }];
    
    XCTAssertEqual(i, 0);
    
    isMainThread = NO;
    XCTAssertEqualObjects(str, @"abc");
    [deepActionManager executeDeepActionWithId:@"testAction" andData:@{@"suffix":@"def"}];
    XCTAssertEqual(i, 1);
    XCTAssertEqualObjects(str, @"123abcdef");
    XCTAssertTrue(isMainThread);
}

- (void)testExecuteDeepActionMainThread {
    __block NSUInteger i = 0;
    __block NSMutableString *str = @"abc".mutableCopy;
    __block BOOL isMainThread = NO;
    [deepActionManager registerDeepActionWithId:@"testAction"
                                   friendlyName:@"A sample test action!"
                                    description:nil
                                           data:@{}
                                 approvedValues:nil
                                      andAction:^(NSDictionary *extra_data) {
                                          i += 1;
                                          if (extra_data[@"suffix"]) {
                                              [str appendString:extra_data[@"suffix"]];
                                          }
                                          isMainThread = [NSThread isMainThread];
                                      }];
    
    XCTAssertEqual(i, 0);
    
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"DeepActionBlockCalledFromMainThread"];
    
    isMainThread = NO;
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, kNilOptions);
    dispatch_async(backgroundQueue, ^{
        XCTAssertFalse([NSThread isMainThread]);
        [deepActionManager executeDeepActionWithId:@"testAction" andData:@{@"suffix":@"def"}];
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:2 handler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"XCTestExpectation error = %@", error);
        }
        XCTAssertNil(error);
        
        XCTAssertEqual(i, 1);
        XCTAssertEqualObjects(str, @"abcdef");
        XCTAssertTrue(isMainThread);
    }];
}

@end
