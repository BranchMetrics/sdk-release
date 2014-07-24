//
//  MATUserAgentCollector.h
//  MobileAppTracker
//
//  Created by John Bender on 5/9/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol MATUserAgentDelegate <NSObject>
@required

- (void)userAgentString:(NSString*)userAgent;

@end


@interface MATUserAgentCollector : NSObject <UIWebViewDelegate>
{
    UIWebView *webView;
    id <MATUserAgentDelegate> delegate;
}

- (id)initWithDelegate:(id <MATUserAgentDelegate>)newDelegate;

@end
