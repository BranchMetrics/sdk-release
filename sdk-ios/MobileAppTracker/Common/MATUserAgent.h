//
//  MATUserAgent.h
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/12/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MATUserAgent : NSObject<UIWebViewDelegate>
{
    NSString * agentString_;
    UIWebView * webView_;
    BOOL stringRetrieved_;
}

@property (nonatomic, readonly) NSString * agentString;

+(id)matUserAgent;

@end
