//
//  TuneUserProfile.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/3/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <mach/machine.h>
#import <Foundation/Foundation.h>
#if TARGET_OS_IOS
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif
#import <UIKit/UIKit.h>

#import "TuneUserProfile.h"

#import "TuneAnalyticsConstants.h"
#import "TuneAnalyticsVariable.h"
#import "TuneConfiguration.h"
#import "TuneDeeplinker.h"
#import "TuneIfa.h"
#import "TuneInstallReceipt.h"
#import "TuneJSONUtils.h"
#import "TuneKeyStrings.h"
#import "TuneLocation+Internal.h"
#import "TuneManager.h"
#import "TunePreloadData.h"
#import "TuneSkyhookCenter.h"
#import "TuneUserAgentCollector.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneDeviceUtils.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"

#import "TuneConstants.h"

#if TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#endif

@interface TuneUserProfile()

#if TARGET_OS_IOS
@property (nonatomic, strong, readwrite) CTTelephonyNetworkInfo *netInfo;
#endif

@property (nonatomic, strong, readwrite) NSMutableDictionary *userVariables;
@property (nonatomic, strong, readwrite) NSMutableSet *userCustomVariables;
@property (nonatomic, strong, readwrite) NSMutableSet *currentVariations;

@end

@implementation TuneUserProfile

#pragma mark - Initialization

+ (NSDictionary *)profileVariablesToSave {
    static NSDictionary *dictionary;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dictionary = @{ TUNE_KEY_SESSION_ID           : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_NONE],
                        TUNE_KEY_MAT_ID               : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_NONE],
                        TUNE_KEY_MAT_INSTALL_LOG_ID   : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_NONE],
                        TUNE_KEY_MAT_UPDATE_LOG_ID    : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_NONE],
                        TUNE_KEY_OPEN_LOG_ID          : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_NONE],
                        TUNE_KEY_LAST_OPEN_LOG_ID     : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_NONE],
                        TUNE_KEY_IAD_ATTRIBUTION      : @[TUNE_DATA_TYPE_FLOAT, TUNE_HASH_TYPE_NONE],
                        TUNE_KEY_USER_EMAIL_MD5       : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_MD5],
                        TUNE_KEY_USER_EMAIL_SHA1      : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_SHA1],
                        TUNE_KEY_USER_EMAIL_SHA256    : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_SHA256],
                        TUNE_KEY_USER_ID              : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_NONE],
                        TUNE_KEY_USER_NAME_MD5        : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_MD5],
                        TUNE_KEY_USER_NAME_SHA1       : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_SHA1],
                        TUNE_KEY_USER_NAME_SHA256     : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_SHA256],
                        TUNE_KEY_USER_PHONE_MD5       : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_MD5],
                        TUNE_KEY_USER_PHONE_SHA1      : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_SHA1],
                        TUNE_KEY_USER_PHONE_SHA256    : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_SHA256],
                        TUNE_KEY_IS_PAYING_USER       : @[TUNE_DATA_TYPE_BOOLEAN, TUNE_HASH_TYPE_NONE],
                        TUNE_KEY_SESSION_COUNT        : @[TUNE_DATA_TYPE_FLOAT, TUNE_HASH_TYPE_NONE],
                        TUNE_KEY_SESSION_CURRENT_DATE : @[TUNE_DATA_TYPE_DATETIME, TUNE_HASH_TYPE_NONE],
                        TUNE_KEY_SESSION_LAST_DATE    : @[TUNE_DATA_TYPE_DATETIME, TUNE_HASH_TYPE_NONE],
                        TUNE_KEY_DEVICE_TOKEN         : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_NONE],
                        TUNE_KEY_PUSH_ENABLED         : @[TUNE_DATA_TYPE_STRING, TUNE_HASH_TYPE_NONE],
                        TUNE_KEY_IS_FIRST_SESSION     : @[TUNE_DATA_TYPE_BOOLEAN, TUNE_HASH_TYPE_NONE]
                        };
    });
    
    return dictionary;
}

+ (NSSet *)profileVariablesToNotSendToMA {
    static NSSet *set;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [[NSSet alloc] initWithArray:@[TUNE_KEY_LONGITUDE,
                                             TUNE_KEY_LATITUDE,
                                             TUNE_KEY_ALTITUDE,
                                             TUNE_KEY_LOCATION_HORIZONTAL_ACCURACY,
                                             TUNE_KEY_LOCATION_VERTICAL_ACCURACY,
                                             TUNE_KEY_LOCATION_TIMESTAMP]];
    });
    return set;
}

+ (NSSet *)profileVariablesToOnlySendOnFirstSession {
    static NSSet *set;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = [[NSSet alloc] initWithArray:@[TUNE_KEY_INSTALL_RECEIPT]];
    });
    return set;
}

- (instancetype)initWithTuneManager:(TuneManager *)tuneManager {
    self = [super initWithTuneManager:tuneManager];
    
    if (self) {
        
#if TARGET_OS_IOS
        self.netInfo = [CTTelephonyNetworkInfo new];
#endif
        
        self.userVariables = [NSMutableDictionary new];
        self.userCustomVariables = [NSMutableSet new];
        self.currentVariations = [NSMutableSet new];
        
        [self loadSavedProfile];
        
        // Tune ID
        // NOTE: The first time we run the tuneId will not be loaded from the disk, so it needs to generated.
        //        On subsequent runs it is loaded from NSUserDefaults automatically, so it doesn't need to be remade.
        if ([self tuneId] == nil) {
            NSString *uuid = [TuneUtils getUUID];
            [self setTuneId:uuid];
        }
        
        [self setIsTestFlightBuild:@([TuneDeviceUtils currentDeviceIsTestFlight])];
        if ([[self isTestFlightBuild] boolValue]) {
            NSLog(@"Detected TestFlight build, using \"%@\" as deviceId", [self deviceId]);
        }

        NSString *strOsType = @"iOS";
#if TARGET_OS_TV
        strOsType = @"tvOS";
#elif TARGET_OS_WATCH
        strOsType = @"watchOS";
#endif
        // We are on an IOS device
        [self setOsType:strOsType];

#if !TARGET_OS_WATCH
        // IDFA
        [self updateIFA];
#endif
        
        // Set App Parameters
        [self setAppParams];
        
        // install receipt
        [self setReceiptData];
        
        // hardware specs
        [self setHardwareSpecs];
        
        //Other params
        [self setCountryCode:[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]];
#if TARGET_OS_WATCH
        [self setOsVersion:[[WKInterfaceDevice currentDevice] systemVersion]];
#else
        [self setOsVersion:[[UIDevice currentDevice] systemVersion]];
#endif
        [self setLanguage:[[NSLocale preferredLanguages] objectAtIndex:0]];
        [self setInstallDate:[TuneUtils installDate]];
        [self setSDKVersion:[TuneConfiguration frameworkVersion]];
        [self setMinutesFromGMT:@((int)[[NSTimeZone localTimeZone] secondsFromGMT] / 60)];
        [self setLocale:[[NSLocale currentLocale] localeIdentifier]];
        [self updateCoppaStatus];
        
#if TARGET_OS_IOS
        // FB cookie id
        [self loadFacebookCookieId];
#endif
        
        // default to USD for currency code
        [self setCurrencyCode:TUNE_KEY_CURRENCY_USD];
    }
    
    return self;
}


// These methods don't need an implementation since this module must always be up
- (void)bringUp {}
- (void)bringDown {}

#pragma mark - Skyhook registration

- (void)registerSkyhooks {
    [self unregisterSkyhooks];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(initiateSession:)
                                              name:TuneSessionManagerSessionDidStart
                                            object:nil
                                          priority:TuneSkyhookPrioritySecond];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(endSession:)
                                              name:TuneSessionManagerSessionDidEnd
                                            object:nil];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleAddSessionProfileVariable:)
                                              name:TuneSessionVariableToSet
                                            object:nil];
    
    // Listen for registration of device with APN
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(handleRegisteredForRemoteNotificationsWithDeviceToken:)
                                              name:TuneRegisteredForRemoteNotificationsWithDeviceToken
                                            object:nil];
}

#pragma mark - Session Data handlers

- (void)initiateSession:(TuneSkyhookPayload *)payload {
    if (payload.userInfo) {
        NSString *sessionId = [payload.userInfo objectForKey:@"sessionId"];
        NSDate *sessionStartTime = [payload.userInfo objectForKey:@"sessionStartTime"];
        
        if (sessionId) {
            [self storeProfileKey:TUNE_KEY_SESSION_ID value:sessionId];
            
            // TODO: Convert these calls to the NSUserDefaults with calls to the getters?
            if([TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_SESSION_CURRENT_DATE] && [TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_SESSION_COUNT]) {
                NSNumber *currentSessionCount = (NSNumber *)[TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_SESSION_COUNT];
                NSDate *previousSessionDate = [TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_SESSION_CURRENT_DATE];
                
                [self storeProfileKey:TUNE_KEY_SESSION_COUNT value:@([currentSessionCount intValue] + 1) type:TuneAnalyticsVariableNumberType];
                [self storeProfileKey:TUNE_KEY_SESSION_LAST_DATE value:previousSessionDate type:TuneAnalyticsVariableDateTimeType];
            } else {
                [self storeProfileKey:TUNE_KEY_SESSION_COUNT value:@(1) type:TuneAnalyticsVariableNumberType];
                [self storeProfileKey:TUNE_KEY_SESSION_LAST_DATE value:[NSNull null] type:TuneAnalyticsVariableDateTimeType];
            }
            
            if (sessionStartTime) {
                [self storeProfileKey:TUNE_KEY_SESSION_CURRENT_DATE value:sessionStartTime type:TuneAnalyticsVariableDateTimeType];
            }
        }
        
        @synchronized(self) {
            // Restore saved custom profile variable names
            NSString *customVariablesJson = (NSString *)[TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_CUSTOM_VARIABLES];
            [self.userCustomVariables addObjectsFromArray:[TuneJSONUtils createArrayFromJSONString:customVariablesJson]];
            
            // Restore variable values for each name in custom variables
            for (NSString *variableName in self.userCustomVariables) {
                TuneAnalyticsVariable *storedVariable = [TuneUserDefaultsUtils userDefaultCustomVariableforKey:variableName];
                // If stored variable exists, restore it to userVariables
                if (storedVariable) {
                    [self storeProfileVar:storedVariable];
                }
            }
        }
    }
    
    // Update this at the beginning of each of the sessions since this can change without our notification.
    [self checkIfPushIsEnabled];
}

