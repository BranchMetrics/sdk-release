//
//  MobileAppTracker.m
//  MobileAppTracker
//
//  Created by HasOffers on 05/03/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import "MobileAppTracker.h"

#import "Tune.h"
#import "TuneEvent.h"
#import "TuneEventItem.h"

#ifdef MAT_USE_LOCATION
#import "TuneRegionMonitor.h"
#endif

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"


@interface TuneDelegateForMat : NSObject <TuneDelegate>

@property (nonatomic, assign) id<MobileAppTrackerDelegate> matDelegate;
@property (nonatomic, assign) id<MobileAppTrackerDelegate> matDeeplinkDelegate;

@end


@implementation TuneDelegateForMat

#pragma mark - TuneDelegate Local Implementation

- (void)tuneEnqueuedActionWithReferenceId:(NSString *)referenceId
{
    if(self.matDelegate && [self.matDelegate respondsToSelector:@selector(mobileAppTrackerEnqueuedActionWithReferenceId:)])
    {
        [self.matDelegate mobileAppTrackerEnqueuedActionWithReferenceId:referenceId];
    }
}

- (void)tuneDidSucceedWithData:(NSData *)data
{
    if(self.matDelegate && [self.matDelegate respondsToSelector:@selector(mobileAppTrackerDidSucceedWithData:)])
    {
        [self.matDelegate mobileAppTrackerDidSucceedWithData:data];
    }
}

- (void)tuneDidFailWithError:(NSError *)error
{
    if(self.matDelegate && [self.matDelegate respondsToSelector:@selector(mobileAppTrackerDidFailWithError:)])
    {
        [self.matDelegate mobileAppTrackerDidFailWithError:error];
    }
}

- (void)tuneDidReceiveDeeplink:(NSString *)deeplink
{
    id<MobileAppTrackerDelegate> deepDelegate = self.matDeeplinkDelegate ?: self.matDelegate;
    
    if(deepDelegate && [deepDelegate respondsToSelector:@selector(mobileAppTrackerDidReceiveDeeplink:)])
    {
        [deepDelegate mobileAppTrackerDidReceiveDeeplink:deeplink];
    }
}

- (void)tuneDidFailDeeplinkWithError:(NSError *)error
{
    id<MobileAppTrackerDelegate> deepDelegate = self.matDeeplinkDelegate ?: self.matDelegate;
    
    if(deepDelegate && [deepDelegate respondsToSelector:@selector(mobileAppTrackerDidFailDeeplinkWithError:)])
    {
        [deepDelegate mobileAppTrackerDidFailDeeplinkWithError:error];
    }
}

#if USE_IAD

- (void)tuneDidDisplayiAd
{
    if(self.matDelegate && [self.matDelegate respondsToSelector:@selector(mobileAppTrackerDidDisplayiAd)])
    {
        [self.matDelegate mobileAppTrackerDidDisplayiAd];
    }
}

- (void)tuneDidRemoveiAd
{
    if(self.matDelegate && [self.matDelegate respondsToSelector:@selector(mobileAppTrackerDidRemoveiAd)])
    {
        [self.matDelegate mobileAppTrackerDidRemoveiAd];
    }
}

- (void)tuneFailedToReceiveiAdWithError:(NSError *)error
{
    if(self.matDelegate && [self.matDelegate respondsToSelector:@selector(mobileAppTrackerFailedToReceiveiAdWithError:)])
    {
        [self.matDelegate mobileAppTrackerFailedToReceiveiAdWithError:error];
    }
}

#endif

@end


#ifdef MAT_USE_LOCATION

@interface TuneRegionDelegateForMat : NSObject <TuneRegionDelegate>

@property (nonatomic, assign) id<MobileAppTrackerRegionDelegate> matRegionDelegate;

@end


@implementation TuneRegionDelegateForMat

- (void)tuneDidEnterRegion:(CLRegion*)region
{
    if (self.matRegionDelegate && [self.matRegionDelegate respondsToSelector:@selector(mobileAppTrackerDidEnterRegion:)]) {
        [self.matRegionDelegate mobileAppTrackerDidEnterRegion:region];
    }
}

