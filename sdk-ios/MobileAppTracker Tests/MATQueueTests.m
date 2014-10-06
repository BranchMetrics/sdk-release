//
//  MATQueueTests.m
//  MobileAppTracker
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MobileAppTracker/MobileAppTracker.h>
#import "MATTests.h"
#import "MATTestParams.h"
#import "../MobileAppTracker/Common/MATEventQueue.h"
#import "../MobileAppTracker/Common/MATReachability.h"
#import "../MobileAppTracker/Common/MATRequestsQueue.h"
#import "../MobileAppTracker/Common/MATSettings.h"
#import "../MobileAppTracker/Common/MATTracker.h"

@interface MATQueueTests : XCTestCase <MobileAppTrackerDelegate>
{
    BOOL callSuccess;
    BOOL callFailed;
    
    NSMutableArray *successMessages;
    
    MATEventQueue *eventQueue;
    
    MATTestParams *params;
    MATTestParams *params2;
}
@end

@implementation MATQueueTests

- (void)setUp
{
    [super setUp];

    [MobileAppTracker initializeWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    [MobileAppTracker setDelegate:self];
    
    [MobileAppTracker setDebugMode:YES];
    [MobileAppTracker setAllowDuplicateRequests:YES];
    
    eventQueue = [MATEventQueue sharedInstance];
    
    emptyRequestQueue();
    
    successMessages = [NSMutableArray array];
    
    params = [MATTestParams new];
}

- (void)tearDown
{
    networkOnline();

    // drain the event queue
    emptyRequestQueue();
    
    [super tearDown];
}

- (void)checkAndClearExpectedQueueSize:(NSInteger)queueSize
{
    NSLog(@"checkAndClearExpectedQueueSize: cur queue size = %d", (unsigned int)[MATEventQueue queueSize]);
    
    XCTAssertTrue( [MATEventQueue queueSize] == queueSize, @"expected %d queued requests, found %d", (int)queueSize, (unsigned int)[MATEventQueue queueSize] );
    
    emptyRequestQueue();
    
    NSUInteger count = 0;
    XCTAssertTrue( [MATEventQueue queueSize] == count, @"expected %d queued requests, found %d", (unsigned int)count, (unsigned int)[MATEventQueue queueSize] );
}


#pragma mark - Automatic queueing

- (void)testAAAAAQueueFlush // run this test first to clear out queue and pending requests
{
    emptyRequestQueue();
}

- (void)testOfflineFailureQueued
{
    networkOffline();
    XCTAssertTrue( ![MATEventQueue networkReachability], @"connection status should be not reachable" );
    [MobileAppTracker measureSession];
    
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( ![MATEventQueue networkReachability], @"connection status should be not reachable" );
    
    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );
    XCTAssertFalse( callSuccess, @"offline call should not have received a success notification" );
    [self checkAndClearExpectedQueueSize:1];
}

- (void)testOfflineFailureQueuedRetried
{
    networkOffline();
    [MobileAppTracker measureAction:@"registration"];
    
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMATReachabilityChangedNotification object:nil];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION ); // wait for server response
    XCTAssertFalse( callFailed, @"dequeuing call should have succeeded" );
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_RETRY_COUNT, [@0 stringValue] );
    [self checkAndClearExpectedQueueSize:0];
    
    XCTAssertTrue( [successMessages count] == 1, @"call should have succeeded, actual value = %d", (unsigned int)[successMessages count] );
}

- (void)testEnqueue2
{
    networkOffline();
    [MobileAppTracker measureSession];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );

    [MobileAppTracker measureAction:@"yourMomEvent"];
    waitFor( 0.1 );
    XCTAssertFalse( callFailed, @"second offline call should not have received a failure notification" );
    [self checkAndClearExpectedQueueSize:2];
}

- (void)testEnqueue2Retried
{
    [MobileAppTracker setDebugMode:NO];
    
    networkOffline();
    [MobileAppTracker measureSession];
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );

    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );
    
    [MobileAppTracker measureAction:@"yourMomEvent"];
    waitFor( 0.1 );
    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );

    XCTAssertTrue( [MATEventQueue queueSize] == 2, @"expected 2 queued requests" );
     [[NSNotificationCenter defaultCenter] postNotificationName:kMATReachabilityChangedNotification object:nil];
    waitFor( 5. );
    XCTAssertFalse( callFailed, @"dequeuing call should not have failed" );
    XCTAssertTrue( callSuccess, @"dequeuing call should have succeeded" );
    [self checkAndClearExpectedQueueSize:0];
    waitFor( 10. );
}

- (void)testEnqueue2RetriedOrder
{
    [MobileAppTracker setDebugMode:YES];

    networkOffline();
    [MobileAppTracker measureAction:@"event1"];
    [MobileAppTracker measureAction:@"event2"];
    waitFor( 1. );
    
    XCTAssertTrue( [MATEventQueue queueSize] == 2, @"expected 2 queued requests" );
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMATReachabilityChangedNotification object:nil];
    waitFor( MAT_TEST_NETWORK_REQUEST_DURATION + MAT_TEST_NETWORK_REQUEST_DURATION );
    
    XCTAssertTrue( callSuccess, @"dequeuing call should have succeeded" );
    [self checkAndClearExpectedQueueSize:0];
    XCTAssertTrue( [successMessages count] == 2, @"both calls should have succeeded, but %lu did", (unsigned long)[successMessages count] );

    for( NSInteger i = 0; i < [successMessages count]; i++ ) {
        NSData *data = successMessages[i];
        NSDictionary *jso = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *expectedEvent = [NSString stringWithFormat:@"event%d", (int)i + 1];
        XCTAssertTrue( [jso[@"get"][MAT_KEY_SITE_EVENT_NAME] isEqualToString:expectedEvent],
                       @"expected event name '%@', got '%@'", expectedEvent, jso[@"get"][@"site_event_name"] );
    }
}

