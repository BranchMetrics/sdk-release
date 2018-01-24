//
//  TuneInAppMessageAction.h
//  Tune
//
//  Created by John Gu on 10/2/17.
//  Copyright © 2017 Tune. All rights reserved.
//

#import "TuneMessageAction.h"

@interface TuneInAppMessageAction : TuneMessageAction

FOUNDATION_EXPORT NSString *const TUNE_ACTION_SCHEME;

FOUNDATION_EXPORT NSString *const TUNE_IN_APP_MESSAGE_DISMISS_ACTION;
FOUNDATION_EXPORT NSString *const TUNE_IN_APP_MESSAGE_ONDISPLAY_ACTION;
FOUNDATION_EXPORT NSString *const TUNE_IN_APP_MESSAGE_ONDISMISS_ACTION;

typedef NS_ENUM(NSInteger, TuneActionType) {
    TuneActionTypeDeeplink,
    TuneActionTypeDeepAction,
    TuneActionTypeClose
};

@property (nonatomic, copy) NSString *actionName;
@property (nonatomic, assign) TuneActionType type;

@end
