//
//  NSURLSession+TuneDelegateMockServer.h
//  Tune
//
//  Created by Ernest Cho on 11/17/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

// This mock server is used to verify Tune network error handling.
// This does NOT mock whole data, just modifies real responses.
@interface NSURLSession (TuneDelegateMockServer)

+ (void)swizzleDataTaskToReturnNoData;
+ (void)unswizzleDataTaskToReturnNoData;

+ (void)swizzleDataTaskToHttp400;
+ (void)unswizzleDataTaskToHttp400;

+ (void)swizzleDataTaskToHttpError;
+ (void)unswizzleDataTaskToHttpError;

@end