- (void)testSessionQueue
{
    networkOnline();
    
    [MobileAppTracker setDebugMode:YES];
    [MobileAppTracker measureSession];
    waitFor( 1. );
    XCTAssertFalse( callFailed, @"session call should not have been attempted after 1 sec" );
    XCTAssertFalse( callSuccess, @"session call should not have been attempted after 1 sec" );
    XCTAssertTrue( [MATEventQueue queueSize] == 1, @"expected 1 queued request, but found %lu", (unsigned long)[MATEventQueue queueSize] );
    
    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION);
    XCTAssertFalse( callFailed, @"session call should not have failed" );
    XCTAssertTrue( callSuccess, @"session call should have succeeded" );
    XCTAssertTrue( [successMessages count] == 1, @"call should have succeeded" );
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( MAT_KEY_ACTION, MAT_EVENT_SESSION );
    [self checkAndClearExpectedQueueSize:0];
}

- (void)testSessionQueueOrder
{
    networkOnline();
    
    params2 = [MATTestParams new];

    [MobileAppTracker setDebugMode:YES];
    [MobileAppTracker measureSession];
    [MobileAppTracker measureAction:@"event name"];
    waitFor( 1. );

    XCTAssertFalse( callFailed, @"no calls should have been attempted after 1 sec" );
    XCTAssertFalse( callSuccess, @"no calls should have been attempted after 1 sec" );
    XCTAssertTrue( [MATEventQueue queueSize] == 2, @"expected 2 queued requests, but found %lu", (unsigned long)[MATEventQueue queueSize] );

    waitFor( MAT_SESSION_QUEUING_DELAY + MAT_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertFalse( callFailed, @"session call should not have failed" );
    XCTAssertTrue( callSuccess, @"session call should have succeeded" );
    [self checkAndClearExpectedQueueSize:0];

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertTrue( [params2 checkDefaultValues], @"default value check failed: %@", params2 );
    XCTAssertTrue( [params checkKey:MAT_KEY_ACTION isEqualToValue:MAT_EVENT_SESSION], @"first call should be \"session\"" );
    XCTAssertTrue( [params2 checkKey:MAT_KEY_ACTION isEqualToValue:MAT_EVENT_CONVERSION], @"second call should be \"conversion\"" );
}


#pragma mark - Requests queue behaviors

- (void)testRequestsQueueSerialize
{
    static NSString* const testUrl = @"fakeUrl";
    static NSString* const testPostData = @"someTestJson";
    NSDate *testDate = [NSDate date];
    NSDictionary *item = @{MAT_KEY_URL: testUrl, MAT_KEY_JSON: testPostData, MAT_KEY_RUN_DATE: testDate};
    
    MATRequestsQueue *queue = [MATRequestsQueue new];
    [queue push:item];
    [queue save];

    NSDictionary *readItem = [queue pop];
    XCTAssertTrue( [readItem count] == [item count], @"saved %lud keys, recovered %lud", (unsigned long)[item count], (unsigned long)[readItem count] );
    for( NSInteger i = 0; i < MIN( [item count], [readItem count] ); i++ ) {
        NSString *readKey = [readItem allKeys][i];
        NSString *key = [item allKeys][i];
        XCTAssertTrue( [key isEqualToString:readKey], @"saved key %@, recovered %@", key, readKey );

        if( [key isEqualToString:readKey] ) {
            id readValue = readItem[readKey];
            id value = item[key];
            XCTAssertTrue( [readValue class] == [value class], @"for key %@, saved item of class %@, recovered class %@", key, [value class], [readValue class] );

            if( [value class] == [readValue class] ) {
                XCTAssertTrue( [value isEqual:readValue], "for key %@, saved %@, recovered %@", key, value, readValue );
            }
        }
    }
}


#pragma mark - MAT delegate

- (void)mobileAppTrackerDidSucceedWithData:(NSData *)data
{
    [successMessages addObject:data];
//    NSLog( @"test received success with %@\n", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] );
    callSuccess = YES;
    callFailed = NO;
}

- (void)mobileAppTrackerDidFailWithError:(NSError *)error
{
//    NSLog( @"test received failure with %@\n", error );
    callFailed = YES;
    callSuccess = NO;
}


#pragma mark - MAT delegate

- (void)_matSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    MATTestParams *p = params;
    if( params2 && ![p isEmpty] )
        p = params2;
    
    XCTAssertTrue( [p extractParamsString:trackingUrl], @"couldn't extract from tracking URL %@", trackingUrl );
    if( postData ) {
        XCTAssertTrue( [params extractParamsJSON:postData], @"couldn't extract POST JSON: %@", postData );
        XCTAssertTrue( [p extractParamsJSON:postData], @"couldn't extract POST JSON %@", postData );
    }
}

@end
