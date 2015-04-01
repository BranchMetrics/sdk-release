//
//  MobileAppTracker.m
//  MobileAppTracker
//
//  Created by HasOffers on 05/03/13.
//  Copyright (c) 2013 HasOffers. All rights reserved.
//

#import "MobileAppTracker.h"
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
    [MATDeferredDplinkr setPackageName:packageName];
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

+ (void)setRegionName:(NSString*)regionName // private method
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.regionName = regionName;
    }];
}

+ (void)setLocationAuthorizationStatus:(NSInteger)authStatus // private method
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.locationAuthorizationStatus = @(authStatus);
    }];
}

+ (void)setEventContentType:(NSString*)contentType
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.eventContentType = contentType;
    }];
}

+ (void)setEventContentId:(NSString*)contentId
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.eventContentId = contentId;
    }];
}

+ (void)setEventLevel:(NSInteger)level
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.eventLevel = @(level);
    }];
}

+ (void)setEventQuantity:(NSInteger)quantity
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.eventQuantity = @(quantity);
    }];
}

+ (void)setEventSearchString:(NSString*)searchString
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.eventSearchString = searchString;
    }];
}

+ (void)setEventRating:(CGFloat)rating
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.eventRating = @(rating);
    }];
}

+ (void)setEventDate1:(NSDate*)date
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.eventDate1 = date;
    }];
}

+ (void)setEventDate2:(NSDate*)date
{
    [opQueue addOperationWithBlock:^{
        [self sharedManager].parameters.eventDate2 = date;
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

+ (void)setPayingUser:(BOOL)isPayingUser
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] setPayingUser:isPayingUser];
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
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackSession];
    }];
}

+ (void)measureAction:(NSString *)eventName
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventName];
    }];
}

+ (void)measureAction:(NSString *)eventName
          referenceId:(NSString *)refId
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventName
                                              referenceId:refId];
    }];
}

+ (void)measureAction:(NSString *)eventName
        revenueAmount:(float)revenueAmount
         currencyCode:(NSString *)currencyCode
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventName
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode];
    }];
}

+ (void)measureAction:(NSString *)eventName
          referenceId:(NSString *)refId
        revenueAmount:(float)revenueAmount
         currencyCode:(NSString *)currencyCode
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventName
                                              referenceId:refId
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode];
    }];
}

+ (void)measureAction:(NSString *)eventName
           eventItems:(NSArray *)eventItems
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventName
                                               eventItems:eventItems];
    }];
}

+ (void)measureAction:(NSString *)eventName
           eventItems:(NSArray *)eventItems
          referenceId:(NSString *)refId
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventName
                                               eventItems:eventItems
                                              referenceId:refId];
    }];
}

+ (void)measureAction:(NSString *)eventName
           eventItems:(NSArray *)eventItems
        revenueAmount:(float)revenueAmount
         currencyCode:(NSString *)currencyCode
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventName
                                               eventItems:eventItems
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode];
    }];
}

+ (void)measureAction:(NSString *)eventName
           eventItems:(NSArray *)eventItems
          referenceId:(NSString *)refId
        revenueAmount:(float)revenueAmount
         currencyCode:(NSString *)currencyCode
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventName
                                               eventItems:eventItems
                                              referenceId:refId
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode];
    }];
}

+ (void)measureAction:(NSString *)eventName
           eventItems:(NSArray *)eventItems
          referenceId:(NSString *)refId
        revenueAmount:(float)revenueAmount
         currencyCode:(NSString *)currencyCode
     transactionState:(NSInteger)transactionState
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventName
                                               eventItems:eventItems
                                              referenceId:refId
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode
                                         transactionState:transactionState];
    }];
}

+ (void)measureAction:(NSString *)eventName
           eventItems:(NSArray *)eventItems
          referenceId:(NSString *)refId
        revenueAmount:(float)revenueAmount
         currencyCode:(NSString *)currencyCode
     transactionState:(NSInteger)transactionState
              receipt:(NSData *)receipt
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:eventName
                                               eventItems:eventItems
                                              referenceId:refId
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode
                                         transactionState:transactionState
                                                  receipt:receipt];
    }];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:@(eventId)];
    }];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                     referenceId:(NSString *)refId
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:@(eventId)
                                              referenceId:refId];
    }];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                   revenueAmount:(float)revenueAmount
                    currencyCode:(NSString *)currencyCode
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:@(eventId)
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode];
    }];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                     referenceId:(NSString *)refId
                   revenueAmount:(float)revenueAmount
                    currencyCode:(NSString *)currencyCode
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:@(eventId)
                                              referenceId:refId
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode];
    }];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                      eventItems:(NSArray *)eventItems
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:@(eventId)
                                               eventItems:eventItems];
    }];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                      eventItems:(NSArray *)eventItems
                     referenceId:(NSString *)refId
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:@(eventId)
                                               eventItems:eventItems
                                              referenceId:refId];
    }];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                      eventItems:(NSArray *)eventItems
                   revenueAmount:(float)revenueAmount
                    currencyCode:(NSString *)currencyCode
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:@(eventId)
                                               eventItems:eventItems
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode];
    }];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                      eventItems:(NSArray *)eventItems
                     referenceId:(NSString *)refId
                   revenueAmount:(float)revenueAmount
                    currencyCode:(NSString *)currencyCode
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:@(eventId)
                                               eventItems:eventItems
                                              referenceId:refId
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode];
    }];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                      eventItems:(NSArray *)eventItems
                     referenceId:(NSString *)refId
                   revenueAmount:(float)revenueAmount
                    currencyCode:(NSString *)currencyCode
                transactionState:(NSInteger)transactionState
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:@(eventId)
                                               eventItems:eventItems
                                              referenceId:refId
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode
                                         transactionState:transactionState];
    }];
}

+ (void)measureActionWithEventId:(NSInteger)eventId
                      eventItems:(NSArray *)eventItems
                     referenceId:(NSString *)refId
                   revenueAmount:(float)revenueAmount
                    currencyCode:(NSString *)currencyCode
                transactionState:(NSInteger)transactionState
                         receipt:(NSData *)receipt
{
    [opQueue addOperationWithBlock:^{
        [[self sharedManager] trackActionForEventIdOrName:@(eventId)
                                               eventItems:eventItems
                                              referenceId:refId
                                            revenueAmount:revenueAmount
                                             currencyCode:currencyCode
                                         transactionState:transactionState
                                                  receipt:receipt];
    }];
}

#pragma mark - Other Methods

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
