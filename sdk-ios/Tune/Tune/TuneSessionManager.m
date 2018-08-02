//
//  TuneSessionManager.m
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/17/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneModule.h"
#import "TuneManager.h"
#import "TuneSessionManager.h"
#import "TuneUtils.h"
#import "TuneFileUtils.h"
#import "TuneSkyhookConstants.h"
#import "TuneSkyhookCenter.h"
#import "TuneUserProfile.h"

@interface TuneSessionManager ()

@property (readonly) BOOL sessionStarted;
@property (readonly) NSDate *sessionStartTime;
@property (readonly) NSString *sessionId;

@end

@implementation TuneSessionManager

- (id)initWithTuneManager:(TuneManager *)tuneManager {
    self = [super initWithTuneManager:tuneManager];
    
    return self;
}

// These methods don't need an implementation since this module must always be up
- (void)bringUp {}
- (void)bringDown {}

- (void)registerSkyhooks {
    
    [self unregisterSkyhooks];
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(applicationStateChanged)
                                              name:UIApplicationWillTerminateNotification
                                            object:nil];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(applicationWillEnterForeground)
                                              name:UIApplicationWillEnterForegroundNotification
                                            object:nil];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(applicationStateChanged)
                                              name:UIApplicationWillEnterForegroundNotification
                                            object:nil];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(applicationStateChanged)
                                              name:UIApplicationDidEnterBackgroundNotification
                                            object:nil];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(applicationStateChanged)
                                              name:UIApplicationWillResignActiveNotification
                                            object:nil];
    
    [[TuneSkyhookCenter defaultCenter] addObserver:self
                                          selector:@selector(applicationStateChanged)
                                              name:UIApplicationDidBecomeActiveNotification
                                            object:nil];
}

#pragma mark - Private Methods

- (void)applicationWillEnterForeground {

}

- (void)applicationStateChanged {
    [self applicationStateChangedWithCompletion:^(BOOL isActive) {
        if (isActive) {
            [self startSession];
        } else {
            [self endSession];
        }
    }];
}

// This method calls the completion block on Main Thread!  If it's expensive do a dispatch async to a background thread.
- (void)applicationStateChangedWithCompletion:(void(^)(BOOL isActive))completion {
    
    // UIApplication should be called on main, it's a UI class
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            if (completion) {
                completion(YES);
            }
        } else if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            if (completion) {
                completion(NO);
            }
        }
    });
}

// Starts a session. This may be called multiple times, but it
// only starts a session if one hasn't been started already.
- (void)startSession {
    @synchronized(self) {
        if (self.sessionStarted) return;
        
        NSDate *sessionStartTime = [NSDate date];
        NSString *sessionId = [NSString stringWithFormat:@"t%0.f-%@", [sessionStartTime timeIntervalSince1970], [TuneUtils getUUID]];
        
        _sessionId = sessionId;
        _sessionStartTime = sessionStartTime;
        
        [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart object:self userInfo:@{@"sessionId": self.sessionId, @"sessionStartTime": self.sessionStartTime}];
    }
}

- (void)endSession {
    @synchronized(self) {
        if (!self.sessionStarted) return;
                
        NSString *currentId = self.sessionId;
        NSTimeInterval sessionLength = [self timeSinceSessionStart];
        NSDate *startTime = self.sessionStartTime;
        NSDictionary *userInfo = @{@"sessionId": currentId ?: @"", @"sessionLength": @(sessionLength), @"sessionStartTime": startTime ?: [NSDate date]};
        
        [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidEnd object:self userInfo:userInfo];
        
        _sessionId = nil;
        _sessionStartTime = nil;
    }
}

- (BOOL)sessionStarted {
    if (self.sessionId && self.sessionId.length > 0) {
        return YES;
    }
    return NO;
}

- (NSTimeInterval)timeSinceSessionStart {
    if (self.sessionStartTime) {
        return -1*[self.sessionStartTime timeIntervalSinceNow];
    } else {
        return 0;
    }
}

@end
