//
//  TuneInAppMessageExperimentDetails.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/29/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TuneInAppMessageExperimentDetails+Internal.h"
#import "TuneDateUtils.h"
#import "TuneExperimentDetails+Internal.h"

@implementation TuneInAppMessageExperimentDetails

- (instancetype)initWithDetailsDictionary:(NSDictionary *)detailsDictionary {
    self = [super initWithDictionary:detailsDictionary];
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"In App Message Experiment Details { Experiment ID: %@ | Experiment Name: %@ | Current Variation ID: %@ | Current Variation Name: %@ }", self.experimentId, self.experimentName, self.currentVariantId, self.currentVariantName];
}

@end
