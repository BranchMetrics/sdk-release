//
//  TuneInAppUtilsTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 4/20/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TuneInAppUtils.h"

@interface TuneInAppUtilsTests : XCTestCase

@end

@implementation TuneInAppUtilsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPropertyIsNotEmpty {
    XCTAssertFalse([TuneInAppUtils propertyIsNotEmpty:nil]);
    XCTAssertFalse([TuneInAppUtils propertyIsNotEmpty:@""]);
    XCTAssertFalse([TuneInAppUtils propertyIsNotEmpty:[NSMutableString new]]);
    
    XCTAssertTrue([TuneInAppUtils propertyIsNotEmpty:[NSNull null]]);
    XCTAssertTrue([TuneInAppUtils propertyIsNotEmpty:@NO]);
    XCTAssertTrue([TuneInAppUtils propertyIsNotEmpty:[NSObject new]]);
    XCTAssertTrue([TuneInAppUtils propertyIsNotEmpty:@"abc"]);
    XCTAssertTrue([TuneInAppUtils propertyIsNotEmpty:[NSMutableString stringWithString:@"abcdef"]]);
}

@end
