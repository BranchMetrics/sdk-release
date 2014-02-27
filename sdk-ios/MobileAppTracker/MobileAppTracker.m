//
//  MobileAppTracker.m
//  MobileAppTracker
//
//  Created by HasOffers on 05/03/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import "MobileAppTracker.h"

#import <UIKit/UIKit.h>

#import "Common/MATConnectionManager.h"
#import "Common/MATCWorks.h"
#import "Common/MATSettings.h"
#import "Common/MATUtils.h"
#import "Common/NSString+MATURLEncoding.m"

#import "MATEncrypter.h"

#import <CoreFoundation/CoreFoundation.h>

#ifdef __IPHONE_7_1 // i.e., built with Xcode 5.1
#import <AdSupport/AdSupport.h>
#endif
#import <iAd/iAd.h>


static const int MAT_CONVERSION_KEY_LENGTH = 32;

static const int IGNORE_IOS_PURCHASE_STATUS = -192837465;

#define PLUGIN_NAMES (@[@"air", @"cocos2dx", @"marmalade", @"phonegap", @"titanium", @"unity", @"xamarin"])

static NSOperationQueue *opQueue = nil;


@interface MobileAppTracker() <MATConnectionManagerDelegate, ADBannerViewDelegate>
{
    ADBannerView *iAd;
    
    BOOL debugMode;
}

- (void)setEventAttributeN:(NSUInteger)number toValue:(NSString*)value;

@property (atomic, assign, getter=isTrackerStarted) BOOL trackerStarted;

@property (nonatomic, assign) id <MobileAppTrackerDelegate> delegate;
@property (nonatomic, retain) MATConnectionManager *connectionManager;
@property (nonatomic, retain) MATSettings *parameters;
@property (nonatomic, retain) NSString *serverPath;
@property (nonatomic, retain) NSDictionary *doNotEncryptDict;

// settings to check for generating data
@property (nonatomic, assign) BOOL shouldUseCookieTracking;
@property (nonatomic, assign) BOOL shouldDetectJailbroken;
@property (nonatomic, assign) BOOL shouldGenerateVendorIdentifier;

@end


@interface MATEventItem(PrivateMethods)

+ (NSArray *)dictionaryArrayForEventItems:(NSArray *)items;

- (NSDictionary *)dictionary;

@end


@implementation MobileAppTracker

#pragma mark - init methods

+(void) initialize
{
    opQueue = [NSOperationQueue new];
    opQueue.maxConcurrentOperationCount = 1;
}

- (id)init
{
    if (self = [super init])
    {
        // create an empty parameters object
        // this won't generate any auto params yet
        self.parameters = [MATSettings new];
            
#if DEBUG_STAGING
        self.parameters.staging = TRUE;
#endif

        // fire up the shared connection manager
        self.connectionManager = [MATConnectionManager sharedManager];
        self.connectionManager.delegate = self;
        
        // !!! very important to init some parms here
        _shouldUseCookieTracking = NO; // by default do not use cookie tracking
        [self setShouldAutoDetectJailbroken:YES];
        [self setShouldAutoGenerateAppleVendorIdentifier:YES];
        
        // the user can turn these off before calling a method which will
        // remove the keys. turning them back on will regenerate the keys.
    }
    return self;
}


#pragma mark - Public Methods

- (void)startTrackerWithMATAdvertiserId:(NSString *)aid MATConversionKey:(NSString *)key
{
    BOOL hasError = NO;
    self.trackerStarted = NO;
    
    NSString *errorMessage = nil;
    NSString *errorKey = nil;
    int errorCode = 0;
    
    NSString *aid_ = [aid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *key_ = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(0 == aid_.length)
    {
        hasError = YES;
        errorMessage = @"No MAT Advertiser Id provided.";
        errorKey = KEY_ERROR_MAT_ADVERTISER_ID_MISSING;
        errorCode = MATNoAdvertiserIDProvided;
    }
    else if(0 == key_.length)
    {
        hasError = YES;
        errorMessage = @"No MAT Conversion Key provided.";
        errorKey = KEY_ERROR_MAT_CONVERSION_KEY_MISSING;
        errorCode = MATNoConversionKeyProvided;
    }
    else if(MAT_CONVERSION_KEY_LENGTH != key_.length)
    {
        hasError = YES;
        errorMessage = [NSString stringWithFormat:@"Invalid MAT Conversion Key provided, length = %lu. Expected key length = %d", (unsigned long)key_.length, MAT_CONVERSION_KEY_LENGTH];
        errorKey = KEY_ERROR_MAT_CONVERSION_KEY_INVALID;
        errorCode = MATInvalidConversionKey;
    }
    
    if(hasError)
    {
        // Create an error object
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:errorKey forKey:NSLocalizedFailureReasonErrorKey];
        [errorDetails setValue:errorMessage forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:errorCode userInfo:errorDetails];
        
        [self notifyDelegateFailureWithError:error];
    }
    else
    {
        self.parameters.advertiserId = aid_;
        self.parameters.conversionKey = key_;
        
        self.trackerStarted = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNotification:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
    }
}

