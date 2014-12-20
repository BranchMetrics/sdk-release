//
//  MATSettings.m
//  MobileAppTracker
//
//  Created by John Bender on 1/10/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <sys/utsname.h>
#import <sys/sysctl.h>
//#import <sys/types.h>
#import <mach/machine.h>
#import <Foundation/Foundation.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UIKit/UIKit.h>

#import "MATSettings.h"
#import "MATUtils.h"
#import "NSString+MATURLEncoding.m"
#import "MATInstallReceipt.h"
#import "MATUserAgentCollector.h"


@interface MATSettings () <MATUserAgentDelegate>
{
    MATUserAgentCollector *uaCollector;
    
    NSSet *doNotEncryptSet;
}
@end

static NSSet * ignoreParams;
static CTTelephonyNetworkInfo *netInfo;

@implementation MATSettings

#pragma mark - initialize

+ (void)initialize {
    ignoreParams = [NSSet setWithObjects:MAT_KEY_REDIRECT_URL, MAT_KEY_KEY, nil];
    
    netInfo = [CTTelephonyNetworkInfo new];
}

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if( self ) {
        // initiate collection of user agent string
        uaCollector = [[MATUserAgentCollector alloc] initWithDelegate:self];

        // MAT ID
         if([MATUtils userDefaultValueforKey:MAT_KEY_MAT_ID])
         {
             self.matId = [MATUtils userDefaultValueforKey:MAT_KEY_MAT_ID];
         }
         else
         {
             NSString *uuid = [MATUtils getUUID];
             [MATUtils setUserDefaultValue:uuid forKey:MAT_KEY_MAT_ID];
             self.matId = uuid;
         }
        
        // install receipt
        NSData *receiptData = [MATInstallReceipt installReceipt];
        self.installReceipt = [MATUtils MATbase64EncodedStringFromData:receiptData];

        // load saved values
        self.installLogId = [MATUtils userDefaultValueforKey:MAT_KEY_MAT_INSTALL_LOG_ID];
        if( !self.installLogId )
            self.updateLogId = [MATUtils userDefaultValueforKey:MAT_KEY_MAT_UPDATE_LOG_ID];
        self.openLogId = [MATUtils userDefaultValueforKey:MAT_KEY_OPEN_LOG_ID];
        self.lastOpenLogId = [MATUtils userDefaultValueforKey:MAT_KEY_LAST_OPEN_LOG_ID];
        
        self.iadAttribution = [MATUtils userDefaultValueforKey:MAT_KEY_IAD_ATTRIBUTION];
        
        self.userEmail = [MATUtils userDefaultValueforKey:MAT_KEY_USER_EMAIL];
        self.userId = [MATUtils userDefaultValueforKey:MAT_KEY_USER_ID];
        self.userName = [MATUtils userDefaultValueforKey:MAT_KEY_USER_NAME];
        
        // hardware specs
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *machineName = [NSString stringWithCString:systemInfo.machine
                                                   encoding:NSUTF8StringEncoding];
        self.deviceModel = machineName;
        size_t size;
        cpu_type_t type;
        cpu_subtype_t subtype;
        size = sizeof(type);
        sysctlbyname("hw.cputype", &type, &size, NULL, 0);
        self.deviceCpuType = @(type);
        size = sizeof(subtype);
        sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0);
        self.deviceCpuSubtype = @(subtype);
        
        // Device params
        self.deviceBrand = @"Apple";
        
        CGSize screenSize = CGSizeZero;
        
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
        
        self.screenSize = [NSString stringWithFormat:@"%.fx%.f", screenSize.width, screenSize.height];
        self.screenDensity = @([[UIScreen mainScreen] scale]);
        
        CTCarrier *carrier = [netInfo subscriberCellularProvider];
        self.deviceCarrier = [carrier carrierName];
        self.mobileCountryCode = [carrier mobileCountryCode];
        self.mobileCountryCodeISO = [carrier isoCountryCode];
        self.mobileNetworkCode = [carrier mobileNetworkCode];
        
        // App params
        NSBundle *mainBundle = [NSBundle mainBundle];
        //self.packageName = [mainBundle objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleIdentifierKey];
        self.packageName = [MATUtils bundleId]; // should be same as above
        self.appName = [mainBundle objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleNameKey];
        self.appVersion = [mainBundle objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleVersionKey];

        if( self.packageName == nil && [UIApplication sharedApplication] == nil ) {
            // should only happen during unit tests
            self.packageName = @"com.mobileapptracking.iosunittest";
        }
        
        //Other params
        self.countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        self.osVersion = [[UIDevice currentDevice] systemVersion];
        self.language = [[NSLocale preferredLanguages] objectAtIndex:0];
        
        self.installDate = [MATUtils installDate];
        
        // FB cookie id
        [self loadFacebookCookieId];
        
        // default to USD for currency code
        self.defaultCurrencyCode = MAT_KEY_CURRENCY_USD;
        
        self.payingUser = [MATUtils userDefaultValueforKey:MAT_KEY_IS_PAYING_USER];

        doNotEncryptSet = [NSSet setWithObjects:MAT_KEY_ADVERTISER_ID, MAT_KEY_SITE_ID, MAT_KEY_ACTION,
                           MAT_KEY_SITE_EVENT_ID, MAT_KEY_SDK, MAT_KEY_VER, MAT_KEY_SITE_EVENT_NAME,
                           MAT_KEY_REFERRAL_URL, MAT_KEY_REFERRAL_SOURCE, MAT_KEY_TRACKING_ID, MAT_KEY_PACKAGE_NAME,
                           MAT_KEY_TRANSACTION_ID, MAT_KEY_RESPONSE_FORMAT, nil];
    }
    return self;
}

