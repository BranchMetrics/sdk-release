//
//  TuneAdDownloadHelper.m
//  Tune
//
//  Created by Harshal Ogale on 5/13/14.
//  Copyright (c) 2014 Tune Inc. All rights reserved.
//

#import "TuneAdDownloadHelper.h"

#import "../TuneAdView.h"
#import "../TuneBanner.h"
#import "../TuneInterstitial.h"
#import "../TuneAdMetadata.h"

#import "../Common/Tune_internal.h"
#import "../Common/TuneKeyStrings.h"
#import "../Common/TuneSettings.h"
#import "../Common/TuneTracker.h"
#import "../Common/TuneUtils.h"

#import "TuneAd.h"
#import "TuneAdKeyStrings.h"
#import "TuneAdParams.h"
#import "TuneAdUtils.h"


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
    
    // the retry count of ad download network requests due to failed requests
    NSUInteger retryCount;
}

@property (nonatomic, strong) NSURLConnection *connection;

@property (nonatomic, copy) NSString *requestUrl;
@property (nonatomic, copy) NSString *requestData;

@property (nonatomic, copy) NSString *placement;
@property (nonatomic, strong) TuneAdMetadata *metadata;
@property (nonatomic, assign) TuneAdType adType;
@property (nonatomic, assign) TuneAdOrientation orientations;

@property (nonatomic, copy) void (^requestHandler) (NSString *url, NSString *data);
@property (nonatomic, copy) void (^responseCompletionHandler) (TuneAd *ad, NSError *error);

@end


@implementation TuneAdDownloadHelper

@synthesize delegate, fetchAdInProgress;

+(void)initialize
{
    dictErrorCodes = @{
                       TUNE_AD_KEY_TuneAdServerErrorNoMatchingAdGroups   : @(TuneAdErrorNoMatchingAds),
                       TUNE_AD_KEY_TuneAdServerErrorNoMatchingPlacement  : @(TuneAdErrorNoMatchingAds),
                       TUNE_AD_KEY_TuneAdServerErrorNoSuitableAds        : @(TuneAdErrorNoMatchingAds),
                       TUNE_AD_KEY_TuneAdServerErrorNoMatchingSites      : @(TuneAdErrorNoMatchingSites),
                       TUNE_AD_KEY_TuneAdServerErrorUnknownAdvertiser    : @(TuneAdErrorUnknownAdvertiser)
                       };
}

