//
//  TunePlaylistManagerTests.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/20/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "TunePlaylistManager+Testing.h"
#import "TuneManager.h"
#import "TuneAnalyticsManager+Testing.h"
#import "TuneApi.h"
#import "TuneHttpRequest.h"
#import "TuneHttpResponse.h"
#import "TuneHttpUtils.h"
#import "DictionaryLoader.h"
#import "SimpleObserver.h"
#import "TuneSkyhookConstants.h"
#import "TuneFileManager.h"
#import "TunePowerHookManager+Testing.h"
#import "TuneSkyhookCenter.h"
#import "Tune+Testing.h"
#import "TuneXCTestCase.h"

@interface TunePlaylistManagerTests : TuneXCTestCase {
    id apiMock;
    id fileManagerMock;
    
    id playlistMock;
    id playlistInstanceMock;
    
    id httpRequestMock;
    id httpUtilsMock;
    
    TuneHttpResponse *newResponse;
    TuneManager *tuneManager;
    
    NSDictionary *playlistDictionary;
    
    SimpleObserver *simpleObserver;
}

@end

@implementation TunePlaylistManagerTests

TunePlaylistManager *playlistManager;

- (void)setUp {
    [super setUpWithMocks:@[[TuneAnalyticsManager class]]];
    
    tuneManager = [TuneManager currentManager];
    
    fileManagerMock = OCMClassMock([TuneFileManager class]);
    
    simpleObserver = [[SimpleObserver alloc] init];
    
    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePowerHookValueTests"].mutableCopy;
    
    playlistManager = tuneManager.playlistManager;
    
    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] init] statusCode:200 HTTPVersion:@"1.1" headerFields:@{}];
    newResponse = [[TuneHttpResponse alloc] initWithURLResponse:urlResponse andError:nil];
    [newResponse setResponseDictionary:playlistDictionary];
    
    // Uh... here be dragons?
    // Stub the class method so we can create an instance mock to then stub an instance method. Complicated, but better than using `wait`. :/
    playlistMock = OCMClassMock([TunePlaylist class]);
    OCMStub(ClassMethod([playlistMock playlistWithDictionary:OCMOCK_ANY])).andDo(^(NSInvocation *invocation) {
        NSDictionary *dictionaryArg;
        
        // Ref: https://github.com/erikdoe/ocmock/issues/147#issuecomment-68492449
        [invocation retainArguments];
        
        [invocation getArgument:&dictionaryArg atIndex:2];
        TunePlaylist *instance = [[TunePlaylist alloc] initWithDictionary:dictionaryArg];
        
        playlistInstanceMock = OCMPartialMock(instance);
        OCMStub([playlistInstanceMock retrieveInAppMessageAssets]).andDo(^(NSInvocation *retrieveInvocation) {
            [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistAssetsDownloaded object:playlistInstanceMock userInfo:nil];
        });
        
        [invocation setReturnValue:&playlistInstanceMock];
    });
    
    httpRequestMock = OCMClassMock([TuneHttpRequest class]);
    OCMStub([httpRequestMock performAsynchronousRequestWithCompletionBlock:OCMOCK_ANY]).andCall(self, @selector(performAsynchronousRequestWithCompletionBlock:));
    
    httpUtilsMock = OCMClassMock([TuneHttpUtils class]);
    
    NSHTTPURLResponse *dummyResp = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://www.tune.com"] statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
    NSError *dummyError = nil;
    OCMStub(ClassMethod([httpUtilsMock addIdentifyingHeaders:OCMOCK_ANY])).andDo(^(NSInvocation *invocation) {
        DebugLog(@"mock TuneHttpUtils: ignoring addIdentifyingHeaders: call");
    });
    OCMStub(ClassMethod([httpUtilsMock sendSynchronousRequest:OCMOCK_ANY response:[OCMArg setTo:dummyResp] error:[OCMArg setTo:dummyError]])).andDo(^(NSInvocation *invocation) {
        DebugLog(@"mock TuneHttpUtils: ignoring sendSynchronousRequest:response:error: call");
    });
    
    apiMock = OCMClassMock([TuneApi class]);
    OCMStub([apiMock getPlaylistRequest]).andReturn(httpRequestMock);
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd];
}

- (void)tearDown {
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd];
    
    tuneManager = nil;
    simpleObserver = nil;
    [playlistManager unregisterSkyhooks];
    playlistManager = nil;
    
    [playlistMock stopMocking];
    [playlistInstanceMock stopMocking];
    [apiMock stopMocking];
    [fileManagerMock stopMocking];
    [httpRequestMock stopMocking];
    [httpUtilsMock stopMocking];
    
    [super tearDown];
}

