//
//  TuneSettings.m
//  Tune
//
//  Created by John Bender on 1/10/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <mach/machine.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "../Tune.h"
#import "../TunePreloadData.h"

#import "TuneEvent_internal.h"
#import "TuneInstallReceipt.h"
#import "TuneKeyStrings.h"
#import "TuneLocation_internal.h"
#import "TuneSettings.h"
#import "TuneUserAgentCollector.h"
#import "TuneUtils.h"

#if TARGET_OS_IOS
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif

#if TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#endif

@interface TuneSettings ()
{
    NSSet *doNotEncryptSet;
}
@end

static NSSet * ignoreParams;

#if TARGET_OS_IOS
static CTTelephonyNetworkInfo *netInfo;
#endif

@implementation TuneSettings

#pragma mark - initialize

+ (void)initialize {
    ignoreParams = [NSSet setWithObjects:TUNE_KEY_REDIRECT_URL, TUNE_KEY_KEY, nil];
    
#if TARGET_OS_IOS
    netInfo = [CTTelephonyNetworkInfo new];
#endif
}

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if( self ) {
        // Tune ID
        if([TuneUtils userDefaultValueforKey:TUNE_KEY_MAT_ID])
        {
            self.matId = [TuneUtils userDefaultValueforKey:TUNE_KEY_MAT_ID];
        }
        else
        {
            NSString *uuid = [TuneUtils getUUID];
            [TuneUtils setUserDefaultValue:uuid forKey:TUNE_KEY_MAT_ID];
            self.matId = uuid;
        }
        
        // install receipt
        NSData *receiptData = [TuneInstallReceipt installReceipt];
        self.installReceipt = [TuneUtils tuneBase64EncodedStringFromData:receiptData];
        
        // load saved values
        self.installLogId = [TuneUtils userDefaultValueforKey:TUNE_KEY_MAT_INSTALL_LOG_ID];
        if( !self.installLogId )
            self.updateLogId = [TuneUtils userDefaultValueforKey:TUNE_KEY_MAT_UPDATE_LOG_ID];
        self.openLogId = [TuneUtils userDefaultValueforKey:TUNE_KEY_OPEN_LOG_ID];
        self.lastOpenLogId = [TuneUtils userDefaultValueforKey:TUNE_KEY_LAST_OPEN_LOG_ID];
        
        self.iadAttribution = [TuneUtils userDefaultValueforKey:TUNE_KEY_IAD_ATTRIBUTION];
        
        self.userEmailMd5 = [TuneUtils userDefaultValueforKey:TUNE_KEY_USER_EMAIL_MD5];
        self.userEmailSha1 = [TuneUtils userDefaultValueforKey:TUNE_KEY_USER_EMAIL_SHA1];
        self.userEmailSha256 = [TuneUtils userDefaultValueforKey:TUNE_KEY_USER_EMAIL_SHA256];
        self.userId = [TuneUtils userDefaultValueforKey:TUNE_KEY_USER_ID];
        self.userNameMd5 = [TuneUtils userDefaultValueforKey:TUNE_KEY_USER_NAME_MD5];
        self.userNameSha1 = [TuneUtils userDefaultValueforKey:TUNE_KEY_USER_NAME_SHA1];
        self.userNameSha256 = [TuneUtils userDefaultValueforKey:TUNE_KEY_USER_NAME_SHA256];
        self.phoneNumberMd5 = [TuneUtils userDefaultValueforKey:TUNE_KEY_USER_PHONE_MD5];
        self.phoneNumberSha1 = [TuneUtils userDefaultValueforKey:TUNE_KEY_USER_PHONE_SHA1];
        self.phoneNumberSha256 = [TuneUtils userDefaultValueforKey:TUNE_KEY_USER_PHONE_SHA256];
        
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

#if !TARGET_OS_WATCH
        CGSize screenSize = [TuneUtils screenSize];
        self.screenWidth = @(screenSize.width);
        self.screenHeight = @(screenSize.height);
        
        self.screenSize = [NSString stringWithFormat:@"%.fx%.f", screenSize.width, screenSize.height];
        self.screenDensity = @([[UIScreen mainScreen] scale]);
#endif
        
#if TARGET_OS_IOS
        CTCarrier *carrier = [netInfo subscriberCellularProvider];
        self.deviceCarrier = [carrier carrierName];
        self.mobileCountryCode = [carrier mobileCountryCode];
        self.mobileCountryCodeISO = [carrier isoCountryCode];
        self.mobileNetworkCode = [carrier mobileNetworkCode];
#endif
        
        // App params
        NSBundle *mainBundle = [NSBundle mainBundle];
        //self.packageName = [mainBundle objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleIdentifierKey];
        self.packageName = [TuneUtils bundleId]; // should be same as above
        self.appName = [mainBundle objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleNameKey];
        self.appVersion = [mainBundle objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleVersionKey];
#if !TARGET_OS_WATCH
        if( self.packageName == nil && [UIApplication sharedApplication] == nil ) {
            // should only happen during unit tests
            self.packageName = @"com.mobileapptracking.iosunittest";
        }
#endif
        
        // Other params
        self.countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        
#if TARGET_OS_WATCH
        self.osVersion = [[WKInterfaceDevice currentDevice] systemVersion];
#else
        self.osVersion = [[UIDevice currentDevice] systemVersion];
#endif
        self.language = [[NSLocale preferredLanguages] objectAtIndex:0];
        
        self.installDate = [TuneUtils installDate];

#if TARGET_OS_IOS
        // FB cookie id
        [self loadFacebookCookieId];
#endif
        
        // default to USD for currency code
        self.currencyCode = TUNE_KEY_CURRENCY_USD;
        
        self.payingUser = [TuneUtils userDefaultValueforKey:TUNE_KEY_IS_PAYING_USER];

        doNotEncryptSet = [NSSet setWithObjects:TUNE_KEY_ADVERTISER_ID, TUNE_KEY_SITE_ID, TUNE_KEY_ACTION,
                           TUNE_KEY_SITE_EVENT_ID, TUNE_KEY_SDK, TUNE_KEY_VER, TUNE_KEY_SITE_EVENT_NAME,
                           TUNE_KEY_REFERRAL_URL, TUNE_KEY_REFERRAL_SOURCE, TUNE_KEY_TRACKING_ID, TUNE_KEY_PACKAGE_NAME,
                           TUNE_KEY_TRANSACTION_ID, TUNE_KEY_RESPONSE_FORMAT, nil];
    }
    return self;
}

