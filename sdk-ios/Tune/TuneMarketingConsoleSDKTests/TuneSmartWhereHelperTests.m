//
//  TuneSmartWhereHelperTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Gordon Stewart on 8/4/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "TuneConfiguration.h"
#import "TuneManager.h"
#import "TuneSmartWhereHelper.h"
#import "TuneUtils.h"
#import "TuneEvent.h"
#import "TuneSkyhookPayloadConstants.h"
#import "Tune.h"

@interface SmartWhereForTest : NSObject
- (void)invalidate;
- (void)processMappedEvent:(TuneSkyhookPayload*) payload;
+ (void)setUserString:(NSString*)value forKey:(NSString*)key;
+ (void)removeUserValueForKey:(NSString*)key;
+ (NSDictionary*) getUserAttributes;
+ (void)setUserTrackingString:(NSString *)value forKey:(NSString *)key;
+ (void)removeUserTrackingValueForKey:(NSString*)key;
@end

@implementation SmartWhereForTest
- (void)invalidate {}
- (void)processMappedEvent:(TuneSkyhookPayload*) payload{}
+ (void)setUserString:(NSString*)value forKey:(NSString*)key{}
+ (void)removeUserValueForKey:(NSString*)key{}
+ (NSDictionary*) getUserAttributes{return nil;}
+ (void)setUserTrackingString:(NSString *)value forKey:(NSString *)key{}
+ (void)removeUserTrackingValueForKey:(NSString*)key{}

@end

@interface TuneSmartWhereHelper (Testing)
- (void)startProximityMonitoringWithAppId:(NSString *)appId
                               withApiKey:(NSString *)apiKey
                            withApiSecret:(NSString *)apiSecret
                               withConfig:(NSDictionary *)config;

- (void)setSmartWhere:(id)smartWhere;
- (id)getSmartWhere;
- (void)setConfig:(NSDictionary *)config;
+ (void)invalidateForTesting;

@end

@interface TuneSmartWhereHelperTests : XCTestCase {
    TuneSmartWhereHelper *testObj;
    id mockTuneManager;
    id mockTuneUtils;
    id mockSmartWhere;
}

@end

@implementation TuneSmartWhereHelperTests

- (void)setUp {
    [super setUp];
    
    mockTuneUtils = OCMStrictClassMock([TuneUtils class]);
    mockTuneManager = OCMStrictClassMock([TuneManager class]);
    mockSmartWhere = OCMStrictClassMock([SmartWhereForTest class]);
    
    [TuneSmartWhereHelper invalidateForTesting];
    testObj = [TuneSmartWhereHelper getInstance];
}

- (void)tearDown {
    [mockTuneManager stopMocking];
    [mockTuneUtils stopMocking];
    [mockSmartWhere stopMocking];
    
    [TuneSmartWhereHelper invalidateForTesting];
    
    [super tearDown];
}


#pragma mark - init tests

- (void)testSecondInitReturnsSameObject {
    TuneSmartWhereHelper *newObj = [TuneSmartWhereHelper getInstance];
    XCTAssertEqual(testObj, newObj);
}


#pragma mark - isSmartWhereAvailable tests

- (void)testIsSmartWhereAvailableReturnsFalseWhenSmartWhereClassNotFound {
    [self setTuneConfigurationMockWithDebug:NO];
    
    [[[[mockTuneUtils expect] classMethod] andReturn:nil] getClassFromString:@"SmartWhere"];
    XCTAssertFalse([TuneSmartWhereHelper isSmartWhereAvailable]);
    
    [mockTuneManager verify];
    [mockTuneUtils verify];
}

- (void)testIsSmartWhereAvailableReturnsTrueWhenSmartWhereClassIsFound {
    [self setTuneConfigurationMockWithDebug:NO];
    [self setTuneUtilsGetClassFromStringToAnObject];
    
    XCTAssertTrue([TuneSmartWhereHelper isSmartWhereAvailable]);
    
    [mockTuneManager verify];
    [mockTuneUtils verify];
}

#pragma mark - startMonitoringWithTuneAdvertiserId:tuneConversionKey: tests

