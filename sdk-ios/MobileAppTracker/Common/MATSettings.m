//
//  MATSettings.m
//  MobileAppTracker
//
//  Created by John Bender on 1/10/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <sys/utsname.h>
#import <Foundation/Foundation.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UIKit/UIKit.h>

#import "MATSettings.h"
#import "MATUtils.h"
#import "NSString+MATURLEncoding.m"
#import "MATEncrypter.h"


@implementation MATSettings

-(id) init
{
    self = [super init];
    if( self ) {
         if([MATUtils userDefaultValueforKey:KEY_MAT_ID])
         {
             self.matId = [MATUtils userDefaultValueforKey:KEY_MAT_ID];
         }
         else
         {
             NSString *uuid = [MATUtils getUUID];
             [MATUtils setUserDefaultValue:uuid forKey:KEY_MAT_ID];
             self.matId = uuid;
         }
         
        self.installLogId = [MATUtils userDefaultValueforKey:KEY_MAT_INSTALL_LOG_ID];
        if( !self.installLogId )
            self.updateLogId = [MATUtils userDefaultValueforKey:KEY_MAT_UPDATE_LOG_ID];
        self.openLogId = [MATUtils userDefaultValueforKey:KEY_OPEN_LOG_ID];
        self.lastOpenLogId = [MATUtils userDefaultValueforKey:KEY_LAST_OPEN_LOG_ID];
        
        self.iadAttribution = [MATUtils userDefaultValueforKey:KEY_IAD_ATTRIBUTION];
        
         // Device params
         struct utsname systemInfo;
         uname(&systemInfo);
         NSString * machineName = [NSString stringWithCString:systemInfo.machine
                                                     encoding:NSUTF8StringEncoding];
        self.deviceModel = machineName;
        
        CTTelephonyNetworkInfo * carrier = [[CTTelephonyNetworkInfo alloc] init];
        self.deviceCarrier = [[carrier subscriberCellularProvider] carrierName];
        self.mobileCountryCode = [[carrier subscriberCellularProvider] mobileCountryCode];
        self.mobileCountryCodeISO = [[carrier subscriberCellularProvider] isoCountryCode];
        self.mobileNetworkCode = [[carrier subscriberCellularProvider] mobileNetworkCode];
        
        self.deviceBrand = @"Apple";
        
         // App params
        self.packageName = [MATUtils bundleId];
        if( self.packageName == nil && [UIApplication sharedApplication] == nil ) {
            // should only happen during unit tests
            self.packageName = @"com.mobileapptracking.iosunittest";
        }

        NSDictionary *plist = [[NSBundle mainBundle] infoDictionary];
        self.appName = [plist objectForKey:(__bridge NSString*)kCFBundleNameKey];
        self.appVersion = [plist objectForKey:(__bridge NSString*)kCFBundleVersionKey];
        
         //Other params
         self.countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        self.osVersion = [[UIDevice currentDevice] systemVersion];
         self.language = [[NSLocale preferredLanguages] objectAtIndex:0];
         
         self.userAgent = [MATUtils generateUserAgentString];

        self.installDate = [MATUtils installDate];
        
         // FB cookie id
         [self loadFacebookCookieId];
        
        // default to USD for currency code
        self.defaultCurrencyCode = KEY_CURRENCY_USD;
        
        self.payingUser = [MATUtils userDefaultValueforKey:KEY_IS_PAYING_USER];
        
         //init doNotEncrypt set
         NSSet * doNotEncryptForNormalLevelSet = [NSSet setWithObjects:KEY_ADVERTISER_ID, KEY_SITE_ID, KEY_DOMAIN, KEY_ACTION,
                                                  KEY_SITE_EVENT_ID, KEY_SDK, KEY_VER, KEY_KEY_INDEX, KEY_SITE_EVENT_NAME,
                                                  KEY_REFERRAL_URL, KEY_REFERRAL_SOURCE, KEY_TRACKING_ID, KEY_PACKAGE_NAME,
                                                  KEY_IAD_ATTRIBUTION, KEY_TRANSACTION_ID, nil];
         NSSet * doNotEncryptForHighLevelSet = [NSSet setWithObjects:KEY_ADVERTISER_ID, KEY_SITE_ID, KEY_SDK, KEY_ACTION,
                                                KEY_PACKAGE_NAME, KEY_IAD_ATTRIBUTION, KEY_TRANSACTION_ID, nil];
        NSDictionary * doNotEncryptDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                           doNotEncryptForNormalLevelSet, NORMALLY_ENCRYPTED,
                                           doNotEncryptForHighLevelSet, HIGHLY_ENCRYPTED, nil];
         
         self.doNotEncryptDict = doNotEncryptDict;
    }
    return self;
}


- (void)loadFacebookCookieId
{
    self.facebookCookieId = [MATUtils generateFBCookieIdString];
}


