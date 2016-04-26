//
//  TuneState.h
//  Tune
//
//  Created by Kevin Jenkins on 6/11/13.
//
//

#import <Foundation/Foundation.h>

#import "TuneModule.h"
#import "TuneReachability.h"

enum TuneCurrentNetworkType {
    TuneCurrentNetworkTypeWifi = 1,
    TuneCurrentNetworkTypeIP,
    TuneCurrentNetworkTypeCarrier
};
typedef enum TuneCurrentNetworkType TuneCurrentNetworkType;

@interface TuneState : TuneModule {
#if !TARGET_OS_WATCH
    UIBackgroundTaskIdentifier bgTask;
#endif
}

+ (NSDictionary *)localConfiguration;

+ (void)updateSwizzleDisabled:(BOOL)value;
+ (void)updateTMADisabledState:(BOOL)value;
+ (void)updateTMAPermanentlyDisabledState:(BOOL)value;
+ (void)updateDisabledClasses;
+ (void)updateConnectedMode:(BOOL)value;

+ (BOOL)isSwizzleDisabled;
+ (BOOL)doSendScreenViews;
+ (BOOL)didOptIntoTMA;
+ (BOOL)isTMADisabled;
+ (BOOL)isTMAPermanentlyDisabled;  // Whether the app has been kill-switched (no turning back).
+ (BOOL)isDisabledClass:(NSString *)className;
+ (BOOL)isInConnectedMode;

@end
