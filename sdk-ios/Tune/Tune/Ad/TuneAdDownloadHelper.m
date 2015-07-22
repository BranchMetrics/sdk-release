//
//  TuneDownloadHelper.m
//  Tune
//
//  Created by Harshal Ogale on 5/13/14.
//  Copyright (c) 2014 Tune Inc. All rights reserved.
//

#import "TuneAdDownloadHelper.h"
#import "../Common/TuneUtils.h"
#import "../Common/TuneTracker.h"
#import "../Common/TuneSettings.h"
#import "../Common/Tune_internal.h"

@interface TuneAdDownloadHelper ()

@property (nonatomic, copy) void (^completionHandler) (TuneAd *ad, NSError *error);

@end

#if DEBUG
    #define DUMMY_ADS_IF_NOT_AVAILABLE 0
#endif

const NSUInteger TUNE_AD_MAX_AD_DOWNLOAD_RETRY_COUNT    = 5; // max number of retries when an ad download fails

static NSDictionary *dictErrorCodes;

@interface TuneAdDownloadHelper() <NSURLConnectionDelegate>
{
    NSMutableData *responseData;
    NSURLConnection *connection;
    
    NSString *requestUrl;
    NSString *requestData;
    
    // the retry count of ad download network requests due to failed requests
    NSUInteger retryCount;
    
    // retry timer
    NSTimer *retryTimer;
    
    NSString *placement;
    TuneAdMetadata *metadata;
    TuneAdType adType;
    TuneAdOrientation orientations;
}

@property (nonatomic, copy) void (^responseCompletionHandler) (TuneAd *ad, NSError *error);

@end

@implementation TuneAdDownloadHelper

@synthesize delegate, fetchAdInProgress;


+(void)initialize
{
    dictErrorCodes = @{
                       TUNE_AD_KEY_TuneAdServerErrorNoMatchingAdGroups   : @(TuneAdErrorNoMatchingAds),
                       TUNE_AD_KEY_TuneAdServerErrorNoSuitableAds        : @(TuneAdErrorNoMatchingAds),
                       TUNE_AD_KEY_TuneAdServerErrorNoMatchingSites      : @(TuneAdErrorNoMatchingSites),
                       TUNE_AD_KEY_TuneAdServerErrorUnknownAdvertiser    : @(TuneAdErrorUnknownAdvertiser)
                       };
}

- (instancetype)initWithAdType:(TuneAdType)ty
                     placement:(NSString *)pl
                      metadata:(TuneAdMetadata *)met
                  orientations:(TuneAdOrientation)or
             completionHandler:(void (^)(TuneAd *ad, NSError *error))ch
{
    self = [super init];
    if (self) {
        adType = ty;
        metadata = met;
        placement = pl;
        orientations = or;
        _responseCompletionHandler = ch;
    }
    return self;
}

/*!
 Fire a http POST request.
 @param urlString target url string
 @param strData json string
 */
- (void)fireUrl:(NSString *)urlString withData:(NSString *)strData
{
    [self cancel];
    
    requestUrl = [NSString stringWithString:urlString];
    requestData = [NSString stringWithString:strData];
    
    [self fireUrl];
    
    [delegate downloadStartedForAdWithUrl:requestUrl data:requestData];
}

