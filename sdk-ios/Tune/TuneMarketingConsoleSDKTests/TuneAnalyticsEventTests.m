//
//  TuneAnalyticsEventTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/20/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Tune+Testing.h"
#import "TuneManager.h"
#import "TuneSessionManager.h"
#import "TuneAnalyticsEvent.h"
#import "TuneUserProfile.h"
#import "TuneSkyhookCenter.h"
#import "TuneAnalyticsSubmitter.h"

@interface TuneAnalyticsEventTests : XCTestCase
{
    id mockApplication;
    
    TuneSessionManager *sessionManager;
    TuneUserProfile *userProfile;
}
@end

@implementation TuneAnalyticsEventTests

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
    
    mockApplication = OCMClassMock([UIApplication class]);
    OCMStub(ClassMethod([mockApplication sharedApplication])).andReturn(mockApplication);
    
    sessionManager = [[TuneSessionManager alloc] initWithTuneManager:[TuneManager currentManager]];
    [sessionManager registerSkyhooks];
    
    userProfile = [[TuneUserProfile alloc] initWithTuneManager:[TuneManager currentManager]];
    [userProfile registerSkyhooks];
    userProfile.advertiserId = @"advertiserId";
    userProfile.tuneId = @"something";
    userProfile.appleAdvertisingIdentifier = @"idfa";
    
    [[TuneManager currentManager] setUserProfile:userProfile];
}

- (void)tearDown {
    [mockApplication stopMocking];
    
    [super tearDown];
}

- (void)testTimeWithinSession {
    // Start the session clock.
    OCMStub([mockApplication applicationState]).andReturn(UIApplicationStateActive);
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification object:self];
    
    TuneAnalyticsEvent *testEvent = [[TuneAnalyticsEvent alloc] initCustomEventWithAction:@"Sample Action"];
    
    XCTAssertTrue([testEvent sessionTime] > 0);
    XCTAssertTrue([[testEvent timestamp] compare:[NSDate date]] == -1L);
}

- (void)testBasicMessage {
    // Start the session clock.
    OCMStub([mockApplication applicationState]).andReturn(UIApplicationStateActive);
    [[TuneSkyhookCenter defaultCenter] postSkyhook:UIApplicationDidBecomeActiveNotification object:self];
    
    TuneAnalyticsEvent *testEvent = [[TuneAnalyticsEvent alloc] initCustomEventWithAction:@"Sample Action"];
    
    XCTAssertTrue([testEvent.submitter.ifa isEqualToString:@"idfa"], @"Actually: %@", testEvent.submitter.ifa);
    XCTAssertTrue([testEvent.submitter.sessionId isEqualToString:[[TuneManager currentManager].userProfile sessionId]]);
    XCTAssertTrue([testEvent.submitter.deviceId isEqualToString:[[TuneManager currentManager].userProfile deviceId]]);
    
    XCTAssertTrue([testEvent.appId isEqualToString:[[TuneManager currentManager].userProfile hashedAppId]]);
}

@end
