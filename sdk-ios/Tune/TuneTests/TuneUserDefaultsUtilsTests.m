//
//  TuneUserDefaultsUtilsTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 8/17/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <XCTest/XCTest.h>

#import "TuneCWorks.h"
#import "TuneManager.h"
#import "TuneModule.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneUserProfile.h"
#import "TuneXCTestCase.h"

@interface TuneUserDefaultsUtilsTests : TuneXCTestCase

@end



@implementation TuneUserDefaultsUtilsTests

static NSString* const testKey = @"fakeTuneKey";
static NSString* const expectedKey = @"_TUNE_fakeTuneKey";


- (void)testNewKeyStored {
    static NSString* const testValue = @"fakeValue";
    
    // write a string using old-style key name
    [TuneUserDefaultsUtils setUserDefaultValue:testValue forKey:testKey];
    
    // assert that it's stored in the new-style key name
    NSString *readValue = [TuneUserDefaultsUtils userDefaultValueforKey:expectedKey];
    XCTAssertTrue( [testValue isEqualToString:readValue], @"stored %@, read %@", testValue, readValue );
}

- (void)testOldKeyRead {
    static NSString* const testValue = @"fakeValue";
    
    // write a string to old-style key
    [TuneUserDefaultsUtils setUserDefaultValue:testValue forKey:testKey];
    
    // assert that it's read by TuneUtils
    NSString *readValue = [TuneUserDefaultsUtils userDefaultValueforKey:testKey];
    XCTAssertTrue( [testValue isEqualToString:readValue], @"stored %@, read %@", testValue, readValue );
}

- (void)testNewKeyReadPreferentially {
    static NSString* const testValueOld = @"fakeValue1";
    static NSString* const testValueNew = @"fakeValue2";
    
    // write strings to old- and new-style keys
    [TuneUserDefaultsUtils setUserDefaultValue:testValueOld forKey:testKey addKeyPrefix:NO];
    [TuneUserDefaultsUtils setUserDefaultValue:testValueNew forKey:expectedKey addKeyPrefix:NO];
    
    // assert that new-style key is read by TuneUtils
    NSString *readValue = [TuneUserDefaultsUtils userDefaultValueforKey:testKey];
    XCTAssertTrue( [testValueNew isEqualToString:readValue], @"stored %@, read %@", testValueNew, readValue );
}

- (void)testNewKeyRead {
    NSString *oldTuneId = [TuneUserDefaultsUtils userDefaultValueforKey:@"_TUNE_mat_id"];
    
    static NSString* const newTuneId = @"fakeTuneId";
    
    // write a string to a new-style key
    [TuneUserDefaultsUtils setUserDefaultValue:newTuneId forKey:@"_TUNE_mat_id" addKeyPrefix:NO];
    
    // assert that the new-style key is read by TuneSettings
    TuneUserProfile *userProfile = [[TuneUserProfile alloc] initWithTuneManager:[TuneManager currentManager]];
    NSString *readTuneId = userProfile.tuneId;
    XCTAssertTrue( [readTuneId isEqualToString:newTuneId], @"stored %@, read %@", newTuneId, readTuneId );
    
    [TuneUserDefaultsUtils setUserDefaultValue:oldTuneId forKey:@"_TUNE_mat_id"];
}

- (void)testLoadStoreCustomVariable {
    TuneAnalyticsVariable *var = [TuneAnalyticsVariable analyticsVariableWithName:@"foobar"
                                                                            value:@"bingbang"
                                                                             type:TuneAnalyticsVariableStringType
                                                                         hashType:TuneAnalyticsVariableHashNone
                                                                   shouldAutoHash:YES];
    
    [TuneUserDefaultsUtils setUserDefaultCustomVariable:var forKey:@"fakeValue"];
    
    TuneAnalyticsVariable *shouldBeNil = [TuneUserDefaultsUtils userDefaultValueforKey:@"fakeValue"];
    
    XCTAssertTrue(shouldBeNil == nil, @"The variable should have been set as a custom variable, not a normal variable");
    
    TuneAnalyticsVariable *gotten = [TuneUserDefaultsUtils userDefaultCustomVariableforKey:@"fakeValue"];
    XCTAssertTrue([[var toDictionary] isEqualToDictionary:[gotten toDictionary]]);
}


