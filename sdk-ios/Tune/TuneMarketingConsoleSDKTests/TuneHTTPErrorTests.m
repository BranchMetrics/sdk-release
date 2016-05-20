//
//  TuneHTTPErrorTests.m
//  Tune
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "TuneEventQueue+Testing.h"
#import "TuneKeyStrings.h"
#import "TuneTracker.h"
#import "Tune+Testing.h"
#import "TuneHttpUtils.h"

@interface TuneHTTPErrorTests : XCTestCase
{
    TuneTracker *tracker;
    TuneEventQueue *eventQueue;
    
    id mockTuneHttpUtils;
}
@end

@implementation TuneHTTPErrorTests

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();

    tracker = [TuneTracker new];
    
    eventQueue = [TuneEventQueue sharedInstance];
    
    mockTuneHttpUtils = OCMClassMock([TuneHttpUtils class]);
}

- (void)tearDown {
    emptyRequestQueue();
    waitForQueuesToFinish();

    [mockTuneHttpUtils stopMocking];
    
    [super tearDown];
}

- (void)checkAndClearExpectedQueueSize:(NSInteger)queueSize {
    XCTAssertTrue( [TuneEventQueue queueSize] == queueSize, @"expected %d queued requests, found %d", (int)queueSize, (unsigned int)[TuneEventQueue queueSize] );
    
    emptyRequestQueue();
    
    NSUInteger count = 0;
    XCTAssertTrue( [TuneEventQueue queueSize] == count, @"expected %d queued requests, found %d", (unsigned int)count, (unsigned int)[TuneEventQueue queueSize] );
}

/*
 receive HTTP 400, don't retry (queue is empty)
 receive HTTP 500, failed request should be at the top of the queue (try with another request in the queue behind it)
 */

- (void)test400DontRetry {
    networkOnline();
    
#if !TARGET_OS_TV
    [Tune setDebugMode:YES];
#endif

    NSDictionary *dictHeaders = @{@"Content-Length":@"0", @"Content-Type":@"text/html; charset=UTF-8", @"Connection":@"keep-alive", @"X-Mat-Responder":@"p-deeplinker01-1a.use01", @"Date":@"Wed, 30 Mar 2016 22:46:20 GMT", @"Server" : @"nginx"};
    NSURL *url = [NSURL URLWithString:@"https://www.tune.com"];
    NSHTTPURLResponse *resp = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:400 HTTPVersion:@"1.1" headerFields:dictHeaders];
    NSError *err = nil;
    
    OCMStub([mockTuneHttpUtils sendSynchronousRequest:[OCMArg any] response:[OCMArg setTo:resp] error:[OCMArg setTo:err]]);
    OCMStub([mockTuneHttpUtils addIdentifyingHeaders:[OCMArg any]]).andForwardToRealObject();
    
    [TuneEventQueue enqueueUrlRequest:@"http://www.tune.com"
                          eventAction:nil
                        encryptParams:nil
                             postData:nil
                              runDate:[NSDate date]];
    waitForQueuesToFinish();
    
    [self checkAndClearExpectedQueueSize:0];
}

/* engine automatically returns headers now, I think
- (void)test400NoHeaderRetry
{
 #if !TARGET_OS_TV
 [Tune setDebugMode:YES];
 #endif
 
    [TuneEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=400&statusCode%5Bmessage%5D=HTTP/1.0%20400%20Bad%20Request"
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    waitFor( 10. );
    
    [self checkAndClearExpectedQueueSize:1];
}
 */

- (void)test500Retry {
    networkOnline();
    
#if !TARGET_OS_TV
    [Tune setDebugMode:YES];
#endif
    
    NSDictionary *dictHeaders = @{@"Content-Length":@"0", @"Content-Type":@"text/html; charset=UTF-8", @"Connection":@"keep-alive", @"X-Mat-Responder":@"p-deeplinker01-1a.use01", @"Date":@"Wed, 30 Mar 2016 22:46:20 GMT", @"Server" : @"nginx"};
    NSURL *url = [NSURL URLWithString:@"https://www.tune.com"];
    NSHTTPURLResponse *resp = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:500 HTTPVersion:@"1.1" headerFields:dictHeaders];
    NSError *err = nil;
    
    OCMStub([mockTuneHttpUtils sendSynchronousRequest:[OCMArg any] response:[OCMArg setTo:resp] error:[OCMArg setTo:err]]);
    OCMStub([mockTuneHttpUtils addIdentifyingHeaders:[OCMArg any]]).andForwardToRealObject();
    
    [TuneEventQueue enqueueUrlRequest:@"https://www.tune.com"
                          eventAction:nil
                        encryptParams:nil
                             postData:nil
                              runDate:[NSDate date]];
    waitFor( .1 );
    
    [self checkAndClearExpectedQueueSize:1];
}

