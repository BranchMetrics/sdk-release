//
//  TuneFullScreenMessageView.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/8/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneFullScreenMessageView.h"
#import "TuneFullScreenMessageDefaults.h"
#import "TuneMessageOrientationState.h"
#import "TuneMessageStyling.h"
#import "TuneAnalyticsConstants.h"
#import "TuneDeviceDetails.h"
#import "TuneSkyhookCenter.h"
#import "TuneManager.h"
#import "TuneUserProfile.h"
#import "TuneDeviceDetails.h"
#import "TuneViewUtils.h"
#import "TuneMessageStyling.h"
#import "TuneMessageOrientationState.h"
#import "TuneCloseButton.h"

@implementation TuneFullScreenMessageView

#pragma mark - Initialization

- (id)init {
    
#if TARGET_OS_IOS
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(deviceOrientationDidChange:)
                                              name:UIApplicationDidChangeStatusBarOrientationNotification
                                            object:nil];
#endif
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor clearColor];
        [self initDefaults];
    }
    
    return self;
}

- (void)dealloc {
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
}

- (void)initDefaults {
    self.lastAnimation = NO;
    self.transitionType = DefaultFullScreenTransitionType;
}

#pragma mark - Show / Dismiss

- (void)show {
    
    if (self.needToAddToUIWindow) {
        [[[UIApplication sharedApplication] keyWindow] addSubview:self];
        self.needToAddToUIWindow = NO;
    }
    
    #if TARGET_OS_IOS
    _lastOrientation = [TuneMessageOrientationState getCurrentOrientation];
    [self showOrientation:_lastOrientation];
    #endif
    
    [self recordMessageShown];
}

- (void)dismiss {
    self.parentMessage.visible = NO;
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
    // this allows us to catch the last animation
    self.lastAnimation = YES;
    
    #if TARGET_OS_IOS
    [self dismissOrientation:self.lastOrientation];
    #endif
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    // This is the final animation remove from superview
    if (self.lastAnimation) {
        [self performSelector:@selector(removeTakeOverMessageFromWindow) withObject:nil afterDelay:0.5];
    }
}

- (void)removeTakeOverMessageFromWindow {
    [self removeFromSuperview];
    self.lastAnimation = NO;
    self.needToAddToUIWindow = YES;
}

#pragma mark - Layout

#if TARGET_OS_IOS
- (void)layoutMessageContainerForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    [self buildMessageContainerForDeviceOrientation:deviceOrientation];
    self.needToLayoutView = NO;
}
#endif

- (UIView *)buildViewForOrientation:(TuneMessageDeviceOrientation)orientation {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.bounds.size.width, [UIApplication sharedApplication].keyWindow.bounds.size.height)];
    
#if TARGET_OS_IOS
    self.webView.frame = view.frame;
    self.webView.navigationDelegate = self;
    [view addSubview:self.webView];
    
    // Start by showing activity indicator
    if (self.parentMessage.webViewLoaded) {
        self.webView.hidden = NO;

        // Play transition in animation on WebView if it's loaded
        CATransition *transition = [TuneMessageStyling messageTransitionInWithType:self.transitionType withEaseIn:NO];
        [self.webView.layer removeAllAnimations];
        [self.webView.layer addAnimation:transition forKey:kCATransition];
        [UIView commitAnimations];
    } else {
        // Add activity indicator to view
        self.indicator.center = view.center;
        [view addSubview:self.indicator];
        [view bringSubviewToFront:self.indicator];
        [self.indicator startAnimating];
        
        // Set close button position
        CGRect closeButtonFrame = self.closeButton.frame;
        CGFloat xPosition = CGRectGetWidth(view.frame) - CGRectGetWidth(closeButtonFrame) - 16;
        closeButtonFrame.origin = CGPointMake(ceil(xPosition), self.statusBarOffset + 16.0);
        self.closeButton.frame = closeButtonFrame;
        self.closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        
        // Add close button after 1s
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
            if (!self.parentMessage.webViewLoaded) {
                // Add close button to view
                [view addSubview:self.closeButton];
                [view bringSubviewToFront:self.closeButton];
            }
        });
    }
