//
//  MATHTTPErrorTests.m
//  MobileAppTracker
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MATTests.h"
#import "MATTracker.h"

@interface MATConnectionManager (Privates)
- (void)dumpQueue;
- (void)stopQueueDump;
@end

@interface MATHTTPErrorTests : XCTestCase
{
    MATTracker *tracker;
    MATRequestsQueue *requestsQueue;
}
@end

@implementation MATHTTPErrorTests

- (void)setUp
{
    [super setUp];

    tracker = [MATTracker new];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    requestsQueue = [tracker.connectionManager performSelector:@selector(requestsQueue)];
#pragma clang diagnostic pop
}

- (void)tearDown
{
    while( [requestsQueue pop] );
    [tracker.connectionManager stopQueueDump];

    [super tearDown];
}


-(void) checkAndClearExpectedQueueSize:(NSInteger)queueSize
{
    XCTAssertTrue( requestsQueue.queuedRequestsCount == queueSize, @"expected %d queued requests, found %d",
                  (int)queueSize, (unsigned int)requestsQueue.queuedRequestsCount );
    
    NSMutableArray *requests = [NSMutableArray new];
    NSDictionary *request = nil;
    while( (request = [requestsQueue pop]) )
        [requests addObject:request];

    XCTAssertTrue( [requests count] == queueSize, @"expected to pop %d queue items, found %d", (int)queueSize, (int)[requests count] );
    if( [requests count] != queueSize )
        NSLog( @"found requests %@", requests );
    
    [tracker.connectionManager stopQueueDump];
}

/*
 receive HTTP 400, don't retry (queue is empty)
 receive HTTP 500, failed request should be at the top of the queue (try with another request in the queue behind it)
 */

-(void) test00000QueueFlush // run this test first to clear out queue and pending requests
{
    while( [requestsQueue pop] );
    [tracker.connectionManager stopQueueDump];
    waitFor( 30. );
}


-(void) test400DontRetry
{
    [tracker setDebugMode:TRUE];
    [tracker.connectionManager enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=400&statusCode%5Bmessage%5D=HTTP/1.0%20400%20Bad%20Request&headers%5BX-MAT-Responder%5D=someserver"
                                   encryptParams:nil
                                     andPOSTData:nil
                                         runDate:[NSDate date]];
    waitFor( 10. );
    
    [self checkAndClearExpectedQueueSize:0];
}

/* engine automatically returns headers now, I think
-(void) test400NoHeaderRetry
{
    [tracker setDebugMode:TRUE];
    [tracker.connectionManager enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=400&statusCode%5Bmessage%5D=HTTP/1.0%20400%20Bad%20Request"
                                   encryptParams:nil
                                     andPOSTData:nil
                                         runDate:[NSDate date]];
    waitFor( 10. );
    
    [self checkAndClearExpectedQueueSize:1];
}
 */


-(void) test500Retry
{
    [tracker setDebugMode:TRUE];
    [tracker.connectionManager enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error"
                                   encryptParams:nil
                                     andPOSTData:nil
                                         runDate:[NSDate date]];
    waitFor( 10. );
    
    [self checkAndClearExpectedQueueSize:1];
}


-(void) test500RetryCount
{
    [tracker setDebugMode:TRUE];
    [tracker.connectionManager enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error"
                                   encryptParams:nil
                                     andPOSTData:nil
                                         runDate:[NSDate date]];
    waitFor( 10. );

    XCTAssertTrue( requestsQueue.queuedRequestsCount == 1, @"expected %d queued requests, found %d",
                   1, (unsigned int)requestsQueue.queuedRequestsCount );

    NSMutableArray *requests = [NSMutableArray new];
    NSDictionary *request = nil;
    while( (request = [requestsQueue pop]) )
        [requests addObject:request];

    XCTAssertTrue( [requests count] == 1, @"expected to pop %d queue items, found %d", 1, (int)[requests count] );
    XCTAssertTrue( [requests[0][@"url"] rangeOfString:@"&sdk_retry_attempt=1&"].location != NSNotFound, @"should have incremented retry count" );

    [tracker.connectionManager stopQueueDump];
}


-(void) test500RetryOrder
{
    [tracker setDebugMode:TRUE];
    [tracker.connectionManager enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error"
                                   encryptParams:nil
                                     andPOSTData:nil
                                         runDate:[NSDate date]];
    [tracker.connectionManager enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error&headers%5Bdummyheader%5D=yourmom"
                                   encryptParams:nil
                                     andPOSTData:nil
                                         runDate:[NSDate date]];
    waitFor( 10. );
    
    XCTAssertTrue( requestsQueue.queuedRequestsCount == 2, @"expected %d queued requests, found %d",
                   2, (unsigned int)requestsQueue.queuedRequestsCount );
    
    NSMutableArray *requests = [NSMutableArray new];
    NSDictionary *request = nil;
    while( (request = [requestsQueue pop]) )
        [requests addObject:request];
    
    XCTAssertTrue( [requests count] == 2, @"expected to pop %d queue items, found %d", 2, (int)[requests count] );
    XCTAssertTrue( [requests[0][@"url"] rangeOfString:@"yourmom"].location == NSNotFound, @"first call in queue should not have yourmom" );
    XCTAssertTrue( [requests[1][@"url"] rangeOfString:@"yourmom"].location != NSNotFound, @"second call in queue should have yourmom" );
    [tracker.connectionManager stopQueueDump];
}


-(void) test500RetryTwice
{
    [tracker setDebugMode:TRUE];
    [tracker.connectionManager enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Bad%20Request"
                                   encryptParams:nil
                                     andPOSTData:nil
                                         runDate:[NSDate date]];
    waitFor( 10. );

    XCTAssertTrue( requestsQueue.queuedRequestsCount == 1, @"expected %d queued requests, found %d",
                   1, (unsigned int)requestsQueue.queuedRequestsCount );

    [tracker.connectionManager dumpQueue];
    waitFor( 10. );
    
    [self checkAndClearExpectedQueueSize:1];
}

@end
