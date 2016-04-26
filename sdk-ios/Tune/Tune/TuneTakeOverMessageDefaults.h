//
//  TuneTakeOverMessageDefaults.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/8/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessageConstants.h"

@interface TuneTakeOverMessageDefaults : NSObject

// Size
+ (CGFloat)takeOverMessageDefaultHeightByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;
+ (CGFloat)takeOverMessageDefaultWidthByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;

// Background Mask Type
extern TuneMessageBackgroundMaskType const TakeOverMessageDefaultBackgroundMaskColor;

// Close button
extern TuneMessageCloseButtonColor const TakeOverMessageDefaultCloseButtonColor;
extern TuneTakeOverMessageCloseButtonLocationType const TuneTakeOverMessageDefaultCloseButtonLocation;
extern CGFloat const TakeOverMessageCloseButtonSize;
+ (CGFloat)takeOverMessageCloseButtonPaddingByDeviceOrientation:(TuneMessageDeviceOrientation)orientation;
+ (CGRect)takeOverMessageCloseButtonFrameByDeviceOrientation:(TuneMessageDeviceOrientation)orientation
                                      andCloseButtonLocation:(TuneTakeOverMessageCloseButtonLocationType)closeButtonLocation;
+ (CGRect)takeOverMessageCloseButtonClickOverlayFrameByDeviceOrientation:(TuneMessageDeviceOrientation)orientation
                                                  andCloseButtonLocation:(TuneTakeOverMessageCloseButtonLocationType)closeButtonLocation;

// Transition
extern TuneMessageTransition const DefaultTakeOverTransitionType;

@end
