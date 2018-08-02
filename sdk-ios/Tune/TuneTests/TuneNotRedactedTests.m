//
//  TuneNotRedactedTests.m
//  TuneTests
//
//  Created by Ernest Cho on 11/30/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneXCTestCase.h"
#import "Tune.h"
#import "TuneUserProfile.h"
#import "TuneUserProfileKeys.h"

@interface TuneUserProfile()
- (BOOL)shouldRedactKey:(NSString *)key;
@end

@interface TuneNotRedactedTests : TuneXCTestCase
@property (nonatomic, strong, readwrite) NSString *userId;
@end

@implementation TuneNotRedactedTests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId];
    [[TuneManager currentManager].userProfile setAppAdTracking:@(YES)];
    [[TuneManager currentManager].userProfile setAppleAdvertisingTrackingEnabled:@(YES)];
    
    self.userId = @"Test User";
    [[TuneManager currentManager].userProfile setUserId:self.userId];
    
    // Wait for everything to be set
    waitForQueuesToFinish();
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// if this test fails, the other tests are invalid as user profile initialization failed
- (void)testUserProfileExists {
    XCTAssertTrue([TuneManager currentManager].userProfile);
}

- (void)testNil {
    XCTAssertFalse([[TuneManager currentManager].userProfile shouldRedactKey:nil]);
}

- (void)testEmptyString {
    XCTAssertFalse([[TuneManager currentManager].userProfile shouldRedactKey:@""]);
}

- (void)testFooBar {
    XCTAssertFalse([[TuneManager currentManager].userProfile shouldRedactKey:@"FooBar"]);
}

- (void)testAppAdTracking {
    XCTAssertFalse([[TuneManager currentManager].userProfile shouldRedactKey:TUNE_KEY_APP_AD_TRACKING]);
}

- (void)testAppleAdvertisingTrackingEnabled {
    XCTAssertFalse([[TuneManager currentManager].userProfile shouldRedactKey:TUNE_KEY_IOS_AD_TRACKING]);
}

- (void)testUserId {
    XCTAssertFalse([[TuneManager currentManager].userProfile shouldRedactKey:TUNE_KEY_USER_ID]);
}

// programmatically check every system variable
- (void)testSystemVariables {
    NSSet *variables = [TuneUserProfileKeys systemVariables];
    
    for (NSString *key in variables) {
        XCTAssertFalse([[TuneManager currentManager].userProfile shouldRedactKey:key]);
    }
}

- (void)testUserIdValueUnchanged {
    NSString *userId = [[TuneManager currentManager].userProfile userId];
    XCTAssertEqual(userId, self.userId);
}

- (void)testAdTrackingValueUnchanged {
    NSNumber *adTracking = [[TuneManager currentManager].userProfile appAdTracking];
    XCTAssertTrue(adTracking.boolValue);
}

- (void)testAppleAdvertisingTrackingEnabledValueUnchanged {
    NSNumber *adTracking = [[TuneManager currentManager].userProfile appleAdvertisingTrackingEnabled];
    XCTAssertTrue(adTracking.boolValue);
}

@end
