//
//  TuneInAppMessageAction.m
//  Tune
//
//  Created by John Gu on 10/2/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import "TuneInAppMessageAction.h"

@implementation TuneInAppMessageAction

NSString *const TUNE_ACTION_SCHEME = @"tune-action";

NSString *const TUNE_IN_APP_MESSAGE_DISMISS_ACTION = @"dismiss";
NSString *const TUNE_IN_APP_MESSAGE_ONDISPLAY_ACTION = @"onDisplay";
NSString *const TUNE_IN_APP_MESSAGE_ONDISMISS_ACTION = @"onDismiss";

- (NSString *)description {
    return [NSString stringWithFormat: @"TuneInAppMessageAction: Name=%@ Type=%lid Deeplink=%@ DeepActionName=%@ DeepActionData=%@", self.actionName, (long)self.type, self.url, self.deepActionName, self.deepActionData];
}

@end
