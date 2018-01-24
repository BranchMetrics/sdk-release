//
//  TuneMessageStyling.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessageConstants.h"

@interface TuneMessageStyling : NSObject

+ (CATransition *)messageBackgroundMaskTransition;
+ (CATransition *)messageTransitionWithType:(TuneMessageTransition)transitionType;
+ (CATransition *)messageTransitionWithType:(TuneMessageTransition)transitionType withEaseIn:(BOOL)easeIn;
+ (CATransition *)messageTransitionInWithType:(TuneMessageTransition)transitionType;
+ (CATransition *)messageTransitionInWithType:(TuneMessageTransition)transitionType withEaseIn:(BOOL)easeIn;
+ (CATransition *)messageTransitionOutWithType:(TuneMessageTransition)transitionType;
+ (CATransition *)messageTransitionOutWithType:(TuneMessageTransition)transitionType withEaseIn:(BOOL)easeIn;

+ (TuneMessageTransition)reverseTransitionForType:(TuneMessageTransition)forwardTransition;

@end
