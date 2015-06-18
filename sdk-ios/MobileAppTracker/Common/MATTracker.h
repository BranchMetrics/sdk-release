//
//  MATTracker.h
//  MobileAppTracker
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "../Common/MATEvent_internal.h"
#import "../MATPreloadData.h"
#import "MATSettings.h"
#import "MATRegionMonitor.h"

FOUNDATION_EXPORT const NSTimeInterval MAT_SESSION_QUEUING_DELAY;


@protocol MobileAppTrackerDelegate;


@interface MATTracker : NSObject

@property (nonatomic, assign) id <MobileAppTrackerDelegate> delegate;
@property (nonatomic, retain) MATSettings *parameters;

@property (nonatomic, assign) BOOL shouldUseCookieTracking;

@property (nonatomic, assign) BOOL automateIapMeasurement;

@property (nonatomic, assign) BOOL fbLogging;
@property (nonatomic, assign) BOOL fbLimitUsage;

@property (nonatomic, readonly) MATRegionMonitor *regionMonitor;

- (void)startTrackerWithMATAdvertiserId:(NSString *)aid MATConversionKey:(NSString *)key;

- (void)applicationDidOpenURL:(NSString *)urlString sourceApplication:(NSString *)sourceApplication;

#if USE_IAD

- (void)displayiAdInView:(UIView*)view;
- (void)removeiAd;

#endif

- (void)measureEvent:(MATEvent *)event;

- (void)setTracking:(NSString*)targetAppPackageName
       advertiserId:(NSString*)targetAppAdvertiserId
            offerId:(NSString*)offerId
        publisherId:(NSString*)publisherId
           redirect:(BOOL)shouldRedirect;

- (void)setShouldAutoDetectJailbroken:(BOOL)shouldAutoDetect;
- (void)setShouldAutoGenerateAppleVendorIdentifier:(BOOL)shouldAutoGenerate;

- (void)setDebugMode:(BOOL)newDebugMode;
- (void)setAllowDuplicateRequests:(BOOL)allowDuplicates;
- (void)setPayingUser:(BOOL)isPayingUser;
- (void)setPreloadData:(MATPreloadData *)preloadData;
- (BOOL)isiAdAttribution;

@end
