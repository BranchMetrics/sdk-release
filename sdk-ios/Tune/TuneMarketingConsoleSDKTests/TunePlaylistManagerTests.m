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
#import "TuneApi.h"
#import "TuneHttpRequest.h"
#import "TuneHttpResponse.h"
#import "DictionaryLoader.h"
#import "SimpleObserver.h"
#import "TuneSkyhookConstants.h"
#import "TuneFileManager.h"
#import "TuneSkyhookCenter.h"
#import "Tune+Testing.h"

@interface TunePlaylistManagerTests : XCTestCase {
    id apiMock;
    id fileManagerMock;
    
    id playlistMock;
    id playlistInstanceMock;
    
    id httpRequestMock;
    
    TuneHttpResponse *newResponse;
    TuneManager *tuneManager;
    
    NSDictionary *playlistDictionary;
    
    SimpleObserver *simpleObserver;
}

@end

@implementation TunePlaylistManagerTests

TunePlaylistManager *playlistManager;

- (void)setUp {
    [super setUp];
    
    RESET_EVERYTHING();
    
    tuneManager = [TuneManager currentManager];
    
    fileManagerMock = OCMClassMock([TuneFileManager class]);
    
    simpleObserver = [[SimpleObserver alloc] init];
    
    playlistDictionary = [DictionaryLoader dictionaryFromJSONFileNamed:@"TunePowerHookValueTests"].mutableCopy;
    
    playlistManager = tuneManager.playlistManager;
    
    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] init] statusCode:200 HTTPVersion:@"1.2" headerFields:@{}];
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
        OCMStub([playlistInstanceMock retrieveInAppMessageAssets]).andDo(^(NSInvocation *invocation) {
            [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistAssetsDownloaded object:playlistInstanceMock userInfo:nil];
        });
        
        [invocation setReturnValue:&playlistInstanceMock];
    });
    
    httpRequestMock = OCMClassMock([TuneHttpRequest class]);
    OCMStub([httpRequestMock performAsynchronousRequestWithCompletionBlock:OCMOCK_ANY]).andCall(self, @selector(performAsynchronousRequestWithCompletionBlock:));
    
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
    
    NSHTTPURLResponse *urlResponse = [[NSHTTPURLResponse alloc] initWithURL:[[NSURL alloc] init] statusCode:400 HTTPVersion:@"1.2" headerFields:@{}];
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
    
    [Tune onFirstPlaylistDownloaded:^(){
        i += 1;
    }];
    
    XCTAssertTrue(i == 0);
    
    TunePlaylist *playlist = [[TunePlaylist alloc] initWithDictionary:playlistDictionary];
    [playlistManager setCurrentPlaylist:playlist];
    
    waitFor(0.1);
    
    XCTAssertTrue(i == 2);
    
    [Tune onFirstPlaylistDownloaded:^(){
        i += 1;
    }];
    
    waitFor(0.1);
    
    XCTAssertTrue(i == 3);
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

-(void)performAsynchronousRequestWithCompletionBlock:(void(^)(TuneHttpResponse* response))completionBlock {
    completionBlock(newResponse);
}

@end
