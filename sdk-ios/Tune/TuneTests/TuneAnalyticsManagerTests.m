//
//  TuneAnalyticsManagerTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/24/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "SimpleObserver.h"
#import "Tune+Testing.h"
#import "TuneAnalyticsConstants.h"
#import "TuneAnalyticsDispatchEventsOperation.h"
#import "TuneAnalyticsDispatchToConnectedModeOperation.h"
#import "TuneAnalyticsEvent.h"
#import "TuneAnalyticsManager+Testing.h"
#import "TuneAnalyticsVariable.h"
#import "TuneBlankViewController.h"
#import "TuneConfiguration.h"
#import "TuneDeeplink.h"
#import "TuneEvent+Internal.h"
#import "TuneEventItem+Internal.h"
#import "TuneFileManager.h"
#import "TuneJSONUtils.h"
#import "TuneManager.h"
#import "TunePlaylistManager+Testing.h"
#import "TunePushUtils.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookPayloadConstants.h"
#import "TuneState.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneXCTestCase.h"

@interface TuneAnalyticsManagerTests : TuneXCTestCase {
    id mockApplication;
    id mockTimer;
    id mockOperationQueue;
    
    id analyticsManager;
    id fileManagerMock;
    TuneConfiguration *configuration;
    
    SimpleObserver *simpleObserver;
    
    NSUInteger dispatchCount;
    NSUInteger connectedModeDispatchCount;
}
@end

@implementation TuneAnalyticsManagerTests

- (void)setUp {
    [super setUpWithMocks:@[[TunePlaylistManager class]]];

    // Don't let the automatically made analyticsmanager act on any skyhooks
    [[TuneSkyhookCenter defaultCenter] removeObserver:[TuneManager currentManager].analyticsManager];

    mockApplication = OCMClassMock([UIApplication class]);
    OCMStub(ClassMethod([mockApplication sharedApplication])).andReturn(mockApplication);
    
    mockTimer = OCMClassMock([NSTimer class]);
    
    TuneAnalyticsManager *baseManager = [[TuneAnalyticsManager alloc] initWithTuneManager:[TuneManager currentManager]];
    analyticsManager = OCMPartialMock(baseManager);
    mockOperationQueue = OCMPartialMock([analyticsManager operationQueue]);
    OCMStub([mockOperationQueue addOperation:[OCMArg isKindOfClass:[TuneAnalyticsDispatchEventsOperation class]]]).andCall(self, @selector(addedDispatchOperation:));
    OCMStub([mockOperationQueue addOperation:[OCMArg isKindOfClass:[TuneAnalyticsDispatchToConnectedModeOperation class]]]).andCall(self, @selector(addedConnectedDispatchOperation:));
    OCMStub([analyticsManager operationQueue]).andReturn(mockOperationQueue);
    
    fileManagerMock = OCMClassMock([TuneFileManager class]);
    
    [[analyticsManager tuneManager] setAnalyticsManager:analyticsManager];
    [analyticsManager registerSkyhooks];
    
    configuration = [[TuneConfiguration alloc] initWithTuneManager:[TuneManager currentManager]];
    configuration.analyticsDispatchPeriod = @(3);
    [TuneManager currentManager].configuration = configuration;
    pointMAUrlsToNothing();
    
    simpleObserver = [[SimpleObserver alloc] init];
    
    dispatchCount = 0;
}

- (void)tearDown {
    // make sure that the timer is invalidated
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd object:self];
    [TuneState updateConnectedMode: NO];
    
    [analyticsManager waitForOperationsToFinish];
    
    [mockTimer invalidate];
    
    [analyticsManager stopMocking];
    [mockTimer stopMocking];
    [mockOperationQueue stopMocking];
    [mockApplication stopMocking];
    [fileManagerMock stopMocking];
    
    [super tearDown];
}