- (void)testStartMonitoringStartsProximityMonitoringWithAdIdAndConversionKey {
    
    [self setTuneConfigurationMockWithDebug:NO];
    [self setTuneUtilsGetClassFromStringToAnObject];
    
    NSString *aid = @"aid";
    NSString *conversionKey = @"key";
    
    id mockTestObj = OCMPartialMock(testObj);

    [[mockTestObj expect] startProximityMonitoringWithAppId:aid
                                                 withApiKey:aid
                                              withApiSecret:conversionKey
                                                 withConfig:[OCMArg checkWithBlock:^BOOL(id value) {
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary *actualConfig = value;
            return (actualConfig[@"ENABLE_NOTIFICATION_PERMISSION_PROMPTING"] && [actualConfig[@"ENABLE_NOTIFICATION_PERMISSION_PROMPTING"] isEqual:@"false"]) &&
                (actualConfig[@"ENABLE_LOCATION_PERMISSION_PROMPTING"] && [actualConfig[@"ENABLE_LOCATION_PERMISSION_PROMPTING"] isEqual:@"false"]) &&
                (actualConfig[@"ENABLE_GEOFENCE_RANGING"] && [actualConfig[@"ENABLE_GEOFENCE_RANGING"] isEqual:@"true"]) &&
            (actualConfig[@"DELEGATE_NOTIFICATIONS"] && [actualConfig[@"DELEGATE_NOTIFICATIONS"] isEqual:@"false"]);
        }
        return NO;
    }]];
    [[mockTestObj expect] setTrackingAttributeValue:TUNEVERSION forKey:@"TUNE_SDK_VERSION"];
    
    [mockTestObj startMonitoringWithTuneAdvertiserId:@"aid" tuneConversionKey:@"key" packageName:@"packageName"];
    
    [mockTestObj verify];
}

- (void)testStartMonitoringDoesntStartWhenAlreadyStarted {
    [testObj setSmartWhere:mockSmartWhere];
    [self setTuneUtilsGetClassFromStringToAnObject];
    
    [self setTuneConfigurationMockWithDebug:NO];
    
    id mockTestObj = OCMPartialMock(testObj);
    [[mockTestObj reject] startProximityMonitoringWithAppId:OCMOCK_ANY
                                                 withApiKey:OCMOCK_ANY
                                              withApiSecret:OCMOCK_ANY
                                                 withConfig:OCMOCK_ANY];
    
    [mockTestObj startMonitoringWithTuneAdvertiserId:@"aid" tuneConversionKey:@"key" packageName:@"packageName"];
    
    [mockTestObj verify];
    [mockTuneManager verify];
}

- (void)testStartMonitoringDoesntStartWhenAidIsNil {
    [self setTuneUtilsGetClassFromStringToAnObject];
    
    [self setTuneConfigurationMockWithDebug:NO];
    
    id mockTestObj = OCMPartialMock(testObj);
    [[mockTestObj reject] startProximityMonitoringWithAppId:OCMOCK_ANY
                                                 withApiKey:OCMOCK_ANY
                                              withApiSecret:OCMOCK_ANY
                                                 withConfig:OCMOCK_ANY];
    
    [mockTestObj startMonitoringWithTuneAdvertiserId:nil tuneConversionKey:@"key" packageName:@"packageName"];
    
    [mockTestObj verify];
    [mockTuneManager verify];
}

- (void)testStartMonitoringDoesntStartWhenKeyIsNil {
    [self setTuneUtilsGetClassFromStringToAnObject];
    
    [self setTuneConfigurationMockWithDebug:NO];
    
    id mockTestObj = OCMPartialMock(testObj);
    [[mockTestObj reject] startProximityMonitoringWithAppId:OCMOCK_ANY
                                                 withApiKey:OCMOCK_ANY
                                              withApiSecret:OCMOCK_ANY
                                                 withConfig:OCMOCK_ANY];
    
    [mockTestObj startMonitoringWithTuneAdvertiserId:@"aid" tuneConversionKey:nil packageName:@"packageName"];
    
    [mockTestObj verify];
    [mockTuneManager verify];
}

