//
//  TuneApi.m
//  Tune
//
//  Created by Kevin Jenkins on 4/11/13.
//
//

#import "TuneApi.h"
#import "TuneConfiguration.h"
#import "TuneDeviceDetails.h"
#import "TuneDeviceUtils.h"
#import "TuneHttpUtils.h"
#import "TuneJSONUtils.h"
#import "TuneManager.h"
#import "TuneDeviceDetails.h"
#import "TuneSkyhookCenter.h"
#import "TuneUserProfile.h"
#import "TuneUtils.h"

NSString *const TuneApiConfigEndpoint                 = @"/sdk_api/{api_version}/apps/{app_id}/configuration";
NSString *const TuneApiSyncSDKEndpoint                = @"/sdk_api/{api_version}/apps/{app_id}/sync";
NSString *const TuneApiPlaylistEndpoint               = @"/sdk_api/{api_version}/apps/{app_id}/devices/{device_id}/playlist";
NSString *const TuneApiConnectedPlaylistEndpoint      = @"/sdk_api/{api_version}/apps/{app_id}/devices/{device_id}/connected_playlist";
NSString *const TuneApiDiscoveryModeEndpoint          = @"/sdk_api/{api_version}/apps/{app_id}/devices/{device_id}/discovery";
NSString *const TuneApiConnectEndpoint                = @"/sdk_api/{api_version}/apps/{app_id}/devices/{device_id}/connect";
NSString *const TuneApiDisconnectEndpoint             = @"/sdk_api/{api_version}/apps/{app_id}/devices/{device_id}/disconnect";
NSString *const TuneApiGeocodeEndpoint                = @"/sdk_api/{api_version}/geoip/location";

NSString *const TuneApiVersionKey  = @"api_version";
NSString *const TuneApiAppIdKey    = @"app_id";
NSString *const TuneApiDeviceIdKey = @"device_id";

@implementation TuneApi

#pragma mark - GET Requests

+ (TuneHttpRequest *)getConfigurationRequest {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    
    if ([profile hashedAppId]) {
        TuneHttpRequest *request = [[TuneHttpRequest alloc] init];
        [request setEndpoint:TuneApiConfigEndpoint];
        [request setHTTPMethod:TuneHttpRequestMethodTypeGet];
        [request addValue:TuneHttpRequestHeaderJSON forHTTPHeaderField:TuneHttpRequestHeaderAccept];
        
        @try {
            [request setEndpointArguments:[TuneApi buildDefaultEndpointArguments]];
        } @catch (NSException *exception) {
            ErrorLog(@"Error building configuration request %@", exception);
            return nil;
        }

        [request setParameters:@{@"osVersion":[TuneDeviceUtils artisanIOSVersionString],
                                 @"appVersion":[TuneUtils objectOrNull:profile.appVersion],
                                 @"sdkVersion":[TuneUtils objectOrNull:profile.sdkVersion],
                                 @"matId":[TuneUtils objectOrNull:profile.tuneId],
                                 @"IFA":[TuneUtils objectOrNull:profile.appleAdvertisingIdentifier]}];
        return request;
    } else {
        return nil;
    }
}

+ (TuneHttpRequest *)getPlaylistRequest {
    TuneHttpRequest *request = [[TuneHttpRequest alloc] init];
    [request setEndpoint:TuneApiPlaylistEndpoint];
    [request setHTTPMethod:TuneHttpRequestMethodTypeGet];
    [request addValue:TuneHttpRequestHeaderJSON forHTTPHeaderField:TuneHttpRequestHeaderAccept];
    [request setEndpointArguments:[TuneApi buildDefaultEndpointArguments]];

    return request;
}

+ (TuneHttpRequest *)getConnectedPlaylistRequest {
    TuneHttpRequest *request = [[TuneHttpRequest alloc] init];
    [request setEndpoint:TuneApiConnectedPlaylistEndpoint];
    [request setHTTPMethod:TuneHttpRequestMethodTypeGet];
    [request addValue:TuneHttpRequestHeaderJSON forHTTPHeaderField:TuneHttpRequestHeaderAccept];
    [request setEndpointArguments:[TuneApi buildDefaultEndpointArguments]];
    
    return request;
}

