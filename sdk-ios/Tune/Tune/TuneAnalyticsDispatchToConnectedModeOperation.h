//
//  TuneAnalyticsDispatchToConnectedModeOperation.h
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/13/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TuneManager;
@class TuneAnalyticsEvent;

@interface TuneAnalyticsDispatchToConnectedModeOperation : NSOperation {
@private
    BOOL echoAnalytics;
    
    TuneAnalyticsEvent *event;
}

- (id)initWithTuneManager:(TuneManager *)manager event:(TuneAnalyticsEvent *) eventToSend;

@end
