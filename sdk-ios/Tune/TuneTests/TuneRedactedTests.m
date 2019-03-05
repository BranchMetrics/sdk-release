//
//  TuneRedactedTests.m
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

@interface TuneRedactedTests : TuneXCTestCase
@property (nonatomic, strong, readwrite) NSString *userId;
@end

@implementation TuneRedactedTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId];
    [[TuneManager currentManager].userProfile setAppAdTracking:@(YES)];
    [[TuneManager currentManager].userProfile setAppleAdvertisingTrackingEnabled:@(YES)];

    self.userId = @"Test User";
    [[TuneManager currentManager].userProfile setUserId:self.userId];

    [Tune setPrivacyProtectedDueToAge:YES];

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
    XCTAssertTrue([[TuneManager currentManager].userProfile shouldRedactKey:TUNE_KEY_USER_ID]);
}

// programmatically check every system variable
- (void)testSystemVariables {
    NSSet *variables = [TuneUserProfileKeys systemVariables];
    NSSet *whiteList = [TuneUserProfileKeys privacyProtectionWhiteList];
    
    NSSet *blackList = [TuneUserProfileKeys branchBlacklist];
    
    for (NSString *key in variables) {
        if ([whiteList containsObject:key] && ![blackList containsObject:key]) {
            XCTAssertFalse([[TuneManager currentManager].userProfile shouldRedactKey:key]);
        } else {
            XCTAssertTrue([[TuneManager currentManager].userProfile shouldRedactKey:key]);
        }
    }
}

- (void)testUserIdValueUnchanged {
    NSString *userId = [[TuneManager currentManager].userProfile userId];
    XCTAssertEqual(userId, self.userId);
}

- (void)testAdTrackingValueSetToNO {
    NSNumber *adTracking = [[TuneManager currentManager].userProfile appAdTracking];
    XCTAssertFalse(adTracking.boolValue);
}

- (void)testAppleAdvertisingTrackingEnabledValueSetToNO {
    NSNumber *adTracking = [[TuneManager currentManager].userProfile appleAdvertisingTrackingEnabled];
    XCTAssertFalse(adTracking.boolValue);
}

@end
