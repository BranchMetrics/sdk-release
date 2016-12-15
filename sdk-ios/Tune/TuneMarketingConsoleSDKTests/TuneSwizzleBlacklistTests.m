//
//  TuneSwizzleBlacklistTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/28/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "TuneSwizzleBlacklist+Testing.h"
#import "TuneFileManager.h"
#import "TuneState+Testing.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneXCTestCase.h"

@interface TuneSwizzleBlacklistTests : TuneXCTestCase {
    id fileManagerMock;
}

@end

@implementation TuneSwizzleBlacklistTests

- (void)setUp {
    [super setUp];
    
    fileManagerMock = OCMClassMock([TuneFileManager class]);
    [TuneState resetLocalConfig];
}

- (void)tearDown {
    [fileManagerMock stopMocking];
    
    [TuneSwizzleBlacklist reset];
    [TuneState resetLocalConfig];
    
    [super tearDown];
}

#pragma mark - Simple Class Is On Blacklist Tests

- (void)testClassIsOnBlacklistReturnsTrueForDefaultBlacklistClasses {
    // Random classes from the buildBaseViewControllerBlacklist list
    XCTAssertTrue([TuneSwizzleBlacklist classIsOnBlackList:@"ABContactViewController"]);
    XCTAssertTrue([TuneSwizzleBlacklist classIsOnBlackList:@"_ABPeoplePickerNavigationController"]);
    XCTAssertTrue([TuneSwizzleBlacklist classIsOnBlackList:@"EKEventDetailExtendedNotesViewController"]);
    XCTAssertTrue([TuneSwizzleBlacklist classIsOnBlackList:@"EKEventAttendeePicker"]);
    XCTAssertTrue([TuneSwizzleBlacklist classIsOnBlackList:@"UIImagePickerController"]);
    XCTAssertTrue([TuneSwizzleBlacklist classIsOnBlackList:@"UIActivityViewController"]);
    XCTAssertTrue([TuneSwizzleBlacklist classIsOnBlackList:@"MFMailComposePlaceholderViewController"]);
}

- (void)testClassIsOnBlacklistReturnsFalseForRandomClasses {
    XCTAssertFalse([TuneSwizzleBlacklist classIsOnBlackList:@"GOWTestViewController"]);
    XCTAssertFalse([TuneSwizzleBlacklist classIsOnBlackList:@"GOWAnotherTestViewController"]);
    XCTAssertFalse([TuneSwizzleBlacklist classIsOnBlackList:@"DoesntReallyMatterWhatTheseAreCalled"]);
}

- (void)testClassIsOnBlcklistReturnsTrueWhenPrefixedWithUnderscore {
    XCTAssertTrue([TuneSwizzleBlacklist classIsOnBlackList:@"_UIPrivateAppleViewController"]);
}

#pragma mark - Reading new Blacklists from Disk/UserDefaults Tests

- (void)testClassIsOnBlacklistReturnsTrueWhenViewControllerComesFromDisk {
    XCTAssertFalse([TuneSwizzleBlacklist classIsOnBlackList:@"UIViewController"]);
    OCMStub([fileManagerMock loadLocalConfigurationFromDisk]).andReturn(@{ @"TMABlacklistedViewControllerClasses": @[ @"UIViewController" ] });
    
    [TuneSwizzleBlacklist reset];
    
    XCTAssertTrue([TuneSwizzleBlacklist classIsOnBlackList:@"UIViewController"]);
}

- (void)testClassIsOnBlacklistReturnsTrueWhenViewControllerIsAddedViewUserDefaults {
    XCTAssertFalse([TuneSwizzleBlacklist classIsOnBlackList:@"ARPCustomViewController"]);
    
    [TuneUserDefaultsUtils setUserDefaultValue:@[ @"ARPCustomViewController" ] forKey:@"swizzle_blacklist_additions"];
    
    [TuneSwizzleBlacklist reset];
    
    XCTAssertTrue([TuneSwizzleBlacklist classIsOnBlackList:@"ARPCustomViewController"]);
}

- (void)testClassIsOnBlacklistReturnsFalseWhenViewControllerIsRemovedViaUserDefaults {
    XCTAssertTrue([TuneSwizzleBlacklist classIsOnBlackList:@"AROverlayViewController"]);
    
    [TuneUserDefaultsUtils setUserDefaultValue:@[ @"AROverlayViewController" ] forKey:@"swizzle_blacklist_removals"];
    
    [TuneSwizzleBlacklist reset];
    
    XCTAssertFalse([TuneSwizzleBlacklist classIsOnBlackList:@"AROverlayViewController"]);
}


@end
