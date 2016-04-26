//
//  TuneSkyhookPayload.m
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneSkyhookPayload.h"

@implementation TuneSkyhookPayload

- (id)initWithName:(NSString *)skyhookName object:(id)skyhookObject userInfo:(NSDictionary *)userInfo {
    self = [self init];
    
    if (self) {
        _skyhookName = skyhookName;
        _object = skyhookObject;
        _userInfo = [userInfo copy];
        _returnObject = nil;
    }
    
    return self;
}

@end
