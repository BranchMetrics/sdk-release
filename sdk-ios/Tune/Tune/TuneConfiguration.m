//
//  TuneConfiguration.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/3/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <mach/machine.h>
#import <Foundation/Foundation.h>

#if TARGET_OS_IOS
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif

#import <UIKit/UIKit.h>
#import "TuneConfiguration.h"
#import "Tune+Internal.h"
#import "TuneApi.h"
#import "TuneConfiguration.h"
#import "TuneUtils.h"
#import "TuneConfigurationKeys.h"
#import "TuneEvent+Internal.h"
#import "TuneFileManager.h"
#import "TuneFileUtils.h"
#import "TuneHttpRequest.h"
#import "TuneHttpResponse.h"
#import "TuneInstallReceipt.h"
#import "TuneKeyStrings.h"
#import "TuneManager.h"
#import "TuneSkyhookCenter.h"
#import "TuneState.h"
#import "TuneUserAgentCollector.h"
#import "TuneUtils.h"
#import "TuneStoreKitDelegate.h"
#import "TuneJSONPlayer.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneUserProfile.h"
#import "TuneJSONUtils.h"

NSDictionary *defaultConfiguration;

NSString *const TuneConfigurationPreviewModeKey = @"previewMode";

@implementation TuneConfiguration

#pragma mark - Initialization

- (id)initWithTuneManager:(TuneManager *)tuneManager {
    self = [super initWithTuneManager:tuneManager];
    
    if (self) {
        [self setDefaultConfiguration];
        
#if DEBUG_STAGING
        _staging = YES;
#endif
        
        _updatingConfiguration = NO;
    }
    
    return self;
}

// These methods don't need an implementation since this module must always be up
- (void)bringUp {}
- (void)bringDown {}

#pragma mark - Skyhook registration

- (void)registerSkyhooks {
    [self unregisterSkyhooks];
    
#if TARGET_OS_WATCH
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(didBecomeActiveSkyhook:)
                                              name:NSExtensionHostDidBecomeActiveNotification
                                            object:nil];
#else
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(didBecomeActiveSkyhook:)
                                              name:UIApplicationDidBecomeActiveNotification
                                            object:nil];
#endif
}

#pragma mark - Tune Version

+ (NSString *)frameworkVersion {
    return TUNEVERSION;
}

- (NSString *)apiVersion {
    return @"3";
}

#pragma mark - Skyhook Handlers

- (void)didBecomeActiveSkyhook:(TuneSkyhookPayload *)payload {
    [self updateFromServer];
}

#pragma mark - Action requests

- (NSString*)domainName {
    if(_staging) {
        return TUNE_SERVER_DOMAIN_REGULAR_TRACKING_STAGE;
    }
    return TUNE_SERVER_DOMAIN_REGULAR_TRACKING_PROD;
}

- (void)setDefaultConfiguration {
    _debugLoggingOn = NO;
    _staging = NO;
    _debugMode = @(NO);
    _echoAnalytics = NO;
    _echoFiveline = NO;
    _echoPlaylists = NO;
    _echoConfigurations = NO;
    _usePlaylistPlayer = NO;
    
    self.shouldAutoCollectDeviceLocation = YES;
    
#if !TARGET_OS_WATCH
    // Trigger the special update handlers
    self.shouldAutoDetectJailbroken = YES;
    self.shouldAutomateIapMeasurement = NO;
    self.shouldAutoCollectAdvertisingIdentifier = YES;
    self.shouldAutoGenerateVendorIdentifier = YES;
#endif
    
    _playlistHostPort = @"https://playlist.ma.tune.com";
    _configurationHostPort = @"https://configuration.ma.tune.com";
    _analyticsHostPort = @"https://analytics.ma.tune.com/analytics";
    _staticContentHostPort = @"https://s3.amazonaws.com/uploaded-assets-production";
    _connectedModeHostPort = @"https://connected.ma.tune.com";
    
    _analyticsDispatchPeriod = @(120);
    _analyticsMessageStorageLimit = @(250);
    
    _pollForPlaylist = NO;
    _playlistRequestPeriod = @(180);
    
    _pluginName = nil;
    
    _PIIFiltersAsNSStrings = @[];
}