- (void)applicationDidOpenURL:(NSString *)urlString sourceApplication:(NSString *)sourceApplication
{
    // include the params -- referring app and url -- in the next tracking request
    self.parameters.referralUrl = urlString;
    self.parameters.referralSource = sourceApplication;
}

#pragma mark - Notfication Handlers

- (void)handleNotification:(NSNotification *)notice
{
    if([notice.name isEqualToString:UIApplicationWillResignActiveNotification])
    {
        // make sure that the user default local storage is written to disk before the app closes
        [MATUtils synchronizeUserDefaults];
    }
}


#pragma mark - iAd methods

- (void)displayiAdInView:(UIView*)view
{
    if( [ADBannerView instancesRespondToSelector:@selector(initWithAdType:)] ) {
        // iOS 6.0+
        iAd = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
    }
    else {
        iAd = [[ADBannerView alloc] init];
    }
    iAd.delegate = self;
    
    [view addSubview:iAd];
    [self positioniAd];
}


- (void)positioniAd
{
    // Note: This method of sizing the banner is deprecated in iOS 6.0.
    if( iAd.superview.frame.size.width <= [UIScreen mainScreen].bounds.size.width ) {
        if( debugMode ) NSLog( @"MobileAppTracker laying out iAd in portrait orientation: superview's frame is %@", NSStringFromCGRect( iAd.superview.frame ) );
        iAd.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
    }
    else {
        if( debugMode ) NSLog( @"MobileAppTracker laying out iAd in landscape orientation: superview's frame is %@", NSStringFromCGRect( iAd.superview.frame ) );
        iAd.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
    }
    
    if( iAd.bannerLoaded ) {
        if( debugMode ) NSLog( @"MobileAppTracker iAd has banner loaded, displaying its superview" );
        iAd.superview.alpha = 1.;
        if( [_delegate respondsToSelector:@selector(mobileAppTrackerDidDisplayiAd)] )
            [_delegate mobileAppTrackerDidDisplayiAd];
    }
    else {
        if( debugMode ) NSLog( @"MobileAppTracker iAd has no banner loaded, hiding its superview" );
        iAd.superview.alpha = 0.;
        if( [_delegate respondsToSelector:@selector(mobileAppTrackerDidRemoveiAd)] )
            [_delegate mobileAppTrackerDidRemoveiAd];
    }
}


- (void)removeiAd
{
    [iAd removeFromSuperview];
    iAd = nil;
    
    if( [_delegate respondsToSelector:@selector(mobileAppTrackerDidRemoveiAd)] )
        [_delegate mobileAppTrackerDidRemoveiAd];
}


- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [UIView animateWithDuration:0.2 animations:^{
        [self positioniAd];
    }];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [UIView animateWithDuration:0.2 animations:^{
        [self positioniAd];
    }];
    
    if( [_delegate respondsToSelector:@selector(mobileAppTrackerFailedToReceiveiAdWithError:)] )
        [_delegate mobileAppTrackerFailedToReceiveiAdWithError:error];
}


