//
//  TunePowerHookValue.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 7/28/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TunePowerHookExperimentDetails+Internal.h"

extern NSString *const POWERHOOKVALUE_NAME;
extern NSString *const POWERHOOKVALUE_DEFAULT_VALUE;
extern NSString *const POWERHOOKVALUE_VALUE;
extern NSString *const POWERHOOKVALUE_EXPERIMENT_VALUE;
extern NSString *const POWERHOOKVALUE_START_DATE;
extern NSString *const POWERHOOKVALUE_END_DATE;
extern NSString *const POWERHOOKVALUE_VARIATION_ID;
extern NSString *const POWERHOOKVALUE_EXPERIMENT_ID;
extern NSString *const POWERHOOKVALUE_FRIENDLY_NAME;
extern NSString *const POWERHOOKVALUE_DESCRIPTION;
extern NSString *const POWERHOOKVALUE_APPROVED_VALUES;

@interface TunePowerHookValue : NSObject {
    NSDate *startDateAsDate;
    NSDate *endDateAsDate;
    NSString *value;
}

@property(nonatomic,readonly) NSString *name;
@property(nonatomic,readonly) NSString *defaultValue;
@property(nonatomic,readonly) NSString *experimentValue;
@property(nonatomic,readonly) NSString *startDate;
@property(nonatomic,readonly) NSString *endDate;
@property(nonatomic,readonly) NSString *variationId;
@property(nonatomic,readonly) NSString *value;
@property(nonatomic,readonly) NSString *experimentId;
@property(nonatomic,readonly) NSString *friendlyName;
@property(nonatomic,readonly) NSString *phookDescription;
@property(nonatomic,readonly) NSArray *approvedValues;

@property (nonatomic) TunePowerHookExperimentDetails *experimentDetails;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;
- (TunePowerHookValue *)cloneWithNewValue:(NSString *)value;
- (BOOL)isExperimentRunning;

@end