- (void)testStartMonitoringSetsDebugLoggingWhenTuneLoggingIsEnabled {
    [self setTuneConfigurationMockWithDebug:YES];
    [self setTuneUtilsGetClassFromStringToAnObject];
    
    NSString *aid = @"aid";
    NSString *conversionKey = @"key";
    
    id mockTestObj = OCMPartialMock(testObj);
    [[mockTestObj expect] startProximityMonitoringWithAppId:aid
                                                 withApiKey:aid
                                              withApiSecret:conversionKey
                                                 withConfig:[OCMArg checkWithBlock:^BOOL(id value) {
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary *actualConfig = value;
            return actualConfig[@"DEBUG_LOGGING"] && [actualConfig[@"DEBUG_LOGGING"] isEqual:@"true"];
        }
        return NO;
    }]];
    
    [mockTestObj startMonitoringWithTuneAdvertiserId:@"aid" tuneConversionKey:@"key" packageName:@"packageName"];
    
    [mockTestObj verify];
}

- (void)testStartMonitoringSetsPackageName {
    [self setTuneConfigurationMockWithDebug:YES];
    [self setTuneUtilsGetClassFromStringToAnObject];
    
    NSString *aid = @"aid";
    NSString *conversionKey = @"key";
    NSString *packageName = @"packageName";
    
    id mockTestObj = OCMPartialMock(testObj);
    [[mockTestObj expect] startProximityMonitoringWithAppId:aid
                                                 withApiKey:aid
                                              withApiSecret:conversionKey
                                                 withConfig:[OCMArg checkWithBlock:^BOOL(id value) {
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary *actualConfig = value;
            return actualConfig[@"PACKAGE_NAME"] && [actualConfig[@"PACKAGE_NAME"] isEqual:packageName];
        }
        return NO;
    }]];
    
    [mockTestObj startMonitoringWithTuneAdvertiserId:@"aid" tuneConversionKey:@"key" packageName:packageName];
    
    [mockTestObj verify];
}

#pragma mark - setDebugMode tests

- (void)testSetDebugModeSetsDebugLoggingConfigAndInvokesSmartWhereConfigWhenYES {
    [testObj setSmartWhere:mockSmartWhere];
    id mockTestObj = OCMPartialMock(testObj);
    [[mockTestObj expect] setConfig:[OCMArg checkWithBlock:^BOOL(id value) {
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary* actualConfig = value;
            return actualConfig[@"DEBUG_LOGGING"] && [actualConfig[@"DEBUG_LOGGING"] isEqual:@"true"];
        }
        return NO;
    }]];
    
    [(TuneSmartWhereHelper*)mockTestObj setDebugMode:YES];
    
    [mockTestObj verify];
}

- (void)testSetDebugModeSetsDebugLoggingConfigAndInvokesSmartWhereConfigWhenNO {
    [testObj setSmartWhere:mockSmartWhere];
    id mockTestObj = OCMPartialMock(testObj);
    [[mockTestObj expect] setConfig:[OCMArg checkWithBlock:^BOOL(id value) {
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary* actualConfig = value;
            return actualConfig[@"DEBUG_LOGGING"] && [actualConfig[@"DEBUG_LOGGING"] isEqual:@"false"];
        }
        return NO;
    }]];
    
    [(TuneSmartWhereHelper*)mockTestObj setDebugMode:NO];
    
    [mockTestObj verify];
}

- (void)testSetDebugModeDoesntAttemptWhenNotInstantiated {
    id mockTestObj = OCMPartialMock(testObj);
    [[mockTestObj reject] setConfig:OCMOCK_ANY];
    
    [(TuneSmartWhereHelper*)mockTestObj setDebugMode:NO];
    
    [mockTestObj verify];
}

#pragma mark - setPackageName tests

- (void)testSetPackageNameSetsPackageNameConfigAndInvokesSmartWhereConfig {
    NSString *expectedPackageName = @"com.expected.package.name";
    [testObj setSmartWhere:mockSmartWhere];
    id mockTestObj = OCMPartialMock(testObj);
    [[mockTestObj expect] setConfig:[OCMArg checkWithBlock:^BOOL(id value) {
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDictionary* actualConfig = value;
            return actualConfig[@"PACKAGE_NAME"] && [actualConfig[@"PACKAGE_NAME"] isEqual:expectedPackageName];
        }
        return NO;
    }]];
    
    [(TuneSmartWhereHelper*)mockTestObj setPackageName:expectedPackageName];
    
    [mockTestObj verify];
}

