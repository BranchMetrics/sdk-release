//
//  TuneState.m
//  Tune
//
//  Created by Kevin Jenkins on 6/11/13.
//
//

#import "TuneState.h"
#import "TuneReachability.h"
#import "TuneFileUtils.h"
#import "TuneFileManager.h"
#import "Tune+Internal.h"
#import "TuneManager.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookPayloadConstants.h"
#import "TuneSwizzleBlacklist.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneStorageKeys.h"

@implementation TuneState

NSDictionary *localConfig = nil;
BOOL connectedMode = NO;

#pragma mark - Initialization

- (void)dealloc {
    connectedMode = NO;
    localConfig = nil;
}

// These methods don't need an implementation since this module must always be up
- (void)bringUp {}
- (void)bringDown {}

+ (NSDictionary *)localConfiguration {
    // The local configuration is immutable, so it is safe to load it from disk only once.

    if (!localConfig) {
        localConfig = [TuneFileManager loadLocalConfigurationFromDisk];
    }
    return localConfig;
}

#pragma mark - Setters

+ (void)updateSwizzleDisabled:(BOOL)value {
    [TuneUserDefaultsUtils setUserDefaultValue:@(value) forKey:TMASwizzleDisabled];
}

+ (void)updateTMADisabledState:(BOOL)value {
    [TuneUserDefaultsUtils setUserDefaultValue:@(value) forKey:TMAStateDisabled];
}

+ (void)updateTMAPermanentlyDisabledState:(BOOL)value {
    [TuneUserDefaultsUtils setUserDefaultValue:@(value) forKey:TMAStatePermanentlyDisabled];
}

+ (void)updateDisabledClasses {
    [TuneSwizzleBlacklist reset];
}

+ (void)updateConnectedMode:(BOOL)value {
    connectedMode = value;
}

#pragma mark - Getters

+ (BOOL)isSwizzleDisabled {
    // If the key isn't in NSUserDefaults or the local configuration then the swizzle isn't disabled
    NSNumber *numDefaults = [TuneUserDefaultsUtils userDefaultValueforKey:TMASwizzleDisabled];
    return numDefaults != nil ? [numDefaults boolValue] : [TuneState checkLocalConfig:TMASwizzleDisabled returnIfNotFound:NO];
}

+ (BOOL)doSendScreenViews {
    // If the key isn't in NSUserDefaults or the local configuration then we don't send screen views.
    return [TuneState checkLocalConfig:TMASendScreenViews returnIfNotFound:NO];
}

+ (BOOL)isTMADisabled {
#if !TARGET_OS_IOS
    return YES;
#else
    // If we are permanently disabled we are always disabled
    if ([TuneState isTMAPermanentlyDisabled]) { return YES; }
    
    // If we are in connected mode then we can't be disabled.
    if (connectedMode) { return NO; }
    
    if ([TuneUserDefaultsUtils userDefaultValueforKey:TMAStateDisabled] != nil) {
        // If we have a value for our disabled state then we use that since it means the
        // user opted in at some point, we got a value from the server, and now we're using that
        // as our authoritative value.
        return [[TuneUserDefaultsUtils userDefaultValueforKey:TMAStateDisabled] boolValue];
    } else {
        // Defer to our TurnOnTMA flag in the Local Configuration
        return ![TuneState didOptIntoTMA];
    }
#endif
}

+ (BOOL)didOptIntoTMA {
    // We've opted into TMA if we've set the TurnOnTMA flag in our Local Configuration
    return [TuneState checkLocalConfig:TurnOnTMA returnIfNotFound:NO];
}

+ (BOOL)isTMAPermanentlyDisabled {
#if !TARGET_OS_IOS
    return YES;
#else
    // If the key isn't in NSUserDefaults or the local configuration then TMA isn't permanently disabled
    NSNumber *numDefaults = [TuneUserDefaultsUtils userDefaultValueforKey:TMAStatePermanentlyDisabled];
    return numDefaults != nil ? [numDefaults boolValue] : [TuneState checkLocalConfig:TMAStatePermanentlyDisabled returnIfNotFound:NO];
#endif
}

+ (BOOL)isDisabledClass:(NSString *)className {
    return [TuneSwizzleBlacklist classIsOnBlackList:className];
}

+ (BOOL)isInConnectedMode {
    return connectedMode;
}

#pragma mark - Helpers

+ (BOOL)checkLocalConfig:(NSString *)key returnIfNotFound:(BOOL)returnWith {
    NSDictionary *config = [TuneState localConfiguration];
    return config[key] != nil ? [config[key] boolValue] : returnWith;
}

#pragma mark - Testing Helpers

#if TESTING
+ (void)resetLocalConfig {
    // BEWARE: This method is only intended to be used for the unit tests
    localConfig = nil;
}
#endif

@end
