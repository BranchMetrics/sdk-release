//
//  TuneImageUtils.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/8/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneImageUtils.h"

@implementation TuneImageUtils

+ (UIImage *)imageFromDataURI:(NSString *)dataUri {
    NSURL *url = [NSURL URLWithString:dataUri];
    NSData *imageData = [NSData dataWithContentsOfURL:url];
    return [UIImage imageWithData:imageData];
}

@end
