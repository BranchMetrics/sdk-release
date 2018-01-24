//
//  TuneModalMessageView.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/10/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneBaseInAppMessageView.h"
#import "TuneMessageAction.h"

@interface TuneModalMessageView : TuneBaseInAppMessageView

@property (nonatomic, assign, readwrite) TuneModalMessageEdgeStyle edgeStyle;
@property (nonatomic, assign, readwrite) TuneMessageBackgroundMaskType backgroundMaskType;

@property (nonatomic, strong, readwrite) UIView *messageContainer;
@property (nonatomic, strong, readwrite) UIView *backgroundView;
@property (nonatomic, strong, readwrite) UIView *backgroundMaskView;
@property (nonatomic, strong, readwrite) NSNumber *width;
@property (nonatomic, strong, readwrite) NSNumber *height;


- (id)initWithPopUpMessageEdgeStyle:(TuneModalMessageEdgeStyle)edgeStyle;
- (void)show;

@end