- (void)tuneDidExitRegion:(CLRegion*)region
{
    if (self.matRegionDelegate && [self.matRegionDelegate respondsToSelector:@selector(mobileAppTrackerDidExitRegion:)]) {
        [self.matRegionDelegate mobileAppTrackerDidExitRegion:region];
    }
}

- (void)tuneChangedAuthStatusTo:(CLAuthorizationStatus)authStatus
{
    if (self.matRegionDelegate && [self.matRegionDelegate respondsToSelector:@selector(mobileAppTrackerChangedAuthStatusTo:)]) {
        [self.matRegionDelegate mobileAppTrackerChangedAuthStatusTo:authStatus];
    }
}

- (void)tuneChangedBluetoothStateTo:(CBCentralManagerState)bluetoothState
{
    if (self.matRegionDelegate && [self.matRegionDelegate respondsToSelector:@selector(mobileAppTrackerChangedBluetoothStateTo:)]) {
        [self.matRegionDelegate mobileAppTrackerChangedBluetoothStateTo:bluetoothState];
    }
}

@end

#endif


@interface Tune (MobileAppTracker)

+ (void)setPluginName:(NSString *)pluginName;
+ (void)setLocationAuthorizationStatus:(NSInteger)authStatus;
+ (void)setBluetoothState:(NSInteger)bluetoothState;
+ (void)startMonitoringForBeaconRegion:(NSUUID*)UUID
                                nameId:(NSString*)nameId
                               majorId:(NSUInteger)majorId
                               minorId:(NSUInteger)minorId;

@end


static TuneDelegateForMat *matTuneDelegate;

#ifdef MAT_USE_LOCATION
static TuneRegionDelegateForMat *matTuneRegionDelegate;
#endif

@implementation MobileAppTracker


#pragma mark - Init Method


+(void)initialize
{
    matTuneDelegate = [TuneDelegateForMat new];

#ifdef MAT_USE_LOCATION
    matTuneRegionDelegate = [TuneRegionDelegateForMat new];
#endif
}

+ (void)initializeWithMATAdvertiserId:(NSString *)aid MATConversionKey:(NSString *)key
{
    [Tune initializeWithTuneAdvertiserId:aid tuneConversionKey:key];
}

+ (void)initializeWithMATAdvertiserId:(NSString *)aid MATConversionKey:(NSString *)key MATPackageName:(NSString *)name wearable:(BOOL)wearable
{
    [Tune initializeWithTuneAdvertiserId:aid tuneConversionKey:key tunePackageName:name wearable:wearable];
}


#pragma mark - Debugging Helper Methods

+ (void)setDebugMode:(BOOL)enable
{
    [Tune setDebugMode:enable];
}

+ (void)setAllowDuplicateRequests:(BOOL)allow
{
    [Tune setAllowDuplicateRequests:allow];
}

+ (void)setDelegate:(id<MobileAppTrackerDelegate>)delegate
{
    matTuneDelegate.matDelegate = delegate;
    
    [Tune setDelegate:matTuneDelegate];
}


#pragma mark - Behavior Flags

+ (void)checkForDeferredDeeplink:(id<MobileAppTrackerDelegate>)delegate
{
    matTuneDelegate.matDeeplinkDelegate = delegate;
    
    [Tune checkForDeferredDeeplink:matTuneDelegate];
}

#if !TARGET_OS_WATCH
+ (void)automateIapEventMeasurement:(BOOL)automate
{
    [Tune automateIapEventMeasurement:automate];
}
#endif

#pragma mark - Setter Methods

#ifdef MAT_USE_LOCATION
+ (void)setRegionDelegate:(id<MobileAppTrackerRegionDelegate>)delegate
{
    matTuneRegionDelegate.matRegionDelegate = delegate;
    
    [Tune setRegionDelegate:matTuneRegionDelegate];
}
#endif

