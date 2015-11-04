//
//  TuneTracker.m
//  Tune
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import "TuneTracker.h"

#import "../Tune.h"
#import "../TuneEventItem.h"
#import "../TunePreloadData.h"

#import "TuneAppToAppTracker.h"
#import "TuneCWorks.h"
#import "TuneEvent_internal.h"
#import "TuneEventQueue.h"
#import "TuneFBBridge.h"
#import "TuneIfa.h"
#import "TuneKeyStrings.h"
#import "TuneLocationHelper.h"
#import "TuneRegionMonitor.h"
#import "TuneSettings.h"

#if !TARGET_OS_WATCH
#import "TuneStoreKitDelegate.h"
#endif

#import "TuneUserAgentCollector.h"
#import "TuneUtils.h"

#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>

#if USE_IAD
#import <iAd/iAd.h>
#endif

#if TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#endif

static const int TUNE_CONVERSION_KEY_LENGTH      = 32;

#if USE_IAD
const NSTimeInterval TUNE_SESSION_QUEUING_DELAY  = 15.;
#else
const NSTimeInterval TUNE_SESSION_QUEUING_DELAY  = 0.;
#endif

const NSTimeInterval MAX_WAIT_TIME_FOR_INIT     = 1.0;
const NSTimeInterval TIME_STEP_FOR_INIT_WAIT    = 0.1;

const NSInteger MAX_REFERRAL_URL_LENGTH         = 8192; // 8 KB


@interface TuneEventItem(PrivateMethods)

+ (NSArray *)dictionaryArrayForEventItems:(NSArray *)items;

- (NSDictionary *)dictionary;

@end


@interface TuneTracker() <TuneEventQueueDelegate
#if USE_IAD
, ADBannerViewDelegate
#endif
>
{
#if USE_IAD
    ADBannerView *iAd;
#endif
    BOOL debugMode;
    
    TuneAppToAppTracker *appToAppTracker;
    TuneRegionMonitor *regionMonitor;
}

@property (nonatomic, assign, getter=isTrackerStarted) BOOL trackerStarted;

@property (nonatomic, assign) BOOL shouldDetectJailbroken;
@property (nonatomic, assign) BOOL shouldCollectAdvertisingIdentifier;
@property (nonatomic, assign) BOOL shouldGenerateVendorIdentifier;

@property (nonatomic, strong) NSMutableArray *alertMessages;
@property (nonatomic, assign) BOOL isWatchAlertVisible;

@end


@implementation TuneTracker


#pragma mark - Init methods

- (id)init
{
    if (self = [super init])
    {
        // create an empty parameters object
        // this won't generate any auto params yet
        self.parameters = [TuneSettings new];
        
#if DEBUG_STAGING
        self.parameters.staging = YES;
#endif
        
        // delay user-agent collection to avoid threading related app crash
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // initiate collection of user agent string
            [TuneUserAgentCollector startCollection];
        });
#if TARGET_OS_IOS
        // provide access to location when available
        [TuneLocationHelper class];
#endif
        [TuneEventQueue setDelegate:self];
        
        // !!! very important to init some parms here
        _shouldUseCookieTracking = NO; // by default do not use cookie tracking
        [self setShouldAutoDetectJailbroken:YES];
#if TARGET_OS_IOS
        [self setShouldAutoCollectDeviceLocation:YES];
#endif
        
#if !TARGET_OS_WATCH
        [self setShouldAutoCollectAppleAdvertisingIdentifier:YES];
        [self setShouldAutoGenerateAppleVendorIdentifier:YES];
#endif
        // the user can turn these off before calling a method which will
        // remove the keys. turning them back on will regenerate the keys.
        
        // collect IFA if accessible
        [self updateIfa];
        
        self.alertMessages = [NSMutableArray array];
        
#if USE_IAD
        [self checkIadAttribution:nil];
#endif
    }
    return self;
}


#pragma mark - Public Methods

