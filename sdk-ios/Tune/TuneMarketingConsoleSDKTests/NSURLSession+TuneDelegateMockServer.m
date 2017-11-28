//
//  NSURLSession+TuneDelegateMockServer.m
//  Tune
//
//  Created by Ernest Cho on 11/17/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import "NSURLSession+TuneDelegateMockServer.h"
#import <objc/runtime.h>

// Low level mock server to test server error scenarios
@implementation NSURLSession (TuneDelegateMockServer)

+ (void)swizzleDataTaskToReturnNoData {
    [self swizzleSelector:@selector(dataTaskWithRequest:completionHandler:) withSelector:@selector(returnNoData_dataTaskWithRequest:completionHandler:)];
}

+ (void)unswizzleDataTaskToReturnNoData {
    [self swizzleSelector:@selector(returnNoData_dataTaskWithRequest:completionHandler:) withSelector:@selector(dataTaskWithRequest:completionHandler:)];
}

+ (void)swizzleDataTaskToHttp400 {
    [self swizzleSelector:@selector(dataTaskWithRequest:completionHandler:) withSelector:@selector(http400_dataTaskWithRequest:completionHandler:)];
}

+ (void)unswizzleDataTaskToHttp400 {
    [self swizzleSelector:@selector(http400_dataTaskWithRequest:completionHandler:) withSelector:@selector(dataTaskWithRequest:completionHandler:)];
}

+ (void)swizzleDataTaskToHttpError {
    [self swizzleSelector:@selector(dataTaskWithRequest:completionHandler:) withSelector:@selector(httpError_dataTaskWithRequest:completionHandler:)];
}

+ (void)unswizzleDataTaskToHttpError {
    [self swizzleSelector:@selector(httpError_dataTaskWithRequest:completionHandler:) withSelector:@selector(dataTaskWithRequest:completionHandler:)];
}

// Swaps originalSelector with swizzledSelector
+ (void)swizzleSelector:(SEL)originalSelector withSelector:(SEL)swizzledSelector {
    Class class = [self class];
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (NSURLSessionDataTask *)returnNoData_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSLog(@"Swizzled returnNoData_dataTaskWithRequest:completionHandler:");
    
    // block that removes the data from the response, this is to test data error
    void (^completionHandlerWithNoData)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (completionHandler) {
            completionHandler(nil, response, error);
        }
    };
    
    return [self returnNoData_dataTaskWithRequest:request completionHandler:completionHandlerWithNoData];
}

- (NSURLSessionDataTask *)http400_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSLog(@"Swizzled http400_dataTaskWithRequest:completionHandler:");
    
    // block that removes the data from the response, this is to test data error
    void (^completionHandlerWithNoData)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (completionHandler) {
            // HTTP 400 is not an error from NSURLSession's point of view, it's a valid and expected server response
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSHTTPURLResponse *copyHttpResponse = [[NSHTTPURLResponse alloc] initWithURL:httpResponse.URL statusCode:400 HTTPVersion:@"HTTP/1.1" headerFields:httpResponse.allHeaderFields];
            completionHandler(data, copyHttpResponse, error);
        }
    };
    
    return [self http400_dataTaskWithRequest:request completionHandler:completionHandlerWithNoData];
}

- (NSURLSessionDataTask *)httpError_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSLog(@"Swizzled httpError_dataTaskWithRequest:completionHandler:");
    
    // block that removes the data from the response, this is to test data error
    void (^completionHandlerWithNoData)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (completionHandler) {
            completionHandler(data, response, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotConnectToHost userInfo:nil]);
        }
    };
    
    return [self httpError_dataTaskWithRequest:request completionHandler:completionHandlerWithNoData];
}

@end
