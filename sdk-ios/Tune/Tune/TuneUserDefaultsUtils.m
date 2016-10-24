//
//  TuneUserDefaultsUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 8/17/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneUserDefaultsUtils.h"

@implementation TuneUserDefaultsUtils

static NSString* const USER_DEFAULT_KEY_PREFIX = @"_TUNE_";
static NSString* const USER_DEFAULT_CUSTOM_VARIABLE_KEY_PREFIX = @"_TUNE_CUSTOM_VARIABLE_";

static id customDefaults;

+ (void)initialize {
#if TESTING
    customDefaults = @{}.mutableCopy;
#endif
}

#if TESTING

+ (void)useNSUserDefaults:(BOOL)enabled {
    customDefaults = enabled ? [NSUserDefaults standardUserDefaults] : @{}.mutableCopy;
}

+ (void)setUserDefaultValue:(id)value forKey:(NSString* )key addKeyPrefix:(BOOL)addPrefix {
    if (value == [NSNull null] || value == nil) {
        return;
    }
    if (addPrefix) {
        key = [self tunePrefixedKey:key];
    }
    [[self userDefaults] setValue:value forKey:key];
}

+ (void)clearAll {
    [customDefaults removeAllObjects];
}

#endif

+ (id)userDefaultValueforKey:(NSString *)key {
    NSString *newKey = [self tunePrefixedKey:key];
    id value = [[self userDefaults] valueForKey:newKey];
    
    if (value) {
        return value;
    } else {
        return [[self userDefaults] valueForKey:key];
    }
}

+ (void)setUserDefaultValue:(id)value forKey:(NSString* )key {
    if (value == [NSNull null] || value == nil) {
        return;
    }
    
    key = [self tunePrefixedKey:key];
    [[self userDefaults] setValue:value forKey:key];
}

+ (void)clearUserDefaultValue:(NSString *)key {
    [[self userDefaults] removeObjectForKey:[self tunePrefixedKey:key]];
}

+ (TuneAnalyticsVariable *)userDefaultCustomVariableforKey:(NSString *)key {
    NSData *data = (NSData *)[[self userDefaults] valueForKey:[self tunePrefixedKey:key isCustomVariable:YES]];
    
    if (!data) {
        return nil;
    }
    
    TuneAnalyticsVariable *unArchived = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    return unArchived;
}

+ (void)setUserDefaultCustomVariable:(TuneAnalyticsVariable *)value forKey:(NSString *)key {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
    
    [[self userDefaults] setValue:data forKey:[self tunePrefixedKey:key isCustomVariable:YES]];
}

+ (void)clearCustomVariable:(NSString *)key {
    [[self userDefaults] removeObjectForKey:[self tunePrefixedKey:key isCustomVariable:YES]];
}

+ (void)synchronizeUserDefaults {
#if !TESTING
    [[NSUserDefaults standardUserDefaults] synchronize];
#endif
}

+ (NSString *)tunePrefixedKey:(NSString *)key {
    return [self tunePrefixedKey:key isCustomVariable:NO];
}

+ (NSString *)tunePrefixedKey:(NSString *)key isCustomVariable:(BOOL)custom {
    NSString *prefix = custom ? USER_DEFAULT_CUSTOM_VARIABLE_KEY_PREFIX : USER_DEFAULT_KEY_PREFIX;
    return [NSString stringWithFormat:@"%@%@", prefix, key];
}

+ (id)userDefaults {
#if TESTING
    return customDefaults;
#else
    return [NSUserDefaults standardUserDefaults];
#endif
}

@end
