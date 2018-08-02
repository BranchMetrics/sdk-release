//
//  TuneQueueTests.m
//  Tune
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Tune+Testing.h"
#import "TuneEvent+Internal.h"
#import "TuneEventQueue+Testing.h"
#import "TuneKeyStrings.h"
#import "TuneLog.h"
#import "TuneNetworkUtils.h"
#import "TuneReachability.h"
#import "TuneTestParams.h"
#import "TuneTestsHelper.h"
#import "TuneTracker.h"
#import "TuneUtils.h"
#import "TuneSkyhookCenter+Testing.h"

#import "TuneXCTestCase.h"

#import <OCMock/OCMock.h>

@interface TuneTracker()
+ (NSTimeInterval)sessionQueuingDelay;
@end

static BOOL forcedNetworkStatus;

@interface TuneQueueTests : TuneXCTestCase <TuneDelegate> {
    TuneEventQueue *eventQueue;
    
    TuneTestParams *params;
    TuneTestParams *params2;
    id classMockTuneNetworkUtils;
}
@end

@implementation TuneQueueTests

- (void)setUp {
    [super setUp];
    
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId];
    [Tune setDelegate:self];
    
    eventQueue = [TuneEventQueue sharedQueue];
    emptyRequestQueue();
    params = [TuneTestParams new];
    
    forcedNetworkStatus = YES;
    classMockTuneNetworkUtils = OCMClassMock([TuneNetworkUtils class]);
    OCMStub(ClassMethod([classMockTuneNetworkUtils isNetworkReachable])).andDo(^(NSInvocation *invocation) {
        [invocation setReturnValue:&forcedNetworkStatus];
    });
}

- (void)tearDown {
    TuneLog.shared.verbose = NO;
    TuneLog.shared.logBlock = nil;
    
    [classMockTuneNetworkUtils stopMocking];
    
    // drain the event queue
    emptyRequestQueue();
    waitForQueuesToFinish();
    
    [[TuneEventQueue sharedQueue] setForceNetworkError:NO code:0];
    
    [super tearDown];
}

- (void)checkAndClearExpectedQueueSize:(NSInteger)queueSize {
    NSLog(@"checkAndClearExpectedQueueSize: cur queue size = %d", (unsigned int)[[TuneEventQueue sharedQueue] queueSize]);
    
    NSUInteger size = [[TuneEventQueue sharedQueue] queueSize];
    XCTAssertEqual(size, queueSize, @"expected %d queued requests, found %d", (int)queueSize, (unsigned int)size);
    
    emptyRequestQueue();
    
    NSUInteger count = 0;
    size = [[TuneEventQueue sharedQueue] queueSize];
    XCTAssertEqual(size, count, @"expected %d queued requests, found %d", (unsigned int)count, (unsigned int)size);
}

- (NSUInteger)countOccurrencesOfSubstring:(NSString *)searchString inString:(NSString *)mainString {
    NSUInteger count = 0, length = [mainString length];
    NSRange range = NSMakeRange(0, length);
    
    while(range.location != NSNotFound)
    {
        range = [mainString rangeOfString:searchString options:0 range:range];
        
        if(range.location != NSNotFound)
        {
            range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
            count++;
        }
    }
    
    return count;
}


#pragma mark - Automatic queueing

- (void)testOfflineFailureQueued {
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        // the only message we should get is the Event being queued.  It should not go to network.
        XCTAssert([message containsString:@"EVENT QUEUE"]);
    };

    forcedNetworkStatus = NO;
    XCTAssertFalse([TuneNetworkUtils isNetworkReachable], @"connection status should be not reachable");
    [Tune measureSession];

    BOOL finished;
    waitFor1([TuneTracker sessionQueuingDelay] + 0.1, &finished);
    XCTAssertFalse([TuneNetworkUtils isNetworkReachable], @"connection status should be not reachable");
    [self checkAndClearExpectedQueueSize:1];
}

