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
#import "TuneHttpRequest.h"

@implementation TuneHttpUtils

+ (NSString *)httpRequest:(NSString *)method action:(NSString *)action data:(NSDictionary *)data {
    BOOL needsAmpersand = NO;
    NSMutableString *urlString = [[NSMutableString alloc] init];
    NSString *rightOfQuestionMark = nil;
    
    if(action != nil) {
        [urlString appendString:action];
        
        // TODO: validate incoming method parameter
        method = method ? method : TuneHttpRequestMethodTypeGet;
        
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
        
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    
    NSData *result = [self sendSynchronousRequest:request response:nil error:nil];
    
    return [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
}

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request response:(NSURLResponse **)response error:(NSError **)error {
    // Avoid using out parameters with blocks.  The compiler clones block variables between the stack and the heap, using addresses can cause unexpected behavior!
    // local variables to capture data from network request
    __block NSData *returnData;
    __block NSURLResponse *returnResponse;
    __block NSError *returnError;
    
    [self performSynchronousRequest:request completionHandler:^(NSData *dataTmp, NSURLResponse *responseTmp, NSError *errorTmp) {
        returnData = dataTmp;
        returnResponse = responseTmp;
        returnError = errorTmp;
    }];
    
    // set the out parameters
    if (response && returnResponse) {
        *response = returnResponse;
    }
    if (error && returnError) {
        *error = returnError;
    }
     
    return returnData;
}

// synchronous call to NSURLSession
+ (void)performSynchronousRequest:(NSURLRequest *)request completionHandler:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    // block that just calls the input block and signals the semaphore
    void (^completionHandlerWithSemaphoreSignal)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (completionHandler) {
            completionHandler(data, response, error);
        }
        dispatch_semaphore_signal(semaphore);
    };
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completionHandlerWithSemaphoreSignal] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

// basic call to NSURLSession
+ (void)performAsynchronousRequest:(NSURLRequest *)request completionHandler:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completionHandler] resume];
}

// adds tune headers to a request
+ (void)addIdentifyingHeaders:(NSMutableURLRequest *)request {
    TuneUserProfile *profile = [TuneManager currentManager].userProfile;
    
    NSString *deviceId = [profile deviceId];
    NSString *sdkVersion = [profile sdkVersion];
    NSString *appVersion = [profile appVersion];
    NSString *osVersion = [profile osVersion];
    NSString *osType = [profile osType];
    
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
