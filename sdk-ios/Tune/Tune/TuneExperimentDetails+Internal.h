//
//  TuneExperimentDetails+Internal.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/29/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TuneExperimentDetails.h"

@interface TuneExperimentDetails ()

- (instancetype)initWithDictionary:(NSDictionary *)detailsDictionary;

- (void)copyPropertiesFromDictionary:(NSDictionary *)detailsDictionary;

@end
