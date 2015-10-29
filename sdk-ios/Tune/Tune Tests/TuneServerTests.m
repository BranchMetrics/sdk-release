//
//  TuneServerTests.m
//  Tune
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TuneTestsHelper.h"
#import "../Tune/Tune.h"
#import "../Tune/TuneEvent.h"
#import "../Tune/TuneEventItem.h"
#import "../Tune/Common/TuneTracker.h"

@interface TuneServerTests : XCTestCase <TuneDelegate>
{
    BOOL callSuccess;
    BOOL callFailed;
    BOOL callFailedDuplicate;
}

@end


@implementation TuneServerTests

- (void)setUp
{
    waitFor( 10. ); // wait for previous tests
    
    [super setUp];
    
    callSuccess = NO;
    callFailed = NO;
    callFailedDuplicate = NO;

    [Tune setAllowDuplicateRequests:YES];
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey];
    [Tune setDelegate:self];

    emptyRequestQueue();
}

- (void)tearDown
{
    [super tearDown];

    [Tune setAllowDuplicateRequests:NO];
    [Tune setDebugMode:NO];

    emptyRequestQueue();
}

- (void)testInstall
{
    [Tune measureSession];
    waitFor( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( callSuccess, @"measureSession should have succeeded" );
    XCTAssertFalse( callFailed, @"measureSession should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureSession should have succeeded" );
}

- (void)testInstallPostConversion
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    id tune = [[Tune class] performSelector:@selector(sharedManager)];
    waitFor( 0.1 ); // let it initialize
    [tune performSelector:@selector(measureInstallPostConversion)];
#pragma clang diagnostic pop
    
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( callSuccess, @"measureInstallPostConversion should have succeeded" );
    XCTAssertFalse( callFailed, @"measureInstallPostConversion should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureInstallPostConversion should have succeeded" );
}

- (void)testUpdate
{
    [Tune setExistingUser:YES];
    [Tune measureSession];
    waitFor( TUNE_SESSION_QUEUING_DELAY + TUNE_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( callSuccess, @"trackUpdate should have succeeded" );
    XCTAssertFalse( callFailed, @"trackUpdate should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"trackUpdate should have succeeded" );
}

- (void)testActionNameEvent
{
    static NSString* const eventName = @"testEventName";
    [Tune measureEventName:eventName];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( callSuccess, @"measureEventName should have succeeded" );
    XCTAssertFalse( callFailed, @"measureEventName should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureEventName should have succeeded" );
}

- (void)testActionNameEventDuplicate
{
    static NSString* const eventName = @"testEventName";
    [Tune measureEventName:eventName];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertTrue( callSuccess, @"measureEventName should have succeeded" );
    XCTAssertFalse( callFailed, @"measureEventName should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureEventName should have succeeded" );

    [Tune setAllowDuplicateRequests:NO];
    waitFor( 5. );

    [Tune measureEventName:eventName];
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );
    XCTAssertFalse( callSuccess, @"measureEventName duplicate should not have succeeded" );
    XCTAssertTrue( callFailed, @"measureEventName duplicate should not have succeeded" );
    XCTAssertTrue( callFailedDuplicate, @"measureEventName duplicate should not have succeeded" );
}

- (void)testActionNameIdItemsRevenue
{
    static NSString* const eventName = @"testEventName";
    static NSString* const itemName = @"testItemName";
    static CGFloat const itemPrice = 2.71828;
    static NSInteger const itemQuantity = 42;
    TuneEventItem *item = [TuneEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    static CGFloat revenue = 3.14159;
    static NSString* const currencyCode = @"XXX";
    
    TuneEvent *evt = [TuneEvent eventWithName:eventName];
    evt.eventItems = items;
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;
    
    [Tune measureEvent:evt];
    
    waitFor( TUNE_TEST_NETWORK_REQUEST_DURATION );

    XCTAssertTrue( callSuccess, @"measureEventName with items should have succeeded" );
    XCTAssertFalse( callFailed, @"measureEventName with items should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureEventName with items should have succeeded" );
}

- (void)testPurchaseDuplicates
{
    [Tune setAllowDuplicateRequests:NO];

    TuneEvent *evt = [TuneEvent eventWithName:@"purchase" ];
    evt.refId = [[NSUUID UUID] UUIDString];
    evt.revenue = 1.;
    evt.currencyCode = @"USD";
    
    [Tune measureEvent:evt];
    
    waitFor( 5. );
    XCTAssertTrue( callSuccess, @"measureEventName with revenue should have succeeded" );
    XCTAssertFalse( callFailed, @"measureEventName with revenue should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureEventName with revenue should have succeeded" );

    callSuccess = NO;
    
    evt = [TuneEvent eventWithName:@"purchase" ];
    evt.refId = [[NSUUID UUID] UUIDString];
    evt.revenue = 1.;
    evt.currencyCode = @"USD";
    
    [Tune measureEvent:evt];
    
    waitFor( 5. );
    XCTAssertTrue( callSuccess, @"measureEventName with revenue should have succeeded" );
    XCTAssertFalse( callFailed, @"measureEventName with revenue should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureEventName with revenue should have succeeded" );
}


#pragma mark - Tune delegate

- (void)tuneDidSucceedWithData:(NSData *)data
{
    //NSLog( @"test received success with %@\n", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] );
    callSuccess = YES;
    callFailed = NO;
}

- (void)tuneDidFailWithError:(NSError *)error
{
    callFailed = YES;
    callSuccess = NO;
    
    NSString *serverString = [error localizedDescription];
    
    if( [serverString rangeOfString:@"Duplicate request detected."].location != NSNotFound )
        callFailedDuplicate = YES;
    else
        NSLog( @"test received failure with %@\n", error );
}

// secret functions to test server URLs
- (void)_tuneURLTestingCallbackWithParamsToBeEncrypted:(NSString*)paramsEncrypted withPlaintextParams:(NSString*)paramsPlaintext
{
    //NSLog( @"plaintext params %@, encrypted params %@\n", paramsPlaintext, paramsEncrypted );
}

- (void)_tuneSuperSecretURLTestingCallbackWithURLString:(NSString*)trackingUrl andPostDataString:(NSString*)postData
{
    //NSLog( @"requesting with url %@ and post data %@\n", trackingUrl, postData );
}

@end
