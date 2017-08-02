//
//  TuneSmartWhereMonitoringTests.m
//  Tune
//
//  Created by Gordon Stewart on 8/4/16.
//  Copyright © 2016 Tune. All rights reserved.
//
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

#pragma mark - setPackageName tests

- (void)testSetPackageNameCallsSmartwhereHelperSetPackageNameWhenInstalled {
    NSString *expectedPackageName = @"com.expected.package.name";
    [[[[smartWhereHelperMock expect] classMethod] andReturnValue:OCMOCK_VALUE(YES)] isSmartWhereAvailable];
    [(TuneSmartWhereHelper*)[smartWhereHelperMock expect] setPackageName:expectedPackageName];
    
    [Tune setPackageName:expectedPackageName];
    waitForQueuesToFinish();
    
    [smartWhereHelperMock verify];
}

- (void)testSetPackageNameDoesntAttemptToSetOnSmartwhereHelperWhenNotInstalled {
    NSString *expectedPackageName = @"com.expected.package.name";
    [[[[smartWhereHelperMock expect] classMethod] andReturnValue:OCMOCK_VALUE(NO)] isSmartWhereAvailable];
    [(TuneSmartWhereHelper*)[smartWhereHelperMock reject] setPackageName:OCMOCK_ANY];
    
    [Tune setPackageName:expectedPackageName];
    waitForQueuesToFinish();
    
    [smartWhereHelperMock verify];
}

@end
