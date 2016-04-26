//
//  TuneAnalyticsSubmitter.h
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/6/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneAnalyticsSubmitter : NSObject

@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, copy) NSString *ifa;

- (id)initWithSessionId:(NSString *)sessionId
               deviceId:(NSString *)deviceId
                    ifa:(NSString *)ifa;

- (NSDictionary *) toDictionary;

@end
