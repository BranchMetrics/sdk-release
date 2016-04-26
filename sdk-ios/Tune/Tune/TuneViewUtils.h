//
//  TuneViewUtils.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/1/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TuneViewUtils : NSObject

+ (void)setWidth:(CGFloat)width onView:(UIView *)view;
+ (void)setHeight:(CGFloat)height onView:(UIView *)view;

+ (void)setX:(CGFloat)x onView:(UIView *)view;
+ (void)setY:(CGFloat)y onView:(UIView *)view;

+ (void)centerHorizontallyInFrame:(CGRect)frame onView:(UIView *)view;
+ (void)centerVerticallyInFrame:(CGRect)frame onView:(UIView *)view;
+ (void)centerHorizontallyAndVerticallyInFrame:(CGRect)frame onView:(UIView *)view;

+ (CGFloat)rightXCoordinateOnView:(UIView *)view;
+ (CGFloat)bottomYCoordinateOnView:(UIView *)view;

@end