- (void)endSession:(TuneSkyhookPayload *)payload {
    // Save custom profile variable names
    @synchronized(self) {
        NSString *customVariablesJson = [TuneJSONUtils createJSONStringFromArray:[self.userCustomVariables allObjects]];
        [TuneUserDefaultsUtils setUserDefaultValue:customVariablesJson forKey:TUNE_KEY_CUSTOM_VARIABLES];
    }
}

#pragma mark - Current Variation Helpers

- (void)handleAddSessionProfileVariable:(TuneSkyhookPayload *)payload {
    NSString *variableName = (NSString *)[payload userInfo][TunePayloadSessionVariableName];
    NSString *variableValue = (NSString *)[payload userInfo][TunePayloadSessionVariableValue];
    NSString *saveType = (NSString *)[payload userInfo][TunePayloadSessionVariableSaveType];
    
    if ([saveType isEqualToString:TunePayloadSessionVariableSaveTypeProfile]) {
        [self registerProfileVariable:variableName withValue:variableValue];
    }
}

- (void)registerProfileVariable:(NSString *)name withValue:(NSString *)value {
    TuneAnalyticsVariable *newVariable = [TuneAnalyticsVariable analyticsVariableWithName:name value:value];

    @synchronized(self) {
        [self.currentVariations addObjectsFromArray:newVariable.toArrayOfDicts];
    }
}

#pragma mark - Profile Value Generators

- (void)handleRegisteredForRemoteNotificationsWithDeviceToken:(TuneSkyhookPayload *)payload {
    NSString *deviceToken = (NSString *)[payload userInfo][@"deviceToken"];
    if ([deviceToken length] > 0) {
        // Add the device token to the instance profile
        [self setDeviceToken:deviceToken];
    }
}

#if TARGET_OS_IOS
- (void)loadFacebookCookieId {
    [self setFacebookCookieId:[TuneUtils generateFBCookieIdString]];
}
#endif

#if !TARGET_OS_WATCH
- (void)updateIFA {
    if (self.tuneManager.configuration.shouldAutoCollectAdvertisingIdentifier) {
        TuneIfa *ifaInfo = [TuneIfa ifaInfo];
        
        if(ifaInfo) {
            [self setAppleAdvertisingIdentifier:ifaInfo.ifa];
            [self setAppleAdvertisingTrackingEnabled:@(ifaInfo.trackingEnabled)];
        }
    }
}

- (void)clearIFA {
    [self setAppleAdvertisingIdentifier:nil];
    [self setAppleAdvertisingTrackingEnabled:@(NO)];
}
#endif

- (void)setDeviceToken:(NSString *)deviceToken {
    [self storeProfileKey:TUNE_KEY_DEVICE_TOKEN value:deviceToken];
    [self checkIfPushIsEnabled];
}

- (NSString *)deviceToken {
    return [self getProfileValue:TUNE_KEY_DEVICE_TOKEN];
}

- (void)updateCoppaStatus {
    BOOL isCoppa = NO;
    
    if ([self privacyProtectedDueToAge]) {
        isCoppa = YES;
    
    } else {
        NSNumber *coppaAgeLimit = @13;
        
        // Can be read as age < coppaAgeLimit, when age is available
        isCoppa = self.age != nil && [self.age compare:coppaAgeLimit] == NSOrderedAscending;
    }
    [self storeProfileKey:TUNE_KEY_IS_COPPA value:@(isCoppa) type:TuneAnalyticsVariableBooleanType];
}

- (BOOL)tooYoungForTargetedAds {
    NSNumber *value = (NSNumber *)[self getProfileValue:TUNE_KEY_IS_COPPA];
    if (value) {
        return value.boolValue;
    }
    return NO;
}

#if TARGET_OS_IOS

- (void)checkIfPushIsEnabled {
    BOOL pushEnabled = NO;
    
    if (![self tooYoungForTargetedAds]) {
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
            // iOS8 and after way to get notification types
            pushEnabled = UIUserNotificationTypeAlert == (UIUserNotificationTypeAlert & [UIApplication sharedApplication].currentUserNotificationSettings.types);
        } else {
            // Pre iOS8 way to get notification types
            pushEnabled = UIUserNotificationTypeAlert == (UIUserNotificationTypeAlert & [UIApplication sharedApplication].enabledRemoteNotificationTypes);
        }
    }
    
    [self setPushEnabled:[@(pushEnabled) stringValue]];
}

#else

- (void)checkIfPushIsEnabled {
    [self setPushEnabled:[@(NO) stringValue]];
}

#endif


- (void)setPushEnabled:(NSString *)pushEnabled {
    [self storeProfileKey:TUNE_KEY_PUSH_ENABLED value:pushEnabled];
}

- (NSString *)pushEnabled {
    if ([self tooYoungForTargetedAds]) {
        return [@(NO) stringValue];
    }
    
    return [self getProfileValue:TUNE_KEY_PUSH_ENABLED];
}

- (NSString *)hashedAppId {
    return [TuneUtils hashMd5: [NSString stringWithFormat:@"%@|%@|%@", self.advertiserId, self.packageName, TUNE_KEY_IOS]];
}

- (NSString *)deviceId {
    if ([self.isTestFlightBuild boolValue]) {
        return self.tuneId;
    } else if (self.appleAdvertisingIdentifier && ![self.appleAdvertisingIdentifier isEqualToString:@""]) {
        return self.appleAdvertisingIdentifier;
    } else {
        return self.tuneId;
    }
}

- (void)setAppParams {
    // App params
    [self setPackageName:[TuneUtils bundleId]];
    [self setAppBundleId:[TuneUtils bundleId]];
    [self setAppName:[TuneUtils bundleName]];
    [self setAppVersion:[TuneUtils bundleVersion]];
    [self setAppVersionName:[TuneUtils stringVersion]];
    
#if TESTING
    // should only happen during unit tests
    if( [self packageName] == nil && [UIApplication sharedApplication] == nil ) {
        
    #if TARGET_OS_TV
        NSString *strTestBundleId = @"com.mobileapptracking.tvosunittest";
    #else
        NSString *strTestBundleId = @"com.mobileapptracking.iosunittest";
    #endif
        
        [self setPackageName:strTestBundleId];
    }
#endif
}

- (void)setReceiptData {
    NSData *receiptData = [TuneInstallReceipt installReceipt];
    [self storeProfileKey:TUNE_KEY_INSTALL_RECEIPT value:[TuneUtils tuneBase64EncodedStringFromData:receiptData]];
}

- (void)setHardwareSpecs {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *machineName = [NSString stringWithCString:systemInfo.machine
                                               encoding:NSUTF8StringEncoding];
    [self setDeviceModel:machineName];

    size_t size;
    cpu_type_t type;
    cpu_subtype_t subtype;
    size = sizeof(type);
    sysctlbyname("hw.cputype", &type, &size, NULL, 0);
    [self setDeviceCpuType:@(type)];
    
    size = sizeof(subtype);
    sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0);
    [self setDeviceCpuSubtype:@(subtype)];
    
    // From http://iphonedevsdk.com/discussion/comment/111621/#Comment_111621
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    [self setHardwareType:@(machine)];
    free(machine);
    
    // Set build name to kern.osversion
    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    char *build = malloc(size);
    sysctlbyname("kern.osversion", build, &size, NULL, 0);
    [self setDeviceBuild:@(build)];
    free(build);
    
    // Device params
    [self setDeviceBrand:@"Apple"];
    
    CGSize screenSize = CGSizeZero;
    CGFloat screenScale = 1.0;

#if TARGET_OS_WATCH
    CGSize nativeScreenSize = [[WKInterfaceDevice currentDevice] screenBounds].size;
    CGFloat nativeScreenScale = [[WKInterfaceDevice currentDevice] screenScale];
    screenSize = CGSizeMake(nativeScreenSize.width / nativeScreenScale, nativeScreenSize.height / nativeScreenScale);
    
    screenScale = [[WKInterfaceDevice currentDevice] screenScale];
#else
    // Make sure that the collected screen size is independent of the current device orientation,
    // when iOS version
    // >= 8.0 use "nativeBounds"
    // <  8.0 use "bounds"
    if([UIScreen instancesRespondToSelector:@selector(nativeBounds)])
    {
        CGSize nativeScreenSize = [[UIScreen mainScreen] nativeBounds].size;
        CGFloat nativeScreenScale = [[UIScreen mainScreen] nativeScale];
        screenSize = CGSizeMake(nativeScreenSize.width / nativeScreenScale, nativeScreenSize.height / nativeScreenScale);
    }
    else
    {
        screenSize = [[UIScreen mainScreen] bounds].size;
    }
    
    screenScale = [[UIScreen mainScreen] scale];
