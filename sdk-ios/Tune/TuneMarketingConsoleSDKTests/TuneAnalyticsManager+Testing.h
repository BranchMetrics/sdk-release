//
//  TuneAnalyticsManager+Testing.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/25/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TuneAnalyticsManager.h"

@interface TuneAnalyticsManager()

- (NSOperationQueue *) operationQueue;
- (void)waitForOperationsToFinish;
- (void)setDispatchScheduler:(NSTimer *)timer;

@end
