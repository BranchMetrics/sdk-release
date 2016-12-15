//
//  TuneSmartWhereMonitoringTests.m
//  Tune
//
//  Created by Gordon Stewart on 8/4/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#if TUNE_ENABLE_SMARTWHERE

#import <XCTest/XCTest.h>

#import "Tune+Testing.h"
#import "TuneLocation.h"
#import "TuneManager.h"
#import "TuneSmartWhereHelper.h"
#import "TuneUserProfile.h"
#import "TuneXCTestCase.h"

#import <OCMock/OCMock.h>

@interface TuneSmartWhereMonitoringTests : TuneXCTestCase <TuneDelegate> {
    id smartWhereHelperMock;
}

@end

@implementation TuneSmartWhereMonitoringTests

- (void)setUp {
    [super setUp];
    
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId wearable:NO];
    [Tune setDelegate:self];
    
    waitForQueuesToFinish();
    
    smartWhereHelperMock = OCMStrictClassMock([TuneSmartWhereHelper class]);
    [[[[smartWhereHelperMock stub] classMethod] andReturn:smartWhereHelperMock] getInstance];
}

- (void)tearDown {
    [smartWhereHelperMock stopMocking];
    
    [super tearDown];
}


#pragma mark - SmartWhere Proximity Monitoring Start/Stop Tests

- (void)testSetLocationStopsProximityMonitoring {
    [[[[smartWhereHelperMock expect] classMethod] andReturnValue:OCMOCK_VALUE(YES)] isSmartWhereAvailable];
    [[smartWhereHelperMock expect] stopMonitoring];
    
    TuneLocation *location = [TuneLocation new];
    [Tune setLocation:location];
    waitForQueuesToFinish();
    
    [smartWhereHelperMock verify];
}

- (void)testSetLocationDoesntStopProximityMonitoringWhenNotInstalled {
    [[[[smartWhereHelperMock expect] classMethod] andReturnValue:OCMOCK_VALUE(NO)] isSmartWhereAvailable];
    [[smartWhereHelperMock reject] stopMonitoring];
    
    TuneLocation *location = [TuneLocation new];
    [Tune setLocation:location];
    waitForQueuesToFinish();
    
    [smartWhereHelperMock verify];
}

- (void)testSetShouldAutoCollectDeviceLocationStopsProximityMonitoringWhenSettingToNo {
    [[[[smartWhereHelperMock expect] classMethod] andReturnValue:OCMOCK_VALUE(YES)] isSmartWhereAvailable];
    [[smartWhereHelperMock expect] stopMonitoring];
    
    [Tune setShouldAutoCollectDeviceLocation:NO];
    waitForQueuesToFinish();
    
    [smartWhereHelperMock verify];
}

- (void)testSetShouldAutoCollectDeviceLocationDoesntStopProximityMonitoringWhenNotInstalledAndSettingToNo {
    [[[[smartWhereHelperMock expect] classMethod] andReturnValue:OCMOCK_VALUE(NO)] isSmartWhereAvailable];
    [[smartWhereHelperMock reject] stopMonitoring];
    
    [Tune setShouldAutoCollectDeviceLocation:NO];
    waitForQueuesToFinish();
    
    [smartWhereHelperMock verify];
}

- (void)testSetShouldAutoCollectDeviceLocationStartsProximityMonitoringWhenSettingToYes {
    NSString *advertiserId = [[TuneManager currentManager].userProfile advertiserId];
    NSString *conversionKey = [[TuneManager currentManager].userProfile conversionKey];
    XCTAssertNotNil(advertiserId);
    XCTAssertNotNil(conversionKey);
    
    [[[[smartWhereHelperMock expect] classMethod] andReturnValue:OCMOCK_VALUE(YES)] isSmartWhereAvailable];
    [[smartWhereHelperMock expect] startMonitoringWithTuneAdvertiserId:advertiserId tuneConversionKey:conversionKey];
    
    [Tune setShouldAutoCollectDeviceLocation:YES];
    waitForQueuesToFinish();
    
    [smartWhereHelperMock verify];
}

- (void)testSetShouldAutoCollectDeviceLocationDoesntStartProximityMonitoringWhenNotInstalledAndSettingToYes {
    [[[[smartWhereHelperMock expect] classMethod] andReturnValue:OCMOCK_VALUE(NO)] isSmartWhereAvailable];
    [[smartWhereHelperMock reject] startMonitoringWithTuneAdvertiserId:OCMOCK_ANY tuneConversionKey:OCMOCK_ANY];
    
    [Tune setShouldAutoCollectDeviceLocation:YES];
    waitForQueuesToFinish();
    
    [smartWhereHelperMock verify];
}


#pragma mark - setDebugMode tests

- (void)testSetDebugModeSetsProximityDebugModeWhenInstalled {
    [[[[smartWhereHelperMock expect] classMethod] andReturnValue:OCMOCK_VALUE(YES)] isSmartWhereAvailable];
    [(TuneSmartWhereHelper*)[smartWhereHelperMock expect] setDebugMode:YES];
    
    [Tune setDebugMode:YES];
    waitForQueuesToFinish();
    
    [smartWhereHelperMock verify];
}

- (void)testSetDebugModeDoesntSetsProximityDebugModeWhenInstalled {
    [[[[smartWhereHelperMock expect] classMethod] andReturnValue:OCMOCK_VALUE(NO)] isSmartWhereAvailable];
    [(TuneSmartWhereHelper*)[smartWhereHelperMock reject] setDebugMode:YES];
    
    [Tune setDebugMode:YES];
    waitForQueuesToFinish();
    
    [smartWhereHelperMock verify];
}

@end

#endif
