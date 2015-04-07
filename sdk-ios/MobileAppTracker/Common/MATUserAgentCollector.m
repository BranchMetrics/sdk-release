//
//  MATUserAgentCollector.m
//  MobileAppTracker
//
//  Created by John Bender on 5/9/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import "MATUserAgentCollector.h"

@interface MATUserAgentCollector() <UIWebViewDelegate>

@property (nonatomic, assign) BOOL hasStarted;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, copy) NSString *userAgent;

@end


static MATUserAgentCollector *collector;


@implementation MATUserAgentCollector

+(void) initialize
{
    collector = [MATUserAgentCollector new];
}

+(void) startCollection
{
    @synchronized( collector ) {
        if( collector.hasStarted == NO && [UIApplication sharedApplication] != nil ) {
            collector.hasStarted = YES;

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                collector.webView = [UIWebView new];
                collector.webView.delegate = collector;
                [collector.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://fakesite"]]];
            }];
        }
    }
}

+(NSString*) userAgent
{
    return collector.userAgent;
}

- (BOOL)           webView:(UIWebView *)wv
shouldStartLoadWithRequest:(NSURLRequest *)request
            navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *agent = [request valueForHTTPHeaderField:@"User-Agent"];
    
    // in some rare cases when the user-agent string contains null garbage values, return nil
    collector.userAgent = [agent hasPrefix:@"(null)"] ? nil : agent;
    
    return NO;
}

@end