- (void)loadFacebookCookieId
{
    self.facebookCookieId = [MATUtils generateFBCookieIdString];
}

- (void)userAgentString:(NSString*)userAgent
{
    self.userAgent = userAgent;
    uaCollector = nil; // free memory
}

#pragma mark - Overridden setters

- (void)setUserEmail:(NSString *)userEmail
{
    _userEmail = [userEmail copy];
    [MATUtils setUserDefaultValue:_userEmail forKey:MAT_KEY_USER_EMAIL];
}

- (void)setUserId:(NSString *)userId
{
    _userId = [userId copy];
    [MATUtils setUserDefaultValue:_userId forKey:MAT_KEY_USER_ID];
}

- (void)setUserName:(NSString *)userName
{
    _userName = [userName copy];
    [MATUtils setUserDefaultValue:_userName forKey:MAT_KEY_USER_NAME];
}


#pragma mark - Action requests

- (NSString*)domainName
{
    if(self.staging)
        return MAT_SERVER_DOMAIN_REGULAR_TRACKING_STAGE;
    else
        // on prod, use a different server domain name when debug mode is enabled
        return [self.debugMode boolValue] ? MAT_SERVER_DOMAIN_REGULAR_TRACKING_PROD_DEBUG : MAT_SERVER_DOMAIN_REGULAR_TRACKING_PROD;
}


- (void)resetBeforeTrackAction
{
    self.actionName = nil;
}


- (void)urlStringForTrackingLink:(NSString**)trackingLink
                   encryptParams:(NSString**)encryptParams
                            isId:(BOOL)isId
{
    return [self urlStringForReferenceId:nil
                            trackingLink:trackingLink
                           encryptParams:encryptParams
                                    isId:isId];
}

