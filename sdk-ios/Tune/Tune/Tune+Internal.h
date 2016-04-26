//
//  Tune+Internal.h
//  Tune
//
//  Created by Tune on 03/20/14.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import "Tune.h"

@class TuneTracker;

@interface Tune ()

+ (TuneTracker *)sharedManager;

// These aren't currently enabled, but will be in a later release

/**
* Registers a single-value (non-code-block) Power Hook for use with TUNE.
*
* Use this method to declare the existence of a Power Hook you would like to pass in from TUNE.  This declaration should occur in the `didFinishLaunchingWithOptions:` method of your main app delegate, *before* you start TUNE using the `[ARManager startWithAppId:version:]` method.
*
* @param hookId The name of the configuration setting to register. Name must be unique for this app and cannot be empty.
* @param friendlyName The name for this hook that will be displayed in TMC. This value cannot be empty.
* @param description The description you would like to associate with this Power Hook. This will be displayed in TMC and gives context to others in your organization about what this Power Hook does.
* @param defaultValue The default value for this hook.  This value will be used if no value is passed in from TMC for this app. This value cannot be nil.
*/
+ (void)registerHookWithId:(NSString *)hookId friendlyName:(NSString *)friendlyName defaultValue:(NSString *)defaultValue description:(NSString *)description;

/**
 * Registers a single-value (non-code-block) Power Hook for use with TUNE.
 *
 * Use this method to declare the existence of a Power Hook you would like to pass in from TUNE.  This declaration should occur in the `didFinishLaunchingWithOptions:` method of your main app delegate, *before* you start TUNE using the `[ARManager startWithAppId:version:]` method.
 *
 * @param hookId The name of the configuration setting to register. Name must be unique for this app and cannot be empty.
 * @param friendlyName The name for this hook that will be displayed in TMC. This value cannot be empty.
 * @param description The description you would like to associate with this Power Hook. This will be displayed in TMC and gives context to others in your organization about what this Power Hook does.
 * @param approvedValues A non-empty array of NSString values that this Power Hook accepts. These values allow you (the developer) to restrict the use of this Power Hook to a strict set of values that can be applied via TMC. i.e. `@[ @"YES", @"NO" ]` or `@[ @"USER_FLOW1", @"USER_FLOW2", @"USER_FLOW3", ...]`
 * @param defaultValue The default value for this hook.  This value will be used if no value is passed in from TMC for this app. This value cannot be nil.
 */
+ (void)registerHookWithId:(NSString *)hookId friendlyName:(NSString *)friendlyName defaultValue:(NSString *)defaultValue description:(NSString *)description approvedValues:(NSArray *)approvedValues;

/**
 * Registers a deep action for use with TUNE Marketing Automation.
 *
 * Use this method to declare the existence of a deep action you would like to use in your app with data that is configurable from TUNE Markeing Automation.
 *
 * *NOTE:* If this block is executed from a push message or URL the thread calling the block of code is guaranteed to be the main thread. If the code inside of the block requires executing on a background thread you will need to implement this logic.
 *
 * @param deepActionId The name of the code to register. Name must be unique for this app and cannot be empty.
 * @param friendlyName The name for this deep action that will be displayed in TUNE Marketing Automation. This value cannot be empty.
 * @param description The description for this deep action that will appear in the web console.
 * @param data The default data for this deep action. This should be string keys and values. This data will be used if no data is passed in from TUNE Marketing Automation for this deep action for this app. This may be an empty dictionary but it cannot be nil.
 * @param deepAction The reusable block of code that you are registering with TUNE. We will merge the values from TUNE Marketing Automation with this extra data. A block is required, this parameter cannot be nil.
 */
+ (void)registerDeepActionWithId:(NSString *)deepActionId friendlyName:(NSString *)friendlyName description:(NSString *)description data:(NSDictionary *)data andAction:(void (^)(NSDictionary *extra_data))deepAction;

/**
 * Registers a deep action for use with TUNE Marketing Automation.
 *
 * Use this method to declare the existence of a deep action you would like to use in your app with data that is configurable from TUNE Markeing Automation.
 *
 * *NOTE:* If this block is executed from a push message or URL the thread calling the block of code is guaranteed to be the main thread. If the code inside of the block requires executing on a background thread you will need to implement this logic.
 *
 * @param deepActionId The name of the code to register. Name must be unique for this app and cannot be empty.
 * @param friendlyName The name for this deep action that will be displayed in TUNE Marketing Automation. This value cannot be empty.
 * @param description The description for this deep action that will appear in the web console.
 * @param data The default data for this deep action. This should be string keys and values. This data will be used if no data is passed in from TUNE Marketing Automation for this deep action for this app. This may be an empty dictionary but it cannot be nil.
 * @param approvedValues The approved values for the data dictionary.  This parameter may be nil, but if it isn't then the possible values that can be sent over from the web console will be limited to what is specified.  Each key should be a NSString related to the appropriate key in 'data'. If you don't want to limit what can be set from the web console for specific variable do not include it in the array. The value should be a non-empty array of all possible values to allow for as NSStrings.
 * @param deepAction The reusable block of code that you are registering with TUNE. We will merge the values from TUNE Marketing Automation with this extra data. A block is required, this parameter cannot be nil.
 */
+ (void)registerDeepActionWithId:(NSString *)deepActionId friendlyName:(NSString *)friendlyName description:(NSString *)description data:(NSDictionary *)data approvedValues:(NSDictionary *)approvedValues andAction:(void (^)(NSDictionary *extra_data))deepAction;

+ (void)registerCustomProfileBoolean:(NSString *)variableName;
+ (void)registerCustomProfileString:(NSString *)variableName hashed:(BOOL)shouldHash;
+ (void)registerCustomProfileVersion:(NSString *)variableName;
+ (void)registerCustomProfileBoolean:(NSString *)variableName withDefault:(NSNumber *)value;
+ (void)registerCustomProfileString:(NSString *)variableName withDefault:(NSString *)value hashed:(BOOL)shouldHash;
+ (void)registerCustomProfileVersion:(NSString *)variableName withDefault:(NSString *)value;
+ (void)setCustomProfileVersionValue:(NSString *)value forVariable:(NSString *)name;

@end
