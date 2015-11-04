//
//  TuneAdPlacement.m
//  Tune
//
//  Created by Harshal Ogale on 5/31/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneAdPlacement.h"

#import "TuneAd.h"
#import "TuneAdMetadata.h"

@implementation TuneAdPlacement

+ (instancetype)adPlacementWithPlacement:(NSString *)placement
{
    return [self adPlacementWithPlacement:placement metadata:nil];
}

+ (instancetype)adPlacementWithPlacement:(NSString *)placement metadata:(TuneAdMetadata *)metadata
{
    TuneAdPlacement *pl = [TuneAdPlacement new];
    pl.placement = placement;
    pl.metadata = metadata;
    
    return pl;
}

@end