- (TuneRegionMonitor*)regionMonitor
{
    if( !regionMonitor )
        regionMonitor = [TuneRegionMonitor new];
    return regionMonitor;
}

- (void)startTrackerWithTuneAdvertiserId:(NSString *)aid tuneConversionKey:(NSString *)key wearable:(BOOL)wearable
{
    self.trackerStarted = NO;
    
    NSString *aid_ = [aid stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *key_ = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if(0 == aid_.length)
    {
        [self notifyDelegateFailureWithErrorCode:TuneNoAdvertiserIDProvided
                                             key:TUNE_KEY_ERROR_TUNE_ADVERTISER_ID_MISSING
                                         message:@"No TUNE Advertiser Id provided."];
        return;
    }
    if(0 == key_.length)
    {
        [self notifyDelegateFailureWithErrorCode:TuneNoConversionKeyProvided
                                             key:TUNE_KEY_ERROR_TUNE_CONVERSION_KEY_MISSING
                                         message:@"No TUNE Conversion Key provided."];
        return;
    }
    if(TUNE_CONVERSION_KEY_LENGTH != key_.length)
    {
        [self notifyDelegateFailureWithErrorCode:TuneInvalidConversionKey
                                             key:TUNE_KEY_ERROR_TUNE_CONVERSION_KEY_INVALID
                                         message:[NSString stringWithFormat:@"Invalid TUNE Conversion Key provided, length = %lu. Expected key length = %d", (unsigned long)key_.length, TUNE_CONVERSION_KEY_LENGTH]];
        return;
    }
    
    self.parameters.advertiserId = aid_;
    self.parameters.conversionKey = key_;
    self.parameters.wearable = wearable;
    self.trackerStarted = YES;
    
    NSString *strNotif = nil;
#if TARGET_OS_WATCH
    strNotif = NSExtensionHostWillResignActiveNotification;
#else
    strNotif = UIApplicationWillResignActiveNotification;
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNotification:)
                                                 name:strNotif
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
    
    [TuneEventQueue updateEnqueuedEventsWithReferralUrl:urlString referralSource:sourceApplication];
}


#pragma mark - Notfication Handlers

- (void)handleNotification:(NSNotification *)notice
{
    NSString *strNotif = nil;
#if TARGET_OS_WATCH
    strNotif = NSExtensionHostWillResignActiveNotification;
#else
    strNotif = UIApplicationWillResignActiveNotification;
#endif
    
    if([notice.name isEqualToString:strNotif])
    {
        // make sure that the user default local storage is written to disk before the app closes
        [TuneUtils synchronizeUserDefaults];
    }
}


#if USE_IAD

#pragma mark - iAd methods

/*!
 Check if the app install was attributed to an iAd. If attributed to iAd, the optionally provided code block is executed. This method is a no-op on successive calls.
 @param attributionBlock optional code block to be executed if install has been attributed to iAd
 */