- (void)testSuccessfulPlaylistRequestSetsNewPlaylistAndPostsPlaylistCompletedDownloadSkyhook {
    XCTAssertNil(playlistManager.currentPlaylist);
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistManagerFinishedPlaylistDownload object:nil];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart];
    
    XCTAssertEqual(1, [simpleObserver skyhookPostCount]);
    
    XCTAssertNotNil(playlistManager.currentPlaylist);
}

- (void)testFailedPlaylistRequestStillPostsFinishedSkyhook {
    XCTAssertNil(playlistManager.currentPlaylist);
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:simpleObserver selector:@selector(skyhookPosted:) name:TunePlaylistManagerFinishedPlaylistDownload object:nil];
    
    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] init] statusCode:400 HTTPVersion:@"1.1" headerFields:@{}];
    newResponse = [[TuneHttpResponse alloc] initWithURLResponse:urlResponse andError:nil];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart];
    
    XCTAssertEqual(1, [simpleObserver skyhookPostCount]);
    XCTAssertNil(playlistManager.currentPlaylist);
}

#pragma mark - Playlist Saving - To Save or not to Save.

- (void)testNewPlaylistIsWrittenToDiskWhenNoneExists {
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart];
    waitFor(.1);
    OCMVerify([fileManagerMock savePlaylistToDisk:OCMOCK_ANY]);
}

- (void)testNewPlaylistIsNotWrittenToDiskWhenItIsTheSameAsTheCurrentPlaylist {
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    // Reject the next save to disk call if it happens.
    [[fileManagerMock reject] savePlaylistToDisk:OCMOCK_ANY];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart];
    
    // If we don't expect anything than if anything is called this will fail.
    OCMVerify(fileManagerMock);
}

- (void)testNewPlaylistIsWrittenToDiskWhenItIsDifferentThanCurrentPlaylist {
    [[fileManagerMock expect] savePlaylistToDisk:OCMOCK_ANY];
    [[fileManagerMock expect] savePlaylistToDisk:OCMOCK_ANY];
    
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    NSMutableDictionary *changedPlaylist = playlistDictionary.mutableCopy;
    changedPlaylist[@"power_hooks"][@"new_phook"] = @{ @"value": @"new_value" };
    [newResponse setResponseDictionary:changedPlaylist];
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart];
    
    [fileManagerMock verify];
}

- (void)testOnPlaylistFirstDownloadedCallback {
    __block NSUInteger i = 0;
    [Tune onFirstPlaylistDownloaded:^(){
        i += 1;
    }];
    
    XCTAssertTrue(i == 0);
    
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    waitFor(0.1);
    
    XCTAssertTrue(i == 1);
}

- (void)testOnPlaylistFirstDownloadedCallbackTriggersOnlyOnVeryFirstTime {
    __block NSUInteger i = 0;
    [Tune onFirstPlaylistDownloaded:^(){
        i += 1;
    }];
    
    XCTAssertTrue(i == 0);
    
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    waitFor(0.1);
    
    XCTAssertTrue(i == 1);
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart];
    
    [playlistManager setCurrentPlaylist:playlist];
    
    waitFor(0.1);
    
    XCTAssertTrue(i == 1);
}

- (void)testOnPlaylistFirstDownloadedCallbackTriggersAfterTimeout {
    __block NSUInteger i = 0;
    [Tune onFirstPlaylistDownloaded:^(){
        i += 1;
    } withTimeout:0.3];
    
    XCTAssertTrue(i == 0);
    
    waitFor(0.31);
    
    XCTAssertTrue(i == 1);
}

- (void)testOnPlaylistFirstDownloadIsCalledAfterPowerHookUpdate {
    __block BOOL powerHooksUpdated = NO;
    __block BOOL onFirstPlaylistDownloadCalled = NO;
    
    id mockPowerHookManager = OCMPartialMock([TuneManager currentManager].powerHookManager);
    OCMStub([mockPowerHookManager updatePowerHooksFromPlaylist:[OCMArg any] playlistFromDisk:NO]).andDo(^(NSInvocation *invocation) {
        XCTAssertFalse(onFirstPlaylistDownloadCalled, @"OnFirstPlaylistDownload notification should not have been fired before PowerHooks were updated.");
        powerHooksUpdated = YES;
    });
    
    id mockPlaylistManager = OCMPartialMock([TuneManager currentManager].playlistManager);
    OCMStub([mockPlaylistManager handleOnFirstPlaylistDownloaded:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        XCTAssertTrue(powerHooksUpdated, @"PowerHooks should have been updated before OnFirstPlaylistDownload notification was fired.");
        onFirstPlaylistDownloadCalled = YES;
    });
    
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    XCTAssertTrue(powerHooksUpdated);
    XCTAssertTrue(onFirstPlaylistDownloadCalled);
    
    [mockPowerHookManager stopMocking];
    [mockPlaylistManager stopMocking];
}

