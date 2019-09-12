//
//  TuneUserAgentCollectorTests.m
//
//  Created by Ernest Cho on 8/29/19.
//  Copyright © 2019 Branch, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneUserAgentCollector.h"

// expose private methods for unit testing
@interface TuneUserAgentCollector()

+ (NSString *)userAgentKey;
+ (NSString *)systemBuildVersionKey;

- (NSString *)loadUserAgentForSystemBuildVersion:(NSString *)systemBuildVersion;
- (void)saveUserAgent:(NSString *)userAgent forSystemBuildVersion:(NSString *)systemBuildVersion;
- (void)collectUserAgentWithCompletion:(void (^)(NSString * _Nullable userAgent))completion;

- (void)loadUserAgentForSystemBuildVersion:(NSString *)systemBuildVersion withCompletion:(void (^)(NSString *userAgent))completion;

@end

@interface TuneUserAgentCollectorTests : XCTestCase

@end

@implementation TuneUserAgentCollectorTests

+ (void)setUp {
    [TuneUserAgentCollectorTests resetPersistentData];
}

- (void)setUp {

}

- (void)tearDown {
    [TuneUserAgentCollectorTests resetPersistentData];
}

+ (void)resetPersistentData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:nil forKey:[TuneUserAgentCollector userAgentKey]];
    [defaults setObject:nil forKey:[TuneUserAgentCollector systemBuildVersionKey]];
}

- (void)testResetPersistentData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *savedUserAgent = (NSString *)[defaults valueForKey:[TuneUserAgentCollector userAgentKey]];
    NSString *savedSystemBuildVersion = (NSString *)[defaults valueForKey:[TuneUserAgentCollector systemBuildVersionKey]];
    
    XCTAssertNil(savedUserAgent);
    XCTAssertNil(savedSystemBuildVersion);
}

- (void)testSaveAndLoadUserAgent {
    NSString *systemBuildVersion = @"test";
    NSString *userAgent = @"UserAgent";

    TuneUserAgentCollector *collector = [TuneUserAgentCollector new];
    [collector saveUserAgent:userAgent forSystemBuildVersion:systemBuildVersion];
    NSString *expected = [collector loadUserAgentForSystemBuildVersion:systemBuildVersion];
    XCTAssertTrue([userAgent isEqualToString:expected]);
}

- (void)testCollectUserAgent {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    
    TuneUserAgentCollector *collector = [TuneUserAgentCollector new];
    [collector collectUserAgentWithCompletion:^(NSString * _Nullable userAgent) {
        XCTAssertNotNil(userAgent);
        XCTAssertTrue([userAgent containsString:@"AppleWebKit"]);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)testLoadUserAgent_EmptyDataStore {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    NSString *systemBuildVersion = @"test";

    TuneUserAgentCollector *collector = [TuneUserAgentCollector new];
    [collector loadUserAgentForSystemBuildVersion:systemBuildVersion withCompletion:^(NSString * _Nullable userAgent) {
        XCTAssertNotNil(userAgent);
        XCTAssertTrue([userAgent containsString:@"AppleWebKit"]);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)testLoadUserAgent_FilledDataStore {
    XCTestExpectation *expectation = [self expectationWithDescription:@"expectation"];
    NSString *systemBuildVersion = @"test";
    NSString *savedUserAgent = @"UserAgent";
    
    TuneUserAgentCollector *collector = [TuneUserAgentCollector new];
    [collector saveUserAgent:savedUserAgent forSystemBuildVersion:systemBuildVersion];
    [collector loadUserAgentForSystemBuildVersion:systemBuildVersion withCompletion:^(NSString * _Nullable userAgent) {
        XCTAssertNotNil(userAgent);
        XCTAssertTrue([userAgent isEqualToString:savedUserAgent]);
        XCTAssertFalse([userAgent containsString:@"AppleWebKit"]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError * _Nullable error) {
        
    }];
}

@end
