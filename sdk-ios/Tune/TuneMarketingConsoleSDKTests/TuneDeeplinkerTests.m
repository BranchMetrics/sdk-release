//
//  TuneDeeplinkerTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 3/2/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Tune+Testing.h"
#import "TuneDeeplinker.h"
#import "TuneDeviceDetails.h"
#import "TuneTestsHelper.h"
#import "TuneTracker.h"
#import "TuneUserProfile.h"
#import "TuneXCTestCase.h"

@import AdSupport;

typedef void(^TuneDeepLinkerDelegateCallbackBlock)(BOOL, NSString *);

// utility class so we can use the TuneDelegate like a callback block
@interface TuneDeeplinkerDelegate : NSObject <TuneDelegate>
@property (nonatomic, copy, readwrite) TuneDeepLinkerDelegateCallbackBlock block;
@end

@implementation TuneDeeplinkerDelegate

- (instancetype)initWithBlock:(TuneDeepLinkerDelegateCallbackBlock)block {
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

- (void)tuneDidFailDeeplinkWithError:(NSError *)error {
    if (self.block) {
        self.block(NO, nil);
    }
}

- (void)tuneDidReceiveDeeplink:(NSString *)deeplink {
    if (self.block) {
        self.block(YES, deeplink);
    }
}
@end

@interface TuneDeeplinkerTests : TuneXCTestCase

@end

@implementation TuneDeeplinkerTests

- (void)setUp {
    [super setUp];
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId wearable:NO];
}

- (void)tearDown {
    [super tearDown];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)testLegacyCheckForDeferredDeepLinkSuccess {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Network call completed"];
    
    TuneDeeplinkerDelegate *delegate = [[TuneDeeplinkerDelegate alloc] initWithBlock:^(BOOL success, NSString *deepLinkUrl) {
        XCTAssertTrue(success);
        [expectation fulfill];
        [Tune checkForDeferredDeeplink:nil];
    }];
    
    NSString *dummyIFA = @"12345678-1234-1234-1234-123456789012";
    NSString *measurementUrl = [NSString stringWithFormat:@"https://169564.measurementapi.com/serve?action=click&publisher_id=169564&site_id=47548&invoke_id=279839&ad_id=%@", dummyIFA];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:measurementUrl]];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:dummyIFA] advertisingTrackingEnabled:YES];
        [Tune checkForDeferredDeeplink:delegate];
    }] resume];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError * _Nullable error) {
        
    }];
}
#pragma clang diagnostic pop

- (void)testCheckForDeferredDeepLinkSuccess {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Network call completed"];
    
    TuneDeeplinkerDelegate *delegate = [[TuneDeeplinkerDelegate alloc] initWithBlock:^(BOOL success, NSString *deepLinkUrl) {
        XCTAssertTrue(success);
        [expectation fulfill];
        [Tune registerDeeplinkListener:nil];
    }];
    
    NSString *dummyIFA = @"12345678-1234-1234-1234-123456789012";
    NSString *measurementUrl = [NSString stringWithFormat:@"https://169564.measurementapi.com/serve?action=click&publisher_id=169564&site_id=47548&invoke_id=279839&ad_id=%@", dummyIFA];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:measurementUrl]];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:dummyIFA] advertisingTrackingEnabled:YES];
        [Tune registerDeeplinkListener:delegate];
    }] resume];
    
    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError * _Nullable error) {
        
    }];
}

/*
 This test does not work as expected.
 
 Originally, it relied on the error response to compare the request urls, however the server is now always sending back a deeplink.
 We should follow up with the AA team to find out why this is the case.
 */
