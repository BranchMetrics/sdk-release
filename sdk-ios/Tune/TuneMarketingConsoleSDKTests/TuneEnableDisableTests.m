//
//  TuneEnableDisableTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/14/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "TuneManager+Testing.h"
#import "TuneHttpResponse.h"
#import "TuneHttpRequest.h"
#import "TuneApi.h"
#import "TuneSkyhookCenter.h"
#import "SimpleObserver.h"
#import "TuneSkyhookConstants.h"
#import "TuneState.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneStorageKeys.h"

@interface TuneEnableDisableTests : XCTestCase {
    id apiMock;
    id fileManagerMock;
    id request;
    id tuneStateMock;
    
    TuneHttpResponse *newResponse;
    NSDictionary *playlistDictionary;
    
    SimpleObserver *activatedObserver;
    SimpleObserver *deactivatedObserver;
    SimpleObserver *permanentlyDeactivatedObserver;
}

@end

@implementation TuneEnableDisableTests

- (void)setUp {
    [super setUp];
    RESET_EVERYTHING();
    [TuneManager nilModules];
    
    activatedObserver = [[SimpleObserver alloc] init];
    deactivatedObserver  = [[SimpleObserver alloc] init];
    permanentlyDeactivatedObserver  = [[SimpleObserver alloc] init];
    
    tuneStateMock = OCMClassMock([TuneState class]);
    OCMStub([tuneStateMock didOptIntoTMA]).andReturn(YES);
}

- (void)tearDown {
    [request stopMocking];
    [apiMock stopMocking];
    [fileManagerMock stopMocking];
    [tuneStateMock stopMocking];

    [super tearDown];
}

- (void)preparePlaylistWith:(NSDictionary *)d {
    [apiMock stopMocking];
    [request stopMocking];
    
    playlistDictionary = d.copy;
    
    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] init] statusCode:200 HTTPVersion:@"1.2" headerFields:@{}];
    newResponse = [[TuneHttpResponse alloc] initWithURLResponse:urlResponse andError:nil];
    [newResponse setResponseDictionary:playlistDictionary];
    
    request = OCMClassMock([TuneHttpRequest class]);
    
    OCMStub([request performAsynchronousRequestWithCompletionBlock:OCMOCK_ANY]).andCall(self, @selector(performAsynchronousRequestWithCompletionBlock:));
    
    apiMock = OCMClassMock([TuneApi class]);
    OCMStub([apiMock getPlaylistRequest]).andReturn(request);
}

- (void)prepareConfigWith:(NSDictionary *)d {
    [apiMock stopMocking];
    [request stopMocking];
    
    playlistDictionary = d.copy;
    
    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] init] statusCode:200 HTTPVersion:@"1.2" headerFields:@{}];
    newResponse = [[TuneHttpResponse alloc] initWithURLResponse:urlResponse andError:nil];
    [newResponse setResponseDictionary:playlistDictionary];
    
    request = OCMClassMock([TuneHttpRequest class]);
    
    OCMStub([request performAsynchronousRequestWithCompletionBlock:OCMOCK_ANY]).andCall(self, @selector(performAsynchronousRequestWithCompletionBlock:));
    
    apiMock = OCMClassMock([TuneApi class]);
    OCMStub([apiMock getConfigurationRequest]).andReturn(request);
}

- (void)testTMANotTurnedOnViaConfiguration {
    [TuneUserDefaultsUtils clearUserDefaultValue:TMAStateDisabled];
    
    [tuneStateMock stopMocking];
    tuneStateMock = OCMClassMock([TuneState class]);
    OCMStub([tuneStateMock didOptIntoTMA]).andReturn(NO);
    
    SimpleObserver *observer = [[SimpleObserver alloc] init];
    [[TuneSkyhookCenter defaultCenter] addObserver:observer selector:@selector(skyhookPosted:) name:TuneStateTMAActivated object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:observer selector:@selector(skyhookPosted:) name:TuneStateTMADeactivated object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:observer selector:@selector(skyhookPosted:) name:TuneConfigurationUpdated object:nil];
    
    [TuneManager instantiateModules];
    
    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNil([TuneManager currentManager].triggerManager);
    XCTAssertNil([TuneManager currentManager].campaignStateManager);
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification];
    
    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNil([TuneManager currentManager].triggerManager);
    XCTAssertNil([TuneManager currentManager].campaignStateManager);
    
    XCTAssertEqual(0, [observer skyhookPostCount]);
}

- (void)testTMATurnedOnViaConfiguration {
#if !TARGET_OS_TV
    [TuneUserDefaultsUtils clearUserDefaultValue:TMAStateDisabled];
    
    SimpleObserver *observer = [[SimpleObserver alloc] init];
    // Should not send this since we start in the Active state when opted in (and no need for this Activated skyhook)
    [[TuneSkyhookCenter defaultCenter] addObserver:observer selector:@selector(skyhookPosted:) name:TuneStateTMAActivated object:nil];
    
    [TuneManager instantiateModules];
    
    
    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNotNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNotNil([TuneManager currentManager].triggerManager);
    XCTAssertNotNil([TuneManager currentManager].campaignStateManager);
    
    
    [self prepareConfigWith:@{@"disabled": @"0"}];
    
    // Ensure we requested the configuration
    [[TuneSkyhookCenter defaultCenter] addObserver:observer selector:@selector(skyhookPosted:) name:TuneConfigurationUpdated object:nil];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification];
    
    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNotNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNotNil([TuneManager currentManager].triggerManager);
    XCTAssertNotNil([TuneManager currentManager].campaignStateManager);
    
    XCTAssertEqual(1, [observer skyhookPostCount]);
