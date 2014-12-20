//
//  MATTracker.m
//  MobileAppTracker
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import "MATTracker.h"
#import "../MobileAppTracker.h"

#import <UIKit/UIKit.h>

#import "MATCWorks.h"
#import "MATEventQueue.h"
#import "MATUtils.h"
#import "NSString+MATURLEncoding.m"
#import "MATAppToAppTracker.h"
#import "MATFBBridge.h"

#import <CoreFoundation/CoreFoundation.h>

#if USE_IAD
#import <iAd/iAd.h>
#endif

static const int MAT_CONVERSION_KEY_LENGTH      = 32;

static const int IGNORE_IOS_PURCHASE_STATUS     = -192837465;

#if USE_IAD
const NSTimeInterval MAT_SESSION_QUEUING_DELAY  = 15.;
#else
const NSTimeInterval MAT_SESSION_QUEUING_DELAY  = 0.;
#endif

const NSTimeInterval MAX_WAIT_TIME_FOR_INIT     = 1.0;
const NSTimeInterval TIME_STEP_FOR_INIT_WAIT    = 0.1;

const NSInteger MAX_REFERRAL_URL_LENGTH         = 8192; // 8 KB

@interface MATEventItem(PrivateMethods)

+ (NSArray *)dictionaryArrayForEventItems:(NSArray *)items;

- (NSDictionary *)dictionary;

@end


@interface MATTracker() <MATEventQueueDelegate
#if USE_IAD
, ADBannerViewDelegate
#endif
>
{
#if USE_IAD
    ADBannerView *iAd;
#endif
    BOOL debugMode;
    
    MATAppToAppTracker *appToAppTracker;
    MATRegionMonitor *regionMonitor;
}

@property (nonatomic, assign, getter=isTrackerStarted) BOOL trackerStarted;

@property (nonatomic, assign) BOOL shouldDetectJailbroken;
@property (nonatomic, assign) BOOL shouldGenerateVendorIdentifier;

@property (nonatomic, retain) NSDictionary *doNotEncryptDict;

@end

@implementation MATTracker

#pragma mark - init methods

- (id)init
{
    if (self = [super init])
    {
        // create an empty parameters object
        // this won't generate any auto params yet
        self.parameters = [MATSettings new];
        
#if DEBUG_STAGING
        self.parameters.staging = YES;
#endif
        
        [MATEventQueue setDelegate:self];
        
        // !!! very important to init some parms here
        _shouldUseCookieTracking = NO; // by default do not use cookie tracking
        [self setShouldAutoDetectJailbroken:YES];
        [self setShouldAutoGenerateAppleVendorIdentifier:YES];
        // the user can turn these off before calling a method which will
        // remove the keys. turning them back on will regenerate the keys.

#if USE_IAD
        [self checkIadAttribution:nil];
#endif
    }
    return self;
}


#pragma mark - Public Methods

- (MATRegionMonitor*)regionMonitor
{
    if( !regionMonitor )
        regionMonitor = [MATRegionMonitor new];
    return regionMonitor;
}


