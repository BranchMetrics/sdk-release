//
//  TuneDeferredDplinkr.h
//  Tune
//
//  Created by John Bender on 12/17/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TuneDelegate;

typedef NS_ENUM(NSInteger, TuneDeepLinkError) {
    TuneDeepLinkErrorMissingIdentifiers     = 1500,
    TuneDeepLinkErrorMalformedDeepLinkUrl   = 1501,
    TuneDeepLinkErrorDuplicateCall          = 1502,
    TuneDeepLinkErrorNetworkError           = 1503
};

@interface TuneDeferredDplinkr : NSObject

+ (void)checkForDeferredDeeplink:(id<TuneDelegate>)delegate;
+ (void)setDelegate:(id<TuneDelegate>)tuneDelegate;
+ (void)setTuneAdvertiserId:(NSString *)adId tuneConversionKey:(NSString *)convKey;
+ (void)setTunePackageName:(NSString *)pkgName;
+ (void)setAppleIfa:(NSString *)ifa appleAdTrackingEnabled:(BOOL)enabled;

@end
