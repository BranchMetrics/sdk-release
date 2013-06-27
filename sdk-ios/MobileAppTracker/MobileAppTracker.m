//
//  MobileAppTracker.m
//  MobileAppTracker
//
//  Created by HasOffers on 04/08/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
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
@property (nonatomic, assign) BOOL shouldDetectJailbroken;
@property (nonatomic, assign) BOOL shouldGenerateMacAddress;
@property (nonatomic, assign) BOOL shouldGenereateODIN1Key;
@property (nonatomic, assign) BOOL shouldGenerateOpenUDIDKey;
@property (nonatomic, assign) BOOL shouldGenerateVendorIdentifier;
@property (nonatomic, assign) BOOL shouldGenerateAdvertiserIdentifier;

#if DEBUG_REMOTE_LOG
    @property (nonatomic, retain) RemoteLogger * remoteLogger;
#endif

- (NSString*)urlStringForServerUrl:(NSString *)serverUrl
                              path:(NSString *)path
                            params:(NSDictionary*)params
                      ignoreParams:(NSSet*)ignoreParams
                   encryptionLevel:(NSString*)encryptionLevel;

- (NSString*)prepareUrlWithReferenceId:(NSString*)refId encryptionLevel:(NSString*)encryptionLevel ignoreParams:(NSSet*)ignoreParams;
- (NSString*)prepareUrlWithReferenceId:(NSString*)refId encryptionLevel:(NSString*)encryptionLevel ignoreParams:(NSSet*)ignoreParams isOpenEvent:(BOOL)isOpenEvent;
- (void)sendRequestWithEventItems:(NSArray *)params referenceId:(NSString*)refId isOpenEvent:(BOOL)isOpenEvent;
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

// Methods to handle install_log_id response
- (void)handleInstallLogId:(NSMutableDictionary *)params;
- (void)failedToRequestInstallLogId:(NSMutableDictionary *)params withError:(NSError *)error;

@end

@implementation MobileAppTracker

@synthesize parameters = _parameters;
@synthesize delegate = _delegate;
@synthesize doNotEncryptDict = _doNotEncryptDict;
@synthesize serverPath = _serverPath;
@synthesize defaultCurrencyCode = _defaultCurrencyCode;
@synthesize shouldUseHTTPS = _shouldUseHTTPS;
@synthesize shouldDetectJailbroken = _shouldDetectJailbroken;
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
        
        // this won't generate any auto params yet
        [self loadParametersData];
        
        // !!! very important to init some parms here
        [self setUseCookieTracking:NO];         // default to no for cookie based tracking
        [self setUseHTTPS:YES];
        [self setShouldAutoDetectJailbroken:YES];
        [self setShouldAutoGenerateMacAddress:YES]; // default to yes to generate a mac address
        [self setShouldAutoGenerateODIN1Key:YES];
        [self setShouldAutoGenerateOpenUDIDKey:YES];
        [self setShouldAutoGenerateAppleVendorIdentifier:YES];
        [self setShouldAutoGenerateAppleAdvertisingIdentifier:YES];
        
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

