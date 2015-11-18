//
//  TunePreloadData.m
//  Tune
//
//  Created by Harshal Ogale on 4/27/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TunePreloadData.h"


@implementation TunePreloadData

+ (instancetype)preloadDataWithPublisherId:(NSString *)publisherId
{
    return [[TunePreloadData alloc] initWithPublisherId:publisherId];
}

- (instancetype)initWithPublisherId:(NSString *)pubId
{
    self = [super init];
    if (self) {
        _publisherId = pubId;
    }
    return self;
}

@end
