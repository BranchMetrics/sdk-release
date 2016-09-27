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
#import "TuneState.h"

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
    UIApplication *application = [UIApplication sharedApplication];
    
    if (application.applicationState == UIApplicationStateActive) {
        [self startSession];
    } else if (application.applicationState == UIApplicationStateBackground) {
        [self endSession];
    }
}

// Starts a session. This may be called multiple times, but it
// only starts a session if one hasn't been started already.
- (void)startSession {
    @synchronized(self) {
        if (self.sessionStarted) return;
        
        NSDate *sessionStartTime = [NSDate date];
        NSString *sessionId = [NSString stringWithFormat:@"t%0.f-%@", [sessionStartTime timeIntervalSince1970], [TuneUtils getUUID]];
        
        // Don't update is_first_session if we are disabled because it won't get received by us.
        if (![TuneState isTMADisabled]) {
            // If this value wasn't stored in NSUserDefaults then we know that this is their first session ever
            // Otherwise, they have already had their first session, since it got stored here.
            if ([[TuneManager currentManager].userProfile isFirstSession] == nil) {
                [[TuneManager currentManager].userProfile setIsFirstSession:@(1)];
            } else {
                [[TuneManager currentManager].userProfile setIsFirstSession:@(0)];
            }
        }
        
        _sessionId = sessionId;
        _sessionStartTime = sessionStartTime;
        
        [[TuneSkyhookCenter defaultCenter] postSkyhook:TuneSessionManagerSessionDidStart object:self userInfo:@{@"sessionId": self.sessionId, @"sessionStartTime": self.sessionStartTime}];
    }
}

- (void)endSession {
    @synchronized(self) {
        if (!self.sessionStarted) return;
        
        self.lastOpenedPushNotification = nil;
        
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
    return !!self.sessionId.length;
}

- (NSTimeInterval)timeSinceSessionStart {
    if (self.sessionStartTime) {
        return -1*[self.sessionStartTime timeIntervalSinceNow];
    } else {
        return 0;
    }
}

@end
