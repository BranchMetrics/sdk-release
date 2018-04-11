//
//  Tune.m
//  Tune
//
//  Created by Tune on 05/03/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import "Tune.h"
#import "Tune+Internal.h"

#import "TuneAppDelegate.h"
#import "TuneConfiguration.h"
#import "TuneDeeplink.h"
#import "TuneDeeplinker.h"
#import "TuneDeepActionManager.h"
#import "TuneEvent+Internal.h"
#import "TuneExperimentManager.h"
#import "TuneIfa.h"
#import "TuneJSONPlayer.h"
#import "TuneKeyStrings.h"
#import "TuneManager.h"
#import "TunePlaylistManager.h"
#import "TunePowerHookManager.h"
#import "TunePushInfo+Internal.h"
#import "TuneSessionManager.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookConstants.h"
#import "TuneSkyhookPayloadConstants.h"
#if TUNE_ENABLE_SMARTWHERE
#import "TuneSmartWhereHelper.h"
#endif
#import "TuneState.h"
#import "TuneTracker.h"
#import "TuneUserProfile.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"

#ifdef TUNE_USE_LOCATION
#import "TuneRegionMonitor.h"
#endif

#define PLUGIN_NAMES (@[@"air", @"cocos2dx", @"corona", @"marmalade", @"phonegap", @"react-native", @"titanium", @"unity", @"xamarin"])

@implementation Tune

#pragma mark - Init Method

+ (NSOperationQueue *) tuneQueue {
    static NSOperationQueue *queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [NSOperationQueue new];
        [queue setMaxConcurrentOperationCount:1];
    });
    return queue;
}

+ (void)initializeWithTuneAdvertiserId:(NSString *)aid tuneConversionKey:(NSString *)key {
    [self initializeWithTuneAdvertiserId:aid tuneConversionKey:key tunePackageName:nil wearable:NO];
}

+ (void)initializeWithTuneAdvertiserId:(NSString *)aid tuneConversionKey:(NSString *)key tunePackageName:(NSString *)name wearable:(BOOL)wearable {
    [self initializeWithTuneAdvertiserId:aid tuneConversionKey:key tunePackageName:name wearable:wearable configuration:nil];
}

+ (void)initializeWithTuneAdvertiserId:(NSString *)aid tuneConversionKey:(NSString *)key tunePackageName:(NSString *)name wearable:(BOOL)wearable configuration:(NSDictionary<NSString *, id> *)configOrNil {
    [TuneDeeplinker setTuneAdvertiserId:aid tuneConversionKey:key];
    [TuneDeeplinker setTunePackageName:name ?: [TuneUtils bundleId]];
    
    if (!configOrNil) {
        configOrNil = [NSDictionary dictionary];
    }

    TuneManager *tuneManager = [TuneManager currentManager];

    [tuneManager.userProfile setAdvertiserId: [aid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    [tuneManager.userProfile setConversionKey: [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    [tuneManager.userProfile setWearable:@(wearable)];

    if(name)
    {
        [tuneManager.userProfile setPackageName:name];
    }

    [tuneManager.configuration setupConfiguration:configOrNil];

    // If the SDK user told us to use the PlaylistPlayer than set that up.
    if (tuneManager.configuration.usePlaylistPlayer) {
        TuneJSONPlayer *playlistPlayer = [[TuneJSONPlayer alloc] init];
        [playlistPlayer setFiles:tuneManager.configuration.playlistPlayerFilenames];
        tuneManager.playlistPlayer = playlistPlayer;
    }

    if (tuneManager.configuration.useConfigurationPlayer) {
        TuneJSONPlayer *configurationPlayer = [[TuneJSONPlayer alloc] init];
        [configurationPlayer setFiles:tuneManager.configuration.configurationPlayerFilenames];
        tuneManager.configurationPlayer = configurationPlayer;
    }

    [[TuneTracker sharedInstance] startTracker];
}

#pragma mark - Debugging Helper Methods

+ (void)setDebugMode:(BOOL)enable {
    [[self tuneQueue] addOperationWithBlock:^{
        [TuneManager currentManager].configuration.debugMode = @(enable);
        
        #if TUNE_ENABLE_SMARTWHERE && TARGET_OS_IOS
        if ([TuneSmartWhereHelper isSmartWhereAvailable]) {
            [[TuneSmartWhereHelper getInstance] setDebugMode:enable];
        }
        #endif
    }];
}

+ (void)setDelegate:(id<TuneDelegate>)delegate {
    [[self tuneQueue] addOperationWithBlock:^{
        [TuneDeeplinker setDelegate:delegate];

        [TuneTracker sharedInstance].delegate = delegate;
        #if DEBUG
        [TuneManager currentManager].userProfile.delegate = (id <TuneUserProfileDelegate>)delegate;
        [TuneManager currentManager].configuration.delegate = (id <TuneConfigurationDelegate>)delegate;
        #endif
    }];
}

#pragma mark - Behavior Flags

+ (void)checkForDeferredDeeplink:(id<TuneDelegate>)delegate {
    [self registerDeeplinkListener:delegate];
}

+ (void)registerDeeplinkListener:(id<TuneDelegate>)delegate {
    [TuneDeeplinker setDelegate:delegate];
    [self requestDeferredDeeplink];
}

+ (void)unregisterDeeplinkListener {
    [TuneDeeplinker setDelegate:nil];
}

+ (void)requestDeferredDeeplink {
    [TuneDeeplinker requestDeferredDeeplink];
}

+ (BOOL)isTuneLink:(NSString *)linkUrl {
    return [TuneDeeplinker isTuneLink:linkUrl];
}

+ (void)registerCustomTuneLinkDomain:(NSString *)domain {
    [TuneDeeplinker registerCustomTuneLinkDomain:domain];
}

+ (void)automateIapEventMeasurement:(BOOL)automate {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].configuration setShouldAutomateIapMeasurement:automate];
    }];
}

