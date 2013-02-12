//
//  MATUserAgent.m
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/12/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "MATUserAgent.h"

@interface MATUserAgent()

- (BOOL)stringRetrieved;
- (void)setStringRetrieved:(BOOL)value;

@end

@implementation MATUserAgent

@dynamic agentString;

+(id)matUserAgent
{
    return [[[MATUserAgent alloc] init] autorelease];
}

- (NSString*)agentString
{
    if (!agentString_)
    {        
        [webView_ loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]]];        

        while (![self stringRetrieved]) 
        {
            // This executes another run loop. 
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }
    
    return agentString_;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	agentString_ = [[request valueForHTTPHeaderField:@"User-Agent"] copy];
    
    [self setStringRetrieved:YES];

	return NO;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        agentString_ = nil;
        
        webView_ = [[UIWebView alloc] init];
        webView_.delegate = self;
        
        stringRetrieved_ = NO;
    }
    
    return self;
}

- (void)dealloc
{
    if ([webView_ isLoading])
    {
        [webView_ stopLoading];
    }
    [webView_ setDelegate:nil];
    
    [agentString_ release]; agentString_ = nil;
    [webView_ release]; webView_ = nil;
    
    [super dealloc];
}

- (BOOL)stringRetrieved
{
    @synchronized(self)
    {
        return stringRetrieved_;
    }
}

- (void)setStringRetrieved:(BOOL)value
{
    @synchronized(self)
    {
        stringRetrieved_ = value;
    }
}


@end
