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


@interface MATSettings ()
{
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
        
        self.userEmailMd5 = [MATUtils userDefaultValueforKey:MAT_KEY_USER_EMAIL_MD5];
        self.userEmailSha1 = [MATUtils userDefaultValueforKey:MAT_KEY_USER_EMAIL_SHA1];
        self.userEmailSha256 = [MATUtils userDefaultValueforKey:MAT_KEY_USER_EMAIL_SHA256];
        self.userId = [MATUtils userDefaultValueforKey:MAT_KEY_USER_ID];
        self.userNameMd5 = [MATUtils userDefaultValueforKey:MAT_KEY_USER_NAME_MD5];
        self.userNameSha1 = [MATUtils userDefaultValueforKey:MAT_KEY_USER_NAME_SHA1];
        self.userNameSha256 = [MATUtils userDefaultValueforKey:MAT_KEY_USER_NAME_SHA256];
        self.phoneNumberMd5 = [MATUtils userDefaultValueforKey:MAT_KEY_USER_PHONE_MD5];
        self.phoneNumberSha1 = [MATUtils userDefaultValueforKey:MAT_KEY_USER_PHONE_SHA1];
        self.phoneNumberSha256 = [MATUtils userDefaultValueforKey:MAT_KEY_USER_PHONE_SHA256];
        
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
        self.currencyCode = MAT_KEY_CURRENCY_USD;
        
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


#pragma mark - Overridden setters

- (void)setUserEmail:(NSString *)userEmail
{
    _userEmail = [userEmail copy];
    _userEmailMd5 = [MATUtils hashMd5:userEmail];
    _userEmailSha1 = [MATUtils hashSha1:userEmail];
    _userEmailSha256 = [MATUtils hashSha256:userEmail];
    
    [MATUtils setUserDefaultValue:_userEmailMd5 forKey:MAT_KEY_USER_EMAIL_MD5];
    [MATUtils setUserDefaultValue:_userEmailSha1 forKey:MAT_KEY_USER_EMAIL_SHA1];
    [MATUtils setUserDefaultValue:_userEmailSha256 forKey:MAT_KEY_USER_EMAIL_SHA256];
}

- (void)setUserId:(NSString *)userId
{
    _userId = [userId copy];
    [MATUtils setUserDefaultValue:_userId forKey:MAT_KEY_USER_ID];
}

- (void)setUserName:(NSString *)userName
{
    _userName = [userName copy];
    _userNameMd5 = [MATUtils hashMd5:userName];
    _userNameSha1 = [MATUtils hashSha1:userName];
    _userNameSha256 = [MATUtils hashSha256:userName];
    
    [MATUtils setUserDefaultValue:_userNameMd5 forKey:MAT_KEY_USER_NAME_MD5];
    [MATUtils setUserDefaultValue:_userNameSha1 forKey:MAT_KEY_USER_NAME_SHA1];
    [MATUtils setUserDefaultValue:_userNameSha256 forKey:MAT_KEY_USER_NAME_SHA256];
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
    
    _phoneNumberMd5 = [MATUtils hashMd5:_phoneNumber];
    _phoneNumberSha1 = [MATUtils hashSha1:_phoneNumber];
    _phoneNumberSha256 = [MATUtils hashSha256:_phoneNumber];
    
    [MATUtils setUserDefaultValue:_phoneNumberMd5 forKey:MAT_KEY_USER_PHONE_MD5];
    [MATUtils setUserDefaultValue:_phoneNumberSha1 forKey:MAT_KEY_USER_PHONE_SHA1];
    [MATUtils setUserDefaultValue:_phoneNumberSha256 forKey:MAT_KEY_USER_PHONE_SHA256];
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

- (void)urlStringForEvent:(MATEvent *)event
             trackingLink:(NSString**)trackingLink
            encryptParams:(NSString**)encryptParams
{
    NSString *eventNameOrId = nil;
    
    // do not include the eventName param in the request url for actions -- install, session, geofence
    
    BOOL isActionInstall = [event.actionName isEqualToString:MAT_EVENT_INSTALL];
    BOOL isActionSession = [event.actionName isEqualToString:MAT_EVENT_SESSION];
    BOOL isActionGeofence = [event.actionName isEqualToString:MAT_EVENT_GEOFENCE];
    
    if (!isActionInstall && !isActionSession && !isActionGeofence) {
        eventNameOrId = event.eventName ? event.eventName : [@(event.eventId) stringValue];
    }
    
    // part of the url that does not need encryption
    NSMutableString* nonEncryptedParams = [NSMutableString stringWithCapacity:256];
    
    // part of the url that needs encryption
    NSMutableString* encryptedParams = [NSMutableString stringWithCapacity:512];
    
    if( self.staging && ![ignoreParams containsObject:MAT_KEY_STAGING] )
        [nonEncryptedParams appendFormat:@"%@=1", MAT_KEY_STAGING];
    
    if( event.postConversion && ![ignoreParams containsObject:MAT_KEY_POST_CONVERSION] )
        [nonEncryptedParams appendFormat:@"&%@=1", MAT_KEY_POST_CONVERSION];
    
    NSString *keySiteEvent = event.eventName ? MAT_KEY_SITE_EVENT_NAME : MAT_KEY_SITE_EVENT_ID;
    
    NSString *currencyCode = event.currencyCode ?: self.currencyCode;
    
    // convert properties to keys, format, and append to URL
    [self addValue:event.actionName                  forKey:MAT_KEY_ACTION                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.advertiserId                 forKey:MAT_KEY_ADVERTISER_ID            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.age                          forKey:MAT_KEY_AGE                      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.altitude                     forKey:MAT_KEY_ALTITUDE                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.appAdTracking                forKey:MAT_KEY_APP_AD_TRACKING          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.appName                      forKey:MAT_KEY_APP_NAME                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.appVersion                   forKey:MAT_KEY_APP_VERSION              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.bluetoothState               forKey:MAT_KEY_BLUETOOTH_STATE          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.mobileCountryCode            forKey:MAT_KEY_CARRIER_COUNTRY_CODE     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.mobileCountryCodeISO         forKey:MAT_KEY_CARRIER_COUNTRY_CODE_ISO encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.mobileNetworkCode            forKey:MAT_KEY_CARRIER_NETWORK_CODE     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.countryCode                  forKey:MAT_KEY_COUNTRY_CODE             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:currencyCode                      forKey:MAT_KEY_CURRENCY_CODE            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.deviceBrand                  forKey:MAT_KEY_DEVICE_BRAND             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.deviceCarrier                forKey:MAT_KEY_DEVICE_CARRIER           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.deviceCpuSubtype             forKey:MAT_KEY_DEVICE_CPUSUBTYPE        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.deviceCpuType                forKey:MAT_KEY_DEVICE_CPUTYPE           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.deviceModel                  forKey:MAT_KEY_DEVICE_MODEL             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute1                  forKey:MAT_KEY_EVENT_ATTRIBUTE_SUB1     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute2                  forKey:MAT_KEY_EVENT_ATTRIBUTE_SUB2     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute3                  forKey:MAT_KEY_EVENT_ATTRIBUTE_SUB3     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute4                  forKey:MAT_KEY_EVENT_ATTRIBUTE_SUB4     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute5                  forKey:MAT_KEY_EVENT_ATTRIBUTE_SUB5     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.contentId                   forKey:MAT_KEY_EVENT_CONTENT_ID         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.contentType                 forKey:MAT_KEY_EVENT_CONTENT_TYPE       encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.date1                       forKey:MAT_KEY_EVENT_DATE1              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.date2                       forKey:MAT_KEY_EVENT_DATE2              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.level)                    forKey:MAT_KEY_EVENT_LEVEL              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.quantity)                 forKey:MAT_KEY_EVENT_QUANTITY           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.rating)                   forKey:MAT_KEY_EVENT_RATING             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.refId                       forKey:MAT_KEY_REF_ID                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.revenue)                  forKey:MAT_KEY_REVENUE                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.searchString                forKey:MAT_KEY_EVENT_SEARCH_STRING      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.transactionState)         forKey:MAT_KEY_IOS_PURCHASE_STATUS      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.existingUser                 forKey:MAT_KEY_EXISTING_USER            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.facebookUserId               forKey:MAT_KEY_FACEBOOK_USER_ID         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.facebookCookieId             forKey:MAT_KEY_FB_COOKIE_ID             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.gender                       forKey:MAT_KEY_GENDER                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.iBeaconRegionId             forKey:MAT_KEY_GEOFENCE_NAME            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.googleUserId                 forKey:MAT_KEY_GOOGLE_USER_ID           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.iadAttribution               forKey:MAT_KEY_IAD_ATTRIBUTION          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.iadImpressionDate            forKey:MAT_KEY_IAD_IMPRESSION_DATE      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.installDate                  forKey:MAT_KEY_INSDATE                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.installLogId                 forKey:MAT_KEY_INSTALL_LOG_ID           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.ifaTracking                  forKey:MAT_KEY_IOS_AD_TRACKING          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.ifa                          forKey:MAT_KEY_IOS_IFA                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.ifv                          forKey:MAT_KEY_IOS_IFV                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.payingUser                   forKey:MAT_KEY_IS_PAYING_USER           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.conversionKey                forKey:MAT_KEY_KEY                      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.language                     forKey:MAT_KEY_LANGUAGE                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.lastOpenLogId                forKey:MAT_KEY_LAST_OPEN_LOG_ID         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.latitude                     forKey:MAT_KEY_LATITUDE                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.locationAuthorizationStatus  forKey:MAT_KEY_LOCATION_AUTH_STATUS     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.longitude                    forKey:MAT_KEY_LONGITUDE                encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.matId                        forKey:MAT_KEY_MAT_ID                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.openLogId                    forKey:MAT_KEY_OPEN_LOG_ID              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.jailbroken                   forKey:MAT_KEY_OS_JAILBROKE             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.osVersion                    forKey:MAT_KEY_OS_VERSION               encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.packageName                  forKey:MAT_KEY_PACKAGE_NAME             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.redirectUrl                  forKey:MAT_KEY_REDIRECT_URL             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.referralSource               forKey:MAT_KEY_REFERRAL_SOURCE          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.referralUrl                  forKey:MAT_KEY_REFERRAL_URL             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:MAT_KEY_JSON                      forKey:MAT_KEY_RESPONSE_FORMAT          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.screenDensity                forKey:MAT_KEY_SCREEN_DENSITY           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.screenSize                   forKey:MAT_KEY_SCREEN_SIZE              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:MAT_KEY_IOS                       forKey:MAT_KEY_SDK                      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.pluginName                   forKey:MAT_KEY_SDK_PLUGIN               encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.sessionDate                  forKey:MAT_KEY_SESSION_DATETIME         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:eventNameOrId                     forKey:keySiteEvent                     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.siteId                       forKey:MAT_KEY_SITE_ID                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.systemDate                   forKey:MAT_KEY_SYSTEM_DATE              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.trackingId                   forKey:MAT_KEY_TRACKING_ID              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[NSUUID UUID] UUIDString]        forKey:MAT_KEY_TRANSACTION_ID           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.trusteTPID                   forKey:MAT_KEY_TRUSTE_TPID              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.twitterUserId                forKey:MAT_KEY_TWITTER_USER_ID          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.updateLogId                  forKey:MAT_KEY_UPDATE_LOG_ID            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userEmailMd5                 forKey:MAT_KEY_USER_EMAIL_MD5           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userEmailSha1                forKey:MAT_KEY_USER_EMAIL_SHA1          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userEmailSha256              forKey:MAT_KEY_USER_EMAIL_SHA256        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userId                       forKey:MAT_KEY_USER_ID                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userNameMd5                  forKey:MAT_KEY_USER_NAME_MD5            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userNameSha1                 forKey:MAT_KEY_USER_NAME_SHA1           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userNameSha256               forKey:MAT_KEY_USER_NAME_SHA256         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.phoneNumberMd5               forKey:MAT_KEY_USER_PHONE_MD5           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.phoneNumberSha1              forKey:MAT_KEY_USER_PHONE_SHA1          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.phoneNumberSha256            forKey:MAT_KEY_USER_PHONE_SHA256        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    if(self.preloadData.publisherId)
    {
        [self addValue:@(1)                                     forKey:MAT_KEY_PRELOAD_DATA               encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherId             forKey:MAT_KEY_PUBLISHER_ID               encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.offerId                 forKey:MAT_KEY_OFFER_ID                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.agencyId                forKey:MAT_KEY_AGENCY_ID                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherReferenceId    forKey:MAT_KEY_PUBLISHER_REF_ID           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSubPublisher   forKey:MAT_KEY_PUBLISHER_SUB_PUBLISHER    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSubSite        forKey:MAT_KEY_PUBLISHER_SUB_SITE         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSubCampaign    forKey:MAT_KEY_PUBLISHER_SUB_CAMPAIGN     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSubAdgroup     forKey:MAT_KEY_PUBLISHER_SUB_ADGROUP      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSubAd          forKey:MAT_KEY_PUBLISHER_SUB_AD           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSubKeyword     forKey:MAT_KEY_PUBLISHER_SUB_KEYWORD      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.advertiserSubPublisher  forKey:MAT_KEY_ADVERTISER_SUB_PUBLISHER   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.advertiserSubSite       forKey:MAT_KEY_ADVERTISER_SUB_SITE        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.advertiserSubCampaign   forKey:MAT_KEY_ADVERTISER_SUB_CAMPAIGN    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.advertiserSubAdgroup    forKey:MAT_KEY_ADVERTISER_SUB_ADGROUP     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.advertiserSubAd         forKey:MAT_KEY_ADVERTISER_SUB_AD          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.advertiserSubKeyword    forKey:MAT_KEY_ADVERTISER_SUB_KEYWORD     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSub1           forKey:MAT_KEY_PUBLISHER_SUB1             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSub2           forKey:MAT_KEY_PUBLISHER_SUB2             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSub3           forKey:MAT_KEY_PUBLISHER_SUB3             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSub4           forKey:MAT_KEY_PUBLISHER_SUB4             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:self.preloadData.publisherSub5           forKey:MAT_KEY_PUBLISHER_SUB5             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    }
    
    [self addValue:MATVERSION                        forKey:MAT_KEY_VER                      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    [self addValue:[MATUserAgentCollector userAgent] forKey:MAT_KEY_CONVERSION_USER_AGENT    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    if( [self.debugMode boolValue] )
        [self addValue:@(TRUE)                       forKey:MAT_KEY_DEBUG                    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    if( [self.allowDuplicates boolValue] )
        [self addValue:@(TRUE)                       forKey:MAT_KEY_SKIP_DUP                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    // Note: it's possible for a cworks key to duplicate a built-in key (say, "sdk").
    // If that happened, the constructed URL would have two of the same parameter (e.g.,
    // "...sdk=ios&sdk=cworksvalue..."), though one might be encrypted and one not.
    for( NSString *key in [event.cworksClick allKeys] )
        [self addValue:event.cworksClick[key]        forKey:key                              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    for( NSString *key in [event.cworksImpression allKeys] )
        [self addValue:event.cworksImpression[key]   forKey:key                              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
#if DEBUG
    [self addValue:@(TRUE)                           forKey:MAT_KEY_BYPASS_THROTTLING        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#endif
    
    DLLog(@"MobileAppTracker urlStringForEvent: data to be encrypted: %@", encryptedParams);
    
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
    if( value == nil || [ignoreParams containsObject:key]) return;
    
    if( [key isEqualToString:MAT_KEY_PACKAGE_NAME] || [key isEqualToString:MAT_KEY_DEBUG] )
    {
        [MATUtils addUrlQueryParamValue:value forKey:key queryParams:plaintextParams];
        [MATUtils addUrlQueryParamValue:value forKey:key queryParams:encryptedParams];
    }
    else if( [doNotEncryptSet containsObject:key] )
    {
        [MATUtils addUrlQueryParamValue:value forKey:key queryParams:plaintextParams];
    }
    else
    {
        [MATUtils addUrlQueryParamValue:value forKey:key queryParams:encryptedParams];
    }
}

@end