- (void)testOfflineFailureQueuedRetried {
    __block int successCalls = 0;
    __block int queuedCalls = 0;
    
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        if ([message containsString:@"SUCCESS"]) {
            successCalls++;
        } else if ([message containsString:@"QUEUE"]) {
            queuedCalls++;
        }
    };
    
    [Tune setAllowDuplicateRequests:YES];
    forcedNetworkStatus = NO;
    [Tune measureEventName:@"registration"];

    BOOL finished = NO;
    waitFor1([TuneTracker sessionQueuingDelay] + 0.1, &finished);

    finished = NO;
    forcedNetworkStatus = YES;
    [[TuneSkyhookCenter defaultCenter] postSkyhook:kTuneReachabilityChangedNotification object:nil];
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished ); // wait for server response

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_RETRY_COUNT, [@0 stringValue] );
    [self checkAndClearExpectedQueueSize:0];

    XCTAssertEqual(successCalls, 1);
    XCTAssertEqual(queuedCalls, 1);
}

- (void)testEnqueue2 {
    forcedNetworkStatus = NO;
    [Tune measureSession];
    
    BOOL finished = NO;
    waitFor1([TuneTracker sessionQueuingDelay] + 1, &finished);
    [Tune measureEventName:@"yourMomEvent"];
    waitFor(1);
    [self checkAndClearExpectedQueueSize:2];
}

- (void)testEnqueue2Retried {
    [Tune setAllowDuplicateRequests:YES];

    forcedNetworkStatus = NO;
    [Tune measureSession];
    
    BOOL finished = NO;
    waitFor1([TuneTracker sessionQueuingDelay] + 1, &finished);

    finished = NO;
    [Tune measureEventName:@"yourMomEvent"];
    waitFor( 1 );
    
    NSUInteger size = [[TuneEventQueue sharedQueue] queueSize];
    XCTAssertEqual(size, 2, @"expected 2 queued requests" );
    forcedNetworkStatus = YES;

//    [[TuneSkyhookCenter defaultCenter] postSkyhook:kTuneReachabilityChangedNotification object:nil];
//    waitFor( 5. );
//    XCTAssertFalse( [callFailed boolValue], @"dequeuing call should not have failed" );
//    XCTAssertTrue( [callSuccess boolValue], @"dequeuing call should have succeeded" );
//    [self checkAndClearExpectedQueueSize:0];

    [[TuneSkyhookCenter defaultCenter] postSkyhook:kTuneReachabilityChangedNotification object:nil];

    // wait for session event
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    finished = NO;
    // wait for conversion event
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    [self checkAndClearExpectedQueueSize:0];
    [Tune setAllowDuplicateRequests:NO];
}

- (void)testEnqueue2RetriedOrder {
    __block int successCalls = 0;
    
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        if ([message containsString:@"SUCCESS"]) {
            successCalls++;
        }
    };
    
    [Tune setAllowDuplicateRequests:YES];
#if !TARGET_OS_TV // NOTE: temporarily disabled; since tvOS debugMode is not supported as of now, the server response does not contain "site_event_name" param
    forcedNetworkStatus = NO;
    [Tune measureEventName:@"event1"];
    [Tune measureEventName:@"event2"];
    waitFor( 1. );

    NSUInteger size = [[TuneEventQueue sharedQueue] queueSize];
    XCTAssertEqual(size, 2, @"expected 2 queued requests" );

    forcedNetworkStatus = YES;
    [[TuneSkyhookCenter defaultCenter] postSkyhook:kTuneReachabilityChangedNotification object:nil];
    // wait for event1
    BOOL finished = NO;
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION + TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );

    // wait for event2
    finished = NO;
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION + TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    [self checkAndClearExpectedQueueSize:0];
    XCTAssertEqual(successCalls, 2, @"both calls should have succeeded");
#endif
}

#pragma mark - Tune delegate

- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData {
    TuneTestParams *p = params;
    if( params2 && ![p isEmpty] )
        p = params2;
    
    XCTAssertTrue( [p extractParamsFromQueryString:trackingUrl], @"couldn't extract from tracking URL %@", trackingUrl );
    if( postData ) {
        XCTAssertTrue( [params extractParamsFromJson:postData], @"couldn't extract POST JSON: %@", postData );
        XCTAssertTrue( [p extractParamsFromJson:postData], @"couldn't extract POST JSON %@", postData );
    }
}

@end
