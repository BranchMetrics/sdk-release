//
//  TuneAnalyticsDispatchToConnectedModeOperation.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 10/1/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneAnalyticsDispatchToConnectedModeOperation.h"
#import "TuneUserProfile.h"
#import "TuneAnalyticsEvent.h"
#import "TuneJSONUtils.h"
#import "TuneApi.h"

@implementation TuneAnalyticsDispatchToConnectedModeOperation

- (id)initWithTuneManager:(TuneManager *)manager event:(TuneAnalyticsEvent *) eventToSend {
    self = [self init];
    if (self) {
        echoAnalytics = manager.configuration.echoAnalytics;
        event = eventToSend;
    }
    return self;
}

- (void)main {
    @try {
        DebugLog(@"Dispatching the analytics events.");
        
        TuneHttpResponse *response = [self postAnalytics:event];
        
        if (response.error != nil) {
            DebugLog(@"Unable to send analytics information to server: %@", [response.error localizedDescription]);
        }
    }
    @catch (NSException *exception) {
        DebugLog(@"An exception occured: %@",exception.description);
    }
}

- (TuneHttpResponse *)postAnalytics:(TuneAnalyticsEvent *)eventToSubmit {
    NSDictionary *finalDictionary = @{ @"event": [eventToSubmit toDictionary] };
    
    TuneHttpRequest *request = [TuneApi getDiscoverEventRequest:finalDictionary];
    if (echoAnalytics) {
        NSLog(@"Posting Analytics to endpoint: %@", request.URL);
        NSLog(@"\n%@", [TuneJSONUtils createPrettyJSONFromDictionary:finalDictionary]);
    }
    
    return [request performSynchronousRequest];
}

@end