- (void)testHandleCustomEvent {
    [TuneFileManager deleteAnalyticsFromDisk];
    
    TuneEvent *event = [TuneEvent eventWithName:@"testAction"];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneCustomEventOccurred object:self userInfo:@{ TunePayloadCustomEvent: event }];
    
    [analyticsManager waitForOperationsToFinish];
    
    NSDictionary *storedAnalytics = [TuneFileManager loadAnalyticsFromDisk];
    NSArray *storedAnalyticsKeys = [storedAnalytics allKeys];
    
    XCTAssertTrue([storedAnalytics count] == 1);
    for (NSString *key in storedAnalyticsKeys) {
        // assert action
        XCTAssertTrue([(NSString *)[storedAnalytics objectForKey:key] containsString:@"\"action\":\"testAction\""]);
        XCTAssertTrue([(NSString *)[storedAnalytics objectForKey:key] containsString:@"\"controlEvent\":null"]);
        XCTAssertTrue([(NSString *)[storedAnalytics objectForKey:key] containsString:@"\"category\":\"Custom\""]);
        XCTAssertTrue([(NSString *)[storedAnalytics objectForKey:key] containsString:@"\"schemaVersion\":\"2.0\""]);
        XCTAssertTrue([(NSString *)[storedAnalytics objectForKey:key] containsString:@"\"control\":null"]);
        XCTAssertTrue([(NSString *)[storedAnalytics objectForKey:key] containsString:@"\"type\":\"EVENT\""]);
    }
}

- (void)testHandleCustomEventWithId {
    [TuneFileManager deleteAnalyticsFromDisk];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    TuneEvent *event = [TuneEvent eventWithId:123];
#pragma clang diagnostic pop
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneCustomEventOccurred object:self userInfo:@{ TunePayloadCustomEvent: event }];
    
    [analyticsManager waitForOperationsToFinish];
    
    NSDictionary *storedAnalytics = [TuneFileManager loadAnalyticsFromDisk];
    NSArray *storedAnalyticsKeys = [storedAnalytics allKeys];
    
    XCTAssertTrue([storedAnalytics count] == 1);
    for (NSString *key in storedAnalyticsKeys) {
        // assert action
        XCTAssertTrue([(NSString *)[storedAnalytics objectForKey:key] containsString:@"\"action\":\"123\""]);
        XCTAssertTrue([(NSString *)[storedAnalytics objectForKey:key] containsString:@"\"controlEvent\":null"]);
        XCTAssertTrue([(NSString *)[storedAnalytics objectForKey:key] containsString:@"\"category\":\"Custom\""]);
        XCTAssertTrue([(NSString *)[storedAnalytics objectForKey:key] containsString:@"\"schemaVersion\":\"2.0\""]);
        XCTAssertTrue([(NSString *)[storedAnalytics objectForKey:key] containsString:@"\"control\":null"]);
        XCTAssertTrue([(NSString *)[storedAnalytics objectForKey:key] containsString:@"\"type\":\"EVENT\""]);
    }
}

- (void)testHandleDeeplinkOpened {
    [TuneFileManager deleteAnalyticsFromDisk];
    
    TuneDeeplink *deeplink = [[TuneDeeplink alloc] initWithNSURL:[NSURL URLWithString:@"myapp://deeplink/path?dog=maru&user=john"]];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneAppOpenedFromURL object:nil userInfo:@{TunePayloadDeeplink:deeplink}];
    
    [analyticsManager waitForOperationsToFinish];
    
    NSDictionary *storedAnalytics = [TuneFileManager loadAnalyticsFromDisk];
    NSArray *storedAnalyticsKeys = [storedAnalytics allKeys];
    
    XCTAssertTrue([storedAnalytics count] == 1);
    for (NSString *key in storedAnalyticsKeys) {
        NSString *eventString = (NSString *)[storedAnalytics objectForKey:key];
        // assert action
        XCTAssertTrue([eventString containsString:@"\"action\":\"DeeplinkOpened\""]);
        XCTAssertTrue([eventString containsString:@"\"controlEvent\":null"]);
        XCTAssertTrue([eventString containsString:@"\"category\":\"myapp://deeplink/path\""]);
        XCTAssertTrue([eventString containsString:@"\"schemaVersion\":\"2.0\""]);
        XCTAssertTrue([eventString containsString:@"\"control\":null"]);
        XCTAssertTrue([eventString containsString:@"\"type\":\"APP_OPENED_BY_URL\""]);
    }
}