#endif
    
    [self setScreenWidth:@(screenSize.width)];
    [self setScreenHeight:@(screenSize.height)];
    
    [self setScreenSize:[NSString stringWithFormat:@"%.fx%.f", screenSize.width, screenSize.height]];
    [self setScreenDensity:@(screenScale)];
    
    
#if TARGET_OS_IOS
    CTCarrier *carrier = [self.netInfo subscriberCellularProvider];
    [self setDeviceCarrier:[carrier carrierName]];
    [self setMobileCountryCode:[carrier mobileCountryCode]];
    [self setMobileCountryCodeISO:[carrier isoCountryCode]];
    [self setMobileNetworkCode:[carrier mobileNetworkCode]];
#endif
    
    [self setInterfaceIdiom:[TuneDeviceUtils artisanInterfaceIdiomString]];
}

#pragma mark - Methods for setting Custom Profile Variables


- (void)registerString:(NSString *)variableName {
    [self registerString:variableName withDefault:nil];
}

- (void)registerString:(NSString *)variableName hashed:(BOOL)shouldAutoHash {
    [self registerString:variableName withDefault:nil hashed:(BOOL)shouldAutoHash];
}

- (void)registerBoolean:(NSString *)variableName {
    [self registerBoolean:variableName withDefault:nil];
}

- (void)registerDateTime:(NSString *)variableName {
    [self registerDateTime:variableName withDefault:nil];
}

- (void)registerNumber:(NSString *)variableName {
    [self registerNumber:variableName withDefault:nil];
}

- (void)registerGeolocation:(NSString *)variableName {
    [self registerGeolocation:variableName withDefault:nil];
}

- (void)registerVersion:(NSString *)variableName {
    [self registerVersion:variableName withDefault:nil];
}

- (void)registerString:(NSString *)variableName withDefault:(NSString *)value {
    [self registerString:variableName withDefault:value hashed:NO];
}

- (void)registerString:(NSString *)variableName withDefault:(NSString *)value hashed:(BOOL)shouldAutoHash {
    [self registerVariable:variableName value:value type:TuneAnalyticsVariableStringType hashed:shouldAutoHash];
}

- (void)registerBoolean:(NSString *)variableName withDefault:(NSNumber *)value {
    [self registerVariable:variableName value:value type:TuneAnalyticsVariableBooleanType hashed:NO];
}

- (void)registerDateTime:(NSString *)variableName withDefault:(NSDate *)value {
    [self registerVariable:variableName value:value type:TuneAnalyticsVariableDateTimeType hashed:NO];
}

- (void)registerNumber:(NSString *)variableName withDefault:(NSNumber *)value {
    [self registerVariable:variableName value:value type:TuneAnalyticsVariableNumberType hashed:NO];
}

- (void)registerGeolocation:(NSString *)variableName withDefault:(TuneLocation *)value {
    [self registerVariable:variableName value:value type:TuneAnalyticsVariableCoordinateType hashed:NO];
}

- (void)registerVersion:(NSString *)variableName withDefault:(NSString *)value {
    [self registerVariable:variableName value:value type:TuneAnalyticsVariableVersionType hashed:NO];
}

- (void)registerVariable:(NSString *)variableName value:(id)value type:(TuneAnalyticsVariableDataType)type hashed:(BOOL)shouldAutoHash {
    if ([TuneAnalyticsVariable validateName:variableName]){
        NSString *prettyName = [TuneAnalyticsVariable cleanVariableName:variableName];
        NSSet *systemVariables = [TuneUserProfileKeys systemVariables];
        
        for (NSString *systemVariable in systemVariables) {
            if ([prettyName caseInsensitiveCompare:systemVariable] == NSOrderedSame) {
                ErrorLog(@"The variable '%@' is a system variable, and cannot be registered in this manner. Please use another name.", prettyName);
                return;
            }
        }
        
        if ([prettyName hasPrefix:@"TUNE_"]) {
            ErrorLog(@"Profile variables starting with 'TUNE_' are reserved. Not registering: %@", prettyName);
            return;
        }
        
        [self addCustomProfileVariable:prettyName];
        
        TuneAnalyticsVariable *storedVar = [TuneUserDefaultsUtils userDefaultCustomVariableforKey:prettyName];
        if (storedVar && storedVar.type == type) {
            // If we have a stored custom variable and it is of the matching type use the stored value
            TuneAnalyticsVariable *var = [TuneAnalyticsVariable analyticsVariableWithName:prettyName
                                                                                    value:value
                                                                                     type:storedVar.type
                                                                           shouldAutoHash:storedVar.shouldAutoHash];
            if (storedVar.didHaveValueManuallySet) {
                var.value = storedVar.value;
                var.didHaveValueManuallySet = YES;
            } else {
                var.didHaveValueManuallySet = NO;
            }
            
            [self storeProfileVar:var];
        } else {
            // NOTE: Set a blank variable to be changed later
            [self storeProfileKey:prettyName value:value type:type hashType:TuneAnalyticsVariableHashNone shouldAutoHash:shouldAutoHash];
            // Otherwise just use the default value. IE nil if the user didn't specify one
            return;
        }
    }
    
    return;
}

- (void)setStringValue:(NSString *)value forVariable:(NSString *)name {
    [self setCustomVariable:name value:value type:TuneAnalyticsVariableStringType];
}

- (void)setBooleanValue:(NSNumber *)value forVariable:(NSString *)name {
    [self setCustomVariable:name value:value type:TuneAnalyticsVariableBooleanType];
}

- (void)setDateTimeValue:(NSDate *)value forVariable:(NSString *)name {
    [self setCustomVariable:name value:value type:TuneAnalyticsVariableDateTimeType];
}

- (void)setNumberValue:(NSNumber *)value forVariable:(NSString *)name {
    [self setCustomVariable:name value:value type:TuneAnalyticsVariableNumberType];
}

- (void)setGeolocationValue:(TuneLocation *)value forVariable:(NSString *)name {
    if (![TuneAnalyticsVariable validateTuneLocation:value]) {
        ErrorLog(@"Both the longitude and latitude properties must be set for TuneLocation objects.");
        return;
    }
    
    [self setCustomVariable:name value:value type:TuneAnalyticsVariableCoordinateType];
}

- (void)setVersionValue:(NSString *)value forVariable:(NSString *)name {
    if (![TuneAnalyticsVariable validateVersion:value]) {
        ErrorLog(@"The given version format is not valid. Got: %@", value);
        return;
    }
    
    [self setCustomVariable:name value:value type:TuneAnalyticsVariableVersionType];
}

- (void)setCustomVariable:(NSString *)name value:(id)value type:(TuneAnalyticsVariableDataType)type {
    if ([TuneAnalyticsVariable validateName:name]){
        NSString *prettyName = [TuneAnalyticsVariable cleanVariableName:name];
        
        if([[self getCustomProfileVariables] containsObject:prettyName]){
            TuneAnalyticsVariable *var = [self getProfileVariable:prettyName];
            
            // If var is nil, then there wasn't a value stored in the userVariables dictionary. This occurs when the variable is initially set and doesn't
            // have a value stored in NSUserDefaults, or when the value is cleared.
            if (var == nil || var.type == type) {
                TuneAnalyticsVariable *toStore = [TuneAnalyticsVariable analyticsVariableWithName:prettyName value:value type:type];
                toStore.didHaveValueManuallySet = YES;
                [self storeProfileVar:toStore];
            } else {
                ErrorLog(@"Attempting to set the variable '%@', registered as a %@, with the %@ setter. Please use the appropriate setter.", prettyName, [TuneAnalyticsVariable dataTypeToString:var.type], [TuneAnalyticsVariable dataTypeToString:type]);
            }
        } else {
            ErrorLog(@"In order to set a value for '%@' it must be registered first.", prettyName);
        }
    }
}

- (NSString *)getCustomProfileString:(NSString *)name {
    return (NSString *)[self getCustomProfileVariable:name];
}

- (NSNumber *)getCustomProfileNumber:(NSString *)name {
    return (NSNumber *)[self getCustomProfileVariable:name];
}

- (NSDate *)getCustomProfileDateTime:(NSString *)name {
    return (NSDate *)[self getCustomProfileVariable:name];
}

- (TuneLocation *)getCustomProfileGeolocation:(NSString *)name {
    return (TuneLocation *)[self getCustomProfileVariable:name];
}

- (id)getCustomProfileVariable:(NSString *)name {
    if ([TuneAnalyticsVariable validateName:name]) {
        NSString *prettyName = [TuneAnalyticsVariable cleanVariableName:name];
        
        if([[self getCustomProfileVariables] containsObject:prettyName]){
            return [self getProfileValue:name];
        } else {
            ErrorLog(@"In order to get a value for '%@' it must be registered first.", prettyName);
        }
    }
    
    return nil;
}

- (void) clearVariable:(NSString *)key {
    [TuneUserDefaultsUtils clearCustomVariable:key];
    
    @synchronized(self) {
        [self.userVariables removeObjectForKey:key];
    }
}