#if TARGET_OS_IOS
- (void)loadFacebookCookieId
{
    self.facebookCookieId = [TuneUtils generateFBCookieIdString];
}
#endif

#pragma mark - Overridden setters

- (void)setUserEmail:(NSString *)userEmail
{
    _userEmail = [userEmail copy];
    _userEmailMd5 = [TuneUtils hashMd5:userEmail];
    _userEmailSha1 = [TuneUtils hashSha1:userEmail];
    _userEmailSha256 = [TuneUtils hashSha256:userEmail];
    
    [TuneUtils setUserDefaultValue:_userEmailMd5 forKey:TUNE_KEY_USER_EMAIL_MD5];
    [TuneUtils setUserDefaultValue:_userEmailSha1 forKey:TUNE_KEY_USER_EMAIL_SHA1];
    [TuneUtils setUserDefaultValue:_userEmailSha256 forKey:TUNE_KEY_USER_EMAIL_SHA256];
}

- (void)setUserId:(NSString *)userId
{
    _userId = [userId copy];
    [TuneUtils setUserDefaultValue:_userId forKey:TUNE_KEY_USER_ID];
}

- (void)setUserName:(NSString *)userName
{
    _userName = [userName copy];
    _userNameMd5 = [TuneUtils hashMd5:userName];
    _userNameSha1 = [TuneUtils hashSha1:userName];
    _userNameSha256 = [TuneUtils hashSha256:userName];
    
    [TuneUtils setUserDefaultValue:_userNameMd5 forKey:TUNE_KEY_USER_NAME_MD5];
    [TuneUtils setUserDefaultValue:_userNameSha1 forKey:TUNE_KEY_USER_NAME_SHA1];
    [TuneUtils setUserDefaultValue:_userNameSha256 forKey:TUNE_KEY_USER_NAME_SHA256];
}