- (void)testSetterUpdatedIFAIsUsedByDeferredDeepLinker {
    
    // collect and check real IFA
    __block NSString *realIFA = [[ASIdentifierManager sharedManager] advertisingIdentifier].UUIDString;

    [Tune setShouldAutoCollectAppleAdvertisingIdentifier:YES];
    __block XCTestExpectation *expectation1 = [self expectationWithDescription:@"Real IFA found"];
    [Tune registerDeeplinkListener:[[TuneDeeplinkerDelegate alloc] initWithBlock:^(BOOL success, NSString *deepLinkUrl) {
        XCTAssertTrue(success);
        [expectation1 fulfill];
        [Tune registerDeeplinkListener:nil];
    }]];
    [self waitForExpectations:[NSArray arrayWithObjects:expectation1, nil] timeout:5.0f];
    
    // set and check dummy IFA
//    __block NSString *dummyIFA = @"32132132-3213-3213-3213-321321321321";
//    [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:dummyIFA] advertisingTrackingEnabled:YES];
//
//    __block XCTestExpectation *expectation2 = [self expectationWithDescription:@"Dummy IFA found"];
//    [Tune registerDeeplinkListener:[[TuneDeeplinkerDelegate alloc] initWithBlock:^(BOOL success, NSString *deepLinkUrl) {
//        XCTAssertTrue(success);
//        [expectation2 fulfill];
//    }]];
//    [self waitForExpectationsWithTimeout:5.0f handler:^(NSError * _Nullable error) { }];
//
    

//    XCTAssertTrue([currentRequestUrl rangeOfString:([NSString stringWithFormat:@"%@", dummyIFA])].location != NSNotFound);
//
//    dummyIFA = @"11111111-2222-3333-4444-555555555555";
//
//    [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:dummyIFA] advertisingTrackingEnabled:YES];
//    [Tune registerDeeplinkListener:self];
//
//    waitFor1(1.0, &finished);
//
//    XCTAssertTrue(finished);
//    XCTAssertTrue([currentRequestUrl rangeOfString:([NSString stringWithFormat:@"%@", dummyIFA])].location != NSNotFound);
//
//    [Tune setShouldAutoCollectAppleAdvertisingIdentifier:YES];
//    [Tune registerDeeplinkListener:self];
//
//    waitFor1(1.0, &finished);
//
//    XCTAssertTrue(finished);
//    XCTAssertTrue([currentRequestUrl rangeOfString:([NSString stringWithFormat:@"%@", realIFA])].location != NSNotFound);
//
}

- (void)testCheckForDeferredDeepLinkDuplicate {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expectation that never fulfills..."];
    __block int callCount = 0;
    
    TuneDeeplinkerDelegate *delegate = [[TuneDeeplinkerDelegate alloc] initWithBlock:^(BOOL success, NSString *deepLinkUrl) {
        XCTAssertTrue(success);
        callCount++;
    }];
    
    // Only one call should come through
    [Tune registerDeeplinkListener:delegate];
    [Tune registerDeeplinkListener:delegate];
    [Tune registerDeeplinkListener:delegate];
    [Tune registerDeeplinkListener:delegate];
    
    XCTWaiterResult result = [XCTWaiter waitForExpectations:[NSArray arrayWithObjects:expectation, nil] timeout:4.0];
    XCTAssert(result == XCTWaiterResultTimedOut, @"Expecting timeout");
    XCTAssert(callCount == 1, @"Expecting only one call");
}

- (void)testIsTuneLinkForTlnkio {
    XCTAssertTrue([Tune isTuneLink:@"http://tlnk.io"]);
    XCTAssertTrue([Tune isTuneLink:@"http://12345.tlnk.io"]);
    XCTAssertTrue([Tune isTuneLink:@"http://tlnk.io/path/to/something?withargs=shorething&other=things"]);
    XCTAssertTrue([Tune isTuneLink:@"http://12345.tlnk.io/path/to/something?withargs=shorething&other=things"]);
    XCTAssertTrue([Tune isTuneLink:@"https://tlnk.io"]);
    XCTAssertTrue([Tune isTuneLink:@"https://12345.tlnk.io"]);
    XCTAssertTrue([Tune isTuneLink:@"https://tlnk.io/path/to/something?withargs=shorething&other=things"]);
    XCTAssertTrue([Tune isTuneLink:@"https://12345.tlnk.io/path/to/something?withargs=shorething&other=things"]);
    
    XCTAssertFalse([Tune isTuneLink:@"fake://tlnk.io"]);
    XCTAssertFalse([Tune isTuneLink:@"http://talink.io"]);
    XCTAssertFalse([Tune isTuneLink:@"http://foobar.com.nope"]);
    XCTAssertFalse([Tune isTuneLink:@"http://randomize.it"]);
    XCTAssertFalse([Tune isTuneLink:@"myapp://isthebest/yes/it/is"]);
}

- (void)testIsTuneLinkForBadValues {
    XCTAssertFalse([Tune isTuneLink:@"faketlnk.io"]);
    XCTAssertFalse([Tune isTuneLink:@"      nope      "]);
    XCTAssertFalse([Tune isTuneLink:@"http://"]);
    XCTAssertFalse([Tune isTuneLink:nil]);
    XCTAssertFalse([Tune isTuneLink:@"http://randomize.it   "]);
    XCTAssertFalse([Tune isTuneLink:@"      myapp://isthebest/yes/it/is"]);
}

