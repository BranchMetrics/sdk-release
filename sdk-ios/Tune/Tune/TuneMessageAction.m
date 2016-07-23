//
//  TuneMessageAction.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneMessageAction.h"
#import "TuneDeviceDetails.h"
#import "TuneSkyhookCenter.h"
#import "TuneSkyhookConstants.h"
#import "TuneSkyhookPayloadConstants.h"
#import "TuneUtils.h"

@implementation TuneMessageAction

- (void)performAction {
    if ([self.deepActionName length] > 0) {
        [self executeDeepAction];
    }
    else if ([self.url length] > 0) {
        [self gotoURL];
    }
}

- (void)gotoURL {
    __block NSURL *url = [NSURL URLWithString:_url];
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([TuneDeviceDetails appIsRunningIniOS10OrAfter]) {
#if IDE_XCODE_8_OR_HIGHER
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
#else
            // The openURL:options:completionHandler: method is not visible during
            // compile time when base iOS SDK < iOS 10.0, i.e. prior to Xcode 8.
            NSDictionary *dictOptions = @{};
            id dummyCompletionHandler = nil;

            SEL selOpenUrl = NSSelectorFromString(@"openURL:options:completionHandler:");
            NSMethodSignature *signature = [[UIApplication sharedApplication] methodSignatureForSelector:selOpenUrl];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:[UIApplication sharedApplication]];
            [invocation setSelector:selOpenUrl];
            [invocation setArgument:&url atIndex:2];
            [invocation setArgument:&dictOptions atIndex:3];
            [invocation setArgument:&dummyCompletionHandler atIndex:4];
            [invocation invoke];
#endif
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    });
}

- (void)executeDeepAction {
    // Queue up the power hook code block call until the sdk starts
    NSDictionary *payload = @{TunePayloadDeepActionId : self.deepActionName,
                              TunePayloadDeepActionData : [TuneUtils object:self.deepActionData orDefault:@{}]};
    [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneDeepActionTriggered object:nil userInfo:payload];
}

@end
