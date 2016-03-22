//
//  MATPreloadData.m
//  MobileAppTracker
//
//  Created by Harshal Ogale on 4/27/15.
//  Copyright (c) 2015 HasOffers. All rights reserved.
//

#import "MATPreloadData.h"

@interface TunePreloadData (MATPreloadData)

- (instancetype)initWithPublisherId:(NSString *)pubId;

@end

@implementation MATPreloadData


+ (instancetype)preloadDataWithPublisherId:(NSString *)publisherId
{
    return [[MATPreloadData alloc] initWithPublisherId:publisherId];
}

- (instancetype)initWithPublisherId:(NSString *)pubId
{
    self = [super initWithPublisherId:pubId];
    
    return self;
}


@end
