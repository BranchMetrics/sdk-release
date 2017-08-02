//
//  TuneSmartWhereHelper.m
//  TuneMarketingConsoleSDK
//
//  Created by Gordon Stewart on 8/4/16.
//  Copyright © 2016 Tune. All rights reserved.
//

#import "TuneSmartWhereHelper.h"
#import "TuneEvent.h"
#import "TuneSkyhookPayloadConstants.h"
#import "TuneKeyStrings.h"
#import "TuneUtils.h"

static id _smartWhere;
static TuneSmartWhereHelper *tuneSharedSmartWhereHelper = nil;
static dispatch_once_t smartWhereHelperToken;

NSString * const TUNE_SMARTWHERE_CLASS_NAME = @"SmartWhere";

NSString * const TUNE_SMARTWHERE_ENABLE_NOTIFICATION_PERMISSION_PROMPTING = @"ENABLE_NOTIFICATION_PERMISSION_PROMPTING";
NSString * const TUNE_SMARTWHERE_ENABLE_LOCATION_PERMISSION_PROMPTING = @"ENABLE_LOCATION_PERMISSION_PROMPTING";
NSString * const TUNE_SMARTWHERE_ENABLE_GEOFENCE_RANGING = @"ENABLE_GEOFENCE_RANGING";
NSString * const TUNE_SMARTWHERE_DELEGATE_NOTIFICATIONS = @"DELEGATE_NOTIFICATIONS";
NSString * const TUNE_SMARTWHERE_DEBUG_LOGGING = @"DEBUG_LOGGING";
NSString * const TUNE_SMARTWHERE_PACKAGE_NAME = @"PACKAGE_NAME";

@interface TuneSmartWhereHelper()

/*!
 * TUNE Advertiser ID.
 */
@property (nonatomic, copy) NSString *aid;
/*!
 * TUNE Conversion Key.
 */
@property (nonatomic, copy) NSString *key;

@end

@implementation TuneSmartWhereHelper

+ (TuneSmartWhereHelper *)getInstance {
    dispatch_once(&smartWhereHelperToken, ^{
        tuneSharedSmartWhereHelper = [TuneSmartWhereHelper new];
        tuneSharedSmartWhereHelper.enableSmartWhereEventSharing = NO;
    });
    return tuneSharedSmartWhereHelper;
}

+ (BOOL)isSmartWhereAvailable {
    return ([TuneUtils getClassFromString:TUNE_SMARTWHERE_CLASS_NAME] != nil);
}

- (void)startMonitoringWithTuneAdvertiserId:(NSString *)aid tuneConversionKey:(NSString *)key packageName:(NSString*) packageName {
    @synchronized(self) {
        if ([TuneSmartWhereHelper isSmartWhereAvailable] && _smartWhere == nil && aid != nil && key != nil) {
            _aid = aid;
            _key = key;
            _packageName = packageName;
            [self performSelectorOnMainThread:@selector(startMonitoring) withObject:nil waitUntilDone:YES];
        }
    }
}

- (void)startMonitoring {
    NSMutableDictionary *config = [NSMutableDictionary new];
    
    config[TUNE_SMARTWHERE_ENABLE_NOTIFICATION_PERMISSION_PROMPTING] = TUNE_STRING_FALSE;
    config[TUNE_SMARTWHERE_ENABLE_LOCATION_PERMISSION_PROMPTING] = TUNE_STRING_FALSE;
    config[TUNE_SMARTWHERE_ENABLE_GEOFENCE_RANGING] = TUNE_STRING_TRUE;
    config[TUNE_SMARTWHERE_DELEGATE_NOTIFICATIONS] = TUNE_STRING_TRUE;
    config[TUNE_SMARTWHERE_PACKAGE_NAME] = _packageName;
    
    if ([[TuneManager currentManager].configuration.debugMode boolValue]) {
        config[TUNE_SMARTWHERE_DEBUG_LOGGING] = TUNE_STRING_TRUE;
    }
    
    WarnLog(@"TUNE: Starting SmartWhere Proximity Monitoring");
    
    [self startProximityMonitoringWithAppId:_aid withApiKey:_aid withApiSecret:_key withConfig:config];
}

- (void)stopMonitoring {
    @synchronized(self) {
        if (_smartWhere) {
            [self performSelectorOnMainThread:@selector(invalidateSmartwhere) withObject:nil waitUntilDone:YES];
        }
    }
}

- (void)invalidateSmartwhere {
    WarnLog(@"TUNE: Stopping SmartWhere Proximity Monitoring");
    
    [_smartWhere invalidate];
    _smartWhere = nil;
}

- (void)setDebugMode:(BOOL)enable {
    @synchronized(self) {
        if (_smartWhere) {
            NSMutableDictionary *config = [NSMutableDictionary new];
            config[TUNE_SMARTWHERE_DEBUG_LOGGING] = enable ? TUNE_STRING_TRUE : TUNE_STRING_FALSE;
            [self setConfig:config];
        }
    }
}

