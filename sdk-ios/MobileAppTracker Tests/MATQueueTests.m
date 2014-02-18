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
#import "MATConnectionManager.h"
#import "MATRequestsQueue.h"
#import "MATReachability.h"
#import "MATSettings.h"

@interface MATQueueTests : XCTestCase <MobileAppTrackerDelegate>
{
    BOOL callSuccess;
    BOOL callFailed;
    
    NSMutableArray *successMessages;

    MATConnectionManager *connectionManager;
    MATRequestsQueue *requestsQueue;

    MATTestParams *params;
}
@end

@implementation MATQueueTests

- (void)setUp
{
    [super setUp];

    [MobileAppTracker startTrackerWithMATAdvertiserId:kTestAdvertiserId MATConversionKey:kTestConversionKey];
    [MobileAppTracker setDelegate:self];
    
    [MobileAppTracker setDebugMode:YES];
    [MobileAppTracker setAllowDuplicateRequests:YES];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    MobileAppTracker *mat = [[MobileAppTracker class] performSelector:@selector(sharedManager)];
    connectionManager = [mat performSelector:@selector(connectionManager)];
    requestsQueue = [connectionManager performSelector:@selector(requestsQueue)];
    while( [requestsQueue pop] ); // clear queue
    [connectionManager performSelector:@selector(stopQueueDump)];
#pragma clang diagnostic pop
    
    successMessages = [NSMutableArray array];
    
    params = [MATTestParams new];
}

- (void)tearDown
{
    [self putOnline];

    while( [requestsQueue pop] ); // clear queue
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [connectionManager performSelector:@selector(stopQueueDump)];
#pragma clang diagnostic pop

    [super tearDown];
}


-(void) takeOffline
{
    connectionManager.status = NotReachable;
}

-(void) putOnline
{
    connectionManager.status = ReachableViaWiFi;
}


-(void) checkAndClearExpectedQueueSize:(NSInteger)queueSize
{
    XCTAssertTrue( requestsQueue.queuedRequestsCount == queueSize, @"expected %d queued requests, found %d",
                   (int)queueSize, (unsigned int)requestsQueue.queuedRequestsCount );
    
    NSInteger count = 0;
    while( [requestsQueue pop] ) count++;
    XCTAssertTrue( count == queueSize, @"expected to pop %d queue items, found %d", (int)queueSize, (int)count );

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    [connectionManager performSelector:@selector(stopQueueDump)];
#pragma clang diagnostic pop
}


#pragma mark - Automatic queueing
-(void) testAAAAAQueueFlush // run this test first to clear out queue and pending requests
{
    emptyRequestQueue();
    waitFor( 10. );
    [self checkAndClearExpectedQueueSize:0];

    [self takeOffline];
    waitFor( 1. );
    XCTAssertTrue( connectionManager.status == NotReachable );
}


-(void) testOfflineFailureQueued
{
    [self takeOffline];
    XCTAssertTrue( connectionManager.status == NotReachable, @"connection status should be not reachable" );
    [MobileAppTracker trackSession];
    
    waitFor( 6. );
    XCTAssertTrue( connectionManager.status == NotReachable, @"connection status should be not reachable" );
    
    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );
    XCTAssertFalse( callSuccess, @"offline call should not have received a success notification" );
    [self checkAndClearExpectedQueueSize:1];
}

-(void) testOfflineFailureQueuedRetried
{
    [self takeOffline];
    [MobileAppTracker trackSession];
    
    waitFor( 6. );
    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );
    
 	[[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:nil];
    waitFor( 0.1 );
    XCTAssertFalse( callFailed, @"dequeuing call should have succeeded" );
    [self checkAndClearExpectedQueueSize:0];
}


-(void) testEnqueue2
{
    [self takeOffline];
    [MobileAppTracker trackSession];
    waitFor( 6. );
    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );

    [MobileAppTracker trackActionForEventIdOrName:@"yourMomEvent"];
    waitFor( 0.1 );
    XCTAssertFalse( callFailed, @"second offline call should not have received a failure notification" );
    [self checkAndClearExpectedQueueSize:2];
}

-(void) testEnqueue2Retried
{
    [MobileAppTracker setDebugMode:FALSE];
    
    [self takeOffline];
    [MobileAppTracker trackSession];
    waitFor( 6. );
    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );
    
    [MobileAppTracker trackActionForEventIdOrName:@"yourMomEvent"];
    waitFor( 0.1 );
    XCTAssertFalse( callFailed, @"offline call should not have received a failure notification" );

    XCTAssertTrue( requestsQueue.queuedRequestsCount == 2, @"expected 2 queued requests" );
 	[[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:nil];
    waitFor( 1. );
    XCTAssertFalse( callFailed, @"dequeuing call should not have failed" );
    XCTAssertTrue( callSuccess, @"dequeuing call should have succeeded" );
    [self checkAndClearExpectedQueueSize:0];
}

