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

@implementation TuneAnalyticsSubmitter

- (id)init
{
    self = [super init];
    
    if (self) {
        self.sessionId = [[TuneManager currentManager].userProfile sessionId];
        self.deviceId = [TuneManager currentManager].userProfile.deviceId;
        self.ifa = [[TuneManager currentManager].userProfile appleAdvertisingIdentifier];
    }
    return self;
}

- (id)initWithSessionId:(NSString *)sessionId
               deviceId:(NSString *)deviceId
                    ifa:(NSString *)ifa {
    self = [super init];
    
    if( self ) {
        self.sessionId = sessionId;
        self.deviceId = deviceId;
        self.ifa = ifa;
    }
    return self;
}

- (NSDictionary *) toDictionary {
    return @{ @"sessionId" : [TuneUtils objectOrNull:self.sessionId],
              @"deviceId" : [TuneUtils objectOrNull:self.deviceId],
              @"ifa"  : [TuneUtils objectOrNull:self.ifa], };
}

@end
