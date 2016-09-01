//
//  TuneTracker.m
//  Tune
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import "TuneTracker.h"

#import "Tune+Internal.h"
#import "TuneAppToAppTracker.h"
#import "TuneConfiguration.h"
#import "TuneConfigurationKeys.h"
#import "TuneCWorks.h"
#import "TuneEvent+Internal.h"
#import "TuneEventItem+Internal.h"
#import "TuneEventKeys.h"
#import "TuneEventQueue.h"
#import "TuneFBBridge.h"
#import "TuneIfa.h"
#import "TuneKeyStrings.h"
#import "TuneLocation+Internal.h"
#import "TuneLocationHelper.h"
#import "TuneManager.h"
#import "TuneRegionMonitor.h"
#import "TuneSkyhookCenter.h"

#if !TARGET_OS_WATCH
#import "TuneStoreKitDelegate.h"
#endif

#import "TuneUserAgentCollector.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneUserProfile.h"
#import "TuneUserProfileKeys.h"
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

#if TESTING
    const NSTimeInterval TUNE_SESSION_QUEUING_DELAY  = 1.;
#else
    #if USE_IAD
        const NSTimeInterval TUNE_SESSION_QUEUING_DELAY = 15.;
    #else
        // delay the session requests to allow deferred deep linking requests to complete
        const NSTimeInterval TUNE_SESSION_QUEUING_DELAY = 5.;
    #endif
#endif

const NSTimeInterval MAX_WAIT_TIME_FOR_INIT     = 1.0;
const NSTimeInterval TIME_STEP_FOR_INIT_WAIT    = 0.1;

const NSInteger MAX_REFERRAL_URL_LENGTH         = 8192; // 8 KB

static NSSet * ignoreParams;
static NSSet * doNotEncryptSet;

@interface TuneEventItem(PrivateMethods)

+ (NSArray *)dictionaryArrayForEventItems:(NSArray *)items;

- (NSDictionary *)dictionary;

@end


@interface TuneTracker() <TuneEventQueueDelegate>
{
    TuneAppToAppTracker *appToAppTracker;
    TuneRegionMonitor *regionMonitor;
}

@property (nonatomic, assign, getter=isTrackerStarted) BOOL trackerStarted;

@property (nonatomic, assign, getter=isFirstSessionOnAppActive) BOOL firstSessionOnAppActive;

@property (nonatomic, copy) NSDictionary *iAdAttributionInfo;

@end


@implementation TuneTracker


#pragma mark - init methods
+ (void)initialize {
    ignoreParams = [NSSet setWithObjects:TUNE_KEY_REDIRECT_URL, TUNE_KEY_KEY, nil];
    
    doNotEncryptSet = [NSSet setWithObjects:TUNE_KEY_ADVERTISER_ID, TUNE_KEY_ACTION,
                       TUNE_KEY_SITE_EVENT_ID, TUNE_KEY_SDK, TUNE_KEY_VER, TUNE_KEY_SITE_EVENT_NAME,
                       TUNE_KEY_REFERRAL_URL, TUNE_KEY_REFERRAL_SOURCE, TUNE_KEY_TRACKING_ID, TUNE_KEY_PACKAGE_NAME,
                       TUNE_KEY_TRANSACTION_ID, TUNE_KEY_RESPONSE_FORMAT, nil];
}

- (id)init {
    if(self = [super init]) {
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
        
#if !TARGET_OS_WATCH
        // collect IFA if accessible
        [[TuneManager currentManager].userProfile updateIFA];
#endif
        
#if USE_IAD
        _iAdAttributionInfo = [TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_IAD_ATTRIBUTION_DATA];
        
        // skip the iAd attribution check, if the info has been previously stored
        if(!_iAdAttributionInfo) {
            [self checkIadAttribution:nil];
        }
#endif
    }
    return self;
}


#pragma mark - Public Methods

- (TuneRegionMonitor*)regionMonitor {
    if( !regionMonitor )
        regionMonitor = [TuneRegionMonitor new];
    return regionMonitor;
}

- (void)startTracker {
    self.trackerStarted = NO;
    
    if(0 == [[TuneManager currentManager].userProfile advertiserId].length) {
        [self notifyDelegateFailureWithErrorCode:TuneNoAdvertiserIDProvided
                                             key:TUNE_KEY_ERROR_TUNE_ADVERTISER_ID_MISSING
                                         message:@"No TUNE Advertiser Id provided."];
        return;
    }
    if(0 == [[TuneManager currentManager].userProfile conversionKey].length) {
        [self notifyDelegateFailureWithErrorCode:TuneNoConversionKeyProvided
                                             key:TUNE_KEY_ERROR_TUNE_CONVERSION_KEY_MISSING
                                         message:@"No TUNE Conversion Key provided."];
        return;
    }
    if(TUNE_CONVERSION_KEY_LENGTH != [[TuneManager currentManager].userProfile conversionKey].length) {
        [self notifyDelegateFailureWithErrorCode:TuneInvalidConversionKey
                                             key:TUNE_KEY_ERROR_TUNE_CONVERSION_KEY_INVALID
                                         message:[NSString stringWithFormat:@"Invalid TUNE Conversion Key provided, length = %lu. Expected key length = %d", (unsigned long)[[TuneManager currentManager].userProfile conversionKey].length, TUNE_CONVERSION_KEY_LENGTH]];
        return;
    }
    
    self.trackerStarted = YES;
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(applicationStateChanged:)
                                              name:
#if TARGET_OS_WATCH
     NSExtensionHostWillEnterForegroundNotification
#else
     UIApplicationWillEnterForegroundNotification
#endif
                                            object:nil];
    
    _firstSessionOnAppActive = YES;
}

