//
//  TuneDebugUtilities.m
//  TuneMarketingConsoleSDK
//
//  Created by John Gu on 8/2/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import "TuneDebugUtilities.h"

#import "Tune.h"
#import "TunePlaylistManager.h"

@implementation TuneDebugUtilities

+ (void)setDebugMode:(BOOL)enableDebug {
    [Tune setDebugMode:enableDebug];
}

+ (void)forceSetUserInSegment:(BOOL)isInSegment forSegmentId:(NSString *)segmentId {
    [[TuneManager currentManager].playlistManager forceSetUserInSegment:isInSegment forSegmentId:segmentId];
}

@end
