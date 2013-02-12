//
//  MobileAppTracker.m
//  MobileAppTracker
//
//  Created by HasOffers on 11/14/12.
//  Copyright (c) 2012 HasOffers. All rights reserved.
//

#import "MobileAppTracker.h"

#import <UIKit/UIKit.h>

#import "Common/MATConnectionManager.h"
#import "Common/MATCWorks.h"
#import "Common/MATKeyStrings.h"
#import "Common/MATJSONSerializer.h"
#import "Common/MATRemoteLogger.h"
#import "Common/MATUtils.h"
#import "Common/NSString+MATURLEncoding.m"

#import "MATEncrypter.h"

#import <sys/utsname.h>

#import <CoreFoundation/CoreFoundation.h>

#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import <AdSupport/AdSupport.h>

/****************************************
 *  VERY IMPORTANT!
 *  These values should be zero for releases.
 ****************************************/
#define DEBUG_LOG                   0
#define DEBUG_REMOTE_LOG            0
#define DEBUG_REQUEST_LOG           0
#define DEBUG_JAILBREAK_LOG         0
#define DEBUG_STAGING               0

#if DEBUG_REMOTE_LOG
    NSString * const SERVER_URL_REMOTE_LOGGER = @"http://hasoffers.us/fb-cookie.php"
#endif

@interface MobileAppTracker() <MATConnectionManagerDelegate>

@property (nonatomic, retain) NSMutableDictionary *parameters;
@property (nonatomic, retain) NSString * serverPath;
@property (nonatomic, retain) NSDictionary * doNotEncryptDict;

// this is set by the setter so we can reset the currency code default
// after track actions since parameters is used
@property (nonatomic, retain) NSString *defaultCurrencyCode;

// settings to check for generating data
@property (nonatomic, assign) BOOL shouldUseHTTPS;
@property (nonatomic, assign) BOOL shouldUseCookieTracking;
@property (nonatomic, assign) BOOL shouldGenerateMacAddress;
@property (nonatomic, assign) BOOL shouldGenereateODIN1Key;
@property (nonatomic, assign) BOOL shouldGenerateOpenUDIDKey;
@property (nonatomic, assign) BOOL shouldGenerateVendorIdentifier;
@property (nonatomic, assign) BOOL shouldGenerateAdvertiserIdentifier;

#if DEBUG_REMOTE_LOG
    @property (nonatomic, retain) RemoteLogger * remoteLogger;
#endif

- (NSString*)urlStringForParams:(NSDictionary*)params path:(NSString*)path encryptionLevel:(NSString*)encryptionLevel ignoreParams:(NSSet*)ignoreParams;
- (NSString*)requestLink:(NSString*)refId encryptionLevel:(NSString*)encryptionLevel ignoreParams:(NSSet*)ignoreParams;
- (void)buildUrlRequest:(NSArray *)params referenceId:(NSString*)refId;
- (void)initVariablesForTrackAction:(NSString *)eventIdOrName eventIsId:(BOOL)isId;
- (void)loadParametersData;
- (void)loadFacebookCookieId;
- (BOOL)shouldUseParam:(NSString *)paramKey;
- (void)resetApplicationOpenUrlKeys;
- (void)createInstallMarker;
- (BOOL)checkTracking:(NSString*)refId;
- (void)notifyDelegateSuccessMessage:(NSString *)message;
- (void)notifyDelegateFailureWithError:(NSError *)error;

- (void)fetchCWorksClickKey:(NSString **)key andValue:(NSNumber **)value;
- (void)fetchCWorksImpressionKey:(NSString **)key andValue:(NSNumber **)value;

/*!
 Record a Track Update or Install
 To be called when an app opens; typically in the didFinishLaunching event.
 If updateOnly is YES, then the sdk will never record an install. 
 The SDK will always record updates to an app in any case.
 @param updateOnly only record udpates and no installs.
 @param refId A reference id used to track an install and/or update.
 */
- (void)trackInstallWithUpdateOnly:(BOOL)updateOnly
                       referenceId:(NSString *)refId;

@end

@implementation MobileAppTracker

@synthesize parameters = _parameters;
@synthesize delegate = _delegate;
@synthesize doNotEncryptDict = _doNotEncryptDict;
@synthesize serverPath = _serverPath;
@synthesize defaultCurrencyCode = _defaultCurrencyCode;
@synthesize shouldUseHTTPS = _shouldUseHTTPS;
@synthesize shouldGenerateMacAddress = _shouldGenerateMacAddress;
@synthesize shouldGenerateOpenUDIDKey = _shouldGenerateOpenUDIDKey;
@synthesize shouldGenereateODIN1Key = _shouldGenereateODIN1Key;
@synthesize shouldUseCookieTracking = _shouldUseCookieTracking;
@synthesize shouldGenerateVendorIdentifier = _shouldGenerateVendorIdentifier;
@synthesize shouldGenerateAdvertiserIdentifier = _shouldGenerateAdvertiserIdentifier;

@synthesize sdkDataParameters = _sdkDataParameters;

static int IGNORE_IOS_PURCHASE_STATUS = -192837465;

#if DEBUG_REMOTE_LOG
    @synthesize remoteLogger = _remoteLogger;
#endif

#pragma mark -
#pragma mark Singleton Methods

+ (MobileAppTracker *)sharedManager
{
    static MobileAppTracker *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[MobileAppTracker alloc] init];
        // Do any other initialisation stuff here
    });
    
    return sharedManager;
}

