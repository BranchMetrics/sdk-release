//
//  MATTracker.m
//  MobileAppTracker
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import "MATTracker.h"
#import "MobileAppTracker.h"

#import <UIKit/UIKit.h>

#import "MATCWorks.h"
#import "MATUtils.h"
#import "NSString+MATURLEncoding.m"
#import "MATAppToAppTracker.h"
#import "MATEncrypter.h"

#import <CoreFoundation/CoreFoundation.h>

#define USE_IAD_ATTRIBTION FALSE
#if USE_IAD_ATTRIBUTION
#import <AdSupport/AdSupport.h>
#endif

#import <iAd/iAd.h>


static const int MAT_CONVERSION_KEY_LENGTH = 32;

static const int IGNORE_IOS_PURCHASE_STATUS = -192837465;


@interface MATEventItem(PrivateMethods)

+ (NSArray *)dictionaryArrayForEventItems:(NSArray *)items;

- (NSDictionary *)dictionary;

@end


@interface MATTracker() <MATConnectionManagerDelegate, ADBannerViewDelegate>
{
    ADBannerView *iAd;
    
    BOOL debugMode;
    
    MATAppToAppTracker *appToAppTracker;
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
        self.parameters.staging = TRUE;
#endif
        
        // fire up the shared connection manager
        self.connectionManager = [MATConnectionManager new];
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
    self.trackerStarted = NO;
    
    NSString *aid_ = [aid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *key_ = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(0 == aid_.length)
    {
        [self notifyDelegateFailureWithErrorCode:MATNoAdvertiserIDProvided
                                             key:KEY_ERROR_MAT_ADVERTISER_ID_MISSING
                                         message:@"No MAT Advertiser Id provided."];
        return;
    }
    if(0 == key_.length)
    {
        [self notifyDelegateFailureWithErrorCode:MATNoConversionKeyProvided
                                             key:KEY_ERROR_MAT_CONVERSION_KEY_MISSING
                                         message:@"No MAT Conversion Key provided."];
        return;
    }
    if(MAT_CONVERSION_KEY_LENGTH != key_.length)
    {
        [self notifyDelegateFailureWithErrorCode:MATInvalidConversionKey
                                             key:KEY_ERROR_MAT_CONVERSION_KEY_INVALID
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
                       currencyCode:(NSString *)currencyCode
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

-(void) trackInstallPostConversionWithReferenceId:(NSString*)refId
{
    [self trackActionForEventIdOrName:EVENT_INSTALL
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
    if(!self.isTrackerStarted) {
        [self notifyDelegateFailureWithErrorCode:MATTrackingWithoutInitializing
                                             key:KEY_ERROR_MAT_INVALID_PARAMETERS
                                         message:@"Invalid MAT Advertiser Id or MAT Conversion Key passed in."];
        return;
    }
    
    // 05152013: Now MAT has dropped support for "close" events,
    // so we ignore the "close" event and return an error message using the delegate.
    if([[eventIdOrName lowercaseString] isEqualToString:EVENT_CLOSE]) {
        [self notifyDelegateFailureWithErrorCode:MATInvalidEventClose
                                             key:KEY_ERROR_MAT_CLOSE_EVENT
                                         message:@"MAT does not support tracking of \"close\" event."];
        return;
    }
    
    [self.parameters resetBeforeTrackAction];
    
    self.parameters.revenue = @(revenueAmount);
    if( revenueAmount > 0 )
        [self setPayingUser:TRUE];
    
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
    
#if USE_IAD_ATTRIBUTION
    if( [ADClient class] && self.parameters.iadAttribution == nil ) {
        // for devices >= 7.1
        [[ADClient sharedClient] determineAppInstallationAttributionWithCompletionHandler:^(BOOL appInstallationWasAttributedToiAd) {
            [MATUtils setUserDefaultValue:@(appInstallationWasAttributedToiAd) forKey:KEY_IAD_ATTRIBUTION];
            self.parameters.iadAttribution = @(appInstallationWasAttributedToiAd);
            if( appInstallationWasAttributedToiAd )
                [self trackInstallPostConversionWithReferenceId:refId];
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

-(void) notifyDelegateFailureWithErrorCode:(MATErrorCode)errorCode key:(NSString*)errorKey message:(NSString*)errorMessage
{
    if ([self.delegate respondsToSelector:@selector(mobileAppTrackerDidFailWithError:)]) {
        NSDictionary *errorDetails = @{NSLocalizedFailureReasonErrorKey: errorKey,
                                       NSLocalizedDescriptionKey: errorMessage};
        NSError *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:errorCode userInfo:errorDetails];
        
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
                                                domainName:[self.parameters domainName:debugMode]
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

- (void)setAllowDuplicateRequests:(BOOL)allowDuplicates
{
    DLog(@"MAT: setAllowDuplicateRequests = %d", allowDuplicates);
    
    self.connectionManager.shouldAllowDuplicates = allowDuplicates;
    
    // show an alert if the allow duplicate requests   enabled
    if(allowDuplicates && [UIApplication sharedApplication]) {
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


-(void) setPayingUser:(BOOL)isPayingUser
{
    self.parameters.payingUser = @(isPayingUser);
    [MATUtils setUserDefaultValue:@(isPayingUser) forKey:KEY_IS_PAYING_USER];
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
-(void)sendRequestWithEventItems:(NSArray *)eventItems receipt:(NSString *)receipt referenceId:(NSString*)refId
{
    //----------------------------
    // Always look for a facebook cookie because it could change often.
    //----------------------------
    [self.parameters loadFacebookCookieId];
    
    NSSet * ignoreParams = [NSSet setWithObjects:KEY_REDIRECT_URL, KEY_KEY, nil];
    NSString * trackingLink = [self.parameters urlStringForReferenceId:refId
                                                             debugMode:debugMode
                                                          ignoreParams:ignoreParams
                                                       encryptionLevel:NORMALLY_ENCRYPTED];
    
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
        [postDict setValue:receipt forKey:KEY_STORE_RECEIPT];
    
    NSString *strPost = nil;
    
    if(postDict.count > 0) {
        DLog(@"post data before serialization = %@", postDict);
        strPost = [MATUtils jsonSerialize:postDict];
        DLog(@"post data after  serialization = %@", strPost);
    }
    
    NSDate *runDate = [NSDate date];
    if( [self.parameters.actionName isEqualToString:EVENT_SESSION] )
        runDate = [runDate dateByAddingTimeInterval:5.];
    
    // fire the event tracking request
    [self.connectionManager enqueueUrlRequest:trackingLink andPOSTData:strPost runDate:runDate];

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
        [self notifyDelegateFailureWithErrorCode:MATServerErrorResponse
                                             key:KEY_ERROR_MAT_SERVER_ERROR
                                         message:strData];
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
    return [self.parameters.iadAttribution boolValue];
}


@end