- (void)startTrackerWithMATAdvertiserId:(NSString *)aid MATConversionKey:(NSString *)key
{
    self.trackerStarted = NO;
    
    NSString *aid_ = [aid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *key_ = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(0 == aid_.length)
    {
        [self notifyDelegateFailureWithErrorCode:MATNoAdvertiserIDProvided
                                             key:MAT_KEY_ERROR_MAT_ADVERTISER_ID_MISSING
                                         message:@"No MAT Advertiser Id provided."];
        return;
    }
    if(0 == key_.length)
    {
        [self notifyDelegateFailureWithErrorCode:MATNoConversionKeyProvided
                                             key:MAT_KEY_ERROR_MAT_CONVERSION_KEY_MISSING
                                         message:@"No MAT Conversion Key provided."];
        return;
    }
    if(MAT_CONVERSION_KEY_LENGTH != key_.length)
    {
        [self notifyDelegateFailureWithErrorCode:MATInvalidConversionKey
                                             key:MAT_KEY_ERROR_MAT_CONVERSION_KEY_INVALID
                                         message:[NSString stringWithFormat:@"Invalid MAT Conversion Key provided, length = %lu. Expected key length = %d", (unsigned long)key_.length, MAT_CONVERSION_KEY_LENGTH]];
        return;
    }
    
    self.parameters.advertiserId = aid_;
    self.parameters.conversionKey = key_;
    
    self.trackerStarted = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

- (void)applicationDidOpenURL:(NSString *)urlString sourceApplication:(NSString *)sourceApplication
{
    // include the params -- referring app and url -- in the next tracking request
    
    // 07-Nov-2014: limit the referral url length,
    // so that the NSXMLParser does not run out of memory
    if(urlString.length > MAX_REFERRAL_URL_LENGTH)
    {
        urlString = [urlString substringToIndex:MAX_REFERRAL_URL_LENGTH];
    }
    
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


#if USE_IAD

#pragma mark - iAd methods

- (void)checkIadAttribution:(void (^)(BOOL iadAttributed))attributionBlock
{
#if USE_IAD
    if( [UIApplication sharedApplication] && [ADClient class] && self.parameters.iadAttribution == nil ) {
        // for devices >= 7.1
        ADClient *adClient = [ADClient sharedClient];

#ifdef __IPHONE_8_0 // if MAT is built in Xcode 6
        if( [adClient respondsToSelector:@selector(lookupAdConversionDetails:)] ) {
            // device is iOS 8.0
            [[ADClient sharedClient] lookupAdConversionDetails:^(NSDate *appPurchaseDate, NSDate *iAdImpressionDate) {
                BOOL iAdOriginatedInstallation = (iAdImpressionDate != nil);
                [MATUtils setUserDefaultValue:@(iAdOriginatedInstallation) forKey:MAT_KEY_IAD_ATTRIBUTION];
                self.parameters.iadAttribution = @(iAdOriginatedInstallation);
                self.parameters.iadImpressionDate = iAdImpressionDate;
                if( attributionBlock )
                    attributionBlock( iAdOriginatedInstallation );
            }];
        }
        else
#endif
            // device is iOS 7.1
            [adClient determineAppInstallationAttributionWithCompletionHandler:^(BOOL appInstallationWasAttributedToiAd) {
                [MATUtils setUserDefaultValue:@(appInstallationWasAttributedToiAd) forKey:MAT_KEY_IAD_ATTRIBUTION];
                self.parameters.iadAttribution = @(appInstallationWasAttributedToiAd);
                if( attributionBlock )
                    attributionBlock( appInstallationWasAttributedToiAd );
            }];
    }
#endif
}


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

#endif


#pragma mark -
#pragma mark Track Action Methods

- (void)trackActionForEventIdOrName:(id)eventIdOrName
{
    [self trackActionForEventIdOrName:eventIdOrName
                           eventItems:nil
                          referenceId:nil
                        revenueAmount:0
                         currencyCode:nil];
}

- (void)trackActionForEventIdOrName:(id)eventIdOrName
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
{
    
    [self trackActionForEventIdOrName:eventIdOrName
                           eventItems:nil
                          referenceId:nil
                        revenueAmount:revenueAmount
                         currencyCode:currencyCode];
}

- (void)trackActionForEventIdOrName:(id)eventIdOrName
                        referenceId:(NSString *)refId
{
    [self trackActionForEventIdOrName:eventIdOrName
                           eventItems:nil
                          referenceId:refId
                        revenueAmount:0
                         currencyCode:nil];
}

- (void)trackActionForEventIdOrName:(id)eventIdOrName
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

- (void)trackActionForEventIdOrName:(id)eventIdOrName
                         eventItems:(NSArray *)eventItems
{
    [self trackActionForEventIdOrName:eventIdOrName
                           eventItems:eventItems
                          referenceId:nil
                        revenueAmount:0
                         currencyCode:nil];
}

- (void)trackActionForEventIdOrName:(id)eventIdOrName
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

- (void)trackActionForEventIdOrName:(id)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
{
    [self trackActionForEventIdOrName:eventIdOrName
                           eventItems:eventItems
                          referenceId:refId
                        revenueAmount:0
                         currencyCode:nil];
}

- (void)trackActionForEventIdOrName:(id)eventIdOrName
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

- (void)trackActionForEventIdOrName:(id)eventIdOrName
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

- (void)trackActionForEventIdOrName:(id)eventIdOrName
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

- (void)trackInstallPostConversion
{
    [self trackActionForEventIdOrName:MAT_EVENT_INSTALL
                           eventItems:nil
                          referenceId:nil
                        revenueAmount:0
                         currencyCode:nil
                     transactionState:IGNORE_IOS_PURCHASE_STATUS
                              receipt:nil
                       postConversion:YES];
}

- (void)trackActionForEventIdOrName:(id)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
                   transactionState:(NSInteger)transactionState
                            receipt:(NSData *)receipt
                     postConversion:(BOOL)postConversion
{
    BOOL isId = [eventIdOrName isKindOfClass:[NSNumber class]];
    
    if(!self.isTrackerStarted) {
        [self notifyDelegateFailureWithErrorCode:MATTrackingWithoutInitializing
                                             key:MAT_KEY_ERROR_MAT_INVALID_PARAMETERS
                                         message:@"Invalid MAT Advertiser Id or MAT Conversion Key passed in."];
        
        return;
    }
    
    // 05152013: Now MAT has dropped support for "close" events,
    // so we ignore the "close" event and return an error message using the delegate.
    if(!isId && [[eventIdOrName lowercaseString] isEqualToString:MAT_EVENT_CLOSE]) {
        [self notifyDelegateFailureWithErrorCode:MATInvalidEventClose
                                             key:MAT_KEY_ERROR_MAT_CLOSE_EVENT
                                         message:@"MAT does not support tracking of \"close\" event."];
        
        return;
    }
    
    [self.parameters resetBeforeTrackAction];
    
    self.parameters.revenue = @(revenueAmount);
    if( revenueAmount > 0 )
        [self setPayingUser:YES];
    
    // temporary override of currency in params
    if (currencyCode.length > 0)
        self.parameters.currencyCode = currencyCode;
    
    if(IGNORE_IOS_PURCHASE_STATUS != transactionState)
        self.parameters.transactionState = @(transactionState);
    
    self.parameters.postConversion = postConversion;
    
    // set the standard tracking request parameters
    [self initVariablesForTrackAction:eventIdOrName];
    
    // Base64 encode the IAP receipt data
    NSString *strReceipt = nil;
    if (receipt.length > 0)
        strReceipt = [MATUtils MATbase64EncodedStringFromData:receipt];
    
    // fire the tracking request
    [self sendRequestWithEventItems:eventItems isId:isId receipt:strReceipt referenceId:refId];
    
    [self.parameters resetAfterRequest];
}


#pragma mark - Track Session

- (void)trackSession
{
    [self trackActionForEventIdOrName:MAT_EVENT_SESSION];
    
#if USE_IAD
    [self checkIadAttribution:^(BOOL iadAttributed) {
        if( iadAttributed )
            [self trackInstallPostConversion];
    }];
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

- (void)notifyDelegateFailureWithErrorCode:(MATErrorCode)errorCode key:(NSString*)errorKey message:(NSString*)errorMessage
{
    if ([self.delegate respondsToSelector:@selector(mobileAppTrackerDidFailWithError:)]) {
        NSDictionary *errorDetails = @{NSLocalizedFailureReasonErrorKey: errorKey ?: @"",
                                              NSLocalizedDescriptionKey: errorMessage ?: @""};
        NSError *error = [NSError errorWithDomain:MAT_KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:errorCode userInfo:errorDetails];
    
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
    appToAppTracker = [MATAppToAppTracker new];
    appToAppTracker.delegate = self;
    
    [appToAppTracker startTrackingSessionForTargetBundleId:targetAppPackageName
                                         publisherBundleId:[MATUtils bundleId]
                                              advertiserId:targetAppAdvertiserId
                                                campaignId:offerId
                                               publisherId:publisherId
                                                  redirect:shouldRedirect
                                                domainName:[self.parameters domainName]];
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
            if (uuidStr && ![uuidStr isEqualToString:MAT_KEY_GUID_EMPTY]) {
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
    self.parameters.debugMode = @(newDebugMode);
    
    // show an alert if the debug mode is enabled
    if(newDebugMode && [UIApplication sharedApplication]) {
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

- (void)setAllowDuplicateRequests:(BOOL)newAllowDuplicates
{
    DLog(@"MAT: setAllowDuplicateRequests = %d", newAllowDuplicates);
    
    self.parameters.allowDuplicates = @(newAllowDuplicates);
    
    // show an alert if the allow duplicate requests   enabled
    if(newAllowDuplicates && [UIApplication sharedApplication]) {
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


- (void)setPayingUser:(BOOL)isPayingUser
{
    self.parameters.payingUser = @(isPayingUser);
    [MATUtils setUserDefaultValue:@(isPayingUser) forKey:MAT_KEY_IS_PAYING_USER];
}


#pragma mark - Private Methods

- (void)initVariablesForTrackAction:(NSString *)eventIdOrName
{
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


// Includes the eventItems and referenceId and fires the tracking request
- (void)sendRequestWithEventItems:(NSArray *)eventItems isId:(BOOL)isId receipt:(NSString *)receipt referenceId:(NSString*)refId
{
    //----------------------------
    // Always look for a facebook cookie because it could change often.
    //----------------------------
    [self.parameters loadFacebookCookieId];
    
    if(self.fbLogging)
    {
        // copy the original event name for use in the async call to MATFBBridge.sendEvent
        // and avoid a race condition if self.parameters.actionName value is changed
        NSString *originalEventName = self.parameters.actionName;
        
        // call the Facebook event logging methods on main thread to make sure FBSession threading requirements are met
        dispatch_async( dispatch_get_main_queue(), ^{
            [MATFBBridge sendEvent:originalEventName parameters:self.parameters limitEventAndDataUsage:self.fbLimitUsage];
        });
    }
    
    NSString *trackingLink, *encryptParams;
    
    // NOTE: urlStringForReferenceId: changes self.parameters.actionName to "conversion"
    [self.parameters urlStringForReferenceId:refId
                                trackingLink:&trackingLink
                               encryptParams:&encryptParams
                                        isId:isId];
    
    DRLog(@"MAT sendRequestWithEventItems: %@", trackingLink);
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionary];
    
    // if present then serialize the eventItems
    if([eventItems count] > 0)
    {
        BOOL areEventsLegit = YES;
        for( id item in eventItems )
            if( ![item isMemberOfClass:[MATEventItem class]] )
                areEventsLegit = NO;
        
        if( areEventsLegit ) {
            // Convert the array of MATEventItem objects to an array of equivalent dictionary representations.
            NSArray *arrDictEventItems = [MATEventItem dictionaryArrayForEventItems:eventItems];
            
            DLog(@"MAT sendRequestWithEventItems: %@", arrDictEventItems);
            [postDict setValue:arrDictEventItems forKey:MAT_KEY_DATA];
        }
    }
    
    if(receipt)
        [postDict setValue:receipt forKey:MAT_KEY_STORE_RECEIPT];
    
    // on first open, send install receipt
    if( self.parameters.openLogId == nil )
        [postDict setValue:self.parameters.installReceipt forKey:MAT_KEY_INSTALL_RECEIPT];
    
    NSString *strPost = nil;
    
    if(postDict.count > 0) {
        DLog(@"post data before serialization = %@", postDict);
        strPost = [MATUtils jsonSerialize:postDict];
        DLog(@"post data after  serialization = %@", strPost);
    }
    
    NSDate *runDate = [NSDate date];
    
#if USE_IAD
    if( [self.parameters.actionName isEqualToString:MAT_EVENT_SESSION] )
        runDate = [runDate dateByAddingTimeInterval:MAT_SESSION_QUEUING_DELAY];
#endif
    
    // fire the event tracking request
    [MATEventQueue enqueueUrlRequest:trackingLink encryptParams:encryptParams postData:strPost runDate:runDate];
    
    if( [self.delegate respondsToSelector:@selector(mobileAppTrackerEnqueuedActionWithReferenceId:)] )
        [self.delegate mobileAppTrackerEnqueuedActionWithReferenceId:refId];
}


#pragma mark -
#pragma mark CWorks Method Calls

- (void)fetchCWorksClickKey:(NSString **)key andValue:(NSNumber **)value
{
    // Note: MAT_getClicks() method also deletes the stored click key/value
    NSDictionary *dict = [MATCWorks MAT_getClicks:[MATUtils bundleId]];
    
    if([dict count] > 0)
    {
        *key = [NSString stringWithFormat:@"%@[%@]", MAT_KEY_CWORKS_CLICK, [[dict allKeys] objectAtIndex:0]];
        *value = [dict objectForKey:[[dict allKeys] objectAtIndex:0]];
    }
}

- (void)fetchCWorksImpressionKey:(NSString **)key andValue:(NSNumber **)value
{
    // Note: MAT_getImpressions() method also deletes the stored impression key/value
    NSDictionary *dict = [MATCWorks MAT_getImpressions:[MATUtils bundleId]];
    
    if([dict count] > 0)
    {
        *key = [NSString stringWithFormat:@"%@[%@]", MAT_KEY_CWORKS_IMPRESSION, [[dict allKeys] objectAtIndex:0]];
        *value = [dict objectForKey:[[dict allKeys] objectAtIndex:0]];
    }
}

#pragma mark -
#pragma mark MATEventQueueDelegate protocol methods

- (void)queueRequestDidSucceedWithData:(NSData *)data
{
    NSString *strData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if(!strData || [strData rangeOfString:[NSString stringWithFormat:@"\"%@\":true", MAT_KEY_SUCCESS]].location == NSNotFound)
    {
        [self notifyDelegateFailureWithErrorCode:MATServerErrorResponse
                                             key:MAT_KEY_ERROR_MAT_SERVER_ERROR
                                         message:strData];
        return;
    }
    
    // if the server response contains an open_log_id, then store it for future use
    if([strData rangeOfString:[NSString stringWithFormat:@"\"%@\":\"%@\"", MAT_KEY_SITE_EVENT_TYPE, MAT_EVENT_OPEN]].location != NSNotFound &&
       [strData rangeOfString:[NSString stringWithFormat:@"\"%@\":\"", MAT_KEY_LOG_ID]].location != NSNotFound)
    {
        // regex to find the value of log_id json key
        NSString *pattern = [NSString stringWithFormat:@"(?<=\"%@\":\")([\\w\\d\\-]+)\"", MAT_KEY_LOG_ID];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:strData options:NSMatchingReportCompletion range:NSMakeRange(0, [strData length])];
        
        // if the required match is found
        if(match.range.location != NSNotFound)
        {
            NSString *log_id = [strData substringWithRange:[match rangeAtIndex:1]];
            
            // store open_log_id if there is no other
            if( ![MATUtils userDefaultValueforKey:MAT_KEY_OPEN_LOG_ID] ) {
                self.parameters.openLogId = log_id;
                [MATUtils setUserDefaultValue:log_id forKey:MAT_KEY_OPEN_LOG_ID];
            }
            
            // store last_open_log_id
            self.parameters.lastOpenLogId = log_id;
            [MATUtils setUserDefaultValue:log_id forKey:MAT_KEY_LAST_OPEN_LOG_ID];
        }
    }
    
    [self notifyDelegateSuccessMessage:strData];
}

- (void)queueRequestDidFailWithError:(NSError *)error
{
    if([self.delegate respondsToSelector:@selector(mobileAppTrackerDidFailWithError:)])
    {
        [self.delegate mobileAppTrackerDidFailWithError:error];
    }
}

/*!
 Waits for MAT initialization for max duration of MAX_WAIT_TIME_FOR_INIT second(s)
 in increments of TIME_STEP_FOR_INIT_WAIT second(s).
 */
- (void)waitForInit
{
    NSDate *maxWait = nil;
    
    while( !_trackerStarted ) {
        if( maxWait == nil )
            maxWait = [NSDate dateWithTimeIntervalSinceNow:MAX_WAIT_TIME_FOR_INIT];
        if( [maxWait timeIntervalSinceNow] < 0 ) { // is this right? time is hard
            NSLog( @"MobileAppTracker timeout waiting for initialization" );
            return;
        }
        
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:TIME_STEP_FOR_INIT_WAIT]];
    }
}

- (NSString*)encryptionKey
{
    [self waitForInit];
    return self.parameters.conversionKey;
}

- (BOOL)isiAdAttribution
{
    [self waitForInit];
    return [self.parameters.iadAttribution boolValue];
}

- (NSString*)userAgent
{
    [self waitForInit];
    return self.parameters.userAgent;
}

@end