- (void)checkIadAttribution:(void (^)(BOOL iadAttributed))attributionBlock
{
    // Since app install iAd attribution value does not change, collect it only once and store it to disk. After that, reuse the stored info.
    if( [UIApplication sharedApplication] && [ADClient class] && self.parameters.iadAttribution == nil ) {
        // for devices >= 7.1
        ADClient *adClient = [ADClient sharedClient];
        
#ifdef __IPHONE_9_0 // if Tune is built in Xcode 7
        if( [adClient respondsToSelector:@selector(requestAttributionDetailsWithBlock:)] ) {
            [adClient requestAttributionDetailsWithBlock:^(NSDictionary *attributionDetails, NSError *error) {
                
                if( error.code == ADClientErrorLimitAdTracking ) {
                    // value will never be available, so don't try again
                    // NOTE: legally, iAd could provide attribution information in this case, but chooses not to
                    self.parameters.iadAttribution = @NO;
                }
                else if( error ) {
                    return; // don't call attribution block
                }
                else
                {
                    // iOS 7.1
                    if( attributionDetails[@"iad-attribution"] ) self.parameters.iadAttribution = attributionDetails[@"iad-attribution"];
                    // iOS 8
                    if( attributionDetails[@"iad-impression-date"] ) {
                        NSDateFormatter *formatter = [NSDateFormatter new];
                        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
                        self.parameters.iadImpressionDate = [formatter dateFromString:attributionDetails[@"iad-impression-date"]];
                    }
                    // iOS 9
                    if( attributionDetails[@"iad-campaign-id"] ) self.parameters.iadCampaignId = attributionDetails[@"iad-campaign-id"];
                    if( attributionDetails[@"iad-campaign-name"] ) self.parameters.iadCampaignName = attributionDetails[@"iad-campaign-name"];
                    if( attributionDetails[@"iad-org-name"] ) self.parameters.iadCampaignOrgName = attributionDetails[@"iad-org-name"];
                    if( attributionDetails[@"iad-lineitem-id"] ) self.parameters.iadLineId = attributionDetails[@"iad-lineitem-id"];
                    if( attributionDetails[@"iad-lineitem-name"] ) self.parameters.iadLineName = attributionDetails[@"iad-lineitem-name"];
                    if( attributionDetails[@"iad-creative-id"] ) self.parameters.iadCreativeId = attributionDetails[@"iad-creative-id"];
                    if( attributionDetails[@"iad-creative-name"] ) self.parameters.iadCreativeName = attributionDetails[@"iad-creative-name"];
                }
                
                if( attributionBlock )
                    attributionBlock( self.parameters.iadAttribution.boolValue );
            }];
        }
        else
#endif
        if( [adClient respondsToSelector:@selector(lookupAdConversionDetails:)] ) {
            // device is iOS 8.0
            [[ADClient sharedClient] lookupAdConversionDetails:^(NSDate *appPurchaseDate, NSDate *iAdImpressionDate) {
                BOOL iAdOriginatedInstallation = (iAdImpressionDate != nil);
                [TuneUtils setUserDefaultValue:@(iAdOriginatedInstallation) forKey:TUNE_KEY_IAD_ATTRIBUTION];
                self.parameters.iadAttribution = @(iAdOriginatedInstallation);
                self.parameters.iadImpressionDate = iAdImpressionDate;
                if( attributionBlock )
                    attributionBlock( iAdOriginatedInstallation );
            }];
        }
        else {
            // device is iOS 7.1
            [adClient determineAppInstallationAttributionWithCompletionHandler:^(BOOL appInstallationWasAttributedToiAd) {
                [TuneUtils setUserDefaultValue:@(appInstallationWasAttributedToiAd) forKey:TUNE_KEY_IAD_ATTRIBUTION];
                self.parameters.iadAttribution = @(appInstallationWasAttributedToiAd);
                if( attributionBlock )
                    attributionBlock( appInstallationWasAttributedToiAd );
            }];
        }
    }
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // Note: This method of sizing the banner is deprecated in iOS 6.0.
    if( iAd.superview.frame.size.width <= [UIScreen mainScreen].bounds.size.width ) {
        if( debugMode ) NSLog( @"Tune: laying out iAd in portrait orientation: superview's frame is %@", NSStringFromCGRect( iAd.superview.frame ) );
        iAd.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
    }
    else {
        if( debugMode ) NSLog( @"Tune: laying out iAd in landscape orientation: superview's frame is %@", NSStringFromCGRect( iAd.superview.frame ) );
        iAd.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
    }
#pragma clang diagnostic pop
    
    if( iAd.bannerLoaded ) {
        if( debugMode ) NSLog( @"Tune: iAd has banner loaded, displaying its superview" );
        iAd.superview.alpha = 1.;
        if( [_delegate respondsToSelector:@selector(tuneDidDisplayiAd)] )
            [_delegate tuneDidDisplayiAd];
    }
    else {
        if( debugMode ) NSLog( @"Tune: iAd has no banner loaded, hiding its superview" );
        iAd.superview.alpha = 0.;
        if( [_delegate respondsToSelector:@selector(tuneDidRemoveiAd)] )
            [_delegate tuneDidRemoveiAd];
    }
}

