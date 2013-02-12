//
//  MATRemoteLogger.m
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/17/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "MATRemoteLogger.h"
#import "NSString+MATURLEncoding.m"
#import "MATConnectionManager.h"

@interface MATRemoteLogger()

@end



@implementation MATRemoteLogger

- (id)initWithURL:(NSString*)urlString
{
    self = [super init];
    
    if (self)
    {
        urlString_ = [urlString copy];
    }
    
    return self;
}

- (void)dealloc
{
    [urlString_ release]; urlString_ = nil;
    [super dealloc];
}

- (void)log:(NSString*)data
{
    NSString * dataEncoded = [data urlEncodeUsingEncoding:NSUTF8StringEncoding];
    
    NSString * urlCompleteString = [NSString stringWithFormat:@"%@?%@", urlString_, dataEncoded];
    NSURL * url = [NSURL URLWithString:urlCompleteString];

    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL];

    [NSURLConnection connectionWithRequest:request delegate:self];
}

@end
