//
//  TuneManager.m
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneManager.h"

#import "TuneSessionManager.h"
#import "TuneSkyhookCenter.h"
#import "TuneUserProfile.h"
#import "TuneSkyhookPayload.h"
#import "TuneSkyhookConstants.h"
#import "TuneFileManager.h"
#import "TuneUserDefaultsUtils.h"

@implementation TuneManager

// This is NOT recommended by Apple
+ (void)initialize {
    [[TuneManager sharedInstance] instantiateModules];
}

// ObjC singletons are usually named sharedSomething or just shared.  For example:  [UIApplication sharedApplication]
// Eventually switch to using just sharedInstance
+ (TuneManager *)currentManager {
    return [self sharedInstance];
}

+ (TuneManager *)sharedInstance {
    static TuneManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [TuneManager new];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)instantiateModules {
    [self instantiateAAModules];
}

- (void)instantiateAAModules {
    self.userProfile = [TuneUserProfile moduleWithTuneManager:self];
    [self.userProfile registerSkyhooks];
    
    self.sessionManager = [TuneSessionManager moduleWithTuneManager:self];
    [self.sessionManager registerSkyhooks];
}

#pragma mark - Skyhook management

- (void)registerSkyhooks {
    [[TuneSkyhookCenter defaultCenter] removeObserver:self];
    [[TuneSkyhookCenter defaultCenter] addObserver:self selector:@selector(handleSaveUserDefaults:) name:TuneSessionManagerSessionDidEnd object:nil];
}

#pragma mark - Handle NSUserDefaults Saving

- (void)handleSaveUserDefaults:(TuneSkyhookPayload*)payload {
    [TuneUserDefaultsUtils synchronizeUserDefaults];
}

#pragma mark - Testing Helpers

#if TESTING
- (void)nilModules {
    /* WARNING! This module may not be wholey safe.  It is used for the enable/disable/permanently-disable tests since they need a fresh slate for each test. */
    [self.userProfile unregisterSkyhooks];
    [self.sessionManager unregisterSkyhooks];
    
    self.userProfile = nil;
    self.sessionManager = nil;
}
#endif

@end
