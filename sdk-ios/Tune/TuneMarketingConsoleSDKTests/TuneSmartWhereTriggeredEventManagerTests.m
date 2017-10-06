//
//  TuneSmartWhereTriggeredEventManagerTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Gordon Stewart on 7/6/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "TuneSmartWhereTriggeredEventManager.h"
#import "TuneManager.h"
#import "TuneSmartWhereHelper.h"
#import "TuneSkyhookCenter+Testing.h"

@interface TuneSmartWhereTriggeredEventManagerTests : XCTestCase

@end

@implementation TuneSmartWhereTriggeredEventManagerTests{
    TuneSmartWhereTriggeredEventManager *testObj;
    id mockTuneManager;
    id mockTuneSmartWhereHelper;
    id mockTuneSkyhookCenter;
    id mockPayload;
    SEL selHandleTriggeredEvent;
}

- (void)setUp {
    [super setUp];
    
    selHandleTriggeredEvent = NSSelectorFromString(@"handleTriggeredEvent:");
    
    mockTuneManager = OCMStrictClassMock([TuneManager class]);
    mockTuneSmartWhereHelper = OCMStrictClassMock([TuneSmartWhereHelper class]);
    [[[[mockTuneSmartWhereHelper stub] classMethod] andReturn:mockTuneSmartWhereHelper] getInstance];
    
    mockTuneSkyhookCenter = OCMStrictClassMock([TuneSkyhookCenter class]);
    [[[[mockTuneSkyhookCenter stub] classMethod] andReturn: mockTuneSkyhookCenter] defaultCenter];
    
    mockPayload = OCMStrictClassMock([TuneSkyhookPayload class]);
    
    testObj = [TuneSmartWhereTriggeredEventManager moduleWithTuneManager: mockTuneManager];
}

- (void)tearDown {
    [mockTuneSmartWhereHelper stopMocking];
    [mockTuneSkyhookCenter stopMocking];
    [super tearDown];
}

#pragma mark - Register Skyhooks Tests

- (void)testRegisterSkyhooksRegistersForTuneCustomEventOccurred{
    [[[[mockTuneSmartWhereHelper stub] classMethod] andReturnValue:OCMOCK_VALUE(YES)] isSmartWhereAvailable];
    
    [[mockTuneSkyhookCenter expect] removeObserver:testObj];
    [[mockTuneSkyhookCenter expect] addObserver:testObj selector:selHandleTriggeredEvent name:TuneCustomEventOccurred object:nil];
    
    [testObj registerSkyhooks];
    
    [mockTuneSkyhookCenter verify];
}

- (void)testRegisterSkyhooksDoesntRegisterWhenSmartWhereNotAvailable {
    [[[[mockTuneSmartWhereHelper stub] classMethod] andReturnValue:OCMOCK_VALUE(NO)] isSmartWhereAvailable];
    
    [[mockTuneSkyhookCenter reject] removeObserver:OCMOCK_ANY];
    [[mockTuneSkyhookCenter reject] addObserver:OCMOCK_ANY selector:selHandleTriggeredEvent name:OCMOCK_ANY object:OCMOCK_ANY];
    
    [testObj registerSkyhooks];
    
    [mockTuneSkyhookCenter verify];
}

#pragma mark - bring up and down tests

- (void)testBringUpRegistersSkyhooks {
    [[[[mockTuneSmartWhereHelper stub] classMethod] andReturnValue:OCMOCK_VALUE(YES)] isSmartWhereAvailable];
    
    [[mockTuneSkyhookCenter expect] removeObserver:testObj];
    [[mockTuneSkyhookCenter expect] addObserver:testObj selector:selHandleTriggeredEvent name:TuneCustomEventOccurred object:nil];
    
    [testObj bringUp];
    
    [mockTuneSkyhookCenter verify];
}

- (void)testBringDownUnRegistersSkyhooks {
    [[[[mockTuneSmartWhereHelper stub] classMethod] andReturnValue:OCMOCK_VALUE(YES)] isSmartWhereAvailable];
    
    [[mockTuneSkyhookCenter expect] removeObserver:testObj];
    
    [testObj bringDown];
    
    [mockTuneSkyhookCenter verify];
}

#pragma mark - handleTriggeredEvent tests

- (void)testhandleTriggeredEventCallsSetAttributeValuesFromPayloadAndProcessMappedEvent {
    [[[[mockTuneSmartWhereHelper stub] classMethod] andReturnValue:OCMOCK_VALUE(YES)] isSmartWhereAvailable];
    
    [[mockTuneSmartWhereHelper expect] setAttributeValuesFromPayload:mockPayload];
    [[mockTuneSmartWhereHelper expect] processMappedEvent:mockPayload];
    
    [testObj handleTriggeredEvent: mockPayload];
    
    [mockTuneSmartWhereHelper verify];
}

- (void)testhandleTriggeredEventDoesntCallProcessMappedEventWhenNotAvailable {
    [[[[mockTuneSmartWhereHelper stub] classMethod] andReturnValue:OCMOCK_VALUE(NO)] isSmartWhereAvailable];
    
    [[mockTuneSmartWhereHelper reject] setAttributeValuesFromPayload:mockPayload];
    [[mockTuneSmartWhereHelper reject] processMappedEvent:OCMOCK_ANY];
    
    [testObj handleTriggeredEvent: mockPayload];
    
    [mockTuneSmartWhereHelper verify];
}

@end
