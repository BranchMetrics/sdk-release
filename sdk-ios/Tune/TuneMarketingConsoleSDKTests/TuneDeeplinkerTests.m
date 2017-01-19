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
#import "NSURLSession+SynchronousTask.h"

@import AdSupport;

@interface TuneDeeplinkerTests : TuneXCTestCase <TuneDelegate> {
    BOOL finished;
    BOOL defDeepLinkReceived;
    NSString *deepLinkReceived;
    
    TuneDeepLinkError deepLinkErrorCode;
    
    NSString *currentIfa;
    NSString *currentRequestUrl;
    
    id classMockHttpUtils;
}
@end

@implementation TuneDeeplinkerTests

- (void)setUp {
    [super setUp];
    
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId wearable:NO];
    
    defDeepLinkReceived = NO;
    finished = NO;
    deepLinkReceived = nil;
    currentRequestUrl = nil;
}

- (void)tearDown {
    [Tune registerDeeplinkListener:nil];
    
    [super tearDown];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)testLegacyCheckForDeferredDeepLinkSuccess {
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
#pragma clang diagnostic pop

- (void)testCheckForDeferredDeepLinkSuccess {
    NSString *dummyIFA = @"12345678-1234-1234-1234-123456789012";
    NSString *measurementUrl = [NSString stringWithFormat:@"https://169564.measurementapi.com/serve?action=click&publisher_id=169564&site_id=47548&invoke_id=279839&ad_id=%@", dummyIFA];
    
    NSURLResponse *resp;
    NSError *error;
    [[NSURLSession sharedSession] sendSynchronousDataTaskWithURL:[NSURL URLWithString:measurementUrl] returningResponse:&resp error:&error];
    
    [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:dummyIFA] advertisingTrackingEnabled:YES];
    [Tune registerDeeplinkListener:self];
    
    waitFor1(1.0, &finished);
    XCTAssertTrue(finished);
    XCTAssertTrue(defDeepLinkReceived);
}

- (void)testSetterUpdatedIFAIsUsedByDeferredDeepLinker {
    NSString *realIFA = [[ASIdentifierManager sharedManager] advertisingIdentifier].UUIDString;
    
    [Tune setShouldAutoCollectAppleAdvertisingIdentifier:YES];
    [Tune registerDeeplinkListener:self];
    
    waitFor1(1.0, &finished);
    
    XCTAssertTrue(finished);
    XCTAssertTrue([currentRequestUrl rangeOfString:([NSString stringWithFormat:@"%@", realIFA])].location != NSNotFound);
    
    NSString *dummyIFA = @"32132132-3213-3213-3213-321321321321";
    
    [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:dummyIFA] advertisingTrackingEnabled:YES];
    [Tune registerDeeplinkListener:self];
    
    waitFor1(1.0, &finished);
    
    XCTAssertTrue(finished);
    XCTAssertTrue([currentRequestUrl rangeOfString:([NSString stringWithFormat:@"%@", dummyIFA])].location != NSNotFound);
    
    dummyIFA = @"11111111-2222-3333-4444-555555555555";
    
    [Tune setAppleAdvertisingIdentifier:[[NSUUID alloc] initWithUUIDString:dummyIFA] advertisingTrackingEnabled:YES];
    [Tune registerDeeplinkListener:self];
    
    waitFor1(1.0, &finished);
    
    XCTAssertTrue(finished);
    XCTAssertTrue([currentRequestUrl rangeOfString:([NSString stringWithFormat:@"%@", dummyIFA])].location != NSNotFound);
    
    [Tune setShouldAutoCollectAppleAdvertisingIdentifier:YES];
    [Tune registerDeeplinkListener:self];
    
    waitFor1(1.0, &finished);
    
    XCTAssertTrue(finished);
    XCTAssertTrue([currentRequestUrl rangeOfString:([NSString stringWithFormat:@"%@", realIFA])].location != NSNotFound);
}

- (void)testCheckForDeferredDeepLinkDuplicate {
    [Tune registerDeeplinkListener:self];
    
    waitFor1(1.0, &finished);
    
    XCTAssertTrue(finished);
    
    finished = false;
    
    // Second call should fail silently
    [Tune registerDeeplinkListener:self];
    
    waitFor1(1.0, &finished);
    
    XCTAssertFalse(finished);
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
    NSString *expectedInvokeUrl = @"testapp://path/to/a/thing?with=yes&params=ok";
    
    [Tune registerDeeplinkListener:self];
    waitFor1(1, &finished);
    
    [Tune handleOpenURL:[NSURL URLWithString:@"https://877.tlnk.io/serve?action=click&publisher_id=169564&site_id=47548&invoke_url=testapp%3A%2F%2Fpath%2Fto%2Fa%2Fthing%3Fwith%3Dyes%26params%3Dok"] options:@{}];
    waitForQueuesToFinish();
    waitFor1(TUNE_SESSION_QUEUING_DELAY + 0.1, &finished);
    
    XCTAssertTrue([deepLinkReceived isEqualToString:expectedInvokeUrl], @"deeplink %@ did not match %@", deepLinkReceived, expectedInvokeUrl);
    XCTAssertTrue(finished);
}

- (void)testHandleOpenURLDoesNotShortcutIfNoInvokeUrlParameter {
    NSString *expectedInvokeUrl = @"iosunittest://";
    
    [Tune registerDeeplinkListener:self];
    waitFor1(1, &finished);
    
    [Tune handleOpenURL:[NSURL URLWithString:@"https://877.tlnk.io/serve?action=click&publisher_id=169564&site_id=47548&invoke_id=279839"] options:@{}];
    waitForQueuesToFinish();
    waitFor1(TUNE_SESSION_QUEUING_DELAY + 0.1, &finished);
    
    XCTAssertTrue([deepLinkReceived containsString:expectedInvokeUrl], @"deeplink %@ did not contain %@", deepLinkReceived, expectedInvokeUrl);
    XCTAssertTrue(finished);
}

- (void)testHandleContinueUserActivityCallsHandleOpenURLCorrectly {
    if ([TuneDeviceDetails appIsRunningIniOS9OrAfter]) {
        NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
        activity.webpageURL = [NSURL URLWithString:@"https://www.tune.com"];
        
        [Tune registerDeeplinkListener:self];
        
        [Tune handleContinueUserActivity:activity restorationHandler:^(NSArray * restorableObjects) {}];
        
        waitForQueuesToFinish();
        waitFor1(TUNE_SESSION_QUEUING_DELAY + 0.1, &finished);
        
        XCTAssertTrue([[[TuneManager currentManager].userProfile referralUrl] isEqualToString:@"https://www.tune.com"]);
        XCTAssertTrue([[[TuneManager currentManager].userProfile referralSource] isEqualToString:@"web"]);
    }
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


#pragma mark - TuneDelegate Methods

-(void)tuneDidFailDeeplinkWithError:(NSError *)error {
    finished = YES;
    deepLinkErrorCode = (TuneDeepLinkError)error.code;
    
    currentRequestUrl = error.userInfo[@"request_url"];
}

-(void)tuneDidReceiveDeeplink:(NSString *)deeplink {
    finished = YES;
    defDeepLinkReceived = YES;
    
    deepLinkReceived = deeplink;
}

@end
