//
//  TuneLogTests.m
//  TuneTests
//
//  Created by Jennifer Owens on 6/27/18.
//  Copyright © 2018 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Tune.h"
#import "TuneLog.h"

@interface TuneLogTests : XCTestCase

@end

@implementation TuneLogTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    TuneLog.shared.verbose = NO;
    TuneLog.shared.logBlock = nil;
    
    [super tearDown];
}

- (void)testVerboseIsNO {
    TuneLog *tuneLog = [TuneLog new];
    
    XCTAssertEqual(tuneLog.verbose, NO);
}

- (void)testVerboseChangesToYES {
    TuneLog *tuneLog = [TuneLog new];
    tuneLog.verbose = YES;
    
    XCTAssertEqual(tuneLog.verbose, YES);
}

- (void)testVerboseChangesToYESThenNO {
    TuneLog *tuneLog = [TuneLog new];
    
    tuneLog.verbose = YES;
    XCTAssertEqual(tuneLog.verbose, YES);
    
    tuneLog.verbose = NO;
    XCTAssertEqual(tuneLog.verbose, NO);
}

- (void)testNilMessage {
    TuneLog *tuneLog = [TuneLog new];
    
    tuneLog.logBlock = ^(NSString *message) {
        XCTFail(@"Nil message should not be called");
    };
    
    [tuneLog logError:nil];
}

- (void)testLogErrorWithVerboseNO {
    __block NSString *expectedErrorString = @"Expected error string";
    
    TuneLog *tuneLog = [TuneLog new];
    
    tuneLog.logBlock = ^(NSString *message) {
        XCTAssert([expectedErrorString isEqualToString:message]);
    };
    
    [tuneLog logError:expectedErrorString];
}

- (void)testLogErrorWithVerboseYES {
    __block NSString *expectedErrorString = @"Expected error string";
    
    TuneLog *tuneLog = [TuneLog new];
    tuneLog.verbose = YES;
    
    tuneLog.logBlock = ^(NSString *message) {
        XCTAssert([expectedErrorString isEqualToString:message]);
    };
    
    [tuneLog logError:expectedErrorString];
}

- (void)testLogVerboseWithVerboseYES {
    __block NSString *expectedVerboseString = @"Expected verbose string";
    
    TuneLog *tuneLog = [TuneLog new];
    tuneLog.verbose = YES;
    
    tuneLog.logBlock = ^(NSString *message) {
        XCTAssert([expectedVerboseString isEqualToString:message]);
    };
    
    [tuneLog logVerbose:expectedVerboseString];
}

- (void)testLogVerboseWithVerboseNO {
    __block NSString *notExpectedVerboseString = @"Not expected verbose string";
    
    TuneLog *tuneLog = [TuneLog new];
    tuneLog.logBlock = ^(NSString *message) {
        XCTFail(@"Verbose block should not be called");
    };
    
    [tuneLog logVerbose:notExpectedVerboseString];
}

- (void)testAllLogsWithVerboseNO {
    __block NSString *expectedErrorString = @"Expected error string";
    __block NSString *notExpectedVerboseString = @"Not expected verbose string";
    __block int errorCount = 0;
    
    TuneLog *tuneLog = [TuneLog new];
    tuneLog.logBlock = ^(NSString *message) {
        if ([message isEqualToString:expectedErrorString]) {
            errorCount += 1;
            XCTAssert([expectedErrorString isEqualToString:message]);
        } else {
            XCTFail(@"Did not receive expected message");
        }
    };
    
    [tuneLog logError:expectedErrorString];
    [tuneLog logVerbose:notExpectedVerboseString];
    
    XCTAssertEqual(errorCount, 1);
}

- (void)testAllLogsWithVerboseYES {
    __block NSString *expectedErrorString = @"Expected error string";
    __block NSString *expectedVerboseString = @"Expected verbose string";
    __block int errorCount = 0;
    __block int verboseCount = 0;
    
    TuneLog *tuneLog = [TuneLog new];
    tuneLog.verbose = YES;
    
    tuneLog.logBlock = ^(NSString *message) {
        if ([message isEqualToString:expectedErrorString]) {
            errorCount += 1;
            XCTAssert([expectedErrorString isEqualToString:message]);
        } else if ([message isEqualToString:expectedVerboseString]) {
            verboseCount += 1;
            XCTAssert([expectedVerboseString isEqualToString:message]);
        } else {
            XCTFail(@"Unexpected message received");
        }
    };
    
    [tuneLog logError:expectedErrorString];
    [tuneLog logVerbose:expectedVerboseString];
    
    XCTAssertEqual(errorCount, 1);
    XCTAssertEqual(verboseCount, 1);
}

- (void)testEventCausesVerboseLogMessage {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Wait for log message"];
    
    TuneLog.shared.verbose = YES;
    TuneLog.shared.logBlock = ^(NSString *message) {
        XCTAssert([message containsString:@"site_event_name=EventCausesVerboseLogMessage"]);
        [expectation fulfill];
    };
    
    NSString* const kTestAdvertiserId = @"877";
    NSString* const kTestConversionKey = @"8c14d6bbe466b65211e781d62e301eec";
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey];
    [Tune measureEventName:@"EventCausesVerboseLogMessage"];
    
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