- (void)setupConfiguration:(NSDictionary *)configuration {
    // load the saved config
    NSDictionary *dictStoredConfig = [TuneFileManager loadRemoteConfigurationFromDisk];
    
    // check if saved config is available
    if (dictStoredConfig) {
        // set config using in-code values
        [self updateConfigurationWithLocalDictionary:configuration postSkyhook:NO];
        
        // overwrite config using the latest saved config file and post a skyhook notification
        [self updateConfigurationWithDictionary:dictStoredConfig postSkyhook:YES];
    } else {
        // update config using the values provided in-code and post a skyhook notification
        [self updateConfigurationWithLocalDictionary:configuration postSkyhook:YES];
    }
}

- (void)updateConfigurationWithDictionary:(NSDictionary *)configuration postSkyhook:(BOOL)shouldPostSkyhook {
    [self updateAnalyticsDispatchRate:configuration];
    [self updateAnalyticsMessageStorageLimit:configuration];
    [self updatePollForPlaylist:configuration];
    [self updatePlaylistRequestPeriod:configuration];
    [self updateShouldAutoCollectDeviceLocation:configuration];
#if !TARGET_OS_WATCH
    [self updateShouldAutomateIapMeasurement:configuration];
    [self updateShouldAutoCollectAdvertisingIdentifier:configuration];
    [self updateShouldAutoDetectJailbroken:configuration];
    [self updateShouldAutoGenerateVendorIdentifier:configuration];
#endif
    [self updateEchoAnalytics:configuration];
    [self updateEchoPlaylists:configuration];
    [self updateEchoConfigurations:configuration];
    [self updateEchoFiveline:configuration];
    [self updatePIIRegexFilters:configuration];
    
    if(shouldPostSkyhook) {
        [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneConfigurationUpdated];
    }
}

- (void)updateConfigurationWithLocalDictionary:(NSDictionary *)configuration postSkyhook:(BOOL)shouldPostSkyhook {
    [self updateConfigurationWithDictionary:configuration postSkyhook:NO];
    
    [self updateDebugLogging:configuration];
    [self updateDebugMode:configuration];
    
    [self updatePlaylistHostPort:configuration];
    [self updateConfigurationHostPort:configuration];
    [self updateAnalyticsHostPort:configuration];
    [self updateConnectedModeHostPort:configuration];
    [self updateStaticContentHostPort:configuration];
    
    [self updateUsePlaylistPlayer:configuration];
    [self updatePlaylistPlayerFilenames:configuration];
    [self updateUseConfigurationPlayer:configuration];
    [self updateConfigurationPlayerFilenames:configuration];
    
    if(shouldPostSkyhook) {
        [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneConfigurationUpdated];
    }
}

- (void)updateConfigurationWithRemoteDictionary:(NSDictionary *)configuration {
    // Don't post the skyhook until everything has been updated
    [self updateConfigurationWithDictionary:configuration postSkyhook:NO];
    
    // These two are only updated on configuration download since the presence of them
    // is meaningful. IE If they don't exist then we wipe out what was stored in NSUserDefaults.
    [self updateSwizzleBlacklistAdditions:configuration];
    [self updateSwizzleBlacklistRemovals:configuration];
    [TuneState updateDisabledClasses];
    
    [self updateGlobalSwizzleOff:configuration];
    [self updateConnectedModeState:configuration];

    // We only want to change these settings if it is not permanently disabled -- it is permanent after all
    //     Additionally, don't update the enabled/disabled status if we are in connected mode since going into
    //     connected mode affects the enabled/disabled status
    if (![TuneState isTMAPermanentlyDisabled] && ![TuneState isInConnectedMode]) {
        // These two should always be checked last
        [self updatePermanentlyDisableState:configuration];
        [self updateDisableState:configuration];
    }
    
    [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneConfigurationUpdated];
}

#pragma mark - Persistence

- (NSDictionary *)toDictionary {
    
    return @{TUNE_DEBUG_LOGGING_ON:@(_debugLoggingOn),
             TUNE_TMA_PLAYLIST_HOST_PORT:[TuneUtils objectOrNull:_playlistHostPort],
             TUNE_TMA_CONFIGURATION_HOST_PORT:[TuneUtils objectOrNull:_configurationHostPort],
             TUNE_TMA_ANALYTICS_HOST_PORT:[TuneUtils objectOrNull:_analyticsHostPort],
             TUNE_KEY_AUTOCOLLECT_LOCATION:@(_shouldAutoCollectDeviceLocation),
#if !TARGET_OS_WATCH
             TUNE_KEY_AUTOCOLLECT_JAILBROKEN:@(_shouldAutoDetectJailbroken),
             TUNE_KEY_AUTOCOLLECT_IFA:@(_shouldAutoCollectAdvertisingIdentifier),
             TUNE_KEY_AUTOCOLLECT_IFV:@(_shouldAutoGenerateVendorIdentifier),
#endif
             TUNE_KEY_DEBUG:[TuneUtils objectOrNull:_debugMode],
             TUNE_ANALYTICS_DISPATCH_PERIOD:_analyticsDispatchPeriod,
             TUNE_ANALYTICS_MESSAGE_LIMIT:_analyticsMessageStorageLimit,
             TUNE_POLL_FOR_PLAYLIST: @(_pollForPlaylist),
             TUNE_PLAYLIST_REQUEST_PERIOD:_playlistRequestPeriod,
             TUNE_TMA_PII_FILTERS_NSSTRING:_PIIFiltersAsNSStrings
             };
}

