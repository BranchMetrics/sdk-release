//
//  TuneAnalyticsDispatchEventsOperation+Testing.h
//  TuneMarketingConsoleSDK
//
//  Created by Harshal Ogale on 5/10/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import "TuneAnalyticsDispatchEventsOperation.h"

@interface TuneAnalyticsDispatchEventsOperation (Testing)

- (BOOL)postAnalytics:(NSArray *)eventsToSubmit toURL:(NSURL *)url error:(NSError **)error;

@end
