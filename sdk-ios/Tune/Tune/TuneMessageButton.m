//
//  TuneMessageButton.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneMessageButton.h"
#import "TuneSlideInMessageDefaults.h"
#import "TunePopUpMessageDefaults.h"
#import "TuneInAppUtils.h"
#import "TuneMessageStyling.h"
#import "TuneButtonUtils.h"

@implementation TuneMessageButton

- (id)initWithButtonlDictionary:(NSDictionary *)buttonDictionary andMessageType:(TuneMessageType)messageType {
    return [self initWithButtonlDictionary:buttonDictionary andMessageType:messageType andMessageButtonType:TuneMessageButtonTypeNA];
}

- (id)initWithButtonlDictionary:(NSDictionary *)buttonDictionary andMessageType:(TuneMessageType)messageType andMessageButtonType:(TuneMessageButtonType)buttonType {
    self = [super init];
    
    if(self)
    {
        self.buttonDictionary = buttonDictionary;
        self.messageType = messageType;
        self.buttonType = buttonType;
        [self findProperties];
    }
    return self;
}

- (void)findProperties {
    // title
    if ([TuneInAppUtils propertyIsNotEmpty:[TuneInAppUtils getTitleFromDictionary:self.buttonDictionary]]) {
        self.title = [[TuneMessageLabel alloc] initWithButtonLabelDictionary:[TuneInAppUtils getTitleFromDictionary:self.buttonDictionary] andMessageType:self.messageType andMessageButtonType:self.buttonType];
    }
    
    // buttonColor
    self.buttonColor = [TuneInAppUtils getButtonColorFromDictionary:self.buttonDictionary];
    
    if (!self.buttonColor) {
        switch (_messageType) {
            case TuneMessageTypePopup:
                if (_buttonType == TuneMessageButtonTypeCta) {
                    self.buttonColor = [TunePopUpMessageDefaults popUpMessageDefaultCtaButtonBackgroundColor];
                } else if (_buttonType == TuneMessageButtonTypeCancel) {
                    self.buttonColor = [TunePopUpMessageDefaults popUpMessageDefaultCancelButtonBackgroundColor];
                }
                break;
            case TuneMessageTypeSlideIn:
                self.buttonColor = [TuneSlideInMessageDefaults slideInMessageDefaultButtonBackgroundColor];
                break;
            case TuneMessageTypeTakeOver:
                break;
        }
    }
    
    // action
    self.action = [TuneInAppUtils getDeviceAppropriateActionFromDictionary:self.buttonDictionary[@"actions"]];
    
    // backgroundImage
    self.backgroundImage = [TuneInAppUtils getBackgroundImageFromDictionary:self.buttonDictionary];
}

- (UIButton *)buildButton {
    
    UIButton *button = [TuneMessageStyling createBaseUIButtonForMessageType:self.messageType];
    
    if (self.title) {
        [button setTitle:self.title.text forState:UIControlStateNormal];
        [button setTitleColor:self.title.textColor forState:UIControlStateNormal];
        button.titleLabel.font = self.title.font;
    }
    
    // Button Color and Background Image are mutally exclusive because of how the button is built
    if (self.backgroundImage) {
        [button setBackgroundImage:self.backgroundImage forState:UIControlStateNormal];
    } else if (self.buttonColor) {
        [TuneButtonUtils setBackgroundColor:self.buttonColor forState:UIControlStateNormal onButton:button];
    }
    
    return button;
}

- (UIButton *)getUIButtonWithFrame:(CGRect)frame {
    UIButton *button = [self buildButton];
    button.frame = frame;
    return button;
}

@end
