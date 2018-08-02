//
//  TuneUserProfileTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SimpleObserver.h"
#import "Tune+Testing.h"
#import "TuneManager.h"
#import "TuneUserProfile+Testing.h"
#import "TuneAnalyticsVariable.h"
#import "TuneUtils.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneUserProfileKeys.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookConstants.h"
#import "TuneXCTestCase.h"

@interface TuneUserProfileTests : TuneXCTestCase {
    TuneUserProfile *userProfile;
    SimpleObserver *simpleObserver;
}
@end

@implementation TuneUserProfileTests
- (void)setUp {
    [super setUp];
    
    simpleObserver = [[SimpleObserver alloc] init];
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId];
    
    // Wait for everything to be set
    waitForQueuesToFinish();
}

- (void)tearDown {
    emptyRequestQueue();
    
    [super tearDown];
}

- (void)testPrivacyProtectedDueToAgeDefaultValue {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    XCTAssertFalse([profile privacyProtectedDueToAge]);
}

- (void)testPrivacyProtectedDueToAgeSetYES {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    
    [profile setPrivacyProtectedDueToAge:YES];
    XCTAssertTrue([profile privacyProtectedDueToAge]);
}

- (void)testPrivacyProtectedDueToAgeSetNO {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    
    [profile setPrivacyProtectedDueToAge:NO];
    XCTAssertFalse([profile privacyProtectedDueToAge]);
}

- (void)testPrivacyProtectedDueToAgeSetYESThenNO {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    
    [profile setPrivacyProtectedDueToAge:YES];
    XCTAssertTrue([profile privacyProtectedDueToAge]);

    [profile setPrivacyProtectedDueToAge:NO];
    XCTAssertFalse([profile privacyProtectedDueToAge]);
}

- (void)testPrivacyProtectedDueToAgeSetNOThenYES {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    
    [profile setPrivacyProtectedDueToAge:NO];
    XCTAssertFalse([profile privacyProtectedDueToAge]);
    
    [profile setPrivacyProtectedDueToAge:YES];
    XCTAssertTrue([profile privacyProtectedDueToAge]);
}

- (void)testAgeNotSet {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    XCTAssertNil(profile.age);
    XCTAssertFalse([profile tooYoungForTargetedAds]);
}

- (void)testAgeBelow13 {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    [profile setAge:@(6)];

    XCTAssertTrue([profile tooYoungForTargetedAds]);
}

- (void)testAge13 {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    
    [profile setAge:@(13)];
    XCTAssertFalse([profile tooYoungForTargetedAds]);
}

- (void)testAgeOver13 {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    
    [profile setAge:@(21)];
    XCTAssertFalse([profile tooYoungForTargetedAds]);
}

- (void)testPrivacyYESAndAgeBelow13 {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    [profile setPrivacyProtectedDueToAge:YES];
    [profile setAge:@(6)];

    XCTAssertTrue([profile tooYoungForTargetedAds]);
}

- (void)testPrivacyNOAndAgeBelow13 {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    [profile setPrivacyProtectedDueToAge:NO];
    [profile setAge:@(6)];

    XCTAssertTrue([profile tooYoungForTargetedAds]);
}

- (void)testPrivacyYESAndAge13 {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    [profile setPrivacyProtectedDueToAge:YES];
    [profile setAge:@(13)];
    
    XCTAssertTrue([profile tooYoungForTargetedAds]);
}

- (void)testPrivacyNOAndAge13 {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    [profile setPrivacyProtectedDueToAge:NO];
    [profile setAge:@(13)];
    
    XCTAssertFalse([profile tooYoungForTargetedAds]);
}

- (void)testPrivacyYESAndAgeOver13 {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    [profile setPrivacyProtectedDueToAge:YES];
    [profile setAge:@(21)];
    
    XCTAssertTrue([profile tooYoungForTargetedAds]);
}

- (void)testPrivacyNOAndAgeOver13 {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    [profile setPrivacyProtectedDueToAge:NO];
    [profile setAge:@(21)];
    
    XCTAssertFalse([profile tooYoungForTargetedAds]);
}

- (void)testAgeBelow13AndPrivacyYES {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    [profile setAge:@(6)];
    [profile setPrivacyProtectedDueToAge:YES];
    
    XCTAssertTrue([profile tooYoungForTargetedAds]);
}

- (void)testAgeBelow13PrivacyNO {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    [profile setAge:@(6)];
    [profile setPrivacyProtectedDueToAge:NO];
    
    XCTAssertTrue([profile tooYoungForTargetedAds]);
}

