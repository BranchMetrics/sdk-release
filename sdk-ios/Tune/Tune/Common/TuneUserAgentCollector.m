//
//  TuneUserAgentCollector.m
//  Tune
//
//  Created by John Bender on 5/9/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import "TuneUserAgentCollector.h"

@interface TuneUserAgentCollector() <UIWebViewDelegate>

@property (nonatomic, assign) BOOL hasStarted;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, copy) NSString *userAgent;

@end

static TuneUserAgentCollector *collector;

@implementation TuneUserAgentCollector


#pragma mark - Init Methods

+ (void)initialize
{
    collector = [TuneUserAgentCollector new];
}


#pragma mark - Public Methods

+ (void)startCollection
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

+ (NSString*)userAgent
{
    return collector.userAgent;
}


#pragma mark - UIWebViewDelegate Methods

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
