//
//  MATTracker.h
//  MobileAppTracker
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MATSettings.h"
#import "MATRegionMonitor.h"

FOUNDATION_EXPORT const NSTimeInterval MAT_SESSION_QUEUING_DELAY;

@protocol MobileAppTrackerDelegate;


@interface MATTracker : NSObject

@property (nonatomic, assign) id <MobileAppTrackerDelegate> delegate;
@property (nonatomic, retain) MATSettings *parameters;

@property (nonatomic, assign) BOOL shouldUseCookieTracking;

@property (nonatomic, readonly) MATRegionMonitor *regionMonitor;

- (void)startTrackerWithMATAdvertiserId:(NSString *)aid MATConversionKey:(NSString *)key;

- (void)applicationDidOpenURL:(NSString *)urlString sourceApplication:(NSString *)sourceApplication;

- (void)displayiAdInView:(UIView*)view;
- (void)removeiAd;

- (void)trackActionForEventIdOrName:(id)eventIdOrName;
- (void)trackActionForEventIdOrName:(id)eventIdOrName
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;
- (void)trackActionForEventIdOrName:(id)eventIdOrName
                        referenceId:(NSString *)refId;
- (void)trackActionForEventIdOrName:(id)eventIdOrName
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;
- (void)trackActionForEventIdOrName:(id)eventIdOrName
                         eventItems:(NSArray *)eventItems;
- (void)trackActionForEventIdOrName:(id)eventIdOrName
                         eventItems:(NSArray *)eventItems
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;
- (void)trackActionForEventIdOrName:(id)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId;
- (void)trackActionForEventIdOrName:(id)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;
- (void)trackActionForEventIdOrName:(id)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
                   transactionState:(NSInteger)transactionState;
- (void)trackActionForEventIdOrName:(id)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
                   transactionState:(NSInteger)transactionState
                            receipt:(NSData *)receipt;

- (void)trackSession;

- (void)setTracking:(NSString*)targetAppPackageName
       advertiserId:(NSString*)targetAppAdvertiserId
            offerId:(NSString*)offerId
        publisherId:(NSString*)publisherId
           redirect:(BOOL)shouldRedirect;

- (void)setShouldAutoDetectJailbroken:(BOOL)shouldAutoDetect;
- (void)setShouldAutoGenerateAppleVendorIdentifier:(BOOL)shouldAutoGenerate;

- (void)setDebugMode:(BOOL)newDebugMode;
- (void)setAllowDuplicateRequests:(BOOL)allowDuplicates;
- (void)setEventAttributeN:(NSUInteger)number toValue:(NSString*)value;
- (void)setPayingUser:(BOOL)isPayingUser;
- (BOOL)isiAdAttribution;

@end
