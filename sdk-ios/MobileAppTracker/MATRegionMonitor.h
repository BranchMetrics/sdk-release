//
//  MATRegionMonitor.h
//  MobileAppTracker
//
//  Created by John Bender on 4/30/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>

#define DEBUG_REGION FALSE

@protocol MobileAppTrackerRegionDelegate;


@interface MATRegionMonitor : NSObject

@property (nonatomic, weak) id <MobileAppTrackerRegionDelegate> delegate;

-(void) addBeaconRegion:(NSUUID*)UUID
                 nameId:(NSString*)nameId
                majorId:(NSUInteger)majorId
                minorId:(NSUInteger)minorId;

@end
