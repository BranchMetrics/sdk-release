//
//  TuneConfigurationTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import "SimpleObserver.h"
#import "Tune+Testing.h"
#import "TuneConfiguration+Testing.h"
#import "TuneConfigurationKeys.h"
#import "TuneFileManager.h"
#import "TuneFileUtils.h"
#import "TuneManager.h"
#import "TuneSkyhookCenter.h"
#import "TuneState.h"

@interface TuneConfigurationTests : XCTestCase
{
    SimpleObserver *simpleObserver;
    TuneConfiguration *configuration;
    TuneFileManager *fileManager;
    TuneState *state;
}
@end

@implementation TuneConfigurationTests

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
    // We don't want to accidently bring down everything when testing the enable/disable stuff
    [[TuneSkyhookCenter defaultCenter] removeObserver:[TuneManager currentManager]];
    
    configuration = [[TuneConfiguration alloc] initWithTuneManager:[TuneManager currentManager]];
    [TuneManager currentManager].configuration = configuration;
    pointMAUrlsToNothing();
    
    state = [TuneState moduleWithTuneManager:[TuneManager currentManager]];
    [TuneManager currentManager].state = state;
    
    [TuneFileManager deleteRemoteConfigurationFromDisk];
    
    simpleObserver = [[SimpleObserver alloc] init];
    
    [configuration registerSkyhooks];
}

- (void)tearDown {
    [configuration unregisterSkyhooks];
    
    [TuneState updateTMAPermanentlyDisabledState:NO];
    [TuneState updateTMADisabledState:NO];
    [TuneState updateConnectedMode:NO];
    
    [super tearDown];
}

- (void)testEmptyConfiguration {
    XCTAssert(!configuration.debugLoggingOn, @"debugLoggingOn is NO");
    
    XCTAssert(TuneConfiguration.frameworkVersion != nil, @"configuration.frameworkVersion is not nil");
    XCTAssert([configuration.apiVersion isEqualToString:@"3"], @"apiVersion is 3");
}

- (void)testEachConfigurationParameter {
    
    NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
    
    [options setValue:@{@"server_configuration":@"value"} forKey:@"server_configuration"];
    [options setValue:@{@"user_defined":@"value"} forKey:@"user_defined"];
    [options setValue:@{@"feature_flags":@"value"} forKey:@"feature_flags"];
    [options setValue:@{@"context_tags":@"value"} forKey:@"context_tags"];
    
    [options setValue:@"api_host_port URL" forKey:@"api_host_port"];
    [options setValue:@"static_content_host_port URL" forKey:@"static_content_host_port"];
    
    [options setValue:@"45" forKey:@"analytics_tracer_dispatch_period"];
    [options setValue:@"YES" forKey:@"debug_logging_on"];
    
    // -------------------------
    
    [configuration updateConfigurationWithLocalDictionary:options postSkyhook:NO];
    
    XCTAssert([configuration.apiHostPort isEqualToString:@"api_host_port URL"], @"apiHostPort is empty");
    
    XCTAssertEqualObjects(configuration.staticContentHostPort, @"static_content_host_port URL", @"staticContentHostPort is static_content_host_port URL");
    XCTAssertTrue(configuration.debugLoggingOn, @"debugLoggingOn is YES");
    
    XCTAssertNotNil(TuneConfiguration.frameworkVersion, @"configuration.frameworkVersion is not nil");
    XCTAssertEqualObjects(configuration.apiVersion, @"3", @"apiVersion is 3");
}

- (void)testStartupConfiguration{
    [configuration setupConfiguration:@{}.mutableCopy];

    XCTAssert(!configuration.debugLoggingOn, @"debugLoggingOn is NO");
    
    XCTAssert(TuneConfiguration.frameworkVersion != nil, @"configuration.frameworkVersion is not nil");
    XCTAssert([configuration.apiVersion isEqualToString:@"3"], @"apiVersion is 3");
}

- (void)testStartupWithRemoteConfiguration{
    [configuration setupConfiguration:@{}.mutableCopy];
    
    NSDictionary *remoteDictionary = @{@"permanently_disabled": @"0"}.mutableCopy;
    
    [remoteDictionary setValue:@"api_host_port URL" forKey:@"api_host_port"];
    [remoteDictionary setValue:@"static_content_host_port URL" forKey:@"static_content_host_port"];
    
    [configuration updateConfigurationWithLocalDictionary:remoteDictionary postSkyhook:NO];
    
    XCTAssert([configuration.apiHostPort isEqualToString:@"api_host_port URL"], @"apiHostPort is api_host_port URL");
    XCTAssert([configuration.staticContentHostPort isEqualToString:@"static_content_host_port URL"], @"staticContentHostPort is static_content_host_port URL");
    XCTAssert(!configuration.debugLoggingOn, @"debugLoggingOn is NO");
    
    XCTAssert(TuneConfiguration.frameworkVersion != nil, @"configuration.frameworkVersion is not nil");
    XCTAssert([configuration.apiVersion isEqualToString:@"3"], @"apiVersion is 3");
}