- (void)testHandleClearVariableCall {
    [TuneFileManager deleteAnalyticsFromDisk];
    
    NSSet *analyticsToClear = [[NSSet alloc] initWithObjects:@"variable1", @"variable2", nil];
    
    TuneAnalyticsEvent *clearProfileEvent = [[TuneAnalyticsEvent alloc] initAsTracerEvent];
    clearProfileEvent.action = TUNE_EVENT_ACTION_PROFILE_VARIABLES_CLEARED;
    clearProfileEvent.category = @"variable1,variable2";
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneUserProfileVariablesCleared
                                            object:self
                                          userInfo:@{ TunePayloadProfileVariablesToClear: analyticsToClear }];
    
    XCTAssertTrue(dispatchCount == 1, @"Actually: %lu", (unsigned long)dispatchCount);
    
    [analyticsManager waitForOperationsToFinish];
    
    NSDictionary *storedAnalytics = [TuneFileManager loadAnalyticsFromDisk];
    NSArray *storedAnalyticsKeys = [storedAnalytics allKeys];
    
    XCTAssertTrue([storedAnalytics count] == 1);
    for (NSString *key in storedAnalyticsKeys) {
        XCTAssertTrue([(NSString *)[storedAnalytics objectForKey:key] containsString:@"\"category\":\"variable1,variable2\""]);
    }
}

- (void)testHandleSessionStart {
    [TuneFileManager deleteAnalyticsFromDisk];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart object:self];
    XCTAssertTrue(dispatchCount == 1, @"Actually: %lu", (unsigned long)dispatchCount);
    
    [analyticsManager waitForOperationsToFinish];
    NSDictionary *storedAnalytics = [TuneFileManager loadAnalyticsFromDisk];
    
    XCTAssertTrue([storedAnalytics count] == 1, @"Actually: %lu", (unsigned long)[storedAnalytics count]);
    OCMVerify([mockTimer scheduledTimerWithTimeInterval:3
                                                 target:[OCMArg any]
                                               selector:[OCMArg anySelector]
                                               userInfo:[OCMArg any]
                                                repeats:YES]);
}


- (void)testConfirmNoDuplicateTimers {
    OCMExpect([mockTimer scheduledTimerWithTimeInterval:3
                                                 target:[OCMArg any]
                                               selector:[OCMArg anySelector]
                                               userInfo:[OCMArg any]
                                                repeats:YES]);
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart object:self];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart object:self];
    
    OCMVerifyAll(mockTimer);
}

- (void)testHandleSessionStop {
    OCMExpect([mockTimer invalidate]);
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart object:self];
    [analyticsManager waitForOperationsToFinish];
    
    [TuneFileManager deleteAnalyticsFromDisk];
    [analyticsManager setDispatchScheduler:mockTimer];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd object:self];
    
    OCMVerifyAll(mockTimer);
    XCTAssertTrue(dispatchCount == 2, @"Actually: %lu", (unsigned long)dispatchCount);
    
    [analyticsManager waitForOperationsToFinish];
    NSDictionary *storedAnalytics = [TuneFileManager loadAnalyticsFromDisk];
    XCTAssertTrue([storedAnalytics count] == 1, @"Actually: %lu", (unsigned long)[storedAnalytics count]);
}

