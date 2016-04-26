//
//  TuneArrayUtils.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/12/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneArrayUtils : NSObject

+ (BOOL)areAllElementsOfArray:(NSArray *)array ofType:(Class)type;

+ (BOOL)array:(NSArray *)array containsString:(NSString *)string;

@end
