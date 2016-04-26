//
//  TunePIIUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 8/26/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TunePIIUtils.h"

@implementation TunePIIUtils

+ (BOOL)check:(NSString *)value hasPIIWithPIIRegexFiltersArray:(NSArray *)PIIRegexFiltersAsNSRegularExpressions {
    if (value == nil) {
        // If the value is nil then there is nothing to check
        return NO;
    }
    for (NSRegularExpression *regex in PIIRegexFiltersAsNSRegularExpressions) {
        if ([regex firstMatchInString:value options:0 range:NSMakeRange(0, [value length])]) {
            // We found something that needs to be filtered
            //DebugLog(@"Found a value %@ that needs to be PII scrubbed", value);
            return YES;
        }
    }

    return NO;
}

@end