+ (TuneHttpRequest *)getGeocodeRequest {
    TuneHttpRequest *request = [[TuneHttpRequest alloc] init];
    [request setEndpoint:TuneApiGeocodeEndpoint];
    [request setHTTPMethod:TuneHttpRequestMethodTypeGet];
    [request addValue:TuneHttpRequestHeaderJSON forHTTPHeaderField:TuneHttpRequestHeaderAccept];
    return request;
}

#pragma mark - POST Requests

+ (TuneHttpRequest *)getSyncSDKRequest:(NSDictionary *)toSync {
    TuneHttpRequest *request = [[TuneHttpRequest alloc] init];
    [request setDomain:[TuneManager currentManager].configuration.connectedModeHostPort];
    [request setEndpoint:TuneApiSyncSDKEndpoint];
    [request setHTTPMethod:TuneHttpRequestMethodTypePost];
    [request setValue:TuneHttpRequestHeaderJSON forHTTPHeaderField:TuneHttpRequestHeaderContentType];
    [request setValue:TuneHttpRequestHeaderJSON forHTTPHeaderField:TuneHttpRequestHeaderAccept];
    [request setBodyOverride: NO];
    [request setEndpointArguments:[TuneApi buildDefaultEndpointArguments]];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:toSync options:0 error:NULL];
    [request setHTTPBody:jsonData];

    return request;
}

+ (TuneHttpRequest *)getDiscoverEventRequest:(NSDictionary *)eventDictionary {
    TuneHttpRequest *request = [[TuneHttpRequest alloc] init];
    request.bodyOverride = NO;
    [request setDomain:[TuneManager currentManager].configuration.connectedModeHostPort];
    [request setEndpoint:TuneApiDiscoveryModeEndpoint];
    [request setTimeoutInterval:[@20 doubleValue]];
    [request setHTTPMethod:TuneHttpRequestMethodTypePost];
    [request setValue:TuneHttpRequestHeaderJSON forHTTPHeaderField:TuneHttpRequestHeaderAccept];
    [request setValue:TuneHttpRequestHeaderJSON forHTTPHeaderField:TuneHttpRequestHeaderContentType];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:eventDictionary options:0 error:NULL];
    [request setHTTPBody:jsonData];
    [request setValue:[NSString stringWithFormat:@"%lu", (long)[jsonData length]]
                              forHTTPHeaderField:TuneHttpRequestHeaderContentLength];
    
    NSDictionary *endpointArgs = [TuneApi buildDefaultEndpointArguments];
    [request setEndpointArguments:endpointArgs];
    
    return request;
}

+ (TuneHttpRequest *)getConnectDeviceRequest {
    TuneHttpRequest *request = [[TuneHttpRequest alloc] init];
    [request setDomain:[TuneManager currentManager].configuration.connectedModeHostPort];
    [request setEndpoint:TuneApiConnectEndpoint];
    [request setHTTPMethod:TuneHttpRequestMethodTypePost];
    [request setValue:TuneHttpRequestHeaderJSON forHTTPHeaderField:TuneHttpRequestHeaderAccept];
    [request setValue:TuneHttpRequestHeaderJSON forHTTPHeaderField:TuneHttpRequestHeaderContentType];
    
    NSDictionary *endpointArgs = [TuneApi buildDefaultEndpointArguments];
    [request setEndpointArguments:endpointArgs];
    
    return request;
}

+ (TuneHttpRequest *)getDisconnectDeviceRequest {
    TuneHttpRequest *request = [[TuneHttpRequest alloc] init];
    [request setDomain:[TuneManager currentManager].configuration.connectedModeHostPort];
    [request setEndpoint:TuneApiDisconnectEndpoint];
    [request setHTTPMethod:TuneHttpRequestMethodTypePost];
    [request setValue:TuneHttpRequestHeaderJSON forHTTPHeaderField:TuneHttpRequestHeaderAccept];
    [request setValue:TuneHttpRequestHeaderJSON forHTTPHeaderField:TuneHttpRequestHeaderContentType];
    
    NSDictionary *endpointArgs = [TuneApi buildDefaultEndpointArguments];
    [request setEndpointArguments:endpointArgs];
    
    return request;
}

#pragma mark - Helpers

+ (NSDictionary *)buildDefaultEndpointArguments {
    TuneConfiguration *configuration = [TuneManager currentManager].configuration;
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;

    return @{ TuneApiVersionKey: configuration.apiVersion,
              TuneApiAppIdKey: [profile hashedAppId],
              TuneApiDeviceIdKey: [profile deviceId]
            };
}

@end
