//
//  Tune+Testing.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/25/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "Tune+Internal.h"

@interface Tune (Testing)

+ (void)setPluginName:(NSString *)pluginName;
+ (void)reInitSharedManagerOverride;
+ (void)setAllowDuplicateRequests:(BOOL)allowDup;

+ (void)waitUntilAllOperationsAreFinishedOnQueue;

@end