- (void)fireUrl
{
    responseData = [NSMutableData data];
    
    NSURL *url = [NSURL URLWithString:requestUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    [request setHTTPMethod:TUNE_HTTP_METHOD_POST];
    [request setValue:TUNE_HTTP_CONTENT_TYPE_APPLICATION_JSON forHTTPHeaderField:TUNE_HTTP_CONTENT_TYPE];
    
    NSData *postData = [requestData dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:postData];
    [request setValue:[@(postData.length) stringValue] forHTTPHeaderField:TUNE_HTTP_CONTENT_LENGTH];
    
    //DLLog(@"url: %@, data: %@", url, requestData);
    
    connection = [NSURLConnection connectionWithRequest:request
                                               delegate:self];
}

- (void)cancel
{
    if (connection)
    {
        [connection cancel];
        connection = nil;
    }
}

#pragma mark - NSURLConnectionDelegate Methods

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    DLLog(@"error = %@", error);
    
    self.fetchAdInProgress = NO;
    
    [connection cancel];
    connection = nil;
    
    NSError *networkError = [NSError errorWithDomain:error.domain code:error.code userInfo:error.userInfo];
    
    if(TuneAdTypeInterstitial == adType)
    {
        [self retryAdDownload:networkError];
    }
    else
    {
        DLLog(@"TADH: conn failed: calling error handler: %@", self.responseCompletionHandler);
        
        if(self.responseCompletionHandler)
        {
            self.responseCompletionHandler(nil, networkError);
            DLLog(@"TADH: conn failed: finished error handler");
        }
        [delegate downloadFailedWithError:networkError];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    DLLog(@"DownloadHelper: didReceiveData: %@", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
    
    [responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    DLLog(@"response = %@", [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding]);
    //DLLog(@"delegate = %@", delegate);
    
    fetchAdInProgress = NO;
    
    // extract the json object from the downloaded data
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    
    //DLLog(@"dict = %@", dict);
    
    // create a new ad object by parsing the json string
    TuneAd* ad = [TuneAd ad:adType placement:placement metadata:metadata orientations:orientations fromDictionary:dict];
    
#if DUMMY_ADS_IF_NOT_AVAILABLE
    
    if(!ad)
    {
        static int dummyAdCount = 1;
        
        DLLog(@"dummy ad count = %d", (unsigned int)dummyAdCount);
        
        // dummy banner images
        NSString *dummyBP = @"http://dummyimage.com/768x66/771122/fff/&text=Atomic%20Tilt%250a768x66";
        NSString *dummyBL = @"http://dummyimage.com/1024x66/AA8811/fff/&text=Atomic%20Tilt%250a1024x66";
        NSString *dummyItunesB = @"http://itunes.apple.com/us/app/fairway/id428393447?mt=8";
        
        // dummy interstitial images
        NSString *dummyIP = @"http://dummyimage.com/768x1024/771122/fff/&text=Atomic%20Tilt%250a768x1024";
        NSString *dummyIL = @"http://dummyimage.com/1024x768/AA8811/fff/&text=Atomic%20Tilt%250a1024x768";
        NSString *dummyItunesI = @"http://itunes.apple.com/us/app/fairway/id428393447?mt=8";
        
        NSString *htmlTemplate = @"<!DOCTYPE html><html lang=\"en\"><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width\"></head><style>html,body,a{display:block;width:100%;height:100%;margin:0;padding:0}a{background:#123 url(/uploads/q4r3vigqa1yvi.jpeg) no-repeat center center;background-size:contain}</style><body><a id=\"a\" href=\"%@\"></a><script>(window.onresize=function(){document.getElementById('a').style.backgroundImage='url('+(window.innerWidth/window.innerHeight>1?'%@':'%@')+')'})();var l=new Image(),p=new Image();l.src='%@';p.src='%@';</script></body></html>";
        
        if (0 == dummyAdCount % 11)
        {
            ad = nil;
        }
        else
        {
            ad = [[TuneAd alloc] init];
            ad.type = adView.adType;
            ad.usesNativeCloseButton = adView.adType != TuneAdTypeBanner;
            ad.requestId = @"1234abcd";
            ad.color = @"#123";
            ad.duration = TUNE_AD_DEFAULT_BANNER_CYCLE_DURATION;
            
            if(adView.adType == TuneAdTypeBanner)
            {
                ad.html = [NSString stringWithFormat:htmlTemplate, dummyItunesB, dummyBL, dummyBP, dummyBP, dummyBL];
            }
            else
            {
                ad.html = [NSString stringWithFormat:htmlTemplate, dummyItunesI, dummyIL, dummyIP, dummyIP, dummyIL];
            }
            
            DLLog(@"dummy ad.html = %@", ad.html);
        }
        
        DLLog(@"dummy ad = %@", ad ? @"not nil" : @"nil");
        
        ++dummyAdCount;
    }
#endif
    
    // if next ad was successfully downloaded
    if(ad)
    {
        DLog(@"ad successfully downloaded");
        
        retryCount = 0;
        
        if(self.responseCompletionHandler)
        {
            self.responseCompletionHandler(ad, nil);
        }
        [delegate downloadFinishedWithAd:ad];
    }
    else if(dict && dict[TUNE_AD_KEY_ERROR])
    {
        retryCount = 0;
        
        NSString *msg = dict[TUNE_AD_KEY_ERROR];
        NSNumber *numErr = msg ? dictErrorCodes[msg] : nil;
        NSInteger errCode = numErr ? [numErr integerValue] : TuneAdErrorUnknown;
        
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:msg forKey:NSLocalizedFailureReasonErrorKey];

        // when debug mode is enabled, include the full error description
        TuneSettings *tuneParams = [[Tune sharedManager] parameters];
        BOOL isDebug = metadata ? metadata.debugMode : tuneParams.debugMode.boolValue;
        NSString *msgDescr = isDebug ? [NSString stringWithFormat:@"%@", dict] : msg;
        [errorDetails setValue:msgDescr forKey:NSLocalizedDescriptionKey];
        
        NSError *serverError = [NSError errorWithDomain:TUNE_AD_KEY_TuneAdErrorDomain code:errCode userInfo:errorDetails];
        
        
        if(self.responseCompletionHandler)
        {
            self.responseCompletionHandler(nil, serverError);
        }
        [delegate downloadFailedWithError:serverError];
        
        DLLog(@"server error = %@", error);
        
        // Note: the request will not be retried
    }
    else
    {
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:TUNE_AD_KEY_TuneAdErrorUnknown forKey:NSLocalizedFailureReasonErrorKey];
        [errorDetails setValue:TUNE_AD_KEY_TuneAdErrorUnknown forKey:NSLocalizedDescriptionKey];
        
        NSError *unknownError = [NSError errorWithDomain:TUNE_AD_KEY_TuneAdErrorDomain code:TuneAdErrorUnknown userInfo:errorDetails];
        
        if(TuneAdTypeInterstitial == adType)
        {
            DLLog(@"calling retry");
            
            [self retryAdDownload:unknownError];
        }
        else
        {
            retryCount = 0;
            
            if(self.responseCompletionHandler)
            {
                self.responseCompletionHandler(nil, unknownError);
            }
            
            [delegate downloadFailedWithError:unknownError];
        }
    }
}

#if DEBUG_AD_STAGING

// allow self-signed certificates for internal testing on Tune Staging server
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

#endif

#pragma mark - Dealloc

- (void)dealloc
{
    // empty
}

#pragma mark - Fetch Ad Web Request

- (BOOL)fetchAd
{
    DLog(@"fetchAd: network reachable = %d", [TuneUtils isNetworkReachable]);
    
    // cancel any existing ad fetch request
    [self cancel];
    
    // continue with the request if the network is reachable
    BOOL reachable = [TuneUtils isNetworkReachable];
    if(reachable)
    {
        fetchAdInProgress = YES;
        
        // construct the request json post data
        NSString *adRequestData = [TuneAdParams jsonForAdType:adType placement:placement metadata:metadata orientations:orientations];
        
        // fire the request
        NSString *adUrl = [TuneAdUtils tuneAdServerUrl:adType];
        [self fireUrl:adUrl withData:adRequestData];
    }
    
    return reachable;
}

#pragma mark - Network Request Retry Methods

/**
 Retries download request
 */
- (void)retryAdDownload:(NSError *)error
{
    DLLog(@"retryCount = %ld", (long)retryCount);
    
    // do not fire a new request if the max retry count has been reached
    if(retryCount < TUNE_AD_MAX_AD_DOWNLOAD_RETRY_COUNT)
    {
        DLLog(@"retry: network reachable = %d", [TuneUtils isNetworkReachable]);
        
        BOOL fired = [self fetchAd];
        
        // if network is reachable
        if(fired)
        {
            // increment the retry count by 1
            ++retryCount;
        }
        else
        {
            // the network is not reachable, do not retry anymore
            // also, send an error message to the delegate
            NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
            [errorDetails setValue:TUNE_AD_KEY_TuneAdErrorNetworkNotReachable forKey:NSLocalizedFailureReasonErrorKey];
            [errorDetails setValue:@"The network is currently unreachable." forKey:NSLocalizedDescriptionKey];
            NSError *unreachableError = [NSError errorWithDomain:TUNE_AD_KEY_TuneAdErrorDomain code:TuneAdErrorNetworkNotReachable userInfo:errorDetails];
            
            [delegate downloadFailedWithError:unreachableError];
            if(self.completionHandler)
            {
                self.completionHandler(nil, unreachableError);
            }
        }
    }
    else
    {
        DLLog(@"retryAdDownload max retries consumed: finished retries");
        
        [delegate downloadFailedWithError:error];
        if(self.completionHandler)
        {
            self.completionHandler(nil, error);
        }
    }
}

- (void)reset
{
    [self cancel];
    
    fetchAdInProgress = NO;
    
    retryCount = 0;
}

+ (void)downloadAdForAdType:(TuneAdType)ty
               orientations:(TuneAdOrientation)ori
                  placement:(NSString *)pl
                 adMetadata:(TuneAdMetadata *)met
          completionHandler:(void (^)(TuneAd *ad, NSError *error))ch
{
    DLLog(@"TADH: downloadAdForAdType: ch = %@, eh = %@", ch, eh);
    
    if([TuneUtils isNetworkReachable])
    {
        TuneAdDownloadHelper *dh = [[TuneAdDownloadHelper alloc] initWithAdType:ty placement:pl metadata:met orientations:ori completionHandler:ch];
        [dh fetchAd];
    }
    else
    {
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:TUNE_AD_KEY_TuneAdErrorNetworkNotReachable forKey:NSLocalizedFailureReasonErrorKey];
        [errorDetails setValue:@"The network is currently unreachable." forKey:NSLocalizedDescriptionKey];
        NSError *unreachableError = [NSError errorWithDomain:TUNE_AD_KEY_TuneAdErrorDomain code:TuneAdErrorNetworkNotReachable userInfo:errorDetails];
        
        ch(nil, unreachableError);
    }
}

@end