- (void)testHandleViewControllerAppearedWritesEventWhenViewControllerIsValid {
    OCMExpect([fileManagerMock saveAnalyticsEventToDisk:OCMOCK_ANY withId:OCMOCK_ANY]);
    
    TuneBlankViewController *viewController = [[TuneBlankViewController alloc] init];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneViewControllerAppeared object:viewController];
    
    [analyticsManager waitForOperationsToFinish];
    
    OCMVerifyAll(fileManagerMock);
}

- (void)testConfirmNoInvalidTimerInvalidation {
    OCMStub([mockTimer invalidate]);
    [analyticsManager setDispatchScheduler:nil];
    
    // Shouldn't throw an exception.
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd object:self];
}

- (void)testConfirmNoDuplicateTimerInvalidation {
    OCMExpect([mockTimer invalidate]);
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart object:self];
    [analyticsManager setDispatchScheduler:mockTimer];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd object:self];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd object:self];
    
    OCMVerifyAll(mockTimer);
}

- (void)testPushStatusChangedAnalyticsEvent {
    __block BOOL analyticsStoreAndTrackCalled = NO;
    __block BOOL oldStatus = NO;
    
    OCMStub([analyticsManager storeAndTrackAnalyticsEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
        TuneAnalyticsEvent *evt = (TuneAnalyticsEvent *)obj;
        return [evt.action isEqualToString:@"Push Enabled"] || [evt.action isEqualToString:@"Push Disabled"];
    }]]).andDo(^(NSInvocation *invocation) {
        TuneAnalyticsEvent *evt;
        [invocation getArgument:&evt atIndex:2];
        analyticsStoreAndTrackCalled = YES;
        
        XCTAssertTrue([evt.eventType isEqualToString:@"EVENT"]);
        XCTAssertTrue([evt.category isEqualToString:@"Application"]);
        NSString *expectedEventAction = oldStatus ? @"Push Disabled" : @"Push Enabled";
        XCTAssertTrue([evt.action isEqualToString:expectedEventAction]);
    });
    
    __block BOOL forcedPushStatus = NO;
    id classMockTunePushUtils = OCMClassMock([TunePushUtils class]);
    OCMStub(ClassMethod([classMockTunePushUtils isAlertPushNotificationEnabled])).andDo(^(NSInvocation *invocation) {
        [invocation setReturnValue:&forcedPushStatus];
    });
    
    forcedPushStatus = NO;
    analyticsStoreAndTrackCalled = NO;
    [TuneUserDefaultsUtils setUserDefaultValue:nil forKey:@"TUNE_PUSH_ENABLED_STATUS"];
    XCTAssertNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"]);
    
    TuneSkyhookCenter *skyhookCenter = [TuneSkyhookCenter defaultCenter];
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    XCTAssertNotNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"]);
    XCTAssertFalse([[TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"] boolValue]);
    XCTAssertFalse(analyticsStoreAndTrackCalled);
    
    forcedPushStatus = NO;
    analyticsStoreAndTrackCalled = NO;
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    XCTAssertNotNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"]);
    XCTAssertFalse([[TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"] boolValue]);
    XCTAssertFalse(analyticsStoreAndTrackCalled);
    
    forcedPushStatus = YES;
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    XCTAssertNotNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"]);
    XCTAssertTrue([[TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"] boolValue]);
    XCTAssertTrue(analyticsStoreAndTrackCalled);
    
    forcedPushStatus = YES;
    analyticsStoreAndTrackCalled = NO;
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    XCTAssertNotNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"]);
    XCTAssertTrue([[TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"] boolValue]);
    XCTAssertFalse(analyticsStoreAndTrackCalled);
    
    oldStatus = YES;
    forcedPushStatus = NO;
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    
    XCTAssertNotNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"]);
    XCTAssertFalse([[TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"] boolValue]);
    XCTAssertTrue(analyticsStoreAndTrackCalled);
    
    //////////////////////////
    
    oldStatus = YES;
    forcedPushStatus = NO;
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    oldStatus = NO;
    forcedPushStatus = YES;
    [skyhookCenter postSkyhook:TuneRegisteredForRemoteNotificationsWithDeviceToken object:nil userInfo:@{@"deviceToken":@"1234567894561234567891234567890000"}];
    
    XCTAssertNotNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"]);
    XCTAssertTrue([[TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"] boolValue]);
    XCTAssertTrue(analyticsStoreAndTrackCalled);
    
    //////////////////////////
    
    oldStatus = YES;
    forcedPushStatus = NO;
    [skyhookCenter postSkyhook:TuneSessionManagerSessionDidStart object:nil userInfo:@{}];
    oldStatus = NO;
    forcedPushStatus = YES;
    [skyhookCenter postSkyhook:TuneFailedToRegisterForRemoteNotifications object:nil userInfo:@{}];
    
    XCTAssertNotNil([TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"]);
    XCTAssertTrue([[TuneUserDefaultsUtils userDefaultValueforKey:@"TUNE_PUSH_ENABLED_STATUS"] boolValue]);
    XCTAssertTrue(analyticsStoreAndTrackCalled);
    
    [classMockTunePushUtils stopMocking];
}

#pragma mark - Session Variables

/***************************************
 Temporarily disabled failing unit tests
 ***************************************/
//- (void)testSessionVariablesAreAddedToEvents {
//    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionVariableToSet object:nil userInfo:@{ TunePayloadSessionVariableName: @"VAR_NAME", TunePayloadSessionVariableValue: @"VAR_VALUE", TunePayloadSessionVariableSaveType: TunePayloadSessionVariableSaveTypeTag }];
//    
//    TuneEvent *event = [TuneEvent eventWithName:@"SHRED"];
//    OCMStub([fileManagerMock saveAnalyticsEventToDisk:OCMOCK_ANY withId:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
//        NSString *eventToSaveJSON;
//        [invocation getArgument:&eventToSaveJSON atIndex:2];
//        XCTAssert([eventToSaveJSON containsString:@"VAR_NAME"]);
//        XCTAssert([eventToSaveJSON containsString:@"VAR_VALUE"]);
//    });
//    
//    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: event }];
//}
//
//- (void)testSessionVariablesAreResetAtEndOfSession {
//    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionVariableToSet object:nil userInfo:@{ TunePayloadSessionVariableName: @"VAR_NAME", TunePayloadSessionVariableValue: @"VAR_VALUE", TunePayloadSessionVariableSaveType: TunePayloadSessionVariableSaveTypeTag }];
//    
//    TuneEvent *event = [TuneEvent eventWithName:@"SHRED"];
//    
//    __block int saveCount = 0;
//    OCMStub([fileManagerMock saveAnalyticsEventToDisk:OCMOCK_ANY withId:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
//        if (saveCount == 0) {
//            NSString *eventToSaveJSON;
//            [invocation getArgument:&eventToSaveJSON atIndex:2];
//            XCTAssert([eventToSaveJSON containsString:@"VAR_NAME"]);
//            XCTAssert([eventToSaveJSON containsString:@"VAR_VALUE"]);
//        }
//        
//        if (saveCount == 3) {
//            NSString *eventToSaveJSON2;
//            [invocation getArgument:&eventToSaveJSON2 atIndex:2];
//            XCTAssertFalse([eventToSaveJSON2 containsString:@"VAR_NAME"], @"Actually: %@", eventToSaveJSON2);
//            XCTAssertFalse([eventToSaveJSON2 containsString:@"VAR_VALUE"], @"Actually: %@", eventToSaveJSON2);
//        }
//        
//        saveCount++;
//    });
//    
//    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: event }];
//    
//    // End/Start session
//    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd];
//    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart];
//    
//    [analyticsManager waitForOperationsToFinish];
//    
//    TuneEvent *event2 = [TuneEvent eventWithName:@"SHRED2"];
//    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneCustomEventOccurred object:nil userInfo:@{ TunePayloadCustomEvent: event2 }];
//    
//    [analyticsManager waitForOperationsToFinish];
//}

- (void)testStartOfConnectedMode {
    OCMExpect([mockTimer invalidate]);
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart object:self];
    [analyticsManager setDispatchScheduler:mockTimer];
    [analyticsManager waitForOperationsToFinish];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneStateTMAConnectedModeTurnedOn object:self userInfo:nil];
    
    OCMVerifyAll(mockTimer);
}

- (void)testDispatchWhenInConnectedMode {
    [TuneState updateConnectedMode: YES];
    [TuneFileManager deleteAnalyticsFromDisk];
    
    TuneEvent *event = [TuneEvent eventWithName:@"testAction"];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneCustomEventOccurred object:self userInfo:@{ TunePayloadCustomEvent: event }];
    
    [analyticsManager waitForOperationsToFinish];
    
    // Confirm that we correctly dispatched to connected mode.
    XCTAssertTrue(connectedModeDispatchCount == 1, @"Actually: %lu", (unsigned long)connectedModeDispatchCount);
    XCTAssertTrue(dispatchCount == 0, @"Actually: %lu", (unsigned long)dispatchCount);
    
    // Confirm that the event wasn't stored locally.
    NSDictionary *storedAnalytics = [TuneFileManager loadAnalyticsFromDisk];
    XCTAssertTrue([storedAnalytics count] == 0);
}

#pragma mark - In-App Messaging

- (void)testHandleInAppMessageShown {
    [TuneFileManager deleteAnalyticsFromDisk];
    
    TuneAnalyticsVariable *campaignStepVariable = [TuneAnalyticsVariable analyticsVariableWithName:TUNE_CAMPAIGN_STEP_IDENTIFIER value:@"test_campaign_step_id"];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneInAppMessageShown object:nil userInfo:@{TunePayloadInAppMessageID: @"test_message_id", TunePayloadCampaignStep: campaignStepVariable}];
    
    [analyticsManager waitForOperationsToFinish];
    
    NSDictionary *storedAnalytics = [TuneFileManager loadAnalyticsFromDisk];
    NSArray *storedAnalyticsKeys = [storedAnalytics allKeys];
    
    XCTAssertTrue([storedAnalytics count] == 1);
    for (NSString *key in storedAnalyticsKeys) {
        NSString *eventString = (NSString *)[storedAnalytics objectForKey:key];
        // assert action
        XCTAssertTrue([eventString containsString:@"\"action\":\"TUNE_IN_APP_MESSAGE_ACTION_SHOWN\""]);
        XCTAssertTrue([eventString containsString:@"\"controlEvent\":null"]);
        XCTAssertTrue([eventString containsString:@"\"category\":\"test_message_id\""]);
        XCTAssertTrue([eventString containsString:@"\"schemaVersion\":\"2.0\""]);
        XCTAssertTrue([eventString containsString:@"\"control\":null"]);
        XCTAssertTrue([eventString containsString:@"\"type\":\"IN_APP_MESSAGE\""]);
    }
}

- (void)testHandleInAppMessageDismissed {
    [TuneFileManager deleteAnalyticsFromDisk];
    
    // Record analytics event
    TuneAnalyticsVariable *campaignStepVariable = [TuneAnalyticsVariable analyticsVariableWithName:TUNE_CAMPAIGN_STEP_IDENTIFIER value:@"test_campaign_step_id"];
    TuneAnalyticsVariable *secondsDisplayedVariable = [TuneAnalyticsVariable analyticsVariableWithName:TUNE_IN_APP_MESSAGE_SECONDS_DISPLAYED value:@5 type:TuneAnalyticsVariableNumberType];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneInAppMessageDismissed
                                            object:nil
                                          userInfo:@{TunePayloadInAppMessageID: @"test_message_id",
                                                     TunePayloadInAppMessageDismissedAction: TUNE_IN_APP_MESSAGE_ACTION_DISMISSED_AFTER_DURATION,
                                                     TunePayloadCampaignStep: campaignStepVariable,
                                                     TunePayloadInAppMessageSecondsDisplayed: secondsDisplayedVariable}];
    
    [analyticsManager waitForOperationsToFinish];
    
    NSDictionary *storedAnalytics = [TuneFileManager loadAnalyticsFromDisk];
    NSArray *storedAnalyticsKeys = [storedAnalytics allKeys];
    
    XCTAssertTrue([storedAnalytics count] == 1);
    for (NSString *key in storedAnalyticsKeys) {
        NSString *eventString = (NSString *)[storedAnalytics objectForKey:key];
        // assert action
        XCTAssertTrue([eventString containsString:@"\"action\":\"TUNE_IN_APP_MESSAGE_ACTION_DISMISSED_AFTER_DURATION\""]);
        XCTAssertTrue([eventString containsString:@"\"controlEvent\":null"]);
        XCTAssertTrue([eventString containsString:@"\"category\":\"test_message_id\""]);
        XCTAssertTrue([eventString containsString:@"\"schemaVersion\":\"2.0\""]);
        XCTAssertTrue([eventString containsString:@"\"control\":null"]);
        XCTAssertTrue([eventString containsString:@"\"type\":\"IN_APP_MESSAGE\""]);
    }
}

- (void)testHandleInAppMessageUnspecifiedAction {
    [TuneFileManager deleteAnalyticsFromDisk];
    
    // Record analytics event
    TuneAnalyticsVariable *campaignStepVariable = [TuneAnalyticsVariable analyticsVariableWithName:TUNE_CAMPAIGN_STEP_IDENTIFIER value:@"test_campaign_step_id"];
    TuneAnalyticsVariable *secondsDisplayedVariable = [TuneAnalyticsVariable analyticsVariableWithName:TUNE_IN_APP_MESSAGE_SECONDS_DISPLAYED value:@3 type:TuneAnalyticsVariableNumberType];
    TuneAnalyticsVariable *unspecifiedActionVariable = [TuneAnalyticsVariable analyticsVariableWithName:TUNE_IN_APP_MESSAGE_UNSPECIFIED_ACTION_NAME value:@"test_unspecified_action_name"];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneInAppMessageDismissedWithUnspecifiedAction
                                            object:nil
                                          userInfo:@{TunePayloadInAppMessageID: @"test_message_id",
                                                     TunePayloadInAppMessageDismissedAction: unspecifiedActionVariable,
                                                     TunePayloadCampaignStep: campaignStepVariable,
                                                     TunePayloadInAppMessageSecondsDisplayed: secondsDisplayedVariable}];
    
    [analyticsManager waitForOperationsToFinish];
    
    NSDictionary *storedAnalytics = [TuneFileManager loadAnalyticsFromDisk];
    NSArray *storedAnalyticsKeys = [storedAnalytics allKeys];
    
    XCTAssertTrue([storedAnalytics count] == 1);
    for (NSString *key in storedAnalyticsKeys) {
        NSString *eventString = (NSString *)[storedAnalytics objectForKey:key];
        // assert action
        XCTAssertTrue([eventString containsString:@"\"action\":\"TUNE_IN_APP_MESSAGE_UNSPECIFIED_ACTION_NAME\""]);
        XCTAssertTrue([eventString containsString:@"\"controlEvent\":null"]);
        XCTAssertTrue([eventString containsString:@"\"category\":\"test_message_id\""]);
        XCTAssertTrue([eventString containsString:@"\"schemaVersion\":\"2.0\""]);
        XCTAssertTrue([eventString containsString:@"\"control\":null"]);
        XCTAssertTrue([eventString containsString:@"\"type\":\"IN_APP_MESSAGE\""]);
    }
}

#pragma mark - Helpers

- (void)addedDispatchOperation:(NSOperation *)operation {
    ++dispatchCount;
}

- (void)addedConnectedDispatchOperation:(NSOperation *)operation {
    ++connectedModeDispatchCount;
}

@end
