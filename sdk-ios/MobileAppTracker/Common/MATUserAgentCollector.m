//
//  MATUserAgentCollector.m
//  MobileAppTracker
//
//  Created by John Bender on 5/9/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import "MATUserAgentCollector.h"

@implementation MATUserAgentCollector

- (id)initWithDelegate:(id <MATUserAgentDelegate>)newDelegate
{
    self = [super init];
    if( self ) {
        delegate = newDelegate;
        
        if( [UIApplication sharedApplication] == nil ) {
            // happens during testing -- add delay to check reliability
            [(NSObject*)delegate performSelector:@selector(userAgentString:) withObject:@"no-agent" afterDelay:2.5];
            return nil;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            webView = [UIWebView new];
            webView.delegate = self;
            [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://fakesite"]]];
        }];
    }
    return self;
}

- (BOOL)           webView:(UIWebView *)wv
shouldStartLoadWithRequest:(NSURLRequest *)request
            navigationType:(UIWebViewNavigationType)navigationType
{
    [delegate userAgentString:[request valueForHTTPHeaderField:@"User-Agent"]];

    return NO;
}

@end
