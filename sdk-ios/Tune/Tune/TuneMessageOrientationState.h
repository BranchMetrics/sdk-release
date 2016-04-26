//
//  TuneMessageOrientationState.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//



@interface TuneMessageOrientationState : NSObject {
#if TARGET_OS_IOS
    UIDeviceOrientation _lastOrientation;
#endif
    NSArray *_orientations;
}

#if TARGET_OS_IOS
+ (UIDeviceOrientation)getCurrentOrientation;
+ (void)startTrackingOrientation;
+ (NSNumber *)calculateAngleToRotateView;
+ (BOOL)currentOrientationIsSupportedByApp;
#endif

+ (TuneMessageOrientationState *)sharedState;
+ (NSNumber *)calculateAngleToRotateViewFromPortrait;
+ (CGSize)getCalculatedWindowSizeForCurrentOrientation;


@end