#pragma mark -
#pragma mark Track Action Methods

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
{
    [self trackActionForEventIdOrName:eventIdOrName
                           eventItems:nil
                          referenceId:nil
                        revenueAmount:0
                         currencyCode:nil];
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;
{
    
    [self trackActionForEventIdOrName:eventIdOrName
                           eventItems:nil
                          referenceId:nil
                        revenueAmount:revenueAmount
                         currencyCode:currencyCode];
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                        referenceId:(NSString *)refId
{
    [self trackActionForEventIdOrName:eventIdOrName
                           eventItems:nil
                          referenceId:refId
                        revenueAmount:0
                         currencyCode:nil];
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
{
    
    [self trackActionForEventIdOrName:eventIdOrName
                           eventItems:nil
                          referenceId:refId
                        revenueAmount:revenueAmount
                         currencyCode:currencyCode];
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
{
    [self trackActionForEventIdOrName:eventIdOrName
                           eventItems:eventItems
                          referenceId:nil
                        revenueAmount:0
                         currencyCode:nil];
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
{
    [self trackActionForEventIdOrName:eventIdOrName
                           eventItems:eventItems
                          referenceId:nil
                        revenueAmount:revenueAmount
                         currencyCode:currencyCode];
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
{
    [self trackActionForEventIdOrName:eventIdOrName
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
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
{
    [self trackActionForEventIdOrName:eventIdOrName
                           eventItems:eventItems
                          referenceId:refId
                        revenueAmount:revenueAmount
                         currencyCode:currencyCode
                     transactionState:IGNORE_IOS_PURCHASE_STATUS];
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
                   transactionState:(NSInteger)transactionState
{
    [self trackActionForEventIdOrName:eventIdOrName
                           eventItems:eventItems
                          referenceId:refId
                        revenueAmount:revenueAmount
                         currencyCode:currencyCode
                     transactionState:transactionState
                              receipt:nil];
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
                   transactionState:(NSInteger)transactionState
                            receipt:(NSData *)receipt
{
    [self trackActionForEventIdOrName:eventIdOrName
                           eventItems:eventItems
                          referenceId:refId
                        revenueAmount:revenueAmount
                         currencyCode:currencyCode
                     transactionState:transactionState
                              receipt:receipt
                       postConversion:NO];
}

-(void) trackSessionPostConversionWithReferenceId:(NSString*)refId
{
    [self trackActionForEventIdOrName:EVENT_SESSION
                           eventItems:nil
                          referenceId:refId
                        revenueAmount:0
                         currencyCode:nil
                     transactionState:IGNORE_IOS_PURCHASE_STATUS
                              receipt:nil
                       postConversion:YES];
}

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
                   transactionState:(NSInteger)transactionState
                            receipt:(NSData *)receipt
                     postConversion:(BOOL)postConversion
{
    if(!self.isTrackerStarted)
    {
        // Create an error object
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        NSString *errorMessage = @"Invalid MAT Advertiser Id or MAT Conversion Key passed in.";
        NSString *errorKey = KEY_ERROR_MAT_INVALID_PARAMETERS;
        [errorDetails setValue:errorKey forKey:NSLocalizedFailureReasonErrorKey];
        [errorDetails setValue:errorMessage forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER
                                             code:MATTrackingWithoutInitializing
                                         userInfo:errorDetails];
        
        [self notifyDelegateFailureWithError:error];
        return;
    }
    
    // 05152013: Now MAT has dropped support for "close" events,
    // so we ignore the "close" event and return an error message using the delegate.
    if([[eventIdOrName lowercaseString] isEqualToString:EVENT_CLOSE])
    {
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:KEY_ERROR_MAT_CLOSE_EVENT forKey:NSLocalizedFailureReasonErrorKey];
        [errorDetails setValue:@"MAT does not support tracking of \"close\" event." forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER
                                             code:MATInvalidEventClose
                                         userInfo:errorDetails];
        [self notifyDelegateFailureWithError:error];
        return;
    }

    // continue with normal trackAction
    DLog(@"Continue with normal trackAction... event = %@", eventIdOrName);

    [self.parameters resetBeforeTrackAction];
    
    self.parameters.revenue = @(revenueAmount);
    
    // temporary override of currency in params
    if (currencyCode && currencyCode.length > 0)
    {
        self.parameters.currencyCode = currencyCode;
    }
    
    if(IGNORE_IOS_PURCHASE_STATUS != transactionState)
    {
        self.parameters.transactionState = @(transactionState);
    }
    
    self.parameters.postConversion = postConversion;
    
    // set the standard tracking request parameters
    [self initVariablesForTrackAction:eventIdOrName];
    
    NSString *strReceipt = nil;
    if(receipt && receipt.length > 0)
    {
        // Base64 encode the IAP receipt data
        strReceipt = [MATUtils MATbase64EncodedStringFromData:receipt];
    }
    
    // fire the tracking request
    [self sendRequestWithEventItems:eventItems receipt:strReceipt referenceId:refId];
    
    [self.parameters resetAfterRequest];
}


#pragma mark - Track Session

- (void)trackSession
{
    [self trackSessionWithReferenceId:nil];
}

- (void)trackSessionWithReferenceId:(NSString *)refId
{
    [self trackActionForEventIdOrName:EVENT_SESSION referenceId:refId];

#ifdef __IPHONE_7_1 // i.e., built with Xcode 5.1
    if( [ADClient class] && self.parameters.iadAttribution == nil ) {
        // for devices >= 7.1
        [[ADClient sharedClient] determineAppInstallationAttributionWithCompletionHandler:^(BOOL appInstallationWasAttributedToiAd) {
            [MATUtils setUserDefaultValue:@(appInstallationWasAttributedToiAd) forKey:KEY_IAD_ATTRIBUTION];
            self.parameters.iadAttribution = @(appInstallationWasAttributedToiAd);
            if( appInstallationWasAttributedToiAd )
                [self trackSessionPostConversionWithReferenceId:refId];
        }];
    }
#endif
}


#pragma mark - MAT Delegate Callback Helper Methods

- (void)notifyDelegateSuccessMessage:(NSString *)message
{
    if ([self.delegate respondsToSelector:@selector(mobileAppTrackerDidSucceedWithData:)])
    {
        [self.delegate mobileAppTrackerDidSucceedWithData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void)notifyDelegateFailureWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(mobileAppTrackerDidFailWithError:)])
    {
        [self.delegate mobileAppTrackerDidFailWithError:error];
    }
}


#pragma mark - Start app-to-app tracking session

- (void)setTracking:(NSString*)targetAppPackageName
       advertiserId:(NSString*)targetAppAdvertiserId
            offerId:(NSString*)offerId
        publisherId:(NSString*)publisherId
           redirect:(BOOL)shouldRedirect
{
    [MATUtils startTrackingSessionForTargetBundleId:targetAppPackageName
                                  publisherBundleId:[MATUtils bundleId]
                                       advertiserId:targetAppAdvertiserId
                                         campaignId:offerId
                                        publisherId:publisherId
                                           redirect:shouldRedirect
                                  connectionManager:self.connectionManager];
}


#pragma mark - Set auto-generating properties

- (void)setShouldAutoDetectJailbroken:(BOOL)shouldAutoDetect
{
    self.shouldDetectJailbroken = shouldAutoDetect;
    
    if (shouldAutoDetect)
        self.parameters.jailbroken = @([MATUtils checkJailBreak]);
    else
        self.parameters.jailbroken = nil;
}

- (void)setShouldAutoGenerateAppleVendorIdentifier:(BOOL)shouldAutoGenerate
{
    self.shouldGenerateVendorIdentifier = shouldAutoGenerate;
    if( shouldAutoGenerate ) {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
            NSString *uuidStr = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
            if (uuidStr && ![uuidStr isEqualToString:KEY_GUID_EMPTY]) {
                self.parameters.ifv = uuidStr;
            }
        }
    }
    else
        self.parameters.ifv = nil;
}

#pragma mark - Non-trivial setters

- (void)setDebugMode:(BOOL)newDebugMode
{
    DLog(@"MAT: setDebugMode = %d", newDebugMode);
    
    debugMode = newDebugMode;
    self.connectionManager.shouldDebug = newDebugMode;
    [MATUtils setShouldDebug:newDebugMode];
    
    // show an alert if the debug mode is enabled
    if(newDebugMode) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[[UIAlertView alloc] initWithTitle:@"Warning"
                                        message:@"MAT Debug Mode Enabled. Use only when debugging, do not release with this enabled!!"
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil]
             show];
        }];
    }
}

- (void)setAllowDuplicateRequests:(BOOL)allowDuplicates
{
    DLog(@"MAT: setAllowDuplicateRequests = %d", allowDuplicates);
    
    self.connectionManager.shouldAllowDuplicates = allowDuplicates;
    
    // show an alert if the allow duplicate requests   enabled
    if(allowDuplicates) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[[UIAlertView alloc] initWithTitle:@"Warning"
                                        message:@"Allow Duplicate Requests Enabled. Use only when debugging, do not release with this enabled!!"
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil]
             show];
        }];
    }
}

