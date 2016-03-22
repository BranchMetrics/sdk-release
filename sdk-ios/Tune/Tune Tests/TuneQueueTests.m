//
//  TuneQueueTests.m
//  Tune
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneTestsHelper.h"
#import "TuneTestParams.h"
#import "../Tune/Tune.h"
#import "../Tune/TuneEvent.h"
#import "../Tune/Common/TuneEventQueue.h"
#import "../Tune/Common/TuneKeyStrings.h"
#import "../Tune/Common/TuneReachability.h"
#import "../Tune/Common/TuneRequestsQueue.h"
#import "../Tune/Common/TuneSettings.h"
#import "../Tune/Common/TuneTracker.h"
#import "../Tune/Common/TuneUtils.h"

@interface TuneQueueTests : XCTestCase <TuneDelegate>
{
    BOOL callSuccess;
    BOOL callFailed;
    
    NSMutableArray *successMessages;
    
    TuneEventQueue *eventQueue;
    
    TuneTestParams *params;
    TuneTestParams *params2;
    
    BOOL finished;
}
@end

@implementation TuneQueueTests

- (void)setUp
{
    [super setUp];

    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey];
    [Tune setDelegate:self];
    
    [Tune setDebugMode:YES];
    [Tune setAllowDuplicateRequests:YES];
    
    finished = NO;
    
    eventQueue = [TuneEventQueue sharedInstance];
    
    emptyRequestQueue();
    
    successMessages = [NSMutableArray array];
    
    params = [TuneTestParams new];
}

- (void)tearDown
{
    networkOnline();
    
    finished = NO;
    
    // drain the event queue
    emptyRequestQueue();
    
    [TuneEventQueue setForceNetworkError:NO code:0];
    
    [super tearDown];
}

- (void)checkAndClearExpectedQueueSize:(NSInteger)queueSize
{
    NSLog(@"checkAndClearExpectedQueueSize: cur queue size = %d", (unsigned int)[TuneEventQueue queueSize]);
    
    XCTAssertTrue( [TuneEventQueue queueSize] == queueSize, @"expected %d queued requests, found %d", (int)queueSize, (unsigned int)[TuneEventQueue queueSize] );
    
    emptyRequestQueue();
    
    NSUInteger count = 0;
    XCTAssertTrue( [TuneEventQueue queueSize] == count, @"expected %d queued requests, found %d", (unsigned int)count, (unsigned int)[TuneEventQueue queueSize] );
}

- (NSUInteger)countOccurrencesOfSubstring:(NSString *)searchString inString:(NSString *)mainString
{
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

- (void)testAAAAAQueueFlush // run this test first to clear out queue and pending requests
{
    emptyRequestQueue();
}

- (void)testOfflineFailureQueued
{
    networkOffline();
    XCTAssertFalse( [TuneUtils isNetworkReachable], @"connection status should be not reachable" );
    [Tune measureSession];
    
    waitFor1( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    XCTAssertFalse( [TuneUtils isNetworkReachable], @"connection status should be not reachable" );
    
    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );
    XCTAssertFalse( callSuccess, @"offline call should not have received a success notification" );
    [self checkAndClearExpectedQueueSize:1];
}

- (void)testOfflineFailureQueuedRetried
{
    networkOffline();
    [Tune measureEventName:@"registration"];
    
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );
    
    finished = NO;
    networkOnline();
    [[NSNotificationCenter defaultCenter] postNotificationName:kTuneReachabilityChangedNotification object:nil];
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished ); // wait for server response
    XCTAssertFalse( callFailed, @"dequeuing call should have succeeded" );
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_RETRY_COUNT, [@0 stringValue] );
    [self checkAndClearExpectedQueueSize:0];
    
    XCTAssertTrue( [successMessages count] == 1, @"call should have succeeded, actual value = %d", (unsigned int)[successMessages count] );
}

- (void)testEnqueue2
{
    networkOffline();
    [Tune measureSession];
    waitFor1( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );
    
    [Tune measureEventName:@"yourMomEvent"];
    waitFor( 0.1 );
    XCTAssertFalse( callFailed, @"second offline call should not have received a failure notification" );
    [self checkAndClearExpectedQueueSize:2];
}

- (void)testEnqueue2Retried
{
    [Tune setDebugMode:NO];
    
    networkOffline();
    [Tune measureSession];
    waitFor1( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );

    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );

    finished = NO;
    [Tune measureEventName:@"yourMomEvent"];
    waitFor( 0.1 );
    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );

    XCTAssertTrue( [TuneEventQueue queueSize] == 2, @"expected 2 queued requests" );
    networkOnline();
    [[NSNotificationCenter defaultCenter] postNotificationName:kTuneReachabilityChangedNotification object:nil];
    
    // wait for session event
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    XCTAssertFalse( callFailed, @"dequeuing call should not have failed" );
    XCTAssertTrue( callSuccess, @"dequeuing call should have succeeded" );
    
    finished = NO;
    // wait for conversion event
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    XCTAssertFalse( callFailed, @"dequeuing call should not have failed" );
    XCTAssertTrue( callSuccess, @"dequeuing call should have succeeded" );
    [self checkAndClearExpectedQueueSize:0];
    //waitFor( 10. );
}

