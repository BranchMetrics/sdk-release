//
//  TuneDeferredDplinkr.m
//  Tune
//
//  Created by John Bender on 12/17/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import "TuneDeferredDplinkr.h"

#import "../Tune.h"

#import "TuneIfa.h"
#import "TuneKeyStrings.h"
#import "TuneUserAgentCollector.h"
#import "TuneUtils.h"

@interface TuneDeferredDplinkr()

@property (nonatomic, strong) NSOperationQueue *deeplinkOpQueue;
@property (nonatomic, copy) NSString *advertiserId;
@property (nonatomic, copy) NSString *conversionKey;
@property (nonatomic, assign) id<TuneDelegate> delegate;
@property (nonatomic, assign) id<TuneDelegate> deeplinkDelegate;
@property (nonatomic, copy) NSString *bundleId;
@property (nonatomic, copy) NSString *ifa;
@property (nonatomic, assign) BOOL adTrackingEnabled;
@property (nonatomic, copy) void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *connectionError);

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
    TuneIfa *ifaInfo = [TuneIfa ifaInfo];
    if(ifaInfo)
    {
        dplinkr.ifa = ifaInfo.ifa;
        dplinkr.adTrackingEnabled = ifaInfo.trackingEnabled;
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

+ (void)setIfa:(NSString*)appleAdvertisingIdentifier trackingEnabled:(BOOL)adTrackingEnabled
{
    dplinkr.ifa = appleAdvertisingIdentifier;
    dplinkr.adTrackingEnabled = adTrackingEnabled;
}

+ (void)checkForDeferredDeeplink:(id<TuneDelegate>)delegate
{
    if( dplinkr.advertiserId == nil ||
        dplinkr.ifa == nil ||
        [TuneUtils userDefaultValueforKey:TUNE_KEY_DEEPLINK_CHECKED] != nil )
    {
        return;
    }
    
    dplinkr.deeplinkDelegate = delegate;
    
    // persist state so deeplink isn't requested twice
    [TuneUtils setUserDefaultValue:@YES forKey:TUNE_KEY_DEEPLINK_CHECKED];
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@://%@.%@/%@?platform=ios",
                                  TUNE_KEY_HTTPS,
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
    
    dplinkr.completionHandler = ^(NSData *data, NSURLResponse *response, NSError *connectionError) {
        id<TuneDelegate> deepDelegate = dplinkr.deeplinkDelegate ?: dplinkr.delegate;
        
        NSError *error = nil;
        
        if( !connectionError ) {
            
            NSString *link = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            DLog( @"deeplink response: [%d] %@", (int)[(NSHTTPURLResponse*)response statusCode], link );
            
            if(200 == (int)[(NSHTTPURLResponse*)response statusCode])
            {
                __block NSURL *deeplink = [NSURL URLWithString:link];
                
                if( deeplink )
                {
                    // check and call success delegate callback
                    if ([deepDelegate respondsToSelector:@selector(tuneDidReceiveDeeplink:)])
                    {
                        [deepDelegate tuneDidReceiveDeeplink:deeplink.absoluteString];
                    }
                }
                else
                {
                    DLog( @"response was not a valid URL: %@", link );
                    
                    error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                                code:TUNE_DEEPLINK_MALFORMED_ERROR_CODE
                                            userInfo:@{NSLocalizedDescriptionKey:@"Malformed deferred deeplink", TUNE_KEY_REQUEST_URL:response.URL.absoluteString}];
                }
            }
            else
            {
                DLog( @"invalid http status code %d, response: %@", (int)[(NSHTTPURLResponse*)response statusCode], link );
                
                error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                            code:[(NSHTTPURLResponse*)response statusCode]
                                        userInfo:@{NSLocalizedDescriptionKey:@"Deferred deeplink not found", TUNE_KEY_REQUEST_URL:response.URL.absoluteString}];
            }
        }
        else
        {
            error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN
                                        code:TUNE_DEEPLINK_NETWORK_ERROR_CODE
                                    userInfo:@{NSLocalizedDescriptionKey:@"Network error when retrieving deferred deeplink", NSUnderlyingErrorKey:connectionError}];
        }
        
        if(error)
        {
            DLog( @"error: %@", error );

            // check and call error delegate callback
            if ([deepDelegate respondsToSelector:@selector(tuneDidFailDeeplinkWithError:)])
            {
                [deepDelegate tuneDidFailDeeplinkWithError:error];
            }
        }
    };

    if( [NSURLSession class] ) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        [[session dataTaskWithRequest:request completionHandler:dplinkr.completionHandler] resume];
    }
    else {
        SEL ector = @selector(sendAsynchronousRequest:queue:completionHandler:);
        if( [NSURLConnection respondsToSelector:ector] ) {
            // iOS 6
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[NSURLConnection methodSignatureForSelector:ector]];
            [invocation setTarget:[NSURLConnection class]];
            [invocation setSelector:ector];
            [invocation setArgument:&request atIndex:2];
            NSOperationQueue *q = dplinkr.deeplinkOpQueue;
            [invocation setArgument:&q atIndex:3];
            void (^connectionCompletionHandler)(NSURLResponse *response, NSData *data, NSError *connectionError) =
            ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                dplinkr.completionHandler( data, response, connectionError );
            };
            [invocation setArgument:&connectionCompletionHandler atIndex:4];
            [invocation invoke];
        }
    }
}

@end
