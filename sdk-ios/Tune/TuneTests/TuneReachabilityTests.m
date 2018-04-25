//
//  TuneReachabilityTests.m
//  TuneTests
//
//  Created by Jennifer Owens on 4/19/18.
//  Copyright © 2018 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TuneReachability.h"

@interface TuneReachabilityTests : XCTestCase

@end

@implementation TuneReachabilityTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNetworkUnreachableEnumTranslation {
    TuneReachability *reachability = [TuneReachability reachabilityForInternetConnection];
    
    NSString *test = [reachability translateReachabilityStatus:TuneNotReachable];
    XCTAssertNil(test);
}

- (void)testWifiEnumTranslation {
    TuneReachability *reachability = [TuneReachability reachabilityForInternetConnection];
    
    NSString *test = [reachability translateReachabilityStatus:TuneReachableViaWiFi];
    XCTAssertTrue([test isEqualToString:@"wifi"]);
}

- (void)testMobileEnumTranslation {
    TuneReachability *reachability = [TuneReachability reachabilityForInternetConnection];

    NSString *testOfWifi = [reachability translateReachabilityStatus:TuneReachableViaWWAN];
    XCTAssertTrue([testOfWifi isEqualToString:@"mobile"]);
}

@end