#pragma mark -
#pragma mark init method
- (id)init
{
    if (self = [super init])
    {
        // Initialization code here
        // create an empty parameters dictionary
        if(!self.parameters) self.parameters = [NSMutableDictionary dictionary];
        
#if DEBUG_REMOTE_LOG
        self.remoteLogger = [[[RemoteLogger alloc] initWithURL:SERVER_URL_REMOTE_LOGGER] autorelease];
#endif
        
#if DEBUG_STAGING
        [self.parameters setValue:@"1" forKey:KEY_STAGING];
#endif
        
        // this won't generate any auto params  yet
        [self loadParametersData];
        
        // !!! very important to init some parms here
        [self setUseCookieTracking:NO];         // default to no for cookie based tracking
        [self setUseHTTPS:YES];
        [self setShouldAutoGenerateMacAddress:YES]; // default to yes to generate a mac address
        [self setShouldAutoGenerateODIN1Key:YES];
        [self setShouldAutoGenerateOpenUDIDKey:YES];
        // default to YES for ifa and ifv
        [self setShouldAutoGenerateVendorIdentifier:YES];
        [self setShouldAutoGenerateAdvertiserIdentifier:YES];
        
        // the user can turn these off before calling a method which will
        // remove the keys. turning them back on will regenerate the keys.
    }
    return self;
}

#pragma mark -
#pragma mark - Public Methods

- (NSDictionary *)sdkDataParameters
{
    return self.parameters;
}

- (BOOL)startTrackerWithAdvertiserId:(NSString *)aid advertiserKey:(NSString *)key withError:(NSError **)error
{
    BOOL hasError = NO;
    
    if(nil != aid)
    {
        [[MobileAppTracker sharedManager] setAdvertiserId:aid];
    }
    else
    {
        if (error)
        {
            NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:KEY_ERROR_MAT_ADVERTISER_ID_MISSING forKey:NSLocalizedFailureReasonErrorKey];
            [errorDetails setValue:@"No Advertiser Id passed in." forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:1101 userInfo:errorDetails];
            
            hasError = YES;
        }
    }
    if(nil != key)
    {
        [[MobileAppTracker sharedManager] setAdvertiserKey:key];
    }
    else
    {
        if (error)
        {
            NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:KEY_ERROR_MAT_ADVERTISER_KEY_MISSING forKey:NSLocalizedFailureReasonErrorKey];
            [errorDetails setValue:@"No Advertiser Key passed in." forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:1102 userInfo:errorDetails];
            
            hasError = YES;
        }
    }
    
    return hasError;
}

- (void)applicationDidOpenURL:(NSString *)urlString sourceApplication:(NSString *)sourceApplication
{
    // set the data into the params data so that the url is build with these
    //Application openUrl parms
    [self.parameters setValue:urlString forKey:KEY_EVENT_REFERRAL];
    [self.parameters setValue:sourceApplication forKey:KEY_SOURCE];
}