- (void)setEventAttributeN:(NSUInteger)number toValue:(NSString*)value
{
    switch (number) {
        case 1:
            self.parameters.eventAttribute1 = value;
            break;
        case 2:
            self.parameters.eventAttribute2 = value;
            break;
        case 3:
            self.parameters.eventAttribute3 = value;
            break;
        case 4:
            self.parameters.eventAttribute4 = value;
            break;
        case 5:
            self.parameters.eventAttribute5 = value;
            break;
        default:
            break;
    }
}


#pragma mark - Private Methods

- (void)initVariablesForTrackAction:(NSString *)eventIdOrName
{
    if (self.shouldUseCookieTracking && [[eventIdOrName lowercaseString] isEqualToString:EVENT_INSTALL])
    {
        self.serverPath = SERVER_DOMAIN_COOKIE_TRACKING;
    }
    else
    {
        NSString *domainName = [MATUtils serverDomainName];
        
        self.serverPath = [NSString stringWithFormat:@"https://%@.%@", self.parameters.advertiserId, domainName];
    }

    self.parameters.actionName = eventIdOrName;
    
    self.parameters.systemDate = [NSDate date];

    // Note: set CWorks click param
    NSString *cworksClickKey = nil;
    NSNumber *cworksClickValue = nil;
    
    [self fetchCWorksClickKey:&cworksClickKey andValue:&cworksClickValue];
    DLog(@"cworks=%@:%@", cworksClickKey, cworksClickValue);
    if(nil != cworksClickKey && nil != cworksClickValue)
    {
        self.parameters.cworksClick = @{cworksClickKey: cworksClickValue};
    }
    
    // Note: set CWorks impression param
    NSString *cworksImpressionKey = nil;
    NSNumber *cworksImpressionValue = nil;
    
    [self fetchCWorksImpressionKey:&cworksImpressionKey andValue:&cworksImpressionValue];
    DLog(@"cworks imp=%@:%@", cworksImpressionKey, cworksImpressionValue);
    if(nil != cworksImpressionKey && nil != cworksImpressionValue)
    {
        self.parameters.cworksImpression = @{cworksImpressionKey: cworksImpressionValue};
    }
}