+ (void)setFacebookEventLogging:(BOOL)logging limitEventAndDataUsage:(BOOL)limit {
    [[self tuneQueue] addOperationWithBlock:^{
        [TuneTracker sharedInstance].fbLogging = logging;
        [TuneTracker sharedInstance].fbLimitUsage = limit;
    }];
}


#pragma mark - Setter Methods

#ifdef TUNE_USE_LOCATION
+ (void)setRegionDelegate:(id<TuneRegionDelegate>)delegate {
    [[self tuneQueue] addOperationWithBlock:^{
        [TuneTracker sharedInstance].regionMonitor.delegate = delegate;
    }];
}
#endif

+ (void)setExistingUser:(BOOL)existingUser {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setExistingUser: @(existingUser)];
    }];
}

+ (void)setCurrencyCode:(NSString *)currencyCode {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setCurrencyCode:currencyCode];
    }];
}

+ (void)setPackageName:(NSString *)packageName {
    [TuneDeeplinker setTunePackageName:packageName];
    
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setPackageName:packageName];
        
        #if TUNE_ENABLE_SMARTWHERE && TARGET_OS_IOS
        if ([TuneSmartWhereHelper isSmartWhereAvailable]) {
            [[TuneSmartWhereHelper getInstance] setPackageName:packageName];
        }
        #endif
    }];
}

+ (void)setAppleAdvertisingIdentifier:(NSUUID *)ifa advertisingTrackingEnabled:(BOOL)adTrackingEnabled {
    [TuneDeeplinker setAppleIfa:ifa.UUIDString appleAdTrackingEnabled:adTrackingEnabled];
    
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].configuration setShouldAutoCollectAdvertisingIdentifier:NO];
        [[TuneManager currentManager].userProfile setAppleAdvertisingIdentifier:ifa.UUIDString];
        [[TuneManager currentManager].userProfile setAppleAdvertisingTrackingEnabled:@(adTrackingEnabled)];
    }];
}

+ (void)setAppleVendorIdentifier:(NSUUID *)appleVendorIdentifier {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].configuration setShouldAutoGenerateVendorIdentifier:NO];
        [[TuneManager currentManager].userProfile setAppleVendorIdentifier:[appleVendorIdentifier UUIDString]];
    }];
}

+ (void)setJailbroken:(BOOL)jailbroken {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].configuration setShouldAutoDetectJailbroken:NO];
        [[TuneManager currentManager].userProfile setJailbroken:@(jailbroken)];
    }];
}

+ (void)setShouldAutoDetectJailbroken:(BOOL)autoDetect {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].configuration setShouldAutoDetectJailbroken:autoDetect];
    }];
}

+ (void)setShouldAutoCollectDeviceLocation:(BOOL)autoCollect {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].configuration setShouldAutoCollectDeviceLocation:autoCollect];
    }];
}

