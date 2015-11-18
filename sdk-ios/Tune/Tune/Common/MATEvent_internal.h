//
//  MATEvent_internal.h
//  Tune
//
//  Created by Harshal Ogale on 5/5/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "../MATEvent.h"

@interface MATEvent ()

@property (nonatomic, copy, readonly) NSString *actionName;
@property (nonatomic, assign) BOOL postConversion;                  // KEY_POST_CONVERSION

@end