- (void)testIsTuneLink {
    [Tune registerCustomTuneLinkDomain:@"foobar.com"];
    XCTAssertTrue([Tune isTuneLink:@"http://foobar.com"]);
    XCTAssertTrue([Tune isTuneLink:@"http://wow.foobar.com"]);
    XCTAssertTrue([Tune isTuneLink:@"http://foobar.com/path/to/something?withargs=shorething&other=things"]);
    XCTAssertTrue([Tune isTuneLink:@"http://wow.foobar.com/path/to/something?withargs=shorething&other=things"]);
    XCTAssertTrue([Tune isTuneLink:@"http://tlnk.io"]);
    XCTAssertTrue([Tune isTuneLink:@"http://12345.tlnk.io"]);
    XCTAssertTrue([Tune isTuneLink:@"http://tlnk.io/path/to/something?withargs=shorething&other=things"]);
    XCTAssertTrue([Tune isTuneLink:@"http://12345.tlnk.io/path/to/something?withargs=shorething&other=things"]);
    XCTAssertTrue([Tune isTuneLink:@"https://tlnk.io"]);
    XCTAssertTrue([Tune isTuneLink:@"https://12345.tlnk.io"]);
    XCTAssertTrue([Tune isTuneLink:@"https://tlnk.io/path/to/something?withargs=shorething&other=things"]);
    XCTAssertTrue([Tune isTuneLink:@"https://12345.tlnk.io/path/to/something?withargs=shorething&other=things"]);
    
    XCTAssertFalse([Tune isTuneLink:@"fake://tlnk.io"]);
    XCTAssertFalse([Tune isTuneLink:@"myapp://isthebest/yes/it/is"]);
    XCTAssertFalse([Tune isTuneLink:@"http://wow.foobarz.com"]);
    XCTAssertFalse([Tune isTuneLink:@"http://foobar.co.uk"]);
    XCTAssertFalse([Tune isTuneLink:@"http://foobar.com.nope"]);
    XCTAssertFalse([Tune isTuneLink:@"http://randomize.it"]);
    XCTAssertFalse([Tune isTuneLink:@"http://foobar.co.uk/path/to/something/?withfakearg=foobar.com"]);
    XCTAssertFalse([Tune isTuneLink:@"http://wow.foobarz.com/path/to/something?withargs=shorething&other=things"]);
    XCTAssertFalse([Tune isTuneLink:@"http://foobar.co.uk/path/to/something?withargs=shorething&other=things"]);
    XCTAssertFalse([Tune isTuneLink:@"http://foobar.com.nope/path/to/something?withargs=shorething&other=things"]);
    XCTAssertFalse([Tune isTuneLink:@"http://randomize.it/path/to/something?withargs=shorething&other=things"]);
}

- (void)testRegisterManyTuneLinkDomains {
    [Tune registerCustomTuneLinkDomain:@"blah.org"];
    [Tune registerCustomTuneLinkDomain:@"taptap.it"];
    [Tune registerCustomTuneLinkDomain:@"my.veryspecial.link"];
    [Tune registerCustomTuneLinkDomain:@"foobar.com"];
    
    XCTAssertTrue([Tune isTuneLink:@"http://foobar.com"]);
    XCTAssertTrue([Tune isTuneLink:@"http://blah.org"]);
    XCTAssertTrue([Tune isTuneLink:@"http://taptap.it"]);
    XCTAssertTrue([Tune isTuneLink:@"http://my.veryspecial.link"]);
    XCTAssertTrue([Tune isTuneLink:@"http://wow.foobar.com"]);
    XCTAssertTrue([Tune isTuneLink:@"http://foobar.com/path/to/something?withargs=shorething&other=things"]);
    XCTAssertTrue([Tune isTuneLink:@"http://wow.foobar.com/path/to/something?withargs=shorething&other=things"]);
    XCTAssertTrue([Tune isTuneLink:@"http://tlnk.io"]);
    XCTAssertTrue([Tune isTuneLink:@"http://12345.tlnk.io"]);
    XCTAssertTrue([Tune isTuneLink:@"http://tlnk.io/path/to/something?withargs=shorething&other=things"]);
    XCTAssertTrue([Tune isTuneLink:@"http://12345.tlnk.io/path/to/something?withargs=shorething&other=things"]);
    XCTAssertTrue([Tune isTuneLink:@"https://tlnk.io"]);
    XCTAssertTrue([Tune isTuneLink:@"https://12345.tlnk.io"]);
    XCTAssertTrue([Tune isTuneLink:@"https://tlnk.io/path/to/something?withargs=shorething&other=things"]);
    
    XCTAssertFalse([Tune isTuneLink:@"myapp://isthebest/yes/it/is"]);
    XCTAssertFalse([Tune isTuneLink:@"http://wow.foobarz.com"]);
    XCTAssertFalse([Tune isTuneLink:@"http://foobar.co.uk"]);
    XCTAssertFalse([Tune isTuneLink:@"http://foobar.com.nope"]);
    XCTAssertFalse([Tune isTuneLink:@"http://randomize.it"]);
    XCTAssertFalse([Tune isTuneLink:@"http://foobar.co.uk/path/to/something/?withfakearg=foobar.com"]);
    XCTAssertFalse([Tune isTuneLink:@"http://wow.foobarz.com/path/to/something?withargs=shorething&other=things"]);
    XCTAssertFalse([Tune isTuneLink:@"http://foobar.co.uk/path/to/something?withargs=shorething&other=things"]);
    XCTAssertFalse([Tune isTuneLink:@"http://foobar.com.nope/path/to/something?withargs=shorething&other=things"]);
    XCTAssertFalse([Tune isTuneLink:@"http://randomize.it/path/to/something?withargs=shorething&other=things"]);
}