- (void)applicationDidOpenURL:(NSString *)urlString sourceApplication:(NSString *)sourceApplication {
    // include the params -- referring app and url -- in the next tracking request
    
    // 07-Nov-2014: limit the referral url length,
    // so that the NSXMLParser does not run out of memory
    if(urlString.length > MAX_REFERRAL_URL_LENGTH) {
        urlString = [urlString substringToIndex:MAX_REFERRAL_URL_LENGTH];
    }
    
    [[TuneManager currentManager].userProfile setReferralUrl:urlString];
    [[TuneManager currentManager].userProfile setReferralSource:sourceApplication];
    
    [TuneEventQueue updateEnqueuedEventsWithReferralUrl:urlString referralSource:sourceApplication];
}

#pragma mark - Skyhook Observer

- (void)applicationStateChanged:(TuneSkyhookPayload *)payload {
    NSString *strNotif =
#if TARGET_OS_WATCH
    NSExtensionHostWillEnterForegroundNotification;
#else
    UIApplicationWillEnterForegroundNotification;
#endif
    if([payload.skyhookName isEqualToString:strNotif]) {
        _firstSessionOnAppActive = YES;
    }
}

#if USE_IAD

#pragma mark - iAd methods

/*!
 Check if the app install was attributed to an iAd. If attributed to iAd, the optionally provided code block is executed. If the ADClient call fails because the attribution info is not available, then this method can be called again after a few seconds to retry. Once the attribution status has been determined, this method is a no-op on subsequent calls.
 @param attributionBlock optional code block to be executed if install has been attributed to iAd
 */
- (void)checkIadAttribution:(void (^)(BOOL iadAttributed, NSDictionary *attributionInfo))attributionBlock {
    // Since app install iAd attribution value does not change, collect it only once and store it to disk. After that, reuse the stored info.
    if( [self shouldCheckIadAttribution] ) {
        // for devices >= 7.1
        ADClient *adClient = [ADClient sharedClient];
        
        __weak typeof(self) weakSelf = self;
        
#ifdef __IPHONE_9_0 // if Tune is built in Xcode 7
        if( [TuneUtils object:adClient respondsToSelector:@selector(requestAttributionDetailsWithBlock:)] ) {
            // iOS 9
            [adClient requestAttributionDetailsWithBlock:^(NSDictionary *attributionDetails, NSError *error) {
                BOOL isFakeIadInfo = NO;
                
                if (error.code == ADClientErrorLimitAdTracking) {
                    // value will never be available, so don't try again
                    // NOTE: legally, iAd could provide attribution information in this case, but chooses not to
                    [[TuneManager currentManager].userProfile setIadAttribution:@NO];
                } else if (error) {
                    // iAd attribution info is not available at this time,
                    // don't call the attribution block
                    return;
                } else {
                    // Ref: iAd Attribution v3.1 API
                    __block NSDictionary *iAdCampaignInfo = (NSDictionary *)attributionDetails[@"Version3.1"];
                    __block BOOL foundVersionKey = YES;
                    
                    // if the known "Version3.1" key is not available, check if a different "VersionX.Y" dictionary key exists
                    if(!iAdCampaignInfo) {
                        [((NSDictionary *)attributionDetails) enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
                            foundVersionKey = [[key lowercaseString] hasPrefix:@"version"];
                            if(foundVersionKey) {
                                iAdCampaignInfo = (NSDictionary *)obj;
                            }
                            *stop = foundVersionKey;
                        }];
                    }
                    
                    if (foundVersionKey) {
                        if (iAdCampaignInfo[@"iad-attribution"]) {
                            BOOL isIadAttributed = [iAdCampaignInfo[@"iad-attribution"] boolValue];
                            
                            if (isIadAttributed) {
                                if ([self isFakeIadAttribution:iAdCampaignInfo]) {
                                    NSLog(@"TUNE: Ignoring fake iAd campaign attribution info: %@", iAdCampaignInfo);
                                    isFakeIadInfo = YES;
                                    isIadAttributed = NO;
                                } else {
                                    DebugLog(@"TUNE: Valid iAd campaign attribution info detected: %@", iAdCampaignInfo);
                                }
                            }
                            
                            [[TuneManager currentManager].userProfile setIadAttribution:@(isIadAttributed)];
                        }
                    }
                    
                    if (!isFakeIadInfo) {
                        // store the iAd campaign attribution info for inclusion in post data of a future install request
                        weakSelf.iAdAttributionInfo = attributionDetails;
                        [TuneUserDefaultsUtils setUserDefaultValue:attributionDetails forKey:TUNE_KEY_IAD_ATTRIBUTION_DATA];
                    }
                }
                
                [TuneUserDefaultsUtils setUserDefaultValue:@YES forKey:TUNE_KEY_IAD_ATTRIBUTION_CHECKED];
                
                if (!isFakeIadInfo && attributionBlock)
                    attributionBlock([[[TuneManager currentManager].userProfile iadAttribution] boolValue], attributionDetails);
            }];
        } else
#endif
        if ([TuneUtils object:adClient respondsToSelector:@selector(lookupAdConversionDetails:)]) {
            // device is iOS 8.0
            [[ADClient sharedClient] lookupAdConversionDetails:^(NSDate *appPurchaseDate, NSDate *iAdImpressionDate) {
                BOOL iAdOriginatedInstallation = (iAdImpressionDate != nil);
                [TuneUserDefaultsUtils setUserDefaultValue:@(iAdOriginatedInstallation) forKey:TUNE_KEY_IAD_ATTRIBUTION];
                [[TuneManager currentManager].userProfile setIadAttribution:@(iAdOriginatedInstallation)];
                [[TuneManager currentManager].userProfile setIadImpressionDate:iAdImpressionDate];
                [TuneUserDefaultsUtils setUserDefaultValue:@YES forKey:TUNE_KEY_IAD_ATTRIBUTION_CHECKED];
                if (attributionBlock)
                    attributionBlock( iAdOriginatedInstallation, nil);
            }];
        } else {
            // device is iOS 7.1
            [adClient determineAppInstallationAttributionWithCompletionHandler:^(BOOL appInstallationWasAttributedToiAd) {
                [TuneUserDefaultsUtils setUserDefaultValue:@(appInstallationWasAttributedToiAd) forKey:TUNE_KEY_IAD_ATTRIBUTION];
                [[TuneManager currentManager].userProfile setIadAttribution:@(appInstallationWasAttributedToiAd)];
                [TuneUserDefaultsUtils setUserDefaultValue:@YES forKey:TUNE_KEY_IAD_ATTRIBUTION_CHECKED];
                if (attributionBlock) {
                    attributionBlock(appInstallationWasAttributedToiAd, nil);
                }
            }];
        }
    }
}