- (void)removeiAd
{
    [iAd removeFromSuperview];
    iAd = nil;
    
    if( [_delegate respondsToSelector:@selector(tuneDidRemoveiAd)] )
        [_delegate tuneDidRemoveiAd];
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
    
    if( [_delegate respondsToSelector:@selector(tuneFailedToReceiveiAdWithError:)] )
        [_delegate tuneFailedToReceiveiAdWithError:error];
}


#endif


#pragma mark - Measure Event Methods

- (void)measureInstallPostConversion
{
    TuneEvent *event = [TuneEvent eventWithName:TUNE_EVENT_INSTALL];
    event.postConversion = YES;

    [self measureEvent:event];
}

- (void)measureEvent:(TuneEvent *)event
{
    if(!self.isTrackerStarted) {
        [self notifyDelegateFailureWithErrorCode:TuneMeasurementWithoutInitializing
                                             key:TUNE_KEY_ERROR_TUNE_INVALID_PARAMETERS
                                         message:@"Invalid Tune Advertiser Id or Tune Conversion Key passed in."];
        
        return;
    }
    
    // 05152013: Now TUNE has dropped support for "close" events,
    // so we ignore the "close" event and return an error message using the delegate.
    if(event.eventName && [[event.eventName lowercaseString] isEqualToString:TUNE_EVENT_CLOSE]) {
        [self notifyDelegateFailureWithErrorCode:TuneInvalidEventClose
                                             key:TUNE_KEY_ERROR_TUNE_CLOSE_EVENT
                                         message:@"TUNE does not support measurement of \"close\" event."];
        
        return;
    }
    
    if( event.revenue > 0 )
        [self setPayingUser:YES];
    
    self.parameters.systemDate = [NSDate date];
    
    // include CWorks params
    NSDictionary *dictCworksClick;
    NSDictionary *dictCworksImpression;
    [self generateCworksClick:&dictCworksClick impression:&dictCworksImpression];
    event.cworksClick = dictCworksClick;
    event.cworksImpression = dictCworksImpression;
    
    if(self.shouldCollectAdvertisingIdentifier)
    {
        // collect IFA if accessible
        [self updateIfa];
    }
    
    // if the device location has not been explicitly set, try to auto-collect
    if(self.shouldCollectDeviceLocation && !self.parameters.location)
    {
        // check if location already exists
        BOOL locationEnabled = [TuneLocationHelper isLocationEnabled];
        
        DLog(@"called getOrRequestDeviceLocation: location enabled = %d, location = %@", locationEnabled, self.parameters.location);
        
        if(locationEnabled)
        {
            TuneLocation *location = [TuneLocationHelper getOrRequestDeviceLocation];
            if (location)
            {
                event.location = location;
            }
            else
            {
                DLog(@"delaying event request to wait for location update");
                // delay event request by a few seconds to allow location update
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, TUNE_LOCATION_UPDATE_DELAY * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    DLog(@"firing delayed location check");
                    event.location = [TuneLocationHelper getOrRequestDeviceLocation];
                    
                    [self sendRequestAndCheckIadAttributionForEvent:event];
                });
                
                return;
            }
        }
    }
    
    [self sendRequestAndCheckIadAttributionForEvent:event];
}

- (void)sendRequestAndCheckIadAttributionForEvent:(TuneEvent *)event
{
    // fire the tracking request
    [self sendRequestWithEvent:event];
    
#if USE_IAD
    if( [event.actionName isEqualToString:TUNE_EVENT_SESSION] )
    {
        [self checkIadAttribution:^(BOOL iadAttributed) {
            if( iadAttributed )
                [self measureInstallPostConversion];
        }];
    }
#endif
}

#pragma mark - Tune Delegate Callback Helper Methods

