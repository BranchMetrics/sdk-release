//
//  TuneDeferredDplinkr.h
//  Tune
//
//  Created by John Bender on 12/17/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TuneDelegate;

@interface TuneDeferredDplinkr : NSObject

+ (void)setAdvertiserId:(NSString*)advertiserId conversionKey:(NSString*)conversionKey;

+ (void)setDelegate:(id<TuneDelegate>)delegate;

+ (void)setPackageName:(NSString*)packageName;

+ (void)setIFA:(NSString*)appleAdvertisingIdentifier trackingEnabled:(BOOL)adTrackingEnabled;

+ (void)checkForDeferredDeeplinkWithTimeout:(NSTimeInterval)timeout;

@end