#pragma mark -
#pragma mark Track Action Methods

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
{
    [self trackActionForEventIdOrName:eventIdOrName
                            eventIsId:isId
                           eventItems:nil
                          referenceId:nil
                        revenueAmount:0
                         currencyCode:nil];
    
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;
{
    
    [self trackActionForEventIdOrName:eventIdOrName
                            eventIsId:isId
                           eventItems:nil
                          referenceId:nil
                        revenueAmount:revenueAmount
                         currencyCode:currencyCode];
    
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                        referenceId:(NSString *)refId;
{
    [self trackActionForEventIdOrName:eventIdOrName
                            eventIsId:isId
                           eventItems:nil
                          referenceId:refId
                        revenueAmount:0
                         currencyCode:nil];
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;
{
    
    [self trackActionForEventIdOrName:eventIdOrName
                            eventIsId:isId
                           eventItems:nil
                          referenceId:nil
                        revenueAmount:revenueAmount
                         currencyCode:currencyCode];
}
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                         eventItems:(NSArray *)eventItems;
{
    [self trackActionForEventIdOrName:eventIdOrName
                            eventIsId:isId
                           eventItems:eventItems
                          referenceId:nil
                        revenueAmount:0
                         currencyCode:nil];
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                         eventItems:(NSArray *)eventItems
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;
{
    [self trackActionForEventIdOrName:eventIdOrName
                            eventIsId:isId
                           eventItems:eventItems
                          referenceId:nil
                        revenueAmount:revenueAmount
                         currencyCode:currencyCode];
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId;
{
    [self trackActionForEventIdOrName:eventIdOrName
                            eventIsId:isId
                           eventItems:eventItems
                          referenceId:refId
                        revenueAmount:0
                         currencyCode:nil];
}

//----------------------------------------------------------
// Main Track Action called by other track actions
//
//----------------------------------------------------------
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;
{
    [self trackActionForEventIdOrName:eventIdOrName
                            eventIsId:isId
                           eventItems:eventItems
                          referenceId:refId
                        revenueAmount:revenueAmount
                         currencyCode:currencyCode
                     transactionState:IGNORE_IOS_PURCHASE_STATUS];
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
                   transactionState:(NSInteger)purchaseStatus
{
    [self.parameters setValue:[NSString stringWithFormat:@"%f", revenueAmount] forKey:KEY_REVENUE];
    
    // temporary override of currency in params
    if (currencyCode && currencyCode.length > 0)
    {
        [self.parameters setValue:currencyCode forKey:KEY_CURRENCY];
    }
    
    if(IGNORE_IOS_PURCHASE_STATUS != purchaseStatus)
    {
        [self.parameters setValue:[NSString stringWithFormat:@"%d", purchaseStatus] forKey:KEY_IOS_PURCHASE_STATUS];
    }
    
    // ************************************************
    // Start: Handle CWorks click and impression params
    // ************************************************
    
    // Note: set CWorks click param
    NSString *cworksClickKey = nil;
    NSNumber *cworksClickValue = nil;
    
    [self fetchCWorksClickKey:&cworksClickKey andValue:&cworksClickValue];
#if DEBUG_LOG
    NSLog(@"cworks=%@:%@", cworksClickKey, cworksClickValue);
#endif
    if(nil != cworksClickKey && nil != cworksClickValue)
    {
        [self.parameters setValue:cworksClickValue forKey:cworksClickKey];
    }
    
    // Note: set CWorks impression param
    NSString *cworksImpressionKey = nil;
    NSNumber *cworksImpressionValue = nil;
    
    [self fetchCWorksImpressionKey:&cworksImpressionKey andValue:&cworksImpressionValue];
#if DEBUG_LOG
    NSLog(@"cworks imp=%@:%@", cworksImpressionKey, cworksImpressionValue);
#endif
    if(nil != cworksImpressionKey && nil != cworksImpressionValue)
    {
        [self.parameters setValue:cworksImpressionValue forKey:cworksImpressionKey];
    }
    
    // ************************************************
    // End: Handle CWorks click and impression params
    // ************************************************
    
    
    [self initVariablesForTrackAction:eventIdOrName eventIsId:isId];
    [self buildUrlRequest:eventItems referenceId:refId];
    
    // reset currency code to default
    [self.parameters setValue:self.defaultCurrencyCode forKey:KEY_CURRENCY];
    
    // by default do not include revenue amount
    [self.parameters removeObjectForKey:KEY_REVENUE];
    
    // by default do not include iOS purchase status param
    [self.parameters removeObjectForKey:KEY_IOS_PURCHASE_STATUS];
    
    // by default do not include reference id
    [self.parameters removeObjectForKey:KEY_REF_ID];
    
    if(nil != cworksClickKey && nil != cworksClickValue)
    {
        // remove CWorks click key after it has been used
        [self.parameters removeObjectForKey:cworksClickKey];
    }
    
    if(nil != cworksImpressionKey && nil != cworksImpressionValue)
    {
        // remove CWorks impression key after it has been used
        [self.parameters removeObjectForKey:cworksImpressionKey];
    }
}

#pragma mark -
#pragma mark Track Update Methods


- (void)trackInstall
{
    [self trackInstallWithReferenceId:nil];
}

- (void)trackUpdate
{
    [self trackUpdateWithReferenceId:nil];
}

- (void)trackInstallWithReferenceId:(NSString *)refId
{
    [self trackInstallWithUpdateOnly:NO
                         referenceId:refId];
}

- (void)trackUpdateWithReferenceId:(NSString *)refId
{
    [self trackInstallWithUpdateOnly:YES
                         referenceId:refId];
}

- (void)trackInstallWithUpdateOnly:(BOOL)updateOnly
                       referenceId:(NSString *)refId
{
    // get some information about our marker
    NSString * bundleVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:KEY_CFBUNDLEVERSION];
    BOOL markerExists = ([MATUtils userDefaultValueforKey:KEY_MAT_APP_VERSION] == nil) ? NO : YES;
    BOOL versionsEqual = ([bundleVersion isEqualToString:[MATUtils userDefaultValueforKey:KEY_MAT_APP_VERSION]]) ? YES : NO;
    
    // if updateOnly, if a marker is present or not, record and update
    // and set the marker without recording an install
    if (updateOnly)
    {
        // if we don't have a marker or the versions aren't equal
        // do a trackAction=update
        if ( (!markerExists) || (!versionsEqual))
        {
            // send a trackAction=update
            [self trackActionForEventIdOrName:EVENT_UPDATE
                                    eventIsId:NO
                                  referenceId:refId];
            
            // record the bundle version
            [MATUtils setUserDefaultValue:bundleVersion forKey:KEY_MAT_APP_VERSION];
            
            if (!markerExists)
            {
                [self createInstallMarker];
            }
            
            NSString *result = @"UpdateOnly: bundle versions were not equal or no install existed.";
            [self notifyDelegateSuccessMessage:result];
        }
        else
        {
            NSString *result = @"No Update action sent: bundle versions are equal.";
            [self notifyDelegateSuccessMessage:result];
        }
    }
    else // update or install
    {
        if (!markerExists)  // no marker so it must be an install
        {
            if (![self checkTracking:refId])
            {
                [self trackActionForEventIdOrName:EVENT_INSTALL
                                        eventIsId:NO
                                      referenceId:refId];
            }
            else
            {
                NSString *result = @"No Install or Update sent: cookie tracking is on.";
                [self notifyDelegateSuccessMessage:result];
            }
            
            // create a marker for the install
            // record the bundle version
            [MATUtils setUserDefaultValue:bundleVersion forKey:KEY_MAT_APP_VERSION];
            
            [self createInstallMarker];
            
            NSString *result = @"Install action sent: no previous install existed.";
            [self notifyDelegateSuccessMessage:result];
        }
        else if (!versionsEqual) // just record update
        {
            // send a trackAction=update
            [self trackActionForEventIdOrName:EVENT_UPDATE
                                    eventIsId:NO
                                  referenceId:refId];
            
            // just set a marker for the updated version
            [MATUtils setUserDefaultValue:bundleVersion forKey:KEY_MAT_APP_VERSION];
            
            NSString *result = @"Update action Sent: previous install exists and bundle versions are not equal.";
            [self notifyDelegateSuccessMessage:result];
        }
        else
        {
            NSString *result = @"No Install or Update action sent: previous install was sent.";
            [self notifyDelegateSuccessMessage:result];
        }
    }
}

#pragma mark - MAT Delegate Callback Helper Methods

- (void)notifyDelegateSuccessMessage:(NSString *)message
{
    if ([self.delegate respondsToSelector:@selector(mobileAppTracker:didSucceedWithData:)])
    {
        [self.delegate mobileAppTracker:self didSucceedWithData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void)notifyDelegateFailureWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(mobileAppTracker:didFailWithError:)])
    {
        [self.delegate mobileAppTracker:self didFailWithError:error];
    }
}

//-----------------------------
// CreateInstallMarker
// Creates the necessary data in user defaults to track a first install
//-----------------------------
- (void)createInstallMarker
{
    // record the install_date
    [MATUtils setUserDefaultValue:[MATUtils formattedCurrentDateTime] forKey:KEY_INSTALL_DATE];
    [self.parameters setValue:[MATUtils userDefaultValueforKey:KEY_INSTALL_DATE] forKey:KEY_INSDATE];
}

#pragma mark -
#pragma mark Manually Start Tracking Sessions

- (void)setTracking:(NSString*)targetAppId
       advertiserId:(NSString*)advertiserId
            offerId:(NSString*)offerId
        publisherId:(NSString *)publisherId
           redirect:(BOOL)shouldRedirect
{
    [MATUtils startTrackingSessionForTargetBundleId:targetAppId
                                  publisherBundleId:[MATUtils bundleId]
                                       advertiserId:advertiserId
                                         campaignId:offerId
                                        publisherId:publisherId
                                           redirect:shouldRedirect
                                 connectionDelegate:self];
}

#pragma mark -
#pragma mark Public Setters

- (void)setSiteId:(NSString *)site_id
{
    [self.parameters setValue:site_id forKey:KEY_SITE_ID];
}

- (void)setAdvertiserId:(NSString *)advertiser_id
{
    [self.parameters setValue:advertiser_id forKey:KEY_ADVERTISER_ID];
}

- (void)setAdvertiserKey:(NSString *)advertiser_key
{
    [self.parameters setValue:advertiser_key forKey:KEY_KEY];
}

- (void)setCurrencyCode:(NSString *)currency_code
{
    self.defaultCurrencyCode = currency_code;
    // if it's passed in, set it in the parameters
    [self.parameters setValue:currency_code forKey:KEY_CURRENCY];
}

- (void)setUserId:(NSString *)user_id
{
    [self.parameters setValue:user_id forKey:KEY_USER_ID];
}

- (void)setPackageName:(NSString *)package_name
{
    [self.parameters setValue:package_name forKey:KEY_PACKAGE_NAME];
}

- (void)setRedirectUrl:(NSString *)redirect_url
{
    [self.parameters setValue:redirect_url forKey:KEY_REDIRECT_URL];
}

- (void)setDeviceId:(NSString *)device_id
{
    [self.parameters setValue:device_id forKey:KEY_DEVICE_ID];
}

- (void)setOpenUDID:(NSString *)open_udid
{
    [self.parameters setValue:open_udid forKey:KEY_OPEN_UDID];
}

- (void)setTrusteTPID:(NSString *)truste_tpid
{
    [self.parameters setValue:truste_tpid forKey:KEY_TRUSTE_TPID];
}

- (void)setAdvertiserIdentifier:(NSUUID *)advertiser_identifier
{
    [self.parameters setValue:advertiser_identifier forKey:KEY_IOS_IFA];
    
    ASIdentifierManager *adMgr = [ASIdentifierManager sharedManager];
    [self.parameters setValue:[NSString stringWithFormat:@"%d", adMgr.advertisingTrackingEnabled] forKey:KEY_IOS_AD_TRACKING];
}

- (void)setVendorIdentifier:(NSUUID * )vendor_identifier
{
    [self.parameters setValue:vendor_identifier forKey:KEY_IOS_IFV];
}

- (void)setUseHTTPS:(BOOL)yesorno
{
    self.shouldUseHTTPS = yesorno;
}

- (void)setUseCookieTracking:(BOOL)yesorno
{
    self.shouldUseCookieTracking = yesorno;
}

//***
// These sets will generate or remove auto generated values
//***
- (void)setShouldAutoGenerateMacAddress:(BOOL)yesorno
{
    self.shouldGenerateMacAddress = yesorno;
    if (!yesorno)
    {
        [self.parameters removeObjectForKey:KEY_MAC_ADDRESS];
    }
    else
    {
        // re-generate the key
        [self.parameters setValue:[MATUtils getMacAddress] forKey:KEY_MAC_ADDRESS];
    }
}

- (void)setShouldAutoGenerateODIN1Key:(BOOL)yesorno
{
    self.shouldGenereateODIN1Key = yesorno;
    
    if (!yesorno)
    {
        [self.parameters removeObjectForKey:KEY_ODIN];
    }
    else
    {
        NSString * odin1Id = [MATUtils generateODIN1String];
        if (odin1Id)
        {
            [self.parameters setValue:odin1Id forKey:KEY_ODIN];
        }
    }
}

- (void)setShouldAutoGenerateOpenUDIDKey:(BOOL)yesorno
{
    self.shouldGenerateOpenUDIDKey = yesorno;
    
    if (!yesorno)
    {
        [self.parameters removeObjectForKey:KEY_OPEN_UDID];
    }
    else
    {
        NSString *openUDID = [MATUtils getOpenUDID];
        if (openUDID)
        {
            [self.parameters setValue:openUDID forKey:KEY_OPEN_UDID];
        }
    }
}

- (void)setShouldAutoGenerateVendorIdentifier:(BOOL)yesorno
{
    self.shouldGenerateVendorIdentifier = yesorno;
    if (!yesorno)
    {
        [self.parameters removeObjectForKey:KEY_IOS_IFV];
    }
    else
    {
        if ([[UIDevice currentDevice]respondsToSelector:@selector(identifierForVendor)])
        {
            NSString *uuidStr = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
            if (uuidStr && ![uuidStr isEqualToString:KEY_GUID_EMPTY])
            {
                [self.parameters setValue:uuidStr forKey:KEY_IOS_IFV];
            }
        }
    }
}

- (void)setShouldAutoGenerateAdvertiserIdentifier:(BOOL)yesorno
{
    self.shouldGenerateAdvertiserIdentifier = yesorno;
    if (!yesorno)
    {
        [self.parameters removeObjectForKey:KEY_IOS_IFA];
    }
    else
    {
        ASIdentifierManager *adMgr = [ASIdentifierManager sharedManager];
        NSString *uuidStr = [adMgr.advertisingIdentifier UUIDString];
        if (uuidStr && ![uuidStr isEqualToString:KEY_GUID_EMPTY])
        {
            [self.parameters setValue:uuidStr forKey:KEY_IOS_IFA];
        }
        
        [self.parameters setValue:[NSString stringWithFormat:@"%d", adMgr.advertisingTrackingEnabled] forKey:KEY_IOS_AD_TRACKING];
    }
}

- (void)setShouldDebugResponseFromServer:(BOOL)yesorno;
{
    [MATConnectionManager sharedManager].shouldDebug = yesorno;
}

- (void)setShouldAllowDuplicateRequests:(BOOL)yesorno;
{
    [MATConnectionManager sharedManager].shouldAllowDuplicates = yesorno;
}

#pragma mark -
#pragma mark Private Methods

/// returns YES if cookie based tracking worked
- (BOOL)checkTracking:(NSString*)refId
{
    if (self.shouldUseCookieTracking)
    {
        [self initVariablesForTrackAction:EVENT_INSTALL eventIsId:NO];
        NSString * link = [self requestLink:refId encryptionLevel:HIGHLY_ENCRYPTED ignoreParams:nil];
        
        if ([MATConnectionManager sharedManager].shouldDebug)
        {
            link = [link stringByAppendingFormat:@"&%@=1", KEY_DEBUG];
        }
        if ([MATConnectionManager sharedManager].shouldAllowDuplicates)
        {
            link = [link stringByAppendingFormat:@"&%@=1", KEY_SKIP_DUP];
        }
        
        NSURL * url = [NSURL URLWithString:link];
        [[UIApplication sharedApplication] openURL:url];
        
        return YES;
    }
    else
    {
        if ([MATUtils isTrackingSessionStartedForTargetApplication:[MATUtils bundleId]])
        {
            NSString * sessionDateTime = [MATUtils getSessionDateTime];
            [self.parameters setValue:sessionDateTime forKey:KEY_SESSION_DATETIME];
            
            NSString * trackingId = [MATUtils getTrackingId];
            [self.parameters setValue:trackingId forKey:KEY_TRACKING_ID];
            
            [MATUtils stopTrackingSession];
        }
    }
    
    return NO;
}

- (void)initVariablesForTrackAction:(NSString *)eventIdOrName eventIsId:(BOOL)isId
{
    //Check if predetermined types
    NSString *tempEventIdOrName = [eventIdOrName lowercaseString];
    
    [self.parameters setValue:nil forKey:KEY_SITE_EVENT_NAME];
    [self.parameters setValue:nil forKey:KEY_SITE_EVENT_ID]; //clear cached names and ids
    
    if([[self.parameters objectForKey:KEY_STAGING] boolValue])
    {
        if (self.shouldUseCookieTracking && [tempEventIdOrName isEqualToString:EVENT_INSTALL])
        {
            self.serverPath = SERVER_DOMAIN_COOKIE_TRACKING;
        }
        else
        {
            //http://api.dev.platform.hasservers.com/server?
            //self.serverPath = @"http://api.dev.platform.hasservers.com";
            //self.serverPath = [NSString stringWithFormat:@"http://%@.dev.engine.mobileapptracking.com", [self.parameters objectForKey:@"KEY_ADVERTISER_ID"]]; //staging
            self.serverPath = [NSString stringWithFormat:@"%@://%@.%@", KEY_HTTP, [self.parameters objectForKey:KEY_ADVERTISER_ID], SERVER_DOMAIN_REGULAR_TRACKING_STAGE];
        }
    }
    else
    {
        if (self.shouldUseCookieTracking && [tempEventIdOrName isEqualToString:EVENT_INSTALL])
        {
            self.serverPath = SERVER_DOMAIN_COOKIE_TRACKING;
        }
        else
        {
            self.serverPath = [NSString stringWithFormat:@"%@://%@.%@", KEY_HTTP, [self.parameters objectForKey:KEY_ADVERTISER_ID], SERVER_DOMAIN_REGULAR_TRACKING_PROD];
        }
    }
    
    //Check if HTTPS is turned on
    if(self.shouldUseHTTPS)
    {
        self.serverPath = [self.serverPath stringByReplacingOccurrencesOfString:KEY_HTTP withString:KEY_HTTPS];
    }
    
    // check for built in event names
    if ( [tempEventIdOrName isEqualToString:EVENT_INSTALL] ||
        [tempEventIdOrName isEqualToString:EVENT_UPDATE] ||
        [tempEventIdOrName isEqualToString:EVENT_OPEN] ||
        [tempEventIdOrName isEqualToString:EVENT_CLOSE] )
    {
        [self.parameters setValue:tempEventIdOrName forKey:KEY_ACTION];
    }
    else // this is a conversion event, use the isId to determine from the developer if this is id or name
    {
        [self.parameters setValue:EVENT_CONVERSION forKey:KEY_ACTION];  // set action to conversion
        
        NSString *strKeyIdOrName = isId ? KEY_SITE_EVENT_ID : KEY_SITE_EVENT_NAME;
        
        [self.parameters setValue:eventIdOrName forKey:strKeyIdOrName];
    }
    
    [self.parameters setValue:[MATUtils formattedCurrentDateTime] forKey:KEY_SYSTEM_DATE];//set time
}

//Constructs URL
- (NSString*)urlStringForParams:(NSDictionary*)params path:(NSString*)path encryptionLevel:(NSString*)encryptionLevel ignoreParams:(NSSet*)ignoreParams
{
    // advertiser key to be used for encrypting the request url data
    NSString* encryptKey = [self.parameters objectForKey:KEY_KEY];
    
    // part of the url that does not need encryption
    NSMutableString* nonEncryptedParams = [NSMutableString stringWithCapacity:200];
    
    // part of the url that needs encryption
    NSMutableString* encryptedParams = [NSMutableString stringWithCapacity:400];
    
    // get the list of params that should not be encrypted for the given encryption level
    NSSet* doNotEncryptSet = [self.doNotEncryptDict valueForKey:encryptionLevel];
    
    // handle each key in the sdk parameters
    for (NSString* key in [params allKeys])
    {
        // special handling of KEY_PACKAGE_NAME
        if(0 == [key compare:KEY_PACKAGE_NAME])
        {
            // add to unencrypted params
            [nonEncryptedParams appendFormat:@"&%@=%@", key, [params objectForKey:key]];
            
            // add to encrypted params
            [encryptedParams appendFormat:@"&%@=%@", key, [params objectForKey:key]];
        }
        // decide if the key should be included in the request url
        else if ([self shouldUseParam:key] && (!ignoreParams || ![ignoreParams containsObject:key]))
        {
            // separate the keys in two groups: with encryption and without encryption
            NSMutableString *curParams = [doNotEncryptSet containsObject:key] ? nonEncryptedParams : encryptedParams;
            [curParams appendFormat:@"&%@=%@", key, [params objectForKey:key]];
        }
    }
    
#if DEBUG_LOG
    NSLog(@"data to be encrypted: %@", encryptedParams);
#endif
    
    // encrypt the params
    NSString* encryptedData = [MATEncrypter encryptString:encryptedParams withKey:encryptKey];
    
    // create the final url string by appending the unencrypted and encrypted params
    NSString* urlString = [[NSString stringWithFormat:@"%@/%@%@&%@=%@", self.serverPath, path, nonEncryptedParams, KEY_DATA, encryptedData] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    // clean out the application openURL keys
    [self resetApplicationOpenUrlKeys];
    
    return urlString;
}

- (NSString*)requestLink:(NSString*)refId encryptionLevel:(NSString*)encryptionLevel ignoreParams:(NSSet*)ignoreParams
{
    NSMutableDictionary * parametersCopy = [NSMutableDictionary dictionaryWithDictionary:self.parameters];
    
    if (refId)
    {
        [parametersCopy setValue:refId forKey:KEY_REF_ID];
    }
    
    NSString *strPath = [NSString stringWithFormat:@"%@?", SERVER_PATH_TRACKING_ENGINE];
    NSString *link = [self urlStringForParams:parametersCopy path:strPath encryptionLevel:encryptionLevel ignoreParams:ignoreParams];
    
    return link;
}

// test if key should be used in url - this is to eliminate application openUrl keys
- (BOOL)shouldUseParam:(NSString *)paramKey
{
    BOOL useParam = YES;
    
    if ([[paramKey lowercaseString] isEqualToString:KEY_EVENT_REFERRAL] ||
        [[paramKey lowercaseString] isEqualToString:KEY_SOURCE])
    {
        NSString *temp = [self.parameters valueForKey:paramKey];
        
        // use this key only if some value has been set for the key
        useParam = temp.length > 0;
    }
    // always return yes for any other param
    return useParam;
}

- (void)resetApplicationOpenUrlKeys
{
    [self.parameters setValue:STRING_EMPTY forKey:KEY_EVENT_REFERRAL];
    [self.parameters setValue:STRING_EMPTY forKey:KEY_SOURCE];
}

//Begings query from string
-(void)buildUrlRequest:(NSArray *)params referenceId:(NSString*)refId
{
    //----------------------------
    // Always look for a facebook cookie
    // because it could change often
    //----------------------------
    [self loadFacebookCookieId];
    
    NSSet * ignoreParams = [NSSet setWithObjects:KEY_REDIRECT_URL, KEY_KEY, nil];
    NSString * link = [self requestLink:refId encryptionLevel:NORMALLY_ENCRYPTED ignoreParams:ignoreParams];
    
#if DEBUG_REQUEST_LOG
    NSLog(@"%@", link);
#endif
    
    //Check if params is nil
    if(params)
    {
        NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:params, KEY_DATA, nil];
        [[MATConnectionManager sharedManager] beginUrlRequest:link andData:[[MATJSONSerializer serializer] serializeDictionary:dict] withDelegate:self];
    }
    else
    {
        [[MATConnectionManager sharedManager] beginUrlRequest:link andData:nil withDelegate:self];
    }
}

// loads a facebook cookie into the parameters
- (void)loadFacebookCookieId
{
    NSString * fbCookieId = [MATUtils generateFBCookieIdString];
    if (fbCookieId)
    {
        [self.parameters setValue:fbCookieId forKey:KEY_FB_COOKIE_ID];
#if DEBUG_REMOTE_LOG
        NSString * logString = [NSString stringWithFormat:@"fb_cookie=%@", fbCookieId];
        [self.remoteLogger log:logString];
#endif
    }
#if DEBUG_REMOTE_LOG
    else
    {
        [self.parameters setValue:STRING_EMPTY forKey:KEY_FB_COOKIE_ID];
        [self.remoteLogger log:@"no_fb_cookie_found"];
    }
#endif
}

- (void)loadParametersData
{
    NSDictionary * plist =[[NSBundle mainBundle] infoDictionary];
    
    if([MATUtils userDefaultValueforKey:KEY_MAT_ID])
    {
        [self.parameters setValue:[MATUtils userDefaultValueforKey:KEY_MAT_ID] forKey:KEY_MAT_ID];
    }
    else {
        NSString * GUID = [MATUtils getUUID];
        [MATUtils setUserDefaultValue:GUID forKey:KEY_MAT_ID];
        [self.parameters setValue:GUID forKey:KEY_MAT_ID];
    }
    
    // Device params
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString * machineName = [NSString stringWithCString:systemInfo.machine
                                                encoding:NSUTF8StringEncoding];
    
    
    [self.parameters setValue:machineName forKey:KEY_DEVICE_MODEL];
    
    CTTelephonyNetworkInfo * carrier = [[CTTelephonyNetworkInfo alloc] init];
    NSString * carrierString = [[carrier subscriberCellularProvider]carrierName];
    if (carrierString)
    {
        NSString * carrierEncodedString = [carrierString urlEncodeUsingEncoding:NSUTF8StringEncoding];
        [self.parameters setValue:carrierEncodedString forKey:KEY_DEVICE_CARRIER];
    }
    
    NSString *mobileCountryCode = [[carrier subscriberCellularProvider] mobileCountryCode];
    NSString *mobileCountryCodeISO = [[carrier subscriberCellularProvider] isoCountryCode];
    NSString *mobileNetworkCode = [[carrier subscriberCellularProvider] mobileNetworkCode];
    
    if (mobileCountryCode)
    {
        NSString *mobileCountryCodeEncoded = [mobileCountryCode urlEncodeUsingEncoding:NSUTF8StringEncoding];
        [self.parameters setValue:mobileCountryCodeEncoded forKey:KEY_CARRIER_COUNTRY_CODE];
    }
    
    if (mobileCountryCodeISO)
    {
        NSString *mobileCountryCodeISOEncoded = [mobileCountryCodeISO urlEncodeUsingEncoding:NSUTF8StringEncoding];
        [self.parameters setValue:mobileCountryCodeISOEncoded forKey:KEY_CARRIER_COUNTRY_CODE_ISO];
    }
    
    if (mobileNetworkCode)
    {
        NSString *mobileNetworkCodeEncoded = [mobileNetworkCode urlEncodeUsingEncoding:NSUTF8StringEncoding];
        [self.parameters setValue:mobileNetworkCodeEncoded forKey:KEY_CARRIER_NETWORK_CODE];
    }
    
    [carrier release]; carrier = nil;
    
    [self.parameters setValue:KEY_APPLE forKey:KEY_DEVICE_BRAND];
    
    //App params
    [self.parameters setValue:[MATUtils bundleId] forKey:KEY_PACKAGE_NAME];
    [self.parameters setValue:[plist objectForKey:KEY_CFBUNDLENAME] forKey:KEY_APP_NAME];
    [self.parameters setValue:[plist objectForKey:KEY_CFBUNDLEVERSION] forKey:KEY_APP_VERSION];
    
    //Other params
    [self.parameters setValue:[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode] forKey:KEY_COUNTRY_CODE];
    [self.parameters setValue:[[UIDevice currentDevice] systemVersion] forKey:KEY_OS_VERSION];
    [self.parameters setValue:[[NSLocale preferredLanguages] objectAtIndex:0] forKeyPath:KEY_LANGUAGE];
    [self.parameters setValue:[MATUtils userDefaultValueforKey:KEY_INSTALL_DATE] forKey:KEY_INSDATE];
    
    //Internal
    [self.parameters setValue:KEY_IOS forKey:KEY_SDK];
    [self.parameters setValue:MATVERSION forKey:KEY_VER];
    
    //User agent : perform this method on the main thread, since it creates a UIWebView.
    __block NSString *userAgent = STRING_EMPTY;
    dispatch_async(dispatch_get_main_queue(),
                  ^{
                      userAgent = [MATUtils generateUserAgentString];
                      [self.parameters setValue:userAgent forKey:KEY_CONVERSION_USER_AGENT];
                  });//end block
    
    // FB cookie id
    [self loadFacebookCookieId];
    
    //Application openUrl parms
    // initialized to empty so we don't pass them each time
    [self resetApplicationOpenUrlKeys];
    
    // only generate a mac address if yes
    if (self.shouldGenerateMacAddress)
    {
        [self.parameters setValue:[MATUtils getMacAddress] forKey:KEY_MAC_ADDRESS];
    }
    
    //ODIN1 id
    if (self.shouldGenereateODIN1Key)
    {
        NSString * odin1Id = [MATUtils generateODIN1String];
        if (odin1Id)
        {
            [self.parameters setValue:odin1Id forKey:KEY_ODIN];
        }
    }
    
    //OpenUDID
    if (self.shouldGenerateOpenUDIDKey)
    {
        NSString *openUDID = [MATUtils getOpenUDID];
        if (openUDID)
        {
            [self.parameters setValue:openUDID forKey:KEY_OPEN_UDID];
        }
    }
    
    // Currency code
    if (!self.defaultCurrencyCode)
    {
        // default to USD for currency code
        self.defaultCurrencyCode = KEY_CURRENCY_USD;
    }
    
    //init doNotEncrypt set
    NSSet * doNotEncryptForNormalLevelSet = [NSSet setWithObjects:KEY_ADVERTISER_ID, KEY_SITE_ID, KEY_DOMAIN, KEY_ACTION,
                                             KEY_SITE_EVENT_ID, KEY_SDK, KEY_VER, KEY_KEY_INDEX, KEY_SITE_EVENT_NAME,
                                             KEY_EVENT_REFERRAL, KEY_SOURCE, KEY_TRACKING_ID, KEY_PACKAGE_NAME, nil];
    NSSet * doNotEncryptForHighLevelSet = [NSSet setWithObjects:KEY_ADVERTISER_ID, KEY_SITE_ID, KEY_SDK, KEY_ACTION, KEY_PACKAGE_NAME, nil];
    NSDictionary * doNotEncryptDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       doNotEncryptForNormalLevelSet, NORMALLY_ENCRYPTED,
                                       doNotEncryptForHighLevelSet, HIGHLY_ENCRYPTED, nil];
    
    self.doNotEncryptDict = doNotEncryptDict;
    
    // fire up the connection manager
    [MATConnectionManager sharedManager];
    
    if ([MATUtils checkJailBreak])
    {
        [self.parameters setValue:@"1" forKey:KEY_OS_JAILBROKE];
    }
}

#pragma mark -

- (void)dealloc {
    [MATConnectionManager destroyManager];
    self.doNotEncryptDict = nil;
    self.parameters = nil;
#if DEBUG_REMOTE_LOG
    [_remoteLogger release]; _remoteLogger = nil;
#endif
    [super dealloc];
    
}

#pragma mark -
#pragma mark CWorks Method Calls

- (void)fetchCWorksClickKey:(NSString **)key andValue:(NSNumber **)value
{
    // Note: MAT_getClicks() method also deletes the stored click key/value
    NSDictionary *dict = [MATCWorks MAT_getClicks:[MATUtils bundleId]];
    
    if([dict count] > 0)
    {
        *key = [NSString stringWithFormat:@"cworks_click[%@]", [[dict allKeys] objectAtIndex:0]];
        *value = dict[[[dict allKeys] objectAtIndex:0]];
    }
}

- (void)fetchCWorksImpressionKey:(NSString **)key andValue:(NSNumber **)value
{
    // Note: MAT_getImpressions() method also deletes the stored impression key/value
    NSDictionary *dict = [MATCWorks MAT_getImpressions:[MATUtils bundleId]];
    
    if([dict count] > 0)
    {
        *key = [NSString stringWithFormat:@"cworks_impression[%@]", [[dict allKeys] objectAtIndex:0]];
        *value = dict[[[dict allKeys] objectAtIndex:0]];
    }
}

#pragma mark -
#pragma mark ConnectionManagerDelegate protocol methods

- (void)connectionManager:(MATConnectionManager *)manager didSucceedWithData:(NSData *)data
{
    if([self.delegate respondsToSelector:@selector(mobileAppTracker:didSucceedWithData:)])
    {
        [self.delegate mobileAppTracker:self didSucceedWithData:data];
    }
}

- (void)connectionManager:(MATConnectionManager *)manager didFailWithError:(NSError *)error
{
    if([self.delegate respondsToSelector:@selector(mobileAppTracker:didFailWithError:)])
    {
        [self.delegate mobileAppTracker:self didFailWithError:error];
    }
}

@end