- (void)notifyDelegateSuccessMessage:(NSString *)message
{
    if ([self.delegate respondsToSelector:@selector(tuneDidSucceedWithData:)])
    {
        [self.delegate tuneDidSucceedWithData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void)notifyDelegateFailureWithErrorCode:(TuneErrorCode)errorCode key:(NSString*)errorKey message:(NSString*)errorMessage
{
    if ([self.delegate respondsToSelector:@selector(tuneDidFailWithError:)]) {
        NSDictionary *errorDetails = @{NSLocalizedFailureReasonErrorKey: errorKey ?: @"",
                                              NSLocalizedDescriptionKey: errorMessage ?: @""};
        NSError *error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN code:errorCode userInfo:errorDetails];
    
        [self.delegate tuneDidFailWithError:error];
    }
}


#pragma mark - Start app-to-app tracking session

- (void)setMeasurement:(NSString*)targetAppPackageName
          advertiserId:(NSString*)targetAppAdvertiserId
               offerId:(NSString*)offerId
           publisherId:(NSString*)publisherId
              redirect:(BOOL)shouldRedirect
{
    appToAppTracker = [TuneAppToAppTracker new];
    appToAppTracker.delegate = self;
    
    [appToAppTracker startMeasurementSessionForTargetBundleId:targetAppPackageName
                                            publisherBundleId:[TuneUtils bundleId]
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
        self.parameters.jailbroken = @([TuneUtils checkJailBreak]);
    else
        self.parameters.jailbroken = nil;
}

#if TARGET_OS_IOS
- (void)setShouldAutoCollectDeviceLocation:(BOOL)shouldAutoCollect
{
    self.shouldCollectDeviceLocation = shouldAutoCollect;
}
#endif

#if !TARGET_OS_WATCH
- (void)setShouldAutoCollectAppleAdvertisingIdentifier:(BOOL)shouldAutoCollect
{
    self.shouldCollectAdvertisingIdentifier = shouldAutoCollect;
    if( shouldAutoCollect )
    {
        [self updateIfa];
    }
    else
    {
        self.parameters.ifa = nil;
        self.parameters.ifaTracking = @(NO);
    }
}

- (void)setShouldAutoGenerateAppleVendorIdentifier:(BOOL)shouldAutoGenerate
{
    self.shouldGenerateVendorIdentifier = shouldAutoGenerate;
    if( shouldAutoGenerate ) {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
            NSString *uuidStr = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
            if (uuidStr && ![uuidStr isEqualToString:TUNE_KEY_GUID_EMPTY]) {
                self.parameters.ifv = uuidStr;
            }
        }
    }
    else
        self.parameters.ifv = nil;
}
#endif


#pragma mark - Non-trivial setters

- (void)setDebugMode:(BOOL)newDebugMode
{
    DLog(@"Tune: setDebugMode = %d", newDebugMode);
    
    debugMode = newDebugMode;
    self.parameters.debugMode = @(newDebugMode);
    
    // show an alert if the debug mode is enabled
    if(newDebugMode) {
#if TARGET_OS_WATCH
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self showWarningAlert:@"TUNE Debug Mode Enabled. Use only when debugging, do not release with this enabled!"];
        }];
#else
        if([UIApplication sharedApplication]) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                id <UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
                if( [appDelegate respondsToSelector:@selector(window)] && [UIAlertController class] ) {
                    [self showWarningAlert:@"TUNE Debug Mode Enabled. Use only when debugging, do not release with this enabled!"];
                }
                else {
                    NSLog( @"***********************************************************************************" );
                    NSLog( @"TUNE Debug Mode Enabled. Use only when debugging, do not release with this enabled!" );
                    NSLog( @"***********************************************************************************" );
                }
            }];
        }
#endif
    }
}

