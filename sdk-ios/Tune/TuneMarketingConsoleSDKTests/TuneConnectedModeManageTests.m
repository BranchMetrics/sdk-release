//
//  TuneConnectedModeManageTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 10/12/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "TuneSkyhookCenter.h"
#import "TuneHttpRequest.h"
#import "TuneApi.h"
#import "TuneState.h"
#import "TuneManager.h"
#import "TuneDeepActionManager.h"
#import "TunePowerHookManager.h"
#import "TuneDeviceDetails.h"

@interface TuneConnectedModeManageTests : XCTestCase {
    id request;
    id tuneState;
    BOOL requestSentOut;
    NSDictionary *toSyncDictionary;
}

@end

@implementation TuneConnectedModeManageTests

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
    
    requestSentOut = false;
    
    tuneState = OCMClassMock([TuneState class]);
    
    id api = OCMClassMock([TuneApi class]);
    OCMStub(ClassMethod([api getConnectDeviceRequest])).andCall(self, @selector(getRequest));
    OCMStub(ClassMethod([api getDisconnectDeviceRequest])).andCall(self, @selector(getRequest));
    OCMStub(ClassMethod([api getSyncSDKRequest:OCMOCK_ANY])).andCall(self, @selector(getSyncSDKRequestMock:));
}

- (void)tearDown {
    [request stopMocking];
    [tuneState stopMocking];
    
    request = nil;
    tuneState = nil;

    [super tearDown];
}

#pragma mark - Connect/Disconnect Tests

- (void)testConnectedModeOnSkyhookSendsOutConnectRequest {
    OCMStub([tuneState isInConnectedMode]).andReturn(true);
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneStateTMAConnectedModeTurnedOn];
    
    XCTAssertTrue(requestSentOut);
}

- (void)testSessionEndSkyhookSendsOutDisconnectRequest {
    OCMStub([tuneState isInConnectedMode]).andReturn(true);
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd];
    
    XCTAssertTrue(requestSentOut);
}

- (void)testSessionEndSkyhookWontSendOutDisconnectRequestWhenNotInConnectedMode {
    OCMStub([tuneState isInConnectedMode]).andReturn(false);
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd];
    
    XCTAssertFalse(requestSentOut);
}

#pragma mark - Sync Tests

- (void)testWhenConnectedModeIsTurnedOnWeSendTheSyncRequestWithNothingToSyncIfNothingIsRegistered {
    OCMStub([tuneState isInConnectedMode]).andReturn(true);
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneStateTMAConnectedModeTurnedOn];
    XCTAssertEqual(3, [toSyncDictionary.allValues count]);
    XCTAssertEqual(0, [toSyncDictionary[@"power_hooks"] count]);
    XCTAssertEqual(0, [toSyncDictionary[@"deep_actions"] count]);
}

- (void)testWhenConnectedModeIsTurnedOnWeSendTheSyncRequestWithRegisteredPowerHooks {
    OCMStub([tuneState isInConnectedMode]).andReturn(true);
    [[TuneManager currentManager].powerHookManager registerHookWithId:@"HOOK"
                                                         friendlyName:@"A HOOK"
                                                         defaultValue:@"value"
                                                          description:nil
                                                       approvedValues:nil];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneStateTMAConnectedModeTurnedOn];
    
    XCTAssertEqual(3, [toSyncDictionary.allValues count]);
    XCTAssertEqual(1, [toSyncDictionary[@"power_hooks"] count]);
    XCTAssertEqual(0, [toSyncDictionary[@"deep_actions"] count]);
    XCTAssertEqual(@"HOOK", toSyncDictionary[@"power_hooks"][0][@"name"]);
}

- (void)testWhenConnectedModeIsTurnedOnWeSendTheSyncRequestWithRegisteredDeepActions {
    OCMStub([tuneState isInConnectedMode]).andReturn(true);
    [[TuneManager currentManager].deepActionManager registerDeepActionWithId:@"DEEP_ACTION"
                                                                friendlyName:@"A deep action"
                                                                 description:nil
                                                                        data:@{}
                                                              approvedValues:nil
                                                                   andAction:^(NSDictionary *extra_data) {}];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneStateTMAConnectedModeTurnedOn];
    
    XCTAssertEqual(3, [toSyncDictionary.allValues count]);
    XCTAssertEqual(0, [toSyncDictionary[@"power_hooks"] count]);
    XCTAssertEqual(1, [toSyncDictionary[@"deep_actions"] count]);
    XCTAssertEqual(@"DEEP_ACTION", toSyncDictionary[@"deep_actions"][0][@"name"]);
}

- (void)testWhenConnectedModeIsTurnedOnWeSendTheSyncRequestWithDeviceInfo {
    OCMStub([tuneState isInConnectedMode]).andReturn(true);
    
    id deviceDetailsMock = OCMClassMock([TuneDeviceDetails class]);
    OCMStub([deviceDetailsMock getSupportedDeviceOrientationsString]).andReturn(@"expected1");
    OCMStub([deviceDetailsMock getSupportedDeviceTypesString]).andReturn(@"expected2");
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneStateTMAConnectedModeTurnedOn];
    
    XCTAssertNotNil(toSyncDictionary[@"device_info"]);
    XCTAssertEqualObjects(@"expected1", toSyncDictionary[@"device_info"][@"supported_orientations"]);
    XCTAssertEqualObjects(@"expected2", toSyncDictionary[@"device_info"][@"supported_devices"]);
}

#pragma mark - Helpers

- (TuneHttpRequest *)getRequest {
    request = OCMPartialMock([[TuneHttpRequest alloc] init]);
    OCMStub([request performAsynchronousRequestWithCompletionBlock:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        requestSentOut = true;
    });
    return request;
}

- (TuneHttpRequest *)getSyncSDKRequestMock:(NSDictionary *)toSync {
    toSyncDictionary = toSync.copy;
    
    request = OCMPartialMock([[TuneHttpRequest alloc] init]);
    OCMStub([request performAsynchronousRequestWithCompletionBlock:OCMOCK_ANY]).andDo(nil);
    return request;
}


@end
