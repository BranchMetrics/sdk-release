//
//  TuneDelegateTests.m
//  TuneTests
//
//  Created by Ernest Cho on 11/17/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSURLSession+TuneDelegateMockServer.h"
#import "Tune.h"

typedef void(^TuneDelegateTestsCallbackBlock)(NSError *error, NSString *request, NSString *response);

// utility class so we can use the TuneDelegate like a callback block
@interface TuneDelegateTestsDelegate : NSObject <TuneDelegate>
@property (nonatomic, copy, readwrite) TuneDelegateTestsCallbackBlock block;
@end

@implementation TuneDelegateTestsDelegate

- (instancetype)initWithBlock:(TuneDelegateTestsCallbackBlock)block {
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

- (void)tuneDidSucceedWithData:(NSData *)data {
    if (self.block) {
        NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        self.block(nil, nil, response);
    }
}

- (void)tuneDidFailWithError:(NSError *)error {
    if (self.block) {
        self.block(error, nil, nil);
    }
}

- (void)tuneDidFailWithError:(NSError *)error request:(NSString *)request response:(NSString *)response {
    if (self.block) {
        self.block(error, request, response);
    }
}

@end

@interface TuneDelegateTests : XCTestCase

@end

// Low level tests to verify TuneDelegate behavior
// These tests are not designed to be run as unit tests!  They depend on our test server and they do not reset the Tune singletons in between runs, so tests must run individually!
@implementation TuneDelegateTests

+ (void)setUp {
    [Tune initializeWithTuneAdvertiserId:kTestAdvertiserId tuneConversionKey:kTestConversionKey tunePackageName:kTestBundleId wearable:NO];
}

+ (void)tearDown {
    
}

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

// control test, no mock server
- (void)testMeasureSession {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Network call completed"];
    
    TuneDelegateTestsDelegate *delegate = [[TuneDelegateTestsDelegate alloc] initWithBlock:^(NSError *error, NSString *request, NSString *response) {
        if (response && [response containsString:@"{\"success\":true,\"tracking_id\""]) {
            
            [expectation fulfill];
        }
    }];
    
    // Trigger a measure session
    [Tune setDelegate:delegate];
    [Tune measureSession];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        // Tune crashes when the test finishes and the delegate gets ARC'd.
        [Tune setDelegate:nil];
    }];
}

- (void)testMeasureSessionNoData {
    [NSURLSession swizzleDataTaskToReturnNoData];

    __block XCTestExpectation *expectationOld = [self expectationWithDescription:@"Old delegate error method called"];
    __block XCTestExpectation *expectationNew = [self expectationWithDescription:@"New delegate error method called"];
    
    TuneDelegateTestsDelegate *delegate = [[TuneDelegateTestsDelegate alloc] initWithBlock:^(NSError *error, NSString *request, NSString *response) {
        
        if (error && [error.debugDescription containsString:@"tune_error_server_error"]) {
            
            if ([request containsString:@"engine.mobileapptracking.com"]) {
                [expectationNew fulfill];
            } else if (!request) {
                [expectationOld fulfill];
            }
        }
    }];

    [Tune setDelegate:delegate];
    [Tune measureSession];

    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        // Tune crashes when the test finishes and the delegate gets ARC'd.  Set it to nil.
        [Tune setDelegate:nil];
        [NSURLSession unswizzleDataTaskToReturnNoData];
    }];
}

- (void)testMeasureSessionHttp400 {
    [NSURLSession swizzleDataTaskToHttp400];
    
    __block XCTestExpectation *expectationOld = [self expectationWithDescription:@"Old delegate error method called"];
    __block XCTestExpectation *expectationNew = [self expectationWithDescription:@"New delegate error method called"];

    TuneDelegateTestsDelegate *delegate = [[TuneDelegateTestsDelegate alloc] initWithBlock:^(NSError *error, NSString *request, NSString *response) {
        
        if (error && [error.debugDescription containsString:@"HTTP 400/Bad Request"]) {
            
            if ([request containsString:@"engine.mobileapptracking.com"]) {
                [expectationNew fulfill];
            } else if (!request) {
                [expectationOld fulfill];
            }
        }
    }];
    
    [Tune setDelegate:delegate];
    [Tune measureSession];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        // Tune crashes when the test finishes and the delegate gets ARC'd.  Set it to nil.
        [Tune setDelegate:nil];
        [NSURLSession unswizzleDataTaskToHttp400];
    }];
}

- (void)testMeasureSessionHttpError {
    [NSURLSession swizzleDataTaskToHttpError];
    
    __block XCTestExpectation *expectationOld = [self expectationWithDescription:@"Old delegate error method called"];
    __block XCTestExpectation *expectationNew = [self expectationWithDescription:@"New delegate error method called"];
    
    // current error handling implementation calls the delegate multiple times on HTTP error
    __block BOOL isFulfilledOld = NO;
    __block BOOL isFulfilledNew = NO;

    TuneDelegateTestsDelegate *delegate = [[TuneDelegateTestsDelegate alloc] initWithBlock:^(NSError *error, NSString *request, NSString *response) {
        
        // We get called twice with the same data on network error.  :/
        if (error && [error.debugDescription containsString:@"Error Domain=NSURLErrorDomain Code=-1004"]) {
            
            if ([request containsString:@"engine.mobileapptracking.com"]) {
                @synchronized(expectationNew) {
                    if (!isFulfilledNew) {
                        isFulfilledNew = YES;
                        [expectationNew fulfill];
                    }
                }
            } else if (!request) {
                @synchronized(expectationOld) {
                    if (!isFulfilledOld) {
                        isFulfilledOld = YES;
                        [expectationOld fulfill];
                    }
                }
            }
        }
    }];
    
    [Tune setDelegate:delegate];
    [Tune measureSession];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        // Tune crashes when the test finishes and the delegate gets ARC'd.  Set it to nil.
        [Tune setDelegate:nil];
        [NSURLSession unswizzleDataTaskToHttpError];
    }];
}

@end