-(NSString*) domainName:(BOOL)debug
{
    if(self.staging)
        return SERVER_DOMAIN_REGULAR_TRACKING_STAGE;
    else
        // on prod, use a different server domain name when debug mode is enabled
        return debug ? SERVER_DOMAIN_REGULAR_TRACKING_PROD_DEBUG : SERVER_DOMAIN_REGULAR_TRACKING_PROD;
}


-(void) resetBeforeTrackAction
{
    self.actionName = nil;
}


-(NSString*) urlStringForDebugMode:(BOOL)debugMode
                      ignoreParams:(NSSet*)ignoreParams
                   encryptionLevel:(NSString*)encryptionLevel
{
    return [self urlStringForReferenceId:nil
                               debugMode:debugMode
                            ignoreParams:ignoreParams
                         encryptionLevel:encryptionLevel];
}

-(NSString*) urlStringForReferenceId:(NSString*)referenceId
                           debugMode:(BOOL)debugMode
                        ignoreParams:(NSSet*)ignoreParams
                     encryptionLevel:(NSString*)encryptionLevel
{
    // determine correct event name and action name
    NSString *eventNameOrId = nil;
    BOOL isId = NO;
    
    if( [self.actionName rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location == NSNotFound ) {
        // if no characters, it's an ID
        isId = YES;
        eventNameOrId = [self.actionName copy];
        self.actionName = EVENT_CONVERSION;
    }
    else if( self.postConversion && [self.actionName isEqualToString:EVENT_INSTALL] ) {
        // don't modify action name
    }
    else if( [[self.actionName lowercaseString] isEqualToString:EVENT_INSTALL] ||
             [[self.actionName lowercaseString] isEqualToString:EVENT_UPDATE] ||
             [[self.actionName lowercaseString] isEqualToString:EVENT_OPEN] ||
             [[self.actionName lowercaseString] isEqualToString:EVENT_SESSION] ) {
        self.actionName = EVENT_SESSION;
    }
    else {
        // if it's not an install, update, or open, it's a conversion
        eventNameOrId = [self.actionName copy];
        self.actionName = EVENT_CONVERSION;
    }

    // conversion key to be used for encrypting the request url data
    NSString* encryptKey = self.conversionKey;
 
    // part of the url that does not need encryption
    NSMutableString* nonEncryptedParams = [NSMutableString stringWithCapacity:256];
 
    // part of the url that needs encryption
    NSMutableString* encryptedParams = [NSMutableString stringWithCapacity:512];
 
    // get the list of params that should not be encrypted for the given encryption level
    NSSet* doNotEncryptSet = [self.doNotEncryptDict valueForKey:encryptionLevel];
    
    if( self.staging && ![ignoreParams containsObject:KEY_STAGING] )
        [nonEncryptedParams appendFormat:@"%@=1", KEY_STAGING];
    
    if( self.postConversion && ![ignoreParams containsObject:KEY_POST_CONVERSION] )
        [nonEncryptedParams appendFormat:@"&%@=1", KEY_POST_CONVERSION];

    // convert properties to keys, format, and append to URL
    [self addValue:self.actionName forKey:KEY_ACTION ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    if( isId )
        [self addValue:eventNameOrId forKey:KEY_SITE_EVENT_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    else
        [self addValue:eventNameOrId forKey:KEY_SITE_EVENT_NAME ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:referenceId forKey:KEY_REF_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.installDate forKey:KEY_INSDATE ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.sessionDate forKey:KEY_SESSION_DATETIME ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.systemDate forKey:KEY_SYSTEM_DATE ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.referralUrl forKey:KEY_REFERRAL_URL ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.referralSource forKey:KEY_REFERRAL_SOURCE ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.redirectUrl forKey:KEY_REDIRECT_URL ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.installLogId forKey:KEY_INSTALL_LOG_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.updateLogId forKey:KEY_UPDATE_LOG_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.openLogId forKey:KEY_OPEN_LOG_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.lastOpenLogId forKey:KEY_LAST_OPEN_LOG_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.currencyCode forKey:KEY_CURRENCY ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.revenue forKey:KEY_REVENUE ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.transactionState forKey:KEY_IOS_PURCHASE_STATUS ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.jailbroken forKey:KEY_OS_JAILBROKE ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.siteId forKey:KEY_SITE_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.packageName forKey:KEY_PACKAGE_NAME ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.appName forKey:KEY_APP_NAME ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.appVersion forKey:KEY_APP_VERSION ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.advertiserId forKey:KEY_ADVERTISER_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.conversionKey forKey:KEY_KEY ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.trackingId forKey:KEY_TRACKING_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.matId forKey:KEY_MAT_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.facebookCookieId forKey:KEY_FB_COOKIE_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.ifv forKey:KEY_IOS_IFV ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.ifa forKey:KEY_IOS_IFA ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.ifaTracking forKey:KEY_IOS_AD_TRACKING ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.iadAttribution forKey:KEY_IAD_ATTRIBUTION ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.appAdTracking forKey:KEY_APP_AD_TRACKING ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.payingUser forKey:KEY_IS_PAYING_USER ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.existingUser forKey:KEY_EXISTING_USER ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userEmail forKey:KEY_USER_EMAIL ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userId forKey:KEY_USER_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userName forKey:KEY_USER_NAME ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.facebookUserId forKey:KEY_FACEBOOK_USER_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.twitterUserId forKey:KEY_TWITTER_USER_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.googleUserId forKey:KEY_GOOGLE_USER_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.age forKey:KEY_AGE ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.gender forKey:KEY_GENDER ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.latitude forKey:KEY_LATITUDE ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.longitude forKey:KEY_LONGITUDE ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.altitude forKey:KEY_ALTITUDE ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.trusteTPID forKey:KEY_TRUSTE_TPID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.deviceModel forKey:KEY_DEVICE_MODEL ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.deviceCarrier forKey:KEY_DEVICE_CARRIER ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.deviceBrand forKey:KEY_DEVICE_BRAND ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.mobileCountryCode forKey:KEY_CARRIER_COUNTRY_CODE ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.mobileCountryCodeISO forKey:KEY_CARRIER_COUNTRY_CODE_ISO ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.mobileNetworkCode forKey:KEY_CARRIER_NETWORK_CODE ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.countryCode forKey:KEY_COUNTRY_CODE ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.osVersion forKey:KEY_OS_VERSION ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.language forKey:KEY_LANGUAGE ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.userAgent forKey:KEY_CONVERSION_USER_AGENT ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@"ios" forKey:KEY_SDK ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:MATVERSION forKey:KEY_VER ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.pluginName forKey:KEY_SDK_PLUGIN ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    [self addValue:self.eventAttribute1 forKey:KEY_EVENT_ATTRIBUTE_SUB1 ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventAttribute2 forKey:KEY_EVENT_ATTRIBUTE_SUB2 ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventAttribute3 forKey:KEY_EVENT_ATTRIBUTE_SUB3 ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventAttribute4 forKey:KEY_EVENT_ATTRIBUTE_SUB4 ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:self.eventAttribute5 forKey:KEY_EVENT_ATTRIBUTE_SUB5 ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    // Note: it's possible for a cworks key to duplicate a built-in key (say, "sdk").
    // If that happened, the constructed URL would have two of the same parameter (e.g.,
    // "...sdk=ios&sdk=cworksvalue..."), though one might be encrypted and one not.
    for( NSString *key in [self.cworksClick allKeys] )
        [self addValue:self.cworksClick[key] forKey:key ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    for( NSString *key in [self.cworksImpression allKeys] )
        [self addValue:self.cworksImpression[key] forKey:key ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];

    [self addValue:[[NSUUID UUID] UUIDString] forKey:KEY_TRANSACTION_ID ignoreParams:ignoreParams doNotEncrypt:doNotEncryptSet encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];

#if DEBUG
    if( [self.delegate respondsToSelector:@selector(_matURLTestingCallbackWithParamsToBeEncrypted:withPlaintextParams:)] )
        [self.delegate performSelector:@selector(_matURLTestingCallbackWithParamsToBeEncrypted:withPlaintextParams:) withObject:encryptedParams withObject:nonEncryptedParams];
#endif
    //NSLog( @"%@ %@", encryptedParams, nonEncryptedParams );

    DLLog(@"MAT urlStringForServerUrl: key = %@, data to be encrypted: %@", encryptKey, encryptedParams);
 
    // encrypt the params
    NSString* encryptedData = [MATEncrypter encryptString:encryptedParams withKey:encryptKey];
 
    DLLog(@"MAT urlStringForServerUrl: encrypted data: %@", encryptedData);
 
    NSString *host = [NSString stringWithFormat:@"https://%@.%@",
                      self.advertiserId,
                      [self domainName:debugMode]];

    // create the final url string by appending the unencrypted and encrypted params
    return [NSString stringWithFormat:@"%@/%@?%@&%@=%@",
            host,
            SERVER_PATH_TRACKING_ENGINE,
            nonEncryptedParams,
            KEY_DATA,
            encryptedData];
}

-(void) addValue:(id)value
          forKey:(NSString*)key
    ignoreParams:(NSSet*)ignoreParams
    doNotEncrypt:(NSSet*)doNotEncryptSet
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

    if( [key isEqualToString:KEY_PACKAGE_NAME] ) {
        [plaintextParams appendFormat:@"&%@=%@", key, useString];
        [encryptedParams appendFormat:@"&%@=%@", key, useString];
    }
    else {
        if( [doNotEncryptSet containsObject:key] )
            [plaintextParams appendFormat:@"&%@=%@", key, useString];
        else
            [encryptedParams appendFormat:@"&%@=%@", key, useString];
    }
}


-(void) resetAfterRequest
{
    self.currencyCode = self.defaultCurrencyCode;
    
    self.eventAttribute1 = nil;
    self.eventAttribute2 = nil;
    self.eventAttribute3 = nil;
    self.eventAttribute4 = nil;
    self.eventAttribute5 = nil;
    
    self.postConversion = FALSE;
    
    self.revenue = nil;
    self.transactionState = nil;
    self.cworksClick = nil;
    self.cworksImpression = nil;
}

@end