- (void)setAllowDuplicateRequests:(BOOL)newAllowDuplicates
{
    DLog(@"Tune: setAllowDuplicateRequests = %d", newAllowDuplicates);
    
    self.parameters.allowDuplicates = @(newAllowDuplicates);
    
    // show an alert if the allow duplicate requests   enabled
    if(newAllowDuplicates) {
#if TARGET_OS_WATCH
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self showWarningAlert:@"TUNE Duplicate Requests Enabled. Use only when debugging, do not release with this enabled!"];
        }];
#else
        if([UIApplication sharedApplication]) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                id <UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
                if( [appDelegate respondsToSelector:@selector(window)] && [UIAlertController class] ) {
                    [self showWarningAlert:@"TUNE Duplicate Requests Enabled. Use only when debugging, do not release with this enabled!"];
                }
                else {
                    NSLog( @"*******************************************************************************************" );
                    NSLog( @"TUNE Duplicate Requests Enabled. Use only when debugging, do not release with this enabled!" );
                    NSLog( @"*******************************************************************************************" );
                }
            }];
        }
#endif
    }
}

- (void)showWarningAlert:(NSString *)warning
{
    if(warning)
    {
        BOOL isAlertVisible = 
#if TARGET_OS_WATCH
        self.isWatchAlertVisible;
#else
        nil != [[UIApplication sharedApplication].delegate.window.rootViewController presentedViewController];
#endif
        
        if(isAlertVisible)
        {
            [self.alertMessages addObject:warning];
        }
        else
        {
#if TARGET_OS_WATCH
            self.isWatchAlertVisible = YES;
            
            WKAlertAction *alertAction = [WKAlertAction actionWithTitle:@"OK" style:WKAlertActionStyleCancel handler:^{
                self.isWatchAlertVisible = NO;
                NSString *nextMessage = [self.alertMessages firstObject];
                if(nextMessage)
                {
                    [self showWarningAlert:nextMessage];
                    [self.alertMessages removeObjectAtIndex:0];
                }
            }];
            
            [[[WKExtension sharedExtension] rootInterfaceController] presentAlertControllerWithTitle:@"Warning"
                                                                                             message:warning
                                                                                      preferredStyle:WKAlertControllerStyleAlert
                                                                                             actions:@[alertAction]];
#else
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning"
                                                                           message:warning
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        NSString *nextMessage = [self.alertMessages firstObject];
                                                        if(nextMessage)
                                                        {
                                                            [self showWarningAlert:nextMessage];
                                                            [self.alertMessages removeObjectAtIndex:0];
                                                        }
                                                    }]];
            
            [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert animated:YES completion:nil];
#endif
        }
    }
}

- (void)setPayingUser:(BOOL)isPayingUser
{
    self.parameters.payingUser = @(isPayingUser);
    [TuneUtils setUserDefaultValue:@(isPayingUser) forKey:TUNE_KEY_IS_PAYING_USER];
}

#if !TARGET_OS_WATCH
- (void)setAutomateIapMeasurement:(BOOL)automate
{
    _automateIapMeasurement = automate;
    
    if(automate)
    {
        // start listening for in-app-purchase transactions
        [TuneStoreKitDelegate startObserver];
    }
    else
    {
        // stop listening for in-app-purchase transactions
        [TuneStoreKitDelegate stopObserver];
    }
}
#endif

- (void)setPreloadData:(TunePreloadData *)preloadData
{
    self.parameters.preloadData = preloadData;
}

#pragma mark - Private Methods

- (void)generateCworksClick:(NSDictionary **)cworksClick impression:(NSDictionary **)cworksImpression
{
    // Note: set CWorks click param
    NSString *cworksClickKey = nil;
    NSNumber *cworksClickValue = nil;
    
    [self fetchCWorksClickKey:&cworksClickKey andValue:&cworksClickValue];
    DLog(@"cworks=%@:%@", cworksClickKey, cworksClickValue);
    if(nil != cworksClickKey && nil != cworksClickValue)
    {
        *cworksClick = @{cworksClickKey: cworksClickValue};
    }
    
    // Note: set CWorks impression param
    NSString *cworksImpressionKey = nil;
    NSNumber *cworksImpressionValue = nil;
    
    [self fetchCWorksImpressionKey:&cworksImpressionKey andValue:&cworksImpressionValue];
    DLog(@"cworks imp=%@:%@", cworksImpressionKey, cworksImpressionValue);
    if(nil != cworksImpressionKey && nil != cworksImpressionValue)
    {
        *cworksImpression = @{cworksImpressionKey: cworksImpressionValue};
    }
}

