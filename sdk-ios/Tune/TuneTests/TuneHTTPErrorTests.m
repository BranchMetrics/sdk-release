//
//  TuneHTTPErrorTests.m
//  Tune
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Tune+Testing.h"
#import "TuneEventQueue+Testing.h"
#import "TuneHttpUtils.h"
#import "TuneKeyStrings.h"
#import "TuneNetworkUtils.h"
#import "TuneTracker.h"
#import "TuneXCTestCase.h"

#import <OCMock/OCMock.h>

@interface TuneHTTPErrorTests : TuneXCTestCase
{
    TuneTracker *tracker;
    TuneEventQueue *eventQueue;
}
@end

@implementation TuneHTTPErrorTests

- (void)setUp {
    [super setUp];

    tracker = [TuneTracker new];
    
    eventQueue = [TuneEventQueue sharedQueue];
}

- (void)tearDown {
    emptyRequestQueue();
    waitForQueuesToFinish();
    
    [super tearDown];
}

- (void)checkAndClearExpectedQueueSize:(NSInteger)queueSize {
    NSUInteger size = [[TuneEventQueue sharedQueue] queueSize];
    XCTAssertTrue(size == queueSize, @"expected %d queued requests, found %d", (int)queueSize, (unsigned int)size);
    
    emptyRequestQueue();
    
    NSUInteger count = 0;
    size = [[TuneEventQueue sharedQueue] queueSize];
    XCTAssertTrue(size == count, @"expected %d queued requests, found %d", (unsigned int)count, (unsigned int)size );
}

- (void)test500Retry {
    __block BOOL forcedNetworkStatus = YES;
    id classMockTuneNetworkUtils = OCMClassMock([TuneNetworkUtils class]);
    OCMStub(ClassMethod([classMockTuneNetworkUtils isNetworkReachable])).andDo(^(NSInvocation *invocation) {
        [invocation setReturnValue:&forcedNetworkStatus];
    });
    
    [[TuneEventQueue sharedQueue] enqueueUrlRequest:@"https://www.tune.com"
                          eventAction:nil
                                refId:nil
                        encryptParams:nil
                             postData:nil
                              runDate:[NSDate date]];
    waitFor( .1 );
    
    [self checkAndClearExpectedQueueSize:1];
    
    [classMockTuneNetworkUtils stopMocking];
}

- (void)test500RetryOrder {
        
    [[TuneEventQueue sharedQueue] enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.1%20500%20Server%20Error"
                          eventAction:nil
                                refId:nil
                        encryptParams:nil
                             postData:nil
                              runDate:[NSDate date]];
    [[TuneEventQueue sharedQueue] enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.1%20500%20Server%20Error&headers%5Bdummyheader%5D=yourmom"
                          eventAction:nil
                                refId:nil
                        encryptParams:nil
                             postData:nil
                              runDate:[NSDate date]];
    
    XCTAssertEqual( [[TuneEventQueue sharedQueue] queueSize], 2, @"expected %d queued requests, found %d",
                   2, (unsigned int)[[TuneEventQueue sharedQueue] queueSize] );
    
    NSMutableArray *requests = [[TuneEventQueue sharedQueue] events];
    
    NSUInteger size = [[TuneEventQueue sharedQueue] queueSize];
    XCTAssertEqual(size, 2, @"expected to pop %d queue items, found %d", 2, (int)size);
    XCTAssertTrue([requests[0][@"url"] rangeOfString:@"yourmom"].location == NSNotFound, @"first call in queue should not have yourmom");
    XCTAssertTrue([requests[1][@"url"] rangeOfString:@"yourmom"].location != NSNotFound, @"second call in queue should have yourmom");
}

- (void)test500RetryTwice {
    
    [[TuneEventQueue sharedQueue] enqueueUrlRequest:@"http://engine.stage.mobileapptracking.com/v1/Integrations/sdk/headers?statusCode%5Bcode%5D=500&statusCode%5Bmessage%5D=HTTP/1.1%20500%20Bad%"
                          eventAction:nil
                                refId:nil
                        encryptParams:nil
                             postData:nil
                              runDate:[NSDate date]];
    
    int expected = 1;
    int actual = (unsigned int)[[TuneEventQueue sharedQueue] queueSize];

    XCTAssertEqual( expected, actual, @"expected %d queued requests, found %d", expected, actual );
    
    [[TuneEventQueue sharedQueue] dumpQueue];
    
    [self checkAndClearExpectedQueueSize:1];
}

@end