+ (void)setShouldAutoCollectAppleAdvertisingIdentifier:(BOOL)autoCollect {
    NSString *strIfa = nil;
    BOOL trackEnabled = NO;
    
    if(autoCollect) {
        TuneIfa *ifaInfo = [TuneIfa ifaInfo];
        strIfa = ifaInfo.ifa;
        trackEnabled = ifaInfo.trackingEnabled;
    }
    
    [TuneDeeplinker setAppleIfa:strIfa appleAdTrackingEnabled:trackEnabled];
    
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].configuration setShouldAutoCollectAdvertisingIdentifier:autoCollect];
    }];
}

+ (void)setShouldAutoGenerateAppleVendorIdentifier:(BOOL)autoGenerate {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].configuration setShouldAutoGenerateVendorIdentifier:autoGenerate];
    }];
}

+ (void)setTRUSTeId:(NSString *)tpid; {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setTRUSTeId:tpid];
    }];
}

+ (void)setUserEmail:(NSString *)userEmail {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setUserEmail:userEmail];
    }];
}

+ (void)setUserId:(NSString *)userId {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setUserId:userId];
    }];
}

+ (void)setUserName:(NSString *)userName {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setUserName:userName];
    }];
}

+ (void)setPhoneNumber:(NSString *)phoneNumber {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setPhoneNumber:phoneNumber];
    }];
}

+ (void)setFacebookUserId:(NSString *)facebookUserId {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setFacebookUserId:facebookUserId];
    }];
}

+ (void)setTwitterUserId:(NSString *)twitterUserId {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setTwitterUserId:twitterUserId];
    }];
}

+ (void)setGoogleUserId:(NSString *)googleUserId {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setGoogleUserId:googleUserId];
    }];
}

+ (void)setAge:(NSInteger)userAge {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setAge:@(userAge)];
    }];
}

+ (void)setPrivacyProtectedDueToAge:(BOOL)privacyProtected {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setPrivacyProtectedDueToAge:privacyProtected];
    }];
}

+ (BOOL)isPrivacyProtectedDueToAge {
    // tooYoungForTargetedAds is a combination of age + privacyProtectedDueToAge
    return [[TuneManager currentManager].userProfile tooYoungForTargetedAds];
}

+ (void)setGender:(TuneGender)userGender {
    [[self tuneQueue] addOperationWithBlock:^{
        NSNumber *gen = (TuneGenderFemale == userGender || TuneGenderMale == userGender) ? @(userGender) : nil;
        [[TuneManager currentManager].userProfile setGender:gen];
    }];
}

+ (void)setLocation:(TuneLocation *)location {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].configuration setShouldAutoCollectDeviceLocation:NO];
        [[TuneManager currentManager].userProfile setLocation:location];
    }];
}

+ (void)setAppAdMeasurement:(BOOL)enable {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setAppAdTracking:@(enable)];
    }];
}

+ (void)setPluginName:(NSString *)pluginName {
    [[self tuneQueue] addOperationWithBlock:^{
        if (pluginName == nil) {
            [TuneManager currentManager].configuration.pluginName = pluginName;
        } else {
            for (NSString *allowedName in PLUGIN_NAMES) {
                if ([pluginName isEqualToString:allowedName]) {
                    [TuneManager currentManager].configuration.pluginName = pluginName;
                    break;
                }
            }
        }
    }];
}

+ (void)setLocationAuthorizationStatus:(NSInteger)authStatus { // private method
    [[self tuneQueue] addOperationWithBlock:^{
        [TuneManager currentManager].userProfile.locationAuthorizationStatus = @(authStatus);
    }];
}

+ (void)setBluetoothState:(NSInteger)bluetoothState { // private method
    [[self tuneQueue] addOperationWithBlock:^{
        [TuneManager currentManager].userProfile.bluetoothState = @(bluetoothState);
    }];
}

+ (void)setPayingUser:(BOOL)isPayingUser {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setPayingUser:@(isPayingUser)];
    }];
}

+ (void)setPreloadData:(TunePreloadData *)preloadData {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setPreloadData:preloadData];
    }];
}

#pragma mark - Register/Set Custom Profile Variables

+ (void)registerCustomProfileString:(NSString *)variableName {
    [[TuneManager currentManager].userProfile registerString:variableName];
}

