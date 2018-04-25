//
//  TunePowerHookExperimentDetails.h
//  TuneMarketingConsoleSDK
//
//  Copyright (c) 2015 Artisan Mobile. All rights reserved.
//

#import "TuneExperimentDetails.h"

/**
 Contains information about a Power Hook experiment.

 This does not include the current experimental value for the Power Hook variable or block. To get the current values use the appropriate methods on Tune.

 If the experiment is not running then some fields will be nil, including currentVariantId, currentVariantName, experimentId, experimentName, experimentType. You can check whether the experiment is currently running with **isRunning**.
 */
@interface TunePowerHookExperimentDetails : TuneExperimentDetails

/**
 Get the start date of the Power Hook experiment.

 @note This will be nil if this power hook value is not currently from an experiment. You can check whether the value is from an experiment with **isRunning**.
 */
@property (nonatomic, readonly) NSDate *experimentStartDate;

/**
 Get the end date for this power hook experiment. The end date can change if the experiment is manually ended early in Tune Marketing Automation Tools.

 @note This will be nil if this power hook value is not currently from an experiment. You can check whether the value is from an experiment with **isRunning**.
 */
@property (nonatomic, readonly) NSDate *experimentEndDate;

/**
 Whether this experiment is currently running in Tune Marketing Automation Tools.
 
 @note isRunning's method signature is:
     \- (BOOL)isRunning;
 */
@property (NS_NONATOMIC_IOSONLY, getter=isRunning, readonly) BOOL running;

/**
 @return the experiment details as a dictionary.
 */
- (NSDictionary *)toDictionary;

@end