+ (void)setExistingUser:(BOOL)existingUser
{
    [Tune setExistingUser:existingUser];
}

#if !TARGET_OS_WATCH
+ (void)setAppleAdvertisingIdentifier:(NSUUID *)appleAdvertisingIdentifier
           advertisingTrackingEnabled:(BOOL)adTrackingEnabled;
{
    [Tune setAppleAdvertisingIdentifier:appleAdvertisingIdentifier advertisingTrackingEnabled:adTrackingEnabled];
}

+ (void)setAppleVendorIdentifier:(NSUUID * )appleVendorIdentifier
{
    [Tune setAppleVendorIdentifier:appleVendorIdentifier];
}
#endif

+ (void)setCurrencyCode:(NSString *)currencyCode
{
    [Tune setCurrencyCode:currencyCode];
}

#if TARGET_OS_IOS
+ (void)setJailbroken:(BOOL)jailbroken
{
    [Tune setJailbroken:jailbroken];
}
#endif

+ (void)setPackageName:(NSString *)packageName
{
    [Tune setPackageName:packageName];
}

#if !TARGET_OS_WATCH
+ (void)setShouldAutoCollectAppleAdvertisingIdentifier:(BOOL)autoCollect
{
    [Tune setShouldAutoCollectAppleAdvertisingIdentifier:autoCollect];
}

+ (void)setShouldAutoCollectDeviceLocation:(BOOL)autoCollect
{
    [Tune setShouldAutoCollectDeviceLocation:autoCollect];
}
#endif

+ (void)setShouldAutoDetectJailbroken:(BOOL)autoDetect
{
    [Tune setShouldAutoDetectJailbroken:autoDetect];
}

#if !TARGET_OS_WATCH
+ (void)setShouldAutoGenerateAppleVendorIdentifier:(BOOL)autoGenerate
{
    [Tune setShouldAutoGenerateAppleVendorIdentifier:autoGenerate];
}
#endif

+ (void)setSiteId:(NSString *)siteId
{
    [Tune setSiteId:siteId];
}

+ (void)setTRUSTeId:(NSString *)tpid;
{
    [Tune setTRUSTeId:tpid];
}

+ (void)setUserEmail:(NSString *)userEmail
{
    [Tune setUserEmail:userEmail];
}

+ (void)setUserId:(NSString *)userId
{
    [Tune setUserId:userId];
}

+ (void)setUserName:(NSString *)userName
{
    [Tune setUserName:userName];
}

+ (void)setPhoneNumber:(NSString *)phoneNumber
{
    [Tune setPhoneNumber:phoneNumber];
}

+ (void)setFacebookUserId:(NSString *)facebookUserId
{
    [Tune setFacebookUserId:facebookUserId];
}

+ (void)setTwitterUserId:(NSString *)twitterUserId
{
    [Tune setTwitterUserId:twitterUserId];
}

+ (void)setGoogleUserId:(NSString *)googleUserId
{
    [Tune setGoogleUserId:googleUserId];
}

+ (void)setAge:(NSInteger)userAge
{
    [Tune setAge:userAge];
}

+ (void)setGender:(MATGender)userGender
{
    [Tune setGender:userGender == MATGenderMale ? TuneGenderMale : (userGender == MATGenderFemale ? TuneGenderFemale : TuneGenderUnknown)];
}

+ (void)setLatitude:(double)latitude longitude:(double)longitude
{
    TuneLocation *location = [TuneLocation new];
    location.latitude = @(latitude);
    location.longitude = @(longitude);
    
    [Tune setLocation:location];
}

+ (void)setLatitude:(double)latitude longitude:(double)longitude altitude:(double)altitude
{
    TuneLocation *location = [TuneLocation new];
    location.altitude = @(altitude);
    location.latitude = @(latitude);
    location.longitude = @(longitude);
    
    [Tune setLocation:location];
}

+ (void)setAppAdTracking:(BOOL)enable
{
    [Tune setAppAdMeasurement:enable];
}

