//
//  TuneDeepActionManager.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/29/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TuneModule.h"

@interface TuneDeepActionManager : TuneModule

- (void)registerDeepActionWithId:(NSString *)deepActionId friendlyName:(NSString *)friendlyName description:(NSString *)description data:(NSDictionary *)data approvedValues:(NSDictionary *)approvedValues andAction:(void (^)(NSDictionary *extra_data)) deepAction;

- (NSArray *)getDeepActions;

- (void)executeDeepActionWithId:(NSString *)deepActionId andData:(NSDictionary *)data;

@end
