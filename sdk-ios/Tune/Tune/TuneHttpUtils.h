//
//  TuneHttpUtils.h
//  Tune
//
//  Created by Michael Raber on 5/24/12.
//  Copyright (c) 2012 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneManager.h"

@interface TuneHttpUtils : NSObject

+ (void)addIdentifyingHeaders:(NSMutableURLRequest *)request;
+ (NSString *)httpRequest:(NSString *)method action:(NSString *)action data:(NSDictionary *)data;

+ (void)performAsynchronousRequest:(NSURLRequest *)request completionHandler:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
+ (void)performSynchronousRequest:(NSURLRequest *)request completionHandler:(void(^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request response:(NSURLResponse **)response error:(NSError **)error;

@end