- (void)testSetPackageNameDoesntAttemptWhenNotInstantiated {
    id mockTestObj = OCMPartialMock(testObj);
    [[mockTestObj reject] setConfig:OCMOCK_ANY];
    
    [(TuneSmartWhereHelper*)mockTestObj setPackageName:@"any.package.name"];
    
    [mockTestObj verify];
}

#pragma mark - stopMonitoring tests

- (void)testStopMonitoringCallsInvalidateOnSmartWhereAndSetsToNil {
    [testObj setSmartWhere:mockSmartWhere];
    [[mockSmartWhere expect] invalidate];
    
    [testObj stopMonitoring];
    
    [mockSmartWhere verify];
    XCTAssertNil(testObj.getSmartWhere);
}

#pragma mark - processMappedEvent tests

- (void)testprocessMappedEventCallsOnSmartWhere {
    NSString *eventName = @"test_event_name";
    TuneEvent *expectedEvent = [TuneEvent eventWithName:eventName];
    TuneSkyhookPayload *payload = [[TuneSkyhookPayload alloc] initWithName:@"name" object:[NSObject new] userInfo:@{TunePayloadCustomEvent: expectedEvent }];
    
    [testObj setSmartWhere:mockSmartWhere];
    [[mockSmartWhere reject] performSelector:@selector(processMappedEvent:) withObject:OCMOCK_ANY];
    
    [testObj processMappedEvent:payload];
    
    [mockSmartWhere verify];
}

- (void)testprocessMappedEventCallsOnSmartWhereEventSharingEnabled {
    NSString *eventName = @"test_event_name";
    TuneEvent *expectedEvent = [TuneEvent eventWithName:eventName];
    TuneSkyhookPayload *payload = [[TuneSkyhookPayload alloc] initWithName:@"name" object:[NSObject new] userInfo:@{TunePayloadCustomEvent: expectedEvent }];
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[mockSmartWhere expect] performSelector:@selector(processMappedEvent:) withObject:eventName];
    
    [testObj processMappedEvent:payload];
    
    [mockSmartWhere verify];
}

- (void)testprocessMappedEventDoesntCallOnSmartWhereWhenNotInstantiated {
    NSString *eventName = @"test_event_name";
    TuneEvent *expectedEvent = [TuneEvent eventWithName:eventName];
    TuneSkyhookPayload *payload = [[TuneSkyhookPayload alloc] initWithName:@"name" object:[NSObject new] userInfo:@{TunePayloadCustomEvent: expectedEvent }];
    
    [[mockSmartWhere reject] performSelector:@selector(processMappedEvent:) withObject:OCMOCK_ANY];
    
    [testObj processMappedEvent:payload];
    
    [mockSmartWhere verify];
}

- (void)testprocessMappedEventDoesntCallOnSmartWhereWhenThereIsNoEventInUserInfo {
    TuneSkyhookPayload *payload = [[TuneSkyhookPayload alloc] initWithName:@"name" object:[NSObject new] userInfo:@{}];
    
    [testObj setSmartWhere:mockSmartWhere];
    [[mockSmartWhere reject] performSelector:@selector(processMappedEvent:) withObject:OCMOCK_ANY];
    
    [testObj processMappedEvent:payload];
    
    [mockSmartWhere verify];
}

- (void)testprocessMappedEventDoesntCallOnSmartWhereWhenUserInfoIsNil {
    TuneSkyhookPayload *payload = [[TuneSkyhookPayload alloc] initWithName:@"name" object:[NSObject new] userInfo:nil];
    
    [testObj setSmartWhere:mockSmartWhere];
    [[mockSmartWhere reject] performSelector:@selector(processMappedEvent:) withObject:OCMOCK_ANY];
    
    [testObj processMappedEvent:payload];
    
    [mockSmartWhere verify];
}

#pragma mark - set Attribute Value tests

- (void)testsetAttributeValueFromAnalyticsVariableCallsSmartWhereWhenAvailable {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"variableName";
    NSString *expectedVariableName = [NSString stringWithFormat:@"T_A_V_%@", variableName];
    NSString *expectedValue = @"expectedValue";
    
    TuneAnalyticsVariable *analyticsVariable = [TuneAnalyticsVariable analyticsVariableWithName:variableName value:expectedValue];
    [testObj setSmartWhere:mockSmartWhere];
        testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere expect] classMethod] performSelector:@selector(setUserString:forKey:) withObject:expectedValue withObject:expectedVariableName];
    
    [testObj setAttributeValueFromAnalyticsVariable:analyticsVariable];
    
    [mockSmartWhere verify];
}

