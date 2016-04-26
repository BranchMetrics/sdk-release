//
//  TuneMessageLabel.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessageConstants.h"

@interface TuneMessageLabel : NSObject {
    BOOL _headlineLabel;
    BOOL _buttonLabel;
}

@property (nonatomic, copy) NSDictionary *labelDictionary;
@property (nonatomic, copy) NSString *text;
@property (nonatomic) NSTextAlignment alignment;
@property (strong, nonatomic) UIColor *textColor;
@property (strong, nonatomic) UIFont *font;
@property (nonatomic, copy) NSString *fontName;
@property (nonatomic) TuneMessageType messageType;
@property (nonatomic) TuneMessageButtonType buttonType;
@property (nonatomic) TuneMessageDeviceOrientation orientation;


- (id)initWithLabelDictionary:(NSDictionary *)labelDictionary
               andMessageType:(TuneMessageType)messageType;

- (id)initWithHeadlineLabelDictionary:(NSDictionary *)labelDictionary
                          messageType:(TuneMessageType)messageType;

- (id)initWithButtonLabelDictionary:(NSDictionary *)labelDictionary
                     andMessageType:(TuneMessageType)messageType
               andMessageButtonType:(TuneMessageButtonType)buttonType;

- (id)initWithLabelDictionary:(NSDictionary *)labelDictionary
                  messageType:(TuneMessageType)messageType
               andOrientation:(TuneMessageDeviceOrientation)orientation;

- (UILabel *)getUILabelWithFrame:(CGRect)frame;


@end
