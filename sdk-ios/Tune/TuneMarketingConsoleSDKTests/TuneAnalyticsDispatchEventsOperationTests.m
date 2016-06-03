//
//  TuneAnalyticsEventDispatchOperationTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/14/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Tune+Testing.h"
#import "TuneFileManager.h"
#import "TuneFileUtils.h"
#import "TunePlaylistManager+Testing.h"
#import "TuneUserProfile.h"
#import "TuneManager+Testing.h"
#import "TuneAnalyticsDispatchEventsOperation.h"
#import "NSData+TuneGZIP.h"
#import "NSURLRequest+TuneUtils.h"
#import "TuneHttpUtils.h"
#import "TuneJSONUtils.h"
#import "TuneAnalyticsEvent.h"
#import "TuneConfiguration+Testing.h"
#import "TuneAnalyticsManager.h"
#import "TuneXCTestCase.h"

@interface TuneAnalyticsDispatchEventsOperationsTest : TuneXCTestCase
{
    TuneFileManager *fileManager;
    TuneConfiguration *configuration;
    TuneUserProfile *userProfile;
    
    id httpMock;
    id mockApplication;
    
    NSURLRequest *expectedRequest;
    
    NSURLRequest *receivedRequest;
    id mockResponseReference;
    id mockErrorReference;
    NSData *mockResponse;
    
    BOOL returnError;
    
    UIBackgroundTaskIdentifier dispatchBgTask;
    NSOperationQueue *trackEventOpQueue;
}
@end

@implementation TuneAnalyticsDispatchEventsOperationsTest

- (void)setUp {
    [super setUpWithMocks:@[[TunePlaylistManager class]]];

    // This suite expects nothing else running in the background
    [TuneManager nilModules];
    
    mockApplication = OCMClassMock([UIApplication class]);
    OCMStub(ClassMethod([mockApplication sharedApplication])).andReturn(mockApplication);
    
    configuration = [[TuneConfiguration alloc] initWithTuneManager:[TuneManager currentManager]];
    [[TuneManager currentManager] setConfiguration:configuration];
    pointMAUrlsToNothing();
    
    TuneAnalyticsManager *anyManager = [[TuneAnalyticsManager alloc] initWithTuneManager:[TuneManager currentManager]];
    [[TuneManager currentManager] setAnalyticsManager:anyManager];
    
    userProfile = [[TuneUserProfile alloc] initWithTuneManager:[TuneManager currentManager]];
    userProfile.advertiserId = @"advertiserId";
    userProfile.tuneId = @"something";
    [[TuneManager currentManager] setUserProfile:userProfile];
    
    if (trackEventOpQueue == nil) {
        trackEventOpQueue = [NSOperationQueue new];
        [trackEventOpQueue setMaxConcurrentOperationCount:1];
    }
    
    dispatchBgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        // Should never be called.
    }];
    
    mockResponse = [[NSData alloc] init];
    httpMock = OCMClassMock([TuneHttpUtils class]);
    returnError = NO;
    OCMStub(ClassMethod([httpMock sendSynchronousRequest:[OCMArg any]
                                                response:[OCMArg setTo:mockResponseReference]
                                                   error:[OCMArg setTo:mockErrorReference]])).andCall(self, @selector(mockHttpRequest:response:error:));
}

- (void)tearDown {
    trackEventOpQueue = nil;
    mockResponse = nil;
    mockResponseReference = nil;
    mockErrorReference = nil;
    
    [mockApplication stopMocking];
    [httpMock stopMocking];
    
    [configuration unregisterSkyhooks];
    configuration = nil;
    
    [userProfile unregisterSkyhooks];
    userProfile = nil;
    
    [super tearDown];
}

