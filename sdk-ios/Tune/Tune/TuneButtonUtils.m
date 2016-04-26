//
//  TuneButtonUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneButtonUtils.h"

// Taken from UIButton+ButtonMagic in Artisan SDK
@implementation TuneButtonUtils

+ (void)setBackgroundColor:(UIColor *)color forState:(UIControlState)state onButton:(UIButton *)button {
    [button setBackgroundImage:[TuneButtonUtils imageFromColor:color] forState:state];
}

+ (UIImage *)imageFromColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}



@end