#endif
    
    return view;
}

#pragma mark - Orientation Handling

#if TARGET_OS_IOS
- (void)handleTransitionToCurrentOrientation:(NSNumber *)currentOrientationAsNSNumber {
    UIInterfaceOrientation currentOrientation = [currentOrientationAsNSNumber intValue];
    [self showOrientation:currentOrientation];
    self.lastOrientation = currentOrientation;
}
#endif

#pragma mark - Overridden By Subclasses

#if TARGET_OS_IOS
- (void)buildMessageContainerForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation {
    
    if (![TuneDeviceDetails orientationIsSupportedByApp:deviceOrientation]) {
        return;
    }
    
#if TARGET_OS_IOS
    self.statusBarOffset = [[UIApplication sharedApplication].delegate.window.rootViewController prefersStatusBarHidden] ? 0 : 20;
#else
    self.statusBarOffset = 0;
#endif
    
    TuneMessageDeviceOrientation orientation = self.portraitType;
    
    switch (deviceOrientation) {
        case UIInterfaceOrientationPortrait:
        orientation = self.portraitType;
        break;
        case UIInterfaceOrientationPortraitUpsideDown:
        orientation = self.portraitUpsideDownType;
        break;
        case UIInterfaceOrientationLandscapeRight:
        orientation = self.landscapeRightType;
        break;
        case UIInterfaceOrientationLandscapeLeft:
        orientation = self.landscapeLeftType;
        break;
        default:
        break;
    }
    
    self.containerView = [self buildViewForOrientation:orientation];
    [TuneViewUtils setX:0 onView:self.containerView];
    [TuneViewUtils setY:self.statusBarOffset onView:self.containerView];
    self.containerView.hidden = YES;
    [self addSubview:self.containerView];
}
#endif

#pragma mark - Transition

#if TARGET_OS_IOS
- (TuneMessageTransition)getTransitionType {
    return self.transitionType;
}
#endif

#pragma mark - Orientation Handling

#if TARGET_OS_IOS
- (void)showOrientation:(UIInterfaceOrientation)orientation {
    [self.layer removeAllAnimations];

    if (!self.containerView) {
        [self layoutMessageContainerForDeviceOrientation:orientation];
    }
    self.containerView.hidden = NO;
}

- (void)dismissOrientation:(UIInterfaceOrientation)orientation {
    [self.layer removeAllAnimations];
    CATransition *transition = [TuneMessageStyling messageTransitionOutWithType:[self getTransitionType] withEaseIn:YES];
    
    if (self.lastAnimation) {
        transition.delegate = self;
        CATransition *maskTransition = [TuneMessageStyling messageBackgroundMaskTransition];
        [self.backgroundMaskView.layer addAnimation:maskTransition forKey:kCATransition];
        self.backgroundMaskView.hidden = YES;
    }
    
    [self.containerView.layer removeAllAnimations];
    [self.containerView.layer addAnimation:transition forKey:kCATransition];
    self.containerView.hidden = YES;
    
    [UIView commitAnimations];
}
#endif

- (void)deviceOrientationDidChange:(TuneSkyhookPayload *)payload {
    // Resize the container view based on orientation
    CGFloat screenWidth = [UIApplication sharedApplication].keyWindow.bounds.size.width;
    CGFloat screenHeight = [UIApplication sharedApplication].keyWindow.bounds.size.height;
    
#if TARGET_OS_IOS
    self.statusBarOffset = [[UIApplication sharedApplication].delegate.window.rootViewController prefersStatusBarHidden] ? 0 : 20;
#else
    self.statusBarOffset = 0;
#endif
    
    CGRect bounds = CGRectMake(0, self.statusBarOffset, screenWidth, screenHeight);
    
    self.containerView.frame = bounds;
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    if (activity) {
        activity.center = CGPointMake(screenWidth / 2, screenHeight / 2);
    }
}

@end