- (void)testEnqueue2RetriedOrder
{
    [Tune setDebugMode:YES];

    networkOffline();
    [Tune measureEventName:@"event1"];
    [Tune measureEventName:@"event2"];
    waitFor( 1. );
    
    XCTAssertTrue( [TuneEventQueue queueSize] == 2, @"expected 2 queued requests" );
    
    networkOnline();
    [[NSNotificationCenter defaultCenter] postNotificationName:kTuneReachabilityChangedNotification object:nil];
    // wait for event1
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION + TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    // wait for event2
    finished = NO;
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION + TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    XCTAssertTrue( callSuccess, @"dequeuing call should have succeeded" );
    [self checkAndClearExpectedQueueSize:0];
    XCTAssertTrue( [successMessages count] == 2, @"both calls should have succeeded, but %lu did", (unsigned long)[successMessages count] );

    for( NSInteger i = 0; i < [successMessages count]; i++ ) {
        NSData *data = successMessages[i];
        NSDictionary *jso = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *expectedEvent = [NSString stringWithFormat:@"event%d", (int)i + 1];
        XCTAssertTrue( [jso[@"get"][TUNE_KEY_SITE_EVENT_NAME] isEqualToString:expectedEvent],
                       @"expected event name '%@', got '%@'", expectedEvent, jso[@"get"][@"site_event_name"] );
    }
}

- (void)testSessionQueue
{
    networkOnline();
    
    [Tune setDebugMode:YES];
    [Tune measureSession];
    waitFor( 1. );
    XCTAssertFalse( callFailed, @"session call should not have been attempted after 1 sec" );
    XCTAssertFalse( callSuccess, @"session call should not have been attempted after 1 sec" );
    XCTAssertTrue( [TuneEventQueue queueSize] == 1, @"expected 1 queued request, but found %lu", (unsigned long)[TuneEventQueue queueSize] );
    
    waitFor1( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION, &finished);
    XCTAssertFalse( callFailed, @"session call should not have failed" );
    XCTAssertTrue( callSuccess, @"session call should have succeeded" );
    XCTAssertTrue( [successMessages count] == 1, @"call should have succeeded" );
    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    ASSERT_KEY_VALUE( TUNE_KEY_ACTION, TUNE_EVENT_SESSION );
    [self checkAndClearExpectedQueueSize:0];
}