+ (void)registerCustomProfileString:(NSString *)variableName hashed:(BOOL)shouldHash {
    [[TuneManager currentManager].userProfile registerString:variableName hashed:shouldHash];
}

+ (void)registerCustomProfileBoolean:(NSString *)variableName {
    [[TuneManager currentManager].userProfile registerBoolean:variableName];
}

+ (void)registerCustomProfileDateTime:(NSString *)variableName {
    [[TuneManager currentManager].userProfile registerDateTime:variableName];
}

+ (void)registerCustomProfileNumber:(NSString *)variableName {
    [[TuneManager currentManager].userProfile registerNumber:variableName];
}

+ (void)registerCustomProfileGeolocation:(NSString *)variableName {
    [[TuneManager currentManager].userProfile registerGeolocation:variableName];
}

+ (void)registerCustomProfileVersion:(NSString *)variableName {
    [[TuneManager currentManager].userProfile registerVersion:variableName];
}

+ (void)registerCustomProfileString:(NSString *)variableName withDefault:(NSString *)value {
    [[TuneManager currentManager].userProfile registerString:variableName withDefault:value];
}

+ (void)registerCustomProfileString:(NSString *)variableName withDefault:(NSString *)value hashed:(BOOL)shouldHash {
    [[TuneManager currentManager].userProfile registerString:variableName withDefault:value hashed:shouldHash];
}

+ (void)registerCustomProfileBoolean:(NSString *)variableName withDefault:(NSNumber *)value {
    [[TuneManager currentManager].userProfile registerBoolean:variableName withDefault:value];
}

+ (void)registerCustomProfileDateTime:(NSString *)variableName withDefault:(NSDate *)value {
    [[TuneManager currentManager].userProfile registerDateTime:variableName withDefault:value];
}

+ (void)registerCustomProfileNumber:(NSString *)variableName withDefault:(NSNumber *)value {
    [[TuneManager currentManager].userProfile registerNumber:variableName withDefault:value];
}

+ (void)registerCustomProfileGeolocation:(NSString *)variableName withDefault:(TuneLocation *)value {
    [[TuneManager currentManager].userProfile registerGeolocation:variableName withDefault:value];
}

+ (void)registerCustomProfileVersion:(NSString *)variableName withDefault:(NSString *)value {
    [[TuneManager currentManager].userProfile registerVersion:variableName withDefault:value];
}

+ (void)setCustomProfileStringValue:(NSString *)value forVariable:(NSString *)name {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setStringValue:value forVariable:name];
    }];
}

+ (void)setCustomProfileBooleanValue:(NSNumber *)value forVariable:(NSString *)name {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setBooleanValue:value forVariable:name];
    }];
}

+ (void)setCustomProfileDateTimeValue:(NSDate *)value forVariable:(NSString *)name {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setDateTimeValue:value forVariable:name];
    }];
}

+ (void)setCustomProfileNumberValue:(NSNumber *)value forVariable:(NSString *)name {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setNumberValue:value forVariable:name];
    }];
}

+ (void)setCustomProfileGeolocationValue:(TuneLocation *)value forVariable:(NSString *)name {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setGeolocationValue:value forVariable:name];
    }];
}

+ (void)setCustomProfileVersionValue:(NSString *)value forVariable:(NSString *)name {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setVersionValue:value forVariable:name];
    }];
}

+ (NSString *)getCustomProfileString:(NSString *)name {
    return [[TuneManager currentManager].userProfile getCustomProfileString:name];
}

+ (NSDate *)getCustomProfileDateTime:(NSString *)name {
    __block NSDate *tmp;
    dispatch_sync([self tuneQueue], ^() {
        tmp = [[TuneManager currentManager].userProfile getCustomProfileDateTime:name];
    });
    return tmp;
}

+ (NSNumber *)getCustomProfileNumber:(NSString *)name {
    return [[TuneManager currentManager].userProfile getCustomProfileNumber:name];
}

+ (TuneLocation *)getCustomProfileGeolocation:(NSString *)name {
    return [[TuneManager currentManager].userProfile getCustomProfileGeolocation:name];
}

+ (void)clearCustomProfileVariable:(NSString *)name {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile clearCustomVariables:[NSSet setWithObject:name]];
    }];
}

+ (void)clearAllCustomProfileVariables {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile clearCustomProfile];
    }];
}

#pragma mark - Getter Methods