- (void)testsetAttributeVAlueFromAnalyticsVariableDoenstCallSmartWhereWhenNotAvailable {
    [[[[mockTuneUtils expect] classMethod] andReturn:nil] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"variableName";
    NSString *expectedValue = @"expectedValue";
    
    TuneAnalyticsVariable *analyticsVariable = [TuneAnalyticsVariable analyticsVariableWithName:variableName value:expectedValue];
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(setUserString:forKey:) withObject:OCMOCK_ANY withObject:OCMOCK_ANY];
    
    [testObj setAttributeValueFromAnalyticsVariable:analyticsVariable];
    
    [mockSmartWhere verify];
}

- (void)testsetAttributeValueFromAnalyticsVariableDoesntCallSmartWhereWhenEventSharingIsDisabled {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"variableName";
    NSString *expectedValue = @"expectedValue";
    
    TuneAnalyticsVariable *analyticsVariable = [TuneAnalyticsVariable analyticsVariableWithName:variableName value:expectedValue];
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = NO;
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(setUserString:forKey:) withObject:OCMOCK_ANY withObject:OCMOCK_ANY];
    
    [testObj setAttributeValueFromAnalyticsVariable:analyticsVariable];
    
    [mockSmartWhere verify];
}

- (void)testsetAttributeFromAnalyticsVariableChecksThatTheNameExists {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = nil;
    NSString *expectedValue = @"expectedValue";
    
    TuneAnalyticsVariable *analyticsVariable = [TuneAnalyticsVariable analyticsVariableWithName:variableName value:expectedValue];
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(setUserString:forKey:) withObject:OCMOCK_ANY withObject:OCMOCK_ANY];
    
    [testObj setAttributeValueFromAnalyticsVariable:analyticsVariable];
    
    [mockSmartWhere verify];
}

- (void)testsetAttributeFromAnalyticsVariableChecksThatTheNameIsntEmpty {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"";
    NSString *expectedValue = @"expectedValue";
    
    TuneAnalyticsVariable *analyticsVariable = [TuneAnalyticsVariable analyticsVariableWithName:variableName value:expectedValue];
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(setUserString:forKey:) withObject:OCMOCK_ANY withObject:OCMOCK_ANY];
    
    [testObj setAttributeValueFromAnalyticsVariable:analyticsVariable];
    
    [mockSmartWhere verify];
}

- (void)testsetAttributeFromAnalyticsVariableRemovesTheAttributeIfTheValueIsNull {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"variableName";
    NSString *expectedVariableName = [NSString stringWithFormat:@"T_A_V_%@", variableName];
    NSString *expectedValue = nil;
    
    TuneAnalyticsVariable *analyticsVariable = [TuneAnalyticsVariable analyticsVariableWithName:variableName value:expectedValue];
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere expect] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:expectedVariableName];
    
    [testObj setAttributeValueFromAnalyticsVariable:analyticsVariable];
    
    [mockSmartWhere verify];
}

- (void)testsetAttributeValueCallsSmartWhereWhenAvailable {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"variableName";
    NSString *expectedVariableName = [NSString stringWithFormat:@"T_A_V_%@", variableName];
    NSString *expectedValue = @"expectedValue";
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere expect] classMethod] performSelector:@selector(setUserString:forKey:) withObject:expectedValue withObject:expectedVariableName];
    
    [testObj setAttributeValue:expectedValue forKey:variableName];
    
    [mockSmartWhere verify];
}

- (void)testsetAttributeValueDoenstCallSmartWhereWhenNotAvailable {
    [[[[mockTuneUtils expect] classMethod] andReturn:nil] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"variableName";
    NSString *expectedValue = @"expectedValue";
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(setUserString:forKey:) withObject:OCMOCK_ANY withObject:OCMOCK_ANY];
    
    [testObj setAttributeValue:variableName forKey:expectedValue];
    
    [mockSmartWhere verify];
}

