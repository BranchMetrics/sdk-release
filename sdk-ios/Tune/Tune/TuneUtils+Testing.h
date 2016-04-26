//
//  TuneUtils+Testing.h
//  Tune
//
//  Created by Harshal Ogale on 7/31/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import "TuneUtils.h"

@interface TuneUtils (Testing)

+ (void)overrideNetworkReachability:(NSString *)reachable;

@end
