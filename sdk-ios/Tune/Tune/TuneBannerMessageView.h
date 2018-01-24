//
//  TuneBannerMessageView.h
//  
//
//  Created by Matt Gowie on 9/3/15.
//
//

#import "TuneBaseInAppMessageView.h"
#import "TuneMessageAction.h"
#import "TuneSkyhookPayload.h"
#import "TuneBannerMessageDefaults.h"
#import "TuneDeviceDetails.h"
#import "TuneAnalyticsConstants.h"
#import "TuneMessageOrientationState.h"
#import "TuneMessageStyling.h"
#import "TuneViewUtils.h"

#if TARGET_OS_IOS
@import WebKit;
#endif

@interface TuneBannerMessageView : TuneBaseInAppMessageView

// Configuration
@property (nonatomic) TuneMessageLocationType locationType;
@property (nonatomic, strong) NSNumber *duration;

// Layout state
@property (nonatomic) BOOL lastAnimation;

// Views
@property (nonatomic, strong, readwrite) UIView *containerView;

#if TARGET_OS_IOS
// Orientation
@property (nonatomic) UIInterfaceOrientation lastOrientation;
#endif

- (id)initWithLocationType:(TuneMessageLocationType)locationType;

// Show / Dismiss
- (void)show;

#if TARGET_OS_IOS
- (void)showOrientation:(UIInterfaceOrientation)deviceOrientation;
- (void)dismissOrientation:(UIInterfaceOrientation)orientation;
#endif

#if TARGET_OS_IOS
// Layout Containers (Overridden)
- (void)layoutMessageContainerForOrientation:(UIInterfaceOrientation)deviceOrientation;
- (void)buildMessageContainerForOrientation:(UIInterfaceOrientation)deviceOrientation;
#endif


#if TARGET_OS_IOS

// Orientation

- (void)deviceOrientationDidChange:(TuneSkyhookPayload *)payload;
- (void)handleTransitionToCurrentOrientation:(NSNumber *)currentOrientationAsNSNumber;

#endif

@end
