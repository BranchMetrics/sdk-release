//
//  NSURLSession+SynchronousTask.m
//
//  Copyright (c) 2015 Florian Schliep (http://floschliep.com/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "NSURLSession+SynchronousTask.h"

#if DEBUG_STAGING
// handle self-signed certificates for Stage site
@interface TuneNSURLSessionDataDelegateHelper : NSObject <NSURLSessionDataDelegate>

@end

@implementation TuneNSURLSessionDataDelegateHelper

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    }
}

@end

#endif

@implementation NSURLSession (SynchronousTask)

#pragma mark - NSURLSessionDataTask

- (NSData *)sendSynchronousDataTaskWithURL:(NSURL *)url returningResponse:(NSURLResponse **)response error:(NSError **)error {
    return [self sendSynchronousDataTaskWithRequest:[NSURLRequest requestWithURL:url] returningResponse:response error:error];
}

- (NSData *)sendSynchronousDataTaskWithRequest:(NSURLRequest *)request returningResponse:(NSURLResponse * __autoreleasing *)response error:(NSError * __autoreleasing *)error {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSData *data = nil;
    
    NSURLSession *session = self;
    
#if DEBUG_STAGING
    // handle self-signed certificates for Stage site
    session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                            delegate:[TuneNSURLSessionDataDelegateHelper new]
                                       delegateQueue:[NSOperationQueue mainQueue]];
#endif
    
    [[session dataTaskWithRequest:request completionHandler:^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError) {
        data = taskData;
        if (response) {
            *response = taskResponse;
        }
        if (error) {
            *error = taskError;
        }
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return data;
}

#pragma mark - NSURLSessionDownloadTask

- (NSURL *)sendSynchronousDownloadTaskWithURL:(NSURL *)url returningResponse:(NSURLResponse **)response error:(NSError **)error {
    return [self sendSynchronousDownloadTaskWithRequest:[NSURLRequest requestWithURL:url] returningResponse:response error:error];
}

- (NSURL *)sendSynchronousDownloadTaskWithRequest:(NSURLRequest *)request returningResponse:(NSURLResponse * __autoreleasing *)response error:(NSError * __autoreleasing *)error {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSURL *location = nil;
    NSURLSession *session = self;
    
#if DEBUG_STAGING
    // handle self-signed certificates for Stage site
    session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                            delegate:[TuneNSURLSessionDataDelegateHelper new]
                                       delegateQueue:[NSOperationQueue mainQueue]];
#endif
    
    [[session downloadTaskWithRequest:request completionHandler:^(NSURL *taskLocation, NSURLResponse *taskResponse, NSError *taskError) {
        location = taskLocation;
        if (response) {
            *response = taskResponse;
        }
        if (error) {
            *error = taskError;
        }
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return location;
}

#pragma mark - NSURLSessionUploadTask

- (NSData *)sendSynchronousUploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL returningResponse:(NSURLResponse **)response error:(NSError **)error {
    return [self sendSynchronousUploadTaskWithRequest:request fromData:[NSData dataWithContentsOfURL:fileURL] returningResponse:response error:error];
}

- (NSData *)sendSynchronousUploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData returningResponse:(NSURLResponse * __autoreleasing *)response error:(NSError * __autoreleasing *)error {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSData *data = nil;
    NSURLSession *session = self;
    
#if DEBUG_STAGING
    // handle self-signed certificates for Stage site
    session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                            delegate:[TuneNSURLSessionDataDelegateHelper new]
                                       delegateQueue:[NSOperationQueue mainQueue]];
#endif
    
    [[session uploadTaskWithRequest:request fromData:bodyData completionHandler:^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError) {
        data = taskData;
        if (response) {
            *response = taskResponse;
        }
        if (error) {
            *error = taskError;
        }
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return data;
}

@end
