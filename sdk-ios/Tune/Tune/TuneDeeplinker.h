//
//  TuneDeeplinker.h
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
    TuneDeepLinkErrorNetworkError           = 1503,
    TuneDeepLinkErrorNoInvokeUrl            = 1504
};

@interface TuneDeeplinker : NSObject

/*!
 Requests a deferred deeplink from measurement and returns the deeplink value to the delegate if one is found,
 or returns error to the delegate if an error was encountered.
 If a deeplink has been requested before (not first install), then exits early.
 */
+ (void)requestDeferredDeeplink;
+ (void)setDelegate:(id<TuneDelegate>)tuneDelegate;
+ (void)setTuneAdvertiserId:(NSString *)adId tuneConversionKey:(NSString *)convKey;
+ (void)setTunePackageName:(NSString *)pkgName;
+ (void)setAppleIfa:(NSString *)ifa appleAdTrackingEnabled:(BOOL)enabled;
+ (void)handleFailedExpandedTuneLink:(NSString *)errorMessage;
+ (void)handleExpandedTuneLink:(NSString *)invokeUrl;

/*!
 Looks for "invoke_url" value in click server response. If found, returns the invoke_url value to deeplink delegate.
 @param link Click link
 @param response Server response from click
 */
+ (void)checkForExpandedTuneLinks:(NSString *)link inResponse:(NSString *)response;
+ (void)registerCustomTuneLinkDomain:(NSString *)domain;

/*!
 Checks whether a given URL is a Tune Link, i.e. a tlnk.io or other accepted domain.
 @param linkUrl URL to check.
 @return If URL is a Tune Link.
 */
+ (BOOL)isTuneLink:(NSString *)linkUrl;

/*!
 Checks if a given URL contains the "invoke_url" query param.
 @param linkUrl URL to check.
 @return If URL contains "invoke_url" query param.
 */
+ (bool)hasInvokeUrl:(NSString *)linkUrl;

/*!
 Retrieves "invoke_url" query param value from referral URL.
 @param referralUrl Referral URL to parse.
 @return invoke_url query param value.
 */
+ (NSString *)invokeUrlFromReferralUrl:(NSString *)referralUrl;

@end
