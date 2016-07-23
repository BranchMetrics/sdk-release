//
//  TuneDeferredDplinkr.m
//  Tune
//
//  Created by John Bender on 12/17/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import "TuneDeferredDplinkr.h"

#import "Tune+Internal.h"
#import "TuneHttpUtils.h"
#import "TuneIfa.h"
#import "TuneKeyStrings.h"
#import "TuneStringUtils.h"
#import "TuneUserAgentCollector.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"


@interface TuneDeferredDplinkr ()

// keep local copies of required params, so that this class can
// work independently and does not have to wait for Tune class init
@property (nonatomic, assign) id<TuneDelegate> delegate;
@property (nonatomic, assign) id<TuneDelegate> deeplinkDelegate;
@property (nonatomic, copy) NSString *tuneAdvId;
@property (nonatomic, copy) NSString *tuneConvKey;
@property (nonatomic, copy) NSString *tunePackageName;
@property (nonatomic, copy) NSString *appleIfa;
@property (nonatomic, assign) BOOL appleAdTrackingEnabled;

@property (nonatomic, copy) void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *connectionError);

@end

static const NSTimeInterval TUNE_NSURLCONNECTION_DEFAULT_TIMEOUT = 60.;

static TuneDeferredDplinkr *dplinkr;


@implementation TuneDeferredDplinkr

+ (void)initialize {
    dplinkr = [TuneDeferredDplinkr new];
    
    // to start with, auto-collect IFA if accessible
    TuneIfa *ifaInfo = [TuneIfa ifaInfo];
    
    if(ifaInfo) {
        dplinkr.appleIfa = ifaInfo.ifa;
        dplinkr.appleAdTrackingEnabled = ifaInfo.trackingEnabled;
    }
    
    // by default, use the app bundleId as the Tune package name
    if(!dplinkr.tunePackageName) {
        dplinkr.tunePackageName = [TuneUtils bundleId];
    }
}

+ (void)setDelegate:(id<TuneDelegate>)tuneDelegate {
    dplinkr.delegate = tuneDelegate;
}

+ (void)setTuneAdvertiserId:(NSString *)adId tuneConversionKey:(NSString *)convKey {
    dplinkr.tuneAdvId = adId;
    dplinkr.tuneConvKey = convKey;
}

+ (void)setTunePackageName:(NSString *)pkgName {
    dplinkr.tunePackageName = pkgName;
}

+ (void)setAppleIfa:(NSString *)ifa appleAdTrackingEnabled:(BOOL)enabled {
    dplinkr.appleIfa = ifa;
    dplinkr.appleAdTrackingEnabled = enabled;
}

+ (void)checkForDeferredDeeplink:(id<TuneDelegate>)delegate {
    dplinkr.deeplinkDelegate = delegate;
    
    id<TuneDelegate> deepDelegate = dplinkr.deeplinkDelegate ?: dplinkr.delegate;
    
    if ( [TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_DEEPLINK_CHECKED] != nil ) {
        if ([deepDelegate respondsToSelector:@selector(tuneDidFailDeeplinkWithError:)]) {
            NSError *error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                                 code:TuneDeepLinkErrorDuplicateCall
                                             userInfo:@{NSLocalizedDescriptionKey:@"Ignoring duplicate call to check deferred deep link."}];
            
            [deepDelegate tuneDidFailDeeplinkWithError:error];
        }
        
        return;
    }
    
    if( dplinkr.tuneAdvId == nil ) {
        if ([deepDelegate respondsToSelector:@selector(tuneDidFailDeeplinkWithError:)]) {
            NSError *error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                                 code:TuneDeepLinkErrorMissingIdentifiers
                                             userInfo:@{NSLocalizedDescriptionKey:@"Please make sure that TUNE Advertiser ID has been set before calling this method."}];
            
            [deepDelegate tuneDidFailDeeplinkWithError:error];
        }
        
        return;
    }
    
    // persist state so deeplink isn't requested twice
    [TuneUserDefaultsUtils setUserDefaultValue:@YES forKey:TUNE_KEY_DEEPLINK_CHECKED];
    
    NSString *sdkPlatform = TUNE_KEY_IOS;
