//
//  TuneAnalyticsDispatchToConnectedModeOperationTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 10/1/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Tune+Testing.h"
#import "TuneFileManager.h"
#import "TuneFileUtils.h"
#import "TuneUserProfile.h"
#import "TuneManager+Testing.h"
#import "TuneAnalyticsDispatchToConnectedModeOperation.h"
#import "NSData+TuneGZIP.h"
#import "NSURLRequest+TuneUtils.h"
#import "TuneHttpUtils.h"
#import "TuneJSONUtils.h"
#import "TuneAnalyticsEvent.h"
#import "TuneConfiguration+Testing.h"
#import "TuneHttpRequest.h"
#import "TuneApi.h"
#import "TuneXCTestCase.h"

@interface TuneAnalyticsDispatchToConnectedModeOperationTests : TuneXCTestCase
{
    TuneConfiguration *configuration;
    TuneUserProfile *userProfile;
    
    id httpMock;
    id mockApplication;
    
    TuneHttpRequest *expectedRequest;
    NSURLRequest *receivedRequest;
    
    id mockResponseReference;
    id mockErrorReference;
    NSData *mockResponse;
    
    BOOL returnError;
    
    NSOperationQueue *sendConnectedEventOpQueue;
}
@end

@implementation TuneAnalyticsDispatchToConnectedModeOperationTests

- (void)setUp {
    [super setUp];
    
    // This suite expects nothing else running in the background
    [TuneManager nilModules];
    
    mockApplication = OCMClassMock([UIApplication class]);
    OCMStub(ClassMethod([mockApplication sharedApplication])).andReturn(mockApplication);
    
    configuration = [[TuneConfiguration alloc] initWithTuneManager:[TuneManager currentManager]];
    [[TuneManager currentManager] setConfiguration:configuration];
    pointMAUrlsToNothing();
    
    userProfile = [[TuneUserProfile alloc] initWithTuneManager:[TuneManager currentManager]];
    userProfile.advertiserId = @"advertiserId";
    userProfile.tuneId = @"something";
    [[TuneManager currentManager] setUserProfile:userProfile];
    
    if (sendConnectedEventOpQueue == nil) {
        sendConnectedEventOpQueue = [NSOperationQueue new];
        [sendConnectedEventOpQueue setMaxConcurrentOperationCount:1];
    }
    
    mockResponse = [[NSData alloc] init];
    httpMock = OCMClassMock([TuneHttpUtils class]);
    returnError = NO;
    OCMStub(ClassMethod([httpMock sendSynchronousRequest:[OCMArg any]
                                                response:[OCMArg setTo:mockResponseReference]
                                                   error:[OCMArg setTo:mockErrorReference]])).andCall(self, @selector(mockHttpRequest:response:error:));
}

- (void)tearDown {
    sendConnectedEventOpQueue = nil;
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
    TuneAnalyticsEvent *testEvent = [[TuneAnalyticsEvent alloc] initCustomEventWithAction:@"testAction"];
    
    TuneAnalyticsDispatchToConnectedModeOperation *testOperation = [[TuneAnalyticsDispatchToConnectedModeOperation alloc] initWithTuneManager:[TuneManager currentManager]
                                                                                                                                        event:testEvent];
    
    expectedRequest = [self buildExpectedURLRequest:testEvent];
    
    [sendConnectedEventOpQueue addOperation:testOperation];
    [sendConnectedEventOpQueue waitUntilAllOperationsAreFinished];
    
    XCTAssertTrue([receivedRequest tuneIsEqualToTuneHttpRequest:expectedRequest]);
    
    OCMVerify([httpMock sendSynchronousRequest:[OCMArg any]
                                      response:[OCMArg setTo:mockResponseReference]
                                         error:[OCMArg setTo:mockErrorReference]]);
}

- (TuneHttpRequest *)buildExpectedURLRequest:(TuneAnalyticsEvent *)event {
    NSDictionary *eventDictionary = @{ @"event": [event toDictionary] };
    
    TuneHttpRequest *request = [TuneApi getDiscoverEventRequest:eventDictionary];
    
    return request;
}

- (NSData *)mockHttpRequest:(NSURLRequest *)request response:(NSURLResponse **)response error:(NSError **)error {
    receivedRequest = request;
    
    if (error != NULL) {
        *error = returnError ? [NSError errorWithDomain:@"TuneTestsMock" code:0 userInfo:nil] : nil;
    }
    
    return [[NSData alloc] init];
}

@end