- (void)urlStringForReferenceId:(NSString*)referenceId
                   trackingLink:(NSString**)trackingLink
                  encryptParams:(NSString**)encryptParams
                           isId:(BOOL)isId
{
    // determine correct event name and action name
    NSString *eventNameOrId = nil;
    
    if( isId ) {
        eventNameOrId = [self.actionName copy];
        self.actionName = MAT_EVENT_CONVERSION;
    }
    else if( self.postConversion && [self.actionName isEqualToString:MAT_EVENT_INSTALL] ) {
        // don't modify action name
    }
    else if( [self.actionName isEqualToString:MAT_EVENT_GEOFENCE] ) {
        // don't modify action name
    }
    else if( [[self.actionName lowercaseString] isEqualToString:MAT_EVENT_INSTALL] ||
             [[self.actionName lowercaseString] isEqualToString:MAT_EVENT_UPDATE] ||
             [[self.actionName lowercaseString] isEqualToString:MAT_EVENT_OPEN] ||
             [[self.actionName lowercaseString] isEqualToString:MAT_EVENT_SESSION] ) {
        self.actionName = MAT_EVENT_SESSION;
    }
    else {
        // it's a conversion
        eventNameOrId = [self.actionName copy];
        self.actionName = MAT_EVENT_CONVERSION;
    }

    // part of the url that does not need encryption
    NSMutableString* nonEncryptedParams = [NSMutableString stringWithCapacity:256];
    
    // part of the url that needs encryption
    NSMutableString* encryptedParams = [NSMutableString stringWithCapacity:512];
    
    if( self.staging && ![ignoreParams containsObject:MAT_KEY_STAGING] )
        [nonEncryptedParams appendFormat:@"%@=1", MAT_KEY_STAGING];
    
    if( self.postConversion && ![ignoreParams containsObject:MAT_KEY_POST_CONVERSION] )
        [nonEncryptedParams appendFormat:@"&%@=1", MAT_KEY_POST_CONVERSION];

     NSString *keySiteEvent = isId ? MAT_KEY_SITE_EVENT_ID : MAT_KEY_SITE_EVENT_NAME;
    
    // convert properties to keys, format, and append to URL
    [self addValue:self.actionName                  forKey:MAT_KEY_ACTION                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.advertiserId                forKey:MAT_KEY_ADVERTISER_ID            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.age                         forKey:MAT_KEY_AGE                      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.altitude                    forKey:MAT_KEY_ALTITUDE                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.appAdTracking               forKey:MAT_KEY_APP_AD_TRACKING          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.appName                     forKey:MAT_KEY_APP_NAME                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.appVersion                  forKey:MAT_KEY_APP_VERSION              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.mobileCountryCode           forKey:MAT_KEY_CARRIER_COUNTRY_CODE     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.mobileCountryCodeISO        forKey:MAT_KEY_CARRIER_COUNTRY_CODE_ISO encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.mobileNetworkCode           forKey:MAT_KEY_CARRIER_NETWORK_CODE     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userAgent                   forKey:MAT_KEY_CONVERSION_USER_AGENT    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.countryCode                 forKey:MAT_KEY_COUNTRY_CODE             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.currencyCode                forKey:MAT_KEY_CURRENCY_CODE            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    if( [self.debugMode boolValue] )
        [self addValue:@(TRUE)                      forKey:MAT_KEY_DEBUG                    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    [self addValue:self.deviceBrand                 forKey:MAT_KEY_DEVICE_BRAND             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.deviceCarrier               forKey:MAT_KEY_DEVICE_CARRIER           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.deviceCpuSubtype            forKey:MAT_KEY_DEVICE_CPUSUBTYPE        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.deviceCpuType               forKey:MAT_KEY_DEVICE_CPUTYPE           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.deviceModel                 forKey:MAT_KEY_DEVICE_MODEL             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventAttribute1             forKey:MAT_KEY_EVENT_ATTRIBUTE_SUB1     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventAttribute2             forKey:MAT_KEY_EVENT_ATTRIBUTE_SUB2     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventAttribute3             forKey:MAT_KEY_EVENT_ATTRIBUTE_SUB3     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventAttribute4             forKey:MAT_KEY_EVENT_ATTRIBUTE_SUB4     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventAttribute5             forKey:MAT_KEY_EVENT_ATTRIBUTE_SUB5     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventContentId              forKey:MAT_KEY_EVENT_CONTENT_ID         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventContentType            forKey:MAT_KEY_EVENT_CONTENT_TYPE       encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventDate1                  forKey:MAT_KEY_EVENT_DATE1              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventDate2                  forKey:MAT_KEY_EVENT_DATE2              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventLevel                  forKey:MAT_KEY_EVENT_LEVEL              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventQuantity               forKey:MAT_KEY_EVENT_QUANTITY           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventRating                 forKey:MAT_KEY_EVENT_RATING             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventSearchString           forKey:MAT_KEY_EVENT_SEARCH_STRING      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.existingUser                forKey:MAT_KEY_EXISTING_USER            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.facebookUserId              forKey:MAT_KEY_FACEBOOK_USER_ID         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.facebookCookieId            forKey:MAT_KEY_FB_COOKIE_ID             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.gender                      forKey:MAT_KEY_GENDER                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.regionName                  forKey:MAT_KEY_GEOFENCE_NAME            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.googleUserId                forKey:MAT_KEY_GOOGLE_USER_ID           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.iadAttribution              forKey:MAT_KEY_IAD_ATTRIBUTION          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.iadImpressionDate           forKey:MAT_KEY_IAD_IMPRESSION_DATE      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.installDate                 forKey:MAT_KEY_INSDATE                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.installLogId                forKey:MAT_KEY_INSTALL_LOG_ID           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.ifaTracking                 forKey:MAT_KEY_IOS_AD_TRACKING          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.ifa                         forKey:MAT_KEY_IOS_IFA                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.ifv                         forKey:MAT_KEY_IOS_IFV                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.transactionState            forKey:MAT_KEY_IOS_PURCHASE_STATUS      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.payingUser                  forKey:MAT_KEY_IS_PAYING_USER           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.conversionKey               forKey:MAT_KEY_KEY                      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.language                    forKey:MAT_KEY_LANGUAGE                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.lastOpenLogId               forKey:MAT_KEY_LAST_OPEN_LOG_ID         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.latitude                    forKey:MAT_KEY_LATITUDE                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.locationAuthorizationStatus forKey:MAT_KEY_LOCATION_AUTH_STATUS     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.longitude                   forKey:MAT_KEY_LONGITUDE                encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.matId                       forKey:MAT_KEY_MAT_ID                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.openLogId                   forKey:MAT_KEY_OPEN_LOG_ID              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.jailbroken                  forKey:MAT_KEY_OS_JAILBROKE             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.osVersion                   forKey:MAT_KEY_OS_VERSION               encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.packageName                 forKey:MAT_KEY_PACKAGE_NAME             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.redirectUrl                 forKey:MAT_KEY_REDIRECT_URL             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:referenceId                      forKey:MAT_KEY_REF_ID                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.referralSource              forKey:MAT_KEY_REFERRAL_SOURCE          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.referralUrl                 forKey:MAT_KEY_REFERRAL_URL             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:MAT_KEY_JSON                     forKey:MAT_KEY_RESPONSE_FORMAT          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.revenue                     forKey:MAT_KEY_REVENUE                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.screenDensity               forKey:MAT_KEY_SCREEN_DENSITY           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.screenSize                  forKey:MAT_KEY_SCREEN_SIZE              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:MAT_KEY_IOS                      forKey:MAT_KEY_SDK                      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.pluginName                  forKey:MAT_KEY_SDK_PLUGIN               encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.sessionDate                 forKey:MAT_KEY_SESSION_DATETIME         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:eventNameOrId                    forKey:keySiteEvent                     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.siteId                      forKey:MAT_KEY_SITE_ID                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    if( [self.allowDuplicates boolValue] )
        [self addValue:@(TRUE)                      forKey:MAT_KEY_SKIP_DUP                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    [self addValue:self.systemDate                  forKey:MAT_KEY_SYSTEM_DATE              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.trackingId                  forKey:MAT_KEY_TRACKING_ID              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[NSUUID UUID] UUIDString]       forKey:MAT_KEY_TRANSACTION_ID           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.trusteTPID                  forKey:MAT_KEY_TRUSTE_TPID              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.twitterUserId               forKey:MAT_KEY_TWITTER_USER_ID          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.updateLogId                 forKey:MAT_KEY_UPDATE_LOG_ID            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userEmail                   forKey:MAT_KEY_USER_EMAIL               encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userId                      forKey:MAT_KEY_USER_ID                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userName                    forKey:MAT_KEY_USER_NAME                encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:MATVERSION                       forKey:MAT_KEY_VER                      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    // Note: it's possible for a cworks key to duplicate a built-in key (say, "sdk").
    // If that happened, the constructed URL would have two of the same parameter (e.g.,
    // "...sdk=ios&sdk=cworksvalue..."), though one might be encrypted and one not.
    for( NSString *key in [self.cworksClick allKeys] )
        [self addValue:self.cworksClick[key]        forKey:key                              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    for( NSString *key in [self.cworksImpression allKeys] )
        [self addValue:self.cworksImpression[key]   forKey:key                              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
#if DEBUG
    [self addValue:@(TRUE)                          forKey:MAT_KEY_BYPASS_THROTTLING        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#endif
    
    DLLog(@"MAT urlStringForServerUrl: data to be encrypted: %@", encryptedParams);
    
    if( [_delegate respondsToSelector:@selector(_matURLTestingCallbackWithParamsToBeEncrypted:withPlaintextParams:)] )
        [_delegate _matURLTestingCallbackWithParamsToBeEncrypted:encryptedParams withPlaintextParams:nonEncryptedParams];
    
    *trackingLink = [NSString stringWithFormat:@"https://%@.%@/%@?%@",
                     self.advertiserId,
                     [self domainName],
                     MAT_SERVER_PATH_TRACKING_ENGINE,
                     nonEncryptedParams];
    *encryptParams = encryptedParams;
}

- (void)addValue:(id)value
          forKey:(NSString*)key
 encryptedParams:(NSMutableString*)encryptedParams
 plaintextParams:(NSMutableString*)plaintextParams
{
    if( value == nil ) return;
    if( [ignoreParams containsObject:key] ) return;
    
    NSString *useString = nil;
    if( [value isKindOfClass:[NSNumber class]] )
        useString = [(NSNumber*)value stringValue];
    else if( [value isKindOfClass:[NSDate class]] )
        useString = [NSString stringWithFormat:@"%ld", (long)round( [value timeIntervalSince1970] )];
    else if( [value isKindOfClass:[NSString class]] )
        useString = [(NSString*)value urlEncodeUsingEncoding:NSUTF8StringEncoding];
    else
        return;

    if( [key isEqualToString:MAT_KEY_PACKAGE_NAME] || [key isEqualToString:MAT_KEY_DEBUG] )
    {
        [plaintextParams appendFormat:@"&%@=%@", key, useString];
        [encryptedParams appendFormat:@"&%@=%@", key, useString];
    }
    else if( [doNotEncryptSet containsObject:key] )
    {
        [plaintextParams appendFormat:@"&%@=%@", key, useString];
    }
    else
    {
        [encryptedParams appendFormat:@"&%@=%@", key, useString];
    }
}

- (void)resetAfterRequest
{
    self.currencyCode = self.defaultCurrencyCode;
    
    self.eventContentType = nil;
    self.eventContentId = nil;
    self.eventLevel = nil;
    self.eventQuantity = nil;
    self.eventSearchString = nil;
    self.eventRating = nil;
    self.eventDate1 = nil;
    self.eventDate2 = nil;
    
    self.eventAttribute1 = nil;
    self.eventAttribute2 = nil;
    self.eventAttribute3 = nil;
    self.eventAttribute4 = nil;
    self.eventAttribute5 = nil;
    
    self.postConversion = NO;
    
    self.revenue = nil;
    self.transactionState = nil;
    self.cworksClick = nil;
    self.cworksImpression = nil;
    
    self.regionName = nil;
}

@end