- (NSString*)prepareUrlWithReferenceId:(NSString*)refId encryptionLevel:(NSString*)encryptionLevel ignoreParams:(NSSet*)ignoreParams
{
    NSString *path = SERVER_PATH_TRACKING_ENGINE;

    DLLog(@"MAT prepareUrl: path = %@", path);

    NSString *urlString = [self.parameters urlStringForServerUrl:self.serverPath
                                                            path:path
                                                     referenceId:refId
                                                    ignoreParams:ignoreParams
                                                 encryptionLevel:encryptionLevel];
    
    DLLog(@"MAT prepareUrl: pass end: %@", urlString);
    
    return urlString;
}


// Includes the eventItems and referenceId and fires the tracking request
-(void)sendRequestWithEventItems:(NSArray *)eventItems receipt:(NSString *)receipt referenceId:(NSString*)refId
{
    //----------------------------
    // Always look for a facebook cookie because it could change often.
    //----------------------------
    [self.parameters loadFacebookCookieId];
    
    NSSet * ignoreParams = [NSSet setWithObjects:KEY_REDIRECT_URL, KEY_KEY, nil];
    NSString * trackingLink = [self prepareUrlWithReferenceId:refId
                                              encryptionLevel:NORMALLY_ENCRYPTED
                                                 ignoreParams:ignoreParams];
    
    DRLog(@"MAT sendRequestWithEventItems: %@", trackingLink);
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionary];
    
    // if present then serialize the eventItems
    if([eventItems count] > 0)
    {
        BOOL areEventsLegit = TRUE;
        for( id item in eventItems )
            if( ![item isMemberOfClass:[MATEventItem class]] )
                areEventsLegit = FALSE;
        
        if( areEventsLegit ) {
            // Convert the array of MATEventItem objects to an array of equivalent dictionary representations.
            NSArray *arrDictEventItems = [MATEventItem dictionaryArrayForEventItems:eventItems];
            
            DLog(@"MAT sendRequestWithEventItems: %@", arrDictEventItems);
            [postDict setValue:arrDictEventItems forKey:KEY_DATA];
        }
    }
    
    if(receipt)
    {
        [postDict setValue:receipt forKey:KEY_STORE_RECEIPT];
    }
    
    NSString *strPost = nil;

    if(postDict.count > 0)
    {
        DLog(@"post data before serialization = %@", postDict);

        strPost = [MATUtils jsonSerialize:postDict];
        
        DLog(@"post data after  serialization = %@", strPost);
    }
    
    NSDate *runDate = [NSDate date];
    if( [self.parameters.actionName isEqualToString:EVENT_SESSION] )
        runDate = [runDate dateByAddingTimeInterval:5.];
    
    // fire the event tracking request
    [self.connectionManager enqueueUrlRequest:trackingLink andPOSTData:strPost runDate:runDate];
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
        *value = [dict objectForKey:[[dict allKeys] objectAtIndex:0]];
    }
}