+ (NSString*)appleAdvertisingIdentifier {
    return [[TuneManager currentManager].userProfile appleAdvertisingIdentifier];
}

+ (NSString*)tuneId {
    return [[TuneManager currentManager].userProfile tuneId];
}

+ (NSString*)openLogId {
    return [[TuneManager currentManager].userProfile openLogId];
}

+ (BOOL)isPayingUser {
    return [[[TuneManager currentManager].userProfile payingUser] boolValue];
}

+ (NSString *)getPushToken {
    return [[TuneManager currentManager].userProfile deviceToken];
}

+ (nonnull NSString *)getIAMAppId {
    return [[TuneManager currentManager].userProfile hashedAppId];
}

+ (nonnull NSString *)getIAMDeviceIdentifier {
    return [[TuneManager currentManager].userProfile deviceId];
}

#pragma mark - Power Hook API

+ (void)registerHookWithId:(NSString *)hookId friendlyName:(NSString *)friendlyName defaultValue:(NSString *)defaultValue {
    [Tune registerHookWithId:hookId friendlyName:friendlyName defaultValue:defaultValue description:nil approvedValues:nil];
}

+ (void)registerHookWithId:(NSString *)hookId friendlyName:(NSString *)friendlyName defaultValue:(NSString *)defaultValue description:(NSString *)description {
    [Tune registerHookWithId:hookId friendlyName:friendlyName defaultValue:defaultValue description:description approvedValues:nil];
}

+ (void)registerHookWithId:(NSString *)hookId friendlyName:(NSString *)friendlyName defaultValue:(NSString *)defaultValue description:(NSString *)description approvedValues:(NSArray *)approvedValues {
    [[TuneManager currentManager].powerHookManager registerHookWithId:hookId friendlyName:friendlyName defaultValue:defaultValue description:description approvedValues:approvedValues];
}


+ (NSString *)getValueForHookById:(NSString *)hookId {
    return [[TuneManager currentManager].powerHookManager getValueForHookById:hookId];
}

+ (void)setValueForHookById:(NSString *)hookId value:(NSString *)value {
    [[TuneManager currentManager].powerHookManager setValueForHookById:hookId value:value];
}

+ (void)onPowerHooksChanged:(void (^)(void)) block {
    [[TuneManager currentManager].powerHookManager onPowerHooksChanged:block];
}


#pragma mark - Deep Action API

+ (void)registerDeepActionWithId:(NSString *)deepActionId friendlyName:(NSString *)friendlyName data:(NSDictionary<NSString *, NSString *> *)data andAction:(void (^)(NSDictionary<NSString *, NSString *> *extra_data))deepAction {
    [self registerDeepActionWithId:deepActionId friendlyName:friendlyName description:nil data:data andAction:deepAction];
}

+ (void)registerDeepActionWithId:(NSString *)deepActionId friendlyName:(NSString *)friendlyName description:(NSString *)description data:(NSDictionary<NSString *, NSString *> *)data andAction:(void (^)(NSDictionary<NSString *, NSString *> *extra_data))deepAction {
    [self registerDeepActionWithId:deepActionId friendlyName:friendlyName description:description data:data approvedValues:nil andAction:deepAction];
}

+ (void)registerDeepActionWithId:(NSString *)deepActionId friendlyName:(NSString *)friendlyName description:(NSString *)description data:(NSDictionary<NSString *, NSString *> *)data approvedValues:(NSDictionary<NSString *, NSArray <NSString *> *> *)approvedValues andAction:(void (^)(NSDictionary<NSString *, NSString *> *extra_data))deepAction {
    [[TuneManager currentManager].deepActionManager registerDeepActionWithId:deepActionId
                                                                friendlyName:friendlyName
                                                                 description:description
                                                                        data:data
                                                              approvedValues:approvedValues
                                                                   andAction:deepAction];
}

+ (void)executeDeepActionWithId:(NSString *)deepActionId andData:(NSDictionary<NSString *, NSString *> *)data {
    [[TuneManager currentManager].deepActionManager executeDeepActionWithId:deepActionId andData:data];
}

#pragma mark - Push Notifications API

+ (BOOL)didSessionStartFromTunePush {
    return [TuneManager currentManager].sessionManager.lastOpenedPushNotification != nil;
}

+ (TunePushInfo *)getTunePushInfoForSession {
    TuneNotification *msg = [TuneManager currentManager].sessionManager.lastOpenedPushNotification;
    if (msg == nil) {
        return nil;
    } else {
        return [[TunePushInfo alloc] initWithNotification:msg];
    }
}

