//
//  TuneMessageButton.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneInAppMessageConstants.h"
#import "TuneMessageLabel.h"
#import "TuneMessageAction.h"

@interface TuneMessageButton : NSObject

@property (nonatomic, copy) NSDictionary *buttonDictionary;
@property (strong, nonatomic) TuneMessageLabel *title;
@property (strong, nonatomic) UIColor *buttonColor;
@property (strong, nonatomic) TuneMessageAction *action;
@property (strong, nonatomic) UIImage *backgroundImage;
@property (nonatomic) TuneMessageType messageType;
@property (nonatomic) TuneMessageButtonType buttonType;

- (id)initWithButtonlDictionary:(NSDictionary *)buttonDictionary andMessageType:(TuneMessageType)messageType;

- (id)initWithButtonlDictionary:(NSDictionary *)buttonDictionary andMessageType:(TuneMessageType)messageType andMessageButtonType:(TuneMessageButtonType)buttonType;

- (UIButton *)getUIButtonWithFrame:(CGRect)frame;

@end
