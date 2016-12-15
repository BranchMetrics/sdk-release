//
//  TuneSmartWhereHelperTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Gordon Stewart on 8/4/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#if TUNE_ENABLE_SMARTWHERE

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "TuneConfiguration.h"
#import "TuneManager.h"
#import "TuneSmartWhereHelper.h"
#import "TuneUtils.h"

@interface SmartWhereForTest : NSObject
- (void)invalidate;
@end

@implementation SmartWhereForTest
- (void)invalidate {
    // empty
}
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
            (actualConfig[@"DELEGATE_NOTIFICATIONS"] && [actualConfig[@"DELEGATE_NOTIFICATIONS"] isEqual:@"true"]);
        }
        return NO;
    }]];
    
    [mockTestObj startMonitoringWithTuneAdvertiserId:@"aid" tuneConversionKey:@"key"];
    
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
    
    [mockTestObj startMonitoringWithTuneAdvertiserId:@"aid" tuneConversionKey:@"key"];
    
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
    
    [mockTestObj startMonitoringWithTuneAdvertiserId:nil tuneConversionKey:@"key"];
    
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
    
    [mockTestObj startMonitoringWithTuneAdvertiserId:@"aid" tuneConversionKey:nil];
    
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
    
    [mockTestObj startMonitoringWithTuneAdvertiserId:@"aid" tuneConversionKey:@"key"];
    
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

- (void)testSetDebugModeDoesntAttemptWhenNotInstanciated {
    id mockTestObj = OCMPartialMock(testObj);
    [[mockTestObj reject] setConfig:OCMOCK_ANY];
    
    [(TuneSmartWhereHelper*)mockTestObj setDebugMode:NO];
    
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


#pragma mark - test helpers

- (void)setTuneConfigurationMockWithDebug:(BOOL)debug {
    TuneConfiguration *config = [TuneConfiguration new];
    config.debugMode = @(debug);
    [[[[mockTuneManager stub] classMethod] andReturn:mockTuneManager] currentManager];
    [[[mockTuneManager stub] andReturn:config] configuration];
}

- (void)setTuneUtilsGetClassFromStringToAnObject {
    id obj = [NSObject new];
    [[[[mockTuneUtils expect] classMethod] andReturn:obj] getClassFromString:@"SmartWhere"];
}

@end

#endif
