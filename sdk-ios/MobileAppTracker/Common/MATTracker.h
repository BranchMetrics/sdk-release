//
//  MATTracker.h
//  MobileAppTracker
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MATSettings.h"
#import "MATConnectionManager.h"

@protocol MobileAppTrackerDelegate;


@interface MATTracker : NSObject

@property (nonatomic, assign) id <MobileAppTrackerDelegate> delegate;
@property (nonatomic, retain) MATConnectionManager *connectionManager;
@property (nonatomic, retain) MATSettings *parameters;

@property (nonatomic, assign) BOOL shouldUseCookieTracking;

- (void)startTrackerWithMATAdvertiserId:(NSString *)aid MATConversionKey:(NSString *)key;

- (void)applicationDidOpenURL:(NSString *)urlString sourceApplication:(NSString *)sourceApplication;

- (void)displayiAdInView:(UIView*)view;
- (void)removeiAd;

- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName;
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                        referenceId:(NSString *)refId;
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems;
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId;
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode;
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
                   transactionState:(NSInteger)transactionState;
- (void)trackActionForEventIdOrName:(NSString *)eventIdOrName
                         eventItems:(NSArray *)eventItems
                        referenceId:(NSString *)refId
                      revenueAmount:(float)revenueAmount
                       currencyCode:(NSString *)currencyCode
                   transactionState:(NSInteger)transactionState
                            receipt:(NSData *)receipt;

- (void)trackSession;
- (void)trackSessionWithReferenceId:(NSString *)refId;

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
-(void) setPayingUser:(BOOL)isPayingUser;
-(BOOL) isiAdAttribution;

@end
