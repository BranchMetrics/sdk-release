//
//  TuneAdNetworkHelper.m
//  Tune
//
//  Created by Harshal Ogale on 6/6/14.
//  Copyright (c) 2014 Tune Inc. All rights reserved.
//

#import "TuneAdNetworkHelper.h"

#import "../TuneAdMetadata.h"

#import "../Common/TuneKeyStrings.h"

#import "TuneAd.h"
#import "TuneAdDownloadHelper.h"
#import "TuneAdParams.h"


@interface TuneAdNetworkHelper ()
{
    NSMutableData *responseData;
    NSURLConnection *connection;
}
@end


@implementation TuneAdNetworkHelper

+ (void)fireUrl:(NSString *)urlString ad:(TuneAd *)ad
{
    TuneAdNetworkHelper *nh = [TuneAdNetworkHelper new];
    [nh fireUrl:urlString adType:ad.type placement:ad.placement metadata:ad.metadata orientations:ad.orientations ad:ad];
}

- (void)fireUrl:(NSString *)urlString adType:(TuneAdType)adType placement:(NSString *)placement metadata:(TuneAdMetadata *)metadata orientations:(TuneAdOrientation)orientations ad:(TuneAd *)ad
{
    [self cancel];
    
    responseData = [NSMutableData data];
    
    // construct the request json post data
    NSString *paramData = [TuneAdParams jsonForAdType:adType placement:placement metadata:metadata orientations:orientations ad:ad];
    
    DLLog(@"TuneAdsNetworkHelper: url: %@, data: %@", urlString, paramData);
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:TUNE_HTTP_METHOD_POST];
    [request setValue:TUNE_HTTP_CONTENT_TYPE_APPLICATION_JSON forHTTPHeaderField:TUNE_HTTP_CONTENT_TYPE];
    
    NSData *postData = [paramData dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:postData];
    [request setValue:[@(postData.length) stringValue] forHTTPHeaderField:TUNE_HTTP_CONTENT_LENGTH];
    
    connection = [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)cancel
{
    if(connection)
    {
        [connection cancel];
        connection = nil;
    }
}

- (void)dealloc
{
    [self cancel];
}

#pragma mark - NSURLConnectionDelegate Methods

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
    DLLog(@"TuneAdsNetworkHelper: connection:didFailWithError: %@", error);
    
    [conn cancel];
    conn = nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    DLLog(@"TuneAdsNetworkHelper: didReceiveData: size = %lu, %@", (unsigned long)data.length, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    
    [responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    DLLog(@"TuneAdsNetworkHelper: connectionDidFinishLoading: %@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
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

@end
