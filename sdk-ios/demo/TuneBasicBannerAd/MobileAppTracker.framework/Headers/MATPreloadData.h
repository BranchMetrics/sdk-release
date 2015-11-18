//
//  MATPreloadData.h
//  MobileAppTracker
//
//  Created by Harshal Ogale on 4/27/15.
//  Copyright (c) 2015 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AvailabilityMacros.h>

#import "TunePreloadData.h"


DEPRECATED_MSG_ATTRIBUTE("Please use class TunePreloadData instead") @interface MATPreloadData : TunePreloadData

/*!
 Create a new instance with the specified publisher name or ID.
 
 @param publisherId ID of the publisher on MAT
 */
+ (instancetype)preloadDataWithPublisherId:(NSString *)publisherId DEPRECATED_MSG_ATTRIBUTE("Please use corresponding method from class TunePreloadData");

@end
