//
//  TuneLocationHelper.h
//  Tune
//
//  Created by Harshal Ogale on 7/6/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class TuneLocation;

/*!
 Provides access to device location (latitude, longitude, altitude).
 <ul>
 <li>Does not request location access permission from end user.</li>
 <li>Implements location delegate. If location is not readily available, updates the location on its own.</li>
 <li>The latest location is accessed only once each time <code>deviceLocation</code> is called.</li>
 </ul>
 */
@interface TuneLocationHelper : NSObject

/*!
 Duration in seconds by which an event measurement request may be delayed while waiting for device location update
 */
FOUNDATION_EXPORT const NSTimeInterval TUNE_LOCATION_UPDATE_DELAY;

/*!
 When location access is permitted, the current device location is included in the mutable array input param.
 If this is the first time location is being requested or if the location info is more than 60 seconds old,
 then this method initiates a new location fetch request. Note: This method should be called on the main thread.
 @param resultArr a mutable array to be used by the method to return location info
 */
+ (void)getOrRequestDeviceLocation:(NSMutableArray *)resultArr;

/*!
 Checks if the end-user has permitted device location access
 @return YES if location access is permitted, NO otherwise
 */
+ (BOOL)isLocationEnabled;

@end
