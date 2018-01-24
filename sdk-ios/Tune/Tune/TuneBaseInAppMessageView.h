//
//  TuneBaseInAppMessageView.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneCampaign.h"
#import "TuneInAppMessage.h"
#import "TuneInAppMessageAction.h"
#import "TuneInAppMessageConstants.h"
#import "TuneCloseButton.h"

@class TuneCloseButton;

#if TARGET_OS_IOS
@import WebKit;
#import <QuartzCore/QuartzCore.h>
@interface TuneBaseInAppMessageView : UIView <CAAnimationDelegate, WKNavigationDelegate>
#else
@interface TuneBaseInAppMessageView : UIView
#endif

@property (nonatomic, copy, readwrite) NSString *messageID;
@property (nonatomic, copy, readwrite) NSString *campaignStepID;
@property (nonatomic, strong, readwrite) TuneCampaign *campaign;
@property (nonatomic, copy, readwrite) NSString *html;
@property (nonatomic, strong, readwrite) NSDictionary<NSString *, TuneInAppMessageAction *> *tuneActions;
@property (nonatomic, strong, readwrite) NSDate *messageShownTimestamp;

@property (nonatomic, readwrite) BOOL needToLayoutView;
@property (nonatomic, readwrite) BOOL needToAddToUIWindow;
@property (nonatomic, readwrite) TuneMessageDeviceOrientation landscapeLeftType;
@property (nonatomic, readwrite) TuneMessageDeviceOrientation landscapeRightType;
@property (nonatomic, readwrite) TuneMessageDeviceOrientation portraitType;
@property (nonatomic, readwrite) TuneMessageDeviceOrientation portraitUpsideDownType;

@property (nonatomic, readwrite) TuneMessageTransition transitionType;
#if TARGET_OS_IOS
@property (nonatomic, strong, readwrite) WKWebView *webView;
#endif

@property (nonatomic, strong, readwrite) UIActivityIndicatorView *indicator;
@property (nonatomic, strong, readwrite) TuneCloseButton *closeButton;

@property (nonatomic, weak, readwrite) TuneInAppMessage *parentMessage;

@property (nonatomic) CGFloat statusBarOffset;

- (void)dismissAndWait;
- (void)dismiss;

- (void)recordMessageShown;
- (void)recordMessageDismissedWithAction:(NSString *)dismissedAction;

@end
