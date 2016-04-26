//
//  TuneServerTests.m
//  Tune
//
//  Created by John Bender on 12/18/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "Tune+Testing.h"
#import "TuneEvent+Internal.h"
#import "TuneEventItem+Internal.h"
#import "TuneTracker.h"


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
    [super setUp];
    
    RESET_EVERYTHING();
    
    callSuccess = NO;
    callFailed = NO;
    callFailedDuplicate = NO;
    
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey];
    [Tune setDelegate:self];

    [Tune setAllowDuplicateRequests:YES];
    
    emptyRequestQueue();
}

- (void)tearDown
{
    [Tune setDebugMode:NO];

    emptyRequestQueue();
    
    [super tearDown];
}

- (void)testInstall
{
    [Tune measureSession];
    waitForQueuesToFinish();
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
    
    waitForQueuesToFinish();
    XCTAssertTrue( callSuccess, @"measureInstallPostConversion should have succeeded" );
    XCTAssertFalse( callFailed, @"measureInstallPostConversion should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureInstallPostConversion should have succeeded" );
}

- (void)testUpdate
{
    [Tune setExistingUser:YES];
    [Tune measureSession];
    waitForQueuesToFinish();
    XCTAssertTrue( callSuccess, @"trackUpdate should have succeeded" );
    XCTAssertFalse( callFailed, @"trackUpdate should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"trackUpdate should have succeeded" );
}

- (void)testActionNameEvent
{
    static NSString* const eventName = @"testEventName";
    [Tune measureEventName:eventName];
    waitForQueuesToFinish();
    XCTAssertTrue( callSuccess, @"measureEventName should have succeeded" );
    XCTAssertFalse( callFailed, @"measureEventName should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureEventName should have succeeded" );
}

// TODO: We need to figure this out with the API team. TRACK-991
//- (void)testActionNameEventDuplicate
//{
//    static NSString* const eventName = @"testEventName";
//    [Tune measureEventName:eventName];
//    waitForQueuesToFinish();
//    XCTAssertTrue( callSuccess, @"measureEventName should have succeeded" );
//    XCTAssertFalse( callFailed, @"measureEventName should have succeeded" );
//    XCTAssertFalse( callFailedDuplicate, @"measureEventName should have succeeded" );
//
//    waitForQueuesToFinish();
//
//    [Tune measureEventName:eventName];
//    waitForQueuesToFinish();
//    XCTAssertFalse( callSuccess, @"measureEventName duplicate should not have succeeded" );
//    XCTAssertTrue( callFailed, @"measureEventName duplicate should not have succeeded" );
//    XCTAssertTrue( callFailedDuplicate, @"measureEventName duplicate should not have succeeded" );
//}

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
    
    waitForQueuesToFinish();

    XCTAssertTrue( callSuccess, @"measureEventName with items should have succeeded" );
    XCTAssertFalse( callFailed, @"measureEventName with items should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureEventName with items should have succeeded" );
}

- (void)testPurchaseDuplicates
{
    TuneEvent *evt = [TuneEvent eventWithName:@"purchase" ];
    evt.refId = [[NSUUID UUID] UUIDString];
    evt.revenue = 1.;
    evt.currencyCode = @"USD";
    
    [Tune measureEvent:evt];
    
    waitForQueuesToFinish();
    XCTAssertTrue( callSuccess, @"measureEventName with revenue should have succeeded" );
    XCTAssertFalse( callFailed, @"measureEventName with revenue should have succeeded" );
    XCTAssertFalse( callFailedDuplicate, @"measureEventName with revenue should have succeeded" );

    callSuccess = NO;
    
    evt = [TuneEvent eventWithName:@"purchase" ];
    evt.refId = [[NSUUID UUID] UUIDString];
    evt.revenue = 1.;
    evt.currencyCode = @"USD";
    
    [Tune measureEvent:evt];
    
    waitForQueuesToFinish();
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
