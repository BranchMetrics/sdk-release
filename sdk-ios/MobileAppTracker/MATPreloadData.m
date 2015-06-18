//
//  MATPreloadData.m
//  MobileAppTracker
//
//  Created by Harshal Ogale on 4/27/15.
//  Copyright (c) 2015 HasOffers. All rights reserved.
//

#import "MATPreloadData.h"

@implementation MATPreloadData


+ (instancetype)preloadDataWithPublisherId:(NSString *)publisherId
{
    return [[MATPreloadData alloc] initWithPublisherId:publisherId];
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
