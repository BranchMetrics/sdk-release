//
//  TuneDateUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 7/28/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneDateUtils.h"

@implementation TuneDateUtils

+ (NSDateFormatter*)dateFormatterIso8601 {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss+00:00"];
    return dateFormatter;
}

+ (NSDateFormatter*)dateFormatterIso8601UTC {
    NSDateFormatter *notThreadSafeDateFormatter = [[NSDateFormatter alloc] init];
    [notThreadSafeDateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [notThreadSafeDateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [notThreadSafeDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    
    return notThreadSafeDateFormatter;
}

+ (BOOL)date:(NSDate*)date isBetweenDate:(NSDate*)beginDate andEndDate:(NSDate*)endDate {
    return [date compare:beginDate] != NSOrderedAscending && [date compare:endDate] != NSOrderedDescending;
}

+ (int)daysBetween:(NSDate *)beginDate and:(NSDate *)endDate {
    NSUInteger unitFlags = NSCalendarUnitDay;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:unitFlags fromDate:beginDate toDate:endDate options:0];
    return (int)[components day];
}

@end
