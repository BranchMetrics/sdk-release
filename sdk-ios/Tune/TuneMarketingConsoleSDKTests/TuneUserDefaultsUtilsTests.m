//
//  TuneUserDefaultsUtilsTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 8/17/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <XCTest/XCTest.h>
#import "TuneUtils+Testing.h"
#import "TuneUserProfile.h"
#import "TuneModule.h"
#import "TuneCWorks.h"
#import "Tunemanager.h"
#import "TuneUserDefaultsUtils.h"

@interface TuneUserDefaultsUtilsTests : XCTestCase

@end


@implementation TuneUserDefaultsUtilsTests

static NSString* const testKey = @"fakeTuneKey";
#define expectedKey [NSString stringWithFormat:@"_TUNE_%@", testKey]


- (void)setUp
{
    [super setUp];
    
    RESET_EVERYTHING();
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testNewKeyStored {
    static NSString* const testValue = @"fakeValue";
    
    // write a string using old-style key name
    [TuneUserDefaultsUtils setUserDefaultValue:testValue forKey:testKey];
    
    // assert that it's stored in the new-style key name
    NSString *readValue = [[NSUserDefaults standardUserDefaults] valueForKey:expectedKey];
    XCTAssertTrue( [testValue isEqualToString:readValue], @"stored %@, read %@", testValue, readValue );
}

- (void)testOldKeyRead {
    static NSString* const testValue = @"fakeValue";
    
    // write a string to old-style key
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:testValue forKey:testKey];
    [defaults synchronize];
    
    // assert that it's read by TuneUtils
    NSString *readValue = [TuneUserDefaultsUtils userDefaultValueforKey:testKey];
    XCTAssertTrue( [testValue isEqualToString:readValue], @"stored %@, read %@", testValue, readValue );
}

- (void)testNewKeyReadPreferentially {
    static NSString* const testValueOld = @"fakeValue1";
    static NSString* const testValueNew = @"fakeValue2";
    
    // write strings to old- and new-style keys
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:testValueOld forKey:testKey];
    [defaults setObject:testValueNew forKey:expectedKey];
    [defaults synchronize];
    
    // assert that new-style key is read by TuneUtils
    NSString *readValue = [TuneUserDefaultsUtils userDefaultValueforKey:testKey];
    XCTAssertTrue( [testValueNew isEqualToString:readValue], @"stored %@, read %@", testValueNew, readValue );
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

@end
