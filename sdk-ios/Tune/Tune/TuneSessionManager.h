//
//  TuneSessionManager.h
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/17/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneModule.h"

@interface TuneSessionManager : TuneModule

/* Returns the time since the session began. If there is no current
 session, 0 will be returned. */
- (NSTimeInterval)timeSinceSessionStart;

@end
