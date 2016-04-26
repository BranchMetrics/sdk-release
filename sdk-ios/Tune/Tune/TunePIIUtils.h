//
//  TunePIIUtils.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 8/26/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneAnalyticsVariable.h"

@interface TunePIIUtils : NSObject

+ (BOOL)check:(NSString *)value hasPIIWithPIIRegexFiltersArray:(NSArray *)PIIRegexFiltersAsNSRegularExpressions;

@end