#pragma mark - Update

- (void)updateFromServer {
    // Unlike most downloads we actually *do* want to download the configuration if Tune is off (inactive but not permakilled)
    if ([TuneState isTMAPermanentlyDisabled]) { return; }
    
    // Only request the configuration if our user has Turned on TMA through their local configuration
    if (![TuneState didOptIntoTMA]) { return; }
    
    if (_updatingConfiguration) { return; }
    
    _updatingConfiguration = YES;

    TuneHttpRequest *request = [TuneApi getConfigurationRequest];
    
    if (request == nil) {
        _updatingConfiguration = NO;
        return;
    }
    
    [request performAsynchronousRequestWithCompletionBlock:^(TuneHttpResponse *response) {
        @try {
            if ([response error]) {
                WarnLog(@"Unable to download configuration. %@", [[response error] localizedDescription]);
            } else {
                InfoLog(@"Successfully downloaded the configuration.");
            }
            
            NSDictionary *configurationDictionary = nil;
            
            if (self.tuneManager.configuration.useConfigurationPlayer) {
                configurationDictionary = [self.tuneManager.configurationPlayer getNext];
                
            // check if the config was successfully downloaded
            } else if (response.wasSuccessful) {
                if (response.responseDictionary) {
                    configurationDictionary = response.responseDictionary;
                } else {
                    configurationDictionary = @{};
                }
            }
            
            if (configurationDictionary == nil) {
                WarnLog(@"Configuration response did not have any JSON");
            } else if (configurationDictionary.count == 0) {
                /*
                 *  IMPORTANT:
                 *      An empty configuration is a signal from the server to not process anything
                 */
                WarnLog(@"Received empty configuration from the server -- not updating");
            } else {
                if (_echoConfigurations) {
                    NSLog(@"Got configuration:\n%@", [TuneJSONUtils createPrettyJSONFromDictionary:configurationDictionary withSecretTMADepth:nil]);
                }
                
                // save config to disk
                [TuneFileManager saveRemoteConfigurationToDisk:configurationDictionary];
                
                // update config and post a skyhook notification
                [self updateConfigurationWithRemoteDictionary:configurationDictionary];
            }
        } @catch (NSException *exception) {
            ErrorLog(@"Error processing the configuration: %@", exception);
        } @finally {
            _updatingConfiguration = NO;
        }
    }];
}

#pragma mark - Dictionary Setters

- (void)updatePlaylistHostPort:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_TMA_PLAYLIST_HOST_PORT]) {
        _playlistHostPort = configurationDictionary[TUNE_TMA_PLAYLIST_HOST_PORT];
    }
}

- (void)updateConfigurationHostPort:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_TMA_CONFIGURATION_HOST_PORT]) {
        _configurationHostPort = configurationDictionary[TUNE_TMA_CONFIGURATION_HOST_PORT];
    }
}

- (void)updateAnalyticsHostPort:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_TMA_ANALYTICS_HOST_PORT]) {
        _analyticsHostPort = configurationDictionary[TUNE_TMA_ANALYTICS_HOST_PORT];
    }
}

- (void)updateStaticContentHostPort:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_TMA_STATIC_CONTENT_HOST_PORT]) {
        _staticContentHostPort = configurationDictionary[TUNE_TMA_STATIC_CONTENT_HOST_PORT];
    }
}

- (void)updateDebugMode:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_KEY_DEBUG]!=nil) {
        _debugMode = configurationDictionary[TUNE_KEY_DEBUG];
        
        // show an alert if the debug mode is enabled
        if([_debugMode boolValue]) {
#if !TARGET_OS_WATCH
            if([UIApplication sharedApplication])
#endif
            [TuneUtils showAlertWithTitle:@"Warning" message:@"TUNE Debug Mode Enabled. Use only when debugging, do not release with this enabled!!"];
        }
    }
}