- (void) clearCustomVariables:(NSSet *)variables {
    NSMutableSet *clearedVariables = [[NSMutableSet alloc] init];
    
    for (NSString *key in variables) {
        if ([TuneAnalyticsVariable validateName:key]) {
            NSString *cleanVariableName = [TuneAnalyticsVariable cleanVariableName:key];
            
            if ([[self getCustomProfileVariables] containsObject:cleanVariableName]) {
                [self clearVariable:cleanVariableName];
                [clearedVariables addObject: cleanVariableName];
            }
        }
    }
    
    // Only send the Power Hook if we cleared at least one variable.
    if (clearedVariables.count > 0) {
        [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneUserProfileVariablesCleared
                                                      object:nil
                                                    userInfo:@{ TunePayloadProfileVariablesToClear: clearedVariables }];
    }
}

- (void)clearCustomProfile {
    [self clearCustomVariables:[self getCustomProfileVariables]];
}

#pragma mark - Profile Variable Manager Methods

- (void)addCustomProfileVariable:(NSString *)value {
    @synchronized(self) {
        [self.userCustomVariables addObject:value];
    }
}

- (NSSet *)getCustomProfileVariables {
    @synchronized(self) {
        // One layer deep copy, requires all contents conform to NSCopying
        // NSString does conform to NSCopying
        return [[NSSet alloc] initWithSet:self.userCustomVariables copyItems:YES];
    }
}

- (id)getProfileValue:(NSString *)key {
    @synchronized(self) {
        if ([self.userVariables objectForKey: key] != nil) {
            return [(TuneAnalyticsVariable *)[self.userVariables objectForKey: key] value];
        };
    }
        
    return nil;
}

- (TuneAnalyticsVariable *)getProfileVariable:(NSString *)key {
    @synchronized(self) {
        if ([self.userVariables objectForKey: key] != nil) {
            return (TuneAnalyticsVariable *)[self.userVariables objectForKey: key];
        } else {
            return nil;
        }
    }
    
    return nil;
}

- (NSDictionary *)getProfileVariables {
    @synchronized(self){
        // One layer deep copy, requires all contents conform to NSCopying
        // TuneAnalyticsVariable does conform to NSCopying
        return [[NSDictionary alloc] initWithDictionary:self.userVariables copyItems:YES];
    }
}

- (void) storeProfileKey:(NSString *)key
                   value:(id)value {
    [self storeProfileKey:key value:value type:TuneAnalyticsVariableStringType hashType:TuneAnalyticsVariableHashNone shouldAutoHash:NO];
}

- (void) storeProfileKey:(NSString *)key
                   value:(id)value
                hashType:(TuneAnalyticsVariableHashType)hashType {
    [self storeProfileKey:key value:value type:TuneAnalyticsVariableStringType hashType:hashType shouldAutoHash:NO];
}

- (void) storeProfileKey:(NSString *)key
                   value:(id)value
                    type:(TuneAnalyticsVariableDataType)type {
    [self storeProfileKey:key value:value type:type hashType:TuneAnalyticsVariableHashNone shouldAutoHash:NO];
}

- (void) storeProfileKey:(NSString *)key
                   value:(id)value
                    type:(TuneAnalyticsVariableDataType)type
                hashType:(TuneAnalyticsVariableHashType)hashType
          shouldAutoHash:(BOOL)shouldAutoHash {
    TuneAnalyticsVariable *var = [TuneAnalyticsVariable analyticsVariableWithName:key value:value type:type hashType:hashType shouldAutoHash:shouldAutoHash];
    [self storeProfileVar:var];
}

- (void)storeProfileVar:(TuneAnalyticsVariable *)var {
    @synchronized(self) {
        NSString *key = var.name;
        
        [self.userVariables setObject:[var copy] forKey:key];
        
        if ([[TuneUserProfile profileVariablesToSave] objectForKey:key] != nil) {
            [TuneUserDefaultsUtils setUserDefaultValue:var.value forKey:key];
        } else if ([[self getCustomProfileVariables] containsObject:key]) {
            [TuneUserDefaultsUtils setUserDefaultCustomVariable:[var copy] forKey:key];
        }
    }
}

#pragma mark - Specific Property Getters and Setters

- (NSString *)installReceipt {
    return [self getProfileValue:TUNE_KEY_INSTALL_RECEIPT];
}

- (void)setSessionId:(NSString *)sessionId {
    [self storeProfileKey:TUNE_KEY_SESSION_ID value:sessionId];
}
- (NSString *)sessionId {
    return [self getProfileValue:TUNE_KEY_SESSION_ID];
}

- (void)setLastSessionDate:(NSDate *)lastSessionDate {
    [self storeProfileKey:TUNE_KEY_SESSION_LAST_DATE value:lastSessionDate type:TuneAnalyticsVariableDateTimeType];
}
- (NSDate *)lastSessionDate {
    return [self getProfileValue:TUNE_KEY_SESSION_LAST_DATE];
}

- (void)setCurrentSessionDate:(NSDate *)currentSessionDate {
    [self storeProfileKey:TUNE_KEY_SESSION_CURRENT_DATE value:currentSessionDate type:TuneAnalyticsVariableDateTimeType];
}
- (NSDate *)currentSessionDate {
    return [self getProfileValue:TUNE_KEY_SESSION_CURRENT_DATE];
}

- (void)setSessionCount:(NSNumber *)count {
    [self storeProfileKey:TUNE_KEY_SESSION_COUNT value:count type:TuneAnalyticsVariableNumberType];
}
- (NSNumber *)sessionCount {
    return [self getProfileValue:TUNE_KEY_SESSION_COUNT];
}

- (void)setInstallDate:(NSDate *)installDate {
    [self storeProfileKey:TUNE_KEY_INSDATE value:installDate type:TuneAnalyticsVariableDateTimeType];
}
- (NSDate *)installDate {
    return [self getProfileValue:TUNE_KEY_INSDATE];
}

- (void)setSessionDate:(NSString *)sessionDate {
    [self storeProfileKey:TUNE_KEY_SESSION_DATETIME value:sessionDate type:TuneAnalyticsVariableDateTimeType];
}
- (NSString *)sessionDate {
    return [self getProfileValue:TUNE_KEY_SESSION_DATETIME];
}

- (void)setSystemDate:(NSDate *)systemDate {
    [self storeProfileKey:TUNE_KEY_SYSTEM_DATE value:systemDate type:TuneAnalyticsVariableDateTimeType];
}
- (NSDate *)systemDate {
    return [self getProfileValue:TUNE_KEY_SYSTEM_DATE];
}

- (void)setTuneId:(NSString *)tuneId {
    [self storeProfileKey:TUNE_KEY_MAT_ID value:tuneId];
}
- (NSString *)tuneId {
    return [self getProfileValue:TUNE_KEY_MAT_ID];
}

- (void)setIsFirstSession:(NSNumber *)isFirstSession {
    [self storeProfileKey:TUNE_KEY_IS_FIRST_SESSION value:isFirstSession type:TuneAnalyticsVariableBooleanType];
}
- (NSNumber *)isFirstSession {
    return [self getProfileValue:TUNE_KEY_IS_FIRST_SESSION];
}

- (void)setInstallLogId:(NSString *)installLogId {
    [self storeProfileKey:TUNE_KEY_INSTALL_LOG_ID value:installLogId];
}
- (NSString *)installLogId {
    return [self getProfileValue:TUNE_KEY_INSTALL_LOG_ID];
}

- (void)setUpdateLogId:(NSString *)updateLogId {
    [self storeProfileKey:TUNE_KEY_UPDATE_LOG_ID value:updateLogId];
}
- (NSString *)updateLogId {
    return [self getProfileValue:TUNE_KEY_UPDATE_LOG_ID];
}

- (void)setOpenLogId:(NSString *)openLogId {
    [self storeProfileKey:TUNE_KEY_OPEN_LOG_ID value:openLogId];
}
- (NSString *)openLogId {
    return [self getProfileValue:TUNE_KEY_OPEN_LOG_ID];
}

- (void)setLastOpenLogId:(NSString *)lastOpenLogId {
    [self storeProfileKey:TUNE_KEY_LAST_OPEN_LOG_ID value:lastOpenLogId];
}
- (NSString *)lastOpenLogId {
    return [self getProfileValue:TUNE_KEY_LAST_OPEN_LOG_ID];
}

- (void)setAdvertiserId:(NSString *)advertiserId {
    [self storeProfileKey:TUNE_KEY_ADVERTISER_ID value:advertiserId];
}

- (NSString *)advertiserId {
    return [self getProfileValue:TUNE_KEY_ADVERTISER_ID];
}

- (void)setConversionKey:(NSString *)conversionKey {
    [self storeProfileKey:TUNE_KEY_KEY value:conversionKey];
}

- (NSString *)conversionKey {
    return [self getProfileValue:TUNE_KEY_KEY];
}

- (void)setAppBundleId:(NSString *)bId {
    [self storeProfileKey:TUNE_KEY_APP_BUNDLE_ID value:bId];
}
- (NSString *)appBundleId {
    return [self getProfileValue:TUNE_KEY_APP_BUNDLE_ID];
}

- (void)setAppName:(NSString *)appName {
    [self storeProfileKey:TUNE_KEY_APP_NAME value:appName];
}
- (NSString *)appName {
    return [self getProfileValue:TUNE_KEY_APP_NAME];
}

- (void)setAppVersion:(NSString *)appVersion {
    [self storeProfileKey:TUNE_KEY_APP_VERSION value:appVersion type:TuneAnalyticsVariableVersionType];
}
- (NSString *)appVersion {
    return [self getProfileValue:TUNE_KEY_APP_VERSION];
}

- (void)setAppVersionName:(NSString *)appVersionName {
    [self storeProfileKey:TUNE_KEY_APP_VERSION_NAME value:appVersionName type:TuneAnalyticsVariableVersionType];
}
- (NSString *)appVersionName {
    return [self getProfileValue:TUNE_KEY_APP_VERSION_NAME];
}