- (BOOL)startTrackerWithMATAdvertiserId:(NSString *)aid MATConversionKey:(NSString *)key withError:(NSError **)error
{
    BOOL hasError = NO;
    
    if(nil != aid)
    {
        [[MobileAppTracker sharedManager] setMATAdvertiserId:aid];
    }
    else
    {
        if (error)
        {
            NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:KEY_ERROR_MAT_ADVERTISER_ID_MISSING forKey:NSLocalizedFailureReasonErrorKey];
            [errorDetails setValue:@"No MAT Advertiser Id passed in." forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:1101 userInfo:errorDetails];
            
            hasError = YES;
        }
    }
    if(nil != key)
    {
        [[MobileAppTracker sharedManager] setMATConversionKey:key];
    }
    else
    {
        if (error)
        {
            NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:KEY_ERROR_MAT_CONVERSION_KEY_MISSING forKey:NSLocalizedFailureReasonErrorKey];
            [errorDetails setValue:@"No MAT Conversion Key passed in." forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:1102 userInfo:errorDetails];
            
            hasError = YES;
        }
    }
    
    if(!hasError)
    {
        // Observe app-did-become-active notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNotification:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
#if DEBUG_LOG
        NSLog(@"MAT.startTracker: call requestInstallLogId");
#endif
        [self requestInstallLogId];
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

#pragma mark - Notfication Handlers

- (void)handleNotification:(NSNotification *)notice
{
    if(0 == [notice.name compare:UIApplicationDidBecomeActiveNotification])
    {
#if DEBUG_LOG
        NSLog(@"MAT handleNotification.AppDidBecomeActive: call requestInstallLogId");
#endif
        [self requestInstallLogId];
    }
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
                        referenceId:(NSString *)refId
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
                       currencyCode:(NSString *)currencyCode
{
    
    [self trackActionForEventIdOrName:eventIdOrName
                            eventIsId:isId
                           eventItems:nil
                          referenceId:refId
                        revenueAmount:revenueAmount
                         currencyCode:currencyCode];
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                         eventItems:(NSArray *)eventItems
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
                       currencyCode:(NSString *)currencyCode
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
                        referenceId:(NSString *)refId
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
                       currencyCode:(NSString *)currencyCode
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
    [self trackActionForEventIdOrName:eventIdOrName
                            eventIsId:isId
                           eventItems:eventItems
                          referenceId:refId
                        revenueAmount:revenueAmount
                         currencyCode:currencyCode
                     transactionState:purchaseStatus
                       forceOpenEvent:NO];
}

// When forceOpenEvent is set install/update log_id check is skipped.
// forceOpenEvent applies only for OPEN events.
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                          eventIsId:(BOOL)isId
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
                   transactionState:(NSInteger)purchaseStatus
                     forceOpenEvent:(BOOL)forceOpenEvent
{
#if DEBUG_LOG
    NSLog(@"MAT trackAction: install/update log_id already present = %d", [self.parameters objectForKey:KEY_INSTALL_LOG_ID] || [self.parameters objectForKey:KEY_UPDATE_LOG_ID]);
#endif
    
    BOOL continueTrackAction = TRUE;
    
    // is this an OPEN event
    BOOL isOpenEvent = [[eventIdOrName lowercaseString] isEqualToString:EVENT_OPEN];
    
    // Do not check install_log_id -- only for open events with forceOpenEvent flag enabled.
    if(!(isOpenEvent && forceOpenEvent))
    {
        // is install_log_id already present
        BOOL isInstallLogIdAvailable = [self.parameters objectForKey:KEY_INSTALL_LOG_ID] || [self.parameters objectForKey:KEY_UPDATE_LOG_ID];
        
        // by default FALSE
        BOOL requestFiredInstallLogId = FALSE;
        
        // If the install_log_id is not available, then fire a request to download one.
        if(!isInstallLogIdAvailable)
        {
            // dictionary to store info about OPEN event
            NSMutableDictionary *dict = nil;
            
            // if it's an open event, then make sure that it is fired when the install_log_id request completes
            if(isOpenEvent)
            {
                // create a dictionary of current trackAction parameters
                dict = [NSMutableDictionary dictionary];
                [dict setValue:eventIdOrName forKey:@"eventIdOrName"];
                [dict setValue:[NSNumber numberWithBool:isId] forKey:@"eventIsId"];
                [dict setValue:eventItems forKey:@"eventItems"];
                [dict setValue:refId forKey:@"referenceId"];
                [dict setValue:[NSNumber numberWithFloat:revenueAmount] forKey:@"revenueAmount"];
                [dict setValue:currencyCode forKey:@"currencyCode"];
                [dict setValue:[NSNumber numberWithInteger:purchaseStatus] forKey:@"transactionCode"];
                [dict setValue:[NSNumber numberWithBool:YES] forKey:@"forceOpenEvent"];
            }
            
            // fire a request to download the install_log_id
            // and perform the current trackAction when the download is successful
            [self requestInstallLogIdWithOpenRequestParams:dict];
            
            requestFiredInstallLogId = TRUE;
        }
        
        // if this is an open event
        if(isOpenEvent)
        {
            // if there is no install_log_id request already in progress
            if(requestFiredInstallLogId)
            {
                continueTrackAction = FALSE;
#if DEBUG_LOG
                // request already in progress for install/update log_id and open event
                NSLog(@"MAT trackAction: OPEN event: requests already in progress for -->install_log_id-->open event");
#endif
            }
            else
            {
                NSError *errorShouldFireOpen = nil;
                BOOL shouldFireOpenEvent = [self shouldFireOpenEventCausedError:&errorShouldFireOpen];
                
                if(!shouldFireOpenEvent)
                {
                    continueTrackAction = FALSE;
                    
                    [self notifyDelegateFailureWithError:errorShouldFireOpen];
                }
#if DEBUG_LOG
                NSLog(@"MAT trackAction: OPEN event: shouldFireOpenEvent = %d", shouldFireOpenEvent);
#endif
            }
        }
    }
    
    // if the tracking request should continue
    if(continueTrackAction)
    {
#if DEBUG_LOG
        NSLog(@"Continue with normal trackAction... event = %@", eventIdOrName);
#endif
        
        // continue with normal trackAction
        
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
        
        // set the standard tracking request parameters
        [self initVariablesForTrackAction:eventIdOrName eventIsId:isId];
        
        // fire the tracking request
        [self sendRequestWithEventItems:eventItems referenceId:refId isOpenEvent:isOpenEvent];
        
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
    BOOL markerExists = nil != [MATUtils userDefaultValueforKey:KEY_MAT_APP_VERSION];
    BOOL versionsEqual = [bundleVersion isEqualToString:[MATUtils userDefaultValueforKey:KEY_MAT_APP_VERSION]];
    
    // If updateOnly is true, then only record an update.
    if (updateOnly)
    {
        // If the marker exists and the versions are equal then no update,
        // else trackAction = update.
        if (markerExists && versionsEqual)
        {
            NSString *result = @"No Update action sent: bundle versions are equal.";
            [self notifyDelegateSuccessMessage:result];
        }
        else
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
            
            NSString *result = [NSString stringWithFormat:@"UpdateOnly action sent: %@.", markerExists ? @"bundle versions were not equal" : @"no install existed"];
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
                NSString *result = @"No Install or Update action sent: cookie tracking is on.";
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
            NSString *result = @"No Install/Update action sent: Install/Update has already been tracked for this version.";
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

- (void)setJailbroken:(BOOL)yesorno
{
    [self.parameters setValue:[NSString stringWithFormat:@"%d", yesorno] forKey:KEY_OS_JAILBROKE];
}

- (void)setSiteId:(NSString *)site_id
{
    [self.parameters setValue:site_id forKey:KEY_SITE_ID];
}

- (void)setMATAdvertiserId:(NSString *)advertiser_id
{
    [self.parameters setValue:advertiser_id forKey:KEY_ADVERTISER_ID];
}

- (void)setMATConversionKey:(NSString *)conversion_key
{
    [self.parameters setValue:conversion_key forKey:KEY_KEY];
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

- (void)setOpenUDID:(NSString *)open_udid
{
    [self.parameters setValue:open_udid forKey:KEY_OPEN_UDID];
}

- (void)setTrusteTPID:(NSString *)truste_tpid
{
    [self.parameters setValue:truste_tpid forKey:KEY_TRUSTE_TPID];
}

- (void)setAppleAdvertisingIdentifier:(NSUUID *)advertising_identifier
{
    [self.parameters setValue:[advertising_identifier UUIDString] forKey:KEY_IOS_IFA];
    
    ASIdentifierManager *adMgr = [ASIdentifierManager sharedManager];
    [self.parameters setValue:[NSString stringWithFormat:@"%d", adMgr.advertisingTrackingEnabled] forKey:KEY_IOS_AD_TRACKING];
}

- (void)setAppleVendorIdentifier:(NSUUID * )vendor_identifier
{
    [self.parameters setValue:[vendor_identifier UUIDString] forKey:KEY_IOS_IFV];
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

- (void)setShouldAutoDetectJailbroken:(BOOL)yesorno
{
    self.shouldGenerateOpenUDIDKey = yesorno;
    
    if (!yesorno)
    {
        [self.parameters removeObjectForKey:KEY_OS_JAILBROKE];
    }
    else
    {
        [self.parameters setValue:[NSString stringWithFormat:@"%d", [MATUtils checkJailBreak]] forKey:KEY_OS_JAILBROKE];
    }
}

- (void)setShouldAutoGenerateAppleVendorIdentifier:(BOOL)yesorno
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

- (void)setShouldAutoGenerateAppleAdvertisingIdentifier:(BOOL)yesorno
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

- (void)setDebugMode:(BOOL)yesorno
{
    [MATConnectionManager sharedManager].shouldDebug = yesorno;
    [MATUtils setShouldDebug:yesorno];
    
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       if([MATConnectionManager sharedManager].shouldDebug)
                       {
                           UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                                           message:@"MAT Debug Mode Enabled. Use only when debugging, do not release with this enabled!!"
                                                                          delegate:nil
                                                                 cancelButtonTitle:@"OK"
                                                                 otherButtonTitles:nil];
                           [alert show];
                           [alert release];
                       }
                   });
}

- (void)setAllowDuplicateRequests:(BOOL)yesorno
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
        NSString * link = [self prepareUrlWithReferenceId:refId encryptionLevel:HIGHLY_ENCRYPTED ignoreParams:nil];
        
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
    
    if (self.shouldUseCookieTracking && [tempEventIdOrName isEqualToString:EVENT_INSTALL])
    {
        self.serverPath = SERVER_DOMAIN_COOKIE_TRACKING;
    }
    else
    {
        NSString *domainName = [MATUtils serverDomainName];
        
        self.serverPath = [NSString stringWithFormat:@"%@://%@.%@", KEY_HTTP, [self.parameters objectForKey:KEY_ADVERTISER_ID], domainName];
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
- (NSString*)urlStringForServerUrl:(NSString *)serverUrl
                              path:(NSString *)path
                            params:(NSDictionary*)params
                      ignoreParams:(NSSet*)ignoreParams
                   encryptionLevel:(NSString*)encryptionLevel
{
    // conversion key to be used for encrypting the request url data
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
        if([key isEqualToString:KEY_PACKAGE_NAME])
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
    return [[NSString stringWithFormat:@"%@/%@?%@&%@=%@", serverUrl, path, nonEncryptedParams, KEY_DATA, encryptedData] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString*)prepareUrlWithReferenceId:(NSString*)refId encryptionLevel:(NSString*)encryptionLevel ignoreParams:(NSSet*)ignoreParams
{
    return [self prepareUrlWithReferenceId:refId encryptionLevel:encryptionLevel ignoreParams:ignoreParams isOpenEvent:FALSE];
}

- (NSString*)prepareUrlWithReferenceId:(NSString*)refId encryptionLevel:(NSString*)encryptionLevel ignoreParams:(NSSet*)ignoreParams isOpenEvent:(BOOL)isOpenEvent
{
    NSMutableDictionary *parametersCopy = [NSMutableDictionary dictionaryWithDictionary:self.parameters];
    
    if (refId)
    {
        [parametersCopy setValue:refId forKey:KEY_REF_ID];
    }
    
#if DEBUG_LOG
    NSLog(@"MAT prepareUrl: isOpenEvent = %d, installLogId = %d, updateLogId = %d", isOpenEvent, nil != [self.parameters valueForKey:KEY_INSTALL_LOG_ID], nil != [self.parameters valueForKey:KEY_UPDATE_LOG_ID]);
#endif
    
    // Use serve_no_log endpoint only when: event = OPEN and install_log_id is not available.
    NSString *path = (!isOpenEvent
                      || [self.parameters valueForKey:KEY_INSTALL_LOG_ID]
                      || [self.parameters valueForKey:KEY_UPDATE_LOG_ID])
                    ? SERVER_PATH_TRACKING_ENGINE : SERVER_PATH_TRACKING_ENGINE_NO_LOG;

#if DEBUG_LOG
    NSLog(@"MAT prepareUrl: path = %@", path);
#endif
    
    NSString *urlString = [self urlStringForServerUrl:self.serverPath
                                                 path:path
                                               params:parametersCopy
                                         ignoreParams:ignoreParams
                                      encryptionLevel:encryptionLevel];
    
    // clean out the application openURL keys
    [self resetApplicationOpenUrlKeys];
    
    return urlString;
}

// test if key should be used in url - this is to eliminate application openUrl keys
- (BOOL)shouldUseParam:(NSString *)paramKey
{
    BOOL useParam = YES;
    
    NSString *paramLowerCase = [paramKey lowercaseString];
    
    if ([paramLowerCase isEqualToString:KEY_EVENT_REFERRAL] ||
        [paramLowerCase isEqualToString:KEY_SOURCE])
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

// Includes the eventItems and referenceId and fires the tracking request
-(void)sendRequestWithEventItems:(NSArray *)eventItems referenceId:(NSString*)refId isOpenEvent:(BOOL)isOpenEvent
{
    //----------------------------
    // Always look for a facebook cookie because it could change often.
    //----------------------------
    [self loadFacebookCookieId];
    
    NSSet * ignoreParams = [NSSet setWithObjects:KEY_REDIRECT_URL, KEY_KEY, nil];
    NSString * link = [self prepareUrlWithReferenceId:refId encryptionLevel:NORMALLY_ENCRYPTED ignoreParams:ignoreParams isOpenEvent:isOpenEvent];
    
#if DEBUG_REQUEST_LOG
    NSLog(@"%@", link);
#endif
    
    // serialized event items
    NSString *strEventItems = nil;
    
    // if present then serialize the eventItems
    if(eventItems)
    {
        NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:eventItems, KEY_DATA, nil];
        strEventItems = [[MATJSONSerializer serializer] serializeDictionary:dict];
    }
    
    // fire the event tracking request
    [[MATConnectionManager sharedManager] beginUrlRequest:link andEventItems:strEventItems withDelegate:self];
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
    // Create a dictionary from the app info.plist file.
    NSDictionary * plist =[[NSBundle mainBundle] infoDictionary];
    
    if([MATUtils userDefaultValueforKey:KEY_MAT_ID])
    {
        [self.parameters setValue:[MATUtils userDefaultValueforKey:KEY_MAT_ID] forKey:KEY_MAT_ID];
    }
    else
    {
        NSString * GUID = [MATUtils getUUID];
        [MATUtils setUserDefaultValue:GUID forKey:KEY_MAT_ID];
        [self.parameters setValue:GUID forKey:KEY_MAT_ID];
    }
    
    // Check if install or update log_id has been stored earlier.
    // First preference is to use the install_log_id,
    // failing which the update_log_id will be used.
    if([MATUtils userDefaultValueforKey:KEY_MAT_INSTALL_LOG_ID])
    {
        [self.parameters setValue:[MATUtils userDefaultValueforKey:KEY_MAT_INSTALL_LOG_ID] forKey:KEY_INSTALL_LOG_ID];
    }
    else if([MATUtils userDefaultValueforKey:KEY_MAT_UPDATE_LOG_ID])
    {
        [self.parameters setValue:[MATUtils userDefaultValueforKey:KEY_MAT_UPDATE_LOG_ID] forKey:KEY_UPDATE_LOG_ID];
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
}

#pragma mark -

- (void)dealloc
{
    // stop observing app-did-become-active notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
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
#pragma mark MATConnectionManagerDelegate protocol methods

- (void)connectionManager:(MATConnectionManager *)manager didSucceedWithData:(NSData *)data
{
    NSString *strData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

#if DEBUG_LOG
    NSLog(@"MAT: didSucceedWithData: = %@", strData);
#endif
    if(strData)
    {
        // Parse the json response to extract the values
        NSRange range1 = [strData rangeOfString:@"\"success\":true"];
        NSRange range2 = [strData rangeOfString:@"\"site_event_type\":\"open\""];
#if DEBUG_LOG
        NSLog(@"MAT: didSucceedWithData: range lengths: %d, %d", range1.length, range2.length);
#endif
        // if this is an open event request response
        if(range1.length > 0 && range2.length > 0)
        {
            [MATUtils setUserDefaultValue:[NSDate date] forKey:KEY_MAT_OPEN_EVENT_TIMESTAMP];
        }
        
        // if there is no stored install or update log_id
        else if(nil == [self.parameters valueForKey:KEY_INSTALL_LOG_ID]
                && nil == [self.parameters valueForKey:KEY_UPDATE_LOG_ID])
        {
#if DEBUG_LOG
            NSLog(@"MAT: didSucceedWithData: = %@", strData);
#endif
            // If this is the server response for an install action,
            // then try to extract the log_id by parsing the response data.
            
            // Parse the json response to extract the values
            NSRange range2_1 = [strData rangeOfString:@"\"site_event_type\":\"install\""];
            NSRange range2_2 = [strData rangeOfString:@"\"site_event_type\":\"update\""];
            NSRange range3 = [strData rangeOfString:@"\"log_id\":\""];
            
            BOOL eventSuccess = range1.length > 0;
            BOOL eventIsInstall = range2_1.length > 0;
            BOOL eventIsUpdate = range2_2.length > 0;
            BOOL eventContainsLogId = range3.length > 0;
            
#if DEBUG_LOG
            NSLog(@"MAT: didSucceedWithData: log_id found in server response: %d", eventSuccess && (eventIsInstall || eventIsUpdate) && eventContainsLogId);
#endif
            if(eventSuccess && (eventIsInstall || eventIsUpdate) && eventContainsLogId)
            {
                // regex to find the value of log_id json key
                NSString *pattern = @"(?<=\"log_id\":\")([\\w\\d\\-]+)\"";
             
                NSError *error = NULL;
                
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:&error];
                // find the regex match
                NSTextCheckingResult *match = [regex firstMatchInString:strData options:NSMatchingCompleted range:NSMakeRange(0, [strData length])];
                
                NSString *log_id = nil;
                
                // if the required match is found
                if(2 == [match numberOfRanges])
                {
                    // extract the install / update log_id
                    log_id = [strData substringWithRange:[match rangeAtIndex:1]];
                    
                    NSString *keyLogId = eventIsInstall > 0 ? KEY_INSTALL_LOG_ID : KEY_UPDATE_LOG_ID;
                    NSString *keyMATLogId = eventIsInstall > 0 ? KEY_MAT_INSTALL_LOG_ID : KEY_MAT_UPDATE_LOG_ID;
                    
                    // store the install log id
                    [self.parameters setValue:log_id forKey:keyLogId];
                    [MATUtils setUserDefaultValue:log_id forKey:keyMATLogId];
                }
#if DEBUG_LOG
                NSLog(@"regex_log_id = %@, type = %@", log_id, range2_1.length > 0 ? @"install" : @"update");
#endif
            }
        }
        
        if(range1.length > 0)
        {
            if([self.delegate respondsToSelector:@selector(mobileAppTracker:didSucceedWithData:)])
            {
                [self.delegate mobileAppTracker:self didSucceedWithData:data];
            }
        }
        else
        {
            NSRange range4 = [strData rangeOfString:@"\"success\":false"];
            if(range4.length > 0)
            {
                if([self.delegate respondsToSelector:@selector(mobileAppTracker:didFailWithError:)])
                {
                    NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
                    [errorDetails setValue:KEY_ERROR_MAT_SERVER_ERROR forKey:NSLocalizedFailureReasonErrorKey];
                    [errorDetails setValue:strData forKey:NSLocalizedDescriptionKey];
                    
                    NSError *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:1103 userInfo:errorDetails];
                    [self.delegate mobileAppTracker:self didFailWithError:error];
                }
            }
        }
        
        [strData release], strData = nil;
    }
}

- (void)connectionManager:(MATConnectionManager *)manager didFailWithError:(NSError *)error
{
    if([self.delegate respondsToSelector:@selector(mobileAppTracker:didFailWithError:)])
    {
        [self.delegate mobileAppTracker:self didFailWithError:error];
    }
}

#pragma mark - Open Event

- (BOOL)shouldFireOpenEventCausedError:(NSError **)error
{
    BOOL isNetworkReachable = [MATUtils isNetworkReachable];
    BOOL isInstallLogIdAvailable = TRUE;
    BOOL isAlreadyFiredToday = FALSE;
    
    if(isNetworkReachable)
    {
        isInstallLogIdAvailable = [self.parameters valueForKey:KEY_INSTALL_LOG_ID] || [self.parameters valueForKey:KEY_UPDATE_LOG_ID];
        
#if DEBUG_LOG
        NSLog(@"MAT shouldFireOpen: isInstallLogIdAvailable = %d", isInstallLogIdAvailable);
#endif
        
        // Skip the OPEN event, since it has no meaning without the presence of the install_log_id.
        if(isInstallLogIdAvailable)
        {
            NSDate *dtOld = [MATUtils userDefaultValueforKey:KEY_MAT_OPEN_EVENT_TIMESTAMP];
            NSDate *dtCurrent = [NSDate date];

#if DEBUG_LOG
            NSLog(@"MAT shouldFireOpen: dtOld = %@, dtCurrent = %@", dtOld, dtCurrent);
#endif
            // if the request has been fired earlier, then check the date
            if(dtOld)
            {
                // Make sure that the request to fetch the install_log_id was not fired today.
                // Note: checks difference in dates, does not check 24 hours.
                
                // If an "open" event has already been fired TODAY then ignore this event.
                
#if DEBUG_LOG
                NSLog(@"MAT shouldFireOpen: last fired diff in days = %d", [MATUtils daysBetweenDate:dtCurrent andDate:dtOld]);
#endif
                
                isAlreadyFiredToday = [MATUtils daysBetweenDate:dtCurrent andDate:dtOld] == 0;
            }
        }
    }
    
    BOOL shouldFire = isNetworkReachable && isInstallLogIdAvailable && !isAlreadyFiredToday;
    
    // If the OPEN event is being ignored then let the user know.
    if(!shouldFire)
    {

#if DEBUG_LOG
        NSLog(@"MAT shouldFireOpen: shouldFire = %d, isNetworkReachable = %d, isInstallLogIdAvailable = %d, isAlreadyFiredToday = %d", shouldFire, isNetworkReachable, isInstallLogIdAvailable, isAlreadyFiredToday);
#endif
        
        NSString *errorCode = nil;
        NSString *errorMessage = nil;
        
        if(!isNetworkReachable)
        {
            errorCode = 1121;
            errorMessage = @"The network is not reachable. Ignoring the open event.";
        }
        else if(!isInstallLogIdAvailable)
        {
            errorCode = 1122;
            errorMessage = @"The install or update log_id is not available. Ignoring the open event.";
        }
        else
        {
            errorCode = 1123;
            errorMessage = @"An open event has already been fired today. Ignoring the open event.";
        }
        
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:KEY_ERROR_MAT_OPEN_EVENT_ERROR forKey:NSLocalizedFailureReasonErrorKey];
        [errorDetails setValue:errorMessage forKey:NSLocalizedDescriptionKey];
        
        if(nil != error)
        {
            *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:errorCode userInfo:errorDetails];
        }
    }
    
    return shouldFire;
}

#pragma mark - Server Request For Install Log Id

- (void)requestInstallLogId
{
    [self requestInstallLogId:NO params:nil];
}

- (void)requestInstallLogIdWithOpenRequestParams:(NSMutableDictionary *)params
{
    [self requestInstallLogId:TRUE params:params];
}

- (void)requestInstallLogId:(BOOL)isOpenPending params:(NSMutableDictionary *)params
{
    // if an install or update has already been fired
    BOOL installMarkerExists = nil != [MATUtils userDefaultValueforKey:KEY_INSTALL_DATE];

#if DEBUG_LOG
    NSLog(@"requestInstallLogId: install/update already fired = %d", installMarkerExists);
    NSLog(@"requestInstallLogId: stored install_log_id        = %@", [self.parameters objectForKey:KEY_INSTALL_LOG_ID]);
    NSLog(@"requestInstallLogId: stored update_log_id         = %@", [self.parameters objectForKey:KEY_UPDATE_LOG_ID]);
#endif
    
    // if an install or update has already been fired and if there is no stored install_log_id
    if(installMarkerExists && ![self.parameters objectForKey:KEY_INSTALL_LOG_ID] && ![self.parameters objectForKey:KEY_INSTALL_LOG_ID])
    {
        BOOL shouldFireRequest = ![self isInstallRequestAlreadyFired];
        
        BOOL isNetworkReachable = [MATUtils isNetworkReachable];
        
#if DEBUG_LOG
        NSLog(@"requestInstallLogId: shouldFireRequest: %d, networkReachable = %d", shouldFireRequest, isNetworkReachable);
#endif
        
        // also fire the request only if the network is reachable
        if(shouldFireRequest && isNetworkReachable)
        {
#if DEBUG_LOG
            NSLog(@"requestInstallLogId: requesting install log id");
#endif
            
            [MATUtils setUserDefaultValue:[NSDate date] forKey:KEY_MAT_INSTALL_LOG_ID_REQUEST_TIMESTAMP];
            
            NSSet * ignoreParams = [NSSet setWithObjects:KEY_REDIRECT_URL, KEY_KEY, nil];
            
            NSString *domainName = [MATUtils serverDomainName];
            
            NSString *pathServer = [NSString stringWithFormat:@"%@://%@", KEY_HTTPS, domainName];
            
            NSString *link = [self urlStringForServerUrl:pathServer
                                                    path:SERVER_PATH_GET_INSTALL_LOG_ID
                                                  params:self.parameters
                                            ignoreParams:ignoreParams
                                         encryptionLevel:NORMALLY_ENCRYPTED];
            
            link = [NSString stringWithFormat:@"%@&fields[]=log_id&fields[]=type", link];
            
            [MATUtils sendRequestGetInstallLogIdWithLink:link
                                                  params:params
                                      connectionDelegate:self];
        }
#if DEBUG_LOG
        else
        {
            NSLog(@"requestInstallLogId: request not fired 2");
        }
#endif
    }
#if DEBUG_LOG
    else
    {
        NSLog(@"requestInstallLogId: request not fired 1");
    }
#endif
}

- (BOOL)isInstallRequestAlreadyFired
{
    BOOL isAlreadyFired = FALSE;
    
    NSDate *dtOld = [MATUtils userDefaultValueforKey:KEY_MAT_INSTALL_LOG_ID_REQUEST_TIMESTAMP];
    NSDate *dtCurrent = [NSDate date];
    
#if DEBUG_LOG
    NSLog(@"dtOld     = %@", dtOld);
    NSLog(@"dtCurrent = %@", dtCurrent);
#endif
    
    // if the request has been fired earlier, then check the date
    if(dtOld)
    {
        // Make sure that the request to fetch the install_log_id was not fired today.
        // Note: checks difference in dates, does not check 24 hours.
        isAlreadyFired = [MATUtils daysBetweenDate:dtCurrent andDate:dtOld] == 0;
    }
    
    return isAlreadyFired;
}

#pragma mark - install/update log_id request handler methods

- (void)handleInstallLogId:(NSMutableDictionary *)params
{
#if DEBUG_LOG
    NSLog(@"MobileAppTracker handleInstallLogId: params = %@", params);
#endif
    
    if(params)
    {
        NSData *data = [params objectForKey:KEY_SERVER_RESPONSE];
        NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSArray *arrResponse = [response componentsSeparatedByString:@","];
        [response release], response = nil;
        
#if DEBUG_LOG
        NSLog(@"MobileAppTracker handleInstallLogId: response items = %@", arrResponse);
#endif
        
        // check if the expected two items are present in the response
        if(2 == [arrResponse count])
        {
            // extract the install_log_id from the response
            NSString *newInstallLogId = [arrResponse objectAtIndex:0];
            NSString *newLogIdType = [arrResponse objectAtIndex:1];
            
            // if the install_log_id is present
            if(newInstallLogId && newLogIdType)
            {
                newLogIdType = [newLogIdType stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
#if DEBUG_LOG
                NSLog(@"log_id : %@", newInstallLogId);
                NSLog(@"type   : %@", newLogIdType);
#endif
                
                if([newLogIdType isEqualToString:EVENT_INSTALL])
                {
                    // store the install_log_id
                    [self.parameters setValue:newInstallLogId forKey:KEY_INSTALL_LOG_ID];
                    [MATUtils setUserDefaultValue:newInstallLogId forKey:KEY_MAT_INSTALL_LOG_ID];
                }
                else
                {
                    [self.parameters setValue:newInstallLogId forKey:KEY_UPDATE_LOG_ID];
                    [MATUtils setUserDefaultValue:newInstallLogId forKey:KEY_MAT_UPDATE_LOG_ID];
                }
                
                [self callMethod:params];
            }
        }
    }
}

- (void)failedToRequestInstallLogId:(NSMutableDictionary *)params withError:(NSError *)error
{
#if DEBUG_LOG
    NSLog(@"MobileAppTracker failedToRequestInstallLogId: params = %@, \nerror = %@", params, error);
    NSLog(@"MobileAppTracker failedToRequestInstallLogId: resume tracking request, if any");
#endif
    
    // resume tracking request, if any
    [self callMethod:params];
}

- (void)callMethod:(NSDictionary *)params
{
    if(nil != params && nil != [params valueForKey:@"eventIdOrName"])
    {
        NSString *evtName = [params valueForKey:@"eventIdOrName"];
        BOOL evtIsId = [[params valueForKey:@"eventIsId"] boolValue];
        NSArray *evtItems = [params valueForKey:@"eventItems"];
        NSString *evtRefId = [params valueForKey:@"referenceId"];
        float evtRevAmt = [[params valueForKey:@"revenueAmount"] floatValue];
        NSString *evtCurrency = [params valueForKey:@"currencyCode"];
        NSInteger evtTranStatus = [params valueForKey:@"transactionCode"];
        BOOL forceOpenEvent = [[params valueForKey:@"forceOpenEvent"] boolValue];
        
        [[MobileAppTracker sharedManager] trackActionForEventIdOrName:evtName
                                                            eventIsId:evtIsId
                                                           eventItems:evtItems
                                                          referenceId:evtRefId
                                                        revenueAmount:evtRevAmt
                                                         currencyCode:evtCurrency
                                                     transactionState:evtTranStatus
                                                       forceOpenEvent:forceOpenEvent];
    }
}

@end


#pragma mark - Deprecated Methods

@implementation MobileAppTracker (Deprecated)

- (BOOL)startTrackerWithAdvertiserId:(NSString *)aid advertiserKey:(NSString *)key withError:(NSError **)error
{
    return [self startTrackerWithMATAdvertiserId:aid MATConversionKey:key withError:error];
}

- (void)setAdvertiserId:(NSString *)advertiser_id
{
    [self setMATAdvertiserId:advertiser_id];
}

- (void)setAdvertiserKey:(NSString *)advertiser_key
{
    [self setMATConversionKey:advertiser_key];
}

- (void)setAdvertiserIdentifier:(NSUUID *)advertiser_identifier
{
    [self setAppleAdvertisingIdentifier:advertiser_identifier];
}

- (void)setVendorIdentifier:(NSUUID * )vendor_identifier
{
    [self setAppleVendorIdentifier:vendor_identifier];
}

- (void)setShouldAutoGenerateAdvertiserIdentifier:(BOOL)yesorno
{
    [self setShouldAutoGenerateAppleAdvertisingIdentifier:yesorno];
}

- (void)setShouldAutoGenerateVendorIdentifier:(BOOL)yesorno
{
    [self setShouldAutoGenerateAppleVendorIdentifier:yesorno];
}

- (void)setShouldDebugResponseFromServer:(BOOL)yesorno
{
    [self setDebugMode:yesorno];
}

- (void)setShouldAllowDuplicateRequests:(BOOL)yesorno
{
    [self setAllowDuplicateRequests:yesorno];
}

@end