- (void)updateEchoAnalytics:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_KEY_ECHO_ANALYTICS]!=nil) {
        _echoAnalytics = [configurationDictionary[TUNE_KEY_ECHO_ANALYTICS] boolValue];
    }
}

- (void)updateEchoPlaylists:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_KEY_ECHO_PLAYLISTS]!=nil) {
        _echoPlaylists = [configurationDictionary[TUNE_KEY_ECHO_PLAYLISTS] boolValue];
    }
}

- (void)updateEchoConfigurations:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_KEY_ECHO_CONFIGURATIONS]!=nil) {
        _echoConfigurations = [configurationDictionary[TUNE_KEY_ECHO_CONFIGURATIONS] boolValue];
    }
}

- (void)updateEchoFiveline:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_KEY_ECHO_FIVELINE]!=nil) {
        self.echoFiveline = [configurationDictionary[TUNE_KEY_ECHO_FIVELINE] boolValue];
    }
}

- (void)updateUsePlaylistPlayer:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_KEY_USE_PLAYLIST_PLAYER]!=nil) {
        _usePlaylistPlayer = [configurationDictionary[TUNE_KEY_USE_PLAYLIST_PLAYER] boolValue];
    }
}

- (void)updatePlaylistPlayerFilenames:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_KEY_PLAYLIST_PLAYER_FILENAMES]!=nil) {
        _playlistPlayerFilenames = configurationDictionary[TUNE_KEY_PLAYLIST_PLAYER_FILENAMES];
    }
}

- (void)updateUseConfigurationPlayer:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_KEY_USE_CONFIGURATION_PLAYER]!=nil) {
        _useConfigurationPlayer = [configurationDictionary[TUNE_KEY_USE_CONFIGURATION_PLAYER] boolValue];
    }
}

- (void)updateConfigurationPlayerFilenames:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_KEY_CONFIGURATION_PLAYER_FILENAMES]!=nil) {
        _configurationPlayerFilenames = configurationDictionary[TUNE_KEY_CONFIGURATION_PLAYER_FILENAMES];
    }
}

- (void)updateShouldAutoCollectDeviceLocation:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_KEY_AUTOCOLLECT_LOCATION]) {
        _shouldAutoCollectDeviceLocation = [configurationDictionary[TUNE_KEY_AUTOCOLLECT_LOCATION] boolValue];
    }
}

#if !TARGET_OS_WATCH
- (void)updateShouldAutoDetectJailbroken:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_KEY_AUTOCOLLECT_JAILBROKEN]) {
        _shouldAutoDetectJailbroken = [configurationDictionary[TUNE_KEY_AUTOCOLLECT_JAILBROKEN] boolValue];
        
        if (_shouldAutoDetectJailbroken) {
            [[TuneManager currentManager].userProfile setJailbroken:@([TuneUtils checkJailBreak])];
        } else {
            [[TuneManager currentManager].userProfile setJailbroken:nil];
        }
    }
}

- (void)updateShouldAutoCollectAdvertisingIdentifier:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_KEY_AUTOCOLLECT_IFA]) {
        _shouldAutoCollectAdvertisingIdentifier = [configurationDictionary[TUNE_KEY_AUTOCOLLECT_IFA] boolValue];
        
        if (_shouldAutoCollectAdvertisingIdentifier) {
            [[TuneManager currentManager].userProfile updateIFA];
        } else {
            [[TuneManager currentManager].userProfile clearIFA];
        }
    }
}

- (void)updateShouldAutoGenerateVendorIdentifier:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_KEY_AUTOCOLLECT_IFV]) {
        _shouldAutoGenerateVendorIdentifier = [configurationDictionary[TUNE_KEY_AUTOCOLLECT_IFV] boolValue];
        
        if(_shouldAutoGenerateVendorIdentifier) {
            if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
                NSString *uuidStr = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
                if (uuidStr && ![uuidStr isEqualToString:TUNE_KEY_GUID_EMPTY]) {
                    [[TuneManager currentManager].userProfile setAppleVendorIdentifier:uuidStr];
                }
            }
        } else {
            [[TuneManager currentManager].userProfile setAppleVendorIdentifier:nil];
        }
    }
}

