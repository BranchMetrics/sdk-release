//
//  TuneMessageLabel.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneMessageLabel.h"
#import "TuneInAppUtils.h"
#import "TuneSlideInMessageDefaults.h"
#import "TuneMessageStyling.h"
#import "TuneMessageLabel.h"
#import "TunePopUpMessageDefaults.h"

@implementation TuneMessageLabel

- (id)initWithLabelDictionary:(NSDictionary *)labelDictionary andMessageType:(TuneMessageType)messageType {
    
    self = [super init];
    
    if(self)
    {
        self.messageType = messageType;
        self.buttonType = TuneMessageButtonTypeNA;
        self.orientation = TuneMessageOrientationNA;
        self.labelDictionary = labelDictionary;
        _headlineLabel = NO;
        _buttonLabel = NO;
        [self findProperties];
        [self buildLabel];
    }
    return self;
}


- (id)initWithHeadlineLabelDictionary:(NSDictionary *)labelDictionary messageType:(TuneMessageType)messageType {
    
    self = [super init];
    
    if(self)
    {
        self.messageType = messageType;
        self.buttonType = TuneMessageButtonTypeNA;
        self.orientation = TuneMessageOrientationNA;
        self.labelDictionary = labelDictionary;
        _headlineLabel = YES;
        _buttonLabel = NO;
        [self findProperties];
        [self buildLabel];
    }
    return self;
}

- (id)initWithButtonLabelDictionary:(NSDictionary *)labelDictionary andMessageType:(TuneMessageType)messageType andMessageButtonType:(TuneMessageButtonType)buttonType {
    self = [super init];
    
    if(self)
    {
        self.messageType = messageType;
        self.buttonType = buttonType;
        self.orientation = TuneMessageOrientationNA;
        self.labelDictionary = labelDictionary;
        _headlineLabel = NO;
        _buttonLabel = YES;
        [self findProperties];
        [self buildLabel];
    }
    return self;
}

- (id)initWithLabelDictionary:(NSDictionary *)labelDictionary messageType:(TuneMessageType)messageType andOrientation:(TuneMessageDeviceOrientation)orientation {
    
    self = [super init];
    
    if(self)
    {
        self.messageType = messageType;
        self.buttonType = TuneMessageButtonTypeNA;
        self.orientation = orientation;
        self.labelDictionary = labelDictionary;
        _headlineLabel = NO;
        _buttonLabel = NO;
        [self findProperties];
        [self buildLabel];
    }
    return self;
}

- (void)findProperties {
    // text
    self.text = [TuneInAppUtils getTextFromDictionary:self.labelDictionary];
    
    UIFont *defaultFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:14];
    
    switch (self.messageType) {
        case TuneMessageTypePopup:
            if (_headlineLabel) {
                defaultFont = [TunePopUpMessageDefaults popUpMessageDefaultHeadlineFont];
            }
            else if (_buttonLabel) {
                if (_buttonType == TuneMessageButtonTypeCta) {
                    defaultFont = [TunePopUpMessageDefaults popUpMessageDefaultCtaButtonFont];
                } else {
                    defaultFont = [TunePopUpMessageDefaults popUpMessageDefaultCancelButtonFont];
                }
            }
            else {
                defaultFont = [TunePopUpMessageDefaults popUpMessageDefaultBodyFont];
            }
            break;
        case TuneMessageTypeSlideIn:
            defaultFont = [TuneSlideInMessageDefaults slideInMessageDefaultMessageFontByDeviceOrientation:_orientation];
            break;
        case TuneMessageTypeTakeOver:
            // NA
            break;
        default:
            break;
    }
    
    // alignment
    if ([TuneInAppUtils propertyIsNotEmpty:[TuneInAppUtils getAlignmentStringFromDictionary:self.labelDictionary]]) {
        self.alignment = [TuneInAppUtils getTextAlignmentFromDictionary:self.labelDictionary];
    }
    else {
        self.alignment = NSTextAlignmentLeft;
        switch (self.messageType) {
            case TuneMessageTypePopup:
                if (_headlineLabel) {
                    self.alignment = [TunePopUpMessageDefaults popUpMessageDefaultHeadlineTextAlignment];
                }
                else {
                    self.alignment = [TunePopUpMessageDefaults popUpMessageDefaultBodyTextAlignment];
                }
                break;
            case TuneMessageTypeSlideIn:
                self.alignment = [TuneSlideInMessageDefaults slideInMessageDefaultMessageTextAlignment];
                break;
            case TuneMessageTypeTakeOver:
                break;
        }
    }
    
    // textColor
    self.textColor = [TuneInAppUtils getTextColorFromDictionary:self.labelDictionary];
    
    if (!self.textColor) {
        switch (self.messageType) {
            case TuneMessageTypePopup:
                if (_headlineLabel) {
                    self.textColor = [TunePopUpMessageDefaults popUpMesasgeDefaultHeadlineTextColor];
                } else if (_buttonLabel) {
                    if (_buttonType == TuneMessageButtonTypeCta) {
                        self.textColor = [TunePopUpMessageDefaults popUpMessageDefaultCtaButtonTextColor];
                    } else {
                        self.textColor = [TunePopUpMessageDefaults popUpMessageDefaultCancelButtonTextColor];
                    }
                } else {
                    self.textColor = [TunePopUpMessageDefaults popUpMesasgeDefaultBodyTextColor];
                }
                break;
            case TuneMessageTypeSlideIn:
                self.textColor = [TuneSlideInMessageDefaults slideInMesasgeDefaultMessageTextColor];
                break;
            case TuneMessageTypeTakeOver:
                break;
        }
    }
    
    // font
    self.font = [TuneInAppUtils getFontFromDictionary:self.labelDictionary withDefault:defaultFont];
}

- (UILabel *)buildLabel {
    UILabel *label;
    
    // Build the base default label
    if (_headlineLabel) {
        label = [TuneMessageStyling createBaseMessageBoldUILabelForMessageType:self.messageType];
    }
    else {
        label = [TuneMessageStyling createBaseMessageUILabelForMessageType:self.messageType];
    }
    
    // Text
    label.text = self.text;
    
    // Text Color
    label.textColor = self.textColor;
    
    // Font
    label.font = self.font;
    
    // Alignment
    label.textAlignment = self.alignment;
    
    return label;
}

- (UILabel *)getUILabelWithFrame:(CGRect)frame {
    UILabel *label = [self buildLabel];
    label.frame = frame;
    return label;
}

@end
