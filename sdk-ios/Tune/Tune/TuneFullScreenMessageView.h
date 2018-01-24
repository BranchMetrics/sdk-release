//
//  TuneFullScreenMessageView.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/8/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneBaseInAppMessageView.h"
#import "TuneMessageAction.h"
#import "TuneSkyhookPayload.h"

#if TARGET_OS_IOS
@import WebKit;
#endif

@interface TuneFullScreenMessageView : TuneBaseInAppMessageView

// Background mask
@property (nonatomic, readwrite) TuneMessageBackgroundMaskType backgroundMaskType;
@property (nonatomic, strong, readwrite) UIView *backgroundMaskView;

// Layout state
@property (nonatomic, readwrite) BOOL lastAnimation;

// Views
@property (nonatomic, strong, readwrite) UIView *containerView;

#if TARGET_OS_IOS
// Orientation
@property (nonatomic, readwrite) UIInterfaceOrientation lastOrientation;
#endif

- (id)init;

- (void)show;

#if TARGET_OS_IOS
- (void)showOrientation:(UIInterfaceOrientation)orientation;
- (void)dismissOrientation:(UIInterfaceOrientation)orientation;
#endif

- (UIView *)buildViewForOrientation:(TuneMessageDeviceOrientation)orientation;

#if TARGET_OS_IOS
- (void)layoutMessageContainerForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation;

- (void)buildMessageContainerForDeviceOrientation:(UIInterfaceOrientation)deviceOrientation;
#endif

#if TARGET_OS_IOS

- (void)deviceOrientationDidChange:(TuneSkyhookPayload *)payload;
- (void)handleTransitionToCurrentOrientation:(NSNumber *)currentOrientationAsNSNumber;

#endif

@end
