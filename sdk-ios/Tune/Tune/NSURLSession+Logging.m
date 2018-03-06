//
//  NSURLSession+Logging.m
//  TuneSwiftSample
//
//  Created by Ernest Cho on 12/8/17.
//  Copyright © 2017 tune. All rights reserved.
//

#import "NSURLSession+Logging.h"
#import <objc/runtime.h>

//  Logs EVERY network request!  Only include this file to debug the project at a low level.
//  This should NOT be included in any target by default.
@implementation NSURLSession (Logging)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(dataTaskWithRequest:completionHandler:);
        SEL swizzledSelector = @selector(xxx_dataTaskWithRequest:completionHandler:);

        [self swizzleSelector:originalSelector withSelector:swizzledSelector];
    });
}

// Swaps originalSelector with swizzledSelector
+ (void)swizzleSelector:(SEL)originalSelector withSelector:(SEL)swizzledSelector {
    Class class = [self class];
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

- (NSURLSessionDataTask *)xxx_dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSLog(@"Swizzled xxx_dataTaskWithRequest:completionHandler:");
    
    // block that removes the data from the response, this is to test data error
    void (^completionHandlerWithLogging)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"%@\n%@\n%@\n", data, response, error);
        if (completionHandler) {
            completionHandler(data, response, error);
        }
    };
    
    return [self xxx_dataTaskWithRequest:request completionHandler:completionHandlerWithLogging];
}

@end