- (void)testIsInvokeUrlInReferralUrl {
    NSString *expectedInvokeUrl = @"testapp://path/to/a/thing?with=yes&params=ok";
    NSString *invokeUrl = [TuneDeeplinker invokeUrlFromReferralUrl:@"https://12sfci8ss.tlnk.io/something?withparams=yes&invoke_url=testapp%3A%2F%2Fpath%2Fto%2Fa%2Fthing%3Fwith%3Dyes%26params%3Dok&seomthingelse=2"];
    
    XCTAssertTrue([invokeUrl isEqualToString:expectedInvokeUrl]);
}

- (void)testIsInvokeUrlInReferralUrlWhenNotPresent {
    XCTAssertNil([TuneDeeplinker invokeUrlFromReferralUrl:@"https://12sfci8ss.tlnk.io/something?withparams=yes&seomthingelse=2"]);
    XCTAssertNil([TuneDeeplinker invokeUrlFromReferralUrl:nil]);
    XCTAssertNil([TuneDeeplinker invokeUrlFromReferralUrl:@""]);
    XCTAssertNil([TuneDeeplinker invokeUrlFromReferralUrl:@"somestringnoturl"]);
}

- (void)testHandleOpenURLShortcutsIfInvokeUrlPresent {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expectation that never fulfills..."];
    
    // delegate callback values
    NSString *expectedInvokeUrl = @"testapp://path/to/a/thing?with=yes&params=ok";
    __block NSString *deepLinkReceived;
    __block int callCount = 0;

    TuneDeeplinkerDelegate *delegate = [[TuneDeeplinkerDelegate alloc] initWithBlock:^(BOOL success, NSString *deepLinkUrl) {
        XCTAssertTrue(success);
        callCount++;

        XCTAssertNotNil(deepLinkUrl, @"deeplink is nil");
        deepLinkReceived = deepLinkUrl;
    }];
    
    // intial call, should not match the expected deeplink url
    [Tune registerDeeplinkListener:delegate];
    XCTWaiterResult resultA = [XCTWaiter waitForExpectations:[NSArray arrayWithObjects:expectation, nil] timeout:1.0];
    XCTAssert(resultA == XCTWaiterResultTimedOut, @"Expected timeout did not happen");
    XCTAssert(callCount == 1, @"Did not recieve callback for registerDeeplinkListener");
    XCTAssertFalse([deepLinkReceived isEqualToString:expectedInvokeUrl], @"deeplink %@ matches %@", deepLinkReceived, expectedInvokeUrl);

    // second call, should match the expected deeplink url
    [Tune handleOpenURL:[NSURL URLWithString:@"https://877.tlnk.io/serve?action=click&publisher_id=169564&site_id=47548&invoke_url=testapp%3A%2F%2Fpath%2Fto%2Fa%2Fthing%3Fwith%3Dyes%26params%3Dok"] options:@{}];
    waitForQueuesToFinish();
    XCTWaiterResult resultB = [XCTWaiter waitForExpectations:[NSArray arrayWithObjects:expectation, nil] timeout:1.0];
    XCTAssert(resultB == XCTWaiterResultTimedOut, @"Expected timeout did not happen");
    XCTAssert(callCount == 2, @"Did not recieve callback for handleOpenURL");
    XCTAssertTrue([deepLinkReceived isEqualToString:expectedInvokeUrl], @"deeplink %@ did not match %@", deepLinkReceived, expectedInvokeUrl);
}

