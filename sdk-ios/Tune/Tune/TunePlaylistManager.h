//
//  TunePlaylistManager.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneModule.h"
#import "TunePlaylist.h"
#import "TuneSkyhookPayload.h"

@interface TunePlaylistManager : TuneModule

- (void)didEnterBackgroundSkyhook:(TuneSkyhookPayload *)payload;
- (void)onFirstPlaylistDownloaded:(void (^)())block withTimeout:(NSTimeInterval)timeout;
- (BOOL)isUserInSegmentId:(NSString *)segmentId;
- (BOOL)isUserInAnySegmentIds:(NSArray<NSString *> *)segmentIds;
- (void)forceSetUserInSegment:(BOOL)isInSegment forSegmentId:(NSString *)segmentId;

- (BOOL)loadPlaylistFromDisk;

@end