- (void)setWearable:(NSNumber *)wearable {
    [self storeProfileKey:TUNE_KEY_DEVICE_FORM value:wearable type:TuneAnalyticsVariableBooleanType];
}

- (NSNumber *)wearable {
    return [self getProfileValue:TUNE_KEY_DEVICE_FORM];
}

- (void)setExistingUser:(NSNumber *)existingUser {
    [self storeProfileKey:TUNE_KEY_EXISTING_USER value:existingUser type:TuneAnalyticsVariableBooleanType];
}

- (NSNumber *)existingUser {
    return [self getProfileValue:TUNE_KEY_EXISTING_USER];
}

- (void)setAppleAdvertisingIdentifier:(NSString *)advertisingId {
    [self storeProfileKey:TUNE_KEY_IOS_IFA value:([advertisingId isEqualToString:TUNE_KEY_GUID_EMPTY] ? nil : advertisingId)];
}

- (NSString *)appleAdvertisingIdentifier {
    return [self getProfileValue:TUNE_KEY_IOS_IFA];
}

- (void)setAppleAdvertisingTrackingEnabled:(NSNumber *)adTrackingEnabled {
    [self storeProfileKey:TUNE_KEY_IOS_AD_TRACKING value:adTrackingEnabled type:TuneAnalyticsVariableBooleanType];
}

- (NSNumber *)appleAdvertisingTrackingEnabled {
    if ([self tooYoungForTargetedAds]) {
        return @(NO);
    }
    
    return [self getProfileValue:TUNE_KEY_IOS_AD_TRACKING];
}

- (void)setAppleVendorIdentifier:(NSString *)appleVendorIdentifier {
    [self storeProfileKey:TUNE_KEY_IOS_IFV value:appleVendorIdentifier];
}

- (NSString *)appleVendorIdentifier {
    return [self getProfileValue:TUNE_KEY_IOS_IFV];
}

- (void)setCurrencyCode:(NSString *)currencyCode {
    [self storeProfileKey:TUNE_KEY_CURRENCY_CODE value:currencyCode];
}

- (NSString *)currencyCode {
    return [self getProfileValue:TUNE_KEY_CURRENCY_CODE];
}

- (void)setJailbroken:(NSNumber *)jailbroken {
    [self storeProfileKey:TUNE_KEY_OS_JAILBROKE value:jailbroken type:TuneAnalyticsVariableBooleanType];
}

- (NSNumber *)jailbroken {
    return [self getProfileValue:TUNE_KEY_OS_JAILBROKE];
}

- (void)setPackageName:(NSString *)packageName {
    [self storeProfileKey:TUNE_KEY_PACKAGE_NAME value:packageName];
}

- (NSString *)packageName {
    return [self getProfileValue:TUNE_KEY_PACKAGE_NAME];
}

- (void)setTRUSTeId:(NSString *)tpid {
    [self storeProfileKey:TUNE_KEY_TRUSTE_TPID value:tpid];
}

- (NSString *)trusteTPID {
    return [self getProfileValue:TUNE_KEY_TRUSTE_TPID];
}

- (void)setUserId:(NSString *)userId {
    [self storeProfileKey:TUNE_KEY_USER_ID value:userId];
}

- (NSString *)userId {
    return [self getProfileValue:TUNE_KEY_USER_ID];
}

- (void)setTrackingId:(NSString *)trackingId {
    [self storeProfileKey:TUNE_KEY_TRACKING_ID value:trackingId];
}

- (NSString *)trackingId {
    return [self getProfileValue:TUNE_KEY_TRACKING_ID];
}

- (void)setFacebookUserId:(NSString *)facebookUserId {
    [self storeProfileKey:TUNE_KEY_FACEBOOK_USER_ID value:facebookUserId];
}

- (NSString *)facebookUserId {
    return [self getProfileValue:TUNE_KEY_FACEBOOK_USER_ID];
}

- (void)setFacebookCookieId:(NSString *)facebookCookieId {
    [self storeProfileKey:TUNE_KEY_FB_COOKIE_ID value:facebookCookieId];
}
- (NSString *)facebookCookieId {
    return [self getProfileValue:TUNE_KEY_FB_COOKIE_ID];
}

- (void)setTwitterUserId:(NSString *)twitterUserId {
    [self storeProfileKey:TUNE_KEY_TWITTER_USER_ID value:twitterUserId];
}

- (NSString *)twitterUserId {
    return [self getProfileValue:TUNE_KEY_TWITTER_USER_ID];
}

- (void)setGoogleUserId:(NSString *)googleUserId {
    [self storeProfileKey:TUNE_KEY_GOOGLE_USER_ID value:googleUserId];
}

- (NSString *)googleUserId {
    return [self getProfileValue:TUNE_KEY_GOOGLE_USER_ID];
}

- (void)setPrivacyProtectedDueToAge:(BOOL)privacyProtected {
    [self storeProfileKey:TUNE_KEY_PRIVACY_PROTECTED_DUE_TO_AGE value:@(privacyProtected) type:TuneAnalyticsVariableBooleanType];
    [self updateCoppaStatus];
}

- (BOOL)privacyProtectedDueToAge {
    return ((NSNumber *)[self getProfileValue:TUNE_KEY_PRIVACY_PROTECTED_DUE_TO_AGE]).boolValue;
}

- (void)setAge:(NSNumber *)age {
    [self storeProfileKey:TUNE_KEY_AGE value:age type:TuneAnalyticsVariableNumberType];
    [self updateCoppaStatus];
}

- (NSNumber *)age {
    return [self getProfileValue:TUNE_KEY_AGE];
}

- (void)setGender:(NSNumber *)gender {
    [self storeProfileKey:TUNE_KEY_GENDER value:gender type:TuneAnalyticsVariableNumberType];
}

- (NSNumber *)gender {
    return [self getProfileValue:TUNE_KEY_GENDER];
}

- (void)setAppAdTracking:(NSNumber *)enable {
    [self storeProfileKey:TUNE_KEY_APP_AD_TRACKING value:enable type:TuneAnalyticsVariableBooleanType];
}

- (NSNumber *)appAdTracking {
    if ([self tooYoungForTargetedAds]) {
        return @(NO);
    }
    
    return [self getProfileValue:TUNE_KEY_APP_AD_TRACKING];
}

- (void)setLocationAuthorizationStatus:(NSNumber *)authStatus {
    [self storeProfileKey:TUNE_KEY_LOCATION_AUTH_STATUS value:authStatus type:TuneAnalyticsVariableNumberType];
}

- (NSNumber *)locationAuthorizationStatus {
    return [self getProfileValue:TUNE_KEY_LOCATION_AUTH_STATUS];
}

- (void)setBluetoothState:(NSNumber *)bluetoothState {
    [self storeProfileKey:TUNE_KEY_BLUETOOTH_STATE value:bluetoothState type:TuneAnalyticsVariableNumberType];
}

- (NSNumber *)bluetoothState {
    return [self getProfileValue:TUNE_KEY_BLUETOOTH_STATE];
}

- (void)setPayingUser:(NSNumber *)payingState {
    [self storeProfileKey:TUNE_KEY_IS_PAYING_USER value:payingState type:TuneAnalyticsVariableBooleanType];
}

- (NSNumber *)payingUser {
    return [self getProfileValue:TUNE_KEY_IS_PAYING_USER];
}

- (void)setOsType:(NSString *)osType {
    [self storeProfileKey:TUNE_KEY_OS_TYPE value:osType];
}
- (NSString *)osType {
    return [self getProfileValue:TUNE_KEY_OS_TYPE];
}

- (void)setDeviceModel:(NSString *)deviceModel {
    [self storeProfileKey:TUNE_KEY_DEVICE_MODEL value:deviceModel];
}
- (NSString *)deviceModel {
    return [self getProfileValue:TUNE_KEY_DEVICE_MODEL];
}

- (void)setDeviceCpuType:(NSNumber *)deviceCpuType {
    [self storeProfileKey:TUNE_KEY_DEVICE_CPUTYPE value:deviceCpuType type:TuneAnalyticsVariableNumberType];
}
- (NSNumber *)deviceCpuType {
    return [self getProfileValue:TUNE_KEY_DEVICE_CPUTYPE];
}

- (void)setDeviceCpuSubtype:(NSNumber *)deviceCpuSubtype {
    [self storeProfileKey:TUNE_KEY_DEVICE_CPUSUBTYPE value:deviceCpuSubtype type:TuneAnalyticsVariableNumberType];
}
- (NSNumber *)deviceCpuSubtype {
    return [self getProfileValue:TUNE_KEY_DEVICE_CPUSUBTYPE];
}

- (void)setDeviceCarrier:(NSString *)deviceCarrier {
    [self storeProfileKey:TUNE_KEY_DEVICE_CARRIER value:deviceCarrier];
}
- (NSString *)deviceCarrier {
    return [self getProfileValue:TUNE_KEY_DEVICE_CARRIER];
}

- (void)setDeviceBrand:(NSString *)deviceBrand {
    [self storeProfileKey:TUNE_KEY_DEVICE_BRAND value:deviceBrand];
}
- (NSString *)deviceBrand {
    return [self getProfileValue:TUNE_KEY_DEVICE_BRAND];
}

