//
//  TuneDeeplinker.m
//  Tune
//
//  Created by John Bender on 12/17/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import "TuneDeeplinker.h"

#import "Tune+Internal.h"
#import "TuneHttpUtils.h"
#import "TuneIfa.h"
#import "TuneKeyStrings.h"
#import "TuneStringUtils.h"
#import "TuneUserAgentCollector.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneUserProfile.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"


@interface TuneDeeplinker ()

// keep local copies of required params, so that this class can
// work independently and does not have to wait for Tune class init
@property (nonatomic, assign) id<TuneDelegate> delegate;
@property (nonatomic, copy) NSString *tuneAdvId;
@property (nonatomic, copy) NSString *tuneConvKey;
@property (nonatomic, copy) NSString *tunePackageName;
@property (nonatomic, copy) NSString *appleIfa;
@property (nonatomic, assign) BOOL appleAdTrackingEnabled;

@property (nonatomic, strong) NSSet *registeredTuneLinkDomains;

@property (nonatomic, copy) void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *connectionError);

@end

static const NSTimeInterval TUNE_NSURLCONNECTION_DEFAULT_TIMEOUT = 60.;

static const NSString *TLNK_IO = @"tlnk.io";

static TuneDeeplinker *dplinkr;


@implementation TuneDeeplinker

+ (void)initialize {
    dplinkr = [TuneDeeplinker new];
    
    // to start with, auto-collect IFA if accessible
    TuneIfa *ifaInfo = [TuneIfa ifaInfo];
    
    if (ifaInfo) {
        dplinkr.appleIfa = ifaInfo.ifa;
        dplinkr.appleAdTrackingEnabled = ifaInfo.trackingEnabled;
    }
    
    // by default, use the app bundleId as the Tune package name
    if (!dplinkr.tunePackageName) {
        dplinkr.tunePackageName = [TuneUtils bundleId];
    }
    
    // Initialize registered domains with "tlnk.io"
    dplinkr.registeredTuneLinkDomains = [NSSet setWithObject:TLNK_IO];
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

+ (void)requestDeferredDeeplink {
    id<TuneDelegate> deepDelegate = dplinkr.delegate;
    
    if ( [TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_DEEPLINK_CHECKED] != nil ) {
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

+ (void)handleFailedExpandedTuneLink:(NSString *)errorMessage {
    id<TuneDelegate> deepDelegate = dplinkr.delegate;

    if ([deepDelegate respondsToSelector:@selector(tuneDidFailDeeplinkWithError:)]) {
        NSError *error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                             code:TuneDeepLinkErrorNoInvokeUrl
                                         userInfo:@{NSLocalizedDescriptionKey:errorMessage}];

        [deepDelegate tuneDidFailDeeplinkWithError:error];
    }
}

+ (void)handleExpandedTuneLink:(NSString *)invokeUrl {
    id<TuneDelegate> deepDelegate = dplinkr.delegate;

    if ([deepDelegate respondsToSelector:@selector(tuneDidReceiveDeeplink:)]) {
        [deepDelegate tuneDidReceiveDeeplink:invokeUrl];
    }
}

+ (void)registerCustomTuneLinkDomain:(NSString *)domain {
    @synchronized (self) {
        if (domain) {
            NSMutableSet *domainsMutableSet = [dplinkr.registeredTuneLinkDomains mutableCopy];
            [domainsMutableSet addObject:domain];
            dplinkr.registeredTuneLinkDomains = [domainsMutableSet copy];
        }
    }
}

+ (BOOL)isTuneLink:(NSString *)linkUrl {
    @synchronized (self) {
        BOOL isTuneLink = NO;
    
        NSURL *url = [NSURL URLWithString:linkUrl];
        NSString *scheme = [url scheme];
        if (!([scheme isEqualToString:@"https"] || [scheme isEqualToString:@"http"])) {
            // All Tune Links are https or http
            return NO;
        }
        NSString *host = [url host];
        for (NSString *registeredTuneDomain in dplinkr.registeredTuneLinkDomains) {
            if ([host hasSuffix:registeredTuneDomain]) {
                isTuneLink = YES;
                break;
            }
        }
    
        return isTuneLink;
    }
}

+ (bool)hasInvokeUrl:(NSString *)linkUrl {
    return [self invokeUrlFromReferralUrl:linkUrl] != nil;
}

+ (void)checkForExpandedTuneLinks:(NSString *)link inResponse:(NSString *)response {
    if ([self isTuneLinkMeasurementRequest:link] && ![self isInvokeUrlParameterInReferralUrl]) {
        // If invoke_url not found in Tune Link response, log error
        if ([response rangeOfString:[NSString stringWithFormat:@"\"%@\":\"", TUNE_KEY_INVOKE_URL]].location == NSNotFound) {
            DebugLog(@"Error parsing response %@ to check for invoke url", response);
        } else {
            // Regex to find the value of invoke_url json key
            NSString *pattern = [NSString stringWithFormat:@"(?<=\"%@\":\")([-a-zA-Z0-9@:%%_\\\\+.~#?&\\/\\/=]*)\"", TUNE_KEY_INVOKE_URL];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:nil];
            NSTextCheckingResult *match = [regex firstMatchInString:response options:NSMatchingReportCompletion range:NSMakeRange(0, [response length])];
            
            // If the invoke_url is found, handle it
            if (match.range.location != NSNotFound) {
                NSString *invokeUrl = [response substringWithRange:[match rangeAtIndex:1]];
                [TuneDeeplinker handleExpandedTuneLink:invokeUrl];
            } else {
                [TuneDeeplinker handleFailedExpandedTuneLink:@"There is no invoke url for this Tune Link"];
            }
        }
    }
}

+ (BOOL)isInvokeUrlParameterInReferralUrl {
    NSString *referralUrl = [[TuneManager currentManager].userProfile referralUrl];
    return ([self invokeUrlFromReferralUrl:referralUrl] != nil);
}

+ (BOOL)isTuneLinkMeasurementRequest:(NSString *)link {
    return [TuneStringUtils string:link containsString:[NSString stringWithFormat:@"%@=%@", TUNE_KEY_ACTION, TUNE_EVENT_CLICK]];
}

+ (NSString *)invokeUrlFromReferralUrl:(NSString *)referralUrl {
    NSString *invokeUrl = nil;
    if (referralUrl) {
        if ([TuneStringUtils string:referralUrl containsString:TUNE_KEY_INVOKE_URL]) {
            // Get invoke_url query param from referral URL
            // Can't use NSURLQueryItem because we need to support iOS 6.0
            NSArray *urlComponents = [referralUrl componentsSeparatedByString:@"?"];
            NSString *urlQueryParamsString = [urlComponents lastObject];
            NSArray *urlQueryParams = [urlQueryParamsString componentsSeparatedByString:@"&"];
            
            for (NSString *keyValuePair in urlQueryParams) {
                NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
                NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
                NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
                
                if ([key isEqualToString:TUNE_KEY_INVOKE_URL]) {
                    invokeUrl = value;
                    break;
                }
            }
        }
    }
    return invokeUrl;
}

@end