- (void)setPhoneNumber:(NSString *)userPhone
{
    if(userPhone)
    {
        // character set containing English decimal digits
        NSCharacterSet *charsetEngNum = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
        BOOL containsNonEnglishDigits = NO;
        
        // remove non-numeric characters
        NSCharacterSet *charset = [NSCharacterSet decimalDigitCharacterSet];
        NSMutableString *cleanPhone = [NSMutableString string];
        for (int i = 0; i < userPhone.length; ++i)
        {
            unichar nextChar = [userPhone characterAtIndex:i];
            if([charset characterIsMember:nextChar])
            {
                // if this digit character is not an English decimal digit
                if(!containsNonEnglishDigits && ![charsetEngNum characterIsMember:nextChar])
                {
                    containsNonEnglishDigits = YES;
                }
                
                // only include decimal digit characters
                [cleanPhone appendString:[NSString stringWithCharacters:&nextChar length:1]];
            }
        }
        _phoneNumber = [cleanPhone copy];
        
        // if the phone number string includes non-English digits
        if(containsNonEnglishDigits)
        {
            // convert to English digits
            NSNumberFormatter *Formatter = [[NSNumberFormatter alloc] init];
            NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"EN"];
            [Formatter setLocale:locale];
            NSNumber *newNum = [Formatter numberFromString:_phoneNumber];
            if (newNum) {
                _phoneNumber = [newNum stringValue];
            }
        }
    }
    else
    {
        _phoneNumber = nil;
    }
    
    _phoneNumberMd5 = [TuneUtils hashMd5:_phoneNumber];
    _phoneNumberSha1 = [TuneUtils hashSha1:_phoneNumber];
    _phoneNumberSha256 = [TuneUtils hashSha256:_phoneNumber];
    
    [TuneUtils setUserDefaultValue:_phoneNumberMd5 forKey:TUNE_KEY_USER_PHONE_MD5];
    [TuneUtils setUserDefaultValue:_phoneNumberSha1 forKey:TUNE_KEY_USER_PHONE_SHA1];
    [TuneUtils setUserDefaultValue:_phoneNumberSha256 forKey:TUNE_KEY_USER_PHONE_SHA256];
}


#pragma mark - Action requests

- (NSString*)domainName
{
    if(self.staging)
        return TUNE_SERVER_DOMAIN_REGULAR_TRACKING_STAGE;
    else
        // on prod, use a different server domain name when debug mode is enabled
        return [self.debugMode boolValue] ? TUNE_SERVER_DOMAIN_REGULAR_TRACKING_PROD_DEBUG : TUNE_SERVER_DOMAIN_REGULAR_TRACKING_PROD;
}

