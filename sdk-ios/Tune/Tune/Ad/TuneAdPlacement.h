//
//  TuneAdPlacement.h
//  Tune
//
//  Created by Harshal Ogale on 5/31/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TuneAd;
@class TuneAdMetadata;

@interface TuneAdPlacement : NSObject

/*!
 Ad for the placement
 */
@property (nonatomic, strong) TuneAd *ad;

/*!
 Name of the placement
 */
@property (nonatomic, copy) NSString *placement;

/*!
 Used to provide custom info to help ad targeting. Once set, all subsequent ad requests for this ad view include this info.
 */
@property (nonatomic, strong) TuneAdMetadata *metadata;

+ (instancetype)adPlacementWithPlacement:(NSString *)placement;
+ (instancetype)adPlacementWithPlacement:(NSString *)placement metadata:(TuneAdMetadata *)metadata;

@end
