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

@interface TuneDeferredDplinkrTests : XCTestCase <TuneDelegate>
{
    BOOL finished;
    
    TuneDeepLinkError deepLinkErrorCode;
}
@end

@implementation TuneDeferredDplinkrTests

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
    
    finished = NO;
}

- (void)testCheckForDeferredDeepLinkMissingIdentifier {
    [Tune checkForDeferredDeeplink:self];
    
    waitFor(0.1);
    
    XCTAssertEqual(TuneDeepLinkErrorMissingIdentifiers, deepLinkErrorCode);
    
    XCTAssertTrue(finished);
}

- (void)testCheckForDeferredDeepLinkDuplicate {
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey];
    
    [Tune checkForDeferredDeeplink:self];
    
    waitFor1(5.0, &finished);
    
    XCTAssertTrue(finished);
    
    finished = false;
    
    [Tune checkForDeferredDeeplink:self];
    
    waitFor1(5.0, &finished);
    
    XCTAssertEqual(TuneDeepLinkErrorDuplicateCall, deepLinkErrorCode);
    
    XCTAssertTrue(finished);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - TuneDelegate Methods

-(void)tuneDidFailDeeplinkWithError:(NSError *)error {
    finished = YES;
    
    deepLinkErrorCode = (TuneDeepLinkError)error.code;
}

-(void)tuneDidReceiveDeeplink:(NSString *)deeplink {
    finished = YES;
}

@end
