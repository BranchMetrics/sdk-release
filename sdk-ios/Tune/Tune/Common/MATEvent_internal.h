//
//  MATEvent_internal.h
//  Tune
//
//  Created by Harshal Ogale on 5/5/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "../MATEvent.h"

@interface MATEvent (PrivateMethods)

@property (nonatomic, copy, readonly) NSString *actionName;
@property (nonatomic, copy) NSNumber *altitude;
@property (nonatomic, strong) NSDictionary *cworksClick;            // key, value pair
@property (nonatomic, strong) NSDictionary *cworksImpression;       // key, value pair
@property (nonatomic, copy) NSString *iBeaconRegionId;              // KEY_GEOFENCE_NAME
@property (nonatomic, copy) NSNumber *latitude;
@property (nonatomic, copy) NSNumber *longitude;
@property (nonatomic, copy) NSNumber *locationHorizontalAccuracy;
@property (nonatomic, copy) NSNumber *locationVerticalAccuracy;
@property (nonatomic, copy) NSDate *locationTimestamp;
@property (nonatomic, assign) BOOL postConversion;                  // KEY_POST_CONVERSION

@end
