//
//  TuneDeepLinkerTests.m
//  TuneTests
//
//  Created by Ernest Cho on 12/20/18.
//  Copyright © 2018 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneDeeplinker.h"

@interface TuneDeepLinkerTests : XCTestCase

@end

@implementation TuneDeepLinkerTests

- (void)setUp {
    
}

- (void)tearDown {

}

- (void)testIsTuneLink_Nil {
    XCTAssertFalse([TuneDeeplinker isTuneLink:nil]);
}

- (void)testIsTuneLink_EmptyString {
    XCTAssertFalse([TuneDeeplinker isTuneLink:@""]);
}

- (void)testIsTuneLink_InvalidURL {
    XCTAssertFalse([TuneDeeplinker isTuneLink:@"12345678"]);
}

- (void)testIsTuneLink_Google {
    XCTAssertFalse([TuneDeeplinker isTuneLink:@"https://www.google.com"]);
}

- (void)testIsTuneLink_tlnkio {
    XCTAssertTrue([TuneDeeplinker isTuneLink:@"https://tlnk.io/stuff"]);
}

- (void)testIsTuneLink_abctlnkio {
    XCTAssertTrue([TuneDeeplinker isTuneLink:@"https://abc.tlnk.io/stuff"]);
}

- (void)testIsTuneLink_123tlnkio {
    XCTAssertTrue([TuneDeeplinker isTuneLink:@"https://123.tlnk.io/stuff"]);
}

- (void)testIsTuneLink_applink {
    XCTAssertTrue([TuneDeeplinker isTuneLink:@"https://app.link/stuff"]);
}

- (void)testIsTuneLink_abcapplink {
    XCTAssertTrue([TuneDeeplinker isTuneLink:@"https://abc.app.link/stuff"]);
}

- (void)testIsTuneLink_123applink {
    XCTAssertTrue([TuneDeeplinker isTuneLink:@"https://123.app.link/stuff"]);
}

@end
