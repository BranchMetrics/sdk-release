//
//  TuneArrayUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneArrayUtils.h"

@implementation TuneArrayUtils

+ (BOOL)areAllElementsOfArray:(NSArray *)array ofType:(Class)type {
    __block BOOL result = true;
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (![obj isKindOfClass:type]) {
            result = false;
        }
    }];
    
    return result;
}

+ (BOOL)array:(NSArray *)array containsString:(NSString *)string {
    
    for (id obj in array) {
        if ([obj isKindOfClass:[NSString class]] && [obj isEqualToString:string]) {
            return YES;
        }
    }
    return NO;
}


@end
