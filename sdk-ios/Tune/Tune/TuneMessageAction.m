//
//  TuneMessageAction.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/31/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneMessageAction.h"
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
    NSURL *url = [NSURL URLWithString:_url];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[UIApplication sharedApplication] openURL:url];
    });
}

- (void)executeDeepAction {
    // Queue up the power hook code block call until the sdk starts
    NSDictionary *payload = @{TunePayloadDeepActionId : self.deepActionName,
                              TunePayloadDeepActionData : [TuneUtils object:self.deepActionData orDefault:@{}]};
    [[TuneSkyhookCenter defaultCenter] postQueuedSkyhook:TuneDeepActionTriggered object:nil userInfo:payload];
}

@end
