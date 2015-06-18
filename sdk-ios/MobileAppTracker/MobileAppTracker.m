//
//  MobileAppTracker.m
//  MobileAppTracker
//
//  Created by HasOffers on 05/03/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import "MobileAppTracker.h"
#import "Common/MATEvent_internal.h"
#import "Common/MATTracker.h"
#import "Common/MATDeferredDplinkr.h"

#define PLUGIN_NAMES (@[@"air", @"cocos2dx", @"marmalade", @"phonegap", @"titanium", @"unity", @"xamarin"])

static NSOperationQueue *opQueue = nil;


@implementation MobileAppTracker


#pragma mark - Private Initialization Methods

+ (void)initialize
{
    opQueue = [NSOperationQueue new];
    opQueue.maxConcurrentOperationCount = 1;
}

+ (MATTracker *)sharedManager
{
    // note that the initialization is slow (potentially hundreds of milliseconds),
    // so call this function on a background thread if it might be the first time
    static MATTracker *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[MATTracker alloc] init];
    });
    
    return sharedManager;
}


#pragma mark - Init Method

+ (void)initializeWithMATAdvertiserId:(NSString *)aid MATConversionKey:(NSString *)key
{
    [MATDeferredDplinkr setAdvertiserId:aid conversionKey:key];
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] startTrackerWithMATAdvertiserId:aid MATConversionKey:key];
    }];
}


#pragma mark - Debugging Helper Methods

+ (void)setDebugMode:(BOOL)enable
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setDebugMode:enable];
    }];
}

+ (void)setAllowDuplicateRequests:(BOOL)allow
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setAllowDuplicateRequests:allow];
    }];
}

+ (void)setDelegate:(id <MobileAppTrackerDelegate>)delegate
{
    [MATDeferredDplinkr setDelegate:delegate];
    [opQueue addOperationWithBlock:^{
        [self sharedManager].delegate = delegate;
#if DEBUG
        [self sharedManager].parameters.delegate = (id <MATSettingsDelegate>)delegate;
#endif
    }];
}


#pragma mark - Behavior Flags

+ (void)checkForDeferredDeeplinkWithTimeout:(NSTimeInterval)timeout
{
    [MATDeferredDplinkr checkForDeferredDeeplinkWithTimeout:timeout];
}

+ (void)automateIapEventMeasurement:(BOOL)automate
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].automateIapMeasurement = automate;
    }];
}


#pragma mark - Setter Methods

+ (void)setRegionDelegate:(id <MobileAppTrackerRegionDelegate>)delegate
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].regionMonitor.delegate = delegate;
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
    [MATDeferredDplinkr setIFA:[appleAdvertisingIdentifier UUIDString] trackingEnabled:adTrackingEnabled];
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
        [self sharedManager].parameters.currencyCode = currencyCode;
    }];
}

+ (void)setJailbroken:(BOOL)jailbroken
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.jailbroken = @(jailbroken);
    }];
}

+ (void)setPackageName:(NSString *)packageName
{
    [MATDeferredDplinkr setPackageName:packageName];
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.packageName = packageName;
    }];
}

+ (void)setShouldAutoDetectJailbroken:(BOOL)autoDetect
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setShouldAutoDetectJailbroken:autoDetect];
    }];
}

+ (void)setShouldAutoGenerateAppleVendorIdentifier:(BOOL)autoGenerate
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setShouldAutoGenerateAppleVendorIdentifier:autoGenerate];
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

+ (void)setPhoneNumber:(NSString *)phoneNumber
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.phoneNumber = phoneNumber;
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

+ (void)setLocationAuthorizationStatus:(NSInteger)authStatus // private method
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.locationAuthorizationStatus = @(authStatus);
    }];
}

+ (void)setBluetoothState:(NSInteger)bluetoothState // private method
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.bluetoothState = @(bluetoothState);
    }];
}

+ (void)setPayingUser:(BOOL)isPayingUser
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setPayingUser:isPayingUser];
    }];
}

+ (void)setPreloadData:(MATPreloadData *)preloadData
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setPreloadData:preloadData];
    }];
}

+ (void)setFacebookEventLogging:(BOOL)logging limitEventAndDataUsage:(BOOL)limit
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].fbLogging = logging;
        [self sharedManager].fbLimitUsage = limit;
    }];
}


#pragma mark - Getter Methods

+ (NSString*)matId
{
    return [self sharedManager].parameters.matId;
}

+ (NSString*)openLogId
{
    return [self sharedManager].parameters.openLogId;
}

+ (BOOL)isPayingUser
{
    return [[self sharedManager].parameters.payingUser boolValue];
}


#if USE_IAD

#pragma mark - iAd Display Methods

+ (void)displayiAdInView:(UIView*)view
{
    [opQueue addOperationWithBlock:^{
        MATTracker *mat = [self sharedManager];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [mat displayiAdInView:view];
        }];
    }];
}

+ (void)removeiAd
{
    [opQueue addOperationWithBlock:^{
        MATTracker *mat = [self sharedManager];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [mat removeiAd];
        }];
    }];
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
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] measureEvent:event];
    }];
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
    [opQueue addOperationWithBlock:^{
        [self sharedManager].shouldUseCookieTracking = enable;
    }];
}

+ (void)setRedirectUrl:(NSString *)redirectURL
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.redirectUrl = redirectURL;
    }];
}

+ (void)startAppToAppTracking:(NSString *)targetAppPackageName
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

+ (void)startMonitoringForBeaconRegion:(NSUUID*)UUID
                                nameId:(NSString*)nameId
                               majorId:(NSUInteger)majorId
                               minorId:(NSUInteger)minorId
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager].regionMonitor addBeaconRegion:UUID nameId:nameId majorId:majorId minorId:minorId];
    }];
}

@end
