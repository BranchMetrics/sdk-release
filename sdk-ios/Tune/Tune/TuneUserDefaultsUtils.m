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

+ (id)userDefaultValueforKey:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *newKey = [NSString stringWithFormat:@"%@%@", USER_DEFAULT_KEY_PREFIX, key];
    
    id value = [defaults valueForKey:newKey];
    
    // return value for new key if exists, else return value for old key
    if( value ) return value;
    return [defaults valueForKey:key];
}

+ (void)setUserDefaultValue:(id)value forKey:(NSString* )key
{
    if (value == [NSNull null] || value == nil) {
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    key = [NSString stringWithFormat:@"%@%@", USER_DEFAULT_KEY_PREFIX, key];
    [defaults setValue:value forKey:key];
    
    // Note: Moved this synchronize call to Tune handleNotification: -- UIApplicationWillResignActiveNotification notification,
    // so that the synchronize method instead of being called for each key, gets called only once just before the app becomes inactive.
    //[defaults synchronize];
}

+ (void)clearUserDefaultValue:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    key = [NSString stringWithFormat:@"%@%@", USER_DEFAULT_KEY_PREFIX, key];
    [defaults removeObjectForKey:key];
}

+ (TuneAnalyticsVariable *)userDefaultCustomVariableforKey:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *newKey = [NSString stringWithFormat:@"%@%@", USER_DEFAULT_CUSTOM_VARIABLE_KEY_PREFIX, key];

    NSData *data = (NSData *)[defaults valueForKey:newKey];
    
    if (!data) {
        return nil;
    }
    
    TuneAnalyticsVariable *unArchived = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    return unArchived;
}

+ (void)setUserDefaultCustomVariable:(TuneAnalyticsVariable *)value forKey:(NSString *)key
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    key = [NSString stringWithFormat:@"%@%@", USER_DEFAULT_CUSTOM_VARIABLE_KEY_PREFIX, key];
    [defaults setValue:data forKey:key];
}

+ (void)clearCustomVariable:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    key = [NSString stringWithFormat:@"%@%@", USER_DEFAULT_CUSTOM_VARIABLE_KEY_PREFIX, key];
    [defaults removeObjectForKey:key];
}

+ (void)synchronizeUserDefaults
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
