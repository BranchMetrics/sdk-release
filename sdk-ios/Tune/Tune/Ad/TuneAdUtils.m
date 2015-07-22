//
//  TuneAdUtils.m
//  Tune
//
//  Created by Harshal Ogale on 9/1/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import "TuneAdUtils.h"
#import "TuneAdKeyStrings.h"
#import "../Common/TuneSettings.h"
#import "../Common/TuneTracker.h"
#import "../Common/TuneUtils.h"
#import "../Common/Tune_internal.h"
#import "../Common/NSString+TuneURLEncoding.h"

#if DEBUG_AD_STAGING
const NSString * TUNE_AD_SERVER                          = @"aa.stage.tuneapi.com"; // Stage
#else
const NSString * TUNE_AD_SERVER                          = @"aa.tuneapi.com"; // Prod
#endif

// http://p-adsapi01-sta-1a.use01.plat.priv/api/v1/ads/request/?context%5Btype%5D\=banner

//const NSString * TUNE_AD_SERVER                          = @"http://192.168.197.78:8888"; // Sam

const NSUInteger TUNE_AD_LENGTH_ITUNES_APP_ID           = 9; // ex. "550852584" --> https://itunes.apple.com/us/app/atomic-dodge-ball/id550852584?mt=8
NSString * const TUNE_AD_ITUNES_APP_ID_PREFIX           = @"/id";
NSString * const TUNE_AD_ITUNES_AFFILIATE_TOKEN_PREFIX  = @"at=";
NSString * const TUNE_AD_ITUNES_CAMPAIGN_TOKEN_PREFIX   = @"ct=";

NSString* closeImageString()
{
    return @"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";
}

@implementation TuneAdUtils

+ (NSNumber *)itunesItemIdFromUrl:(NSString *)url
{
    NSNumber *appId = nil;
    
    if(url && [NSNull null] != (id)url && url.length > 0)
    {
        NSString *lcUrl = [url lowercaseString];
        
        NSUInteger loc = [lcUrl rangeOfString:TUNE_AD_ITUNES_APP_ID_PREFIX].location;
        
        if(NSNotFound != loc
           && ([lcUrl hasPrefix:@"itms://"] || [lcUrl hasPrefix:@"http://itunes.apple.com"] || [lcUrl hasPrefix:@"https://itunes.apple.com"]))
        {
            NSString *appIdStr = [lcUrl substringWithRange:NSMakeRange(loc + TUNE_AD_ITUNES_APP_ID_PREFIX.length, TUNE_AD_LENGTH_ITUNES_APP_ID)];
            
            NSInteger intAppId = [appIdStr integerValue];
            
            appId = 0 != intAppId ? @(intAppId) : nil;
        }
    }
    
    return appId;
}

