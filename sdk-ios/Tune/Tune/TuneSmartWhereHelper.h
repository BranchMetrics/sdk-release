//
//  TuneSmartWhereHelper.h
//  TuneMarketingConsoleSDK
//
//  Created by Gordon Stewart on 8/4/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#if TUNE_ENABLE_SMARTWHERE

#import <Foundation/Foundation.h>

@protocol SmartWhereDelegate
@end

/*!
 * TUNE-SmartWhere bridge class. Provides methods to start and stop SmartWhere proximity monitoring.
 */
@interface TuneSmartWhereHelper : NSObject <SmartWhereDelegate>
/*!
 * TUNE Advertiser ID.
 */
@property (nonatomic, copy) NSString *aid;
/*!
 * TUNE Conversion Key.
 */
@property (nonatomic, copy) NSString *key;

/*!
 * Checks if SmartWhere class is available.
 * @return YES if SmartWhere class is available, NO otherwise
 */
+ (BOOL)isSmartWhereAvailable;

/*!
 * Gets the shared instance of this class.
 * @return shared instance of this class
 */
+ (TuneSmartWhereHelper *)getInstance;

/*!
 * Starts SmartWhere proximity monitoring when valid TUNE Advertiser ID and TUNE Conversion Key values are provided. This method should be called only when SmartWhere class is available and geo-location auto-collection has been enabled.
 */
- (void)startMonitoringWithTuneAdvertiserId:(NSString *)aid tuneConversionKey:(NSString *)key;

/*!
 * Stops SmartWhere proximity monitoring.
 */
- (void)stopMonitoring;

/*!
 * Sets the SmartWhere debug mode.
 * @param enable boolean value for debug mode, defaults to NO
 */
- (void)setDebugMode:(BOOL)enable;
@end

#ifndef TUNE_SW_EventActionType_Defined
#define TUNE_SW_EventActionType_Defined

typedef enum TUNE_SW_EventActionType : NSInteger {
    TUNE_SW_EventActionTypeUnknown = -1,
    TUNE_SW_EventActionTypeUrl = 0,
    TUNE_SW_EventActionTypeUri = 1,
    TUNE_SW_EventActionTypeCall = 2,
    TUNE_SW_EventActionTypeSMS = 3,
    TUNE_SW_EventActionTypeEmail = 5,
    TUNE_SW_EventActionTypeMarket = 9,
    TUNE_SW_EventActionTypeCoupon = 12,
    TUNE_SW_EventActionTypeTwitter = 13,
    TUNE_SW_EventActionTypeYoutube = 14,
    TUNE_SW_EventActionTypeHTML = 16,
    TUNE_SW_EventActionTypeNewAction = 126,
    TUNE_SW_EventActionTypeCustom = 127
} TUNE_SW_EventActionType;

typedef enum TUNE_SW_ProximityTriggerType : NSInteger {
    TUNE_SW_swNfcTap = 0,
    TUNE_SW_swQRScan = 1,
    TUNE_SW_swBleEnter = 10,
    TUNE_SW_swBleHover = 11,
    TUNE_SW_swBleDwell = 12,
    TUNE_SW_swBleExit = 13,
    TUNE_SW_swGeoFenceEnter = 20,
    TUNE_SW_swGeoFenceDwell = 21,
    TUNE_SW_swGeoFenceExit = 22,
} TUNE_SW_ProximityTriggerType;

#endif

@interface ProximityAction : NSObject<NSCoding>
@property (nonatomic, assign) TUNE_SW_EventActionType actionType;
@property (nonatomic, copy) NSDictionary *values;
@end

@interface ProximityNotification : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, strong) ProximityAction *action;
@property (nonatomic, copy) NSDictionary *proximityObjectProperties;
@property (nonatomic, copy) NSDictionary *eventProperties;
@property (nonatomic, assign) TUNE_SW_ProximityTriggerType triggerType;
@end

#endif
