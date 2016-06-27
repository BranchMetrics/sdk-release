//
//  TuneExperimentDetails.m
//  TuneMarketingConsoleSDK
//
//  Created by Scott Wasserman on 6/12/14.
//
//

#import "TuneExperimentDetails.h"
#import "TuneUtils.h"

NSString *const DetailDictionaryExperimentNameKey = @"name";
NSString *const DetailDictionaryExperimentIdKey = @"id";
NSString *const DetailDictionaryExperimentTypeKey = @"type";
NSString *const DetailDictionaryCurrentVariationKey = @"current_variation";
NSString *const DetailDictionaryCurrentVariationIdKey = @"id";
NSString *const DetailDictionaryCurrentVariationNameKey = @"name";
NSString *const DetailDictionaryCurrentVariationLetterKey = @"letter";

NSString *const DetailDictionaryTypePowerHook = @"power_hook";
NSString *const DetailDictionaryTypeInApp = @"in_app";

@implementation TuneExperimentDetails

- (instancetype)initWithDictionary:(NSDictionary *)detailsDictionary {
    self = [super init];
    if (self) {
        [self copyPropertiesFromDictionary:detailsDictionary];
    }
    return self;
}

- (void)copyPropertiesFromDictionary:(NSDictionary *)detailsDictionary {
    _experimentId = detailsDictionary[DetailDictionaryExperimentIdKey];
    _experimentName = detailsDictionary[DetailDictionaryExperimentNameKey];
    _experimentType = detailsDictionary[DetailDictionaryExperimentTypeKey];
    NSDictionary *currentVariationDict = detailsDictionary[DetailDictionaryCurrentVariationKey];
    _currentVariantId = currentVariationDict[DetailDictionaryCurrentVariationIdKey];
    _currentVariantName = currentVariationDict[DetailDictionaryCurrentVariationNameKey];
    _currentVariantLetter = currentVariationDict[DetailDictionaryCurrentVariationLetterKey];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"{\nExperiment name: %@\nExperiment ID: %@\nExperiment type: %@\nCurrent Variation ID: %@\nCurrent Variation Name: %@\n}", _experimentName, _experimentId, _experimentType, _currentVariantId, _currentVariantName];
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *detailsDictionary = [NSMutableDictionary dictionary];

    detailsDictionary[DetailDictionaryExperimentIdKey] = [TuneUtils objectOrNull:_experimentId];
    detailsDictionary[DetailDictionaryExperimentNameKey] = [TuneUtils objectOrNull:_experimentName];
    detailsDictionary[DetailDictionaryExperimentTypeKey] = [TuneUtils objectOrNull:_experimentType];
    
    NSMutableDictionary *currentVariationDict = [NSMutableDictionary dictionary];
    currentVariationDict[DetailDictionaryCurrentVariationIdKey] = [TuneUtils objectOrNull:_currentVariantId];
    currentVariationDict[DetailDictionaryCurrentVariationNameKey] = [TuneUtils objectOrNull:_currentVariantName];
    currentVariationDict[DetailDictionaryCurrentVariationLetterKey] = [TuneUtils objectOrNull:_currentVariantLetter];
    
    detailsDictionary[DetailDictionaryCurrentVariationKey] = currentVariationDict;

    return detailsDictionary;
}

@end
