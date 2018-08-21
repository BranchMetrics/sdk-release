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
#import "TuneLog.h"
#import "TuneTracker.h"

#import "TuneXCTestCase.h"

@interface TuneServerTests : TuneXCTestCase <TuneDelegate> {
}

@end


@implementation TuneServerTests

- (void)setUp {
    [super setUp];
  
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId];
    [Tune setAllowDuplicateRequests:YES];
    
    emptyRequestQueue();
}

- (void)tearDown {
    TuneLog.shared.verbose = NO;
    TuneLog.shared.logBlock = nil;
    
    emptyRequestQueue();
    
    [super tearDown];
}

- (void)testInstall {
    __block BOOL isMeasureSessionCalled = NO;
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        if ([message containsString:@"action=session"]) {
            isMeasureSessionCalled = YES;
        }
    };
    
    [Tune measureSession];
    waitForQueuesToFinish();
    XCTAssertTrue(isMeasureSessionCalled);

}

- (void)testInstallPostConversion {
    __block BOOL isInstallPostConversionCalled = NO;
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        if ([message containsString:@"action=install"]) {
            isInstallPostConversionCalled = YES;
        }
    };
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    id tune = [[TuneTracker class] performSelector:@selector(sharedInstance)];
    waitFor( 0.1 ); // let it initialize
    [tune performSelector:@selector(measureInstallPostConversion)];
#pragma clang diagnostic pop

    waitForQueuesToFinish();
    XCTAssertTrue(isInstallPostConversionCalled);
}

- (void)testUpdate {
    __block BOOL isTrackUpdate = NO;
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        if ([message containsString:@"existing_user=1"] && [message containsString:@"action=session"]) {
            isTrackUpdate = YES;
        }
    };
    
    [Tune setExistingUser:YES];
    [Tune measureSession];
    waitForQueuesToFinish();
    XCTAssertTrue(isTrackUpdate);
}

- (void)testActionNameEvent {
    __block BOOL isConversion = NO;
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        if ([message containsString:@"site_event_name=testEventName"] && [message containsString:@"action=conversion"]) {
            isConversion = YES;
        }
    };
    
    NSString *eventName = @"testEventName";
    [Tune measureEventName:eventName];
    waitForQueuesToFinish();
    XCTAssertTrue(isConversion);
}

- (void)testActionNameIdItemsRevenue {
    __block BOOL isEventWithItems = NO;
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        if ([message containsString:@"\"revenue\":\"114.16776\""] &&
            [message containsString:@"\"item\":\"testItemName\""] &&
            [message containsString:@"currency_code=XXX"]) {
            isEventWithItems = YES;
        }
    };
    
    NSString *eventName = @"testEventName";
    NSString *itemName = @"testItemName";
    CGFloat itemPrice = 2.71828;
    NSInteger itemQuantity = 42;
    TuneEventItem *item = [TuneEventItem eventItemWithName:itemName unitPrice:itemPrice quantity:itemQuantity];
    NSArray *items = @[item];
    CGFloat revenue = 3.14159;
    NSString *currencyCode = @"XXX";

    TuneEvent *evt = [TuneEvent eventWithName:eventName];
    evt.eventItems = items;
    evt.revenue = revenue;
    evt.currencyCode = currencyCode;

    [Tune measureEvent:evt];
    waitForQueuesToFinish();
    XCTAssertTrue(isEventWithItems);
}

- (void)testPurchaseDuplicates {
    __block int numberOfPurchaseCalls = 0;
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        if ([message containsString:@"revenue=1"] && [message containsString:@"currency_code=USD"]) {
            numberOfPurchaseCalls++;
        }
    };
    
    TuneEvent *evt = [TuneEvent eventWithName:@"purchase" ];
    evt.refId = [[NSUUID UUID] UUIDString];
    evt.revenue = 1.00;
    evt.currencyCode = @"USD";

    [Tune measureEvent:evt];

    waitForQueuesToFinish();
    XCTAssertTrue(numberOfPurchaseCalls == 1);

    
    evt = [TuneEvent eventWithName:@"purchase" ];
    evt.refId = [[NSUUID UUID] UUIDString];
    evt.revenue = 1.;
    evt.currencyCode = @"USD";

    [Tune measureEvent:evt];

    waitForQueuesToFinish();
    XCTAssertTrue(numberOfPurchaseCalls == 2);
}

@end