+ (void)setPluginName:(NSString *)pluginName
{
    [Tune setPluginName:pluginName];
}

+ (void)setLocationAuthorizationStatus:(NSInteger)authStatus // private method
{
    [Tune setLocationAuthorizationStatus:authStatus];
}

+ (void)setBluetoothState:(NSInteger)bluetoothState // private method
{
    [Tune setBluetoothState:bluetoothState];
}

+ (void)setPayingUser:(BOOL)isPayingUser
{
    [Tune setPayingUser:isPayingUser];
}

+ (void)setPreloadData:(MATPreloadData *)preloadData
{
    [Tune setPreloadData:preloadData];
}

+ (void)setFacebookEventLogging:(BOOL)logging limitEventAndDataUsage:(BOOL)limit
{
    [Tune setFacebookEventLogging:logging limitEventAndDataUsage:limit];
}


#pragma mark - Getter Methods

+ (NSString*)matId
{
    return [Tune tuneId];
}

+ (NSString*)openLogId
{
    return [Tune openLogId];
}

+ (BOOL)isPayingUser
{
    return [Tune isPayingUser];
}


#if USE_IAD

#pragma mark - iAd Display Methods

+ (void)displayiAdInView:(UIView*)view
{
    [Tune displayiAdInView:view];
}

+ (void)removeiAd
{
    [Tune removeiAd];
}

#endif


#pragma mark - Measure Methods

+ (void)measureSession
{
    [self measureEventName:MAT_EVENT_SESSION];
}

+ (void)measureEventName:(NSString *)eventName
{
    [self measureEvent:[MATEvent eventWithName:eventName]];
}

+ (void)measureEventId:(NSInteger)eventId
{
    [self measureEvent:[MATEvent eventWithId:eventId]];
}

+ (void)measureEvent:(MATEvent *)event
{
    [Tune measureEvent:[self tuneEventFromMATEvent:event]];
}


#pragma mark - MobileAppTracker-Tune Conversion Helpers

+ (TuneEvent *)tuneEventFromMATEvent:(MATEvent *)event
{
    TuneEvent *tuneEvent = nil;
    if(event.eventName)
    {
        tuneEvent = [TuneEvent eventWithName:event.eventName];
    }
    else
    {
        tuneEvent = [TuneEvent eventWithId:event.eventId];
    }
    tuneEvent.attribute1 = event.attribute1;
    tuneEvent.attribute2 = event.attribute2;
    tuneEvent.attribute3 = event.attribute3;
    tuneEvent.attribute4 = event.attribute4;
    tuneEvent.attribute5 = event.attribute5;
    tuneEvent.contentType = event.contentType;
    tuneEvent.contentId = event.contentId;
    tuneEvent.date1 = event.date1;
    tuneEvent.date2 = event.date2;
    tuneEvent.revenue = event.revenue;
    tuneEvent.receipt = event.receipt;
    tuneEvent.refId = event.refId;
    tuneEvent.level = event.level;
    tuneEvent.quantity = event.quantity;
    tuneEvent.rating = event.rating;
    tuneEvent.currencyCode = event.currencyCode;
    tuneEvent.searchString = event.searchString;
    tuneEvent.transactionState = event.transactionState;
    
    NSMutableArray *arrItems = [NSMutableArray array];
    
    for (MATEventItem *matItem in event.eventItems) {
        [arrItems addObject:[self tuneEventItemFromMATEventItem:matItem]];
    }
    
    tuneEvent.eventItems = arrItems;
    
    return tuneEvent;
}
     
+ (TuneEventItem *)tuneEventItemFromMATEventItem:(MATEventItem *)mat
{
    return [TuneEventItem eventItemWithName:mat.item unitPrice:mat.unitPrice quantity:mat.quantity revenue:mat.revenue
                                 attribute1:mat.attribute1 attribute2:mat.attribute2 attribute3:mat.attribute3 attribute4:mat.attribute4 attribute5:mat.attribute5];
}


#pragma mark - MeasureAction Methods (Deprecated)