- (void)setDeviceBuild:(NSString *)deviceBuild {
    [self storeProfileKey:TUNE_KEY_DEVICE_BUILD value:deviceBuild];
}
- (NSString *)deviceBuild {
    return [self getProfileValue:TUNE_KEY_DEVICE_BUILD];
}

- (void)setScreenHeight:(NSNumber *)screenHeight {
    [self storeProfileKey:TUNE_KEY_SCREEN_HEIGHT value:screenHeight type:TuneAnalyticsVariableNumberType];
}
- (NSNumber *)screenHeight {
    return [self getProfileValue:TUNE_KEY_SCREEN_HEIGHT];
}

- (void)setScreenWidth:(NSNumber *)screenWidth {
    [self storeProfileKey:TUNE_KEY_SCREEN_WIDTH value:screenWidth type:TuneAnalyticsVariableNumberType];
}
- (NSNumber *)screenWidth {
    return [self getProfileValue:TUNE_KEY_SCREEN_WIDTH];
}

- (void)setScreenSize:(NSString *)screenSize {
    [self storeProfileKey:TUNE_KEY_SCREEN_SIZE value:screenSize];
}
- (NSString *)screenSize {
    return [self getProfileValue:TUNE_KEY_SCREEN_SIZE];
}

- (void)setScreenDensity:(NSNumber *)screenDensity {
    [self storeProfileKey:TUNE_KEY_SCREEN_DENSITY value:screenDensity type:TuneAnalyticsVariableNumberType];
}
- (NSNumber *)screenDensity {
    return [self getProfileValue:TUNE_KEY_SCREEN_DENSITY];
}

- (void)setMobileCountryCode:(NSString *)mobileCountryCode {
    [self storeProfileKey:TUNE_KEY_CARRIER_COUNTRY_CODE value:mobileCountryCode];
}
- (NSString *)mobileCountryCode {
    return [self getProfileValue:TUNE_KEY_CARRIER_COUNTRY_CODE];
}

- (void)setMobileCountryCodeISO:(NSString *)mobileCountryCodeISO {
    [self storeProfileKey:TUNE_KEY_CARRIER_COUNTRY_CODE_ISO value:mobileCountryCodeISO];
}
- (NSString *)mobileCountryCodeISO {
    return [self getProfileValue:TUNE_KEY_CARRIER_COUNTRY_CODE_ISO];
}

- (void)setMobileNetworkCode:(NSString *)mobileNetworkCode {
    [self storeProfileKey:TUNE_KEY_CARRIER_NETWORK_CODE value:mobileNetworkCode];
}
- (NSString *)mobileNetworkCode {
    return [self getProfileValue:TUNE_KEY_CARRIER_NETWORK_CODE];
}

- (void)setCountryCode:(NSString *)mobileNetworkCode {
    [self storeProfileKey:TUNE_KEY_COUNTRY_CODE value:mobileNetworkCode];
}
- (NSString *)countryCode {
    return [self getProfileValue:TUNE_KEY_COUNTRY_CODE];
}

- (void)setOsVersion:(NSString *)osVersion {
    [self storeProfileKey:TUNE_KEY_OS_VERSION value:osVersion type:TuneAnalyticsVariableVersionType];
}
- (NSString *)osVersion {
    return [self getProfileValue:TUNE_KEY_OS_VERSION];
}

- (void)setLanguage:(NSString *)language {
    [self storeProfileKey:TUNE_KEY_LANGUAGE value:language];
}
- (NSString *)language {
    return [self getProfileValue:TUNE_KEY_LANGUAGE];
}

- (void)setLocale:(NSString *)locale {
    [self storeProfileKey:TUNE_KEY_LOCALE value:locale];
}
- (NSString *)locale {
    return [self getProfileValue:TUNE_KEY_LOCALE];
}

- (void)setReferralUrl:(NSString *)url {
    NSInteger maxReferralURL = 1024;
    
    // limit url length so that the NSXMLParser does not run out of memory
    if (url.length > maxReferralURL) {
        url = [url substringToIndex:maxReferralURL];
    }
    
    [self storeProfileKey:TUNE_KEY_REFERRAL_URL value:url];
}
- (NSString *)referralUrl {
    return [self getProfileValue:TUNE_KEY_REFERRAL_URL];
}

- (void)setReferralSource:(NSString *)source {
    [self storeProfileKey:TUNE_KEY_REFERRAL_SOURCE value:source];
}
- (NSString *)referralSource {
    return [self getProfileValue:TUNE_KEY_REFERRAL_SOURCE];
}

- (void)setRedirectUrl:(NSString *)redirectUrl {
    [self storeProfileKey:TUNE_KEY_REDIRECT_URL value:redirectUrl];
}
- (NSString *)redirectUrl {
    return [self getProfileValue:TUNE_KEY_REDIRECT_URL];
}

- (void)setIadAttribution:(NSNumber *)iadAttribution {
    [self storeProfileKey:TUNE_KEY_IAD_ATTRIBUTION value:iadAttribution type:TuneAnalyticsVariableNumberType];
}
- (NSNumber *)iadAttribution {
    return [self getProfileValue:TUNE_KEY_IAD_ATTRIBUTION];
}

- (void)setIadImpressionDate:(NSDate *)iadImpressionDate {
    [self storeProfileKey:TUNE_KEY_IAD_IMPRESSION_DATE value:iadImpressionDate type:TuneAnalyticsVariableDateTimeType];
}
- (NSDate *)iadImpressionDate {
    return [self getProfileValue:TUNE_KEY_IAD_IMPRESSION_DATE];
}

- (void)setIadClickDate:(NSDate *)iadClickDate {
    [self storeProfileKey:TUNE_KEY_IAD_CLICK_DATE value:iadClickDate type:TuneAnalyticsVariableDateTimeType];
}
- (NSDate *)iadClickDate {
    return [self getProfileValue:TUNE_KEY_IAD_CLICK_DATE];
}

- (void)setIadConversionDate:(NSDate *)iadConversionDate {
    [self storeProfileKey:TUNE_KEY_IAD_CONVERSION_DATE value:iadConversionDate type:TuneAnalyticsVariableDateTimeType];
}
- (NSDate *)iadConversionDate {
    return [self getProfileValue:TUNE_KEY_IAD_CONVERSION_DATE];
}

- (void)setAdvertiserSubAd:(NSString *)advertiserSubAd {
    [self storeProfileKey:TUNE_KEY_ADVERTISER_SUB_AD value:advertiserSubAd];
}
- (NSString *)advertiserSubAd {
    return [self getProfileValue:TUNE_KEY_ADVERTISER_SUB_AD];
}

- (void)setAdvertiserSubAdgroup:(NSString *)advertiserSubAdgroup {
    [self storeProfileKey:TUNE_KEY_ADVERTISER_SUB_ADGROUP value:advertiserSubAdgroup];
}
- (NSString *)advertiserSubAdgroup {
    return [self getProfileValue:TUNE_KEY_ADVERTISER_SUB_ADGROUP];
}

- (void)setAdvertiserSubCampaign:(NSString *)advertiserSubCampaign {
    [self storeProfileKey:TUNE_KEY_ADVERTISER_SUB_CAMPAIGN value:advertiserSubCampaign];
}
- (NSString *)advertiserSubCampaign {
    return [self getProfileValue:TUNE_KEY_ADVERTISER_SUB_CAMPAIGN];
}

- (void)setAdvertiserSubKeyword:(NSString *)advertiserSubKeyword {
    [self storeProfileKey:TUNE_KEY_ADVERTISER_SUB_KEYWORD value:advertiserSubKeyword];
}
- (NSString *)advertiserSubKeyword {
    return [self getProfileValue:TUNE_KEY_ADVERTISER_SUB_KEYWORD];
}

- (void)setAdvertiserSubPublisher:(NSString *)advertiserSubPublisher {
    [self storeProfileKey:TUNE_KEY_ADVERTISER_SUB_PUBLISHER value:advertiserSubPublisher];
}
- (NSString *)advertiserSubPublisher {
    return [self getProfileValue:TUNE_KEY_ADVERTISER_SUB_PUBLISHER];
}

- (void)setAdvertiserSubSite:(NSString *)advertiserSubSite {
    [self storeProfileKey:TUNE_KEY_ADVERTISER_SUB_SITE value:advertiserSubSite];
}
- (NSString *)advertiserSubSite {
    return [self getProfileValue:TUNE_KEY_ADVERTISER_SUB_SITE];
}

- (void)setAgencyId:(NSString *)agencyId {
    [self storeProfileKey:TUNE_KEY_AGENCY_ID value:agencyId];
}
- (NSString *)agencyId {
    return [self getProfileValue:TUNE_KEY_AGENCY_ID];
}

- (void)setOfferId:(NSString *)offerId {
    [self storeProfileKey:TUNE_KEY_OFFER_ID value:offerId];
}
- (NSString *)offerId {
    return [self getProfileValue:TUNE_KEY_OFFER_ID];
}

- (void)setPublisherId:(NSString *)publisherId {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_ID value:publisherId];
}
- (NSString *)publisherId {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_ID];
}

- (void)setPublisherReferenceId:(NSString *)publisherReferenceId {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_REF_ID value:publisherReferenceId];
}
- (NSString *)publisherReferenceId {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_REF_ID];
}

- (void)setPublisherSubAd:(NSString *)publisherSubAd {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_AD value:publisherSubAd];
}
- (NSString *)publisherSubAd {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB_AD];
}

- (void)setPublisherSubAdgroup:(NSString *)publisherSubAdgroup {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_ADGROUP value:publisherSubAdgroup];
}
- (NSString *)publisherSubAdgroup {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB_ADGROUP];
}

