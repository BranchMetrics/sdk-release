//
//  TuneUserDefaultsUtils.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 8/17/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneAnalyticsVariable.h"

/**
 Wrapper for interacting with NSUserDefaults standardDefaults. Note that the setters in this class do not include a call to NSUserDefaults synchronize() method. The SDK calls NSUserDefaults synchronize() method only once just before the app becomes inactive.
 */
@interface TuneUserDefaultsUtils : NSObject

/**
 Returns value for new key if it exists, else returns value for old key.
 e.g.
 - regular variable: old key = "some_key", new key = "_TUNE_some_key"
 - custom variable: old key = "some_other_key", new key = "_TUNE_CUSTOM_VARIABLE_some_other_key"
 */
+ (id)userDefaultValueforKey:(NSString *)key;
+ (void)setUserDefaultValue:(id)value forKey:(NSString* )key;
+ (void)clearUserDefaultValue:(NSString *)key;

+ (TuneAnalyticsVariable *)userDefaultCustomVariableforKey:(NSString *)key;
+ (void)setUserDefaultCustomVariable:(TuneAnalyticsVariable *)value forKey:(NSString *)key;
+ (void)clearCustomVariable:(NSString *)key;

+ (void)synchronizeUserDefaults;

#if TESTING
+ (void)setUserDefaultValue:(id)value forKey:(NSString* )key addKeyPrefix:(BOOL)addPrefix;
+ (void)clearAll;
+ (void)useNSUserDefaults:(BOOL)enabled;
#endif

@end
