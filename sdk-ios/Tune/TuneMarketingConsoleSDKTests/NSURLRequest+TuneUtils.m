//
//  NSURLRequest+TuneUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/14/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSURLRequest+TuneUtils.h"
#import "TuneHttpRequest.h"

@implementation NSURLRequest (TuneUtils)

- (BOOL)tuneIsEqualToNSURLRequest:(NSURLRequest *)request {
    if ([request HTTPBody].length != [self HTTPBody].length) {
        return NO;
    } else if (![[request HTTPMethod] isEqualToString:[self HTTPMethod]]){
        return NO;
    } else if (![[request valueForHTTPHeaderField:@"Content-Type"] isEqualToString:[self valueForHTTPHeaderField:@"Content-Type"]]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)tuneIsEqualToTuneHttpRequest:(TuneHttpRequest *)request {
    if ([request HTTPBody].length != [self HTTPBody].length) {
        return NO;
    } else if (![[request HTTPMethod] isEqualToString:[self HTTPMethod]]){
        return NO;
    } else if (![[request valueForHTTPHeaderField:@"Content-Type"] isEqualToString:[self valueForHTTPHeaderField:@"Content-Type"]]) {
        return NO;
    }
    
    return YES;
}

@end