- (void)processMappedEvent:(TuneSkyhookPayload*) payload{
    @synchronized(self) {
        if (_smartWhere && self.enableSmartWhereEventSharing) {
            NSDictionary *userInfo = payload.userInfo;
            if (userInfo){
                TuneEvent *event = userInfo[TunePayloadCustomEvent];
                if (event){
                    [_smartWhere performSelector:@selector(processMappedEvent:) withObject:event.eventName];
                }
            }
        }
    }
}

- (void)setPackageName:(NSString *)packageName {
    @synchronized(self) {
        if (_smartWhere) {
            NSMutableDictionary *config = [NSMutableDictionary new];
            config[TUNE_SMARTWHERE_PACKAGE_NAME] = packageName;
            [self setConfig:config];
        }
    }
}


#pragma mark - SmartWhere methods

- (void)startProximityMonitoringWithAppId:(NSString *)appId
                               withApiKey:(NSString *)apiKey
                            withApiSecret:(NSString *)apiSecret
                               withConfig:(NSDictionary *)config {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL selInitWithAppId = @selector(initWithAppId:apiKey:apiSecret:withConfig:);
    Class classSmartWhere = NSClassFromString(TUNE_SMARTWHERE_CLASS_NAME);
    
    NSMethodSignature *signature = [classSmartWhere instanceMethodSignatureForSelector:selInitWithAppId];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation retainArguments];
    [invocation setTarget:[classSmartWhere alloc]];
    [invocation setSelector:selInitWithAppId];
    [invocation setArgument:&appId atIndex:2];
    [invocation setArgument:&apiKey atIndex:3];
    [invocation setArgument:&apiSecret atIndex:4];
    [invocation setArgument:&config atIndex:5];
    [invocation invoke];
    
    id __unsafe_unretained tempResultSet;
    [invocation getReturnValue:&tempResultSet];
    _smartWhere = tempResultSet;
    
    [_smartWhere performSelector:@selector(setDelegate:) withObject:self];
#pragma clang diagnostic pop
}

- (void)setConfig:(NSDictionary *)config {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL selSetConfig = @selector(configWithDictionary:);
    Class classSmartWhere = NSClassFromString(TUNE_SMARTWHERE_CLASS_NAME);
    
    NSMethodSignature *signature = [classSmartWhere methodSignatureForSelector:selSetConfig];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation retainArguments];
    [invocation setTarget:classSmartWhere];
    [invocation setSelector:selSetConfig];
    [invocation setArgument:&config atIndex:2];
    [invocation invoke];
#pragma clang diagnostic pop
}


#pragma mark - handle smartWhere location events

- (void)smartWhere:(id)smartwhere didReceiveLocalNotification:(ProximityNotification *)notification {
    // Handle notification here.  e.g. put up a dialog or add to a list.  The notification is used to fire events like interstitials,
    // custom events as deep links.  etc...
    // Use [_smartwhere fireLocalNotificationAction: notification] to execute the event
    
    ProximityAction *action = notification.action;
    NSString *message = [NSString stringWithFormat:@"didReceiveLocalNotification: %ld %@ withProperties: %@ triggeredBy: %ld", (long)action.actionType, action.values, notification.eventProperties, (long)notification.triggerType];
    InfoLog(@"%@", message);
}

- (void)smartWhere:(id)smartwhere didReceiveCustomBeaconAction:(ProximityAction *)action withBeaconProperties:(NSDictionary *)beaconProperties triggeredBy:(TUNE_SW_ProximityTriggerType)trigger {
    NSString *message = [NSString stringWithFormat:@"didReceiveCustomBeaconAction: %ld %@ withBeaconProperties: %@ triggeredBy: %ld", (long)action.actionType, action.values, beaconProperties, (long)trigger];
    InfoLog(@"%@", message);
}

- (void)smartWhere:(id)smartwhere didReceiveCustomFenceAction:(ProximityAction *)action withFenceProperties:(NSDictionary *)fenceProperties triggeredBy:(TUNE_SW_ProximityTriggerType)trigger {
    NSString *message = [NSString stringWithFormat:@"didReceiveCustomFenceAction: %ld %@ withFenceProperties: %@ triggeredBy: %ld", (long)action.actionType, action.values, fenceProperties, (long)trigger];
    InfoLog(@"%@", message);
}

- (void)smartWhere:(id)smartwhere didReceiveCommunicationError:(NSError *)error {
    NSString *message = [NSString stringWithFormat:@"didReceiveCommunicationError: %@ %ld", error.domain, (long)error.code];
    InfoLog(@"%@", message);
}


#pragma mark - getters and setters for test
- (void)setSmartWhere:(id)smartWhere {
    _smartWhere = smartWhere;
}

- (id)getSmartWhere {
    return _smartWhere;
}

+ (void)invalidateForTesting {
    _smartWhere = nil;
    tuneSharedSmartWhereHelper = nil;
    smartWhereHelperToken = 0;
}

@end
