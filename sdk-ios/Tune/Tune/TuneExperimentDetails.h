//
//  TuneExperimentDetails.h
//  TuneMarketingConsoleSDK
//
//  Copyright (c) 2014 Tune Mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Experiment details dictionary key "name" for an experiment.
 */
FOUNDATION_EXPORT NSString *const DetailDictionaryExperimentNameKey;
/**
 Experiment details dictionary key "id" for an experiment.
 */
FOUNDATION_EXPORT NSString *const DetailDictionaryExperimentIdKey;
/**
 Experiment details dictionary key "type" for an experiment.
 */
FOUNDATION_EXPORT NSString *const DetailDictionaryExperimentTypeKey;
/**
 Experiment details dictionary key "current_variation" for an experiment's current variation.
 */
FOUNDATION_EXPORT NSString *const DetailDictionaryCurrentVariationKey;
/**
 Experiment details dictionary key "id" for an experiment's current variation.
 */
FOUNDATION_EXPORT NSString *const DetailDictionaryCurrentVariationIdKey;
/**
 Experiment details dictionary key "name" for an experiment's current variation.
 */
FOUNDATION_EXPORT NSString *const DetailDictionaryCurrentVariationNameKey;
/**
 Experiment details dictionary key "power_hook" to denote Power Hook experiments.
 */
FOUNDATION_EXPORT NSString *const DetailDictionaryTypePowerHook;
/**
 Experiment details dictionary key "in_app" to denote In App experiments.
 */
FOUNDATION_EXPORT NSString *const DetailDictionaryTypeInApp;

/**
 * An object containing useful information about an experiment.
 **/
@interface TuneExperimentDetails : NSObject

/**
 * The id of the experiment.
 *
 * The experiment id is a unique identifier for an experiment.
 */
@property (nonatomic, readonly) NSString *experimentId;

/**
 * The name of the experiment.
 *
 * The experiment name is the same that you would see in Tune Marketing Automation Tools.
 */
@property (nonatomic, readonly) NSString *experimentName;

/**
 * The type of the experiment.
 */
@property (nonatomic, copy) NSString *experimentType;

/**
 * The current variant id for the experiment.
 *
 * The variant id is a unique identifier for the variation of an Tune Marketing Automation Experiment.
 */
@property (nonatomic, copy) NSString *currentVariantId;

/**
 * The current variant name for the experiment.
 *
 * The variant name is the same that you would see in Tune Marketing Automation Tools. Unless the names were edited in Artisan tools they are "Control", "B", "C", etc.
 */
@property (nonatomic, copy) NSString *currentVariantName;

/**
 * The current variant letter for the experiment.
 *
 * This will the be same as 'currentVariantName' unless you gave it a new name. Otherwise it will give the associated variation letter to the name.
 */
@property (nonatomic, copy) NSString *currentVariantLetter;

/**
 * Return the experiment details as a dictionary
 */
- (NSDictionary *)toDictionary;

@end