- (void)testAge13AndPrivacyYES {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    [profile setAge:@(13)];
    [profile setPrivacyProtectedDueToAge:YES];
    
    XCTAssertTrue([profile tooYoungForTargetedAds]);
}

- (void)testAge13AndPrivacyNO {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    [profile setAge:@(13)];
    [profile setPrivacyProtectedDueToAge:NO];

    XCTAssertFalse([profile tooYoungForTargetedAds]);
}

- (void)testAgeOver13AndPrivacyYES {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    [profile setAge:@(21)];
    [profile setPrivacyProtectedDueToAge:YES];

    XCTAssertTrue([profile tooYoungForTargetedAds]);
}

- (void)testAgeOver13AndPrivacyNO {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    [profile setAge:@(21)];
    [profile setPrivacyProtectedDueToAge:NO];
    
    XCTAssertFalse([profile tooYoungForTargetedAds]);
}

- (void)testTooYoungForTargetedAds {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    XCTAssertNil(profile.age);
    XCTAssertFalse([profile tooYoungForTargetedAds]);
    
    [profile setAge:@(6)];
    XCTAssertTrue([profile tooYoungForTargetedAds]);
    
    [profile setAge:@(13)];
    XCTAssertFalse([profile tooYoungForTargetedAds]);
    
    [profile setAge:@(12)];
    XCTAssertTrue([profile tooYoungForTargetedAds]);
    
    [profile setAge:@(17)];
    XCTAssertFalse([profile tooYoungForTargetedAds]);
    
    [profile setAge:@(-1)];
    XCTAssertTrue([profile tooYoungForTargetedAds]);
    
    [profile setAge:@(0)];
    XCTAssertTrue([profile tooYoungForTargetedAds]);
}

- (void)testReferralURL {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    XCTAssertNil(profile.referralUrl);
    
    NSString *test = @"the quick brown fox";
    [profile setReferralUrl:test];
    
    XCTAssertTrue([[profile referralUrl] isEqualToString:test]);
}

- (void)testReferralURLLengthIsEnforced {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    XCTAssertNil(profile.referralUrl);

    NSString *test = @"the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog.";
    [profile setReferralUrl:test];

    XCTAssertTrue(1024 == [profile referralUrl].length);
    XCTAssertTrue([test containsString:[profile referralUrl]]);
}

// Need another way to verify set, thinking maybe a private getter.
//- (void)testAppleReceiptOnlySentWithFirstSession {
//    // Set first session to true
//    [[TuneManager currentManager].userProfile setIsFirstSession:@(1)];
//
//    // Trigger a marshaling to dictionary as an analytics event would do
//    NSArray *profileArray = [[TuneManager currentManager].userProfile toArrayOfDictionaries];
//
//    // Assert that the user profile toArrayOfDictionaries method contains an apple receipt for the first session
//    NSArray *receiptVar = [[[[TuneManager currentManager].userProfile getProfileVariables] objectForKey:TUNE_KEY_INSTALL_RECEIPT] toArrayOfDicts];
//
//    XCTAssertTrue([profileArray containsObject:receiptVar[0]]);
//
//    // Set first session to false
//    [[TuneManager currentManager].userProfile setIsFirstSession:@(0)];
//
//    // Trigger another marshaling to dictionary
//    profileArray = [[TuneManager currentManager].userProfile toArrayOfDictionaries];
//
//    // Assert that the user profile toArrayOfDictionaries method does not contain an apple receipt for the non-first session
//    XCTAssertFalse([profileArray containsObject:receiptVar[0]]);
//}

- (void)testProfileVariablesDeepCopy {
    NSDictionary *original = [[TuneManager currentManager].userProfile userVariables];
    NSDictionary *copy = [[TuneManager currentManager].userProfile getProfileVariables];

    XCTAssertEqual(original.count, copy.count);
    
    NSArray *originalKeys = [[original allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray *copyKeys = [[copy allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for (int i=0; i<originalKeys.count; i++) {
        id originalObject = [original objectForKey:[originalKeys objectAtIndex:i]];
        id copyObject = [copy objectForKey:[copyKeys objectAtIndex:i]];
        
        // confirm objects are different
        XCTAssert(originalObject != copyObject);
    }
}

- (void)testUpdateConnectionType {
    // This test may fail; connectionType is probably wifi, but it is not explicitly mocked to be
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    XCTAssertTrue([[profile connectionType] isEqualToString:@"wifi"]);
}

@end
