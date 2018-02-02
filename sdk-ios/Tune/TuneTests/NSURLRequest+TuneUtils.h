//
//  NSURLRequest+TuneUtils.h
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/14/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TuneHttpRequest.h"

@interface NSURLRequest (TuneUtils)

- (BOOL)tuneIsEqualToNSURLRequest:(NSURLRequest *)request;
- (BOOL)tuneIsEqualToTuneHttpRequest:(TuneHttpRequest *)request;

@end
