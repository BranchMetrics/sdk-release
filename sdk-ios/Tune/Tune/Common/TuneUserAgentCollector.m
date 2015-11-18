//
//  TuneUserAgentCollector.m
//  Tune
//
//  Created by John Bender on 5/9/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import "TuneUserAgentCollector.h"

@interface TuneUserAgentCollector()
#if TARGET_OS_IOS
<UIWebViewDelegate>
#endif

@property (nonatomic, assign) BOOL hasStarted;
@property (nonatomic, strong) id webView;
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
#if !TARGET_OS_WATCH
        if( collector.hasStarted == NO && [UIApplication sharedApplication] != nil ) {
#else
        if( collector.hasStarted == NO ) {
#endif
            collector.hasStarted = YES;
            
            Class webViewClass = NSClassFromString(@"UIWebView");
            if( webViewClass && [webViewClass class] ) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    collector.webView = [webViewClass new];
                    [collector.webView performSelector:@selector(setDelegate:) withObject:collector];
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://fakesite"]];
                    [collector.webView performSelector:@selector(loadRequest:) withObject:request];
                }];
            }
        }
    }
}

+ (NSString*)userAgent
{
    return collector.userAgent;
}


#pragma mark - UIWebViewDelegate Methods

- (BOOL)           webView:(id)wv
shouldStartLoadWithRequest:(NSURLRequest *)request
#if TARGET_OS_IOS
            navigationType:(UIWebViewNavigationType)navigationType
#else
            navigationType:(NSInteger)navigationType
#endif
{
    NSString *agent = [request valueForHTTPHeaderField:@"User-Agent"];
    
    // in some rare cases when the user-agent string contains null garbage values, return nil
    collector.userAgent = [agent hasPrefix:@"(null)"] ? nil : agent;
    
    return NO;
}

@end
