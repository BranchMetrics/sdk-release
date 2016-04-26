//
//  UIViewController+NameTag.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 9/21/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "UIViewController+NameTag.h"
#import <objc/runtime.h>

static const char *nameTagKey = "nameTag";

@implementation UIViewController (NameTag)

@dynamic nameTag;

- (NSString *)nameTag {
    return objc_getAssociatedObject(self, nameTagKey);
}

- (void)setNameTag:(NSString *)newNameTag {
    objc_setAssociatedObject(self, nameTagKey, newNameTag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