- (void)fetchCWorksImpressionKey:(NSString **)key andValue:(NSNumber **)value
{
    // Note: MAT_getImpressions() method also deletes the stored impression key/value
    NSDictionary *dict = [MATCWorks MAT_getImpressions:[MATUtils bundleId]];
    
    if([dict count] > 0)
    {
        *key = [NSString stringWithFormat:@"cworks_impression[%@]", [[dict allKeys] objectAtIndex:0]];
        *value = [dict objectForKey:[[dict allKeys] objectAtIndex:0]];
    }
}

#pragma mark -
#pragma mark MATConnectionManagerDelegate protocol methods

- (void)connectionManager:(MATConnectionManager *)manager didSucceedWithData:(NSData *)data
{
    NSString *strData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    DLog(@"MAT: didSucceedWithData: = %@", strData);

    if(!strData || [strData rangeOfString:@"\"success\":true"].location == NSNotFound)
    {
        if([self.delegate respondsToSelector:@selector(mobileAppTrackerDidFailWithError:)])
        {
            NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:KEY_ERROR_MAT_SERVER_ERROR forKey:NSLocalizedFailureReasonErrorKey];
            [errorDetails setValue:strData forKey:NSLocalizedDescriptionKey];
            
            NSError *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER
                                                 code:MATServerErrorResponse
                                             userInfo:errorDetails];
            [self.delegate mobileAppTrackerDidFailWithError:error];
        }
        return;
    }
    
    // if the server response contains an open_log_id, then store it for future use
    if([strData rangeOfString:@"\"site_event_type\":\"open\""].location != NSNotFound &&
       [strData rangeOfString:@"\"log_id\":\""].location != NSNotFound)
    {
        // regex to find the value of log_id json key
        NSString *pattern = @"(?<=\"log_id\":\")([\\w\\d\\-]+)\"";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:strData options:NSMatchingReportCompletion range:NSMakeRange(0, [strData length])];
        
        // if the required match is found
        if(match.range.location != NSNotFound)
        {
            NSString *log_id = [strData substringWithRange:[match rangeAtIndex:1]];

            // store open_log_id if there is no other
            if( ![MATUtils userDefaultValueforKey:KEY_OPEN_LOG_ID] ) {
                self.parameters.openLogId = log_id;
                [MATUtils setUserDefaultValue:log_id forKey:KEY_OPEN_LOG_ID];
            }

            // store last_open_log_id
            self.parameters.lastOpenLogId = log_id;
            [MATUtils setUserDefaultValue:log_id forKey:KEY_LAST_OPEN_LOG_ID];
        }
    }
    
    [self notifyDelegateSuccessMessage:strData];
}

