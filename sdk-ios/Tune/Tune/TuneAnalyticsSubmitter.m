//
//  TuneAnalyticsSubmitter.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/6/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TuneAnalyticsSubmitter.h"

#import "TuneManager.h"
#import "TuneUserProfile.h"
#import "TuneUtils.h"
#import "TuneDeviceUtils.h"

@implementation TuneAnalyticsSubmitter

- (instancetype)init {
    self = [super init];
    
    if(self) {
        _sessionId = [[TuneManager currentManager].userProfile.sessionId copy];
        _deviceId = [[TuneManager currentManager].userProfile.deviceId copy];
        _ifa = [TuneDeviceUtils currentDeviceIsTestFlight] ? _deviceId : [[TuneManager currentManager].userProfile.appleAdvertisingIdentifier copy];
    }
    
    return self;
}

- (NSDictionary *)toDictionary {
    return @{ @"sessionId" : [TuneUtils objectOrNull:self.sessionId],
              @"deviceId" : [TuneUtils objectOrNull:self.deviceId],
              @"ifa"  : [TuneUtils objectOrNull:self.ifa] };
}

@end