- (void)test500RetryCount {
    networkOnline();
    
#if !TARGET_OS_TV
    [Tune setDebugMode:YES];
#endif
    
    NSDictionary *dictHeaders = @{@"Content-Length":@"0", @"Content-Type":@"text/html; charset=UTF-8", @"Connection":@"keep-alive", @"X-Mat-Responder":@"p-deeplinker01-1a.use01", @"Date":@"Wed, 30 Mar 2016 22:46:20 GMT", @"Server" : @"nginx"};
    NSURL *url = [NSURL URLWithString:@"https://www.tune.com"];
    NSHTTPURLResponse *resp = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:500 HTTPVersion:@"1.1" headerFields:dictHeaders];
    NSError *err = nil;
    
    OCMStub([mockTuneHttpUtils sendSynchronousRequest:[OCMArg any] response:[OCMArg setTo:resp] error:[OCMArg setTo:err]]);
    OCMStub([mockTuneHttpUtils addIdentifyingHeaders:[OCMArg any]]).andForwardToRealObject();
    
    [TuneEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error"
                          eventAction:nil
                        encryptParams:nil
                             postData:nil
                              runDate:[NSDate date]];
    waitFor( .1 );

    XCTAssertEqual( [TuneEventQueue queueSize], 1, @"expected %d queued requests, found %d",
                   1, (unsigned int)[TuneEventQueue queueSize] );
    
    NSMutableArray *requests = [TuneEventQueue events];

    XCTAssertEqual( [requests count], 1, @"expected to pop %d queue items, found %d", 1, (int)[requests count] );
    
    NSString *strUrl = requests[0][@"url"];
    NSString *searchString = [NSString stringWithFormat:@"&%@=1", TUNE_KEY_RETRY_COUNT];
    
    XCTAssertTrue( [strUrl rangeOfString:searchString].location != NSNotFound, @"should have incremented retry count" );
}

- (void)test500RetryOrder {
#if !TARGET_OS_TV
    [Tune setDebugMode:YES];
#endif
    
    NSDictionary *dictHeaders = @{@"Content-Length":@"0", @"Content-Type":@"text/html; charset=UTF-8", @"Connection":@"keep-alive", @"X-Mat-Responder":@"p-deeplinker01-1a.use01", @"Date":@"Wed, 30 Mar 2016 22:46:20 GMT", @"Server" : @"nginx"};
    NSURL *url = [NSURL URLWithString:@"https://www.tune.com"];
    NSHTTPURLResponse *resp = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:500 HTTPVersion:@"1.1" headerFields:dictHeaders];
    NSError *err = nil;
    
    OCMStub([mockTuneHttpUtils sendSynchronousRequest:[OCMArg any] response:[OCMArg setTo:resp] error:[OCMArg setTo:err]]);
    OCMStub([mockTuneHttpUtils addIdentifyingHeaders:[OCMArg any]]).andForwardToRealObject();
    
    [TuneEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error"
                          eventAction:nil
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    [TuneEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Server%20Error&headers%5Bdummyheader%5D=yourmom"
                          eventAction:nil
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    
    XCTAssertEqual( [TuneEventQueue queueSize], 2, @"expected %d queued requests, found %d",
                   2, (unsigned int)[TuneEventQueue queueSize] );
    
    NSMutableArray *requests = [TuneEventQueue events];
    
    XCTAssertEqual( [TuneEventQueue queueSize], 2, @"expected to pop %d queue items, found %d", 2, (int)[TuneEventQueue queueSize] );
    XCTAssertTrue( [requests[0][@"url"] rangeOfString:@"yourmom"].location == NSNotFound, @"first call in queue should not have yourmom" );
    XCTAssertTrue( [requests[1][@"url"] rangeOfString:@"yourmom"].location != NSNotFound, @"second call in queue should have yourmom" );
}

- (void)test500RetryTwice
{
#if !TARGET_OS_TV
    [Tune setDebugMode:YES];
#endif
    
    NSDictionary *dictHeaders = @{@"Content-Length":@"0", @"Content-Type":@"text/html; charset=UTF-8", @"Connection":@"keep-alive", @"X-Mat-Responder":@"p-deeplinker01-1a.use01", @"Date":@"Wed, 30 Mar 2016 22:46:20 GMT", @"Server" : @"nginx"};
    NSURL *url = [NSURL URLWithString:@"https://www.tune.com"];
    NSHTTPURLResponse *resp = [[NSHTTPURLResponse alloc] initWithURL:url statusCode:500 HTTPVersion:@"1.1" headerFields:dictHeaders];
    NSError *err = nil;
    
    OCMStub([mockTuneHttpUtils sendSynchronousRequest:[OCMArg any] response:[OCMArg setTo:resp] error:[OCMArg setTo:err]]);
    OCMStub([mockTuneHttpUtils addIdentifyingHeaders:[OCMArg any]]).andForwardToRealObject();
    
    [TuneEventQueue enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.0%20500%20Bad%"
                          eventAction:nil
                       encryptParams:nil
                            postData:nil
                             runDate:[NSDate date]];
    
    int expected = 1;
    int actual = (unsigned int)[TuneEventQueue queueSize];

    XCTAssertEqual( expected, actual, @"expected %d queued requests, found %d", expected, actual );
    
    [TuneEventQueue dumpQueue];
    
    [self checkAndClearExpectedQueueSize:1];
}

@end