- (void)connectionManager:(MATConnectionManager *)manager didFailWithError:(NSError *)error
{
    if([self.delegate respondsToSelector:@selector(mobileAppTrackerDidFailWithError:)])
    {
        [self.delegate mobileAppTrackerDidFailWithError:error];
    }
}


-(BOOL) isiAdAttribution
{
    return self.parameters.iadAttribution;
}


#pragma mark -
#pragma mark Pass-through methods

+ (MobileAppTracker *)sharedManager
{
    // note that the initialization is slow (potentially hundreds of milliseconds),
    // so call this function on a background thread if it might be the first time
    static MobileAppTracker *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[MobileAppTracker alloc] init];
    });
    
    return sharedManager;
}

+ (void)startTrackerWithMATAdvertiserId:(NSString *)aid MATConversionKey:(NSString *)key
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] startTrackerWithMATAdvertiserId:aid MATConversionKey:key];
    }];
}

+ (void)setDelegate:(id <MobileAppTrackerDelegate>)delegate
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].delegate = delegate;
#if DEBUG
        [self sharedManager].parameters.delegate = (id <MATSettingsDelegate>)delegate;
#endif
    }];
}

+ (void)setDebugMode:(BOOL)yesorno
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setDebugMode:yesorno];
    }];
}

+ (void)setAllowDuplicateRequests:(BOOL)yesorno
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setAllowDuplicateRequests:yesorno];
    }];
}

+ (void)setExistingUser:(BOOL)existingUser
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.existingUser = @(existingUser);
    }];
}

+ (void)setAppleAdvertisingIdentifier:(NSUUID *)appleAdvertisingIdentifier
           advertisingTrackingEnabled:(BOOL)adTrackingEnabled;
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.ifa = [appleAdvertisingIdentifier UUIDString];
        [self sharedManager].parameters.ifaTracking = @(adTrackingEnabled);
    }];
}

+ (void)setAppleVendorIdentifier:(NSUUID * )appleVendorIdentifier
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.ifv = [appleVendorIdentifier UUIDString];
    }];
}

+ (void)setCurrencyCode:(NSString *)currencyCode
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.defaultCurrencyCode = currencyCode;
        [self sharedManager].parameters.currencyCode = currencyCode;
    }];
}

+ (void)setJailbroken:(BOOL)yesorno
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.jailbroken = @(yesorno);
    }];
}

+ (void)setPackageName:(NSString *)packageName
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.packageName = packageName;
    }];
}

+ (void)setShouldAutoDetectJailbroken:(BOOL)yesorno
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setShouldAutoDetectJailbroken:yesorno];
    }];
}

+ (void)setShouldAutoGenerateAppleVendorIdentifier:(BOOL)yesorno
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setShouldAutoGenerateAppleVendorIdentifier:yesorno];
    }];
}

+ (void)setSiteId:(NSString *)siteId
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.siteId = siteId;
    }];
}

+ (void)setTRUSTeId:(NSString *)tpid;
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.trusteTPID = tpid;
    }];
}

+ (void)setUserEmail:(NSString *)userEmail
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.userEmail = userEmail;
    }];
}

+ (void)setUserId:(NSString *)userId
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.userId = userId;
    }];
}

+ (void)setUserName:(NSString *)userName
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.userName = userName;
    }];
}

+ (void)setFacebookUserId:(NSString *)facebookUserId
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.facebookUserId = facebookUserId;
    }];
}

+ (void)setTwitterUserId:(NSString *)twitterUserId
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.twitterUserId = twitterUserId;
    }];
}

+ (void)setGoogleUserId:(NSString *)googleUserId
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.googleUserId = googleUserId;
    }];
}

+ (void)setAge:(NSInteger)userAge
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.age = @(userAge);
    }];
}

+ (void)setGender:(MATGender)userGender
{
    [opQueue addOperationWithBlock:^{
        // if an unknown value has been provided then default to "MALE" gender
        long gen = MATGenderFemale == userGender ? MATGenderFemale : MATGenderMale;
        [self sharedManager].parameters.gender = @(gen);
    }];
}

+ (void)setLatitude:(double)latitude longitude:(double)longitude
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.latitude = @(latitude);
        [self sharedManager].parameters.longitude = @(longitude);
    }];
}

