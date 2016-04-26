//
//  TuneUserDefaultsUtils.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 8/17/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneAnalyticsVariable.h"

@interface TuneUserDefaultsUtils : NSObject

+ (id)userDefaultValueforKey:(NSString *)key;
+ (void)setUserDefaultValue:(id)value forKey:(NSString* )key;
+ (void)clearUserDefaultValue:(NSString *)key;

+ (TuneAnalyticsVariable *)userDefaultCustomVariableforKey:(NSString *)key;
+ (void)setUserDefaultCustomVariable:(TuneAnalyticsVariable *)value forKey:(NSString *)key;
+ (void)clearCustomVariable:(NSString *)key;

+ (void)synchronizeUserDefaults;

@end