- (void)testsetAttributeValueDoesntCallSmartWhereWhenEventSharingIsDisabled {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"variableName";
    NSString *expectedValue = @"expectedValue";
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = NO;
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(setUserString:forKey:) withObject:OCMOCK_ANY withObject:OCMOCK_ANY];
    
    [testObj setAttributeValue:expectedValue forKey:variableName];
    
    [mockSmartWhere verify];
}

- (void)testsetAttributeChecksThatTheNameExists {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = nil;
    NSString *expectedValue = @"expectedValue";
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(setUserString:forKey:) withObject:OCMOCK_ANY withObject:OCMOCK_ANY];
    
    [testObj setAttributeValue:expectedValue forKey:variableName];
    
    [mockSmartWhere verify];
}

- (void)testsetAttributeChecksThatTheNameIsntEmpty {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"";
    NSString *expectedValue = @"expectedValue";
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(setUserString:forKey:) withObject:OCMOCK_ANY withObject:OCMOCK_ANY];
    
    [testObj setAttributeValue:expectedValue forKey:variableName];
    
    [mockSmartWhere verify];
}

- (void)testsetAttributeRemovesTheAttributeIfTheValueIsNull {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"variableName";
    NSString *expectedVariableName = [NSString stringWithFormat:@"T_A_V_%@", variableName];
    NSString *expectedValue = nil;
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere expect] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:expectedVariableName];
    
    [testObj setAttributeValue:expectedValue forKey:variableName];
    
    [mockSmartWhere verify];
}

#pragma setAttributeValuesFromPayload tests

- (void)testsetAttributeValuesFromEventTagsCallsSmartWhere {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    NSString *variableName = @"key";
    NSString *expectedVariableName = [NSString stringWithFormat:@"T_A_V_%@", variableName];
    NSString *expectedValue = @"value";
    
    TuneEvent *expectedEvent = [TuneEvent eventWithName:TUNE_EVENT_ADD_TO_CART];
    [expectedEvent addTag:variableName withStringValue:expectedValue];
    TuneSkyhookPayload *payload = [[TuneSkyhookPayload alloc] initWithName:@"name" object:[NSObject new] userInfo:@{TunePayloadCustomEvent: expectedEvent }];

    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere expect] classMethod] performSelector:@selector(setUserString:forKey:) withObject:expectedValue withObject:expectedVariableName];

    [testObj setAttributeValuesFromPayload:payload];

    [mockSmartWhere verify];
}

- (void)testsetAttributeValuesFromEventTagsCallSmartWhereForEachTag {
    [[[[mockTuneUtils stub] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    NSString *variableName = @"key";
    NSString *expectedVariableName = [NSString stringWithFormat:@"T_A_V_%@", variableName];
    NSString *expectedValue = @"value";
    NSString *variableName2 = @"key2";
    NSString *expectedVariableName2 = [NSString stringWithFormat:@"T_A_V_%@", variableName2];
    NSString *expectedValue2 = @"value2";
    
    TuneEvent *expectedEvent = [TuneEvent eventWithName:TUNE_EVENT_ADD_TO_CART];
    [expectedEvent addTag:variableName withStringValue:expectedValue];
    [expectedEvent addTag:variableName2 withStringValue:expectedValue2];
    TuneSkyhookPayload *payload = [[TuneSkyhookPayload alloc] initWithName:@"name" object:[NSObject new] userInfo:@{TunePayloadCustomEvent: expectedEvent }];
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere expect] classMethod] performSelector:@selector(setUserString:forKey:) withObject:expectedValue withObject:expectedVariableName];
    [[[mockSmartWhere expect] classMethod] performSelector:@selector(setUserString:forKey:) withObject:expectedValue2 withObject:expectedVariableName2];
    
    [testObj setAttributeValuesFromPayload:payload];
    
    [mockSmartWhere verify];
}

- (void)testsetAttributeValuesFromEventTagsDoesntCallSmartWhereWhenNotAvailable {
    [[[[mockTuneUtils stub] classMethod] andReturn:nil] getClassFromString:@"SmartWhere"];
    NSString *variableName = @"key";
    NSString *expectedVariableName = [NSString stringWithFormat:@"T_A_V_%@", variableName];
    NSString *expectedValue = @"value";
    
    TuneEvent *expectedEvent = [TuneEvent eventWithName:TUNE_EVENT_ADD_TO_CART];
    [expectedEvent addTag:variableName withStringValue:expectedValue];
    TuneSkyhookPayload *payload = [[TuneSkyhookPayload alloc] initWithName:@"name" object:[NSObject new] userInfo:@{TunePayloadCustomEvent: expectedEvent }];
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(setUserString:forKey:) withObject:expectedValue withObject:expectedVariableName];
    
    [testObj setAttributeValuesFromPayload:payload];
    
    [mockSmartWhere verify];;
}

