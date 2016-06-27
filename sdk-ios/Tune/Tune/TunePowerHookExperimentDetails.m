//
//  TunePowerHookExperimentDetails.m
//  TuneMarketingConsoleSDK
//
//  Created by Audrey Troutt on 3/5/15.
//
//

#import "TunePowerHookExperimentDetails+Internal.h"
#import "TunePowerHookValue.h"
#import "TuneDateUtils.h"
#import "TuneExperimentDetails+Internal.h"
#import "TuneUtils.h"

NSString *const DetailDictionaryExperimentStartDateKey = @"experiment_start_date";
NSString *const DetailDictionaryExperimentEndDateKey = @"experiment_end_date";
NSString *const DetailDictionaryExperimentIsRunningKey = @"is_running";

@implementation TunePowerHookExperimentDetails

- (instancetype)initWithDetailsDictionary:(NSDictionary *)detailsDictionary andPowerHookValue:(TunePowerHookValue *)variable andHookId:(NSString *)hookId {
    self = [super initWithDictionary:detailsDictionary];
    
    if (self) {
        _hookId = hookId;
        if (variable.startDate != nil) {
            _experimentStartDate = [[TuneDateUtils dateFormatterIso8601UTC] dateFromString:variable.startDate];
        }
        
        if (variable.endDate != nil) {
            _experimentEndDate = [[TuneDateUtils dateFormatterIso8601UTC] dateFromString:variable.endDate];
        }
    }
    return self;
}

- (BOOL)isRunning {
    BOOL afterStartDate = NO;
    BOOL beforeEndDate = NO;
    if (_experimentStartDate != nil) {
        afterStartDate = ([_experimentStartDate compare:[NSDate date]] == NSOrderedAscending);
    }
    if (_experimentEndDate != nil) {
        beforeEndDate = ([_experimentEndDate compare:[NSDate date]] == NSOrderedDescending);
    }
    return afterStartDate && beforeEndDate;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Power Hook Experiment Details { Hook ID: %@ | Experiment ID: %@ | Experiment Name: %@ | Current Variation ID: %@ | Current Variation Name: %@ | isRunning: %@ }", self.hookId, self.experimentId, self.experimentName, self.currentVariantId, self.currentVariantName, ([self isRunning] ? @"YES" : @"NO")];
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary* detailsDictionary = [[super toDictionary] mutableCopy];
    
    detailsDictionary[DetailDictionaryExperimentStartDateKey] = [TuneUtils objectOrNull:_experimentStartDate];
    detailsDictionary[DetailDictionaryExperimentEndDateKey] = [TuneUtils objectOrNull:_experimentEndDate];
    NSString *isRunning = @"false";
    if ([self isRunning]) {
        isRunning = @"true";
    }
    detailsDictionary[DetailDictionaryExperimentIsRunningKey] = isRunning;
    
    return detailsDictionary;
}

@end
