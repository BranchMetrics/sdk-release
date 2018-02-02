//
//  TuneConfigurationManager+Testing.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/25/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TuneConfiguration.h"

@interface TuneConfiguration (Testing)

- (void)updateConfigurationWithRemoteDictionary:(NSDictionary *)configuration;
- (void)updateConfigurationWithLocalDictionary:(NSDictionary *)configuration postSkyhook:(BOOL)shouldPostSkyhook;

@end