+ (void)setLatitude:(double)latitude longitude:(double)longitude altitude:(double)altitude
{
    [self setLatitude:latitude longitude:longitude];
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.altitude = @(altitude);
    }];
}

+ (void)setAppAdTracking:(BOOL)enable
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.appAdTracking = @(enable);
    }];
}

+ (void)setPluginName:(NSString *)pluginName
{
    [opQueue addOperationWithBlock:^{
        if( pluginName == nil )
            [self sharedManager].parameters.pluginName = pluginName;
        else
            for( NSString *allowedName in PLUGIN_NAMES )
                if( [pluginName isEqualToString:allowedName] ) {
                    [self sharedManager].parameters.pluginName = pluginName;
                    break;
                }
    }];
}

+ (void)setEventAttribute1:(NSString*)value
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setEventAttributeN:1 toValue:value];
    }];
}

+ (void)setEventAttribute2:(NSString*)value
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setEventAttributeN:2 toValue:value];
    }];
}

+ (void)setEventAttribute3:(NSString*)value
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setEventAttributeN:3 toValue:value];
    }];
}

+ (void)setEventAttribute4:(NSString*)value
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setEventAttributeN:4 toValue:value];
    }];
}

+ (void)setEventAttribute5:(NSString*)value
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setEventAttributeN:5 toValue:value];
    }];
}

+ (NSString*)matId
{
    return [self sharedManager].parameters.matId;
}

+ (NSString*)openLogId
{
    return [self sharedManager].parameters.openLogId;
}

+ (void)displayiAdInView:(UIView*)view
{
    [opQueue addOperationWithBlock:^{
        MobileAppTracker *mat = [self sharedManager];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [mat displayiAdInView:view];
        }];
    }];
}

+ (void) removeiAd
{
    [opQueue addOperationWithBlock:^{
        MobileAppTracker *mat = [self sharedManager];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [mat removeiAd];
        }];
    }];
}

+ (void)trackSession
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackSession];
    }];
}

+ (void)trackSessionWithReferenceId:(NSString *)refId
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackSessionWithReferenceId:refId];
    }];
}

+ (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventIdOrName];
    }];
}

+ (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                        referenceId:(NSString *)refId
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventIdOrName
                                              referenceId:refId];
    }];
}

+ (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventIdOrName
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode];
    }];
}

+ (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventIdOrName
                                              referenceId:refId
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode];
    }];
}

+ (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventIdOrName
                                               eventItems:eventItems];
    }];
}

+ (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventIdOrName
                                               eventItems:eventItems
                                              referenceId:refId];
    }];
}

+ (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventIdOrName
                                               eventItems:eventItems
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode];
    }];
}

+ (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventIdOrName
                                               eventItems:eventItems
                                              referenceId:refId
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode];
    }];
}

+ (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
                   transactionState:(NSInteger)transactionState
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventIdOrName
                                               eventItems:eventItems
                                              referenceId:refId
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode
                                         transactionState:transactionState];
    }];
}

+ (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
                   transactionState:(NSInteger)transactionState
                            receipt:(NSData *)receipt
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventIdOrName
                                               eventItems:eventItems
                                              referenceId:refId
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode
                                         transactionState:transactionState
                                                  receipt:receipt];
    }];
}

+ (void)setUseCookieTracking:(BOOL)yesorno
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].shouldUseCookieTracking = yesorno;
    }];
}

+ (void)setRedirectUrl:(NSString *)redirectURL
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.redirectUrl = redirectURL;
    }];
}

+ (void)setTracking:(NSString *)targetAppPackageName
       advertiserId:(NSString *)targetAppAdvertiserId
            offerId:(NSString *)targetAdvertiserOfferId
        publisherId:(NSString *)targetAdvertiserPublisherId
           redirect:(BOOL)shouldRedirect
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setTracking:targetAppPackageName
                             advertiserId:targetAppAdvertiserId
                                  offerId:targetAdvertiserOfferId
                              publisherId:targetAdvertiserPublisherId
                                 redirect:shouldRedirect];
    }];
}

+ (void)applicationDidOpenURL:(NSString *)urlString sourceApplication:(NSString *)sourceApplication
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] applicationDidOpenURL:urlString sourceApplication:sourceApplication];
    }];
}

@end
