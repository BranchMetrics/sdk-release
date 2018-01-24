//
//  TuneMessageStyling.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneMessageStyling.h"
#import "TuneBannerMessageDefaults.h"
#import "TuneModalMessageDefaults.h"
#import "TuneButtonUtils.h"
#import "TuneImageAssets.h"
#import "TuneDeviceDetails.h"
#import "TuneImageUtils.h"

@implementation TuneMessageStyling

#pragma mark - Transitions

+ (CATransition *)messageBackgroundMaskTransition {
    CATransition *transition = [CATransition animation];
    transition.duration = 0.25;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    return transition;
}

+ (CATransition *)messageTransitionInWithType:(TuneMessageTransition)transitionType {
    return [TuneMessageStyling messageTransitionWithType:transitionType withEaseIn:YES];
}

+ (CATransition *)messageTransitionInWithType:(TuneMessageTransition)transitionType withEaseIn:(BOOL)easeIn {
    return [TuneMessageStyling messageTransitionWithType:transitionType withEaseIn:easeIn];
}

+ (CATransition *)messageTransitionOutWithType:(TuneMessageTransition)transitionType {
    return [TuneMessageStyling messageTransitionWithType:[TuneMessageStyling reverseTransitionForType:transitionType] withEaseIn:NO];
}

+ (CATransition *)messageTransitionOutWithType:(TuneMessageTransition)transitionType withEaseIn:(BOOL)easeIn {
    return [TuneMessageStyling messageTransitionWithType:[TuneMessageStyling reverseTransitionForType:transitionType] withEaseIn:easeIn];
}

+ (CATransition *)messageTransitionWithType:(TuneMessageTransition)transitionType {
    return [TuneMessageStyling messageTransitionWithType:transitionType withEaseIn:YES];
}

+ (CATransition *)messageTransitionWithType:(TuneMessageTransition)transitionType withEaseIn:(BOOL)easeIn {
    CATransition* transition = [CATransition animation];
    
    transition.timingFunction = [CAMediaTimingFunction functionWithName:easeIn ? kCAMediaTimingFunctionEaseIn : kCAMediaTimingFunctionEaseOut];
    transition.duration = 0.25f;
    transition.type = kCATransitionPush;
    
    if (transitionType == TuneMessageTransitionFromLeft) {
        transition.type = kCATransitionPush;
        transition.subtype = @"fromLeft";
    }
    else if (transitionType == TuneMessageTransitionFromRight) {
        transition.type = kCATransitionPush;
        transition.subtype = @"fromRight";
    }
    else if (transitionType == TuneMessageTransitionFromBottom) {
        transition.type = kCATransitionPush;
        transition.subtype = @"fromTop";
    }
    else if (transitionType == TuneMessageTransitionFromTop) {
        transition.type = kCATransitionPush;
        transition.subtype = @"fromBottom";
    }
    else if (transitionType == TuneMessageTransitionFadeIn) {
        transition.duration = 0.4f;
        transition.type = kCATransitionMoveIn;
        transition.subtype = kCATransitionFade;
    }
    
    return transition;
}

+ (TuneMessageTransition)reverseTransitionForType:(TuneMessageTransition)forwardTransition
{
    if (forwardTransition == TuneMessageTransitionFadeIn) {
        return TuneMessageTransitionFadeIn;
    }
    else if (forwardTransition == TuneMessageTransitionFromBottom) {
        return TuneMessageTransitionFromTop;
    }
    else if (forwardTransition == TuneMessageTransitionFromTop) {
        return TuneMessageTransitionFromBottom;
    }
    else if (forwardTransition == TuneMessageTransitionFromLeft) {
        return TuneMessageTransitionFromRight;
    }
    else if (forwardTransition == TuneMessageTransitionFromRight) {
        return TuneMessageTransitionFromLeft;
    }
    
    return TuneMessageTransitionNone;
}

@end