- (void)testSetupConfigurationNoneSaved {
    
    NSDictionary *testDictionary = @{TUNE_TMA_API_HOST_PORT:@"testApiPort",
                                     TUNE_TMA_ANALYTICS_HOST_PORT:@"analyticsPort",
                                     TUNE_KEY_AUTOCOLLECT_JAILBROKEN:@(YES),
                                     TUNE_KEY_AUTOCOLLECT_LOCATION:@(YES),
                                     TUNE_KEY_AUTOCOLLECT_IFA:@(YES),
                                     TUNE_KEY_AUTOCOLLECT_IFV:@(YES),
                                     TUNE_ANALYTICS_MESSAGE_LIMIT:@(800)};
    
    [configuration setupConfiguration:testDictionary];
    
    XCTAssertEqualObjects(testDictionary[TUNE_TMA_API_HOST_PORT], configuration.apiHostPort, @"unsaved api host property does not match");
    XCTAssertEqualObjects(testDictionary[TUNE_TMA_ANALYTICS_HOST_PORT], configuration.analyticsHostPort, @"unsaved  property does not match");
    XCTAssertEqualObjects(testDictionary[TUNE_KEY_AUTOCOLLECT_JAILBROKEN], @(configuration.shouldAutoDetectJailbroken), @"unsaved  property does not match");
    XCTAssertEqualObjects(testDictionary[TUNE_KEY_AUTOCOLLECT_LOCATION], @(configuration.shouldAutoCollectDeviceLocation), @"unsaved  property does not match");
    XCTAssertEqualObjects(testDictionary[TUNE_KEY_AUTOCOLLECT_IFA], @(configuration.shouldAutoCollectAdvertisingIdentifier), @"unsaved  property does not match");
    XCTAssertEqualObjects(testDictionary[TUNE_KEY_AUTOCOLLECT_IFV], @(configuration.shouldAutoGenerateVendorIdentifier), @"unsaved  property does not match");
    XCTAssertEqualObjects(testDictionary[TUNE_ANALYTICS_MESSAGE_LIMIT], configuration.analyticsMessageStorageLimit, @"unsaved  property does not match");
}

- (void)testSetupConfigurationWithSaved {
    NSDictionary *testDictionary = @{TUNE_TMA_API_HOST_PORT:@"testApiPort",
                                     TUNE_TMA_ANALYTICS_HOST_PORT:@"analyticsPort",
                                     TUNE_KEY_AUTOCOLLECT_JAILBROKEN:@(YES),
                                     TUNE_KEY_AUTOCOLLECT_LOCATION:@(YES),
                                     TUNE_KEY_AUTOCOLLECT_IFA:@(YES),
                                     TUNE_KEY_AUTOCOLLECT_IFV:@(YES),
                                     TUNE_ANALYTICS_MESSAGE_LIMIT:@(800)};
    
    NSDictionary *savedDictionary = @{TUNE_KEY_AUTOCOLLECT_IFA:@(NO),
                                     TUNE_KEY_AUTOCOLLECT_IFV:@(NO),
                                     TUNE_ANALYTICS_MESSAGE_LIMIT:@(300)};
    
    [TuneFileManager saveRemoteConfigurationToDisk:savedDictionary];
    [configuration setupConfiguration:testDictionary];
    
    XCTAssertTrue([savedDictionary[TUNE_KEY_AUTOCOLLECT_IFA] boolValue] == configuration.shouldAutoCollectAdvertisingIdentifier, @"saved autocollect ifa config value not used");
    XCTAssertTrue([savedDictionary[TUNE_KEY_AUTOCOLLECT_IFV] boolValue] == configuration.shouldAutoGenerateVendorIdentifier, @"saved autocollect ifv config value not used");
    XCTAssertEqualObjects(savedDictionary[TUNE_ANALYTICS_MESSAGE_LIMIT], configuration.analyticsMessageStorageLimit, @"saved message limit config value not used");
}