- (void)testPlaylistCallbackIsCalledWhenPlaylistIsNotUpdated {
    __block NSUInteger i = 0;
    [Tune onFirstPlaylistDownloaded:^(){
        i += 1;
    }];
    
    XCTAssertTrue(i == 0);
    
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    waitFor(0.1);
    
    XCTAssertTrue(i == 1);
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart];
    
    // Re-register callback to simulate app being started again
    [Tune onFirstPlaylistDownloaded:^(){
        i += 1;
    }];
    
    // Downloading same playlist that is already on disk
    [playlistManager setCurrentPlaylist:playlist];
    
    waitFor(0.1);
    
    XCTAssertTrue(i == 2);
}

- (void)testPlaylistCallbackCanceledAfterBackground {
    __block NSUInteger i = 0;
    [Tune onFirstPlaylistDownloaded:^(){
        i += 1;
    } withTimeout:0.3];
    
    XCTAssertTrue(i == 0);
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd];
    
    waitFor(0.31);
    
    XCTAssertTrue(i == 0);
}

- (void)testPlaylistCallbackCanceledAndResumedAfterBackgroundForeground {
    __block NSUInteger i = 0;
    [Tune onFirstPlaylistDownloaded:^(){
        i += 1;
    } withTimeout:0.3];
    
    XCTAssertTrue(i == 0);
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd];
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart];
    
    waitFor(0.31);
    
    XCTAssertTrue(i == 1);
}

- (void)testSecondCallbackExecutedAfterTimeoutWhenRegisteredTwice {
    __block NSUInteger i = 0;
    [Tune onFirstPlaylistDownloaded:^(){
        i += 1;
    }];
    
    // Second callback should override first
    [Tune onFirstPlaylistDownloaded:^(){
        i += 5;
    }];
    
    XCTAssertTrue(i == 0);
    
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    waitFor(0.1);
    
    XCTAssertTrue(i == 5);
}

- (void)testBothCallbacksExecutedWhenRegisteredTwice {
    __block NSUInteger i = 0;
    [Tune onFirstPlaylistDownloaded:^(){
        i += 1;
    }];
    
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    waitFor(0.1);
    
    XCTAssertTrue(i == 1);
    
    // Second callback should override first
    [Tune onFirstPlaylistDownloaded:^(){
        i += 5;
    }];
    
    playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    waitFor(0.1);
    
    XCTAssertTrue(i == 6);
}

#pragma mark - User in Segment API

- (void)testIsUserInSegment {
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    XCTAssertTrue([playlistManager isUserInSegmentId:@"abc"]);
    XCTAssertFalse([playlistManager isUserInSegmentId:@"xyz"]);
}

- (void)testIsUserInAnySegments {
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    // Add some segment ids that aren't in the playlist
    NSMutableArray *segmentIds = [NSMutableArray arrayWithArray:@[@"asdf", @"xyz"]];
    
    // User should not be found in any of the segments
    XCTAssertFalse([playlistManager isUserInAnySegmentIds:segmentIds]);
    
    // Add a segment id that IS in the playlist
    [segmentIds addObject:@"def"];

    // User should now be found in a segment
    XCTAssertTrue([playlistManager isUserInAnySegmentIds:segmentIds]);
}

- (void)testEmptySegmentsFromPlaylist {
    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePlaylistEmptySegmentTests"].mutableCopy;
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    // Should handle if segments in playlist is empty
    XCTAssertFalse([playlistManager isUserInSegmentId:@"abc"]);
    NSArray *segmentIds = @[@"abc", @"def"];
    XCTAssertFalse([playlistManager isUserInAnySegmentIds:segmentIds]);
}

- (void)testIsUserInAnySegmentsWithEmptyArray {
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    // isUserInAnySegmentIds should handle nil for segmentIds array
    XCTAssertFalse([playlistManager isUserInAnySegmentIds:@[]]);
}

- (void)testIsUserInAnySegmentsWithNil {
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    // isUserInAnySegmentIds should handle nil for segmentIds array
    XCTAssertFalse([playlistManager isUserInAnySegmentIds:nil]);
}

- (void)testForceSetUserInSegment {
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    NSString *segmentId = @"localTestSegmentId";
    
    [TuneDebugUtilities forceSetUserInSegment:YES forSegmentId:segmentId];
    
    XCTAssertTrue([playlistManager isUserInSegmentId:segmentId]);
    
    [TuneDebugUtilities forceSetUserInSegment:NO forSegmentId:segmentId];
    
    XCTAssertFalse([playlistManager isUserInSegmentId:segmentId]);
}

#pragma mark - Helper Methods

-(void)performAsynchronousRequestWithCompletionBlock:(void(^)(TuneHttpResponse* response))completionBlock {
    DebugLog(@"TunePlaylistManagerTests: dummy performAsynchronousRequestWithCompletionBlock: method called");
    completionBlock(newResponse);
}

@end
