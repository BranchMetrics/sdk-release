//
//  TuneNotInitializedTests.m
//  TuneTests
//
//  Created by Audrey Troutt on 3/2/18.
//  Copyright © 2018 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Tune.h"
#import "TuneUserProfile.h"
#import "TuneManager.h"

@interface TuneNotInitializedTests : XCTestCase

@end

@implementation TuneNotInitializedTests

- (void)testProveTuneIsNotInitialized {
    // there's no advertiserId because no init has happened
    XCTAssertNil([[TuneManager currentManager].userProfile advertiserId]);
    // there's no conversionKey because no init has happened
    XCTAssertNil([[TuneManager currentManager].userProfile conversionKey]);
    // the package name is pulled from the test target, so it is set.
    XCTAssertEqualObjects(@"com.tune.TuneTests", [[TuneManager currentManager].userProfile packageName]);
}

@end
