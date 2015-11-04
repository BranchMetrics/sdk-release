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
 When location access is permitted, this method can be used to access the current device location.
 If the available location info is more than 60 seconds old, then this method initiates a new location fetch request and returns nil.
 When nil is returned, this method may be called again after a few seconds to access the updated device location.
 @return a TuneLocation instance, nil if location access is disabled or if current location info is stale
 */
+ (TuneLocation *)getOrRequestDeviceLocation;

/*!
 Checks if the end-user has permitted device location access
 @return YES if location access is permitted, NO otherwise
 */
+ (BOOL)isLocationEnabled;

@end