- (void)testHandleOpenURLDoesNotShortcutIfNoInvokeUrlParameter {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expectation that never fulfills..."];
    
    // delegate callback values
    NSString *expectedInvokeUrl = @"iosunittest://";
    __block NSString *deepLinkReceived;
    __block int callCount = 0;
    
    TuneDeeplinkerDelegate *delegate = [[TuneDeeplinkerDelegate alloc] initWithBlock:^(BOOL success, NSString *deepLinkUrl) {
        XCTAssertTrue(success);
        callCount++;
        
        XCTAssertNotNil(deepLinkUrl, @"deeplink is nil");
        deepLinkReceived = deepLinkUrl;
    }];
    
    // intial call
    [Tune registerDeeplinkListener:delegate];
    XCTWaiterResult resultA = [XCTWaiter waitForExpectations:[NSArray arrayWithObjects:expectation, nil] timeout:1.0];
    XCTAssert(resultA == XCTWaiterResultTimedOut, @"Expected timeout did not happen");
    XCTAssert(callCount == 1, @"Did not recieve callback for registerDeeplinkListener");

    // second call, should contain the expected deeplink url
    [Tune handleOpenURL:[NSURL URLWithString:@"https://877.tlnk.io/serve?action=click&publisher_id=169564&site_id=47548&invoke_id=279839"] options:@{}];
    waitForQueuesToFinish();
    XCTWaiterResult resultB = [XCTWaiter waitForExpectations:[NSArray arrayWithObjects:expectation, nil] timeout:1.0];
    XCTAssert(resultB == XCTWaiterResultTimedOut, @"Expected timeout did not happen");
    XCTAssert(callCount == 2, @"Did not recieve callback for handleOpenURL");
    XCTAssertTrue([deepLinkReceived containsString:expectedInvokeUrl], @"deeplink %@ did not contain %@", deepLinkReceived, expectedInvokeUrl);
}

- (void)testHandleContinueUserActivityCallsHandleOpenURLCorrectly {
    
    // test is only valid for newer devices
    if (![TuneDeviceDetails appIsRunningIniOS9OrAfter]) {
        return;
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Expectation that never fulfills..."];
    __block int callCount = 0;
    
    TuneDeeplinkerDelegate *delegate = [[TuneDeeplinkerDelegate alloc] initWithBlock:^(BOOL success, NSString *deepLinkUrl) {
        XCTAssertTrue(success);
        callCount++;
    }];
    
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = [NSURL URLWithString:@"https://www.tune.com"];

    [Tune registerDeeplinkListener:delegate];
    [Tune handleContinueUserActivity:activity restorationHandler:^(NSArray * restorableObjects) {}];
    waitForQueuesToFinish();
    
    XCTWaiterResult resultA = [XCTWaiter waitForExpectations:[NSArray arrayWithObjects:expectation, nil] timeout:1.0];
    XCTAssert(resultA == XCTWaiterResultTimedOut, @"Expected timeout did not happen");
    XCTAssert(callCount == 1, @"Did not recieve callback for registerDeeplinkListener");
    XCTAssertTrue([[[TuneManager currentManager].userProfile referralUrl] isEqualToString:@"https://www.tune.com"]);
    XCTAssertTrue([[[TuneManager currentManager].userProfile referralSource] isEqualToString:@"web"]);
}

- (void)testHandleOpenURLReturnsYesWithInvokeUrl {
    BOOL handledByTune = [Tune handleOpenURL:[NSURL URLWithString:@"tune://?invoke_url=something"] options:@{}];
    XCTAssertTrue(handledByTune);
}

- (void)testHandleOpenURLReturnsNoWithoutInvokeUrl {
    BOOL handledByTune = [Tune handleOpenURL:[NSURL URLWithString:@"tune://"] options:@{}];
    XCTAssertFalse(handledByTune);
}

- (void)testHandleContinueUserActivityReturnsNoWithNonTlnkDomain {
    if ([TuneDeviceDetails appIsRunningIniOS9OrAfter]) {
        NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
        activity.webpageURL = [NSURL URLWithString:@"https://tune.com"];

        BOOL handledByTune = [Tune handleContinueUserActivity:activity restorationHandler:^(NSArray * restorableObjects) {}];
        
        XCTAssertFalse(handledByTune);
    }
}

- (void)testHandleContinueUserActivityReturnsYesWithTlnkDomain {
    if ([TuneDeviceDetails appIsRunningIniOS9OrAfter]) {
        NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
        activity.webpageURL = [NSURL URLWithString:@"https://tlnk.io"];
        
        BOOL handledByTune = [Tune handleContinueUserActivity:activity restorationHandler:^(NSArray * restorableObjects) {}];
        XCTAssertTrue(handledByTune);
    }
}

@end