- (instancetype)initWithAdType:(TuneAdType)ty
                     placement:(NSString *)pl
                      metadata:(TuneAdMetadata *)met
                  orientations:(TuneAdOrientation)or
                requestHandler:(void (^)(NSString *url, NSString *data))rh
             completionHandler:(void (^)(TuneAd *ad, NSError *error))ch
{
    self = [super init];
    if (self) {
        _adType = ty;
        _metadata = [met copy];
        _placement = [pl copy];
        _orientations = or;
        _requestHandler = [rh copy];
        _responseCompletionHandler = [ch copy];
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
    DLog(@"TADH: fireUrl:withData:");
    [self cancel];
    
    self.requestUrl = urlString;
    self.requestData = strData;
    
    [self fireUrl];
    
    [delegate downloadStartedForAdWithUrl:self.requestUrl data:self.requestData];
}

- (void)fireUrl
{
    DLog(@"TADH: fireUrl");
    
    responseData = [NSMutableData data];
    
    NSURL *url = [NSURL URLWithString:self.requestUrl];
    NSData *postData = [self.requestData dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:TUNE_HTTP_METHOD_POST];
    [request setValue:TUNE_HTTP_CONTENT_TYPE_APPLICATION_JSON forHTTPHeaderField:TUNE_HTTP_CONTENT_TYPE];
    [request setHTTPBody:postData];
    [request setValue:[@(postData.length) stringValue] forHTTPHeaderField:TUNE_HTTP_CONTENT_LENGTH];
    
    self.connection = [NSURLConnection connectionWithRequest:request
                                                    delegate:self];
    
    DLog(@"TADH: fireUrl: connection = %p", self.connection);
}

- (void)cancel
{
    if (self.connection)
    {
        DLog(@"TADH: canceling connection: %p, fetchAdInProgress = %d", self.connection, self.fetchAdInProgress);
        [self.connection cancel];
        self.connection = nil;
    }
}

#pragma mark - NSURLConnectionDelegate Methods

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    DLog(@"TADH: conn failed: error = %@", error);
    
    self.fetchAdInProgress = NO;
    
    [self.connection cancel];
    self.connection = nil;
    
    NSError *networkError = [NSError errorWithDomain:error.domain code:error.code userInfo:error.userInfo];
    
    if(TuneAdTypeInterstitial == self.adType)
    {
        [self retryAdDownload:networkError];
    }
    else
    {
        DLog(@"TADH: conn failed: calling error handler: %@", self.responseCompletionHandler);
        
        if(self.responseCompletionHandler)
        {
            self.responseCompletionHandler(nil, networkError);
            DLog(@"TADH: conn failed: finished error handler");
        }
        
        [delegate downloadFailedWithError:networkError];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    DLog(@"TADH: didReceiveData");
    DLLog(@"TADH: didReceiveData: %@", [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]);
    
    [responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    DLog(@"TADH: conn finished");
    //DLog(@"TADH: conn finished: response = %@", [[NSString alloc] initWithData:responseData encoding:NSASCIIStringEncoding]);
    //DLog(@"TADH: delegate = %@", delegate);
    
    self.fetchAdInProgress = NO;
    
    // extract the json object from the downloaded data
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    
    DLog(@"TADH: conn finished: dict = %p", dict);
    
    // create a new ad object by parsing the json string
    TuneAd* ad = [TuneAd ad:self.adType placement:self.placement metadata:self.metadata orientations:self.orientations fromDictionary:dict];
    
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
    
    DLog(@"TADH: conn finished: ad = %p", ad);
    
    // if next ad was successfully downloaded
    if(ad)
    {
        DLog(@"TADH: conn finished: ad successfully downloaded: calling completion handler: %p", self.responseCompletionHandler);
        
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
        BOOL isDebug = self.metadata ? self.metadata.debugMode : tuneParams.debugMode.boolValue;
        NSString *msgDescr = isDebug ? dict.description : msg;
        [errorDetails setValue:msgDescr forKey:NSLocalizedDescriptionKey];
        
        NSError *serverError = [NSError errorWithDomain:TUNE_AD_KEY_TuneAdErrorDomain code:errCode userInfo:errorDetails];
        
        if(self.responseCompletionHandler)
        {
            self.responseCompletionHandler(nil, serverError);
        }
        
        [delegate downloadFailedWithError:serverError];
        
        DLog(@"TADH: server error = %@", error);
        
        // Note: the request will not be retried
    }
    else
    {
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:TUNE_AD_KEY_TuneAdErrorUnknown forKey:NSLocalizedFailureReasonErrorKey];
        [errorDetails setValue:TUNE_AD_KEY_TuneAdErrorUnknown forKey:NSLocalizedDescriptionKey];
        
        NSError *unknownError = [NSError errorWithDomain:TUNE_AD_KEY_TuneAdErrorDomain code:TuneAdErrorUnknown userInfo:errorDetails];
        
        // only retry interstitial ad download, banner download will be auto retried at the next ad refresh cycyle
        if(TuneAdTypeInterstitial == self.adType)
        {
            DLog(@"TADH: calling retry");
            
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
    DLog(@"TADH: dealloc: self = %@", self);
    
    [self cancel];
}

#pragma mark - Fetch Ad Web Request

- (void)fetchAd
{
    DLog(@"TADH: fetchAd: network reachable = %d", [TuneUtils isNetworkReachable]);
    
    // cancel any existing ad fetch request
    [self cancel];
    
    self.fetchAdInProgress = YES;
    
    // construct the request json post data
    NSString *adRequestData = [TuneAdParams jsonForAdType:self.adType placement:self.placement metadata:self.metadata orientations:self.orientations];
    
    // fire the request
    NSString *adUrl = [TuneAdUtils tuneAdServerUrl:self.adType];
    [self fireUrl:adUrl withData:adRequestData];
    
    if(self.requestHandler)
    {
        self.requestHandler(adUrl, adRequestData);
    }
    
    [delegate downloadStartedForAdWithUrl:adUrl data:adRequestData];
}

#pragma mark - Network Request Retry Methods

/**
 Retries download request
 */
- (void)retryAdDownload:(NSError *)error
{
    DLog(@"TADH: retryCount = %td", retryCount);
    
    // do not fire a new request if the max retry count has been reached
    if(retryCount < TUNE_AD_MAX_AD_DOWNLOAD_RETRY_COUNT)
    {
        DLog(@"TADH: retry: network reachable = %d", [TuneUtils isNetworkReachable]);
        
        // if network is reachable
        if([TuneUtils isNetworkReachable])
        {
            [self fetchAd];
            
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
            
            if(self.completionHandler)
            {
                self.completionHandler(nil, unreachableError);
            }
            
            [delegate downloadFailedWithError:unreachableError];
        }
    }
    else
    {
        DLog(@"TADH: retryAdDownload max retries consumed: finished retries");
        
        if(self.completionHandler)
        {
            self.completionHandler(nil, error);
        }
        
        [delegate downloadFailedWithError:error];
    }
}

- (void)reset
{
    DLog(@"TADH: reset");
    
    [self cancel];
    
    fetchAdInProgress = NO;
    
    retryCount = 0;
}

+ (void)downloadAdForAdType:(TuneAdType)ty
                  placement:(NSString *)pl
                   metadata:(TuneAdMetadata *)met
               orientations:(TuneAdOrientation)ori
             requestHandler:(void (^)(NSString *url, NSString *data))rh
          completionHandler:(void (^)(TuneAd *ad, NSError *error))ch
{
    DLog(@"TADH: downloadAdForAdType: ch = %@, rh = %@, network reachable = %d", ch, rh, [TuneUtils isNetworkReachable]);
    
    if([TuneUtils isNetworkReachable])
    {
        TuneAdDownloadHelper *dh = [[TuneAdDownloadHelper alloc] initWithAdType:ty placement:pl metadata:met orientations:ori requestHandler:rh completionHandler:ch];
        DLog(@"TADH: downloadAdForAdType: dh = %@", dh);
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
