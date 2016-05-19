//
//  TunePlaylistManager.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TunePlaylistManager.h"
#import "TuneSkyhookPayload.h"
#import "TuneSkyhookPayloadConstants.h"
#import "TuneApi.h"
#import "TuneManager.h"
#import "TuneFileManager.h"
#import "TuneSkyhookCenter.h"
#import "TuneConfiguration.h"
#import "TuneState.h"
#import "TuneJSONPlayer.h"
#import "TuneCallbackBlock.h"
#import "TuneJSONUtils.h"

@interface TunePlaylistManager ()

@property (strong, nonatomic) TunePlaylist *currentPlaylist;
@property (assign, nonatomic) BOOL isUpdating;

@end

@implementation TunePlaylistManager

NSTimer *playlistScheduler;
static BOOL startedScheduledDispatch = NO;
static BOOL receivedFirstPlaylistDownload = NO;

static BOOL gotVeryFirstPlaylist = NO;
NSArray *firstPlaylistDownloadedBlocks;
NSObject *firstPlaylistDownloadedBlocksLock;
NSOperationQueue *playlistCallbackQueue;

#pragma mark - Initialization / Deallocation

-(id)initWithTuneManager:(TuneManager *)tuneManager {
    self = [super initWithTuneManager:tuneManager];
    
    if (self) {
        playlistCallbackQueue = [NSOperationQueue new];
        firstPlaylistDownloadedBlocks = [[NSArray alloc] init];
        firstPlaylistDownloadedBlocksLock = [[NSObject alloc] init];
        
        startedScheduledDispatch = NO;
        receivedFirstPlaylistDownload = NO;
        gotVeryFirstPlaylist = NO;
    }
    
    return self;
}

- (void)bringUp {
    [self registerSkyhooks];
    startedScheduledDispatch = NO;
}

- (void)bringDown {
    [self unregisterSkyhooks];
    [playlistScheduler invalidate];
    playlistScheduler = nil;
}

#pragma mark - Skyhook registration

- (void)registerSkyhooks {
    [self unregisterSkyhooks];
    [[TuneSkyhookCenter defaultCenter] addObserver:self selector:@selector(didEnterForegroundSkyhook:) name:TuneSessionManagerSessionDidStart object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:self selector:@selector(didEnterBackgroundSkyhook:) name:TuneSessionManagerSessionDidEnd object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:self selector:@selector(playlistProcessed:) name:TunePlaylistAssetsDownloaded object:nil];
    [[TuneSkyhookCenter defaultCenter] addObserver:self selector:@selector(handleOnFirstPlaylistDownloaded:) name:TunePlaylistManagerFirstPlaylistDownloaded object:nil];
}

#pragma mark - Skyhook Calls

- (void)didEnterForegroundSkyhook:(TuneSkyhookPayload*)payload {
    if ([TuneState isTMADisabled]) { return; }
    
    // Pull our playlist from disk before our first download
    [self loadPlaylistFromDisk];
    
    [self fetchAndUpdatePlaylist];
    
    if (!startedScheduledDispatch) {
        NSTimeInterval interval = [self.tuneManager.configuration.playlistRequestPeriod integerValue];
        if (self.tuneManager.configuration.pollForPlaylist) {
            playlistScheduler = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(fetchAndUpdatePlaylist) userInfo:nil repeats:YES];
            startedScheduledDispatch = YES;
        }
    }
}

- (void)didEnterBackgroundSkyhook:(TuneSkyhookPayload*)payload {
    if ([TuneState isTMADisabled]) { return; }
    
    // Reset received first playlist flag so we fire the first Playlist Skyhook on next download
    receivedFirstPlaylistDownload = NO;
    
    if (startedScheduledDispatch) {
        [playlistScheduler invalidate];
        playlistScheduler = nil;
        startedScheduledDispatch = NO;
    }
}

#pragma mark - Fetch Playlist

- (void)fetchAndUpdatePlaylist {
    InfoLog(@"Fetch and Update Playlist!");
    
    // do not allow concurrent updates
    if (self.isUpdating) { return; }
    
    self.isUpdating = YES;
    
    TuneHttpRequest *request = [TuneApi getPlaylistRequest];
    
    // If there was an error building the request, then don't do anything
    if (request == nil) {
        self.isUpdating = NO;
        return;
    }
    
    request.timeoutInterval = 15.0;
    __block TunePlaylistManager *_self = self;
    [request performAsynchronousRequestWithCompletionBlock:^(TuneHttpResponse *response) {
        @try {
            if ([response error]) {
                WarnLog(@"Error downloading playlist from %@, Error: %@", request.URL, [[response error] localizedDescription]);
            } else {
                InfoLog(@"Successfully downloaded the playlist.");
            }
            
            NSDictionary *playlistDictionary = nil;
            if (_self.tuneManager.configuration.usePlaylistPlayer) {
                playlistDictionary = [_self.tuneManager.playlistPlayer getNext];
            } else if (response.wasSuccessful) {
                playlistDictionary = response.responseDictionary;
            }
            
            TunePlaylist *newPlaylist = nil;
            if (playlistDictionary) {
                newPlaylist = [TunePlaylist playlistWithDictionary:playlistDictionary];
                if ([TuneManager currentManager].configuration.echoPlaylists) {
                    NSLog(@"Got playlist:\n%@", [TuneJSONUtils createPrettyJSONFromDictionary:playlistDictionary withSecretTMADepth:nil]);
                }
            }
            
            if (newPlaylist) {
                [newPlaylist retrieveInAppMessageAssets];
            } else {
                // Even if the playlist manager failed to download and no new playlist was returned, we still post the Finished Download Skyhook.
                [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistManagerFinishedPlaylistDownload object:self];
            }
        } @catch (NSException *exception) {
            ErrorLog(@"Error processing the playlist: %@", exception);
        } @finally {
            _self.isUpdating = NO;
        }
    }];
}

