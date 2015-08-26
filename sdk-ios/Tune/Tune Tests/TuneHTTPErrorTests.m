//
//  TuneHTTPErrorTests.m
//  Tune
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneTestsHelper.h"
#import "../Tune/Common/TuneEventQueue.h"
#import "../Tune/Common/TuneKeyStrings.h"
#import "../Tune/Common/TuneTracker.h"

@interface TuneHTTPErrorTests : XCTestCase
{
    TuneTracker *tracker;
    TuneEventQueue *eventQueue;
}
@end

@implementation TuneHTTPErrorTests

- (void)setUp
{
    [super setUp];

    tracker = [TuneTracker new];
    
    eventQueue = [TuneEventQueue sharedInstance];
}

- (void)tearDown
{
    emptyRequestQueue();

    [super tearDown];
}

- (void)checkAndClearExpectedQueueSize:(NSInteger)queueSize
{
    XCTAssertTrue( [TuneEventQueue queueSize] == queueSize, @"expected %d queued requests, found %d", (int)queueSize, (unsigned int)[TuneEventQueue queueSize] );
    
    emptyRequestQueue();
    
    NSUInteger count = 0;
    XCTAssertTrue( [TuneEventQueue queueSize] == count, @"expected %d queued requests, found %d", (unsigned int)count, (unsigned int)[TuneEventQueue queueSize] );
}

/*
 receive HTTP 400, don't retry (queue is empty)
 receive HTTP 500, failed request should be at the top of the queue (try with another request in the queue behind it)
 */

- (void)test00000QueueFlush // run this test first to clear out queue and pending requests
{
    emptyRequestQueue();
    
    waitFor( 30. );
}


- (void)test400DontRetry
{
    networkOnline();
    
    [tracker setDebugMode:YES];
    [TuneEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=400&statusCode%5Bmessage%5D=HTTP/1.0%20400%20Bad%20Request&headers%5BX-MAT-Responder%5D=someserver"
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    waitFor( 10. );
    
    [self checkAndClearExpectedQueueSize:0];
}

/* engine automatically returns headers now, I think
- (void)test400NoHeaderRetry
{
    [tracker setDebugMode:YES];
    [TuneEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=400&statusCode%5Bmessage%5D=HTTP/1.0%20400%20Bad%20Request"
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    waitFor( 10. );
    
    [self checkAndClearExpectedQueueSize:1];
}
 */

- (void)test500Retry
{
    networkOnline();
    
    [tracker setDebugMode:YES];
    [TuneEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error"
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    waitFor( 10. );
    
    [self checkAndClearExpectedQueueSize:1];
}

- (void)test500RetryCount
{
    networkOnline();
    
    [tracker setDebugMode:YES];
    [TuneEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error"
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    waitFor( 10. );

    XCTAssertEqual( [TuneEventQueue queueSize], 1, @"expected %d queued requests, found %d",
                   1, (unsigned int)[TuneEventQueue queueSize] );

    NSMutableArray *requests = [TuneEventQueue events];

    XCTAssertEqual( [requests count], 1, @"expected to pop %d queue items, found %d", 1, (int)[requests count] );
    
    NSString *strUrl = requests[0][@"url"];
    NSString *searchString = [NSString stringWithFormat:@"&%@=1", TUNE_KEY_RETRY_COUNT];
    
    XCTAssertTrue( [strUrl rangeOfString:searchString].location != NSNotFound, @"should have incremented retry count" );
}

- (void)test500RetryOrder
{
    [tracker setDebugMode:YES];
    [TuneEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error"
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    [TuneEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error&headers%5Bdummyheader%5D=yourmom"
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    waitFor( 10. );
    
    XCTAssertEqual( [TuneEventQueue queueSize], 2, @"expected %d queued requests, found %d",
                   2, (unsigned int)[TuneEventQueue queueSize] );
    
    NSMutableArray *requests = [TuneEventQueue events];
    
    XCTAssertEqual( [TuneEventQueue queueSize], 2, @"expected to pop %d queue items, found %d", 2, (int)[TuneEventQueue queueSize] );
    XCTAssertTrue( [requests[0][@"url"] rangeOfString:@"yourmom"].location == NSNotFound, @"first call in queue should not have yourmom" );
    XCTAssertTrue( [requests[1][@"url"] rangeOfString:@"yourmom"].location != NSNotFound, @"second call in queue should have yourmom" );
}

- (void)test500RetryTwice
{
    [tracker setDebugMode:YES];
    [TuneEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Bad%"
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    waitFor( 10. );
    
    int expected = (unsigned int)[TuneEventQueue queueSize];
    int actual = 1;

    XCTAssertEqual( expected, actual, @"expected %d queued requests, found %d", expected, actual );
    
    [TuneEventQueue dumpQueue];
    waitFor( 10. );
    
    [self checkAndClearExpectedQueueSize:1];
}

@end