- (void)testTMANotPermanentlyDisabledMeansTMAIsOn {
    XCTAssertFalse([TuneState isTMAPermanentlyDisabled]);
    XCTAssertFalse([TuneState isTMADisabled]);
    
    NSDictionary *remoteDictionary = @{@"permanently_disabled": @"0" };
    
    [configuration updateConfigurationWithRemoteDictionary:remoteDictionary];
    XCTAssertFalse([TuneState isTMAPermanentlyDisabled]);
    XCTAssertFalse([TuneState isTMADisabled]);
}

- (void)testTMAPermanentlyDisabledMeansTMAIsOff {
    XCTAssertFalse([TuneState isTMAPermanentlyDisabled]);
    XCTAssertFalse([TuneState isTMADisabled]);
    
    NSDictionary *remoteDictionary = @{@"permanently_disabled": @"1" };
    
    [configuration updateConfigurationWithRemoteDictionary:remoteDictionary];
    XCTAssertTrue([TuneState isTMAPermanentlyDisabled]);
    XCTAssertTrue([TuneState isTMADisabled]);
}

- (void)testTMAConnectedModeOn {
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TuneStateTMAConnectedModeTurnedOn object:nil];
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    
    XCTAssertFalse([TuneState isInConnectedMode]);
    
    NSDictionary *remoteDictionary = @{@"connected_mode": @"1" };
    
    [configuration updateConfigurationWithRemoteDictionary:remoteDictionary];
    
    XCTAssertTrue([TuneState isInConnectedMode]);
    XCTAssertEqual([simpleObserver skyhookPostCount], 1);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:simpleObserver name:TuneStateTMAConnectedModeTurnedOn object:nil];
}

- (void)testTMAConnectedModeOff {
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TuneStateTMAConnectedModeTurnedOn object:nil];
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    
    XCTAssertFalse([TuneState isInConnectedMode]);
    
    NSDictionary *remoteDictionary = @{@"connected_mode": @"0" };
    
    [configuration updateConfigurationWithRemoteDictionary:remoteDictionary];
    
    XCTAssertFalse([TuneState isInConnectedMode]);
    XCTAssertEqual([simpleObserver skyhookPostCount], 0);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:simpleObserver name:TuneStateTMAConnectedModeTurnedOn object:nil];
}

- (void)testTMAConnectedModeOffIfNotSpecified {
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TuneStateTMAConnectedModeTurnedOn object:nil];
    [[TuneSkyhookCenter defaultCenter] startSkyhookQueue];
    
    XCTAssertFalse([TuneState isInConnectedMode]);
    
    NSDictionary *remoteDictionary = @{@"nothing_to_do_with_connected_mode": @"1" };
    
    [configuration updateConfigurationWithRemoteDictionary:remoteDictionary];
    XCTAssertFalse([TuneState isInConnectedMode]);
    XCTAssertEqual([simpleObserver skyhookPostCount], 0);
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:simpleObserver name:TuneStateTMAConnectedModeTurnedOn object:nil];
}

- (void)testTMAPermanentlyDisabledIsPermanent {
    XCTAssertFalse([TuneState isTMAPermanentlyDisabled]);
    XCTAssertFalse([TuneState isTMADisabled]);
    
    NSDictionary *remoteDictionary = @{@"permanently_disabled": @"1" };
    
    [configuration updateConfigurationWithRemoteDictionary:remoteDictionary];
    XCTAssertTrue([TuneState isTMAPermanentlyDisabled]);
    XCTAssertTrue([TuneState isTMADisabled]);
    
    remoteDictionary = @{@"permanently_disabled": @"0" };
    
    [configuration updateConfigurationWithRemoteDictionary:remoteDictionary];
    XCTAssertTrue([TuneState isTMAPermanentlyDisabled]);
    XCTAssertTrue([TuneState isTMADisabled]);
    
}

- (void)testTMADisabledMeansTMAisDisabled {
    XCTAssertFalse([TuneState isTMAPermanentlyDisabled]);
    XCTAssertFalse([TuneState isTMADisabled]);
    
    NSDictionary *remoteDictionary = @{@"disabled": @"1" };
    
    [configuration updateConfigurationWithRemoteDictionary:remoteDictionary];
    XCTAssertFalse([TuneState isTMAPermanentlyDisabled]);
    XCTAssertTrue([TuneState isTMADisabled]);
    
    remoteDictionary = @{@"disabled": @"0" };
    
    [configuration updateConfigurationWithRemoteDictionary:remoteDictionary];
    XCTAssertFalse([TuneState isTMAPermanentlyDisabled]);
    XCTAssertFalse([TuneState isTMADisabled]);
}

@end
