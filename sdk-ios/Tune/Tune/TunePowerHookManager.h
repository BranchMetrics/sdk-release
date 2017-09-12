//
//  TunePowerHookManager.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 7/27/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneModule.h"

@interface TunePowerHookManager : TuneModule

#pragma mark - PowerHook Registration/Setting

/**
 * Registers a single-value (non-code-block) Power Hook for use with TUNE.
 *
 * Use this method to declare the existence of a Power Hook you would like to pass in from TUNE.  This declaration should occur in the `didFinishLaunchingWithOptions:` method of your main app delegate, *before* you start TUNE using the `[TuneManager startWithAppId:version:]` method.
 *
 * @param hookId The name of the configuration setting to register. Name must be unique for this app and cannot be empty.
 * @param friendlyName The name for this hook that will be displayed in TMC. This value cannot be empty.
 * @param defaultValue The default value for this hook.  This value will be used if no value is passed in from TMC for this app. This value cannot be nil.
 */
- (void)registerHookWithId:(NSString *)hookId friendlyName:(NSString *)friendlyName defaultValue:(NSString *)defaultValue description:(NSString *)description approvedValues:(NSArray *)approvedValues;

/**
 * Gets the value of a single-value (non-code-block) Power Hook.
 *
 * Use this method to get the value of a Power Hook from TUNE.  This will return the value specified in TMC, or the default value if none has been specified.
 *
 * *NOTE*: When called in the context of an experiment this method triggers the view for the Power Hook variation value that is returned.
 *
 * @param hookId The name of the Power Hook you wish to retrieve. Will return nil if the setting has not been registered.
 */
- (NSString *)getValueForHookById:(NSString *)hookId;

/** Set the value of a single-value (non-code-block) Power Hook manually.
 *
 * Use this method to manually apply a value to an TUNE Power Hook.  The app will behave as if this value has been passed from TMC, and all calls to getValueForhookId: for this hookId will return this value.
 *
 * This method should be called in the `didFinishLaunchingWithOptions:` method of your main app delegate, immediately after regstering the corresponding hookId.
 *
 * @warning *Note:* This method is intended for local test and QA use only, and should *not* be used within production code.
 *
 * @param hookId The name of the Power Hook whose value you want to set.
 * @param value The value you want to specify for this Power Hook.  If the Power Hook has not been registered, this will be ignored. This value cannot be nil.
 */
- (void)setValueForHookById:(NSString *)hookId value:(NSString *)value;

- (void)onPowerHooksChanged:(void (^)(void))block;

- (NSArray *)getPowerHooks;

@end
