//
//  TuneRegionMonitor.h
//  Tune
//
//  Created by John Bender on 4/30/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

//#define DEBUG_REGION TRUE

@protocol TuneRegionDelegate;


@interface TuneRegionMonitor : NSObject

@property (nonatomic, weak) id <TuneRegionDelegate> delegate;

- (void)addBeaconRegion:(NSUUID*)UUID
                 nameId:(NSString*)nameId
                majorId:(NSUInteger)majorId
                minorId:(NSUInteger)minorId;

@end
