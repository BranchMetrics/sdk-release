//
//  TuneStateTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/14/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "TuneState+Testing.h"
#import "TuneFileManager.h"
#import "TuneUserDefaultsUtils.h"

@interface TuneStateTests : XCTestCase {
    id fileManagerMock;
}

@end

@implementation TuneStateTests

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
    
    fileManagerMock = OCMClassMock([TuneFileManager class]);
    [TuneState resetLocalConfig];
    
    [super setUp];
}

- (void)tearDown {
    [fileManagerMock stopMocking];
    [TuneState resetLocalConfig];
    
    [super tearDown];
}

- (void)resetConfig {
    // Needed b/c you can't change the Stub return without remocking.
    // SEE: https://github.com/erikdoe/ocmock/issues/103
    [fileManagerMock stopMocking];
    fileManagerMock = OCMClassMock([TuneFileManager class]);
    [TuneState resetLocalConfig];
}

- (void)testGlobalSwizzleEnabledByDefault {
    XCTAssertFalse([TuneState isSwizzleDisabled]);
}

- (void)testGlobalSwizzleDisabledByNSUserDefaults {
    XCTAssertFalse([TuneState isSwizzleDisabled]);
    [TuneUserDefaultsUtils setUserDefaultValue:@(YES) forKey:@"TMASwizzleDisabled"];
    XCTAssertTrue([TuneState isSwizzleDisabled]);
    [TuneUserDefaultsUtils setUserDefaultValue:@(NO) forKey:@"TMASwizzleDisabled"];
    XCTAssertFalse([TuneState isSwizzleDisabled]);
}

- (void)testGlobalSwizzleDisabledByLocalConfig {
    XCTAssertFalse([TuneState isSwizzleDisabled]);

    [self resetConfig];
    OCMStub([fileManagerMock loadLocalConfigurationFromDisk]).andReturn(@{ @"TMASwizzleDisabled": @(YES) });
    XCTAssertTrue([TuneState isSwizzleDisabled]);

    [self resetConfig];
    OCMStub([fileManagerMock loadLocalConfigurationFromDisk]).andReturn(@{ @"TMASwizzleDisabled": @(NO) });
    XCTAssertFalse([TuneState isSwizzleDisabled]);
}

- (void)testGlobalSwizzleNSUserDefaultsOverridesLocalConfig {
    XCTAssertFalse([TuneState isSwizzleDisabled]);
    
    [self resetConfig];
    OCMStub([fileManagerMock loadLocalConfigurationFromDisk]).andReturn(@{ @"TMASwizzleDisabled": @(NO) });
    [TuneUserDefaultsUtils setUserDefaultValue:@(YES) forKey:@"TMASwizzleDisabled"];
    XCTAssertTrue([TuneState isSwizzleDisabled]);
    
    [self resetConfig];
    OCMStub([fileManagerMock loadLocalConfigurationFromDisk]).andReturn(@{ @"TMASwizzleDisabled": @(YES) });
    [TuneUserDefaultsUtils setUserDefaultValue:@(NO) forKey:@"TMASwizzleDisabled"];
    XCTAssertFalse([TuneState isSwizzleDisabled]);
}

@end
