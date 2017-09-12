//
//  TuneSmartWherePublicAPITests.m
//  TuneMarketingConsoleSDK
//
//  Created by Ernest Cho on 7/20/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneXCTestCase.h"
#import <OCMock/OCMock.h>
#import "Tune+Testing.h"
#import "TuneTestsHelper.h"
#import "TuneSmartWhereHelper.h"
#import "SmartWhereForDelegateTest.h"

@interface TuneSmartWherePublicAPITests : XCTestCase

@end

@implementation TuneSmartWherePublicAPITests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testEnableSmartWhere {
    id helperMock = OCMClassMock([TuneSmartWhereHelper class]);
    [OCMStub([helperMock isSmartWhereAvailable]) andReturnValue:[NSNumber numberWithBool:YES]];

    @try {
        [Tune enableSmartwhereIntegration];
    }
    @catch (NSException *e) {
        XCTFail(@":(");
    }
    
    OCMVerify([helperMock isSmartWhereAvailable]);
    [helperMock stopMocking];
    
}

- (void)testEnableSmartWhereNoSDK {
    id helperMock = OCMClassMock([TuneSmartWhereHelper class]);
    [OCMStub([helperMock isSmartWhereAvailable]) andReturnValue:[NSNumber numberWithBool:NO]];
    
    @try {
        [Tune enableSmartwhereIntegration];
    }
    @catch (NSException *e) {
        XCTAssertNotNil(e);
    }
    
    OCMVerify([helperMock isSmartWhereAvailable]);
    [helperMock stopMocking];
}

- (void)testEnableSmartWhereDefaultSettings {
    id helperMock = OCMClassMock([TuneSmartWhereHelper class]);
    [OCMStub([helperMock isSmartWhereAvailable]) andReturnValue:[NSNumber numberWithBool:YES]];
    
    [Tune enableSmartwhereIntegration];
    waitForQueuesToFinish();
    
    XCTAssertFalse([TuneSmartWhereHelper getInstance].enableSmartWhereEventSharing);

    
    [helperMock stopMocking];
}

- (void)testEnableSmartWhereWithDataSharing {
    id helperMock = OCMClassMock([TuneSmartWhereHelper class]);
    [OCMStub([helperMock isSmartWhereAvailable]) andReturnValue:[NSNumber numberWithBool:YES]];
    
    [Tune enableSmartwhereIntegration];
    [Tune configureSmartwhereIntegrationWithOptions:TuneSmartwhereShareEventData];
    waitForQueuesToFinish();
    
    XCTAssertTrue([TuneSmartWhereHelper getInstance].enableSmartWhereEventSharing);
    
    [helperMock stopMocking];
}

- (void)testEnableSmartWhereThenDisableDataSharing {
    id helperMock = OCMClassMock([TuneSmartWhereHelper class]);
    [OCMStub([helperMock isSmartWhereAvailable]) andReturnValue:[NSNumber numberWithBool:YES]];
    
    [Tune enableSmartwhereIntegration];
    [Tune configureSmartwhereIntegrationWithOptions:TuneSmartwhereShareEventData];
    waitForQueuesToFinish();
    
    XCTAssertTrue([TuneSmartWhereHelper getInstance].enableSmartWhereEventSharing);
    // TODO: figure out a way to stub out a conditionally loaded class that is not available
    //XCTAssertNotNil([[TuneSmartWhereHelper getInstance] getSmartWhere]);

    [Tune configureSmartwhereIntegrationWithOptions:TuneSmartwhereResetConfiguration];
    waitForQueuesToFinish();
    
    XCTAssertFalse([TuneSmartWhereHelper getInstance].enableSmartWhereEventSharing);
    //XCTAssertNotNil([TuneSmartWhereHelper getInstance].getSmartWhere);

    [helperMock stopMocking];
}

- (void)testEnableSmartWhereThenDisableSmartWhere {
    id helperMock = OCMClassMock([TuneSmartWhereHelper class]);
    [OCMStub([helperMock isSmartWhereAvailable]) andReturnValue:[NSNumber numberWithBool:YES]];
    
    [Tune enableSmartwhereIntegration];
    [Tune configureSmartwhereIntegrationWithOptions:TuneSmartwhereShareEventData];
    waitForQueuesToFinish();
    
    XCTAssertTrue([TuneSmartWhereHelper getInstance].enableSmartWhereEventSharing);
    //XCTAssertNotNil([TuneSmartWhereHelper getInstance].getSmartWhere);

    [Tune disableSmartwhereIntegration];
    waitForQueuesToFinish();
    
    XCTAssertFalse([TuneSmartWhereHelper getInstance].enableSmartWhereEventSharing);
    //XCTAssertNil([TuneSmartWhereHelper getInstance].getSmartWhere);
    
    [helperMock stopMocking];
}

@end
