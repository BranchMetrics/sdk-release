//
//  TuneDeferredDplinkr.m
//  Tune
//
//  Created by John Bender on 12/17/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import "TuneDeferredDplinkr.h"
#import "TuneKeyStrings.h"
#import "TuneUtils.h"
#import "TuneUserAgentCollector.h"
#import "NSString+TuneURLEncoding.h"


@interface TuneDeferredDplinkr()

@property (nonatomic, strong) NSOperationQueue *deeplinkOpQueue;
@property (nonatomic, copy) NSString *advertiserId;
@property (nonatomic, copy) NSString *conversionKey;
@property (nonatomic, assign) id<TuneDelegate> delegate;
@property (nonatomic, copy) NSString *bundleId;
@property (nonatomic, copy) NSString *ifa;
@property (nonatomic, assign) BOOL adTrackingEnabled;

@end

static const NSInteger TUNE_DEEPLINK_MALFORMED_ERROR_CODE = 1501;
static const NSInteger TUNE_DEEPLINK_NETWORK_ERROR_CODE = 1503;

static const NSTimeInterval TUNE_NSURLCONNECTION_DEFAULT_TIMEOUT = 60.;

static TuneDeferredDplinkr *dplinkr;


@implementation TuneDeferredDplinkr

- (instancetype)init
{
    if( self = [super init] ) {
        self.deeplinkOpQueue = [NSOperationQueue new];
        self.bundleId = [TuneUtils bundleId];
    }
    return self;
}

+ (void)initialize
{
    dplinkr = [TuneDeferredDplinkr new];
    
    // collect IFA if accessible
    NSArray *ifaInfo = [TuneUtils ifaInfo];
    if(ifaInfo && 2 == ifaInfo.count)
    {
        dplinkr.ifa = [ifaInfo[0] UUIDString];
        dplinkr.adTrackingEnabled = [ifaInfo[1] boolValue];
    }
}

+ (void)setAdvertiserId:(NSString*)advertiserId conversionKey:(NSString*)conversionKey
{
    dplinkr.advertiserId = advertiserId;
    dplinkr.conversionKey = conversionKey;
}

+ (void)setDelegate:(id<TuneDelegate>)tuneDelegate
{
    dplinkr.delegate = tuneDelegate;
}

+ (void)setPackageName:(NSString*)packageName
{
    dplinkr.bundleId = packageName;
}

+ (void)setIFA:(NSString*)appleAdvertisingIdentifier trackingEnabled:(BOOL)adTrackingEnabled
{
    dplinkr.ifa = appleAdvertisingIdentifier;
    dplinkr.adTrackingEnabled = adTrackingEnabled;
}

+ (void)checkForDeferredDeeplinkWithTimeout:(NSTimeInterval)timeout
{
    if( dplinkr.advertiserId == nil ||
        dplinkr.ifa == nil ||
        [TuneUtils userDefaultValueforKey:TUNE_KEY_DEEPLINK_CHECKED] != nil )
        return;
    
    // persist state so deeplink isn't requested twice
    [TuneUtils setUserDefaultValue:@YES forKey:TUNE_KEY_DEEPLINK_CHECKED];
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"https://%@.%@/%@?platform=ios",
                                  dplinkr.advertiserId,
                                  TUNE_SERVER_DOMAIN_DEEPLINK,
                                  TUNE_SERVER_PATH_DEEPLINK];
    
    [TuneUtils addUrlQueryParamValue:dplinkr.advertiserId                forKey:TUNE_KEY_ADVERTISER_ID            queryParams:urlString];
    [TuneUtils addUrlQueryParamValue:TUNEVERSION                         forKey:TUNE_KEY_VER                      queryParams:urlString];
    [TuneUtils addUrlQueryParamValue:dplinkr.bundleId                    forKey:TUNE_KEY_PACKAGE_NAME             queryParams:urlString];
    [TuneUtils addUrlQueryParamValue:dplinkr.ifa                         forKey:TUNE_KEY_IOS_IFA_DEEPLINK         queryParams:urlString];
    [TuneUtils addUrlQueryParamValue:@(dplinkr.adTrackingEnabled)        forKey:TUNE_KEY_IOS_AD_TRACKING          queryParams:urlString];
    [TuneUtils addUrlQueryParamValue:[TuneUserAgentCollector userAgent]  forKey:TUNE_KEY_CONVERSION_USER_AGENT    queryParams:urlString];
    
    DLog( @"deeplink request: %@", urlString );
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:TUNE_NSURLCONNECTION_DEFAULT_TIMEOUT];
    
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    [request addValue:dplinkr.conversionKey forHTTPHeaderField:@"X-MAT-Key"];
    
    NSDate *start = [NSDate date];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:dplinkr.deeplinkOpQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        NSError *error = nil;
        
        if( !connectionError ) {
            
            NSString *link = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            DLog( @"deeplink response: [%d] %@", (int)[(NSHTTPURLResponse*)response statusCode], link );
            
            if(200 == (int)[(NSHTTPURLResponse*)response statusCode])
            {
                __block NSURL *deeplink = [NSURL URLWithString:link];
                
                if( deeplink )
                {
                    NSDate *end = [NSDate date];
                    NSTimeInterval diff = [end timeIntervalSinceDate:start];
                    BOOL didTimeout = diff - timeout > 0;
                    
                    if(!didTimeout)
                    {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            
                            // let the AppDelegate handle
                            [[[UIApplication sharedApplication] delegate] application:[UIApplication sharedApplication]
                                                                              openURL:deeplink
                                                                    sourceApplication:[TuneUtils bundleId]
                                                                           annotation:nil];
                        }];
                    }
                    
                    // check and call success delegate callback
                    if ([dplinkr.delegate respondsToSelector:@selector(tuneDidReceiveDeeplink:didTimeout:)])
                    {
                        [dplinkr.delegate tuneDidReceiveDeeplink:deeplink.absoluteString didTimeout:didTimeout];
                    }
                }
                else
                {
                    DLog( @"response was not a valid URL: %@", link );
                    
                    error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                                code:TUNE_DEEPLINK_MALFORMED_ERROR_CODE
                                            userInfo:@{NSLocalizedDescriptionKey:@"Malformed deferred deeplink", TUNE_KEY_REQUEST_URL:urlString}];
                }
            }
            else
            {
                DLog( @"invalid http status code %d, response: %@", (int)[(NSHTTPURLResponse*)response statusCode], link );
                
                error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                            code:[(NSHTTPURLResponse*)response statusCode]
                                        userInfo:@{NSLocalizedDescriptionKey:@"Deferred deeplink not found", TUNE_KEY_REQUEST_URL:urlString}];
            }
        }
        else
        {
            error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                        code:TUNE_DEEPLINK_NETWORK_ERROR_CODE
                                    userInfo:@{NSLocalizedDescriptionKey:@"Network error when retrieving deferred deeplink", NSUnderlyingErrorKey:connectionError, TUNE_KEY_REQUEST_URL:urlString}];
        }
        
        if(error)
        {
            DLog( @"error: %@", error );

            // check and call error delegate callback
            if ([dplinkr.delegate respondsToSelector:@selector(tuneDidFailDeeplinkWithError:)])
            {
                [dplinkr.delegate tuneDidFailDeeplinkWithError:error];
            }
        }
    }];
}

@end