+ (void)measureAction:(NSString *)eventName
{
    [self measureEventName:eventName];
}

+ (void)measureAction:(NSString *)eventName
          referenceId:(NSString *)refId
{
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.refId = refId;
    
    [self measureEvent:evt];
}

+ (void)measureAction:(NSString *)eventName
        revenueAmount:(float)revenueAmount
         currencyCode:(NSString *)currencyCode
{
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.revenue = revenueAmount;
    evt.currencyCode = currencyCode;
    
    [self measureEvent:evt];
}

+ (void)measureAction:(NSString *)eventName
          referenceId:(NSString *)refId
        revenueAmount:(float)revenueAmount
         currencyCode:(NSString *)currencyCode
{
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.refId = refId;
    evt.revenue = revenueAmount;
    evt.currencyCode = currencyCode;
    
    [self measureEvent:evt];
}

+ (void)measureAction:(NSString *)eventName
           eventItems:(NSArray *)eventItems
{
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.eventItems = eventItems;
    
    [self measureEvent:evt];
}

+ (void)measureAction:(NSString *)eventName
           eventItems:(NSArray *)eventItems
          referenceId:(NSString *)refId
{
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.eventItems = eventItems;
    evt.refId = refId;
    
    [self measureEvent:evt];
}

+ (void)measureAction:(NSString *)eventName
           eventItems:(NSArray *)eventItems
        revenueAmount:(float)revenueAmount
         currencyCode:(NSString *)currencyCode
{
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.eventItems = eventItems;
    evt.revenue = revenueAmount;
    evt.currencyCode = currencyCode;
    
    [self measureEvent:evt];
}

+ (void)measureAction:(NSString *)eventName
           eventItems:(NSArray *)eventItems
          referenceId:(NSString *)refId
        revenueAmount:(float)revenueAmount
         currencyCode:(NSString *)currencyCode
{
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.eventItems = eventItems;
    evt.refId = refId;
    evt.revenue = revenueAmount;
    evt.currencyCode = currencyCode;
    
    [self measureEvent:evt];
}

+ (void)measureAction:(NSString *)eventName
           eventItems:(NSArray *)eventItems
          referenceId:(NSString *)refId
        revenueAmount:(float)revenueAmount
         currencyCode:(NSString *)currencyCode
     transactionState:(NSInteger)transactionState
{
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.eventItems = eventItems;
    evt.refId = refId;
    evt.revenue = revenueAmount;
    evt.currencyCode = currencyCode;
    evt.transactionState = transactionState;
    
    [self measureEvent:evt];
}

