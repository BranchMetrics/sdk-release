//
//  TuneExperimentManager.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/29/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TuneModule.h"

@interface TuneExperimentManager : TuneModule

- (NSDictionary *)getPowerHookVariableExperimentDetails;
- (NSDictionary *)getInAppMessageExperimentDetails;

@end