+ (NSDictionary *)itunesItemIdAndTokensFromUrl:(NSString *)url
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSNumber *appId = nil;
    
    if(url && [NSNull null] != (id)url && url.length > 0)
    {
        NSString *lcUrl = [url lowercaseString];
        
        // extract the app id from the url
        NSUInteger loc = [lcUrl rangeOfString:TUNE_AD_ITUNES_APP_ID_PREFIX].location;
        
        if(NSNotFound != loc
           && ([lcUrl hasPrefix:@"itms://"] || [lcUrl hasPrefix:@"http://itunes.apple.com"] || [lcUrl hasPrefix:@"https://itunes.apple.com"]))
        {
            NSString *appIdStr = [url substringWithRange:NSMakeRange(loc + TUNE_AD_ITUNES_APP_ID_PREFIX.length, TUNE_AD_LENGTH_ITUNES_APP_ID)];
            
            NSInteger intAppId = [appIdStr integerValue];
            
            appId = 0 != intAppId ? @(intAppId) : nil;
            
            if(appId)
            {
                dict[@"itemId"] = appId;
            }
            
            
            // extract affiliate token if param "at" exists in the url query string
            loc = [lcUrl rangeOfString:TUNE_AD_ITUNES_AFFILIATE_TOKEN_PREFIX].location;
            
            if(NSNotFound != loc)
            {
                NSUInteger locEnd = [lcUrl rangeOfString:@"&" options:NSCaseInsensitiveSearch range:NSMakeRange(loc, lcUrl.length - loc)].location;
                locEnd = NSNotFound == locEnd ? lcUrl.length : locEnd;
                
                NSUInteger rangeLen = locEnd - loc - TUNE_AD_ITUNES_AFFILIATE_TOKEN_PREFIX.length;
                NSString *affiliateToken = [url substringWithRange:NSMakeRange(loc + TUNE_AD_ITUNES_AFFILIATE_TOKEN_PREFIX.length, rangeLen)];
                
                if(affiliateToken)
                {
                    dict[@"at"] = affiliateToken;
                }
            }
            
            
            // extract campaign token if param "ct" exists in the url query string
            loc = [lcUrl rangeOfString:TUNE_AD_ITUNES_CAMPAIGN_TOKEN_PREFIX].location;
            
            if(NSNotFound != loc)
            {
                NSUInteger locEnd = [lcUrl rangeOfString:@"&" options:NSCaseInsensitiveSearch range:NSMakeRange(loc, lcUrl.length - loc)].location;
                NSUInteger rangeLen = NSNotFound == locEnd ? lcUrl.length - loc - TUNE_AD_ITUNES_CAMPAIGN_TOKEN_PREFIX.length : locEnd - loc;
                NSString *campaignToken = [url substringWithRange:NSMakeRange(loc + TUNE_AD_ITUNES_CAMPAIGN_TOKEN_PREFIX.length, rangeLen)];
                
                if(campaignToken)
                {
                    dict[@"ct"] = campaignToken;
                }
            }
        }
    }
    
    return dict;
}

+ (NSString *)tuneAdServerUrl:(TuneAdType)type
{
    TuneSettings *tuneParams = [[Tune sharedManager] parameters];
    
    return [NSString stringWithFormat:@"https://%@.request.%@/api/v1/ads/request?context[type]=%@", tuneParams.advertiserId, TUNE_AD_SERVER, TuneAdTypeInterstitial == type ? @"interstitial" : @"banner"];
}

+ (NSString *)tuneAdClickUrl:(TuneAd *)ad
{
    return [self tuneUrlForAd:ad endpoint:TUNE_AD_KEY_CLICK action:TUNE_AD_KEY_CLICK];
}

+ (NSString *)tuneAdViewUrl:(TuneAd *)ad
{
    return [self tuneUrlForAd:ad endpoint:TUNE_AD_KEY_EVENT action:TUNE_AD_KEY_VIEW];
}

+ (NSString *)tuneAdClosedUrl:(TuneAd *)ad
{
    return [self tuneUrlForAd:ad endpoint:TUNE_AD_KEY_EVENT action:TUNE_AD_KEY_CLOSE];
}

+ (NSString *)tuneUrlForAd:(TuneAd *)ad endpoint:(NSString *)endpoint action:(NSString *)action
{
    TuneSettings *tuneParams = [[Tune sharedManager] parameters];
    
    return [NSString stringWithFormat:@"https://%@.%@.%@/api/v1/ads/%@?%@=%@&%@", tuneParams.advertiserId, endpoint, TUNE_AD_SERVER, endpoint, TUNE_AD_KEY_ACTION, action, [self requestQueryParams:ad]];
}

+ (NSString *)requestQueryParams:(TuneAd *)ad
{
    NSString *query = [NSString stringWithFormat:@"%@=%@", TUNE_AD_KEY_REQUEST_ID, [[self class] urlEncode:ad.requestId]];
    
    return query;
}

