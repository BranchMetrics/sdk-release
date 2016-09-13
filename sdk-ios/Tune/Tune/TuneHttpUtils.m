//
//  TuneHttpUtils.m
//  Tune
//
//  Created by Michael Raber on 5/24/12.
//  Copyright (c) 2012 TUNE. All rights reserved.
//

#import "TuneHttpUtils.h"
#import "TuneHttpRequest.h"
#import "TuneManager.h"
#import "TuneUserProfile.h"
#import "TuneConfiguration.h"
#import "TuneDeviceDetails.h"
#import "TuneHttpRequest.h"
#import "NSURLSession+SynchronousTask.h"

@implementation TuneHttpUtils

+ (NSString *)httpRequest:(NSString *)method action:(NSString *)action data:(NSDictionary *)data {
    BOOL needsAmpersand = NO;
    NSMutableString *urlString = [[NSMutableString alloc] init];
    NSString *rightOfQuestionMark = nil;
    
    if(action != nil) {
        [urlString appendString:action];
        
        // TODO: validate incoming method parameter
        method = method ?: TuneHttpRequestMethodTypeGet;
        
        if(data) {
            NSInteger location = [action rangeOfString:@"?"].location;
            
            if(location==NSNotFound) {
                [urlString appendString:@"?"];
                
                needsAmpersand = NO;
            }
            else {
                rightOfQuestionMark = [action substringFromIndex:location + 1];
                needsAmpersand = rightOfQuestionMark.length > 0 && ![rightOfQuestionMark hasSuffix:@"&"];
            }
            
            for (NSString* key in data) {
                if(needsAmpersand) {
                    [urlString appendString:@"&"];
                }
                else {
                    needsAmpersand = YES;
                }
                
                [urlString appendString:key];
                [urlString appendString:@"="];
                [urlString appendString:[data valueForKey:key]];
            }
        }
    }
    
    DebugLog(@"urlString: %@", urlString);
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    
    NSData *result = [self sendSynchronousRequest:request response:nil error:nil];
    
    return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
}

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request response:(NSURLResponse **)response error:(NSError **)error {
    NSData *result;
    
#if TESTING
    if ([request.URL.absoluteString hasPrefix:@"(null)"]) {
        *error = nil;
        *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
        return nil;
    }
#endif
    
    if( [NSURLSession class] && [[NSURLSession sharedSession] respondsToSelector:@selector(sendSynchronousDataTaskWithRequest:returningResponse:error:)]) {
        result = [[NSURLSession sharedSession] sendSynchronousDataTaskWithRequest:request returningResponse:response error:error];
    } else {
        // iOS 6
        SEL ector = @selector(sendSynchronousRequest:returningResponse:error:);
        if ([NSURLConnection respondsToSelector:ector]) {
            typedef NSData* (*FuncProto)(id, SEL, NSURLRequest *, NSURLResponse **, NSError **);
            FuncProto methodToCall = (FuncProto)[[NSURLConnection class] methodForSelector:ector];
            result = methodToCall([NSURLConnection class], ector, request, response, error);
        }
    }
    
    return result;
}

+ (void)performAsynchronousRequest:(NSURLRequest *)request completionHandler:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    dispatch_async([[TuneManager currentManager] concurrentQueue], ^{
        NSURLResponse *response;
        NSError *error;
        NSData *data = [self sendSynchronousRequest:request response:&response error:&error];
        completionHandler(data, response, error);
    });
}

+ (void)addIdentifyingHeaders:(NSMutableURLRequest *)request {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    
    NSString *appId = [profile hashedAppId];
    NSString *deviceId = [profile deviceId];
    NSString *sdkVersion = [profile sdkVersion];
    NSString *appVersion = [profile appVersion];
    NSString *osVersion = [profile osVersion];
    NSString *osType = [profile osType];
    
    if (appId) {
        [request setValue:appId forHTTPHeaderField:TuneHttpRequestHeaderAppID];
    }
    
    if (deviceId) {
        [request setValue:deviceId forHTTPHeaderField:TuneHttpRequestHeaderDeviceID];
    }
    
    if (sdkVersion) {
        [request setValue:sdkVersion forHTTPHeaderField:TuneHttpRequestHeaderSdkVersion];
    }
    
    if (appVersion) {
        [request setValue:appVersion forHTTPHeaderField:TuneHttpRequestHeaderAppVersion];
    }
    
    if (osVersion) {
        [request setValue:osVersion forHTTPHeaderField:TuneHttpRequestHeaderOsVersion];
    }
    
    if (osType) {
        [request setValue:osType forHTTPHeaderField:TuneHttpRequestHeaderOsType];
    }
}

@end