#if TARGET_OS_IOS

+ (void)application:(UIApplication *)application tuneDidRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [TuneAppDelegate application:application tune_didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

+ (void)application:(UIApplication *)application tuneDidFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    [TuneAppDelegate application:application tune_didFailToRegisterForRemoteNotificationsWithError:error];
}

+ (void)application:(UIApplication *)application tuneDidReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [TuneAppDelegate application:application tune_didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
}

+ (void)application:(UIApplication *)application tuneHandleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)(void))completionHandler {
    [TuneAppDelegate application:application tune_handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:completionHandler];
}

+ (void)application:(UIApplication *)application tuneHandleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void(^)(void))completionHandler {
    [TuneAppDelegate application:application tune_handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo completionHandler:completionHandler];
}

+ (void)application:(UIApplication *)application tuneDidReceiveLocalNotification:(UILocalNotification *)notification{
    [TuneAppDelegate application:application tune_didReceiveLocalNotification:notification];
}

#if IDE_XCODE_8_OR_HIGHER
+ (void)userNotificationCenter:(UNUserNotificationCenter *)center tuneDidReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    [TuneAppDelegate userNotificationCenter:center tune_didReceiveNotificationResponse:response withCompletionHandler:completionHandler];
}
#endif

#endif

#pragma mark - Spotlight API

+ (BOOL)application:(UIApplication *)application tuneContinueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray *restorableObjects))restorationHandler {
    return [self handleContinueUserActivity:userActivity restorationHandler:restorationHandler];
}

#pragma mark - Experiment API

+ (NSDictionary<NSString *, TunePowerHookExperimentDetails *> *)getPowerHookVariableExperimentDetails {
    return [[TuneManager currentManager].experimentManager getPowerHookVariableExperimentDetails];
}

+ (NSDictionary<NSString *, TuneInAppMessageExperimentDetails *> *)getInAppMessageExperimentDetails {
    return [[TuneManager currentManager].experimentManager getInAppMessageExperimentDetails];
}

#pragma mark - Playlist API

+ (void)onFirstPlaylistDownloaded:(void (^)(void))block {
    [[TuneManager currentManager].playlistManager onFirstPlaylistDownloaded:block withTimeout:DefaultFirstPlaylistDownloadedTimeout];
}

+ (void)onFirstPlaylistDownloaded:(void (^)(void))block withTimeout:(NSTimeInterval)timeout {
    [[TuneManager currentManager].playlistManager onFirstPlaylistDownloaded:block withTimeout:timeout];
}

#pragma mark - User in Segment API

+ (BOOL)isUserInSegmentId:(NSString *)segmentId {
    return [[TuneManager currentManager].playlistManager isUserInSegmentId:segmentId];
}

+ (BOOL)isUserInAnySegmentIds:(NSArray<NSString *> *)segmentIds {
    return [[TuneManager currentManager].playlistManager isUserInAnySegmentIds:segmentIds];
}

#pragma mark - In-App Messaging API

// TODO: revisit deep copying later if necessary