+ (void)measureAction:(NSString *)eventName
           eventItems:(NSArray *)eventItems
          referenceId:(NSString *)refId
        revenueAmount:(float)revenueAmount
         currencyCode:(NSString *)currencyCode
     transactionState:(NSInteger)transactionState
              receipt:(NSData *)receipt
{
    MATEvent *evt = [MATEvent eventWithName:eventName];
    evt.eventItems = eventItems;
    evt.refId = refId;
    evt.revenue = revenueAmount;
    evt.currencyCode = currencyCode;
    evt.transactionState = transactionState;
    evt.receipt = receipt;
    
    [self measureEvent:evt];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
{
    [self measureEventId:eventId];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                     referenceId:(NSString *)refId
{
    MATEvent *evt = [MATEvent eventWithId:eventId];
    evt.refId = refId;
    
    [self measureEvent:evt];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                   revenueAmount:(float)revenueAmount
                    currencyCode:(NSString *)currencyCode
{
    MATEvent *evt = [MATEvent eventWithId:eventId];
    evt.revenue = revenueAmount;
    evt.currencyCode = currencyCode;
    
    [self measureEvent:evt];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                     referenceId:(NSString *)refId
                   revenueAmount:(float)revenueAmount
                    currencyCode:(NSString *)currencyCode
{
    MATEvent *evt = [MATEvent eventWithId:eventId];
    evt.refId = refId;
    evt.revenue = revenueAmount;
    evt.currencyCode = currencyCode;
    
    [self measureEvent:evt];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                      eventItems:(NSArray *)eventItems
{
    MATEvent *evt = [MATEvent eventWithId:eventId];
    evt.eventItems = eventItems;
    
    [self measureEvent:evt];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                      eventItems:(NSArray *)eventItems
                     referenceId:(NSString *)refId
{
    MATEvent *evt = [MATEvent eventWithId:eventId];
    evt.refId = refId;
    evt.eventItems = eventItems;
    
    [self measureEvent:evt];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                      eventItems:(NSArray *)eventItems
                   revenueAmount:(float)revenueAmount
                    currencyCode:(NSString *)currencyCode
{
    MATEvent *evt = [MATEvent eventWithId:eventId];
    evt.eventItems = eventItems;
    evt.revenue = revenueAmount;
    evt.currencyCode = currencyCode;
    
    [self measureEvent:evt];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                      eventItems:(NSArray *)eventItems
                     referenceId:(NSString *)refId
                   revenueAmount:(float)revenueAmount
                    currencyCode:(NSString *)currencyCode
{
    MATEvent *evt = [MATEvent eventWithId:eventId];
    evt.eventItems = eventItems;
    evt.refId = refId;
    evt.revenue = revenueAmount;
    evt.currencyCode = currencyCode;
    
    [self measureEvent:evt];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                      eventItems:(NSArray *)eventItems
                     referenceId:(NSString *)refId
                   revenueAmount:(float)revenueAmount
                    currencyCode:(NSString *)currencyCode
                transactionState:(NSInteger)transactionState
{
    MATEvent *evt = [MATEvent eventWithId:eventId];
    evt.eventItems = eventItems;
    evt.refId = refId;
    evt.revenue = revenueAmount;
    evt.currencyCode = currencyCode;
    evt.transactionState = transactionState;
    
    [self measureEvent:evt];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                      eventItems:(NSArray *)eventItems
                     referenceId:(NSString *)refId
                   revenueAmount:(float)revenueAmount
                    currencyCode:(NSString *)currencyCode
                transactionState:(NSInteger)transactionState
                         receipt:(NSData *)receipt
{
    MATEvent *evt = [MATEvent eventWithId:eventId];
    evt.eventItems = eventItems;
    evt.refId = refId;
    evt.revenue = revenueAmount;
    evt.currencyCode = currencyCode;
    evt.transactionState = transactionState;
    evt.receipt = receipt;
    
    [self measureEvent:evt];
}


#pragma mark - Other Methods

+ (void)setUseCookieTracking:(BOOL)enable
{
    [Tune setUseCookieMeasurement:enable];
}

+ (void)setRedirectUrl:(NSString *)redirectURL
{
    [Tune setRedirectUrl:redirectURL];
}

+ (void)startAppToAppTracking:(NSString *)targetAppPackageName
                 advertiserId:(NSString *)targetAppAdvertiserId
                      offerId:(NSString *)targetAdvertiserOfferId
                  publisherId:(NSString *)targetAdvertiserPublisherId
                     redirect:(BOOL)shouldRedirect
{
    [Tune startAppToAppMeasurement:targetAppPackageName
                      advertiserId:targetAppAdvertiserId
                           offerId:targetAdvertiserOfferId
                       publisherId:targetAdvertiserPublisherId
                          redirect:shouldRedirect];
}

+ (void)applicationDidOpenURL:(NSString *)urlString sourceApplication:(NSString *)sourceApplication
{
    [Tune applicationDidOpenURL:urlString sourceApplication:sourceApplication];
}

+ (void)startMonitoringForBeaconRegion:(NSUUID*)UUID
                                nameId:(NSString*)nameId
                               majorId:(NSUInteger)majorId
                               minorId:(NSUInteger)minorId
{
    [Tune startMonitoringForBeaconRegion:UUID
                                  nameId:nameId
                                 majorId:majorId
                                 minorId:minorId];
}

@end

#pragma mark - GCC diagnostic pop
