//
//  TuneUtilsTests.m
//  Tune
//
//  Created by Harshal Ogale on 1/24/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneUtils_TestPrivateMethods.h"
#import "../Tune/Common/TuneSettings.h"
#import "../Tune/Common/TuneCWorks.h"
#import "../Tune/Common/TuneKeyStrings.h"

@interface TuneUtilsTests : XCTestCase

@end


@implementation TuneUtilsTests

static NSString* const testKey = @"fakeTuneKey";
#define expectedKey [NSString stringWithFormat:@"_TUNE_%@", testKey]


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
    NSDictionary *item1 = @{@"item":@"item1",
                            @"quantity":@(1),
                            @"revenue":@(2.99f),
                            @"unit_price":@(2.99f),
                            @"attribute_sub1":@"attr1",
                            @"attribute_sub2":@"attr2",
                            @"attribute_sub3":@"attr3",
                            @"attribute_sub4":@"attr4",
                            @"attribute_sub5":@"attr5"};
    
    NSArray *arr1 = @ [ item1 ];
    
    NSDictionary *dict1 = @ { @"data" : arr1 };
    
    NSString *actualOutput = [TuneUtils jsonSerialize:dict1];
    
    // TODO: this is a fragile (bad) test, because it's order- and spacing-dependent
    // instead, use something like the TuneTestParams checkDataItems: method
    NSString *expectedOutput = @"{\"data\":[{\"quantity\":1,\"unit_price\":2.99,\"attribute_sub5\":\"attr5\",\"attribute_sub3\":\"attr3\",\"revenue\":2.99,\"attribute_sub1\":\"attr1\",\"attribute_sub4\":\"attr4\",\"item\":\"item1\",\"attribute_sub2\":\"attr2\"}]}";
    
    //NSLog(@"expected %@, actual: %@", expectedOutput, actualOutput);
    
    XCTAssertTrue([expectedOutput isEqualToString:actualOutput], @"JSON Serialization failed: expected %@, actual: %@", expectedOutput, actualOutput);
    
    
    actualOutput = [TuneUtils jsonSerialize:nil];
    
    XCTAssertNil(actualOutput, @"JSON Serialization failed: expected: nil, actual: %@", actualOutput);
}

- (void)testNewKeyRead
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *oldMatId = [defaults valueForKey:@"_TUNE_mat_id"];
    
    static NSString* const newMatId = @"fakeMatId";
    
    // write a string to a new-style key
    [defaults setObject:newMatId forKey:@"_TUNE_mat_id"];
    [defaults synchronize];
    
    // assert that the new-style key is read by TuneSettings
    TuneSettings *settings = [TuneSettings new];
    NSString *readMatId = settings.matId;
    XCTAssertTrue( [readMatId isEqualToString:newMatId], @"stored %@, read %@", newMatId, readMatId );
    
    [defaults setValue:oldMatId forKey:@"_TUNE_mat_id"];
}

- (void)testNewKeyStored
{
    static NSString* const testValue = @"fakeValue";
    
    // write a string using old-style key name
    [TuneUtils setUserDefaultValue:testValue forKey:testKey];
    
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
    
    // assert that it's read by TuneUtils
    NSString *readValue = [TuneUtils userDefaultValueforKey:testKey];
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
    
    // assert that new-style key is read by TuneUtils
    NSString *readValue = [TuneUtils userDefaultValueforKey:testKey];
    XCTAssertTrue( [testValueNew isEqualToString:readValue], @"stored %@, read %@", testValueNew, readValue );
}

- (void)testHashMd5
{
    static NSString* const input = @"some \"test\" string; 1234, with numbers & symbols!";
    static NSString* const expected = @"a346e5dc2a8d22f2733af9740c5a8756";
    
    NSString *actual = [TuneUtils hashMd5:input];
    
    XCTAssertTrue( [actual isEqualToString:expected], @"expected %@, actual %@", expected, actual );
}

- (void)testHashSha1
{
    static NSString* const input = @"some \"test\" string; 1234, with numbers & symbols!";
    static NSString* const expected = @"310fd0f3e8716db8bb44f474b5fe4bc2336ad967";
    
    NSString *actual = [TuneUtils hashSha1:input];
    
    XCTAssertTrue( [actual isEqualToString:expected], @"expected %@, actual %@", expected, actual );
}

- (void)testHashSha256
{
    static NSString* const input = @"some \"test\" string; 1234, with numbers & symbols!";
    static NSString* const expected = @"36e75466833deaf7fbce4780ed813707a83c261876d2a7f08115d5cb6842b0c4";
    
    NSString *actual = [TuneUtils hashSha256:input];
    
    XCTAssertTrue( [actual isEqualToString:expected], @"expected %@, actual %@", expected, actual );
}

- (void)testUrlEncode
{
    id input = nil;
    NSString * expected = nil;
    NSString * actual = nil;
    
    input = nil;
    actual = [TuneUtils urlEncode:input];
    XCTAssertNil(actual, @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
    
    input = [NSNull null];
    actual = [TuneUtils urlEncode:input];
    XCTAssertNil(actual, @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
    
    input = @"abc.pqr@xyz.com";
    expected = @"abc.pqr%40xyz.com";
    actual = [TuneUtils urlEncode:input];
    XCTAssert([actual isEqualToString:expected], @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
}

@end