//+ (NSArray<TuneInAppMessage *> *)getInAppMessagesForCustomEvent:(NSString *)eventName {
//    TuneAnalyticsEvent *customEvent = [[TuneAnalyticsEvent alloc] initWithTuneEvent:TUNE_EVENT_TYPE_BASE
//                                                                             action:eventName
//                                                                           category:TUNE_EVENT_CATEGORY_CUSTOM
//                                                                            control:nil
//                                                                       controlEvent:nil
//                                                                              event:nil];
//    return [self getInAppMessagesByTriggerEvents][[customEvent getEventMd5]];
//}
//
//+ (NSArray<TuneInAppMessage *> *)getInAppMessagesForPushOpened:(NSString *)pushId {
//    TuneAnalyticsEvent *pushOpenedEvent = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_PUSH_NOTIFICATION
//                                                                                 action:TUNE_EVENT_ACTION_NOTIFICATION_OPENED
//                                                                               category:pushId
//                                                                                control:nil
//                                                                           controlEvent:nil
//                                                                                   tags:nil
//                                                                                  items:nil];
//    return [self getInAppMessagesByTriggerEvents][[pushOpenedEvent getEventMd5]];
//}
//
//+ (NSArray<TuneInAppMessage *> *)getInAppMessagesForPushEnabled:(BOOL)pushEnabled {
//    NSString *eventAction = pushEnabled ? TunePushEnabled : TunePushDisabled;
//    TuneAnalyticsEvent *pushEnabledEvent = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_BASE
//                                                                                  action:eventAction
//                                                                                category:TUNE_EVENT_CATEGORY_APPLICATION
//                                                                                 control:nil
//                                                                            controlEvent:nil
//                                                                                    tags:nil
//                                                                                   items:nil];
//    return [self getInAppMessagesByTriggerEvents][[pushEnabledEvent getEventMd5]];
//}
//
//+ (NSArray<TuneInAppMessage *> *)getInAppMessagesForStartsApp {
//    TuneAnalyticsEvent *firstPlaylistDownloadedEvent = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_SESSION
//                                                                                              action:TUNE_EVENT_ACTION_FIRST_PLAYLIST_DOWNLOADED
//                                                                                            category:TUNE_EVENT_CATEGORY_APPLICATION
//                                                                                             control:nil
//                                                                                        controlEvent:nil
//                                                                                                tags:nil
//                                                                                               items:nil];
//    return [self getInAppMessagesByTriggerEvents][[firstPlaylistDownloadedEvent getEventMd5]];
//}
//
//+ (NSArray<TuneInAppMessage *> *)getInAppMessagesForScreenViewed:(UIViewController *)viewController {
//    TuneAnalyticsEvent *pageViewEvent = [[TuneAnalyticsEvent alloc] initWithEventType:TUNE_EVENT_TYPE_PAGEVIEW
//                                                                               action:nil
//                                                                             category:viewController.tuneScreenName
//                                                                              control:nil
//                                                                         controlEvent:nil
//                                                                                 tags:nil
//                                                                                items:nil];
//    return [self getInAppMessagesByTriggerEvents][[pageViewEvent getEventMd5]];
//}
//
//+ (NSDictionary<NSString *, NSArray<TuneInAppMessage *> *> *)getInAppMessagesByTriggerEvents {
//    return [[TuneManager currentManager].triggerManager.inAppMessagesByEvents mutableCopy];
//}

#pragma mark - Measure Methods

+ (void)measureSession {
    [self measureEventName:TUNE_EVENT_SESSION];
}

+ (void)measureEventName:(NSString *)eventName {
    [self measureEvent:[TuneEvent eventWithName:eventName]];
}

+ (void)measureEventId:(NSInteger)eventId {
    [self measureEvent:[TuneEvent eventWithId:eventId]];
}

+ (void)measureEvent:(TuneEvent *)event {
    if (event == nil) {
        ErrorLog(@"Events passed to 'measureEvent:' can not be nil.");
        return;
    }

    // Handoff to new code via CustomEvent Skyhook
    [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneCustomEventOccurred
                                                  object:nil
                                                userInfo:@{ TunePayloadCustomEvent: event }];
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneTracker sharedInstance] measureEvent:event];
    }];
}

#pragma mark - Other Methods

+ (void)setUseCookieMeasurement:(BOOL)enable {
    [[self tuneQueue] addOperationWithBlock:^{
        [TuneTracker sharedInstance].shouldUseCookieTracking = enable;
    }];
}

+ (void)setRedirectUrl:(NSString *)redirectURL {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setRedirectUrl:redirectURL];
    }];
}

+ (void)startAppToAppMeasurement:(NSString *)targetAppPackageName
                    advertiserId:(NSString *)targetAppAdvertiserId
                         offerId:(NSString *)targetAdvertiserOfferId
                     publisherId:(NSString *)targetAdvertiserPublisherId
                        redirect:(BOOL)shouldRedirect
{
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneTracker sharedInstance] setMeasurement:targetAppPackageName
                                advertiserId:targetAppAdvertiserId
                                     offerId:targetAdvertiserOfferId
                                 publisherId:targetAdvertiserPublisherId
                                    redirect:shouldRedirect];
    }];
}

+ (BOOL)handleOpenURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    NSString *sourceApplication = options[UIApplicationOpenURLOptionsSourceApplicationKey];
    return [self handleOpenURL:url sourceApplication:sourceApplication];
}

