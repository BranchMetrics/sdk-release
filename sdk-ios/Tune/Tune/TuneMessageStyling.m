//
//  TuneMessageStyling.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneMessageStyling.h"
#import "TuneSlideInMessageDefaults.h"
#import "TunePopUpMessageDefaults.h"
#import "TuneButtonUtils.h"
#import "TuneImageAssets.h"
#import "TuneDeviceDetails.h"
#import "TuneImageUtils.h"

@implementation TuneMessageStyling

#pragma mark - Buttons

+ (UIButton *)createBaseUIButtonForMessageType:(TuneMessageType)messageType {
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button layoutIfNeeded];
    
    switch (messageType) {
        case TuneMessageTypePopup:
            button.titleLabel.font = [TunePopUpMessageDefaults popUpMessageDefaultCtaButtonFont];
            [button setTitleColor:[TunePopUpMessageDefaults popUpMessageDefaultCtaButtonTextColor] forState:UIControlStateNormal];
            [TuneButtonUtils setBackgroundColor:[TunePopUpMessageDefaults popUpMessageDefaultCtaButtonBackgroundColor] forState:UIControlStateNormal onButton:button];
            break;
            
        case TuneMessageTypeSlideIn:
            button.titleLabel.font = [TuneSlideInMessageDefaults slideInMessageDefaultButtonFont];
            [button setTitleColor:[TuneSlideInMessageDefaults slideInMessageDefaultButtonTextColor] forState:UIControlStateNormal];
            [TuneButtonUtils setBackgroundColor:[TuneSlideInMessageDefaults slideInMessageDefaultButtonBackgroundColor] forState:UIControlStateNormal onButton:button];
            break;
            
        case TuneMessageTypeTakeOver:
            break;
    }
    
    return button;
}

+ (UIImage *)closeButtonImageByCloseButtonColor:(TuneMessageCloseButtonColor)closeButtonColor {
    NSString *closeButtonImageData = @"";
    
    if ([TuneDeviceDetails isRetina]) {
        switch (closeButtonColor) {
            case TunePopUpMessageCloseButtonColorRed:
                closeButtonImageData = TuneCloseButtonRedRetina;
                break;
            case TunePopUpMessageCloseButtonColorBlack:
                closeButtonImageData = TuneCloseButtonBlackRetina;
                break;
            case TuneSlideInMessageCloseButtonColorWhite:
                closeButtonImageData = TuneCloseButtonSimpleWhiteRetina;
                break;
            case TuneSlideInMessageCloseButtonColorBlack:
                closeButtonImageData = TuneCloseButtonSimpleRetina;
                break;
            case TuneTakeOverMessageCloseButtonColorRed:
                closeButtonImageData = TuneCloseButtonRedRetina;
                break;
            case TuneTakeOverMessageCloseButtonColorBlack:
                closeButtonImageData = TuneCloseButtonBlackRetina;
                break;
            default:
                closeButtonImageData = TuneCloseButtonRedRetina;
                break;
        }
    } else {
        switch (closeButtonColor) {
            case TunePopUpMessageCloseButtonColorRed:
                closeButtonImageData = TuneCloseButtonRed;
                break;
            case TunePopUpMessageCloseButtonColorBlack:
                closeButtonImageData = TuneCloseButtonBlack;
                break;
            case TuneSlideInMessageCloseButtonColorWhite:
                closeButtonImageData = TuneCloseButtonSimpleWhite;
                break;
            case TuneSlideInMessageCloseButtonColorBlack:
                closeButtonImageData = TuneCloseButtonSimple;
                break;
            case TuneTakeOverMessageCloseButtonColorRed:
                closeButtonImageData = TuneCloseButtonRed;
                break;
            case TuneTakeOverMessageCloseButtonColorBlack:
                closeButtonImageData = TuneCloseButtonBlack;
                break;
            default:
                closeButtonImageData = TuneCloseButtonRed;
                break;
        }
    }
    
    return [TuneImageUtils imageFromDataURI:closeButtonImageData];
}

#pragma mark - Labels

+ (UILabel *)createBaseMessageUILabelForMessageType:(TuneMessageType)messageType andOrientation:(TuneMessageDeviceOrientation)orientation {
    UILabel *messageLabel =  [[UILabel alloc] init];
    
    switch (messageType) {
        case TuneMessageTypePopup:
            messageLabel.font = [TunePopUpMessageDefaults popUpMessageDefaultBodyFont];
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = [TunePopUpMessageDefaults popUpMessageDefaultBodyTextAlignment];
            messageLabel.textColor = [TunePopUpMessageDefaults popUpMesasgeDefaultBodyTextColor];
            messageLabel.backgroundColor = [UIColor clearColor];
            break;
        case TuneMessageTypeSlideIn:
            messageLabel.font = [TuneSlideInMessageDefaults slideInMessageDefaultMessageFontByDeviceOrientation:orientation];
            messageLabel.numberOfLines = [TuneSlideInMessageDefaults slideInMesasgeDefaultMessageNumberOfLinesByDeviceOrientation:orientation];
            messageLabel.textAlignment = [TuneSlideInMessageDefaults slideInMessageDefaultMessageTextAlignment];
            messageLabel.textColor = [TuneSlideInMessageDefaults slideInMesasgeDefaultMessageTextColor];
            messageLabel.backgroundColor = [UIColor clearColor];
            break;
            
        case TuneMessageTypeTakeOver:
            break;
    }
    
    return messageLabel;
}

+ (UILabel *)createBaseMessageUILabelForMessageType:(TuneMessageType)messageType {
    return [TuneMessageStyling createBaseMessageUILabelForMessageType:messageType andOrientation:TuneMessageOrientationNA];
}

+ (UILabel *)createBaseMessageBoldUILabelForMessageType:(TuneMessageType)messageType {
    return [TuneMessageStyling createBaseMessageHeadlineUILabelForMessageType:messageType];
}

+ (UILabel *)createBaseMessageBoldUILabelForMessageType:(TuneMessageType)messageType andOrientation:(TuneMessageDeviceOrientation)orientation {
    UILabel *messageLabel =  [[UILabel alloc] init];
    
    switch (messageType) {
        case TuneMessageTypePopup:
            messageLabel.font = [TunePopUpMessageDefaults popUpMessageDefaultHeadlineFont];
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = [TunePopUpMessageDefaults popUpMessageDefaultHeadlineTextAlignment];
            messageLabel.textColor = [TunePopUpMessageDefaults popUpMesasgeDefaultHeadlineTextColor];
            break;
        case TuneMessageTypeSlideIn:
            // Not Applicable at the moment
            break;
            
        case TuneMessageTypeTakeOver:
            break;
    }
    
    return messageLabel;
    
}

+ (UILabel *)createBaseMessageHeadlineUILabelForMessageType:(TuneMessageType)messageType andOrientation:(TuneMessageDeviceOrientation)orientation {
    return [TuneMessageStyling createBaseMessageBoldUILabelForMessageType:messageType andOrientation:orientation];
}

+ (UILabel *)createBaseMessageHeadlineUILabelForMessageType:(TuneMessageType)messageType {
    return [TuneMessageStyling createBaseMessageBoldUILabelForMessageType:messageType andOrientation:TuneMessageOrientationNA];
}

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