- (void)updateShouldAutomateIapMeasurement:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_KEY_AUTO_IAP_MEASUREMENT]!=nil) {
        _shouldAutomateIapMeasurement = [configurationDictionary[TUNE_KEY_AUTO_IAP_MEASUREMENT] boolValue];
        
        if(_shouldAutomateIapMeasurement) {
            // start listening for in-app-purchase transactions
            [TuneStoreKitDelegate startObserver];
        } else {
            // stop listening for in-app-purchase transactions
            [TuneStoreKitDelegate stopObserver];
        }
    }
}
#endif

- (void)updateAnalyticsDispatchRate:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_ANALYTICS_DISPATCH_PERIOD]) {
        _analyticsDispatchPeriod = configurationDictionary[TUNE_ANALYTICS_DISPATCH_PERIOD];
    }
}

- (void)updateAnalyticsMessageStorageLimit:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_ANALYTICS_MESSAGE_LIMIT]) {
        _analyticsMessageStorageLimit = configurationDictionary[TUNE_ANALYTICS_MESSAGE_LIMIT];
    }
}

- (void)updatePollForPlaylist:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_POLL_FOR_PLAYLIST]) {
        _pollForPlaylist = [configurationDictionary[TUNE_POLL_FOR_PLAYLIST] boolValue];
    }
}

- (void)updatePlaylistRequestPeriod:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_PLAYLIST_REQUEST_PERIOD]) {
        _playlistRequestPeriod = configurationDictionary[TUNE_PLAYLIST_REQUEST_PERIOD];
    }
}

- (void)updateConnectedModeHostPort:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_TMA_CONNECTED_MODE_HOST_PORT]) {
        _connectedModeHostPort = configurationDictionary[TUNE_TMA_CONNECTED_MODE_HOST_PORT];
    }
}

- (void)updateDisableState:(NSDictionary*)configurationDictionary {
    if(configurationDictionary[TUNE_TMA_DISABLED]!=nil) {
        BOOL newState = [configurationDictionary[TUNE_TMA_DISABLED] boolValue];
        
        // Only update the disabled status if it is not equal to the current status
        // This is to prevent firing off the skyhooks more times then needed
        if (newState != [TuneState isTMADisabled]) {
            [TuneState updateTMADisabledState:newState];
            
            if (newState) {
                [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneStateTMADeactivated];
            } else {
                [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneStateTMAActivated];
            }
        }
    }
}

- (void)updatePermanentlyDisableState:(NSDictionary*)configurationDictionary {
    if(configurationDictionary[TUNE_TMA_PERMANENTLY_DISABLED]!=nil) {
        if ([configurationDictionary[TUNE_TMA_PERMANENTLY_DISABLED] boolValue]) {
            // Shut everything down. Forever.
            [TuneState updateTMAPermanentlyDisabledState:YES];
            [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneStateTMADeactivated];
        }
    }
}

- (void)updateDebugLogging:(NSDictionary *)configurationDictionary {
    if (configurationDictionary[TUNE_DEBUG_LOGGING_ON] != nil) {
        _debugLoggingOn = [configurationDictionary[TUNE_DEBUG_LOGGING_ON] boolValue];
    }
}

- (void)updateGlobalSwizzleOff:(NSDictionary*)configurationDictionary {
    if(configurationDictionary[TUNE_GLOBAL_SWIZZLE_OFF]!=nil) {
        [TuneState updateSwizzleDisabled:[configurationDictionary[TUNE_GLOBAL_SWIZZLE_OFF] boolValue]];
    }
}

- (void)updateSwizzleBlacklistAdditions:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_SWIZZLE_BLACKLIST_ADDITIONS] != nil) {
        NSArray *additions = configurationDictionary[TUNE_SWIZZLE_BLACKLIST_ADDITIONS];
        [TuneUserDefaultsUtils setUserDefaultValue:additions forKey:TUNE_SWIZZLE_BLACKLIST_ADDITIONS];
    } else {
        [TuneUserDefaultsUtils clearUserDefaultValue:TUNE_SWIZZLE_BLACKLIST_ADDITIONS];
    }
}

- (void)updateSwizzleBlacklistRemovals:(NSDictionary *)configurationDictionary {
    if(configurationDictionary[TUNE_SWIZZLE_BLACKLIST_REMOVALS] != nil) {
        NSArray *removals = configurationDictionary[TUNE_SWIZZLE_BLACKLIST_REMOVALS];
        [TuneUserDefaultsUtils setUserDefaultValue:removals forKey:TUNE_SWIZZLE_BLACKLIST_REMOVALS];
    } else {
        [TuneUserDefaultsUtils clearUserDefaultValue:TUNE_SWIZZLE_BLACKLIST_REMOVALS];
    }
}

