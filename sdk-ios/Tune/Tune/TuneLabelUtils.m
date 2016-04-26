//
//  TuneLabelUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/10/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneLabelUtils.h"

@implementation TuneLabelUtils

+ (CGSize)actualTextSizeOnLabel:(UILabel *)label {
    return [TuneLabelUtils actualTextSizeConstrainedByWidth:label.frame.size.width
                                                  andHeight:label.frame.size.height
                                                    onLabel:label];
}

#if TARGET_OS_IOS

+ (CGSize)actualTextSizeConstrainedByWidth:(CGFloat)width andHeight:(CGFloat)height onLabel:(UILabel *)label {
    CGSize actualTextSize;
    if ([[UIDevice currentDevice].systemVersion floatValue] < 7.0) {
        // We know this is deprecated but the boundingRectWithSize we're using is only in iOS7 or greater
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        actualTextSize = [label.text sizeWithFont:label.font
                               constrainedToSize:CGSizeMake(width,height)
                                   lineBreakMode:label.lineBreakMode];
#pragma clang diagnostic pop
    }
    else {
        actualTextSize = [label.text boundingRectWithSize:CGSizeMake(width,height)
                                                  options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                               attributes:@{NSFontAttributeName:label.font}
                                                  context:nil].size;
    }
    
    return CGSizeMake(ceil(actualTextSize.width), ceil(actualTextSize.height));
}

#else

+ (CGSize)actualTextSizeConstrainedByWidth:(CGFloat)width andHeight:(CGFloat)height onLabel:(UILabel *)label {
    CGSize actualTextSize = [label.text boundingRectWithSize:CGSizeMake(width,height)
                                                     options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                                  attributes:@{NSFontAttributeName:label.font}
                                                     context:nil].size;
    
    return CGSizeMake(ceil(actualTextSize.width), ceil(actualTextSize.height));
}

#endif

+ (void)adjustFrameHeightToTextHeightOnLabel:(UILabel *)label {
    CGSize labelActualTextSize = [TuneLabelUtils actualTextSizeOnLabel:label];
    label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, label.frame.size.width, labelActualTextSize.height);
}

@end
