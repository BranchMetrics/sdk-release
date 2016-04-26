//
//  TuneAnalyticsDispatchEventsOperation.h
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/13/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneFileManager.h"

@interface TuneAnalyticsDispatchEventsOperation : NSOperation {
    @private
    
    NSString *urlString;
    BOOL echoAnalytics;
    
    NSNumber *timeoutInterval;
    
    NSString *appId;
    NSString *deviceId;
}

@property (nonatomic, assign) BOOL includeTracer;

- (id)initWithTuneManager:(TuneManager *)manager;

@end
