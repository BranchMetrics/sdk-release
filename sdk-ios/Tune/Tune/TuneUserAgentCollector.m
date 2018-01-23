//
//  TuneUserAgentCollector.m
//  Tune
//
//  Created by John Bender on 5/9/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import "TuneUserAgentCollector.h"
#import "TuneUtils.h"
#import "TuneUserDefaultsUtils.h"

@interface TuneUserAgentCollector()
#if TARGET_OS_IOS
<UIWebViewDelegate>
#endif

@property (nonatomic, assign) BOOL hasStarted;
@property (nonatomic, strong) id webView;
@property (nonatomic, copy) NSString *userAgent;

@end

static TuneUserAgentCollector *collector;
static NSString *TuneUserAgentCollectorUserAgent = @"tuneUserAgentCollectorUserAgent";
static NSString *TuneUserAgentCollectorOsVersion = @"tuneUserAgentCollectorOsVersion";

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
        if( !collector.hasStarted && [UIApplication sharedApplication] != nil ) {
#else
        if( !collector.hasStarted ) {
#endif
            collector.hasStarted = YES;

            NSString *cachedUserAgent = [self cachedUserAgentForOSVersion:[UIDevice currentDevice].systemVersion];
            if (cachedUserAgent) {
                collector.userAgent = cachedUserAgent;
                return;
            }

            Class webViewClass = [TuneUtils getClassFromString:@"UIWebView"];
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

#pragma mark - Private Methods

+ (NSString *)cachedUserAgentForOSVersion:(NSString *)osVersion
{
    NSString *userAgent = [TuneUserDefaultsUtils userDefaultValueforKey:TuneUserAgentCollectorUserAgent];
    NSString *cachedOsVersion = [TuneUserDefaultsUtils userDefaultValueforKey:TuneUserAgentCollectorOsVersion];
    if([cachedOsVersion isEqualToString:osVersion]) {
        return userAgent;
    }
    return nil;
}

+ (void)saveUserAgent:(NSString *)userAgent forOSVersion:(NSString *)osVersion
{
    [TuneUserDefaultsUtils setUserDefaultValue:userAgent forKey:TuneUserAgentCollectorUserAgent];
    [TuneUserDefaultsUtils setUserDefaultValue:osVersion forKey:TuneUserAgentCollectorOsVersion];
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
    [self.class saveUserAgent:collector.userAgent forOSVersion:[UIDevice currentDevice].systemVersion];
    
    return NO;
}

@end
