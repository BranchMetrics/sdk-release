//
//  TuneUtilsTests.m
//  Tune
//
//  Created by Harshal Ogale on 1/24/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneUtils+Testing.h"
#import "TuneUserProfile.h"
#import "TuneModule.h"
#import "TuneCWorks.h"
#import "TuneManager.h"
#import "TuneInAppUtils.h"

@interface TuneUtilsTests : XCTestCase

@end


@implementation TuneUtilsTests

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

- (void)testNewKeyRead {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *oldTuneId = [defaults valueForKey:@"_TUNE_mat_id"];
    
    static NSString* const newTuneId = @"fakeTuneId";
    
    // write a string to a new-style key
    [defaults setObject:newTuneId forKey:@"_TUNE_mat_id"];
    [defaults synchronize];
    
    // assert that the new-style key is read by TuneSettings
    TuneUserProfile *userProfile = [[TuneUserProfile new] initWithTuneManager:[TuneManager currentManager]];
    NSString *readTuneId = userProfile.tuneId;
    XCTAssertTrue( [readTuneId isEqualToString:newTuneId], @"stored %@, read %@", newTuneId, readTuneId );
    
    [defaults setValue:oldTuneId forKey:@"_TUNE_mat_id"];
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

- (void)testDontCrashIfCantDownloadImages {
    NSMutableDictionary *results = @{@"WTFQBBURL.nope": @YES}.mutableCopy;
    dispatch_group_t group = dispatch_group_create();
    
    [TuneInAppUtils downloadImages:results withDispatchGroup:group];
    
    waitFor(0.1);
    
    XCTAssertFalse([results[@"WTFQBBURL.nope"] boolValue]);
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

@end
