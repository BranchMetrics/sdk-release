//
//  TuneDeferredDplinkrTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 3/2/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Tune+Testing.h"
#import "TuneDeferredDplinkr.h"
#import "TuneXCTestCase.h"
#import "NSURLSession+SynchronousTask.h"

@import AdSupport;

@interface TuneDeferredDplinkrTests : TuneXCTestCase <TuneDelegate> {
    BOOL finished;
    BOOL defDeepLinkReceived;
    
    TuneDeepLinkError deepLinkErrorCode;
    
    NSString *currentIfa;
    NSString *currentRequestUrl;
    
    id classMockHttpUtils;
}
@end

@implementation TuneDeferredDplinkrTests

- (void)setUp {
    [super setUp];
    
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId wearable:NO];
    
    defDeepLinkReceived = NO;
    finished = NO;
}

- (void)testCheckForDeferredDeepLinkSuccess {
    NSString *dummyIFA = @"12345678-1234-1234-1234-123456789012";
    NSString *measurementUrl = [NSString stringWithFormat:@"https://169564.measurementapi.com/serve?action=click&publisher_id=169564&site_id=47548&invoke_id=279839&ad_id=%@", dummyIFA];
    
    NSURLResponse *resp;
    NSError *error;
    [[NSURLSession sharedSession] sendSynchronousDataTaskWithURL:[NSURL URLWithString:measurementUrl] returningResponse:&resp error:&error];
    
    [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:dummyIFA] advertisingTrackingEnabled:YES];
    [Tune checkForDeferredDeeplink:self];
    
    waitFor1(1.0, &finished);
    
    XCTAssertTrue(finished);
    XCTAssertTrue(defDeepLinkReceived);
}

- (void)testSetterUpdatedIFAIsUsedByDeferredDeepLinker {
    NSString *realIFA = [[ASIdentifierManager sharedManager] advertisingIdentifier].UUIDString;
    
    [Tune setShouldAutoCollectAppleAdvertisingIdentifier:YES];
    [Tune checkForDeferredDeeplink:self];
    
    waitFor1(1.0, &finished);
    
    XCTAssertTrue(finished);
    XCTAssertTrue([currentRequestUrl rangeOfString:([NSString stringWithFormat:@"%@", realIFA])].location != NSNotFound);
    
    NSString *dummyIFA = @"32132132-3213-3213-3213-321321321321";
    
    [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:dummyIFA] advertisingTrackingEnabled:YES];
    [Tune checkForDeferredDeeplink:self];
    
    waitFor1(1.0, &finished);
    
    XCTAssertTrue(finished);
    XCTAssertTrue([currentRequestUrl rangeOfString:([NSString stringWithFormat:@"%@", dummyIFA])].location != NSNotFound);
    
    dummyIFA = @"11111111-2222-3333-4444-555555555555";
    
    [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:dummyIFA] advertisingTrackingEnabled:YES];
    [Tune checkForDeferredDeeplink:self];
    
    waitFor1(1.0, &finished);
    
    XCTAssertTrue(finished);
    XCTAssertTrue([currentRequestUrl rangeOfString:([NSString stringWithFormat:@"%@", dummyIFA])].location != NSNotFound);
    
    [Tune setShouldAutoCollectAppleAdvertisingIdentifier:YES];
    [Tune checkForDeferredDeeplink:self];
    
    waitFor1(1.0, &finished);
    
    XCTAssertTrue(finished);
    XCTAssertTrue([currentRequestUrl rangeOfString:([NSString stringWithFormat:@"%@", realIFA])].location != NSNotFound);
}

- (void)testCheckForDeferredDeepLinkDuplicate {
    [Tune checkForDeferredDeeplink:self];
    
    waitFor1(1.0, &finished);
    
    XCTAssertTrue(finished);
    
    finished = false;
    
    [Tune checkForDeferredDeeplink:self];
    
    waitFor1(1.0, &finished);
    
    XCTAssertEqual(TuneDeepLinkErrorDuplicateCall, deepLinkErrorCode);
    
    XCTAssertTrue(finished);
}

#pragma mark - TuneDelegate Methods

-(void)tuneDidFailDeeplinkWithError:(NSError *)error {
    finished = YES;
    deepLinkErrorCode = (TuneDeepLinkError)error.code;
    
    currentRequestUrl = error.userInfo[@"request_url"];
}

-(void)tuneDidReceiveDeeplink:(NSString *)deeplink {
    finished = YES;
    defDeepLinkReceived = YES;
}

@end