#pragma mark - clear attribute tests

- (void)testclearAttributeValueCallsSmartWhereToRemoveObject {
    [[[[mockTuneUtils stub] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    NSString *variableName = @"expectedName";
    NSString *expectedVariableName = [NSString stringWithFormat:@"T_A_V_%@", variableName];

    [[[mockSmartWhere expect] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:expectedVariableName];

    testObj.enableSmartWhereEventSharing = YES;
    [testObj clearAttributeValue:variableName];
    
    [mockSmartWhere verify];
}

- (void)testclearAttributeValueDoesntCallSmartWhereWhenNotAvailable {
    [[[[mockTuneUtils stub] classMethod] andReturn:nil] getClassFromString:@"SmartWhere"];
    NSString *expectedName = @"expectedName";
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:OCMOCK_ANY];
    
    testObj.enableSmartWhereEventSharing = YES;
    [testObj clearAttributeValue:expectedName];
    
    [mockSmartWhere verify];
}

- (void)testtestclearAttributeValueDoesntCallSmartWhereWhenSharingIsntEnabled {
    [[[[mockTuneUtils stub] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    NSString *variableName = @"expectedName";
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:OCMOCK_ANY];
    
    testObj.enableSmartWhereEventSharing = NO;
    [testObj clearAttributeValue:variableName];
    
    [mockSmartWhere verify];
}

- (void)testtestclearAllAttributeValuesCallsSmartWhereForEachValueWithTunePrefix {
    [[[[mockTuneUtils stub] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    NSMutableDictionary *currentlySetAttributes = [NSMutableDictionary new];
    currentlySetAttributes[@"key1"] = @"value1";
    currentlySetAttributes[@"key2"] = @"value2";
    currentlySetAttributes[@"key3"] = @"value3";
    currentlySetAttributes[@"T_A_V_key4"]= @"a value";
    currentlySetAttributes[@"T_A_V_key5"] = @"abc 123";

    [[[[mockSmartWhere expect] classMethod] andReturn:currentlySetAttributes] performSelector:@selector(getUserAttributes)];

    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"key1"];
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"key2"];
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"key3"];
    [[[mockSmartWhere expect] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"T_A_V_key4"];
    [[[mockSmartWhere expect] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"T_A_V_key5"];

    testObj.enableSmartWhereEventSharing = YES;
    [testObj clearAllAttributeValues];
    
    [mockSmartWhere verify];
}

- (void)testtestclearAllAttributeValuesDoesntCallSmartWhereWhenNotAvailable {
    [[[[mockTuneUtils stub] classMethod] andReturn:nil] getClassFromString:@"SmartWhere"];
    NSMutableDictionary *currentlySetAttributes = [NSMutableDictionary new];
    currentlySetAttributes[@"key1"] = @"value1";
    currentlySetAttributes[@"key2"] = @"value2";
    currentlySetAttributes[@"key3"] = @"value3";
    currentlySetAttributes[@"T_A_V_key4"]= @"a value";
    currentlySetAttributes[@"T_A_V_key5"] = @"abc 123";
    
    [[[[mockSmartWhere reject] classMethod] andReturn:currentlySetAttributes] performSelector:@selector(getUserAttributes)];
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"key1"];
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"key2"];
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"key3"];
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"T_A_V_key4"];
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"T_A_V_key5"];
    
    testObj.enableSmartWhereEventSharing = YES;
    [testObj clearAllAttributeValues];
    
    [mockSmartWhere verify];
}

- (void)testtestclearAllAttributeValuesDoesntCallSmartWhereWhenSharingIsntEnabled {
    [[[[mockTuneUtils stub] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    NSMutableDictionary *currentlySetAttributes = [NSMutableDictionary new];
    currentlySetAttributes[@"key1"] = @"value1";
    currentlySetAttributes[@"key2"] = @"value2";
    currentlySetAttributes[@"key3"] = @"value3";
    currentlySetAttributes[@"T_A_V_key4"]= @"a value";
    currentlySetAttributes[@"T_A_V_key5"] = @"abc 123";
    
    [[[[mockSmartWhere reject] classMethod] andReturn:currentlySetAttributes] performSelector:@selector(getUserAttributes)];
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"key1"];
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"key2"];
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"key3"];
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"T_A_V_key4"];
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(removeUserValueForKey:) withObject:@"T_A_V_key5"];
    
    testObj.enableSmartWhereEventSharing = NO;
    [testObj clearAllAttributeValues];
    
    [mockSmartWhere verify];
}