// Includes the eventItems and referenceId and fires the tracking request
- (void)sendRequestWithEvent:(TuneEvent *)event
{
    if(self.fbLogging)
    {
        // call the Facebook event logging methods on main thread to make sure FBSession threading requirements are met
        dispatch_async( dispatch_get_main_queue(), ^{
            [TuneFBBridge sendEvent:event parameters:self.parameters limitEventAndDataUsage:self.fbLimitUsage];
        });
    }
    
    NSString *trackingLink, *encryptParams;
    
    [self.parameters urlStringForEvent:event
                          trackingLink:&trackingLink
                         encryptParams:&encryptParams];
    
    DRLog(@"Tune sendRequestWithEvent: %@", trackingLink);
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionary];
    
    // if present then serialize the eventItems
    if([event.eventItems count] > 0)
    {
        BOOL areEventsLegit = YES;
        for( id item in event.eventItems )
            if( ![item isMemberOfClass:[TuneEventItem class]] )
                areEventsLegit = NO;
        
        if( areEventsLegit ) {
            // Convert the array of TuneEventItem objects to an array of equivalent dictionary representations.
            NSArray *arrDictEventItems = [TuneEventItem dictionaryArrayForEventItems:event.eventItems];
            
            DLog(@"Tune sendRequestWithEvent: %@", arrDictEventItems);
            [postDict setValue:arrDictEventItems forKey:TUNE_KEY_DATA];
        }
    }
    
    if(event.receipt.length > 0)
    {
        // Base64 encode the IAP receipt data
        NSString *strReceipt = [TuneUtils tuneBase64EncodedStringFromData:event.receipt];
        [postDict setValue:strReceipt forKey:TUNE_KEY_STORE_RECEIPT];
    }
    
    // on first open, send install receipt
    if( self.parameters.openLogId == nil )
        [postDict setValue:self.parameters.installReceipt forKey:TUNE_KEY_INSTALL_RECEIPT];
    
    NSString *strPost = nil;
    
    if(postDict.count > 0)
    {
        DLog(@"post data before serialization = %@", postDict);
        strPost = [TuneUtils jsonSerialize:postDict];
        DLog(@"post data after  serialization = %@", strPost);
    }
    
    NSDate *runDate = [NSDate date];
    
#if USE_IAD
    if( [event.actionName isEqualToString:TUNE_EVENT_SESSION] )
        runDate = [runDate dateByAddingTimeInterval:TUNE_SESSION_QUEUING_DELAY];
#endif
    
    // fire the event tracking request
    [TuneEventQueue enqueueUrlRequest:trackingLink eventAction:event.actionName encryptParams:encryptParams postData:strPost runDate:runDate];
    
    if( [self.delegate respondsToSelector:@selector(tuneEnqueuedActionWithReferenceId:)] )
    {
        [self.delegate tuneEnqueuedActionWithReferenceId:event.refId];
    }
}

- (void)updateIfa
{
    TuneIfa *ifaInfo = [TuneIfa ifaInfo];
    if(ifaInfo)
    {
        self.parameters.ifa = ifaInfo.ifa;
        self.parameters.ifaTracking = @(ifaInfo.trackingEnabled);
    }
}

#pragma mark - CWorks Method Calls