- (void)testBasicAnalyticsEventDispatch {
    TuneAnalyticsDispatchEventsOperation *testOperation = [[TuneAnalyticsDispatchEventsOperation alloc] initWithTuneManager:[TuneManager currentManager]];
    testOperation.includeTracer = NO;
    
    NSDictionary *batchDictionary = @{ @"1439486620-a" : @"{ json: \"string\", json2: intvalue }",
                                       @"1439486759-b" : @"{ json: \"string1\", json2: intvalue2 }",
                                       @"1439486810-c" : @"{ json: \"string2\", json2: intvalue3 }"
                                       };
    
    NSString *expectedPayload = @"{ \"events\": [{ json: \"string2\", json2: intvalue3 },{ json: \"string\", json2: intvalue },{ json: \"string1\", json2: intvalue2 }]}";
    NSDictionary *expectedRemainingDictionary = @{};
    
    expectedRequest = [self buildExpectedURLRequest:expectedPayload
                                                url:[NSURL URLWithString:configuration.analyticsHostPort]
                                              appId:userProfile.hashedAppId
                                           deviceId:userProfile.deviceId];
    
    [TuneFileManager saveAnalyticsToDisk:batchDictionary];
    [trackEventOpQueue addOperation:testOperation];
    [trackEventOpQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertTrue([receivedRequest tuneIsEqualToNSURLRequest:expectedRequest]);
    
    NSDictionary *remainingAnalytics = [TuneFileManager loadAnalyticsFromDisk];
    XCTAssertTrue([[remainingAnalytics description] isEqualToString:[expectedRemainingDictionary description]]);
    
    OCMVerify([httpMock sendSynchronousRequest:[OCMArg any]
                                      response:[OCMArg setTo:mockResponseReference]
                                         error:[OCMArg setTo:mockErrorReference]]);
}

- (void)testBasicAnalyticsEventDispatchWithTracer {
    TuneAnalyticsEvent *expectedTracer = [[TuneAnalyticsEvent alloc] initAsTracerEvent];
    NSDate *constantDate = [NSDate date];
    expectedTracer.timestamp = constantDate;
    
    id mockDate = OCMClassMock([NSDate class]);
    [OCMStub([mockDate date]) andReturn:constantDate];
    
    TuneAnalyticsDispatchEventsOperation *testOperation = [[TuneAnalyticsDispatchEventsOperation alloc] initWithTuneManager:[TuneManager currentManager]];
    
    NSDictionary *batchDictionary = @{ @"1439486620-a" : @"{ json: \"string\", json2: intvalue }",
                                       @"1439486759-b" : @"{ json: \"string1\", json2: intvalue2 }"};
    
    NSString *expectedPayload = [NSString stringWithFormat:@"{ \"events\": [{ json: \"string\", json2: intvalue },{ json: \"string1\", json2: intvalue2 },%@]}", [TuneJSONUtils createJSONStringFromDictionary:[expectedTracer toDictionary]]];
    NSDictionary *expectedRemainingDictionary = @{};
    
    expectedRequest = [self buildExpectedURLRequest:expectedPayload
                                                url:[NSURL URLWithString:configuration.analyticsHostPort]
                                              appId:userProfile.hashedAppId
                                           deviceId:userProfile.deviceId];
    
    [TuneFileManager saveAnalyticsToDisk:batchDictionary];
    [trackEventOpQueue addOperation:testOperation];
    [trackEventOpQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertTrue([receivedRequest tuneIsEqualToNSURLRequest:expectedRequest]);
    
    NSDictionary *remainingAnalytics = [TuneFileManager loadAnalyticsFromDisk];
    XCTAssertTrue([[remainingAnalytics description] isEqualToString:[expectedRemainingDictionary description]]);
    
    OCMVerify([httpMock sendSynchronousRequest:[OCMArg any]
                                      response:[OCMArg setTo:mockResponseReference]
                                         error:[OCMArg setTo:mockErrorReference]]);
    [mockDate stopMocking];
}

- (void)testFailedAnalyticsEventDispatch {
    TuneAnalyticsDispatchEventsOperation *testOperation = [[TuneAnalyticsDispatchEventsOperation alloc] initWithTuneManager:[TuneManager currentManager]];
    
    NSDictionary *batchDictionary = @{ @"1439486620-a" : @"{ json: \"string\", json2: intvalue }",
                                       @"1439486759-b" : @"{ json: \"string1\", json2: intvalue2 }"};
    
    [TuneFileManager saveAnalyticsToDisk:batchDictionary];
    
    // Set the HTTP request to return an error.  This means that we should keep the submitted analytics around.
    returnError = YES;
    [trackEventOpQueue addOperation:testOperation];
    [trackEventOpQueue waitUntilAllOperationsAreFinished];
    
    NSDictionary *remainingAnalytics = [TuneFileManager loadAnalyticsFromDisk];
    XCTAssertTrue([[remainingAnalytics description] isEqualToString:[batchDictionary description]]);
    
    OCMVerify([httpMock sendSynchronousRequest:[OCMArg any]
                                      response:[OCMArg setTo:mockResponseReference]
                                         error:[OCMArg setTo:mockErrorReference]]);
}

- (NSURLRequest *)buildExpectedURLRequest:(NSString *)analyticsPayload url:(NSURL *)url appId:(NSString *)appId deviceId:(NSString *)deviceId {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"multipart/form-data; boundary=thisIsMyFileBoundary" forHTTPHeaderField: @"Content-Type"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    [request setValue:deviceId forHTTPHeaderField:@"X-ARTISAN-DEVICEID"];
    [request setValue:appId forHTTPHeaderField:@"X-ARTISAN-APPID"];
    
    NSString *postBodyHeader = @"--thisIsMyFileBoundary\r\nContent-Disposition: form-data; name=\"analytics\"; filename=\"analytics.gzip\"\r\nContent-Type: application/gzip\r\n\r\n";
    NSData *zippedData = [[analyticsPayload dataUsingEncoding:NSUTF8StringEncoding] tuneGzippedData];
    NSString *postBodyFooter = @"\r\n--thisIsMyFileBoundary--\r\n";
    
    NSMutableData *postBody = [[NSMutableData alloc] init];
    [postBody appendData:[postBodyHeader dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:zippedData];
    [postBody appendData:[postBodyFooter dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:postBody];
    
    return request;
}

- (NSData *)mockHttpRequest:(NSURLRequest *)request response:(NSURLResponse **)response error:(NSError **)error {
    receivedRequest = request;
    
    if (error != NULL) {
        *error = returnError ? [NSError errorWithDomain:@"TuneTestsMock" code:-1 userInfo:nil] : nil;
    }
    
    return [[NSData alloc] init];
}

@end
