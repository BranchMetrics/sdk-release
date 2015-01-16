//
//  MATUtilsTests.m
//  MobileAppTracker
//
//  Created by Harshal Ogale on 1/24/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MATUtils_TestPrivateMethods.h"
#import "../MobileAppTracker/Common/MATSettings.h"
#import "../MobileAppTracker/Common/MATUtils.h"

@interface MATUtilsTests : XCTestCase

@end


@implementation MATUtilsTests

static NSString* const testKey = @"fakeMatKey";
#define expectedKey [NSString stringWithFormat:@"_MAT_%@", testKey]


- (void)setUp
{
    [super setUp];
    
    [self clearTestDefaults];
}

- (void)tearDown
{
    [self clearTestDefaults];
    
    [super tearDown];
}


- (void)clearTestDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:testKey];
    [defaults setObject:nil forKey:expectedKey];
    [defaults synchronize];
}


- (void)testJsonSerialize
{
    NSDictionary *item1 = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"item1", @(1), @(2.99f), @(2.99f), @"attr1", @"attr2", @"attr3", @"attr4", @"attr5", nil]
                                                      forKeys:[NSArray arrayWithObjects:@"item", @"quantity", @"revenue", @"unit_price", @"attribute_sub1", @"attribute_sub2", @"attribute_sub3", @"attribute_sub4", @"attribute_sub5", nil]];
    
    NSArray *arr1 = @ [ item1 ];
    
    NSDictionary *dict1 = @ { @"data" : arr1 };
    
    NSString *actualOutput = [MATUtils jsonSerialize:dict1];
    
    // TODO: this is a fragile (bad) test, because it's order- and spacing-dependent
    // instead, use something like the MATTestParams checkDataItems: method
    NSString *expectedOutput = @"{\"data\":[{\"quantity\":1,\"unit_price\":2.99,\"attribute_sub5\":\"attr5\",\"attribute_sub3\":\"attr3\",\"revenue\":2.99,\"attribute_sub1\":\"attr1\",\"attribute_sub4\":\"attr4\",\"item\":\"item1\",\"attribute_sub2\":\"attr2\"}]}";
    
    //NSLog(@"expected %@, actual: %@", expectedOutput, actualOutput);
    
    XCTAssertTrue([expectedOutput isEqualToString:actualOutput], @"JSON Serialization failed: expected %@, actual: %@", expectedOutput, actualOutput);
}


- (void)testNewKeyRead
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *oldMatId = [defaults valueForKey:@"_MAT_mat_id"];
    
    static NSString* const newMatId = @"fakeMatId";
    
    // write a string to a new-style key
    [defaults setObject:newMatId forKey:@"_MAT_mat_id"];
    [defaults synchronize];
    
    // assert that the new-style key is read by MATSettings
    MATSettings *settings = [MATSettings new];
    NSString *readMatId = settings.matId;
    XCTAssertTrue( [readMatId isEqualToString:newMatId], @"stored %@, read %@", newMatId, readMatId );
    
    [defaults setValue:oldMatId forKey:@"_MAT_mat_id"];
}


- (void)testNewKeyStored
{
    static NSString* const testValue = @"fakeValue";
    
    // write a string using old-style key name
    [MATUtils setUserDefaultValue:testValue forKey:testKey];
    
    // assert that it's stored in the new-style key name
    NSString *readValue = [[NSUserDefaults standardUserDefaults] valueForKey:expectedKey];
    XCTAssertTrue( [testValue isEqualToString:readValue], @"stored %@, read %@", testValue, readValue );
}


- (void)testOldKeyRead
{
    static NSString* const testValue = @"fakeValue";
    
    // write a string to old-style key
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:testValue forKey:testKey];
    [defaults synchronize];
    
    // assert that it's read by MATUtils
    NSString *readValue = [MATUtils userDefaultValueforKey:testKey];
    XCTAssertTrue( [testValue isEqualToString:readValue], @"stored %@, read %@", testValue, readValue );
}


- (void)testNewKeyReadPreferentially
{
    static NSString* const testValueOld = @"fakeValue1";
    static NSString* const testValueNew = @"fakeValue2";
    
    // write strings to old- and new-style keys
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:testValueOld forKey:testKey];
    [defaults setObject:testValueNew forKey:expectedKey];
    [defaults synchronize];
    
    // assert that new-style key is read by MATUtils
    NSString *readValue = [MATUtils userDefaultValueforKey:testKey];
    XCTAssertTrue( [testValueNew isEqualToString:readValue], @"stored %@, read %@", testValueNew, readValue );
}

@end