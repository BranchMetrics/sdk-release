//
//  TuneFBBridge.h
//  Tune
//
//  Created by John Bender on 10/8/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TuneEvent;

@interface TuneFBBridge : NSObject

+ (void)sendEvent:(TuneEvent *)name limitEventAndDataUsage:(BOOL)limit;

@end
