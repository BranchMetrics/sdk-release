//
//  TuneLocation.h
//  MobileAppTracker
//
//  Created by Harshal Ogale on 8/3/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Receives location information about the device.
 */
@interface TuneLocation : NSObject <NSCoding>

/**
 Altitude of the device at the time an event is recorded.
 */
@property (nonatomic, copy) NSNumber *altitude;

/**
 Latitude of the device an event is recorded.
 */
@property (nonatomic, copy) NSNumber *latitude;

/**
 Longitude of the device an event is recorded.
 */
@property (nonatomic, copy) NSNumber *longitude;

@end
