//
//  TuneUtilsTests.m
//  Tune
//
//  Created by Harshal Ogale on 1/24/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneUtils.h"
#import "TuneUserProfile.h"
#import "TuneModule.h"
#import "TuneCWorks.h"
#import "TuneManager.h"
#import "TuneInAppUtils.h"
#import "TuneXCTestCase.h"

@interface TuneUtilsTests : TuneXCTestCase

@end


@implementation TuneUtilsTests

static NSString* const testKey = @"fakeTuneKey";
#define expectedKey [NSString stringWithFormat:@"_TUNE_%@", testKey]


- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testHashMd5 {
    static NSString* const input = @"some \"test\" string; 1234, with numbers & symbols!";
    static NSString* const expected = @"a346e5dc2a8d22f2733af9740c5a8756";
    
    NSString *actual = [TuneUtils hashMd5:input];
    
    XCTAssertTrue( [actual isEqualToString:expected], @"expected %@, actual %@", expected, actual );
}

- (void)testHashSha1 {
    static NSString* const input = @"some \"test\" string; 1234, with numbers & symbols!";
    static NSString* const expected = @"310fd0f3e8716db8bb44f474b5fe4bc2336ad967";
    
    NSString *actual = [TuneUtils hashSha1:input];
    
    XCTAssertTrue( [actual isEqualToString:expected], @"expected %@, actual %@", expected, actual );
}

- (void)testHashSha256 {
    static NSString* const input = @"some \"test\" string; 1234, with numbers & symbols!";
    static NSString* const expected = @"36e75466833deaf7fbce4780ed813707a83c261876d2a7f08115d5cb6842b0c4";
    
    NSString *actual = [TuneUtils hashSha256:input];
    
    XCTAssertTrue( [actual isEqualToString:expected], @"expected %@, actual %@", expected, actual );
}