- (BOOL)shouldCheckIadAttribution {
    return [UIApplication sharedApplication] && [ADClient class]
    && [[TuneManager currentManager].userProfile iadAttribution] == nil
    && [TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_IAD_ATTRIBUTION_CHECKED] == nil;
}

- (BOOL)isFakeIadAttribution:(NSDictionary *)dict {
    return [(NSString *)dict[@"iad-campaign-id"] isEqualToString:TUNE_FAKE_IAD_CAMPAIGN_ID]
    || [(NSString *)dict[@"iad-lineitem-id"] isEqualToString:TUNE_FAKE_IAD_CAMPAIGN_ID]
    || [(NSString *)dict[@"iad-creative-id"] isEqualToString:TUNE_FAKE_IAD_CAMPAIGN_ID];
}

#endif


#pragma mark - Measure Event Methods

- (void)measureInstallPostConversion {
    DebugLog(@"Tune measureInstallPostConversion");
    TuneEvent *event = [TuneEvent eventWithName:TUNE_EVENT_INSTALL];
    event.postConversion = YES;
    
    [self measureEvent:event];
}

- (void)measureEvent:(TuneEvent *)event {
    if ( !self.isTrackerStarted ) {
        [self notifyDelegateFailureWithErrorCode:TuneMeasurementWithoutInitializing
                                             key:TUNE_KEY_ERROR_TUNE_INVALID_PARAMETERS
                                         message:@"Invalid Tune Advertiser Id or Tune Conversion Key passed in."];
        
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if( 0 == event.eventId && !event.eventName ) {
#pragma clang diagnostic pop
        [self notifyDelegateFailureWithErrorCode:TuneInvalidEvent
                                             key:TUNE_KEY_ERROR_TUNE_INVALID_PARAMETERS
                                         message:@"Invalid event name provided. Event name cannot be nil."];
        
        return;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if( 0 == event.eventId && [event.eventName isEqualToString:TUNE_STRING_EMPTY] ) {
#pragma clang diagnostic pop
        [self notifyDelegateFailureWithErrorCode:TuneInvalidEvent
                                             key:TUNE_KEY_ERROR_TUNE_INVALID_PARAMETERS
                                         message:@"Invalid event name provided. Event name cannot be empty."];
        
        return;
    }
    
    // 05152013: Now TUNE has dropped support for "close" events,
    // so we ignore the "close" event and return an error message using the delegate.
    if( [[event.eventName lowercaseString] isEqualToString:TUNE_EVENT_CLOSE] ) {
        [self notifyDelegateFailureWithErrorCode:TuneInvalidEvent
                                             key:TUNE_KEY_ERROR_TUNE_CLOSE_EVENT
                                         message:@"TUNE does not support measurement of \"close\" event."];
        
        return;
    }
    
    // ignore duplicate 'session' events in the same session
    BOOL isSessionAction = [[event.actionName lowercaseString] isEqualToString:TUNE_EVENT_SESSION];
    BOOL shouldMeasureEvent = !isSessionAction || self.isFirstSessionOnAppActive || event.postConversion;
    
    if ( shouldMeasureEvent ) {
        if( isSessionAction ) {
            self.firstSessionOnAppActive = NO;
        }
    
        if ( event.revenue > 0 ) {
            [[TuneManager currentManager].userProfile setPayingUser:@(YES)];
        }
        
        [[TuneManager currentManager].userProfile setSystemDate:[NSDate date]];
        
        // include CWorks params
        NSDictionary *dictCworksClick;
        NSDictionary *dictCworksImpression;
        [self generateCworksClick:&dictCworksClick impression:&dictCworksImpression];
        event.cworksClick = dictCworksClick;
        event.cworksImpression = dictCworksImpression;
        
#if !TARGET_OS_WATCH
        if([TuneManager currentManager].configuration.shouldAutoCollectAdvertisingIdentifier) {
            // collect IFA if accessible
            [[TuneManager currentManager].userProfile updateIFA];
        }
#endif
        
        // if the device location has not been explicitly set, try to auto-collect
        if ([TuneManager currentManager].configuration.shouldAutoCollectDeviceLocation) {
            // check if location info is accessible
            BOOL locationEnabled = [TuneLocationHelper isLocationEnabled];
            
            // DebugLog(@"called getOrRequestDeviceLocation: location enabled = %d, location = %@", locationEnabled, location);
            
            if(locationEnabled) {
                // try accessing location
                NSMutableArray *arr = [NSMutableArray arrayWithCapacity:1];
                [[TuneLocationHelper class] performSelectorOnMainThread:@selector(getOrRequestDeviceLocation:) withObject:arr waitUntilDone:YES];
                
                // if the location is not readily available
                if( 0 == arr.count ) {
                    // wait for location update to finish
                    [NSThread sleepForTimeInterval:TUNE_LOCATION_UPDATE_DELAY];
                    
                    // retry accessing location
                    [[TuneLocationHelper class] performSelectorOnMainThread:@selector(getOrRequestDeviceLocation:) withObject:arr waitUntilDone:YES];
                }
                
                if( 1 == arr.count ) {
                    event.location = arr[0];
                    [[TuneManager currentManager].userProfile setLocation:arr[0]];
                }
            }
        }
        
        [self sendRequestAndCheckIadAttributionForEvent:event];
    } else {
        // send measurement failure callback to TuneDelegate due to duplicate measureSession call
        [self notifyDelegateFailureWithErrorCode:TuneInvalidDuplicateSession
                                             key:TUNE_KEY_ERROR_TUNE_DUPLICATE_SESSION
                                         message:@"Ignoring duplicate \"session\" event measurement call in the same session."];
    }
}

- (void)sendRequestAndCheckIadAttributionForEvent:(TuneEvent *)event {
    // fire the tracking request
    [self sendRequestWithEvent:event];
    
#if USE_IAD
    if( [event.actionName isEqualToString:TUNE_EVENT_SESSION] ) {
        // use existing stored iAd attribution info when available
        if(self.iAdAttributionInfo) {
            [self measureInstallPostConversion];
        } else {
            [self checkIadAttribution:^(BOOL iadAttributed, NSDictionary *attributionInfo) {
                if( iadAttributed || attributionInfo)
                    [self measureInstallPostConversion];
            }];
        }
    }
#endif
}

#pragma mark - Tune Delegate Callback Helper Methods

- (void)notifyDelegateSuccessMessage:(NSString *)message {
    if( [self.delegate respondsToSelector:@selector(tuneDidSucceedWithData:)] ) {
        [self.delegate tuneDidSucceedWithData:[message dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void)notifyDelegateFailureWithErrorCode:(TuneErrorCode)errorCode key:(NSString*)errorKey message:(NSString*)errorMessage {
    if( [self.delegate respondsToSelector:@selector(tuneDidFailWithError:)] ) {
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
              redirect:(BOOL)shouldRedirect {
    appToAppTracker = [TuneAppToAppTracker new];
    appToAppTracker.delegate = self;
    
    [appToAppTracker startMeasurementSessionForTargetBundleId:targetAppPackageName
                                            publisherBundleId:[TuneUtils bundleId]
                                                 advertiserId:targetAppAdvertiserId
                                                   campaignId:offerId
                                                  publisherId:publisherId
                                                     redirect:shouldRedirect
                                                   domainName:[[TuneManager currentManager].configuration domainName]];
}

#pragma mark - Private Methods

- (void)generateCworksClick:(NSDictionary **)cworksClick impression:(NSDictionary **)cworksImpression {
    // Note: set CWorks click param
    NSString *cworksClickKey = nil;
    NSNumber *cworksClickValue = nil;
    
    [self fetchCWorksClickKey:&cworksClickKey andValue:&cworksClickValue];
    DebugLog(@"cworks=%@:%@", cworksClickKey, cworksClickValue);
    if( nil != cworksClickKey && nil != cworksClickValue ) {
        *cworksClick = @{cworksClickKey: cworksClickValue};
    }
    
    // Note: set CWorks impression param
    NSString *cworksImpressionKey = nil;
    NSNumber *cworksImpressionValue = nil;
    
    [self fetchCWorksImpressionKey:&cworksImpressionKey andValue:&cworksImpressionValue];
    DebugLog(@"cworks imp=%@:%@", cworksImpressionKey, cworksImpressionValue);
    if( nil != cworksImpressionKey && nil != cworksImpressionValue ) {
        *cworksImpression = @{cworksImpressionKey: cworksImpressionValue};
    }
}

// Includes the eventItems and referenceId and fires the tracking request
- (void)sendRequestWithEvent:(TuneEvent *)event {
#if TARGET_OS_IOS
    //----------------------------
    // Always look for a facebook cookie because it could change often.
    //----------------------------
    [[TuneManager currentManager].userProfile loadFacebookCookieId];
#endif
    if(self.fbLogging) {
        // call the Facebook event logging methods on main thread to make sure FBSession threading requirements are met
        dispatch_async( dispatch_get_main_queue(), ^{
            [TuneFBBridge sendEvent:event limitEventAndDataUsage:self.fbLimitUsage];
        });
    }
    
    NSString *trackingLink, *encryptParams;
    
    [self urlStringForEvent:event
               trackingLink:&trackingLink
              encryptParams:&encryptParams];
    
    DRLog(@"Tune sendRequestWithEvent: %@", trackingLink);
    
    NSMutableDictionary *postDict = [NSMutableDictionary dictionary];
    
    // if present then serialize the eventItems
    if([event.eventItems count] > 0) {
        BOOL areEventsLegit = YES;
        for( id item in event.eventItems )
            if( ![item isMemberOfClass:[TuneEventItem class]] )
                areEventsLegit = NO;
        
        if( areEventsLegit ) {
            // Convert the array of TuneEventItem objects to an array of equivalent dictionary representations.
            NSArray *arrDictEventItems = [TuneEventItem dictionaryArrayForEventItems:event.eventItems];
            
            DebugLog(@"Tune sendRequestWithEvent: %@", arrDictEventItems);
            [postDict setValue:arrDictEventItems forKey:TUNE_KEY_DATA];
        }
    }
    
    // include the iAd attribution info only if this is the first "session" request or if this is an "install" post-conversion request
    if( self.iAdAttributionInfo && (([[TuneManager currentManager].userProfile openLogId] == nil && [event.actionName isEqualToString:TUNE_EVENT_SESSION]) || event.postConversion) ) {
        // include iAd attribution info in the current request
        [postDict setValue:self.iAdAttributionInfo forKey:TUNE_KEY_IAD];
        
        // clear the stored iAd attribution info
        self.iAdAttributionInfo = nil;
        [TuneUserDefaultsUtils setUserDefaultValue:nil forKey:TUNE_KEY_IAD_ATTRIBUTION_DATA];
    }
    
    if(event.receipt.length > 0) {
        // Base64 encode the IAP receipt data
        NSString *strReceipt = [TuneUtils tuneBase64EncodedStringFromData:event.receipt];
        [postDict setValue:strReceipt forKey:TUNE_KEY_STORE_RECEIPT];
    }
    
    // on first open, send install receipt
    if( [[TuneManager currentManager].userProfile openLogId] == nil )
        [postDict setValue:[[TuneManager currentManager].userProfile installReceipt] forKey:TUNE_KEY_INSTALL_RECEIPT];
    
    NSString *strPost = nil;
    
    if(postDict.count > 0) {
        DebugLog(@"post data before serialization = %@", postDict);
        strPost = [TuneUtils jsonSerialize:postDict];
        DebugLog(@"post data after  serialization = %@", strPost);
    }
    
    NSDate *runDate = [NSDate date];
    
    if( [event.actionName isEqualToString:TUNE_EVENT_SESSION] )
        runDate = [runDate dateByAddingTimeInterval:TUNE_SESSION_QUEUING_DELAY];
    
    // fire the event tracking request
    [TuneEventQueue enqueueUrlRequest:trackingLink eventAction:event.actionName encryptParams:encryptParams postData:strPost runDate:runDate];
    
    if([self.delegate respondsToSelector:@selector(tuneEnqueuedRequest:postData:)]) {
        NSString *reqUrl = [NSString stringWithFormat:@"%@%@", trackingLink, encryptParams];
        
        [self.delegate tuneEnqueuedRequest:reqUrl postData:strPost];
    }
    
    if([self.delegate respondsToSelector:@selector(tuneEnqueuedActionWithReferenceId:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [self.delegate tuneEnqueuedActionWithReferenceId:event.refId];
#pragma clang diagnostic pop
    }
}

#pragma mark - CWorks Method Calls

- (void)fetchCWorksClickKey:(NSString **)key andValue:(NSNumber **)value {
    // Note: TUNE_getClicks() method also deletes the stored click key/value
    NSDictionary *dict = [TuneCWorks TUNE_getClicks:[TuneUtils bundleId]];
    
    if([dict count] > 0) {
        *key = [NSString stringWithFormat:@"%@[%@]", TUNE_KEY_CWORKS_CLICK, [[dict allKeys] objectAtIndex:0]];
        *value = [dict objectForKey:[[dict allKeys] objectAtIndex:0]];
    }
}

- (void)fetchCWorksImpressionKey:(NSString **)key andValue:(NSNumber **)value {
    // Note: TUNE_getImpressions() method also deletes the stored impression key/value
    NSDictionary *dict = [TuneCWorks TUNE_getImpressions:[TuneUtils bundleId]];
    
    if([dict count] > 0) {
        *key = [NSString stringWithFormat:@"%@[%@]", TUNE_KEY_CWORKS_IMPRESSION, [[dict allKeys] objectAtIndex:0]];
        *value = [dict objectForKey:[[dict allKeys] objectAtIndex:0]];
    }
}


#pragma mark - TuneEventQueueDelegate protocol methods

- (void)queueRequestDidSucceedWithData:(NSData *)data {
    NSString *strData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if(!strData || [strData rangeOfString:[NSString stringWithFormat:@"\"%@\":true", TUNE_KEY_SUCCESS]].location == NSNotFound) {
        [self notifyDelegateFailureWithErrorCode:TuneServerErrorResponse
                                             key:TUNE_KEY_ERROR_TUNE_SERVER_ERROR
                                         message:strData];
        return;
    }
    
    // if the server response contains an open_log_id, then store it for future use
    if([strData rangeOfString:[NSString stringWithFormat:@"\"%@\":\"%@\"", TUNE_KEY_SITE_EVENT_TYPE, TUNE_EVENT_OPEN]].location != NSNotFound &&
       [strData rangeOfString:[NSString stringWithFormat:@"\"%@\":\"", TUNE_KEY_LOG_ID]].location != NSNotFound) {
        // regex to find the value of log_id json key
        NSString *pattern = [NSString stringWithFormat:@"(?<=\"%@\":\")([\\w\\d\\-]+)\"", TUNE_KEY_LOG_ID];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:nil];
        NSTextCheckingResult *match = [regex firstMatchInString:strData options:NSMatchingReportCompletion range:NSMakeRange(0, [strData length])];
        
        // if the required match is found
        if(match.range.location != NSNotFound) {
            NSString *log_id = [strData substringWithRange:[match rangeAtIndex:1]];
            
            // store open_log_id if there is no other
            if( ![TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_OPEN_LOG_ID] ) {
                [[TuneManager currentManager].userProfile setOpenLogId:log_id];
                [TuneUserDefaultsUtils setUserDefaultValue:log_id forKey:TUNE_KEY_OPEN_LOG_ID];
            }
            
            // store last_open_log_id
            [[TuneManager currentManager].userProfile setLastOpenLogId:log_id];
            [TuneUserDefaultsUtils setUserDefaultValue:log_id forKey:TUNE_KEY_LAST_OPEN_LOG_ID];
        }
    }
    
    [self notifyDelegateSuccessMessage:strData];
}

- (void)queueRequestDidFailWithError:(NSError *)error {
    if([self.delegate respondsToSelector:@selector(tuneDidFailWithError:)]) {
        [self.delegate tuneDidFailWithError:error];
    }
}

/*!
 Waits for Tune initialization for max duration of MAX_WAIT_TIME_FOR_INIT second(s)
 in increments of TIME_STEP_FOR_INIT_WAIT second(s).
 */
- (void)waitForInit {
    NSDate *maxWait = nil;
    
    while( !_trackerStarted ) {
        if( maxWait == nil ) {
            maxWait = [NSDate dateWithTimeIntervalSinceNow:MAX_WAIT_TIME_FOR_INIT];
        } else if ([maxWait timeIntervalSinceNow] < 0) { // is this right? time is hard
            WarnLog( @"Tune timeout waiting for initialization" );
            return;
        }
        
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:TIME_STEP_FOR_INIT_WAIT]];
    }
}

- (NSString*)encryptionKey {
    [self waitForInit];
    return [[TuneManager currentManager].userProfile conversionKey];
}

- (BOOL)isiAdAttribution {
    [self waitForInit];
    return [[[TuneManager currentManager].userProfile iadAttribution] boolValue];
}

- (void)urlStringForEvent:(TuneEvent *)event
             trackingLink:(NSString**)trackingLink
            encryptParams:(NSString**)encryptParams {
    NSString *eventNameOrId = nil;
    
    // do not include the eventName param in the request url for actions -- install, session, geofence
    
    BOOL isActionInstall = [event.actionName isEqualToString:TUNE_EVENT_INSTALL];
    BOOL isActionSession = [event.actionName isEqualToString:TUNE_EVENT_SESSION];
    BOOL isActionGeofence = [event.actionName isEqualToString:TUNE_EVENT_GEOFENCE];
    
    if (!isActionInstall && !isActionSession && !isActionGeofence) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        eventNameOrId = event.eventName ? event.eventName : [@(event.eventId) stringValue];
#pragma clang diagnostic pop
    }
    
    // part of the url that does not need encryption
    NSMutableString* nonEncryptedParams = [NSMutableString stringWithCapacity:256];
    
    // part of the url that needs encryption
    NSMutableString* encryptedParams = [NSMutableString stringWithCapacity:512];
    
    if( [TuneManager currentManager].configuration.staging && ![ignoreParams containsObject:TUNE_KEY_STAGING] )
        [nonEncryptedParams appendFormat:@"%@=1", TUNE_KEY_STAGING];
    
    if( event.postConversion && ![ignoreParams containsObject:TUNE_KEY_POST_CONVERSION] )
        [nonEncryptedParams appendFormat:@"&%@=1", TUNE_KEY_POST_CONVERSION];
    
    NSString *keySiteEvent = event.eventName ? TUNE_KEY_SITE_EVENT_NAME : TUNE_KEY_SITE_EVENT_ID;
    
    NSString *currencyCode = event.currencyCode ?: [[TuneManager currentManager].userProfile currencyCode];
    
    TuneLocation *location = event.location ?: [[TuneManager currentManager].userProfile location];
    [self addValue:location.altitude             forKey:TUNE_KEY_ALTITUDE                     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:location.longitude            forKey:TUNE_KEY_LONGITUDE                    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:location.latitude             forKey:TUNE_KEY_LATITUDE                     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:location.verticalAccuracy     forKey:TUNE_KEY_LOCATION_VERTICAL_ACCURACY   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:location.horizontalAccuracy   forKey:TUNE_KEY_LOCATION_HORIZONTAL_ACCURACY encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:location.timestamp            forKey:TUNE_KEY_LOCATION_TIMESTAMP           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    // convert properties to keys, format, and append to URL
    [self addValue:event.actionName                                                         forKey:TUNE_KEY_ACTION                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile advertiserId]                  forKey:TUNE_KEY_ADVERTISER_ID            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile age]                           forKey:TUNE_KEY_AGE                      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile appAdTracking]                 forKey:TUNE_KEY_APP_AD_TRACKING          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile appBundleId]                   forKey:TUNE_KEY_APP_BUNDLE_ID            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile appName]                       forKey:TUNE_KEY_APP_NAME                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile appVersion]                    forKey:TUNE_KEY_APP_VERSION              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile appVersionName]                forKey:TUNE_KEY_APP_VERSION_NAME         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile bluetoothState]                forKey:TUNE_KEY_BLUETOOTH_STATE          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#if TARGET_OS_IOS
    [self addValue:[[TuneManager currentManager].userProfile mobileCountryCode]             forKey:TUNE_KEY_CARRIER_COUNTRY_CODE     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile mobileCountryCodeISO]          forKey:TUNE_KEY_CARRIER_COUNTRY_CODE_ISO encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile mobileNetworkCode]             forKey:TUNE_KEY_CARRIER_NETWORK_CODE     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#endif
    [self addValue:[[TuneManager currentManager].userProfile countryCode]                   forKey:TUNE_KEY_COUNTRY_CODE             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:currencyCode                                                             forKey:TUNE_KEY_CURRENCY_CODE            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile deviceBrand]                   forKey:TUNE_KEY_DEVICE_BRAND             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#if TARGET_OS_IOS
    [self addValue:[[TuneManager currentManager].userProfile deviceCarrier]                 forKey:TUNE_KEY_DEVICE_CARRIER           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#endif
    [self addValue:[[TuneManager currentManager].userProfile deviceCpuSubtype]              forKey:TUNE_KEY_DEVICE_CPUSUBTYPE        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile deviceCpuType]                 forKey:TUNE_KEY_DEVICE_CPUTYPE           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
#if TARGET_OS_IOS
    // watchOS1
    if([[[TuneManager currentManager].userProfile wearable] boolValue]) {
        [self addValue:TUNE_KEY_DEVICE_FORM_WEARABLE                                        forKey:TUNE_KEY_DEVICE_FORM             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    }
#elif TARGET_OS_TV
    [self addValue:TUNE_KEY_DEVICE_FORM_TV                                                  forKey:TUNE_KEY_DEVICE_FORM             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#elif TARGET_OS_WATCH
    // watchOS2
    [self addValue:TUNE_KEY_DEVICE_FORM_WEARABLE                                            forKey:TUNE_KEY_DEVICE_FORM             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#endif
    
    [self addValue:[[TuneManager currentManager].userProfile deviceModel]                   forKey:TUNE_KEY_DEVICE_MODEL             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute1                                                         forKey:TUNE_KEY_EVENT_ATTRIBUTE_SUB1     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute2                                                         forKey:TUNE_KEY_EVENT_ATTRIBUTE_SUB2     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute3                                                         forKey:TUNE_KEY_EVENT_ATTRIBUTE_SUB3     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute4                                                         forKey:TUNE_KEY_EVENT_ATTRIBUTE_SUB4     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.attribute5                                                         forKey:TUNE_KEY_EVENT_ATTRIBUTE_SUB5     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.contentId                                                          forKey:TUNE_KEY_EVENT_CONTENT_ID         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.contentType                                                        forKey:TUNE_KEY_EVENT_CONTENT_TYPE       encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.date1                                                              forKey:TUNE_KEY_EVENT_DATE1              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.date2                                                              forKey:TUNE_KEY_EVENT_DATE2              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.level)                                                           forKey:TUNE_KEY_EVENT_LEVEL              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.quantity)                                                        forKey:TUNE_KEY_EVENT_QUANTITY           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.rating)                                                          forKey:TUNE_KEY_EVENT_RATING             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.refId                                                              forKey:TUNE_KEY_REF_ID                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.revenue)                                                         forKey:TUNE_KEY_REVENUE                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.searchString                                                       forKey:TUNE_KEY_EVENT_SEARCH_STRING      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:@(event.transactionState)                                                forKey:TUNE_KEY_IOS_PURCHASE_STATUS      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile existingUser]                  forKey:TUNE_KEY_EXISTING_USER            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile facebookUserId]                forKey:TUNE_KEY_FACEBOOK_USER_ID         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#if TARGET_OS_IOS
    [self addValue:[[TuneManager currentManager].userProfile facebookCookieId]              forKey:TUNE_KEY_FB_COOKIE_ID             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#endif
    [self addValue:[[TuneManager currentManager].userProfile gender]                        forKey:TUNE_KEY_GENDER                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:event.iBeaconRegionId                                                    forKey:TUNE_KEY_GEOFENCE_NAME            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile googleUserId]                  forKey:TUNE_KEY_GOOGLE_USER_ID           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile iadAttribution]                forKey:TUNE_KEY_IAD_ATTRIBUTION          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile iadImpressionDate]             forKey:TUNE_KEY_IAD_IMPRESSION_DATE      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile publisherSubCampaignRef]       forKey:TUNE_KEY_PUBLISHER_SUB_CAMPAIGN_REF      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile publisherSubCampaignName]      forKey:TUNE_KEY_PUBLISHER_SUB_CAMPAIGN_NAME     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile publisherSubPublisherRef]      forKey:TUNE_KEY_PUBLISHER_SUB_PUBLISHER_REF     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile publisherSubAdRef]             forKey:TUNE_KEY_PUBLISHER_SUB_AD_REF            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile publisherSubAdName]            forKey:TUNE_KEY_PUBLISHER_SUB_AD_NAME           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile publisherSubPlacementRef]      forKey:TUNE_KEY_PUBLISHER_SUB_PLACEMENT_REF     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile publisherSubPlacementName]     forKey:TUNE_KEY_PUBLISHER_SUB_PLACEMENT_NAME    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile publisherSubKeywordRef]        forKey:TUNE_KEY_PUBLISHER_SUB_KEYWORD_REF       encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile installDate]                   forKey:TUNE_KEY_INSDATE                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile installLogId]                  forKey:TUNE_KEY_INSTALL_LOG_ID           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile isTestFlightBuild]             forKey:TUNE_KEY_IS_TESTFLIGHT_BUILD      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile appleAdvertisingTrackingEnabled]   forKey:TUNE_KEY_IOS_AD_TRACKING      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile appleAdvertisingIdentifier]    forKey:TUNE_KEY_IOS_IFA                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile appleVendorIdentifier]         forKey:TUNE_KEY_IOS_IFV                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile payingUser]                    forKey:TUNE_KEY_IS_PAYING_USER           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile conversionKey]                 forKey:TUNE_KEY_KEY                      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile language]                      forKey:TUNE_KEY_LANGUAGE                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile lastOpenLogId]                 forKey:TUNE_KEY_LAST_OPEN_LOG_ID         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile locationAuthorizationStatus]   forKey:TUNE_KEY_LOCATION_AUTH_STATUS     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile tuneId]                        forKey:TUNE_KEY_MAT_ID                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile openLogId]                     forKey:TUNE_KEY_OPEN_LOG_ID              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile jailbroken]                    forKey:TUNE_KEY_OS_JAILBROKE             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile osVersion]                     forKey:TUNE_KEY_OS_VERSION               encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile packageName]                   forKey:TUNE_KEY_PACKAGE_NAME             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile redirectUrl]                   forKey:TUNE_KEY_REDIRECT_URL             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile referralSource]                forKey:TUNE_KEY_REFERRAL_SOURCE          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile referralUrl]                   forKey:TUNE_KEY_REFERRAL_URL             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:TUNE_KEY_JSON                                                            forKey:TUNE_KEY_RESPONSE_FORMAT          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile screenDensity]                 forKey:TUNE_KEY_SCREEN_DENSITY           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile screenSize]                    forKey:TUNE_KEY_SCREEN_SIZE              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    NSString *sdkPlatform = TUNE_KEY_IOS;