-(void) testEnqueue2RetriedOrder
{
    [MobileAppTracker setDebugMode:TRUE];

    [self takeOffline];
    [MobileAppTracker trackActionForEventIdOrName:@"event1"];
    [MobileAppTracker trackActionForEventIdOrName:@"event2"];
    waitFor( 0.1 );
    
    XCTAssertTrue( requestsQueue.queuedRequestsCount == 2, @"expected 2 queued requests" );
 	[[NSNotificationCenter defaultCenter] postNotificationName:kReachabilityChangedNotification object:nil];
    waitFor( 5. );

    XCTAssertTrue( callSuccess, @"dequeuing call should have succeeded" );
    [self checkAndClearExpectedQueueSize:0];
    XCTAssertTrue( [successMessages count] == 2, @"both calls should have succeeded" );

    for( NSInteger i = 0; i < [successMessages count]; i++ ) {
        NSData *data = successMessages[i];
        NSDictionary *jso = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *expectedEvent = [NSString stringWithFormat:@"event%d", (int)i + 1];
        XCTAssertTrue( [jso[@"get"][@"site_event_name"] isEqualToString:expectedEvent],
                       @"expected event name '%@', got '%@'", expectedEvent, jso[@"get"][@"site_event_name"] );
    }
}


-(void) testSessionQueue
{
    [MobileAppTracker setDebugMode:TRUE];
    [MobileAppTracker trackSession];
    waitFor( 1. );
    XCTAssertFalse( callFailed, @"session call should not have been attempted after 1 sec" );
    XCTAssertFalse( callSuccess, @"session call should not have been attempted after 1 sec" );
    XCTAssertTrue( requestsQueue.queuedRequestsCount == 1, @"expected 1 queued requests" );

    waitFor( 6. );
    XCTAssertFalse( callFailed, @"session call should not have failed" );
    XCTAssertTrue( callSuccess, @"session call should have succeeded" );
    XCTAssertTrue( [successMessages count] == 2, @"both calls should have succeeded" );
    [self checkAndClearExpectedQueueSize:0];
}

-(void) testSessionQueueOrder
{
    [MobileAppTracker setDebugMode:TRUE];
    [MobileAppTracker trackSession];
    [MobileAppTracker trackActionForEventIdOrName:@"event name"];
    waitFor( 1. );
    XCTAssertFalse( callFailed, @"no calls should have been attempted after 1 sec" );
    XCTAssertFalse( callSuccess, @"no calls should have been attempted after 1 sec" );
    XCTAssertTrue( requestsQueue.queuedRequestsCount == 2, @"expected 2 queued requests, but found %d", requestsQueue.queuedRequestsCount );
    
    waitFor( 6. );
    XCTAssertFalse( callFailed, @"session call should not have failed" );
    XCTAssertTrue( callSuccess, @"session call should have succeeded" );
    [self checkAndClearExpectedQueueSize:0];
}


#pragma mark - iAd attribution override

-(void) testiAdAttributionOverride
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    MobileAppTracker *mat = [[MobileAppTracker class] performSelector:@selector(sharedManager)];
    MATSettings *settings = [mat performSelector:@selector(parameters)];
#pragma clang diagnostic pop

    settings.iadAttribution = @FALSE;
    [MobileAppTracker trackSession];
    waitFor( 1. );
    ASSERT_KEY_VALUE( @"iad_attribution", [@(FALSE) stringValue] );
    
    settings.iadAttribution = @TRUE;
    waitFor( 5. );
    ASSERT_KEY_VALUE( @"iad_attribution", [@(TRUE) stringValue] );
}


#pragma mark - Requests queue behaviors

-(void) testRequestsQueueSerialize
{
    static NSString* const testUrl = @"fakeUrl";
    static NSString* const testPostData = @"someTestJson";
    NSDate *testDate = [NSDate date];
    NSDictionary *item = @{KEY_URL: testUrl, KEY_JSON: testPostData, KEY_RUN_DATE: testDate};
    
    MATRequestsQueue *queue = [MATRequestsQueue new];
    [queue push:item];
    [queue save];

    NSDictionary *readItem = [queue pop];
    XCTAssertTrue( [readItem count] == [item count], @"saved %ud keys, recovered %ud", [item count], [readItem count] );
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

-(void) mobileAppTrackerDidSucceedWithData:(NSData *)data
{
    [successMessages addObject:data];
    //NSLog( @"test received success with %@\n", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] );
    callSuccess = TRUE;
}

-(void) mobileAppTrackerDidFailWithError:(NSError *)error
{
    NSLog( @"test received failure with %@\n", error );
    callFailed = TRUE;
}


#pragma mark - MAT delegate

// secret functions to test server URLs
-(void) _matURLTestingCallbackWithParamsToBeEncrypted:(NSString*)paramsEncrypted withPlaintextParams:(NSString*)paramsPlaintext
{
    XCTAssertTrue( [params extractParamsString:paramsPlaintext], @"couldn't extract unencrypted params: %@", paramsPlaintext );
    XCTAssertTrue( [params extractParamsString:paramsEncrypted], @"couldn't extract encypted params: %@", paramsEncrypted );
}

-(void) _matSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    XCTAssertTrue( [params extractParamsString:trackingUrl], @"couldn't extract params from URL %@", trackingUrl );
    if( postData )
        XCTAssertTrue( [params extractParamsJSON:postData], @"couldn't extract POST JSON: %@", postData );
}

@end
