//
//  TunePlaylistManager+Testing.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/25/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TunePlaylistManager.h"

@interface TunePlaylistManager (Testing)

@property (strong, nonatomic) TunePlaylist *currentPlaylist;
@property (assign, nonatomic) BOOL isUpdating;

@end
