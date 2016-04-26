//
//  TunePowerHookExperimentDetails+Internal.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/24/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TunePowerHookExperimentDetails.h"

@class TunePowerHookValue;

@interface TunePowerHookExperimentDetails ()

- (instancetype)initWithDetailsDictionary:(NSDictionary *)detailsDictionary andPowerHookValue:(TunePowerHookValue *)variable andHookId:(NSString *)hookId;

@end