- (void)testUrlEncodeQueryParamValue {
    id input = nil;
    NSString *expected = nil;
    NSString *actual = nil;
    
    input = nil;
    expected = nil;
    actual = [TuneUtils urlEncodeQueryParamValue:input];
    XCTAssertEqual(actual, expected, @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
    
    input = [NSNull null];
    expected = nil;
    actual = [TuneUtils urlEncodeQueryParamValue:input];
    XCTAssertEqual(actual, expected, @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
    
    input = @123.456;
    expected = @"123.456";
    actual = [TuneUtils urlEncodeQueryParamValue:input];
    XCTAssertEqualObjects(actual, expected, @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
    
    input = @"abc.pqr@xyz.com";
    expected = @"abc.pqr%40xyz.com";
    actual = [TuneUtils urlEncodeQueryParamValue:input];
    XCTAssertEqualObjects(actual, expected, @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
    
    input = [NSDate dateWithTimeIntervalSince1970:1420099201];
    expected = @"1420099201";
    actual = [TuneUtils urlEncodeQueryParamValue:input];
    XCTAssertEqualObjects(actual, expected, @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
    
    input = @"Hello Günter";
    expected = @"Hello%20G%C3%BCnter";
    actual = [TuneUtils urlEncodeQueryParamValue:input];
    XCTAssertEqualObjects(actual, expected, @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
    
    input = @"dict[key]=val";
    expected = @"dict%5Bkey%5D%3Dval";
    actual = [TuneUtils urlEncodeQueryParamValue:input];
    XCTAssertEqualObjects(actual, expected, @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
    
    input = @"dict[\"key\"]=\"val\"";
    expected = @"dict%5B%22key%22%5D%3D%22val%22";
    actual = [TuneUtils urlEncodeQueryParamValue:input];
    XCTAssertEqualObjects(actual, expected, @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
    
    input = @"!*'\"();:@&=+$,/?%#[] \n";
    expected = @"%21%2A%27%22%28%29%3B%3A%40%26%3D%2B%24%2C%2F%3F%25%23%5B%5D%20%0A";
    actual = [TuneUtils urlEncodeQueryParamValue:input];
    XCTAssertEqualObjects(actual, expected, @"incorrect url encoding, input = %@, expected = %@, actual = %@", input, expected, actual);
}

- (void)testObjectRespondsToSelector {
    id inputObject = [NSString class];
    SEL inputSEL = @selector(stringWithFormat:);
    XCTAssertTrue([TuneUtils object:inputObject respondsToSelector:inputSEL]);
    
    inputObject = [NSString class];
    inputSEL = NSSelectorFromString(@"kjahduhifawejh");
    XCTAssertFalse([TuneUtils object:inputObject respondsToSelector:inputSEL]);
    
    inputObject = nil;
    inputSEL = NSSelectorFromString(@"stringWithFormat:");
    XCTAssertFalse([TuneUtils object:inputObject respondsToSelector:inputSEL]);
    
    inputObject = nil;
    inputSEL = NSSelectorFromString(@"kjahduhifawejh:");
    XCTAssertFalse([TuneUtils object:inputObject respondsToSelector:inputSEL]);
}

- (void)testGetClassFromString {
    NSString *strObjcClassName = @"TuneUtilsTests";
    XCTAssertEqual([TuneUtilsTests class], [TuneUtils getClassFromString:strObjcClassName]);
}

- (void)testJsonSerialize {
    id input = nil;
    NSString *expected = nil;
    NSString *actual = nil;
    
    input = nil;
    actual = [TuneUtils jsonSerialize:input];
    XCTAssertNil(actual);
    
    input = [NSNull null];
    actual = [TuneUtils jsonSerialize:input];
    XCTAssertNil(actual);
    
    input = @{};
    expected = @"{}";
    actual = [TuneUtils jsonSerialize:input];
    XCTAssertEqualObjects(actual, expected);
    
    input = @[];
    expected = @"[]";
    actual = [TuneUtils jsonSerialize:input];
    XCTAssertEqualObjects(actual, expected);
    
    input = @{@"key1":@"val1", @"key2":@"val2", @"key3":@{@"innerKey1":@"innerVal1"}, @"key4":@[]};
    actual = [TuneUtils jsonSerialize:input];
    expected = @"\"key4\":[]";
    XCTAssertTrue([actual containsString:expected]);
    expected = @"\"key3\":{\"innerKey1\":\"innerVal1\"}";
    XCTAssertTrue([actual containsString:expected]);
    expected = @"\"key2\":\"val2\"";
    XCTAssertTrue([actual containsString:expected]);
    expected = @"\"key1\":\"val1\"";
    XCTAssertTrue([actual containsString:expected]);
    
    input = @[@"val1",@"val2",@[@"innerVal1"],@{@"innerKey1":@"innerVal1"}];
    actual = [TuneUtils jsonSerialize:input];
    expected = @"\"val1\"";
    XCTAssertTrue([actual containsString:expected]);
    expected = @"\"val2\"";
    XCTAssertTrue([actual containsString:expected]);
    expected = @"[\"innerVal1\"]";
    XCTAssertTrue([actual containsString:expected]);
    expected = @"{\"innerKey1\":\"innerVal1\"}";
    XCTAssertTrue([actual containsString:expected]);
}

- (void)testJsonDeSerializeData {
    id input = nil;
    id expected = nil;
    id actual = nil;
    
    input = nil;
    actual = [TuneUtils jsonDeserializeData:input];
    XCTAssertNil(actual);
    
    input = [NSNull null];
    actual = [TuneUtils jsonDeserializeData:input];
    XCTAssertNil(actual);
    
    input = [NSData data];
    actual = [TuneUtils jsonDeserializeData:input];
    XCTAssertNil(actual);
    
    input = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    actual = [TuneUtils jsonDeserializeData:input];
    XCTAssertNil(actual);
    
    input = [@"\"floatingString\"]" dataUsingEncoding:NSUTF8StringEncoding];
    actual = [TuneUtils jsonDeserializeData:input];
    XCTAssertNil(actual);
    
    input = [@"[\"val1\":\"val2\"]" dataUsingEncoding:NSUTF8StringEncoding];
    actual = [TuneUtils jsonDeserializeData:input];
    XCTAssertNil(actual);
    
    input = [@"{\"key1\":\"val1\"}" dataUsingEncoding:NSUTF8StringEncoding];
    actual = [TuneUtils jsonDeserializeData:input];
    expected = @{@"key1":@"val1"};
    XCTAssertEqualObjects(actual, expected);
    
    input = [@"[\"val1\",\"val2\"]" dataUsingEncoding:NSUTF8StringEncoding];
    actual = [TuneUtils jsonDeserializeData:input];
    expected = @[@"val1",@"val2"];
    XCTAssertEqualObjects(actual, expected);
    
    input = [@"[\"val1\",{\"innerKey1\":\"innerVal1\",\"innerKey2\":\"innerVal2\"},[\"innerVal3\",\"innerVal4\"]]" dataUsingEncoding:NSUTF8StringEncoding];
    actual = [TuneUtils jsonDeserializeData:input];
    expected = @"val1";
    XCTAssertTrue([actual[1] isKindOfClass:[NSDictionary class]]);
    expected = @"innerVal1";
    XCTAssertEqualObjects([(NSDictionary *)actual[1] valueForKey:@"innerKey1"], expected);
    expected = @"innerVal2";
    XCTAssertEqualObjects([(NSDictionary *)actual[1] valueForKey:@"innerKey2"], expected);
    XCTAssertTrue([actual[2] isKindOfClass:[NSArray class]]);
    expected = @[@"innerVal3",@"innerVal4"];
    XCTAssertEqualObjects([(NSArray *)actual objectAtIndex:2], expected);
}

- (void)testJsonDeSerializeString {
    id input = nil;
    id expected = nil;
    id actual = nil;
    
    input = nil;
    actual = [TuneUtils jsonDeserializeString:input];
    XCTAssertNil(actual);
    
    input = [NSNull null];
    actual = [TuneUtils jsonDeserializeString:input];
    XCTAssertNil(actual);
    
    input = @"";
    actual = [TuneUtils jsonDeserializeString:input];
    XCTAssertNil(actual);
    
    input = @"\"floatingString\"]";
    actual = [TuneUtils jsonDeserializeString:input];
    XCTAssertNil(actual);
    
    input = @"[\"val1\":\"val2\"]";
    actual = [TuneUtils jsonDeserializeString:input];
    XCTAssertNil(actual);
    
    input = @"{\"key1\":\"val1\"}";
    actual = [TuneUtils jsonDeserializeString:input];
    expected = @{@"key1":@"val1"};
    XCTAssertEqualObjects(actual, expected);
    
    input = @"[\"val1\",\"val2\"]";
    actual = [TuneUtils jsonDeserializeString:input];
    expected = @[@"val1",@"val2"];
    XCTAssertEqualObjects(actual, expected);
    
    input = @"[\"val1\",{\"innerKey1\":\"innerVal1\",\"innerKey2\":\"innerVal2\"},[\"innerVal3\",\"innerVal4\"]]";
    actual = [TuneUtils jsonDeserializeString:input];
    expected = @"val1";
    XCTAssertTrue([actual[1] isKindOfClass:[NSDictionary class]]);
    expected = @"innerVal1";
    XCTAssertEqualObjects([(NSDictionary *)actual[1] valueForKey:@"innerKey1"], expected);
    expected = @"innerVal2";
    XCTAssertEqualObjects([(NSDictionary *)actual[1] valueForKey:@"innerKey2"], expected);
    XCTAssertTrue([actual[2] isKindOfClass:[NSArray class]]);
    expected = @[@"innerVal3",@"innerVal4"];
    XCTAssertEqualObjects([(NSArray *)actual objectAtIndex:2], expected);
}

@end
