//
//  TunePowerHookValue.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 7/28/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TunePowerHookValue.h"
#import "TuneDateUtils.h"

NSString *const POWERHOOKVALUE_NAME = @"name";
NSString *const POWERHOOKVALUE_DEFAULT_VALUE = @"default_value";
NSString *const POWERHOOKVALUE_VALUE = @"value";
NSString *const POWERHOOKVALUE_EXPERIMENT_VALUE = @"experiment_value";
NSString *const POWERHOOKVALUE_START_DATE = @"start_date";
NSString *const POWERHOOKVALUE_END_DATE = @"end_date";
NSString *const POWERHOOKVALUE_VARIATION_ID = @"variation_id";
NSString *const POWERHOOKVALUE_EXPERIMENT_ID = @"experiment_id";
NSString *const POWERHOOKVALUE_FRIENDLY_NAME = @"friendly_name";
NSString *const POWERHOOKVALUE_DESCRIPTION = @"description";
NSString *const POWERHOOKVALUE_APPROVED_VALUES = @"approved_values";

@implementation TunePowerHookValue

#pragma mark - Initialization

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        [self setupWithDictionary:dictionary];
    }
    return self;
}

-(void) setupWithDictionary:(NSDictionary *)dictionary {
    _name = dictionary[POWERHOOKVALUE_NAME];
    _defaultValue = dictionary[POWERHOOKVALUE_DEFAULT_VALUE];
    value = dictionary[POWERHOOKVALUE_VALUE];
    _experimentValue = dictionary[POWERHOOKVALUE_EXPERIMENT_VALUE];
    _startDate = dictionary[POWERHOOKVALUE_START_DATE];
    _endDate = dictionary[POWERHOOKVALUE_END_DATE];
    _variationId = dictionary[POWERHOOKVALUE_VARIATION_ID];
    _experimentId = dictionary[POWERHOOKVALUE_EXPERIMENT_ID];
    _friendlyName = dictionary[POWERHOOKVALUE_FRIENDLY_NAME];
    _phookDescription = dictionary[POWERHOOKVALUE_DESCRIPTION];
    _approvedValues = dictionary[POWERHOOKVALUE_APPROVED_VALUES];
    
    
    if (self.startDate != nil) {
        startDateAsDate = [[TuneDateUtils dateFormatterIso8601UTC] dateFromString:self.startDate];
    }
    
    if (self.endDate != nil) {
        endDateAsDate = [[TuneDateUtils dateFormatterIso8601UTC] dateFromString:self.endDate];
    }
}

- (TunePowerHookValue *)cloneWithNewValue:(NSString *)aValue {
    NSMutableDictionary *objDict = [self toDictionary].mutableCopy;
    
    [objDict setValue:aValue forKey:@"value"];
    
    TunePowerHookValue *phValue = [[TunePowerHookValue alloc] initWithDictionary:objDict];
    
    return phValue;
}

#pragma mark - Value / Experiment Value

// Return the experiment value if the experiment is running, otherwise we return the last published value
- (NSString *)value {
    if ([self hasExperimentValue] && [self isExperimentRunning]) {
        return self.experimentValue;
    }
    
    return value;
}

- (BOOL)hasExperimentValue {
    return self.experimentValue != nil;
}

- (BOOL)isExperimentRunning {
    if (![self hasExperimentValue]) { return NO; }
    
    NSDate *now = [NSDate date];
    
    if([now isEqualToDate:startDateAsDate] ||
       [now isEqualToDate:endDateAsDate] ||
       (([now laterDate:startDateAsDate]==now) && ([now earlierDate:endDateAsDate]==now))){
        
        return YES;
    }
    
    return NO;
}

#pragma mark - Misc.

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if (self.name != nil) [dictionary setValue:self.name forKey:POWERHOOKVALUE_NAME];
    if (self.defaultValue != nil) [dictionary setValue:self.defaultValue forKey:POWERHOOKVALUE_DEFAULT_VALUE];
    if (self.value != nil) [dictionary setValue:self.value forKey:POWERHOOKVALUE_VALUE];
    if (self.experimentValue != nil) [dictionary setValue:self.experimentValue forKey:POWERHOOKVALUE_EXPERIMENT_VALUE];
    if (self.startDate != nil) [dictionary setValue:self.startDate forKey:POWERHOOKVALUE_START_DATE];
    if (self.endDate != nil) [dictionary setValue:self.endDate forKey:POWERHOOKVALUE_END_DATE];
    if (self.variationId != nil) [dictionary setValue:self.variationId forKey:POWERHOOKVALUE_VARIATION_ID];
    if (self.experimentId != nil) [dictionary setValue:self.experimentId forKey:POWERHOOKVALUE_EXPERIMENT_ID];
    if (self.friendlyName != nil) [dictionary setValue:self.friendlyName forKey:POWERHOOKVALUE_FRIENDLY_NAME];
    if (self.approvedValues != nil && self.approvedValues.count > 0) [dictionary setValue:self.approvedValues forKey:POWERHOOKVALUE_APPROVED_VALUES];
    if (self.phookDescription != nil) [dictionary setValue:self.phookDescription forKey:POWERHOOKVALUE_DESCRIPTION];
    return dictionary;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"name: %@, description: %@, startDate: %@, endDate: %@, variationId: %@, defaultValue: %@, value: %@, experimentValue: %@, experimentId: %@, friendlyName: %@, approvedValues: %@", self.name, self.phookDescription, self.startDate, self.endDate, self.variationId, self.defaultValue, value, self.experimentValue, self.experimentId, self.friendlyName, self.approvedValues];
}

@end
