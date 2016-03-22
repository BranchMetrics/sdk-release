//
//  TuneLocation_internal.h
//  MobileAppTracker
//
//  Created by Harshal Ogale on 8/3/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "../TuneLocation.h"

@interface TuneLocation ()

@property (nonatomic, copy) NSNumber *horizontalAccuracy;
@property (nonatomic, copy) NSDate *timestamp;
@property (nonatomic, copy) NSNumber *verticalAccuracy;

@end