#endif
}


- (void)testStartDisabled {
#if !TARGET_OS_TV
    [TuneState updateTMADisabledState:YES];
    
    [TuneManager instantiateModules];
    
    
    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNil([TuneManager currentManager].triggerManager);
    XCTAssertNil([TuneManager currentManager].campaignStateManager);
    
    [[TuneSkyhookCenter defaultCenter] addObserver:activatedObserver selector:@selector(skyhookPosted:) name:TuneStateTMAActivated object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:deactivatedObserver selector:@selector(skyhookPosted:) name:TuneStateTMADeactivated object:nil];
    
    /*
     DISABELD AT BOOT ==> DISABLED
     Nothing should happen.
     */
    
    // This forces a 'download' of the configuration
    [self prepareConfigWith:@{@"disabled": @"1"}];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification];
    
    XCTAssertEqual(0, [activatedObserver skyhookPostCount]);
    XCTAssertEqual(0, [deactivatedObserver skyhookPostCount]);
    XCTAssertTrue([[TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStateDisabled"] boolValue]);
    XCTAssertNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStatePermanentlyDisabled"]);
    
    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNil([TuneManager currentManager].triggerManager);
    XCTAssertNil([TuneManager currentManager].campaignStateManager);
    
    /*
     DISABELD AT BOOT ==> ENABLED
     TMA should come online.
     */
    
    [self prepareConfigWith:@{@"disabled": @"0"}];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification];
    
    XCTAssertEqual(1, [activatedObserver skyhookPostCount]);
    XCTAssertEqual(0, [deactivatedObserver skyhookPostCount]);
    XCTAssertFalse([[TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStateDisabled"] boolValue]);
    XCTAssertNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStatePermanentlyDisabled"]);

    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNotNil([TuneManager currentManager].triggerManager);
    XCTAssertNotNil([TuneManager currentManager].campaignStateManager);

    
    /*
     ENABLED ==> DISABLED
     TMA should go offline.
     */
    
    [self prepareConfigWith:@{@"disabled": @"1"}];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification];
    
    XCTAssertEqual(1, [activatedObserver skyhookPostCount]);
    XCTAssertEqual(1, [deactivatedObserver skyhookPostCount]);
    XCTAssertTrue([[TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStateDisabled"] boolValue]);
    XCTAssertNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStatePermanentlyDisabled"]);

    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNotNil([TuneManager currentManager].triggerManager);
    XCTAssertNotNil([TuneManager currentManager].campaignStateManager);

    /*
     DISABLED ==> ENABLED
     TMA should go online.
     NOTE: This is setup for the next block
     */
    
    [self prepareConfigWith:@{@"disabled": @"0"}];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification];
    
    XCTAssertEqual(2, [activatedObserver skyhookPostCount]);
    XCTAssertEqual(1, [deactivatedObserver skyhookPostCount]);
    XCTAssertFalse([[TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStateDisabled"] boolValue]);
    XCTAssertNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStatePermanentlyDisabled"]);

    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNotNil([TuneManager currentManager].triggerManager);
    XCTAssertNotNil([TuneManager currentManager].campaignStateManager);
    
    /*
     ENABLED ==> PERMANENTLY DISABLED
     TMA should go offline.
     */
    
    [self prepareConfigWith:@{@"permanently_disabled": @"1"}];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification];
    
    XCTAssertEqual(2, [activatedObserver skyhookPostCount]);
    XCTAssertEqual(2, [deactivatedObserver skyhookPostCount]);
    XCTAssertFalse([[TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStateDisabled"] boolValue]);
    XCTAssertTrue([[TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStatePermanentlyDisabled"] boolValue]);
    
    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNotNil([TuneManager currentManager].triggerManager);
    XCTAssertNotNil([TuneManager currentManager].campaignStateManager);
#endif
}

- (void)testStartPermanentlyDisabled {
    [TuneUserDefaultsUtils clearUserDefaultValue:@"TMAStateDisabled"];
    [TuneState updateTMAPermanentlyDisabledState:YES];
    
    [TuneManager instantiateModules];
    
    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNil([TuneManager currentManager].triggerManager);
    XCTAssertNil([TuneManager currentManager].campaignStateManager);
    
    [[TuneSkyhookCenter defaultCenter] addObserver:activatedObserver selector:@selector(skyhookPosted:) name:TuneStateTMAActivated object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:deactivatedObserver selector:@selector(skyhookPosted:) name:TuneStateTMADeactivated object:nil];

     /*
     PERMANENTLY DISABLED AT BOOT ==> DISABLED
     Nothing should happen
     */
    
    // This forces a 'download' of the configuration
    [self prepareConfigWith:@{@"disabled": @"1"}];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification];
    
    XCTAssertEqual(0, [activatedObserver skyhookPostCount]);
    XCTAssertEqual(0, [deactivatedObserver skyhookPostCount]);
    XCTAssertNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStateDisabled"]);
    XCTAssertTrue([[TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStatePermanentlyDisabled"] boolValue]);
    
    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNil([TuneManager currentManager].triggerManager);
    XCTAssertNil([TuneManager currentManager].campaignStateManager);
    
    /*
     PERMANENTLY DISABLED AT BOOT ==> ENABLED
     Nothing should happen
     */
    
    [self prepareConfigWith:@{@"disabled": @"0"}];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification];
    
    XCTAssertEqual(0, [activatedObserver skyhookPostCount]);
    XCTAssertEqual(0, [deactivatedObserver skyhookPostCount]);
    XCTAssertNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStateDisabled"]);
    XCTAssertTrue([[TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStatePermanentlyDisabled"] boolValue]);
    
    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNil([TuneManager currentManager].triggerManager);
    XCTAssertNil([TuneManager currentManager].campaignStateManager);
    
    /*
     PERMANENTLY DISABLED AT BOOT ==> PERMANENTLY DISABLED
     Nothing should happen
     */
    
    [self prepareConfigWith:@{@"permanently_disabled": @"1"}];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification];
    
    XCTAssertEqual(0, [activatedObserver skyhookPostCount]);
    XCTAssertEqual(0, [deactivatedObserver skyhookPostCount]);
    XCTAssertNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStateDisabled"]);
    XCTAssertTrue([[TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStatePermanentlyDisabled"] boolValue]);
    
    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNil([TuneManager currentManager].triggerManager);
    XCTAssertNil([TuneManager currentManager].campaignStateManager);
    
    /*
     PERMANENTLY DISABLED AT BOOT ==> NOT PERMANENTLY DISABLED
     Nothing should happen
     */
    
    [self prepareConfigWith:@{@"permanently_disabled": @"0"}];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification];
    
    XCTAssertEqual(0, [activatedObserver skyhookPostCount]);
    XCTAssertEqual(0, [deactivatedObserver skyhookPostCount]);
    XCTAssertNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStateDisabled"]);
    XCTAssertTrue([[TuneUserDefaultsUtils userDefaultValueforKey:@"TMAStatePermanentlyDisabled"] boolValue]);
    
    XCTAssertNotNil([TuneManager currentManager].userProfile);
    XCTAssertNotNil([TuneManager currentManager].configuration);
    XCTAssertNotNil([TuneManager currentManager].state);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    XCTAssertNil([TuneManager currentManager].triggerManager);
    XCTAssertNil([TuneManager currentManager].campaignStateManager);
}

/*
- (void)testEnabledToDisabledToEnabled {
    [defaults setObject:@(NO) forKey:@"TMAStateDisabled"];
    
    [TuneManager instantiateModules];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:activatedObserver selector:@selector(skyhookPosted:) name:TuneStateTMAActivated object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:deactivatedObserver selector:@selector(skyhookPosted:) name:TuneStateTMADeactivated object:nil];
    
    [self prepareConfigWith:@{@"disabled": @"1"}];
    
    
    ////////// Should immediately trigger a playlist download //////////
    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] init] statusCode:200 HTTPVersion:@"1.2" headerFields:@{}];
    newResponse = [[TuneHttpResponse alloc] initWithURLResponse:urlResponse andError:nil];
    [newResponse setResponseDictionary:playlistDictionary];
    
    id request = OCMClassMock([TuneHttpRequest class]);
    
    OCMStub([request performAsynchronousRequestWithCompletionBlock:OCMOCK_ANY]).andCall(self, @selector(performAsynchronousRequestWithCompletionBlock:));

    OCMStub([apiMock getPlaylistRequest]).andReturn(request);
    
    SimpleObserver *playlistObserver = [[SimpleObserver alloc] init];
    [[TuneSkyhookCenter defaultCenter] addObserver:playlistObserver selector:@selector(skyhookPosted:) name:TunePlaylistManagerFinishedPlaylistDownload object:nil];
    //////////////////////////////////////////////////////////////////
    
    // This forces a 'download' of the configuration
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification];
    
    XCTAssertEqual(0, [activatedObserver skyhookPostCount]);
    XCTAssertEqual(1, [deactivatedObserver skyhookPostCount]);
    
    XCTAssertNotNil([TuneManager currentManager].analyticsManager);
    XCTAssertNotNil([TuneManager currentManager].sessionManager);
    XCTAssertNotNil([TuneManager currentManager].powerHookManager);
    XCTAssertNotNil([TuneManager currentManager].playlistManager);
    
    XCTAssertEqual(0, [playlistObserver skyhookPostCount]);
}
*/

-(void)performAsynchronousRequestWithCompletionBlock:(void(^)(TuneHttpResponse* response))completionBlock {
    completionBlock(newResponse);
}

@end
