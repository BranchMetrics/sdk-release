//
//  MATHTTPErrorTests.m
//  MobileAppTracker
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MATTests.h"
#import "../MobileAppTracker/Common/MATTracker.h"

@interface MATHTTPErrorTests : XCTestCase
{
    MATTracker *tracker;
    MATEventQueue *eventQueue;
}
@end

@implementation MATHTTPErrorTests

- (void)setUp
{
    [super setUp];

    tracker = [MATTracker new];
    
    eventQueue = [MATEventQueue sharedInstance];
}

- (void)tearDown
{
    emptyRequestQueue();

    [super tearDown];
}

- (void)checkAndClearExpectedQueueSize:(NSInteger)queueSize
{
    XCTAssertTrue( [MATEventQueue queueSize] == queueSize, @"expected %d queued requests, found %d", (int)queueSize, (unsigned int)[MATEventQueue queueSize] );
    
    emptyRequestQueue();
    
    NSUInteger count = 0;
    XCTAssertTrue( [MATEventQueue queueSize] == count, @"expected %d queued requests, found %d", (unsigned int)count, (unsigned int)[MATEventQueue queueSize] );
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
    [MATEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=400&statusCode%5Bmessage%5D=HTTP/1.0%20400%20Bad%20Request&headers%5BX-MAT-Responder%5D=someserver"
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
    [MATEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=400&statusCode%5Bmessage%5D=HTTP/1.0%20400%20Bad%20Request"
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
    [MATEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error"
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
    [MATEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error"
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    waitFor( 10. );

    XCTAssertEqual( [MATEventQueue queueSize], 1, @"expected %d queued requests, found %d",
                   1, (unsigned int)[MATEventQueue queueSize] );

    NSMutableArray *requests = [MATEventQueue events];

    XCTAssertEqual( [requests count], 1, @"expected to pop %d queue items, found %d", 1, (int)[requests count] );
    
    NSString *strUrl = requests[0][@"url"];
    NSString *searchString = [NSString stringWithFormat:@"&%@=1", MAT_KEY_RETRY_COUNT];
    
    XCTAssertTrue( [strUrl rangeOfString:searchString].location != NSNotFound, @"should have incremented retry count" );
}


- (void)test500RetryOrder
{
    [tracker setDebugMode:YES];
    [MATEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error"
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    [MATEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error&headers%5Bdummyheader%5D=yourmom"
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    waitFor( 10. );
    
    XCTAssertEqual( [MATEventQueue queueSize], 2, @"expected %d queued requests, found %d",
                   2, (unsigned int)[MATEventQueue queueSize] );
    
    NSMutableArray *requests = [MATEventQueue events];
    
    XCTAssertEqual( [MATEventQueue queueSize], 2, @"expected to pop %d queue items, found %d", 2, (int)[MATEventQueue queueSize] );
    XCTAssertTrue( [requests[0][@"url"] rangeOfString:@"yourmom"].location == NSNotFound, @"first call in queue should not have yourmom" );
    XCTAssertTrue( [requests[1][@"url"] rangeOfString:@"yourmom"].location != NSNotFound, @"second call in queue should have yourmom" );
}


- (void)test500RetryTwice
{
    [tracker setDebugMode:YES];
    [MATEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Bad%"
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    waitFor( 10. );
    
    int expected = (unsigned int)[MATEventQueue queueSize];
    int actual = 1;

    XCTAssertEqual( expected, actual, @"expected %d queued requests, found %d", expected, actual );
    
    [MATEventQueue dumpQueue];
    waitFor( 10. );
    
    [self checkAndClearExpectedQueueSize:1];
}

@end
