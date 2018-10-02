//
//  Tune.m
//  Tune
//
//  Created by Tune on 05/03/13.
//  Copyright (c) 2013 Tune. All rights reserved.
//

#import "Tune.h"
#import "Tune+Internal.h"

#import "TuneConfiguration.h"
#import "TuneDeeplink.h"
#import "TuneDeeplinker.h"
#import "TuneEvent+Internal.h"
#import "TuneIfa.h"
#import "TuneKeyStrings.h"
#import "TuneLog.h"
#import "TuneManager.h"
#import "TuneSessionManager.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookConstants.h"
#import "TuneSkyhookPayloadConstants.h"
#import "TuneTracker.h"
#import "TuneUserProfile.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"
#import "TuneLocation.h"

// private
#import "TuneStoreKitDelegate.h"

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
    [self initializeWithTuneAdvertiserId:aid tuneConversionKey:key tunePackageName:nil];
}

+ (void)initializeWithTuneAdvertiserId:(NSString *)aid tuneConversionKey:(NSString *)key tunePackageName:(NSString *)name {
    
    [TuneDeeplinker setTuneAdvertiserId:aid tuneConversionKey:key];
    [TuneDeeplinker setTunePackageName:name ?: [TuneUtils bundleId]];

    TuneManager *tuneManager = [TuneManager currentManager];

    [tuneManager.userProfile setAdvertiserId: [aid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    [tuneManager.userProfile setConversionKey: [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];

    if (name) {
        [tuneManager.userProfile setPackageName:name];
    }

    [[TuneTracker sharedInstance] startTracker];
}

#pragma mark - Debugging Helper Methods

+ (void)setDebugLogCallback:(void (^)(NSString * _Nonnull logMessage))callback {
    TuneLog.shared.logBlock = callback;
}

+ (void)setDebugLogVerbose:(BOOL)enable {
    TuneLog.shared.verbose = enable;
}

#pragma mark - Behavior Flags

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

+ (void)automateInAppPurchaseEventMeasurement:(BOOL)automate {
    [[self tuneQueue] addOperationWithBlock:^{
        if (automate) {
            // start listening for in-app-purchase transactions
            [TuneStoreKitDelegate startObserver];
        } else {
            // stop listening for in-app-purchase transactions
            [TuneStoreKitDelegate stopObserver];
        }
    }];
}

+ (void)setFacebookEventLogging:(BOOL)logging limitEventAndDataUsage:(BOOL)limit {
    [[self tuneQueue] addOperationWithBlock:^{
        [TuneTracker sharedInstance].fbLogging = logging;
        [TuneTracker sharedInstance].fbLimitUsage = limit;
    }];
}


#pragma mark - Setter Methods

+ (void)setExistingUser:(BOOL)existingUser {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setExistingUser: @(existingUser)];
    }];
}

+ (void)setJailbroken:(BOOL)jailbroken {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setJailbroken:@(jailbroken)];
    }];
}

+ (void)disableLocationAutoCollection {
    TuneConfiguration.sharedConfiguration.collectDeviceLocation = NO;
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

+ (void)setLocation:(CLLocation *)location {
    __block TuneLocation *tmp = [TuneLocation new];
    tmp.latitude = @(location.coordinate.latitude);
    tmp.longitude = @(location.coordinate.longitude);
    tmp.altitude = @(location.altitude);
    
    [[self tuneQueue] addOperationWithBlock:^{
        TuneConfiguration.sharedConfiguration.collectDeviceLocation = NO;
        [[TuneManager currentManager].userProfile setLocation:tmp];
    }];
}

+ (void)setLocationWithLatitude:(NSNumber *)latitude longitude:(NSNumber *)longitude altitude:(NSNumber *)altitude {
    __block TuneLocation *location = [TuneLocation new];
    location.latitude = latitude;
    location.longitude = longitude;
    if (altitude) {
        location.altitude = altitude;
    }
    
    [[self tuneQueue] addOperationWithBlock:^{
        TuneConfiguration.sharedConfiguration.collectDeviceLocation = NO;
        [[TuneManager currentManager].userProfile setLocation:location];
    }];
}

+ (void)setAppAdTrackingEnabled:(BOOL)enable {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setAppAdTracking:@(enable)];
    }];
}

+ (void)setPluginName:(NSString *)pluginName {
    [[self tuneQueue] addOperationWithBlock:^{
        if (pluginName == nil) {
            TuneConfiguration.sharedConfiguration.pluginName = nil;
        } else {
            for (NSString *allowedName in PLUGIN_NAMES) {
                if ([pluginName isEqualToString:allowedName]) {
                    TuneConfiguration.sharedConfiguration.pluginName = pluginName;
                    return;
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

+ (void)setPreloadedAppData:(TunePreloadData *)preloadData {
    [[self tuneQueue] addOperationWithBlock:^{
        [[TuneManager currentManager].userProfile setPreloadData:preloadData];
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

#pragma mark - Measure Methods

+ (void)measureSession {
    [self measureEventName:TUNE_EVENT_SESSION];
}

+ (void)measureEventName:(NSString *)eventName {
    [self measureEvent:[TuneEvent eventWithName:eventName]];
}

+ (void)measureEvent:(TuneEvent *)event {
    if (event == nil) {
        [TuneLog.shared logError:@"ERROR: event cannot be nil"];
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

+ (BOOL)handleOpenURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    if (@available(iOS 9, *)) {
        NSString *sourceApplication = options[UIApplicationOpenURLOptionsSourceApplicationKey];
        return [self handleOpenURL:url sourceApplication:sourceApplication];
    }
    return NO;
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

+ (BOOL)handleContinueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler {
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
