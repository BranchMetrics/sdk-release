//
//  TuneBannerMessageView.m
//  
//
//  Created by Matt Gowie on 9/3/15.
//
//

#import "TuneBannerMessageView.h"
#import "TuneBannerMessageDefaults.h"
#import "TuneDeviceDetails.h"
#import "TuneMessageOrientationState.h"
#import "TuneInAppMessageConstants.h"
#import "TuneAnalyticsConstants.h"
#import "TuneMessageStyling.h"
#import "TuneViewUtils.h"
#import "TuneSkyhookCenter.h"

@implementation TuneBannerMessageView

#pragma mark - Initialization

- (id)initWithLocationType:(TuneMessageLocationType)locationType {
    
#if TARGET_OS_IOS
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(deviceOrientationDidChange:)
                                              name:UIApplicationDidChangeStatusBarOrientationNotification
                                            object:nil];
#endif
    
    self = [super init];
    
    if (self) {
        self.locationType = locationType;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        [self initDefaults];
    }
    
    return self;
}

- (void)dealloc {
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
}

- (void)initDefaults {
    self.lastAnimation = NO;
}

#if TARGET_OS_IOS
- (void)layoutMessageContainerForOrientation:(UIInterfaceOrientation)deviceOrientation {
    [self buildMessageContainerForOrientation:deviceOrientation];
    
    // This is not used for this type of slide-in. We build the views if the containers are nil.
    self.needToLayoutView = NO;
}
#endif

#pragma mark - Show

- (void)show {
    if (self.needToAddToUIWindow) {
        [[[UIApplication sharedApplication] keyWindow] addSubview:self];
        self.needToAddToUIWindow = NO;
    }
    
#if TARGET_OS_IOS
    self.lastOrientation = [TuneMessageOrientationState getCurrentOrientation];
    [self showOrientation:self.lastOrientation];
#endif
    
    [self recordMessageShown];
    
    if ([self.duration floatValue] > 0) {
        [self performSelector:@selector(markDismissedAfterDurationAndDismiss) withObject:nil afterDelay:[_duration floatValue]];
    }
}

#pragma mark - Dismiss

- (void)markDismissedAfterDurationAndDismiss {
    [self recordMessageDismissedWithAction:TUNE_IN_APP_MESSAGE_ACTION_DISMISSED_AFTER_DURATION];
    [self dismiss];
}

- (void)dismiss {
    self.parentMessage.visible = NO;
    
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
    // this allows us to catch the last animation
    self.lastAnimation = YES;
#if TARGET_OS_IOS
    [self dismissOrientation:_lastOrientation];
#endif
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
    // This is the final animation remove from superview
    if (self.lastAnimation) {
        [self performSelector:@selector(removeSlideInMessageFromWindow) withObject:nil afterDelay:0.5];
    }
}

- (void)removeSlideInMessageFromWindow {
    [self removeFromSuperview];
    self.lastAnimation = NO;
    self.needToAddToUIWindow = YES;
}

#pragma mark - Orientation

#if TARGET_OS_IOS

- (void)handleTransitionToCurrentOrientation:(NSNumber *)currentOrientationAsNSNumber {
    UIInterfaceOrientation currentOrientation = [currentOrientationAsNSNumber intValue];
    [self showOrientation:currentOrientation];
    self.lastOrientation = currentOrientation;
}

#endif

#pragma mark - Containers

#if TARGET_OS_IOS

- (void)buildMessageContainerForOrientation:(UIInterfaceOrientation)deviceOrientation {
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
    self.containerView.hidden = YES;
    if (self.locationType == TuneMessageLocationTop) {
        [TuneViewUtils setY:self.statusBarOffset onView:self.containerView];
    } else {
        [TuneViewUtils setY:([UIApplication sharedApplication].keyWindow.bounds.size.height - self.containerView.frame.size.height) onView:self.containerView];
    }
    
    [self addSubview:self.containerView];
}

#else

- (void)buildMessageContainer {
    self.containerView = [self buildViewForOrientation:self.portraitType];
    self.containerView.hidden = YES;
    
    if (self.locationType == TuneMessageLocationTop) {
        [TuneViewUtils setY:self.statusBarOffset onView:self.containerView];
    } else {
        [TuneViewUtils setY:([UIApplication sharedApplication].keyWindow.bounds.size.height - self.containerView.frame.size.height) onView:self.containerView];
    }
    
    [self addSubview:self.containerView];
}

#endif

#pragma mark - Orientation related methods

#if TARGET_OS_IOS

- (TuneMessageDeviceOrientation)getCurrentTuneOrientationForUIDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    TuneMessageDeviceOrientation currentTuneDeviceOrientation = TuneMessageOrientationNA;
    
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            currentTuneDeviceOrientation = self.portraitType;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            currentTuneDeviceOrientation = self.portraitUpsideDownType;
            break;
        case UIDeviceOrientationLandscapeRight:
            currentTuneDeviceOrientation = self.landscapeLeftType;
            break;
        case UIDeviceOrientationLandscapeLeft:
            currentTuneDeviceOrientation = self.landscapeRightType;
            break;
        default:
            break;
    }
    
    return currentTuneDeviceOrientation;
}

- (void)showOrientation:(UIInterfaceOrientation)deviceOrientation {
    [self.layer removeAllAnimations];
    [self layoutMessageContainerForOrientation:deviceOrientation];
    
    self.containerView.hidden = NO;
}

- (void)dismissOrientation:(UIInterfaceOrientation)orientation {
    [self.layer removeAllAnimations];
    CATransition *transition = [TuneMessageStyling messageTransitionOutWithType:self.transitionType withEaseIn:YES];
    
    if (self.lastAnimation) {
        transition.delegate = self;
    }
    
    [self.containerView.layer removeAllAnimations];
    [self.containerView.layer addAnimation:transition forKey:kCATransition];
    self.containerView.hidden = YES;
    
    [UIView commitAnimations];
}

#endif


#if TARGET_OS_IOS

- (void)deviceOrientationDidChange:(TuneSkyhookPayload *)payload {
    UIInterfaceOrientation currentOrientation = [TuneMessageOrientationState getCurrentOrientation];
    
    if (currentOrientation == self.lastOrientation) {
        // Do nothing
        return;
    }
    
    if ([TuneDeviceDetails orientationIsSupportedByApp:currentOrientation]) {
        self.frame = CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.bounds.size.width, [UIApplication sharedApplication].keyWindow.bounds.size.height);
        [self dismissOrientation:self.lastOrientation];
        [self performSelector:@selector(handleTransitionToCurrentOrientation:) withObject:@(currentOrientation) afterDelay:0.2];
    }
}

#endif

- (UIView *)buildViewForOrientation:(TuneMessageDeviceOrientation)orientation {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIApplication sharedApplication].keyWindow.bounds.size.width, [TuneBannerMessageDefaults bannerMessageDefaultHeightByDeviceOrientation:orientation])];
    
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
        // Use default margin or vertically center the close button, whichever is closer to the top edge
        CGFloat yPosition = MIN(16, (view.frame.size.height - 44) / 2);
        closeButtonFrame.origin = CGPointMake(ceil(xPosition), ceil(yPosition));
        
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

@end
