//
//  TuneAnalyticsItemTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 8/21/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "TuneAnalyticsItem.h"
#import "TuneAnalyticsVariable.h"
#import "TuneEvent+Internal.h"
#import "TuneEventItem+Internal.h"

@interface TuneAnalyticsItemTests : XCTestCase

@end

@implementation TuneAnalyticsItemTests

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
}

- (void)tearDown {
    [super tearDown];
}

- (void)testConvertingToTuneAnalyticsItemAndToDictionary {
    TuneEventItem *tuneEventItem = [TuneEventItem eventItemWithName:@"foobar" unitPrice:2.5 quantity:10];
    tuneEventItem.attribute1 = @"I'm attribute1!";
    [tuneEventItem addTag:@"tag1" withStringValue:@"value1"];
    
    TuneAnalyticsItem *analyticsItem = [TuneAnalyticsItem analyticsItemFromTuneEventItem:tuneEventItem];
    
    XCTAssertTrue([analyticsItem.item isEqualToString:@"foobar"]);
    XCTAssertTrue([analyticsItem.unitPrice isEqualToString:@"2.5"]);
    XCTAssertTrue([analyticsItem.quantity isEqualToString:@"10"]);
    XCTAssertTrue([analyticsItem.revenue isEqualToString:@"25"]);
    
    XCTAssertTrue([analyticsItem.attributes count] == 2);
    XCTAssertTrue([analyticsItem.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"attribute_sub1" value:@"I'm attribute1!"]]);
    XCTAssertTrue([analyticsItem.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"tag1" value:@"value1"]]);
    
    NSDictionary *dict = [analyticsItem toDictionary];
    
    NSDictionary *expected = @{ @"attributes": @[ @{@"name": @"attribute_sub1",
                                                    @"type": @"string",
                                                    @"value": @"I'm attribute1!"},
                                                  @{@"name": @"tag1",
                                                    @"type": @"string",
                                                    @"value": @"value1"}
                                                 ],
                                @"item": @"foobar",
                                @"quantity": @"10",
                                @"revenue": @"25",
                                @"unitPrice": @"2.5" };
    
    XCTAssertTrue([dict isEqualToDictionary:expected]);
}

- (void)testConvertingToTuneAnalyticsItemAndToDictionaryWithNilItemName {
    TuneEventItem *tuneEventItem = [TuneEventItem eventItemWithName:nil unitPrice:2.5 quantity:10];
    tuneEventItem.attribute1 = @"I'm attribute1!";
    [tuneEventItem addTag:@"tag1" withStringValue:@"value1"];
    
    TuneAnalyticsItem *analyticsItem = [TuneAnalyticsItem analyticsItemFromTuneEventItem:tuneEventItem];
    
    XCTAssertTrue(analyticsItem.item == nil);
    XCTAssertTrue([analyticsItem.unitPrice isEqualToString:@"2.5"]);
    XCTAssertTrue([analyticsItem.quantity isEqualToString:@"10"]);
    XCTAssertTrue([analyticsItem.revenue isEqualToString:@"25"]);
    
    XCTAssertTrue([analyticsItem.attributes count] == 2);
    XCTAssertTrue([analyticsItem.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"attribute_sub1" value:@"I'm attribute1!"]]);
    XCTAssertTrue([analyticsItem.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"tag1" value:@"value1"]]);
    
    NSDictionary *dict = [analyticsItem toDictionary];
    
    NSDictionary *expected = @{ @"attributes": @[ @{@"name": @"attribute_sub1",
                                                    @"type": @"string",
                                                    @"value": @"I'm attribute1!"},
                                                  @{@"name": @"tag1",
                                                    @"type": @"string",
                                                    @"value": @"value1"}
                                                  ],
                                @"item": [NSNull null],
                                @"quantity": @"10",
                                @"revenue": @"25",
                                @"unitPrice": @"2.5" };
    
    XCTAssertTrue([dict isEqualToDictionary:expected]);
}

- (void)testAddingAutoHashingStrings {
    TuneEventItem *tuneEventItem = [TuneEventItem eventItemWithName:@"foobar" unitPrice:2.5 quantity:10];
    [tuneEventItem addTag:@"tag1" withStringValue:@"value" hashed:YES];
    [tuneEventItem addTag:@"tag2" withStringValue:@"value2"];
    
    TuneAnalyticsItem *analyticsItem = [TuneAnalyticsItem analyticsItemFromTuneEventItem:tuneEventItem];
    
    XCTAssertTrue([analyticsItem.item isEqualToString:@"foobar"]);
    XCTAssertTrue([analyticsItem.unitPrice isEqualToString:@"2.5"]);
    XCTAssertTrue([analyticsItem.quantity isEqualToString:@"10"]);
    XCTAssertTrue([analyticsItem.revenue isEqualToString:@"25"]);
    
    XCTAssertTrue([analyticsItem.attributes count] == 2);
    XCTAssertTrue([analyticsItem.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"tag1" value:@"value" type:TuneAnalyticsVariableStringType shouldAutoHash:YES]]);
    XCTAssertTrue([analyticsItem.attributes containsObject:[TuneAnalyticsVariable analyticsVariableWithName:@"tag2" value:@"value2"]]);
    
    NSDictionary *dict = [analyticsItem toDictionary];
    
    NSDictionary *expected = @{ @"attributes": @[  @{ @"name" : @"tag1", @"value" : @"2063c1608d6e0baf80249c42e2be5804", @"type" : @"string", @"hash": @"md5"},
                                                   @{ @"name" : @"tag1", @"value" : @"f32b67c7e26342af42efabc674d441dca0a281c5", @"type" : @"string", @"hash": @"sha1"},
                                                   @{ @"name" : @"tag1", @"value" : @"cd42404d52ad55ccfa9aca4adc828aa5800ad9d385a0671fbcbf724118320619", @"type" : @"string", @"hash": @"sha256"},
                                                  @{@"name": @"tag2",
                                                    @"type": @"string",
                                                    @"value": @"value2"}
                                                  ],
                                @"item": @"foobar",
                                @"quantity": @"10",
                                @"revenue": @"25",
                                @"unitPrice": @"2.5" };
    
    XCTAssertTrue([dict isEqualToDictionary:expected]);
}

@end
