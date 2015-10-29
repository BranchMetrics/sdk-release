//
//  TuneTracker.h
//  Tune
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class TuneEvent;
@class TunePreloadData;
@class TuneRegionMonitor;
@class TuneSettings;

FOUNDATION_EXPORT const NSTimeInterval TUNE_SESSION_QUEUING_DELAY;


@protocol TuneDelegate;


@interface TuneTracker : NSObject

@property (nonatomic, assign) id <TuneDelegate> delegate;
@property (nonatomic, strong) TuneSettings *parameters;

@property (nonatomic, assign) BOOL shouldUseCookieTracking;

@property (nonatomic, assign) BOOL automateIapMeasurement;
@property (nonatomic, assign) BOOL shouldCollectDeviceLocation;

@property (nonatomic, assign) BOOL fbLogging;
@property (nonatomic, assign) BOOL fbLimitUsage;

@property (nonatomic, readonly) TuneRegionMonitor *regionMonitor;

- (void)startTrackerWithTuneAdvertiserId:(NSString *)aid tuneConversionKey:(NSString *)key wearable:(BOOL)wearable;

- (void)applicationDidOpenURL:(NSString *)urlString sourceApplication:(NSString *)sourceApplication;

#if USE_IAD

- (void)displayiAdInView:(UIView*)view;
- (void)removeiAd;

#endif

- (void)measureEvent:(TuneEvent *)event;

- (void)setMeasurement:(NSString*)targetAppPackageName
          advertiserId:(NSString*)targetAppAdvertiserId
               offerId:(NSString*)offerId
           publisherId:(NSString*)publisherId
              redirect:(BOOL)shouldRedirect;

- (void)setShouldAutoDetectJailbroken:(BOOL)shouldAutoDetect;
- (void)setShouldAutoCollectDeviceLocation:(BOOL)shouldAutoCollect;
- (void)setShouldAutoCollectAppleAdvertisingIdentifier:(BOOL)shouldAutoCollect;
- (void)setShouldAutoGenerateAppleVendorIdentifier:(BOOL)shouldAutoGenerate;

- (void)setDebugMode:(BOOL)newDebugMode;
- (void)setAllowDuplicateRequests:(BOOL)allowDuplicates;
- (void)setPayingUser:(BOOL)isPayingUser;
- (void)setPreloadData:(TunePreloadData *)preloadData;
- (BOOL)isiAdAttribution;

@end