- (void)setPublisherSubAdName:(NSString *)publisherSubAdName {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_AD_NAME value:publisherSubAdName];
}
- (NSString *)publisherSubAdName {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB_AD_NAME];
}

- (void)setPublisherSubAdRef:(NSString *)publisherSubAdRef {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_AD_REF value:publisherSubAdRef];
}
- (NSString *)publisherSubAdRef {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB_AD_REF];
}

- (void)setPublisherSubCampaign:(NSString *)publisherSubCampaign {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_CAMPAIGN value:publisherSubCampaign];
}
- (NSString *)publisherSubCampaign {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB_CAMPAIGN];
}

- (void)setPublisherSubCampaignName:(NSString *)publisherSubCampaignName {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_CAMPAIGN_NAME value:publisherSubCampaignName];
}
- (NSString *)publisherSubCampaignName {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB_CAMPAIGN_NAME];
}

- (void)setPublisherSubCampaignRef:(NSString *)publisherSubCampaignRef {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_CAMPAIGN_REF value:publisherSubCampaignRef];
}
- (NSString *)publisherSubCampaignRef {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB_CAMPAIGN_REF];
}

- (void)setPublisherSubKeyword:(NSString *)publisherSubKeyword {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_KEYWORD value:publisherSubKeyword];
}
- (NSString *)publisherSubKeyword {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB_KEYWORD];
}

- (void)setPublisherSubKeywordRef:(NSString *)publisherSubKeywordRef {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_KEYWORD_REF value:publisherSubKeywordRef];
}
- (NSString *)publisherSubKeywordRef {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB_KEYWORD_REF];
}

- (void)setPublisherSubPlacementName:(NSString *)publisherSubPlacementName {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_PLACEMENT_NAME value:publisherSubPlacementName];
}
- (NSString *)publisherSubPlacementName {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB_PLACEMENT_NAME];
}

- (void)setPublisherSubPlacementRef:(NSString *)publisherSubPlacementRef {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_PLACEMENT_REF value:publisherSubPlacementRef];
}
- (NSString *)publisherSubPlacementRef {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB_PLACEMENT_REF];
}

- (void)setPublisherSubPublisher:(NSString *)publisherSubPublisher {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_PUBLISHER value:publisherSubPublisher];
}
- (NSString *)publisherSubPublisher {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB_PUBLISHER];
}

- (void)setPublisherSubPublisherRef:(NSString *)publisherSubPublisherRef {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_PUBLISHER_REF value:publisherSubPublisherRef];
}
- (NSString *)publisherSubPublisherRef {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB_PUBLISHER_REF];
}

- (void)setPublisherSubSite:(NSString *)publisherSubSite {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_SITE value:publisherSubSite];
}
- (NSString *)publisherSubSite {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB_SITE];
}

- (void)setPublisherSub1:(NSString *)publisherSub1 {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB1 value:publisherSub1];
}
- (NSString *)publisherSub1 {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB1];
}

- (void)setPublisherSub2:(NSString *)publisherSub2 {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB2 value:publisherSub2];
}
- (NSString *)publisherSub2 {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB2];
}

- (void)setPublisherSub3:(NSString *)publisherSub3 {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB3 value:publisherSub3];
}
- (NSString *)publisherSub3 {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB3];
}

- (void)setPublisherSub4:(NSString *)publisherSub4 {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB4 value:publisherSub4];
}
- (NSString *)publisherSub4 {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB4];
}

- (void)setPublisherSub5:(NSString *)publisherSub5 {
    [self storeProfileKey:TUNE_KEY_PUBLISHER_SUB5 value:publisherSub5];
}
- (NSString *)publisherSub5 {
    return [self getProfileValue:TUNE_KEY_PUBLISHER_SUB5];
}

- (void)setInterfaceIdiom:(NSString *)interfaceIdiom {
    [self storeProfileKey:TUNE_KEY_INTERFACE_IDIOM value:interfaceIdiom];
}
- (NSString *)interfaceIdiom {
    return [self getProfileValue:TUNE_KEY_INTERFACE_IDIOM];
}

- (void)setHardwareType:(NSString *)hardwareType {
    [self storeProfileKey:TUNE_KEY_HARDWARE_TYPE value:hardwareType];
}
- (NSString *)hardwareType {
    return [self getProfileValue:TUNE_KEY_HARDWARE_TYPE];
}

- (void)setMinutesFromGMT:(NSNumber *)minutesFromGMT {
    [self storeProfileKey:TUNE_KEY_MINUTES_FROM_GMT value:minutesFromGMT type:TuneAnalyticsVariableNumberType];
}
- (NSNumber *)minutesFromGMT {
    return [self getProfileValue:TUNE_KEY_MINUTES_FROM_GMT];
}

- (void)setSDKVersion:(NSString *)sdkVersion {
    [self storeProfileKey:TUNE_KEY_SDK_VERSION value:sdkVersion type:TuneAnalyticsVariableVersionType];
}
- (NSString *)sdkVersion {
    return [self getProfileValue:TUNE_KEY_SDK_VERSION];
}

- (void)setUserEmail:(NSString *)email {
    NSString* userEmail = [email copy];
    NSString* userEmailMd5 = [TuneUtils hashMd5:userEmail];
    NSString* userEmailSha1 = [TuneUtils hashSha1:userEmail];
    NSString* userEmailSha256 = [TuneUtils hashSha256:userEmail];
    
    [self storeProfileKey:TUNE_KEY_USER_EMAIL_MD5 value:userEmailMd5 hashType:TuneAnalyticsVariableHashMD5Type];
    [self storeProfileKey:TUNE_KEY_USER_EMAIL_SHA1 value:userEmailSha1 hashType:TuneAnalyticsVariableHashSHA1Type];
    [self storeProfileKey:TUNE_KEY_USER_EMAIL_SHA256 value:userEmailSha256 hashType:TuneAnalyticsVariableHashSHA256Type];
}

- (NSString *)userEmailMd5 {
    return [self getProfileValue:TUNE_KEY_USER_EMAIL_MD5];
}
- (NSString *)userEmailSha1 {
    return [self getProfileValue:TUNE_KEY_USER_EMAIL_SHA1];
}
- (NSString *)userEmailSha256 {
    return [self getProfileValue:TUNE_KEY_USER_EMAIL_SHA256];
}
 
- (void)setUserName:(NSString *)name {
    NSString* userName = [name copy];
    NSString* userNameMd5 = [TuneUtils hashMd5:userName];
    NSString* userNameSha1 = [TuneUtils hashSha1:userName];
    NSString* userNameSha256 = [TuneUtils hashSha256:userName];
    
    [self storeProfileKey:TUNE_KEY_USER_NAME_MD5 value:userNameMd5 hashType:TuneAnalyticsVariableHashMD5Type];
    [self storeProfileKey:TUNE_KEY_USER_NAME_SHA1 value:userNameSha1 hashType:TuneAnalyticsVariableHashSHA1Type];
    [self storeProfileKey:TUNE_KEY_USER_NAME_SHA256 value:userNameSha256 hashType:TuneAnalyticsVariableHashSHA256Type];
}

- (NSString *)userNameMd5 {
    return [self getProfileValue:TUNE_KEY_USER_NAME_MD5];
}
- (NSString *)userNameSha1 {
    return [self getProfileValue:TUNE_KEY_USER_NAME_SHA1];
}
- (NSString *)userNameSha256 {
    return [self getProfileValue:TUNE_KEY_USER_NAME_SHA256];
}
 
- (void)setPhoneNumber:(NSString *)number {
    NSString* rawPhoneNumber = [number copy];
    NSMutableString *cleanPhone = nil;
    
    if(rawPhoneNumber) {
        // character set containing English decimal digits
        NSCharacterSet *charsetEngNum = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        BOOL containsNonEnglishDigits = NO;
        
        // remove non-numeric characters
        NSCharacterSet *charset = [NSCharacterSet decimalDigitCharacterSet];
        cleanPhone = [NSMutableString string];
        for (int i = 0; i < rawPhoneNumber.length; ++i) {
            unichar nextChar = [rawPhoneNumber characterAtIndex:i];
            if([charset characterIsMember:nextChar]) {
                // if this digit character is not an English decimal digit
                if(!containsNonEnglishDigits && ![charsetEngNum characterIsMember:nextChar]) {
                    containsNonEnglishDigits = YES;
                }
                
                // only include decimal digit characters
                [cleanPhone appendString:[NSString stringWithCharacters:&nextChar length:1]];
            }
        }
        
        // if the phone number string includes non-English digits
        if(containsNonEnglishDigits) {
            // convert to English digits
            NSNumberFormatter *Formatter = [[NSNumberFormatter alloc] init];
            NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"EN"];
            [Formatter setLocale:locale];
            NSNumber *newNum = [Formatter numberFromString:cleanPhone];
            if (newNum) {
                cleanPhone = [[newNum stringValue] mutableCopy];
            }
        }
    }
    
    NSString *cleanPhoneMd5 = [TuneUtils hashMd5:cleanPhone];
    NSString *cleanPhoneSha1 = [TuneUtils hashSha1:cleanPhone];
    NSString *cleanPhoneSha256 = [TuneUtils hashSha256:cleanPhone];
    
    [self storeProfileKey:TUNE_KEY_USER_PHONE_MD5 value:cleanPhoneMd5 hashType:TuneAnalyticsVariableHashMD5Type];
    [self storeProfileKey:TUNE_KEY_USER_PHONE_SHA1 value:cleanPhoneSha1 hashType:TuneAnalyticsVariableHashSHA1Type];
    [self storeProfileKey:TUNE_KEY_USER_PHONE_SHA256 value:cleanPhoneSha256 hashType:TuneAnalyticsVariableHashSHA256Type];
}

