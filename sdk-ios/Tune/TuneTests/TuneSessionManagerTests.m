//
//  TuneSessionManagerTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/20/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "Tune+Testing.h"
#import "TuneFileManager.h"
#import "TuneFileUtils.h"
#import "TuneManager.h"
#import "TunePlaylistManager+Testing.h"
#import "TuneSessionManager+Testing.h"
#import "TuneSkyhookCenter.h"
#import "TuneXCTestCase.h"

@interface TuneSessionManagerTests : TuneXCTestCase {
    id mockApplication;
    
    TuneSessionManager *sessionManager;
}
@end

@implementation TuneSessionManagerTests

- (void)setUp {
    [super setUp];
    
    mockApplication = OCMClassMock([UIApplication class]);
    OCMStub(ClassMethod([mockApplication sharedApplication])).andReturn(mockApplication);
    
    sessionManager = [[TuneSessionManager alloc] initWithTuneManager:[TuneManager currentManager]];
    [sessionManager registerSkyhooks];
}

- (void)tearDown {
    [mockApplication stopMocking];
    
    [super tearDown];
}

# pragma mark - Analytics File Mgmt

- (void)testSessionStart {
    XCTAssertNil([sessionManager sessionId]);
    XCTAssertNil([sessionManager sessionStartTime]);
    XCTAssertFalse([sessionManager sessionStarted]);
    
    OCMStub([mockApplication applicationState]).andReturn(UIApplicationStateActive);
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification object:self];
    
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"This test relies on side effects"];

    // The data this test is checking for is on the main queue, we need to give it a chance to run before we check.
    dispatch_async(dispatch_get_main_queue(), ^{
        XCTAssertNotNil([sessionManager sessionId]);
        XCTAssertNotNil([sessionManager sessionStartTime]);
        XCTAssertTrue([sessionManager sessionStarted]);
        XCTAssertTrue([sessionManager timeSinceSessionStart] > 0);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1.0 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)testSessionDidntActuallyStart {
    XCTAssertNil([sessionManager sessionId]);
    XCTAssertNil([sessionManager sessionStartTime]);
    XCTAssertFalse([sessionManager sessionStarted]);
    
    OCMStub([mockApplication applicationState]).andReturn(UIApplicationStateInactive);
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification object:self];
    
    XCTAssertNil([sessionManager sessionId]);
    XCTAssertNil([sessionManager sessionStartTime]);
    XCTAssertTrue([sessionManager timeSinceSessionStart] == 0);
    XCTAssertFalse([sessionManager sessionStarted]);
}

- (void)testSessionEnded {
    XCTAssertNil([sessionManager sessionId]);
    XCTAssertNil([sessionManager sessionStartTime]);
    XCTAssertFalse([sessionManager sessionStarted]);
    
    OCMStub([mockApplication applicationState]).andReturn(UIApplicationStateActive);
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification object:self];
    
    id mockApplicationStub2;
    mockApplicationStub2 = OCMClassMock([UIApplication class]);
    OCMStub(ClassMethod([mockApplicationStub2 sharedApplication])).andReturn(mockApplicationStub2);
    
    OCMStub([mockApplicationStub2 applicationState]).andReturn(UIApplicationStateBackground);
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidEnterBackgroundNotification object:self];
    
    XCTAssertNil([sessionManager sessionId]);
    XCTAssertNil([sessionManager sessionStartTime]);
    XCTAssertTrue([sessionManager timeSinceSessionStart] == 0);
    XCTAssertFalse([sessionManager sessionStarted]);
    
    [mockApplicationStub2 stopMocking];
}

@end