+ (UIWebView *)webviewForAdView:(CGSize)size
                webviewDelegate:(id<UIWebViewDelegate>)wd
             scrollviewDelegate:(id<UIScrollViewDelegate>)sd
{
    UIWebView *webview = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    webview.scrollView.scrollEnabled = NO;
    webview.scrollView.bounces = NO;
    webview.scrollView.delegate = sd;
    webview.contentMode = UIViewContentModeCenter;
    webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webview.delegate = wd;
    webview.backgroundColor = [UIColor blackColor];
    
    if([webview respondsToSelector:@selector(setTranslatesAutoresizingMaskIntoConstraints:)])
    {
        [webview setTranslatesAutoresizingMaskIntoConstraints:YES];
    }
    
    return webview;
}

+ (NSTimeInterval)durationDelayForRetry:(NSInteger)attempt
{
    // delay in seconds
    NSTimeInterval delay = 0;
    
    switch( attempt ) {
        case 0:
            delay = 0;          // now
            break;
        case 1:
            delay = 10.;        // 10 sec
            break;
        case 2:
            delay = 20.;        // 20 sec
            break;
        case 3:
            delay = 30.;        // 30 sec
            break;
        case 4:
            delay = 45.;        // 45 sec
            break;
        case 5:
            delay = 60.;        // 1 min
            break;
        default:
            delay = 24.*60.*60.;    // 24 hours
            break;
    }
    
#if DEBUG && !TESTING
    // when debugging always use 10 sec delay for each retry
    delay = 10;
#endif
    
    // randomize the delay so as not to flood the server with requests at the same time in case of an outage
    
    // Ref: http://nshipster.com/random/
    // random int between 1..10
    NSUInteger r = arc4random_uniform(10) + 1;
    
    // add up to 10% random delay
    delay += 0.01 * r * delay;
    
    DLog(@"retry attempt = %d, delay = %f", (int)attempt, delay);
    
    return delay;
}

+ (NSTimeInterval)durationExponentialDelayForRetry:(NSInteger)attempt
{
    // delay in seconds
    NSTimeInterval delay = 0;
    
    switch( attempt ) {
        case 0:
            delay = 0;              // now
            break;
        case 1:
            delay = 30.;            // 30 sec
            break;
        case 2:
            delay = 90.;            // 90 sec
            break;
        case 3:
            delay = 10.*60.;        // 10 min
            break;
        case 4:
            delay = 60.*60.;        // 1 hour
            break;
        case 5:
            delay = 6.*60.*60.;     // 6 hours
            break;
        case 6:
        default:
            delay = 24.*60.*60.;    // 24 hours
    }
    
#if DEBUG
    // when debugging always use 10 sec delay for each retry
    delay = 10;
#endif
    
    // randomize the delay so as not to flood the server with requests at the same time in case of an outage
    
    // Ref: http://nshipster.com/random/
    // random int between 1..10
    NSUInteger r = arc4random_uniform(10) + 1;
    
    // add up to 10% random delay
    delay += 0.01 * r * delay;
    
    DLog(@"retry attempt = %d, exponential delay = %f", (int)attempt, delay);
    
    return delay;
}

+ (UIImage*)closeButtonImage
{
    DLLog(@"closeButtonImage");
    
    NSData *data = [TuneUtils tuneDataFromBase64String:closeImageString()];
    return [UIImage imageWithData:data];
}

/*!
 Url-encodes the input string if it's not nil or NULL, otherwise returns an empty string.
 */
+ (NSString *)urlEncode:(id)value
{
    NSString *encodedString = nil;
    
    if( nil == value || (id)[NSNull null] == value )
        encodedString = TUNE_STRING_EMPTY;
    else if( [value isKindOfClass:[NSNumber class]] )
        encodedString = [(NSNumber*)value stringValue];
    else if( [value isKindOfClass:[NSDate class]] )
        encodedString = [NSString stringWithFormat:@"%ld", (long)round( [(NSDate *)value timeIntervalSince1970] )];
    else if( [value isKindOfClass:[NSString class]] )
        encodedString = [(NSString*)value urlEncodeUsingEncoding:NSUTF8StringEncoding];
    
    return encodedString;
}

@end