#pragma mark - set tracking attribute value tests

- (void)testSetTrackingAttributeValueCallsSmartWhereWhenAvailable {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"variableName";
    NSString *expectedVariableName = [NSString stringWithFormat:@"T_A_V_%@", variableName];
    NSString *expectedValue = @"expectedValue";
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere expect] classMethod] performSelector:@selector(setUserTrackingString:forKey:) withObject:expectedValue withObject:expectedVariableName];
    
    [testObj setTrackingAttributeValue:expectedValue forKey:variableName];
    
    [mockSmartWhere verify];
}

- (void)testSetTrackingAttributeValueDoesntCallSmartWhereWhenNotAvailable {
    [[[[mockTuneUtils expect] classMethod] andReturn:nil] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"variableName";
    NSString *expectedValue = @"expectedValue";
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(setUserTrackingString:forKey:) withObject:OCMOCK_ANY withObject:OCMOCK_ANY];
    
    [testObj setTrackingAttributeValue:variableName forKey:expectedValue];
    
    [mockSmartWhere verify];
}

- (void)testSetTrackingAttributeValueDoesntCallSmartWhereWhenEventSharingIsDisabled {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"variableName";
    NSString *expectedValue = @"expectedValue";
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = NO;
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(setUserTrackingString:forKey:) withObject:OCMOCK_ANY withObject:OCMOCK_ANY];
    
    [testObj setTrackingAttributeValue:expectedValue forKey:variableName];
    
    [mockSmartWhere verify];
}

- (void)testSetTrackingAttributeChecksThatTheNameExists {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = nil;
    NSString *expectedValue = @"expectedValue";
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(setUserTrackingString:forKey:) withObject:OCMOCK_ANY withObject:OCMOCK_ANY];
    
    [testObj setTrackingAttributeValue:expectedValue forKey:variableName];
    
    [mockSmartWhere verify];
}

- (void)testSetTrackingAttributeChecksThatTheNameIsntEmpty{
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"";
    NSString *expectedValue = @"expectedValue";
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere reject] classMethod] performSelector:@selector(setUserTrackingString:forKey:) withObject:OCMOCK_ANY withObject:OCMOCK_ANY];
    
    [testObj setTrackingAttributeValue:expectedValue forKey:variableName];
    
    [mockSmartWhere verify];

}
- (void)testSetTrackingAttributeRemovesTheAttributeIfTheValueIsNull {
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
    
    NSString *variableName = @"variableName";
    NSString *expectedVariableName = [NSString stringWithFormat:@"T_A_V_%@", variableName];
    NSString *expectedValue = nil;
    
    [testObj setSmartWhere:mockSmartWhere];
    testObj.enableSmartWhereEventSharing = YES;
    
    [[[mockSmartWhere expect] classMethod] performSelector:@selector(removeUserTrackingValueForKey:) withObject:expectedVariableName];
    
    [testObj setTrackingAttributeValue:expectedValue forKey:variableName];
    
    [mockSmartWhere verify];
}


#pragma mark - test helpers

- (void)setTuneConfigurationMockWithDebug:(BOOL)debug {
    TuneConfiguration *config = [TuneConfiguration new];
    config.debugMode = @(debug);
    [[[[mockTuneManager stub] classMethod] andReturn:mockTuneManager] currentManager];
    [[[mockTuneManager stub] andReturn:config] configuration];
}

- (void)setTuneUtilsGetClassFromStringToAnObject {
//    id obj = [NSObject new];
    [[[[mockTuneUtils expect] classMethod] andReturn:[mockSmartWhere class]] getClassFromString:@"SmartWhere"];
}

@end
