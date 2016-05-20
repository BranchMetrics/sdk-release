//
//  UIViewController+TuneAnalyticsTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/28/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "SimpleObserver.h"
#import "TuneManager+Testing.h"
#import "TuneSkyhookCenter+Testing.h"
#import "TuneSkyhookConstants.h"
#import "TuneSwizzleBlacklist.h"
#import "TuneBlankViewController.h"
#import "UIViewController+NameTag.h"
#import "TuneState+Testing.h"
#import "TuneState.h"


@interface UIViewController_TuneAnalyticsTests : XCTestCase {
    SimpleObserver *simpleObserver;
    id swizzleBlacklistMock;
    id tuneStateMock;
    
    TuneSkyhookCenter *skyhookCenter;
}

@end

@implementation UIViewController_TuneAnalyticsTests

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
    
    tuneStateMock = OCMClassMock([TuneState class]);
    OCMStub(ClassMethod([tuneStateMock doSendScreenViews])).andReturn(YES);
    
    [TuneBlankViewController load];
    
    simpleObserver = [[SimpleObserver alloc] init];
    swizzleBlacklistMock = OCMClassMock([TuneSwizzleBlacklist class]);
    skyhookCenter = [TuneSkyhookCenter defaultCenter];
    [skyhookCenter startSkyhookQueue];
}

- (void)tearDown {
    [[TuneSkyhookCenter defaultCenter] removeObserver:simpleObserver];
    simpleObserver = nil;
    
    [skyhookCenter stopAndClearSkyhookQueue];
    
    [swizzleBlacklistMock stopMocking];
    [tuneStateMock stopMocking];
    
    [super tearDown];
}

#pragma mark - Testing Swizzle

- (void)testNonBlacklistViewControllerSendsOutViewWillAppearSkyhook {
    TuneBlankViewController *viewController = [[TuneBlankViewController alloc] init];
    
    [skyhookCenter addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TuneViewControllerAppeared object:nil];
    
    [viewController viewWillAppear:NO];
    [skyhookCenter waitTilQueueFinishes];
    
    XCTAssertEqual([simpleObserver skyhookPostCount], 1);
    XCTAssertEqual([simpleObserver lastPayload].object, viewController);
    XCTAssertEqual(viewController.viewWillAppearCount, 1);
}

- (void)testBlacklistedViewControllerDoesNotSendOutViewWillAppearSkyhook {
    OCMStub([swizzleBlacklistMock classIsOnBlackList:@"TuneBlankViewController"]).andReturn(YES);
    
    TuneBlankViewController *viewController = [[TuneBlankViewController alloc] init];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TuneViewControllerAppeared object:nil];
    
    [viewController viewWillAppear:NO];
    
    XCTAssertEqual([simpleObserver skyhookPostCount], 0);
    
    // viewWillAppear should still be called normally. 
    XCTAssertEqual(viewController.viewWillAppearCount, 1);
}

#pragma mark - Testing Helpers

- (void)testTuneScreenNameReturnsNameOfClass {
    TuneBlankViewController *viewController = [[TuneBlankViewController alloc] init];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    XCTAssertEqualObjects(@"TuneBlankViewController", [viewController performSelector:@selector(tuneScreenName)]);
#pragma clang diagnostic pop
}

#pragma mark - Testing NameTag

- (void)testNameTaggedViewControllerIncludesNameTagInScreenName {
    TuneBlankViewController *viewController = [[TuneBlankViewController alloc] init];
    viewController.nameTag = @"This is a Test";
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    XCTAssertEqualObjects(@"This is a Test", [viewController performSelector:@selector(tuneScreenName)]);
#pragma clang diagnostic pop
}

@end