+ (BOOL)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication {
    BOOL handled = NO;
    
    NSString *urlString = url.absoluteString;

    // Process referral url if it's a TUNE link and return invoke_url to listener
    if (urlString) {
        BOOL isTuneLink = [self isTuneLink:urlString];
        BOOL hasInvokeUrl = [TuneDeeplinker hasInvokeUrl:urlString];
        if (isTuneLink || hasInvokeUrl) {
            handled = YES;
        
            NSString *invokeUrl = [TuneDeeplinker invokeUrlFromReferralUrl:urlString];
            if (invokeUrl) {
                [TuneDeeplinker handleExpandedTuneLink:invokeUrl];
            }
            
            // Only send click for tlnk.io app link opens
            if (isTuneLink) {
                // Measure Tune Link click
                [[self tuneQueue] addOperationWithBlock:^{
                    [[TuneTracker sharedInstance] measureTuneLinkClick:urlString];
                }];
            }
        }
    }
    
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneTracker sharedInstance] applicationDidOpenURL:urlString sourceApplication:sourceApplication];
        
        // Process any Marketing Automation info in deeplink url
        [TuneDeeplink processDeeplinkURL:url];
    }];

    return handled;
}

+ (BOOL)handleContinueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler {
#if TARGET_OS_IOS
    if (@available(iOS 9, *)) {
        if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
            NSString *searchIndexUniqueId = userActivity.userInfo[CSSearchableItemActivityIdentifier];
            return [Tune handleOpenURL:[NSURL URLWithString:searchIndexUniqueId]
                     sourceApplication:@"spotlight"];
        }
    }
#endif
    if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb] && userActivity.webpageURL) {
        return [Tune handleOpenURL:userActivity.webpageURL
                 sourceApplication:@"web"];
    }

    return NO;
}

+ (void)applicationDidOpenURL:(NSString *)urlString sourceApplication:(NSString *)sourceApplication {
    [self handleOpenURL:[NSURL URLWithString:urlString] sourceApplication:sourceApplication];
}

#ifdef TUNE_USE_LOCATION
+ (void)startMonitoringForBeaconRegion:(NSUUID*)UUID
                                nameId:(NSString*)nameId
                               majorId:(NSUInteger)majorId
                               minorId:(NSUInteger)minorId
{
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneTracker sharedInstance].regionMonitor addBeaconRegion:UUID nameId:nameId majorId:majorId minorId:minorId];
    }];
}
#endif

#if TARGET_OS_IOS

+ (void)enableSmartwhereIntegration {
    
    // Attempting to use SmartWhere when it is not installed is a severe error, throwing an exception.
    if (![TuneSmartWhereHelper isSmartWhereAvailable]) {
        NSException *e = [NSException
                          exceptionWithName:@"FrameworkNotFoundException"
                          reason:@"SmartWhere.framework Not Found"
                          userInfo:nil];
        @throw e;
    }
    
#if TUNE_ENABLE_SMARTWHERE && TARGET_OS_IOS
    [[self tuneQueue] addOperationWithBlock:^{
        TuneSmartWhereHelper *tuneSharedSmartWhereHelper = [TuneSmartWhereHelper getInstance];
        TuneUserProfile *profile = [TuneManager currentManager].userProfile;
        [tuneSharedSmartWhereHelper startMonitoringWithTuneAdvertiserId:[profile advertiserId] tuneConversionKey:[profile conversionKey] packageName:[profile packageName]];
    }];
#endif

}

+ (void)disableSmartwhereIntegration {
    TuneSmartWhereHelper *tuneSharedSmartWhereHelper = [TuneSmartWhereHelper getInstance];
    tuneSharedSmartWhereHelper.enableSmartWhereEventSharing = NO;
    [tuneSharedSmartWhereHelper stopMonitoring];
}

+ (void)configureSmartwhereIntegrationWithOptions:(NSInteger)mask {
    TuneSmartWhereHelper *tuneSharedSmartWhereHelper = [TuneSmartWhereHelper getInstance];
    tuneSharedSmartWhereHelper.enableSmartWhereEventSharing = (mask & TuneSmartwhereShareEventData) ? YES : NO;
}

#endif

#pragma mark - Testing Helpers

#if TESTING

+ (void)resetTuneTrackerSharedInstance {
    [TuneTracker resetSharedInstance];
}

+ (void)setAllowDuplicateRequests:(BOOL)allowDup {
    [TuneTracker sharedInstance].allowDuplicateRequests = allowDup;
}
#endif

@end
