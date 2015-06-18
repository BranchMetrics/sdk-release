//
//  MATDeferredDplinkr.m
//  MobileAppTracker
//
//  Created by John Bender on 12/17/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import "MATDeferredDplinkr.h"
#import "MATKeyStrings.h"
#import "MATUtils.h"
#import "MATUserAgentCollector.h"
#import "NSString+MATURLEncoding.h"


@interface MATDeferredDplinkr()

@property (nonatomic, strong) NSOperationQueue *deeplinkOpQueue;
@property (nonatomic, copy) NSString *advertiserId;
@property (nonatomic, copy) NSString *conversionKey;
@property (nonatomic, assign) id<MobileAppTrackerDelegate> delegate;
@property (nonatomic, copy) NSString *bundleId;
@property (nonatomic, copy) NSString *ifa;
@property (nonatomic, assign) BOOL adTrackingEnabled;

@end


static MATDeferredDplinkr *dplinkr;


@implementation MATDeferredDplinkr

- (instancetype)init
{
    if( self = [super init] ) {
        self.deeplinkOpQueue = [NSOperationQueue new];
        self.bundleId = [MATUtils bundleId];
    }
    return self;
}

+ (void)initialize
{
    dplinkr = [MATDeferredDplinkr new];
}

+ (void)setAdvertiserId:(NSString*)advertiserId conversionKey:(NSString*)conversionKey
{
    dplinkr.advertiserId = advertiserId;
    dplinkr.conversionKey = conversionKey;
}

+ (void)setDelegate:(id<MobileAppTrackerDelegate>)matDelegate
{
    dplinkr.delegate = matDelegate;
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
        [MATUtils userDefaultValueforKey:MAT_KEY_DEEPLINK_CHECKED] != nil )
        return;
    
    // persist state so deeplink isn't requested twice
    [MATUtils setUserDefaultValue:@YES forKey:MAT_KEY_DEEPLINK_CHECKED];
    
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"https://%@.%@/%@?platform=ios",
                                  dplinkr.advertiserId,
                                  MAT_SERVER_DOMAIN_DEEPLINK,
                                  MAT_SERVER_PATH_DEEPLINK];
    
    [MATUtils addUrlQueryParamValue:dplinkr.advertiserId                forKey:MAT_KEY_ADVERTISER_ID            queryParams:urlString];
    [MATUtils addUrlQueryParamValue:MATVERSION                          forKey:MAT_KEY_VER                      queryParams:urlString];
    [MATUtils addUrlQueryParamValue:dplinkr.bundleId                    forKey:MAT_KEY_PACKAGE_NAME             queryParams:urlString];
    [MATUtils addUrlQueryParamValue:dplinkr.ifa                         forKey:MAT_KEY_IOS_IFA_DEEPLINK         queryParams:urlString];
    [MATUtils addUrlQueryParamValue:@(dplinkr.adTrackingEnabled)        forKey:MAT_KEY_IOS_AD_TRACKING          queryParams:urlString];
    [MATUtils addUrlQueryParamValue:[MATUserAgentCollector userAgent]   forKey:MAT_KEY_CONVERSION_USER_AGENT    queryParams:urlString];
    
    DLog( @"deeplink request: %@", urlString );
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:timeout];
    [request addValue:dplinkr.conversionKey forHTTPHeaderField:@"X-MAT-Key"];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:dplinkr.deeplinkOpQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        if( !connectionError ) {
            NSString *link = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            DLog( @"deeplink response: [%d] %@", (int)[(NSHTTPURLResponse*)response statusCode], link );
            
            if(200 == (int)[(NSHTTPURLResponse*)response statusCode])
            {
                __block NSURL *deeplink = [NSURL URLWithString:link];
                if( deeplink ) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        
                        // let the AppDelegate handle
                        [[[UIApplication sharedApplication] delegate] application:[UIApplication sharedApplication]
                                                                          openURL:deeplink
                                                                sourceApplication:[MATUtils bundleId]
                                                                       annotation:nil];
                        
                        if ([dplinkr.delegate respondsToSelector:@selector(mobileAppTrackerDidReceiveDeeplink:)])
                        {
                            [dplinkr.delegate mobileAppTrackerDidReceiveDeeplink:deeplink.absoluteString];
                        }
                    }];
                }
                else DLog( @"response was not a valid URL: %@", link );
            }
            else DLog( @"invalid http status code %d, response: %@", (int)[(NSHTTPURLResponse*)response statusCode], link );
        }
        else DLog( @"connection error: %@", connectionError );
    }];
}

@end
