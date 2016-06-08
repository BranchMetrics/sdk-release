//
//  TuneAnalyticsManager.h
//
//  Created by Daniel Koch on 6/26/12.
//  Copyright (c) 2012 AppRenaissance. All rights reserved.
//

#import "TuneAnalyticsEvent.h"
#import "TuneModule.h"


@interface TuneAnalyticsManager : TuneModule

#if !TARGET_OS_WATCH
- (void)endBackgroundTask;
#endif

- (TuneAnalyticsEvent *)buildTracerEvent;

@end