- (void)testSessionQueueOrder
{
    networkOnline();
    
    params2 = [TuneTestParams new];

    [Tune setDebugMode:YES];
    
    [Tune measureSession];
    [Tune measureEventName:@"event name"];
    waitFor( 1. );

    XCTAssertFalse( callFailed, @"no calls should have been attempted after 1 sec" );
    XCTAssertFalse( callSuccess, @"no calls should have been attempted after 1 sec" );
    XCTAssertTrue( [TuneEventQueue queueSize] == 2, @"expected 2 queued requests, but found %lu", (unsigned long)[TuneEventQueue queueSize] );
    
    NSDate *startTime = [NSDate date];
    
    waitFor1( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    NSLog(@"time spent = %f", [[NSDate date] timeIntervalSinceDate:startTime]);
    
    finished = NO;
    waitFor1( TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    XCTAssertFalse( callFailed, @"session call should not have failed" );
    XCTAssertTrue( callSuccess, @"session call should have succeeded" );
    [self checkAndClearExpectedQueueSize:0];

    XCTAssertTrue( [params checkDefaultValues], @"default value check failed: %@", params );
    XCTAssertTrue( [params2 checkDefaultValues], @"default value check failed: %@", params2 );
    XCTAssertTrue( [params checkKey:TUNE_KEY_ACTION isEqualToValue:TUNE_EVENT_SESSION], @"first call should be \"session\"" );
    XCTAssertTrue( [params2 checkKey:TUNE_KEY_ACTION isEqualToValue:TUNE_EVENT_CONVERSION], @"second call should be \"conversion\"" );
}

- (void)testNoDuplicateParamsInRetriedRequest
{
    networkOnline();
    
    [TuneEventQueue setForceNetworkError:YES code:500];
    
    [Tune setDebugMode:YES];
    [Tune measureSession];
    
    waitFor1( 1., &finished );
    
    NSMutableArray *requests = [TuneEventQueue events];
    NSString *strUrl = requests[0][@"url"];
    
    NSString *searchString = [NSString stringWithFormat:@"&%@=%@", TUNE_KEY_RESPONSE_FORMAT, TUNE_KEY_JSON];
    
    NSUInteger count = [self countOccurrencesOfSubstring:searchString inString:strUrl];
    
    XCTAssertTrue( count == 1, @"duplicate param should not exist in original request url" );
    
    ////////////
    
    waitFor1( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    requests = [TuneEventQueue events];
    strUrl = requests[0][@"url"];
    searchString = [NSString stringWithFormat:@"&%@=%@", TUNE_KEY_RESPONSE_FORMAT, TUNE_KEY_JSON];
    
    count = [self countOccurrencesOfSubstring:searchString inString:strUrl];
    
    XCTAssertTrue( count == 1, @"duplicate params should not exist in retried request url" );
    
    ////////////
    
    NSInteger retry = 1;
    NSTimeInterval retryDelay = [TuneEventQueue retryDelayForAttempt:retry];
    
    waitFor( retryDelay + TUNE_TEST_NETWORK_REQUEST_DURATION);
    
    requests = [TuneEventQueue events];
    strUrl = requests[0][@"url"];
    searchString = [NSString stringWithFormat:@"&%@=%@", TUNE_KEY_RESPONSE_FORMAT, TUNE_KEY_JSON];
    
    count = [self countOccurrencesOfSubstring:searchString inString:strUrl];
    
    XCTAssertTrue( count == 1, @"duplicate params should not exist in retried request url" );
}

- (void)testRetryCount
{
    networkOnline();
    
    [TuneEventQueue setForceNetworkError:YES code:500];
    
    [Tune setDebugMode:YES];
    [Tune measureSession];
    
    waitFor( 1. );
    XCTAssertFalse( callFailed, @"session call should not have been attempted after 1 sec" );
    XCTAssertFalse( callSuccess, @"session call should not have been attempted after 1 sec" );
    XCTAssertTrue( [TuneEventQueue queueSize] == 1, @"expected 1 queued request, but found %lu", (unsigned long)[TuneEventQueue queueSize] );
    
    NSMutableArray *requests = [TuneEventQueue events];
    NSString *strUrl = requests[0][@"url"];
    NSString *searchString = [NSString stringWithFormat:@"&%@=0", TUNE_KEY_RETRY_COUNT];
    
    XCTAssertTrue( [strUrl rangeOfString:searchString].location != NSNotFound, @"should not have incremented retry count" );
    
    ////////////
    
    waitFor1( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    XCTAssertTrue( callFailed, @"session call should have failed" );
    XCTAssertFalse( callSuccess, @"session call should not have succeeded" );
    
    XCTAssertEqual( [TuneEventQueue queueSize], 1, @"expected %d queued requests, found %d", 1, (unsigned int)[TuneEventQueue queueSize] );
    
    requests = [TuneEventQueue events];
    
    XCTAssertEqual( [requests count], 1, @"expected to pop %d queue items, found %d", 1, (int)[requests count] );
    
    strUrl = requests[0][@"url"];
    searchString = [NSString stringWithFormat:@"&%@=1", TUNE_KEY_RETRY_COUNT];
    
    XCTAssertTrue( [strUrl rangeOfString:searchString].location != NSNotFound, @"should have incremented retry count" );
    
    ////////////
    
    finished = NO;
    NSInteger retry = 1;
    NSTimeInterval retryDelay = [TuneEventQueue retryDelayForAttempt:retry];
    
    waitFor1( retryDelay + TUNE_TEST_NETWORK_REQUEST_DURATION, &finished );
    
    requests = [TuneEventQueue events];
    
    XCTAssertEqual( [requests count], 1, @"expected to pop %d queue items, found %d", 1, (int)[requests count] );
    
    strUrl = requests[0][@"url"];
    searchString = [NSString stringWithFormat:@"&%@=2", TUNE_KEY_RETRY_COUNT];
    
    XCTAssertTrue( [strUrl rangeOfString:searchString].location != NSNotFound, @"should have incremented retry count" );
}

#pragma mark - Requests queue behaviors

- (void)testRequestsQueueSerialize
{
    static NSString* const testUrl = @"fakeUrl";
    static NSString* const testPostData = @"someTestJson";
    NSDate *testDate = [NSDate date];
    NSDictionary *item = @{TUNE_KEY_URL: testUrl, TUNE_KEY_JSON: testPostData, TUNE_KEY_RUN_DATE: testDate};
    
    TuneRequestsQueue *queue = [TuneRequestsQueue new];
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


#pragma mark - Tune delegate

- (void)tuneDidSucceedWithData:(NSData *)data
{
    [successMessages addObject:data];
    //NSLog( @"TuneQueueTests: test received success with %@\n", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] );
    callSuccess = YES;
    callFailed = NO;
    
    finished = YES;
}

- (void)tuneDidFailWithError:(NSError *)error
{
    //NSLog( @"TuneQueueTests: test received failure with %@\n", error );
    callFailed = YES;
    callSuccess = NO;
    
    finished = YES;
}


#pragma mark - Tune delegate

- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
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
