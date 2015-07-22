//
//  TuneLocationHelper.h
//  Tune
//
//  Created by Harshal Ogale on 7/6/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*!
 Provides access to device location (latitude, longitude, altitude).
 <ul>
 <li>Does not request location access permission from end user.</li>
 <li>Implements location delegate. If location is not readily available, updates the location on its own.</li>
 <li>The latest location is accessed only once each time <code>deviceLocation</code> is called.</li>
 </ul>
 */
@interface TuneLocationHelper : NSObject

FOUNDATION_EXPORT const NSTimeInterval TUNE_LOCATION_UPDATE_DELAY;

/*!
 If location access is permitted, gets the current device location.
 @param arrLocation pointer to an array that will contain 4 items [latitude, longitude, altitude, timestamp], nil when location is not enabled
 @return YES if location is enabled, NO otherwise
 */
+ (BOOL)getOrRequestDeviceLocation:(NSArray **)arrLocation;

@end
