//
//  TuneUserAgentCollectorTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Adam Zethraeus on 1/17/18.
//  Copyright © 2018 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "Tune+Testing.h"
#import "TuneTestsHelper.h"
#import "TuneXCTestCase.h"
#import "TuneUserAgentCollector.h"
#import "TuneUserDefaultsUtils.h"


@interface TuneUserDefaultsUtils(TestExtension)

+ (void)initialize;

@end

@interface TuneUserAgentCollector(TestExtension)

+ (NSString *)cachedUserAgentForOSVersion:(NSString *)osVersion;
+ (void)saveUserAgent:(NSString *)userAgent forOSVersion:(NSString *)osVersion;
@property (nonatomic, assign) BOOL hasStarted;

@end

@interface TuneUserAgentCollectorTests : TuneXCTestCase

@end

@implementation TuneUserAgentCollectorTests

- (void)setUp {
    [super setUp];
    [TuneUserDefaultsUtils initialize];
}

- (void)tearDown {
    [super tearDown];
    [TuneUserDefaultsUtils clearAll];
}

- (void)testSavedUserAgentIsReturned {
    NSString *osString = @"iOSVersionString";
    NSString *userAgentString = @"safariUserAgentString";
    [TuneUserAgentCollector saveUserAgent:userAgentString forOSVersion:osString];
    XCTAssert([[TuneUserAgentCollector cachedUserAgentForOSVersion:[osString copy]] isEqualToString:userAgentString]);
}

- (void)testCreatesWebViewWhenUncached {
    [TuneUserAgentCollector initialize];
    id webViewClassMock = OCMClassMock([UIWebView class]);
    __block NSInteger callCount = 0;
    OCMStub([webViewClassMock new]).andDo(^(NSInvocation *invocation) {
        callCount++;
    });
    id applicationClassMock = OCMClassMock([UIApplication class]);
    OCMStub([applicationClassMock sharedApplication]).andReturn([NSObject new]);
    id nsOperationQueueClassMock = OCMClassMock([NSOperationQueue class]);

    NSOperationQueue *testingQueue = [[NSOperationQueue alloc] init];
    OCMStub([nsOperationQueueClassMock mainQueue]).andReturn(testingQueue);
    [TuneUserAgentCollector startCollection];
    [testingQueue waitUntilAllOperationsAreFinished];
    XCTAssert(callCount == 1);

    [nsOperationQueueClassMock stopMocking];
    [applicationClassMock stopMocking];
    [webViewClassMock stopMocking];
}

- (void)testDoesNotCreateWebViewWhenCached {
    NSString *osVersionString = @"osVersion";
    // Stub out the call to [UIDevice currentDevice].systemVersion
    id deviceMock = OCMClassMock([UIDevice class]);
    OCMStub([deviceMock currentDevice]).andReturn(deviceMock);
    OCMStub([(UIDevice *)deviceMock systemVersion]).andReturn(osVersionString);

    [TuneUserAgentCollector saveUserAgent:@"userAgent" forOSVersion:osVersionString];

    [TuneUserAgentCollector initialize];
    id webViewClassMock = OCMClassMock([UIWebView class]);
    __block NSInteger callCount = 0;
    OCMStub([webViewClassMock new]).andDo(^(NSInvocation *invocation) {
        callCount++;
    });
    id applicationClassMock = OCMClassMock([UIApplication class]);
    OCMStub([applicationClassMock sharedApplication]).andReturn([NSObject new]);
    id nsOperationQueueClassMock = OCMClassMock([NSOperationQueue class]);

    NSOperationQueue *testingQueue = [[NSOperationQueue alloc] init];
    OCMStub([nsOperationQueueClassMock mainQueue]).andReturn(testingQueue);
    [TuneUserAgentCollector startCollection];
    [testingQueue waitUntilAllOperationsAreFinished];
    XCTAssert(callCount == 0);

    [nsOperationQueueClassMock stopMocking];
    [applicationClassMock stopMocking];
    [webViewClassMock stopMocking];
}

@end
