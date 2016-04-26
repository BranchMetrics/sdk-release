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
#import "TuneManager.h"
#import "TuneStringUtils.h"
#import "TuneUserAgentCollector.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneUserProfile.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"
#import "TuneUserAgentCollector.h"
#import "TuneManager.h"


@interface TuneDeferredDplinkr ()

@property (nonatomic, assign) id<TuneDelegate> delegate;
@property (nonatomic, assign) id<TuneDelegate> deeplinkDelegate;
@property (nonatomic, copy) void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *connectionError);

@end

static const NSTimeInterval TUNE_NSURLCONNECTION_DEFAULT_TIMEOUT = 60.;

static TuneDeferredDplinkr *dplinkr;


@implementation TuneDeferredDplinkr

+ (void)initialize {
    dplinkr = [TuneDeferredDplinkr new];
    
    // collect IFA if accessible
    [[TuneManager currentManager].userProfile updateIFA];
}

+ (void)setDelegate:(id<TuneDelegate>)tuneDelegate {
    dplinkr.delegate = tuneDelegate;
}

+ (void)checkForDeferredDeeplink:(id<TuneDelegate>)delegate {
    dplinkr.deeplinkDelegate = delegate;
    
    id<TuneDelegate> deepDelegate = dplinkr.deeplinkDelegate ?: dplinkr.delegate;
    
    if( [[TuneManager currentManager].userProfile advertiserId] == nil ||
        [[TuneManager currentManager].userProfile appleAdvertisingIdentifier] == nil) {
        if ([deepDelegate respondsToSelector:@selector(tuneDidFailDeeplinkWithError:)]) {
            NSError *error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                                 code:TuneDeepLinkErrorMissingIdentifiers
                                             userInfo:@{NSLocalizedDescriptionKey:@"Please make sure that TUNE Advertiser ID and Apple Advertising Identifier (IDFA) values have been set before calling this method."}];
            
            [deepDelegate tuneDidFailDeeplinkWithError:error];
        }
        
        return;
    }
    
    if ( [TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_DEEPLINK_CHECKED] != nil ) {
        if ([deepDelegate respondsToSelector:@selector(tuneDidFailDeeplinkWithError:)]) {
            NSError *error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                                 code:TuneDeepLinkErrorDuplicateCall
                                             userInfo:@{NSLocalizedDescriptionKey:@"Ignoring duplicate call to check deferred deep link."}];
            
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
                                  [TuneManager currentManager].userProfile.advertiserId,
                                  TUNE_SERVER_DOMAIN_DEEPLINK,
                                  TUNE_SERVER_PATH_DEEPLINK,
                                  sdkPlatform];
    
    [TuneUtils addUrlQueryParamValue:[[TuneManager currentManager].userProfile advertiserId]                    forKey:TUNE_KEY_ADVERTISER_ID            queryParams:urlString];
    [TuneUtils addUrlQueryParamValue:TUNEVERSION                                                                forKey:TUNE_KEY_VER                      queryParams:urlString];
    [TuneUtils addUrlQueryParamValue:[[TuneManager currentManager].userProfile packageName]                     forKey:TUNE_KEY_PACKAGE_NAME             queryParams:urlString];
    [TuneUtils addUrlQueryParamValue:[[TuneManager currentManager].userProfile appleAdvertisingIdentifier]      forKey:TUNE_KEY_IOS_IFA_DEEPLINK         queryParams:urlString];
    [TuneUtils addUrlQueryParamValue:[[TuneManager currentManager].userProfile appleAdvertisingTrackingEnabled] forKey:TUNE_KEY_IOS_AD_TRACKING          queryParams:urlString];
    [TuneUtils addUrlQueryParamValue:[TuneUserAgentCollector userAgent]                                         forKey:TUNE_KEY_CONVERSION_USER_AGENT    queryParams:urlString];
    
    DebugLog( @"deeplink request: %@", urlString );
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:TUNE_NSURLCONNECTION_DEFAULT_TIMEOUT];
    [request addValue:[TuneManager currentManager].userProfile.conversionKey forHTTPHeaderField:@"X-MAT-Key"];
    
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
