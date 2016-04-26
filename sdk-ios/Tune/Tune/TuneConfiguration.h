//
//  TuneConfiguration.h
//  TuneMarketingConsoleSDK
//
//  Copyright (c) 2015 Tune. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "TuneModule.h"

@protocol TuneConfigurationDelegate;

extern NSString *const TuneConfigurationPreviewModeKey;

@interface TuneConfiguration : TuneModule

// Logging
@property (nonatomic, assign) BOOL debugLoggingOn; // Whether we should enable debugging logs.

@property (nonatomic, assign) BOOL staging;                            // KEY_STAGING
@property (nonatomic, copy) NSNumber *debugMode;                       // KEY_DEBUG
@property (nonatomic, assign) BOOL echoAnalytics;                      // KEY_ECHO_ANALYTICS
@property (nonatomic, assign) BOOL echoPlaylists;                      // KEY_ECHO_PLAYLISTS
@property (nonatomic, assign) BOOL echoConfigurations;                 // KEY_ECHO_CONFIGURATIONS
@property (nonatomic, assign) BOOL echoFiveline;                       // KEY_ECHO_FIVELINE
@property (nonatomic, assign) BOOL usePlaylistPlayer;                  // KEY_USE_PLAYLIST_PLAYER
@property (nonatomic, assign) NSArray *playlistPlayerFilenames;        // KEY_PLAYLIST_PLAYER_FILENAMES
@property (nonatomic, assign) BOOL useConfigurationPlayer;             // KEY_USE_CONFIGURATION_PLAYER
@property (nonatomic, assign) NSArray *configurationPlayerFilenames;   // KEY_CONFIGURATION_PLAYER_FILENAMES

#if !TARGET_OS_WATCH
@property (nonatomic, assign) BOOL shouldAutomateIapMeasurement;           // KEY_AUTO_IAP_MEASUREMENT
@property (nonatomic, assign) BOOL shouldAutoDetectJailbroken;             // KEY_AUTOCOLLECT_JAILBROKEN
@property (nonatomic, assign) BOOL shouldAutoCollectAdvertisingIdentifier; // KEY_AUTOCOLLECT_IFA
@property (nonatomic, assign) BOOL shouldAutoGenerateVendorIdentifier;     // KEY_AUTOCOLLLECT_IFV
#endif

@property (nonatomic, assign) BOOL shouldAutoCollectDeviceLocation;        // KEY_AUTOCOLLECT_LOCATION

@property (nonatomic, copy) NSString *apiHostPort;                     // TUNE_TMA_API_HOST_PORT
@property (nonatomic, copy) NSString *analyticsHostPort;               // TUNE_TMA_ANALYTICS_HOST_PORT
@property (nonatomic, copy) NSString *connectedModeHostPort;           // TUNE_TMA_CONNECTED_MODE_HOST_PORT
@property (nonatomic, copy) NSString *staticContentHostPort;           // TUNE_TMA_STATIC_CONTENT_HOST_PORT

@property (nonatomic, copy) NSNumber *analyticsDispatchPeriod;         // ANALYTICS_DISPATCH_PERIOD
@property (nonatomic, copy) NSNumber *analyticsMessageStorageLimit;    // ANALYTICS_MESSAGE_LIMIT

@property (nonatomic, assign) BOOL pollForPlaylist;                    // TUNE_POLL_FOR_PLAYLIST
@property (nonatomic, copy) NSNumber *playlistRequestPeriod;           // TUNE_PLAYLIST_REQUEST_PERIOD

@property (nonatomic, copy) NSString *pluginName;                      // KEY_SDK_PLUGIN

@property (nonatomic, copy) NSArray *PIIFiltersAsNSStrings;            // TUNE_ARTISAN_PII_FILTERS_NSSTRING
// This property does not have an assoctiated key because it is only set when PIIFiltersAsNSStrings is set
@property (nonatomic, copy) NSArray *PIIFiltersAsNSRegularExpressions;

@property (nonatomic, assign) id <TuneConfigurationDelegate> delegate;

@property (assign, nonatomic) BOOL updatingConfiguration;

- (NSString*)domainName;

+ (NSString *)frameworkVersion;
- (NSString *)apiVersion;

- (void)setupConfiguration:(NSDictionary *)configuration;

- (NSDictionary *)toDictionary;

@end