- (void)testIncrementUserDefaultsCountForKey {
    NSString *key = @"int_num_counter_key";
    [TuneUserDefaultsUtils clearUserDefaultValue:key];
    XCTAssertNil([TuneUserDefaultsUtils userDefaultValueforKey:key]);
    
    [TuneUserDefaultsUtils incrementUserDefaultCountForKey:key];
    XCTAssertNotNil([TuneUserDefaultsUtils userDefaultValueforKey:key]);
    XCTAssertEqual(1, [[TuneUserDefaultsUtils userDefaultValueforKey:key] intValue]);
    
    [TuneUserDefaultsUtils incrementUserDefaultCountForKey:key];
    XCTAssertEqual(2, [[TuneUserDefaultsUtils userDefaultValueforKey:key] intValue]);
}

- (void)testIncrementUserDefaultsCountForKeyByValue {
    NSString *key = @"int_num_counter_key";
    [TuneUserDefaultsUtils clearUserDefaultValue:key];
    XCTAssertNil([TuneUserDefaultsUtils userDefaultValueforKey:key]);
    
    [TuneUserDefaultsUtils incrementUserDefaultCountForKey:key byValue:5];
    XCTAssertNotNil([TuneUserDefaultsUtils userDefaultValueforKey:key]);
    XCTAssertEqual(5, [[TuneUserDefaultsUtils userDefaultValueforKey:key] intValue]);
    
    [TuneUserDefaultsUtils incrementUserDefaultCountForKey:key byValue:3];
    XCTAssertEqual(8, [[TuneUserDefaultsUtils userDefaultValueforKey:key] intValue]);
}

- (void)testIncrementUserDefaultsCountForKey_invalid_nonNumeric {
    NSString *key = @"non_int_num_counter_key";
    id nonNSNumberValue = @"object not an NSNumber";
    [TuneUserDefaultsUtils setUserDefaultValue:nonNSNumberValue forKey:key];
    XCTAssertEqualObjects(nonNSNumberValue, [TuneUserDefaultsUtils userDefaultValueforKey:key]);
    
    [TuneUserDefaultsUtils incrementUserDefaultCountForKey:key];
    XCTAssertEqualObjects(nonNSNumberValue, [TuneUserDefaultsUtils userDefaultValueforKey:key]);
    XCTAssertEqual(0, [[TuneUserDefaultsUtils userDefaultValueforKey:key] intValue]);
}

- (void)testIncrementUserDefaultsCountForKeyByValue_invalid_nonNumeric {
    NSString *key = @"non_int_num_counter_key";
    id nonNSNumberValue = @"object not an NSNumber";
    [TuneUserDefaultsUtils setUserDefaultValue:nonNSNumberValue forKey:key];
    XCTAssertEqualObjects(nonNSNumberValue, [TuneUserDefaultsUtils userDefaultValueforKey:key]);
    
    [TuneUserDefaultsUtils incrementUserDefaultCountForKey:key byValue:5];
    XCTAssertEqualObjects(nonNSNumberValue, [TuneUserDefaultsUtils userDefaultValueforKey:key]);
    XCTAssertEqual(0, [[TuneUserDefaultsUtils userDefaultValueforKey:key] intValue]);
    
    [TuneUserDefaultsUtils incrementUserDefaultCountForKey:key byValue:-3];
    XCTAssertEqualObjects(nonNSNumberValue, [TuneUserDefaultsUtils userDefaultValueforKey:key]);
    XCTAssertEqual(0, [[TuneUserDefaultsUtils userDefaultValueforKey:key] intValue]);
}

@end