- (void)updateConnectedModeState:(NSDictionary *)configurationDictionary {
    // NOTE: Connected mode can only be turned ON. Turning connected mode OFF involves restarting the app.
    
    if(configurationDictionary[TUNE_TMA_CONNECTED_MODE] != nil) {
        BOOL newConnectedStatus = [configurationDictionary[TUNE_TMA_CONNECTED_MODE] boolValue];
        
        // Only update the connected status if it is true, and different than what is currently stored
        //     in TuneState
        if (newConnectedStatus && newConnectedStatus != [TuneState isInConnectedMode]) {
            BOOL wasDisabledBefore = [TuneState isTMADisabled];
            [TuneState updateConnectedMode:YES];
            
            // Before doing anything else, we need to bring up TMA if it wasn't enabled before
            if (wasDisabledBefore) {
                [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneStateTMAActivated];
            }
        
            [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneStateTMAConnectedModeTurnedOn];
        }
    }
}

- (void)updatePIIRegexFilters:(NSDictionary *)configurationDictionary {
    if (configurationDictionary[TUNE_TMA_PII_FILTERS_NSSTRING]!=nil) {
        _PIIFiltersAsNSStrings = configurationDictionary[TUNE_TMA_PII_FILTERS_NSSTRING];
        [self buildPIIRegexFiltersAsNSRegularExpressions];
    }
}

- (void)buildPIIRegexFiltersAsNSRegularExpressions {
    NSMutableArray *regexFiltersAsNSRegularExpressions = [[NSMutableArray alloc] init];
    @try {
        for (NSString *regexAsNSString in _PIIFiltersAsNSStrings) {
            NSError *error = NULL;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexAsNSString options:NSRegularExpressionCaseInsensitive error:&error];
            
            if (!error) {
                [regexFiltersAsNSRegularExpressions addObject:regex];
            }
            else {
                ErrorLog(@"Exception parsing %@ %@",TUNE_TMA_PII_FILTERS_NSSTRING,regexAsNSString);
            }
        }
        _PIIFiltersAsNSRegularExpressions = [NSArray arrayWithArray:regexFiltersAsNSRegularExpressions];
    } @catch (NSException *exception) {
        ErrorLog(@"Exception parsing %@ %@",TUNE_TMA_PII_FILTERS_NSSTRING,exception.description);
    }
}

#pragma mark - Direct Setters (that trigger the Dictionary Setters)

- (void)setShouldAutoDetectJailbroken:(BOOL)shouldAutoDetectJailbroken {
    _shouldAutoDetectJailbroken = shouldAutoDetectJailbroken;

    [self updateShouldAutoDetectJailbroken:@{TUNE_KEY_AUTOCOLLECT_JAILBROKEN: @(_shouldAutoDetectJailbroken)}];
}

- (void)setShouldAutoCollectAdvertisingIdentifier:(BOOL)shouldAutoCollectAdvertisingIdentifier {
    _shouldAutoCollectAdvertisingIdentifier = shouldAutoCollectAdvertisingIdentifier;
    
    [self updateShouldAutoCollectAdvertisingIdentifier:@{TUNE_KEY_AUTOCOLLECT_IFA: @(_shouldAutoCollectAdvertisingIdentifier)}];
}

- (void)setShouldAutoGenerateVendorIdentifier:(BOOL)shouldAutoGenerateVendorIdentifier {
    _shouldAutoGenerateVendorIdentifier = shouldAutoGenerateVendorIdentifier;
    
    [self updateShouldAutoGenerateVendorIdentifier:@{TUNE_KEY_AUTOCOLLECT_IFV: @(_shouldAutoGenerateVendorIdentifier)}];
}

- (void)setDebugMode:(NSNumber *)debugMode {
    _debugMode = debugMode;
    
    [self updateDebugMode:@{TUNE_KEY_DEBUG: _debugMode}];
}

- (void)setShouldAutomateIapMeasurement:(BOOL)shouldAutomateIapMeasurement {
    _shouldAutomateIapMeasurement = shouldAutomateIapMeasurement;
    
    [self updateShouldAutomateIapMeasurement:@{TUNE_KEY_AUTO_IAP_MEASUREMENT: @(_shouldAutomateIapMeasurement)}];
}

@end
