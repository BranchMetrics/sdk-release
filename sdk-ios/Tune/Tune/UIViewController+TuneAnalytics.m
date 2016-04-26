//
//  UIViewController+TuneAnalytics.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/26/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#if !TARGET_OS_WATCH

#import "UIViewController+TuneAnalytics.h"
#import "UIViewController+NameTag.h"
#import <objc/runtime.h>
#import "TuneManager.h"
#import "TuneConfiguration.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookConstants.h"
#import "TuneState.h"

@implementation UIViewController (TuneAnalytics)

+ (void)load {
    if ([TuneState isTMADisabled]) { return; }
    
    if ([TuneState isSwizzleDisabled]) { return; }
    
    if ([TuneState isDisabledClass:@"UIViewController"]) {
        InfoLog(@"Skipping the `UIViewController#viewWillAppear:` Swizzle.");
        return;
    }
    
    if (![TuneState doSendScreenViews]) { return; }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class klass = [self class];
    
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(tune_viewWillAppear:);
    
        Method originalMethod = class_getInstanceMethod(klass, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(klass, swizzledSelector);

        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

-(void)tune_viewWillAppear:(BOOL)animated {
    if (![TuneState isDisabledClass:NSStringFromClass([self class])] && ![TuneState isSwizzleDisabled]) {
        InfoLog(@"viewWillAppear intercept Successful -- Class: %@, Screen Name: %@", NSStringFromClass([self class]), self.tuneScreenName);
        [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneViewControllerAppeared object:self];
    } else {
        InfoLog(@"Skipping viewWillAppear intercept for class: %@", NSStringFromClass([self class]));
    }

    [self tune_viewWillAppear:animated];
}

#pragma mark - Properties

- (NSString *)tuneScreenName {
    NSString *screenName = self.class.description;
    
    if (self.nameTag) {
        screenName = self.nameTag;
    }

    if (self.nibName.length) {
        screenName = [screenName stringByAppendingFormat:@"::%@", self.nibName];
    }

    return screenName;
}

@end

#endif