#if TARGET_OS_TV
    sdkPlatform = TUNE_KEY_TVOS;
#elif TARGET_OS_WATCH
    sdkPlatform = TUNE_KEY_WATCHOS;
#endif
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@://%@.%@/%@?platform=%@",
                                  TUNE_KEY_HTTPS,
                                  dplinkr.tuneAdvId,
                                  TUNE_SERVER_DOMAIN_DEEPLINK,
                                  TUNE_SERVER_PATH_DEEPLINK,
                                  sdkPlatform];
    
    [TuneUtils addUrlQueryParamValue:dplinkr.tuneAdvId                  forKey:TUNE_KEY_ADVERTISER_ID            queryParams:urlString];
    [TuneUtils addUrlQueryParamValue:TUNEVERSION                        forKey:TUNE_KEY_VER                      queryParams:urlString];
    [TuneUtils addUrlQueryParamValue:dplinkr.tunePackageName            forKey:TUNE_KEY_PACKAGE_NAME             queryParams:urlString];
    
    if( ![dplinkr.appleIfa isEqualToString:TUNE_KEY_GUID_EMPTY] ) {
        [TuneUtils addUrlQueryParamValue:dplinkr.appleIfa               forKey:TUNE_KEY_IOS_IFA_DEEPLINK         queryParams:urlString];
    }
    
    [TuneUtils addUrlQueryParamValue:@(dplinkr.appleAdTrackingEnabled)  forKey:TUNE_KEY_IOS_AD_TRACKING          queryParams:urlString];
    [TuneUtils addUrlQueryParamValue:[TuneUserAgentCollector userAgent] forKey:TUNE_KEY_CONVERSION_USER_AGENT    queryParams:urlString];
    
    DebugLog( @"deeplink request: %@", urlString );
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:TUNE_NSURLCONNECTION_DEFAULT_TIMEOUT];
    [request addValue:dplinkr.tuneConvKey forHTTPHeaderField:@"X-MAT-Key"];
    
    dplinkr.completionHandler = ^(NSData *data, NSURLResponse *response, NSError *connectionError) {
        NSError *error = nil;
        
        if( !connectionError ) {
            NSString *link = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            DebugLog( @"deeplink response: [%d] %@", (int)[(NSHTTPURLResponse*)response statusCode], link );
            
            if(200 == (int)[(NSHTTPURLResponse*)response statusCode]) {
                __block NSURL *deeplink = [NSURL URLWithString:link];
                
                if( deeplink ) {
                    // check and call success delegate callback
                    if ([deepDelegate respondsToSelector:@selector(tuneDidReceiveDeeplink:)]) {
                        [deepDelegate tuneDidReceiveDeeplink:deeplink.absoluteString];
                    }
                } else {
                    DebugLog( @"response was not a valid URL: %@", link );
                    
                    error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                                code:TuneDeepLinkErrorMalformedDeepLinkUrl
                                            userInfo:@{NSLocalizedDescriptionKey:@"Malformed deferred deep link", TUNE_KEY_REQUEST_URL:response.URL.absoluteString}];
                }
            } else {
                DebugLog( @"invalid http status code %d, response: %@", (int)[(NSHTTPURLResponse*)response statusCode], link );
            
                error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                            code:[(NSHTTPURLResponse*)response statusCode]
                                        userInfo:@{NSLocalizedDescriptionKey:@"Deferred deep link not found", TUNE_KEY_REQUEST_URL:response.URL.absoluteString}];
            }
        } else {
            error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                        code:TuneDeepLinkErrorNetworkError
                                    userInfo:@{NSLocalizedDescriptionKey:@"Network error when retrieving deferred deep link", NSUnderlyingErrorKey:connectionError}];
        }
        
        if(error) {
            DebugLog( @"error: %@", error );

            // check and call error delegate callback
            if ([deepDelegate respondsToSelector:@selector(tuneDidFailDeeplinkWithError:)]) {
                [deepDelegate tuneDidFailDeeplinkWithError:error];
            }
        }
    };
    
    [TuneHttpUtils performAsynchronousRequest:request completionHandler:dplinkr.completionHandler];
}

@end
