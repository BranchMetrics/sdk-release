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

- (void)testGetIAMAppId {
    // this is the app id you get with a nil advertiser id, a "com.tune.TuneTests" package name
    XCTAssertEqualObjects(@"19b36aa5f3130f12d46c4f8048b55445", [Tune getIAMAppId]);
}

- (void)testGetIAMDeviceIdentifier {
    // Since the SDK is not initialized, it hasn't even tried to get the aid yet
    XCTAssertNil([Tune appleAdvertisingIdentifier]);
    // the Tune Id is generated already, though
    XCTAssertNotNil([Tune tuneId]);
    // Tune Id is not null, so the calculated IAM device identifier is not null
    XCTAssertNotNil([Tune getIAMDeviceIdentifier]);
}

@end
