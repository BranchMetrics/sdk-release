//
//  TuneDeepAction.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/29/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TuneDeepAction.h"
#import "TuneUtils.h"

NSString *const DEEPACTION_ID = @"name";
NSString *const DEEPACTION_FRIENDLY_NAME = @"friendly_name";
NSString *const DEEPACTION_DESCRIPTION = @"description";
NSString *const DEEPACTION_APPROVED_VALUES = @"approved_values";
NSString *const DEEPACTION_DEFAULT_DATA = @"default_data";

@implementation TuneDeepAction

- (id)initWithDeepActionId:(NSString *)deepActionId friendlyName:(NSString *)friendlyName description:(NSString *)description action:(void (^)(NSDictionary *extra_data))action defaultData:(NSDictionary *)defaultData approvedValues:(NSDictionary *)approvedValues {
    self = [super init];
    if (self) {
        _deepActionId = deepActionId;
        _friendlyName = friendlyName;
        _deepActionDescription = description;
        _defaultData = defaultData;
        _approvedValues = approvedValues;
        self.action = action;
    }
    return self;
}

+ (BOOL)validateApprovedValues:(NSDictionary *)approvedValues {
    if ([approvedValues count] < 1) {
        ErrorLog(@"The approved values must have at least one key-value pair");
        return NO;
    }
    
    for (id toCheck in approvedValues) {
        if (![toCheck isKindOfClass:[NSString class]]) {
            ErrorLog(@"Each key must be a NSString. Got: %@", [[toCheck class] description]);
            return NO;
        }
        
        NSString *key = toCheck;
        
        if (![approvedValues[key] isKindOfClass:[NSArray class]]) {
            ErrorLog(@"Each value in the approved values must be a NSArray. Got: %@", [[approvedValues[key] class] description]);
            return NO;
        }
        
        if ([approvedValues[key] count] < 1) {
            ErrorLog(@"Each array must have atleast one value. If you want to permit any value for this key don't include it in the approved values.");
            return NO;
        }
        
        for (NSString *approved in approvedValues[key]) {
            if (![approved isKindOfClass:[NSString class]]) {
                ErrorLog(@"Each value in the NSArrays must be NSStrings. Got: %@", [[approved class] description]);
                return NO;
            }
        }
    }
    
    return YES;
}

#pragma mark - Misc.

- (NSDictionary *)toDictionary {
    return @{ DEEPACTION_ID: [TuneUtils objectOrNull:_deepActionId],
              DEEPACTION_FRIENDLY_NAME: [TuneUtils objectOrNull:_friendlyName],
              DEEPACTION_DESCRIPTION: [TuneUtils objectOrNull:_deepActionDescription],
              DEEPACTION_DEFAULT_DATA: [TuneUtils objectOrNull:_defaultData],
              DEEPACTION_APPROVED_VALUES: [TuneUtils objectOrNull:_approvedValues] };
}

- (NSString *)description {
    return [NSString stringWithFormat:@"deepActionId: %@, friendlyName: %@, block:%p, defaultData: %@", self.deepActionId, self.friendlyName, (void *)self.action, self.defaultData];
}

@end