- (void)playlistProcessed:(TuneSkyhookPayload *)payload {
    
    TunePlaylist *processedPlaylist = payload.object;
    if (processedPlaylist) {
        [self setCurrentPlaylist:processedPlaylist];
    }
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistManagerFinishedPlaylistDownload object:self];
}

#pragma mark - Set Current Playlist

- (void)setCurrentPlaylist:(TunePlaylist *)newPlaylist {
    // If TMA is disabled, the new playlist is always blank.
    if ([TuneState isTMADisabled]) {
        newPlaylist = [TunePlaylist playlistWithDictionary:@{}];
    }

    // If this is the first playlist we've downloaded this session then send off the FirstPlaylistDownloaded hook
    if (!newPlaylist.fromDisk && !receivedFirstPlaylistDownload) {
        receivedFirstPlaylistDownload = YES;
        [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistManagerFirstPlaylistDownloaded object:self userInfo:@{ TunePayloadFirstPlaylistDownloaded:newPlaylist }];
    }
    
    
    if ([_currentPlaylist isEqual:newPlaylist]) {
        return;
    }

    _currentPlaylist = newPlaylist;
    
    // Only save this playlist if it is not from disk and it is not from connected mode
    // This could be our first install playlist download or a new playlist that is different than the one on disk.
    if (!newPlaylist.fromDisk && !newPlaylist.fromConnectedMode) {
        [TuneFileManager savePlaylistToDisk:newPlaylist];
    }
    
    NSMutableDictionary *userInfo = @{}.mutableCopy;
    if (newPlaylist) {
        userInfo[TunePayloadNewPlaylist] = newPlaylist;
        userInfo[TunePayloadPlaylistLoadedFromDisk] = @(newPlaylist.fromDisk);
    }
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TunePlaylistManagerCurrentPlaylistChanged object:self userInfo:userInfo];
}

#pragma mark - Load / Save Playlist to Disk

- (BOOL)loadPlaylistFromDisk {
    NSDictionary *playlistFromDisk;
    
    if (self.tuneManager.configuration.usePlaylistPlayer) {
        playlistFromDisk = [self.tuneManager.playlistPlayer getNext];
    } else {
        playlistFromDisk = [TuneFileManager loadPlaylistFromDisk];
    }
    
    if (playlistFromDisk) {
        TunePlaylist *playlist = [TunePlaylist playlistWithDictionary:playlistFromDisk];
        playlist.fromDisk = YES;
        [self setCurrentPlaylist:playlist];
        
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - On First Playlist Downloaded Callbacks

- (void)onFirstPlaylistDownloaded:(void (^)())block withTimeout:(NSTimeInterval)timeout {
    @try {
        TuneCallbackBlock *blockCallback = [[TuneCallbackBlock alloc] initWithCallbackBlock:block fireOnce:YES];
        
        BOOL executeBlock = NO;
        
        @synchronized(firstPlaylistDownloadedBlocksLock) {
            if (gotVeryFirstPlaylist) {
                executeBlock = YES;
            } else {
                if (timeout > 0) {
                    [blockCallback setDelay:timeout];
                }
                NSMutableArray *updatedFirstPlaylistdownloadedBlocks = firstPlaylistDownloadedBlocks.mutableCopy;
                [updatedFirstPlaylistdownloadedBlocks addObject:blockCallback];
                firstPlaylistDownloadedBlocks = [NSArray arrayWithArray:updatedFirstPlaylistdownloadedBlocks];
            }
        }
        
        if (executeBlock) {
            [playlistCallbackQueue addOperationWithBlock:^{
                [blockCallback executeBlock];
            }];
        }
    } @catch (NSException *exception) {
        ErrorLog(@"Error in onFirstPlaylistDownloaded: %@", exception);
    }
}

- (void)handleOnFirstPlaylistDownloaded:(TuneSkyhookPayload *)payload {
    NSArray *blockArray = nil;
    
    @synchronized(firstPlaylistDownloadedBlocksLock) {
        if (!gotVeryFirstPlaylist) {
            gotVeryFirstPlaylist = YES;
            
            blockArray = firstPlaylistDownloadedBlocks.copy;
        }
    }
    
    if ((blockArray != nil) && ([blockArray count] > 0)) {
        for (TuneCallbackBlock *blockCallback in blockArray) {
            [playlistCallbackQueue addOperationWithBlock:^{
                [blockCallback executeBlock];
            }];
        }
    }
}

@end