- (void)urlStringForEvent:(TuneEvent *)event
             trackingLink:(NSString**)trackingLink
            encryptParams:(NSString**)encryptParams
{
    NSString *eventNameOrId = nil;
    
    // do not include the eventName param in the request url for actions -- install, session, geofence
    
    BOOL isActionInstall = [event.actionName isEqualToString:TUNE_EVENT_INSTALL];
    BOOL isActionSession = [event.actionName isEqualToString:TUNE_EVENT_SESSION];
    BOOL isActionGeofence = [event.actionName isEqualToString:TUNE_EVENT_GEOFENCE];
    
    if (!isActionInstall && !isActionSession && !isActionGeofence) {
        eventNameOrId = event.eventName ? event.eventName : [@(event.eventId) stringValue];
    }
    
    // part of the url that does not need encryption
    NSMutableString* nonEncryptedParams = [NSMutableString stringWithCapacity:256];
    
    // part of the url that needs encryption
    NSMutableString* encryptedParams = [NSMutableString stringWithCapacity:512];
    
    if( self.staging && ![ignoreParams containsObject:TUNE_KEY_STAGING] )
        [nonEncryptedParams appendFormat:@"%@=1", TUNE_KEY_STAGING];
    
    if( event.postConversion && ![ignoreParams containsObject:TUNE_KEY_POST_CONVERSION] )
        [nonEncryptedParams appendFormat:@"&%@=1", TUNE_KEY_POST_CONVERSION];

    NSString *keySiteEvent = event.eventName ? TUNE_KEY_SITE_EVENT_NAME : TUNE_KEY_SITE_EVENT_ID;
    
    NSString *currencyCode = event.currencyCode ?: self.currencyCode;
    
    NSNumber *hAccuracy = self.location.horizontalAccuracy ?: event.location.horizontalAccuracy;
    NSNumber *vAccuracy = self.location.verticalAccuracy ?: event.location.verticalAccuracy;
    NSDate *locTimestamp = self.location.timestamp ?: event.location.timestamp;
    
    // convert properties to keys, format, and append to URL
    [self addValue:event.actionName                 forKey:TUNE_KEY_ACTION                   	encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.advertiserId                forKey:TUNE_KEY_ADVERTISER_ID               encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.age                         forKey:TUNE_KEY_AGE                      	encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.location.altitude           forKey:TUNE_KEY_ALTITUDE                 	encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.appAdTracking               forKey:TUNE_KEY_APP_AD_TRACKING          	encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.appName                     forKey:TUNE_KEY_APP_NAME                 	encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.appVersion                  forKey:TUNE_KEY_APP_VERSION                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.bluetoothState              forKey:TUNE_KEY_BLUETOOTH_STATE             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#if TARGET_OS_IOS
    [self addValue:self.mobileCountryCode           forKey:TUNE_KEY_CARRIER_COUNTRY_CODE        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.mobileCountryCodeISO        forKey:TUNE_KEY_CARRIER_COUNTRY_CODE_ISO    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.mobileNetworkCode           forKey:TUNE_KEY_CARRIER_NETWORK_CODE        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#endif
    [self addValue:self.countryCode                 forKey:TUNE_KEY_COUNTRY_CODE                encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:currencyCode                     forKey:TUNE_KEY_CURRENCY_CODE               encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.deviceBrand                 forKey:TUNE_KEY_DEVICE_BRAND                encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#if TARGET_OS_IOS
    [self addValue:self.deviceCarrier               forKey:TUNE_KEY_DEVICE_CARRIER              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#endif
    [self addValue:self.deviceCpuSubtype            forKey:TUNE_KEY_DEVICE_CPUSUBTYPE           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.deviceCpuType               forKey:TUNE_KEY_DEVICE_CPUTYPE              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    // watchOS1
    if(self.wearable)
    {
        [self addValue:TUNE_KEY_DEVICE_FORM_WEARABLE    forKey:TUNE_KEY_DEVICE_FORM         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    }
    
#if TARGET_OS_TV
    [self addValue:TUNE_KEY_DEVICE_FORM_TV          forKey:TUNE_KEY_DEVICE_FORM         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#elif TARGET_OS_WATCH
    // watchOS2
    [self addValue:TUNE_KEY_DEVICE_FORM_WEARABLE    forKey:TUNE_KEY_DEVICE_FORM         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#endif
    
    [self addValue:self.deviceModel                 forKey:TUNE_KEY_DEVICE_MODEL            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute1                 forKey:TUNE_KEY_EVENT_ATTRIBUTE_SUB1    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute2                 forKey:TUNE_KEY_EVENT_ATTRIBUTE_SUB2    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute3                 forKey:TUNE_KEY_EVENT_ATTRIBUTE_SUB3    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute4                 forKey:TUNE_KEY_EVENT_ATTRIBUTE_SUB4    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute5                 forKey:TUNE_KEY_EVENT_ATTRIBUTE_SUB5    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.contentId                  forKey:TUNE_KEY_EVENT_CONTENT_ID        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.contentType                forKey:TUNE_KEY_EVENT_CONTENT_TYPE      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.date1                      forKey:TUNE_KEY_EVENT_DATE1             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.date2                      forKey:TUNE_KEY_EVENT_DATE2             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.level)                   forKey:TUNE_KEY_EVENT_LEVEL             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.quantity)                forKey:TUNE_KEY_EVENT_QUANTITY          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.rating)                  forKey:TUNE_KEY_EVENT_RATING            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.refId                      forKey:TUNE_KEY_REF_ID                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.revenue)                 forKey:TUNE_KEY_REVENUE                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.searchString               forKey:TUNE_KEY_EVENT_SEARCH_STRING     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.transactionState)        forKey:TUNE_KEY_IOS_PURCHASE_STATUS     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.existingUser                forKey:TUNE_KEY_EXISTING_USER           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.facebookUserId              forKey:TUNE_KEY_FACEBOOK_USER_ID        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#if TARGET_OS_IOS
    [self addValue:self.facebookCookieId            forKey:TUNE_KEY_FB_COOKIE_ID            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#endif
    [self addValue:self.gender                      forKey:TUNE_KEY_GENDER                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.iBeaconRegionId            forKey:TUNE_KEY_GEOFENCE_NAME           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.googleUserId                forKey:TUNE_KEY_GOOGLE_USER_ID          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.iadAttribution              forKey:TUNE_KEY_IAD_ATTRIBUTION         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.iadImpressionDate           forKey:TUNE_KEY_IAD_IMPRESSION_DATE     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.iadCampaignId               forKey:TUNE_KEY_IAD_CAMPAIGN_ID         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.iadCampaignName             forKey:TUNE_KEY_IAD_CAMPAIGN_NAME       encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.iadCampaignOrgName          forKey:TUNE_KEY_IAD_CAMPAIGN_ORG_NAME   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.iadLineId                   forKey:TUNE_KEY_IAD_LINE_ID             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.iadLineName                 forKey:TUNE_KEY_IAD_LINE_NAME           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.iadCreativeId               forKey:TUNE_KEY_IAD_CREATIVE_ID         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.iadCreativeName             forKey:TUNE_KEY_IAD_CREATIVE_NAME       encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.installDate                 forKey:TUNE_KEY_INSDATE                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.installLogId                forKey:TUNE_KEY_INSTALL_LOG_ID          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.ifaTracking                 forKey:TUNE_KEY_IOS_AD_TRACKING         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.ifa                         forKey:TUNE_KEY_IOS_IFA                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.ifv                         forKey:TUNE_KEY_IOS_IFV                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.payingUser                  forKey:TUNE_KEY_IS_PAYING_USER          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.conversionKey               forKey:TUNE_KEY_KEY                     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.language                    forKey:TUNE_KEY_LANGUAGE                encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.lastOpenLogId               forKey:TUNE_KEY_LAST_OPEN_LOG_ID        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.location.latitude           forKey:TUNE_KEY_LATITUDE                encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.locationAuthorizationStatus forKey:TUNE_KEY_LOCATION_AUTH_STATUS    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:hAccuracy                        forKey:TUNE_KEY_LOCATION_HORIZONTAL_ACCURACY    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:vAccuracy                        forKey:TUNE_KEY_LOCATION_VERTICAL_ACCURACY      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:locTimestamp                     forKey:TUNE_KEY_LOCATION_TIMESTAMP      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.location.longitude          forKey:TUNE_KEY_LONGITUDE               encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.matId                       forKey:TUNE_KEY_MAT_ID                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.openLogId                   forKey:TUNE_KEY_OPEN_LOG_ID             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.jailbroken                  forKey:TUNE_KEY_OS_JAILBROKE            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.osVersion                   forKey:TUNE_KEY_OS_VERSION              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.packageName                 forKey:TUNE_KEY_PACKAGE_NAME            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.redirectUrl                 forKey:TUNE_KEY_REDIRECT_URL            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.referralSource              forKey:TUNE_KEY_REFERRAL_SOURCE         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.referralUrl                 forKey:TUNE_KEY_REFERRAL_URL            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:TUNE_KEY_JSON                    forKey:TUNE_KEY_RESPONSE_FORMAT         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.screenDensity               forKey:TUNE_KEY_SCREEN_DENSITY          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.screenSize                  forKey:TUNE_KEY_SCREEN_SIZE             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    NSString *sdkPlatform = TUNE_KEY_IOS;
#if TARGET_OS_TV
    sdkPlatform = TUNE_KEY_TVOS;
#elif TARGET_OS_WATCH
    sdkPlatform = TUNE_KEY_WATCHOS;
#endif
    [self addValue:sdkPlatform                      forKey:TUNE_KEY_SDK                     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    [self addValue:self.pluginName                  forKey:TUNE_KEY_SDK_PLUGIN              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.sessionDate                 forKey:TUNE_KEY_SESSION_DATETIME        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:eventNameOrId                    forKey:keySiteEvent                     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.siteId                      forKey:TUNE_KEY_SITE_ID                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.systemDate                  forKey:TUNE_KEY_SYSTEM_DATE             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.trackingId                  forKey:TUNE_KEY_TRACKING_ID             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[NSUUID UUID] UUIDString]       forKey:TUNE_KEY_TRANSACTION_ID          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.trusteTPID                  forKey:TUNE_KEY_TRUSTE_TPID             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.twitterUserId               forKey:TUNE_KEY_TWITTER_USER_ID         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.updateLogId                 forKey:TUNE_KEY_UPDATE_LOG_ID           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userEmailMd5                forKey:TUNE_KEY_USER_EMAIL_MD5          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userEmailSha1               forKey:TUNE_KEY_USER_EMAIL_SHA1         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userEmailSha256             forKey:TUNE_KEY_USER_EMAIL_SHA256       encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userId                      forKey:TUNE_KEY_USER_ID                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userNameMd5                 forKey:TUNE_KEY_USER_NAME_MD5           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userNameSha1                forKey:TUNE_KEY_USER_NAME_SHA1          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userNameSha256              forKey:TUNE_KEY_USER_NAME_SHA256        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.phoneNumberMd5              forKey:TUNE_KEY_USER_PHONE_MD5          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.phoneNumberSha1             forKey:TUNE_KEY_USER_PHONE_SHA1         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.phoneNumberSha256           forKey:TUNE_KEY_USER_PHONE_SHA256       encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    if(self.preloadData.publisherId)
    {
        [self addValue:self.preloadData.advertiserSubAd         forKey:TUNE_KEY_ADVERTISER_SUB_AD           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.advertiserSubAdgroup    forKey:TUNE_KEY_ADVERTISER_SUB_ADGROUP      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.advertiserSubCampaign   forKey:TUNE_KEY_ADVERTISER_SUB_CAMPAIGN     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.advertiserSubKeyword    forKey:TUNE_KEY_ADVERTISER_SUB_KEYWORD      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.advertiserSubPublisher  forKey:TUNE_KEY_ADVERTISER_SUB_PUBLISHER    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.advertiserSubSite       forKey:TUNE_KEY_ADVERTISER_SUB_SITE         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.agencyId                forKey:TUNE_KEY_AGENCY_ID                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.offerId                 forKey:TUNE_KEY_OFFER_ID                    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:@(1)                                     forKey:TUNE_KEY_PRELOAD_DATA                encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherId             forKey:TUNE_KEY_PUBLISHER_ID                encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherReferenceId    forKey:TUNE_KEY_PUBLISHER_REF_ID            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSubAd          forKey:TUNE_KEY_PUBLISHER_SUB_AD            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSubAdgroup     forKey:TUNE_KEY_PUBLISHER_SUB_ADGROUP       encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSubCampaign    forKey:TUNE_KEY_PUBLISHER_SUB_CAMPAIGN      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSubKeyword     forKey:TUNE_KEY_PUBLISHER_SUB_KEYWORD       encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSubPublisher   forKey:TUNE_KEY_PUBLISHER_SUB_PUBLISHER     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSubSite        forKey:TUNE_KEY_PUBLISHER_SUB_SITE          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSub1           forKey:TUNE_KEY_PUBLISHER_SUB1              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSub2           forKey:TUNE_KEY_PUBLISHER_SUB2              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSub3           forKey:TUNE_KEY_PUBLISHER_SUB3              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSub4           forKey:TUNE_KEY_PUBLISHER_SUB4              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSub5           forKey:TUNE_KEY_PUBLISHER_SUB5              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    }
    
    [self addValue:TUNEVERSION                       			forKey:TUNE_KEY_VER                         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    [self addValue:[TuneUserAgentCollector userAgent]           forKey:TUNE_KEY_CONVERSION_USER_AGENT       encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    if( [self.debugMode boolValue] )
        [self addValue:@(TRUE)                       			forKey:TUNE_KEY_DEBUG                       encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];

    if( [self.allowDuplicates boolValue] )
        [self addValue:@(TRUE)                       			forKey:TUNE_KEY_SKIP_DUP                    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];

    // Note: it's possible for a cworks key to duplicate a built-in key (say, "sdk").
    // If that happened, the constructed URL would have two of the same parameter (e.g.,
    // "...sdk=ios&sdk=cworksvalue..."), though one might be encrypted and one not.
    for( NSString *key in [event.cworksClick allKeys] )
        [self addValue:event.cworksClick[key]        			forKey:key                                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    for( NSString *key in [event.cworksImpression allKeys] )
        [self addValue:event.cworksImpression[key]   			forKey:key                                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
#if DEBUG
    [self addValue:@(TRUE)                                      forKey:TUNE_KEY_BYPASS_THROTTLING           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#endif
    
    DLLog(@"Tune urlStringForServerUrl: data to be encrypted: %@", encryptedParams);
    
    if( [_delegate respondsToSelector:@selector(_tuneURLTestingCallbackWithParamsToBeEncrypted:withPlaintextParams:)] )
        [_delegate _tuneURLTestingCallbackWithParamsToBeEncrypted:encryptedParams withPlaintextParams:nonEncryptedParams];
    
    *trackingLink = [NSString stringWithFormat:@"%@://%@.%@/%@?%@",
                     TUNE_KEY_HTTPS,
                     self.advertiserId,
                     [self domainName],
                     TUNE_SERVER_PATH_TRACKING_ENGINE,
                     nonEncryptedParams];
    *encryptParams = encryptedParams;
}

- (void)addValue:(id)value
          forKey:(NSString*)key
 encryptedParams:(NSMutableString*)encryptedParams
 plaintextParams:(NSMutableString*)plaintextParams
{
    if( value == nil || [ignoreParams containsObject:key]) return;
    
    if( [key isEqualToString:TUNE_KEY_PACKAGE_NAME] || [key isEqualToString:TUNE_KEY_DEBUG] )
    {
        [TuneUtils addUrlQueryParamValue:value forKey:key queryParams:plaintextParams];
        [TuneUtils addUrlQueryParamValue:value forKey:key queryParams:encryptedParams];
    }
    else if( [doNotEncryptSet containsObject:key] )
    {
        [TuneUtils addUrlQueryParamValue:value forKey:key queryParams:plaintextParams];
    }
    else
    {
        [TuneUtils addUrlQueryParamValue:value forKey:key queryParams:encryptedParams];
    }
}

@end