- (NSString *)phoneNumberMd5 {
    return [self getProfileValue:TUNE_KEY_USER_PHONE_MD5];
}
- (NSString *)phoneNumberSha1 {
    return [self getProfileValue:TUNE_KEY_USER_PHONE_SHA1];
}
- (NSString *)phoneNumberSha256 {
    return [self getProfileValue:TUNE_KEY_USER_PHONE_SHA256];
}

- (void)setLocation:(TuneLocation *)location {
    [self storeProfileKey:TUNE_KEY_LATITUDE value:location.latitude type:TuneAnalyticsVariableNumberType];
    [self storeProfileKey:TUNE_KEY_LONGITUDE value:location.longitude type:TuneAnalyticsVariableNumberType];
    [self storeProfileKey:TUNE_KEY_ALTITUDE value:location.altitude type:TuneAnalyticsVariableNumberType];
    
    [self storeProfileKey:TUNE_KEY_LOCATION_HORIZONTAL_ACCURACY value:location.horizontalAccuracy type:TuneAnalyticsVariableNumberType];
    [self storeProfileKey:TUNE_KEY_LOCATION_VERTICAL_ACCURACY value:location.verticalAccuracy type:TuneAnalyticsVariableNumberType];
    [self storeProfileKey:TUNE_KEY_LOCATION_TIMESTAMP value:location.timestamp type:TuneAnalyticsVariableDateTimeType];
    
    [self storeProfileKey:TUNE_KEY_GEO_COORDINATE value:location type:TuneAnalyticsVariableCoordinateType];
}

- (TuneLocation *)location {
    TuneLocation *location = [[TuneLocation alloc] init];
    
    location.latitude = [self getProfileValue:TUNE_KEY_LATITUDE];
    location.longitude = [self getProfileValue:TUNE_KEY_LONGITUDE];
    location.altitude = [self getProfileValue:TUNE_KEY_ALTITUDE];
    
    return location;
}

- (void)setIsTestFlightBuild:(NSNumber *)isTestFlightBuild {
    [self storeProfileKey:TUNE_KEY_IS_TESTFLIGHT_BUILD value:isTestFlightBuild type:TuneAnalyticsVariableBooleanType];
}
- (NSNumber *)isTestFlightBuild {
    return [self getProfileValue:TUNE_KEY_IS_TESTFLIGHT_BUILD];
}

- (void)setPreloadData:(TunePreloadData *)preloadData {
    if (preloadData && preloadData.publisherId) {
        if (0 != preloadData.publisherId.length) {[self storeProfileKey:TUNE_KEY_PUBLISHER_ID value:preloadData.publisherId];}
        if (0 != preloadData.offerId.length) {[self storeProfileKey:TUNE_KEY_OFFER_ID value:preloadData.offerId];}
        if (0 != preloadData.agencyId.length) {[self storeProfileKey:TUNE_KEY_AGENCY_ID value:preloadData.agencyId];}
        if (0 != preloadData.publisherReferenceId.length) {[self storeProfileKey:TUNE_KEY_PUBLISHER_REF_ID value:preloadData.publisherReferenceId];}
        if (0 != preloadData.publisherSub1.length) {[self storeProfileKey:TUNE_KEY_PUBLISHER_SUB1 value:preloadData.publisherSub1];}
        if (0 != preloadData.publisherSub2.length) {[self storeProfileKey:TUNE_KEY_PUBLISHER_SUB2 value:preloadData.publisherSub2];}
        if (0 != preloadData.publisherSub3.length) {[self storeProfileKey:TUNE_KEY_PUBLISHER_SUB3 value:preloadData.publisherSub3];}
        if (0 != preloadData.publisherSub4.length) {[self storeProfileKey:TUNE_KEY_PUBLISHER_SUB4 value:preloadData.publisherSub4];}
        if (0 != preloadData.publisherSub5.length) {[self storeProfileKey:TUNE_KEY_PUBLISHER_SUB5 value:preloadData.publisherSub5];}
        if (0 != preloadData.publisherSubAd.length) {[self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_AD value:preloadData.publisherSubAd];}
        if (0 != preloadData.publisherSubAd.length) {[self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_AD value:preloadData.publisherSubAd];}
        if (0 != preloadData.publisherSubAdgroup.length) {[self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_ADGROUP value:preloadData.publisherSubAdgroup];}
        if (0 != preloadData.publisherSubCampaign.length) {[self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_CAMPAIGN value:preloadData.publisherSubCampaign];}
        if (0 != preloadData.publisherSubKeyword.length) {[self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_KEYWORD value:preloadData.publisherSubKeyword];}
        if (0 != preloadData.publisherSubPublisher.length) {[self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_PUBLISHER value:preloadData.publisherSubPublisher];}
        if (0 != preloadData.publisherSubSite.length) {[self storeProfileKey:TUNE_KEY_PUBLISHER_SUB_SITE value:preloadData.publisherSubSite];}
        if (0 != preloadData.advertiserSubAdgroup.length) {[self storeProfileKey:TUNE_KEY_ADVERTISER_SUB_ADGROUP value:preloadData.advertiserSubAdgroup];}
        if (0 != preloadData.advertiserSubCampaign.length) {[self storeProfileKey:TUNE_KEY_ADVERTISER_SUB_CAMPAIGN value:preloadData.advertiserSubCampaign];}
        if (0 != preloadData.advertiserSubKeyword.length) {[self storeProfileKey:TUNE_KEY_ADVERTISER_SUB_KEYWORD value:preloadData.advertiserSubKeyword];}
        if (0 != preloadData.advertiserSubPublisher.length) {[self storeProfileKey:TUNE_KEY_ADVERTISER_SUB_PUBLISHER value:preloadData.advertiserSubPublisher];}
        if (0 != preloadData.advertiserSubSite.length) {[self storeProfileKey:TUNE_KEY_ADVERTISER_SUB_SITE value:preloadData.advertiserSubSite];}
        if (0 != preloadData.advertiserSubAd.length) {[self storeProfileKey:TUNE_KEY_ADVERTISER_SUB_AD value:preloadData.advertiserSubAd];}
    }
}

#pragma mark - Persistence

- (void)loadSavedProfile {
    // We don't load custom variables because they are loaded on app foreground
    
    for (NSString *profileKey in [TuneUserProfile profileVariablesToSave]) {
        NSString *value = [TuneUserDefaultsUtils userDefaultValueforKey:profileKey];
        if (value) {
            TuneAnalyticsVariableDataType type = [TuneAnalyticsVariable stringToDataType:[[TuneUserProfile profileVariablesToSave] objectForKey:profileKey][0]];
            TuneAnalyticsVariableHashType hashType = [TuneAnalyticsVariable stringToHashType:[[TuneUserProfile profileVariablesToSave] objectForKey:profileKey][1]];
            
            [self storeProfileKey:profileKey value:value type:type hashType:hashType shouldAutoHash:NO];
        }
    }
    
    if ([self getProfileValue:TUNE_KEY_INSTALL_LOG_ID] != nil) {
        [self clearVariable:TUNE_KEY_UPDATE_LOG_ID];
    }
}

#pragma mark - Marshaling profile into other formats.

// Determine if PII should be redacted for a profile variable key
// Also used by TuneTracker.m
- (BOOL)shouldRedactKey:(NSString *)key {
    if ([[TuneManager currentManager].userProfile tooYoungForTargetedAds]) {
        
        // only redact system variables that are not on the whitelist, custom variables are the responsibility of the client app
        if ([[TuneUserProfileKeys systemVariables] containsObject:key] && ![[TuneUserProfileKeys privacyProtectionWhiteList] containsObject:key]) {
            return YES;
        }
    }
    
    return NO;
}

- (NSArray *)toArrayOfDictionaries {
    NSMutableArray *result = [[NSMutableArray alloc] init];
    NSDictionary *variables = [self getProfileVariables];
    
    @synchronized(self) {
        for (NSString *key in variables) {
            TuneAnalyticsVariable *var = [variables objectForKey:key];
            if (![[TuneUserProfile profileVariablesToNotSendToMA] containsObject:key] && ([var value] != nil || [[self getCustomProfileVariables] containsObject:key])) {
                
                // If this is a variable we should only send once and this is not the first session, skip it
                if ([[TuneUserProfile profileVariablesToOnlySendOnFirstSession] containsObject:key] && ![[self isFirstSession] boolValue]) {
                    continue;
                }
            
                if (![self shouldRedactKey:key]) {
                    [result addObjectsFromArray:[var toArrayOfDicts]];
                }
            }
        }

        [result addObjectsFromArray:self.currentVariations.allObjects];
    }
    
    return result;
}

/*
 *  Returns the current set of profile variables as a flat set of key-value pairs for REST requests.
 */
- (NSDictionary *)toQueryDictionary {
    // TODO: Should we hash the variables here as well?
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    NSDictionary *variables = [self getProfileVariables];
    
    for (NSString *key in variables) {
        TuneAnalyticsVariable *var = [variables objectForKey:key];
        
        //Calling toDictionary forces all the values to be converted into strings
        NSDictionary *stringedVar = [var toDictionary];
        
        [result setObject:(NSString *)[stringedVar objectForKey:@"value"] forKey:(NSString *)[stringedVar objectForKey:@"name"]];
    }
    
    return result;
}

@end