#if TARGET_OS_TV
    sdkPlatform = TUNE_KEY_TVOS;
#elif TARGET_OS_WATCH
    sdkPlatform = TUNE_KEY_WATCHOS;
#endif
    [self addValue:sdkPlatform                                                              forKey:TUNE_KEY_SDK                      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[TuneManager currentManager].configuration.pluginName                    forKey:TUNE_KEY_SDK_PLUGIN               encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile sessionDate]                   forKey:TUNE_KEY_SESSION_DATETIME         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:eventNameOrId                                                            forKey:keySiteEvent                      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile systemDate]                    forKey:TUNE_KEY_SYSTEM_DATE              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile trackingId]                    forKey:TUNE_KEY_TRACKING_ID              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[NSUUID UUID] UUIDString]                                               forKey:TUNE_KEY_TRANSACTION_ID           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile trusteTPID]                    forKey:TUNE_KEY_TRUSTE_TPID              encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile twitterUserId]                 forKey:TUNE_KEY_TWITTER_USER_ID          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile updateLogId]                   forKey:TUNE_KEY_UPDATE_LOG_ID            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile userEmailMd5]                  forKey:TUNE_KEY_USER_EMAIL_MD5           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile userEmailSha1]                 forKey:TUNE_KEY_USER_EMAIL_SHA1          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile userEmailSha256]               forKey:TUNE_KEY_USER_EMAIL_SHA256        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile userId]                        forKey:TUNE_KEY_USER_ID                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile userNameMd5]                   forKey:TUNE_KEY_USER_NAME_MD5            encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile userNameSha1]                  forKey:TUNE_KEY_USER_NAME_SHA1           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile userNameSha256]                forKey:TUNE_KEY_USER_NAME_SHA256         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile phoneNumberMd5]                forKey:TUNE_KEY_USER_PHONE_MD5           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile phoneNumberSha1]               forKey:TUNE_KEY_USER_PHONE_SHA1          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    [self addValue:[[TuneManager currentManager].userProfile phoneNumberSha256]             forKey:TUNE_KEY_USER_PHONE_SHA256        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    if([[TuneManager currentManager].userProfile publisherId]) {
        [self addValue:[[TuneManager currentManager].userProfile advertiserSubAd]           forKey:TUNE_KEY_ADVERTISER_SUB_AD          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile advertiserSubAdgroup]      forKey:TUNE_KEY_ADVERTISER_SUB_ADGROUP     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile advertiserSubCampaign]     forKey:TUNE_KEY_ADVERTISER_SUB_CAMPAIGN    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile advertiserSubKeyword]      forKey:TUNE_KEY_ADVERTISER_SUB_KEYWORD     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile advertiserSubPublisher]    forKey:TUNE_KEY_ADVERTISER_SUB_PUBLISHER   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile advertiserSubSite]         forKey:TUNE_KEY_ADVERTISER_SUB_SITE        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile agencyId]                  forKey:TUNE_KEY_AGENCY_ID                  encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile offerId]                 	forKey:TUNE_KEY_OFFER_ID                   encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:@(1)                                                                 forKey:TUNE_KEY_PRELOAD_DATA               encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile publisherId]             	forKey:TUNE_KEY_PUBLISHER_ID               encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile publisherReferenceId]    	forKey:TUNE_KEY_PUBLISHER_REF_ID           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile publisherSubAd]            forKey:TUNE_KEY_PUBLISHER_SUB_AD           encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile publisherSubAdgroup]     	forKey:TUNE_KEY_PUBLISHER_SUB_ADGROUP      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile publisherSubCampaign]      forKey:TUNE_KEY_PUBLISHER_SUB_CAMPAIGN     encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile publisherSubKeyword]       forKey:TUNE_KEY_PUBLISHER_SUB_KEYWORD      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile publisherSubPublisher]   	forKey:TUNE_KEY_PUBLISHER_SUB_PUBLISHER    encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile publisherSubSite]        	forKey:TUNE_KEY_PUBLISHER_SUB_SITE         encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile publisherSub1]           	forKey:TUNE_KEY_PUBLISHER_SUB1             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile publisherSub2]           	forKey:TUNE_KEY_PUBLISHER_SUB2             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile publisherSub3]             forKey:TUNE_KEY_PUBLISHER_SUB3             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile publisherSub4]           	forKey:TUNE_KEY_PUBLISHER_SUB4             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
        [self addValue:[[TuneManager currentManager].userProfile publisherSub5]           	forKey:TUNE_KEY_PUBLISHER_SUB5             encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    }
    
    [self addValue:TUNEVERSION                       			forKey:TUNE_KEY_VER                        encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    [self addValue:[TuneUserAgentCollector userAgent]           forKey:TUNE_KEY_CONVERSION_USER_AGENT      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    if( [[TuneManager currentManager].configuration.debugMode boolValue] )
        [self addValue:@(TRUE)                       			forKey:TUNE_KEY_DEBUG                      encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
    // Note: it's possible for a cworks key to duplicate a built-in key (say, "sdk").
    // If that happened, the constructed URL would have two of the same parameter (e.g.,
    // "...sdk=ios&sdk=cworksvalue..."), though one might be encrypted and one not.
    for( NSString *key in [event.cworksClick allKeys] )
        [self addValue:event.cworksClick[key]        			forKey:key                                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    for( NSString *key in [event.cworksImpression allKeys] )
        [self addValue:event.cworksImpression[key]   			forKey:key                                 encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    
#if DEBUG
    [self addValue:@(TRUE)                                      forKey:TUNE_KEY_BYPASS_THROTTLING          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
#endif
    
#if TESTING
    if(self.allowDuplicateRequests)
    {
        [self addValue:@(TRUE)                                      forKey:@"skip_dup"          encryptedParams:encryptedParams plaintextParams:nonEncryptedParams];
    }
#endif
    
    if( [_trackerDelegate respondsToSelector:@selector(_tuneURLTestingCallbackWithParamsToBeEncrypted:withPlaintextParams:)] )
        [_trackerDelegate _tuneURLTestingCallbackWithParamsToBeEncrypted:encryptedParams withPlaintextParams:nonEncryptedParams];
    
    *trackingLink = [NSString stringWithFormat:@"%@://%@.%@/%@?%@",
                     TUNE_KEY_HTTPS,
                     [[TuneManager currentManager].userProfile advertiserId],
                     [[TuneManager currentManager].configuration domainName],
                     TUNE_SERVER_PATH_TRACKING_ENGINE,
                     nonEncryptedParams];
    
    DLLog(@"Tune urlStringForServerUrl: data to be encrypted: %@", encryptedParams);
    DLLog(@"Tune urlStringForServerUrl: tracking url: %@", *trackingLink);
    
    *encryptParams = encryptedParams;
}

- (void)addValue:(id)value
          forKey:(NSString*)key
 encryptedParams:(NSMutableString*)encryptedParams
 plaintextParams:(NSMutableString*)plaintextParams {
    if( value == nil || [ignoreParams containsObject:key]) {
        return;
    }
    
    if( [key isEqualToString:TUNE_KEY_PACKAGE_NAME] || [key isEqualToString:TUNE_KEY_DEBUG] ) {
        [TuneUtils addUrlQueryParamValue:value forKey:key queryParams:plaintextParams];
        [TuneUtils addUrlQueryParamValue:value forKey:key queryParams:encryptedParams];
    } else if( [doNotEncryptSet containsObject:key] ) {
        [TuneUtils addUrlQueryParamValue:value forKey:key queryParams:plaintextParams];
    } else {
        [TuneUtils addUrlQueryParamValue:value forKey:key queryParams:encryptedParams];
    }
}

@end