- (void)fetchCWorksClickKey:(NSString **)key andValue:(NSNumber **)value
{
    // Note: TUNE_getClicks() method also deletes the stored click key/value
    NSDictionary *dict = [TuneCWorks TUNE_getClicks:[TuneUtils bundleId]];
    
    if([dict count] > 0)
    {
        *key = [NSString stringWithFormat:@"%@[%@]", TUNE_KEY_CWORKS_CLICK, [[dict allKeys] objectAtIndex:0]];
        *value = [dict objectForKey:[[dict allKeys] objectAtIndex:0]];
    }
}

- (void)fetchCWorksImpressionKey:(NSString **)key andValue:(NSNumber **)value
{
    // Note: TUNE_getImpressions() method also deletes the stored impression key/value
    NSDictionary *dict = [TuneCWorks TUNE_getImpressions:[TuneUtils bundleId]];
    
    if([dict count] > 0)
    {
        *key = [NSString stringWithFormat:@"%@[%@]", TUNE_KEY_CWORKS_IMPRESSION, [[dict allKeys] objectAtIndex:0]];
        *value = [dict objectForKey:[[dict allKeys] objectAtIndex:0]];
    }
}


#pragma mark - TuneEventQueueDelegate protocol methods

- (void)queueRequestDidSucceedWithData:(NSData *)data
{
    NSString *strData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if(!strData || [strData rangeOfString:[NSString stringWithFormat:@"\"%@\":true", TUNE_KEY_SUCCESS]].location == NSNotFound)
    {
        [self notifyDelegateFailureWithErrorCode:TuneServerErrorResponse
                                             key:TUNE_KEY_ERROR_TUNE_SERVER_ERROR
                                         message:strData];
        return;
    }
    
    // if the server response contains an open_log_id, then store it for future use
    if([strData rangeOfString:[NSString stringWithFormat:@"\"%@\":\"%@\"", TUNE_KEY_SITE_EVENT_TYPE, TUNE_EVENT_OPEN]].location != NSNotFound &&
       [strData rangeOfString:[NSString stringWithFormat:@"\"%@\":\"", TUNE_KEY_LOG_ID]].location != NSNotFound)
    {
        // regex to find the value of log_id json key
        NSString *pattern = [NSString stringWithFormat:@"(?<=\"%@\":\")([\\w\\d\\-]+)\"", TUNE_KEY_LOG_ID];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:strData options:NSMatchingReportCompletion range:NSMakeRange(0, [strData length])];
        
        // if the required match is found
        if(match.range.location != NSNotFound)
        {
            NSString *log_id = [strData substringWithRange:[match rangeAtIndex:1]];
            
            // store open_log_id if there is no other
            if( ![TuneUtils userDefaultValueforKey:TUNE_KEY_OPEN_LOG_ID] ) {
                self.parameters.openLogId = log_id;
                [TuneUtils setUserDefaultValue:log_id forKey:TUNE_KEY_OPEN_LOG_ID];
            }
            
            // store last_open_log_id
            self.parameters.lastOpenLogId = log_id;
            [TuneUtils setUserDefaultValue:log_id forKey:TUNE_KEY_LAST_OPEN_LOG_ID];
        }
    }
    
    [self notifyDelegateSuccessMessage:strData];
}

- (void)queueRequestDidFailWithError:(NSError *)error
{
    if([self.delegate respondsToSelector:@selector(tuneDidFailWithError:)])
    {
        [self.delegate tuneDidFailWithError:error];
    }
}

/*!
 Waits for Tune initialization for max duration of MAX_WAIT_TIME_FOR_INIT second(s)
 in increments of TIME_STEP_FOR_INIT_WAIT second(s).
 */
- (void)waitForInit
{
    NSDate *maxWait = nil;
    
    while( !_trackerStarted ) {
        if( maxWait == nil )
            maxWait = [NSDate dateWithTimeIntervalSinceNow:MAX_WAIT_TIME_FOR_INIT];
        else if( [maxWait timeIntervalSinceNow] < 0 ) { // is this right? time is hard
            NSLog( @"Tune timeout waiting for initialization" );
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

@end
