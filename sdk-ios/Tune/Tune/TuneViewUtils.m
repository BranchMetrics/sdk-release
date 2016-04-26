//
//  TuneViewUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/1/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneViewUtils.h"

@implementation TuneViewUtils

#pragma mark - Height + Width
+ (void)setWidth:(CGFloat)width onView:(UIView *)view {
    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, width, view.frame.size.height);
}

+ (void)setHeight:(CGFloat)height onView:(UIView *)view {
    view.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, height);
}

#pragma mark - X + Y
+ (void)setX:(CGFloat)x onView:(UIView *)view {
    view.frame = CGRectMake(x, view.frame.origin.y, view.frame.size.width, view.frame.size.height);
}

+ (void)setY:(CGFloat)y onView:(UIView *)view {
    view.frame = CGRectMake(view.frame.origin.x, y, view.frame.size.width, view.frame.size.height);
}

#pragma mark - Centering
+ (void)centerHorizontallyInFrame:(CGRect)frame onView:(UIView *)view {
    view.frame = CGRectMake( ceil((frame.size.width - view.frame.size.width)/2), view.frame.origin.y, view.frame.size.width, view.frame.size.height);
}

+ (void)centerVerticallyInFrame:(CGRect)frame onView:(UIView *)view {
    view.frame = CGRectMake(view.frame.origin.x, ceil((frame.size.height - view.frame.size.height)/2), view.frame.size.width, view.frame.size.height);
}

+ (void)centerHorizontallyAndVerticallyInFrame:(CGRect)frame onView:(UIView *)view {
    [TuneViewUtils centerHorizontallyInFrame:frame onView:view];
    [TuneViewUtils centerVerticallyInFrame:frame onView:view];
}

#pragma mark - Coordinates

+ (CGFloat)rightXCoordinateOnView:(UIView *)view {
    return view.frame.origin.x + view.frame.size.width;
}

+ (CGFloat)bottomYCoordinateOnView:(UIView *)view {
    return view.frame.origin.y + view.frame.size.height;
}

@end
