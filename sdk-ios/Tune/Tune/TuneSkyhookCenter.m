//
//  TuneSkyhookCenter.m
//  MobileAppTracker
//
//  Created by Matt Gowie on 7/22/15.
//  Copyright (c) 2015 TUNE. All rights reserved.
//

#import "TuneSkyhookCenter.h"

@implementation TuneSkyhookCenter

- (id)init {
    self = [super init];
    
    @autoreleasepool {
        if (self) {
            _hooks = [[NSMutableDictionary alloc] init];
            [self initSkyhookQueue];
        }
    }
    
    return self;
}

static TuneSkyhookCenter *defaultCenter = nil;

+ (TuneSkyhookCenter *)defaultCenter {
    @synchronized(self) {
        
        if (defaultCenter == nil) {
            defaultCenter = [[self alloc] init];

#if !TARGET_OS_WATCH
            // Proxy the NSNotificationCenter
            NSNotificationCenter *notifcationCenter = [NSNotificationCenter defaultCenter];

            UIApplication *application = [UIApplication sharedApplication];
            
            [notifcationCenter addObserver:defaultCenter selector:@selector(applicationDidBecomeActive:)
                                      name:UIApplicationDidBecomeActiveNotification object:application];
            [notifcationCenter addObserver:defaultCenter selector:@selector(applicationDidEnterBackground:)
                                      name:UIApplicationDidEnterBackgroundNotification object:application];
            [notifcationCenter addObserver:defaultCenter selector:@selector(applicationDidFinishLaunching:)
                                      name:UIApplicationDidFinishLaunchingNotification object:application];
            [notifcationCenter addObserver:defaultCenter selector:@selector(applicationWillTerminate:)
                                      name:UIApplicationWillTerminateNotification object:application];
            [notifcationCenter addObserver:defaultCenter selector:@selector(applicationWillResignActive:)
                                      name:UIApplicationWillResignActiveNotification object:application];
            [notifcationCenter addObserver:defaultCenter selector:@selector(applicationWillEnterForeground:)
                                      name:UIApplicationWillEnterForegroundNotification object:application];
            [notifcationCenter addObserver:defaultCenter selector:@selector(applicationLowMemory:)
                                      name:UIApplicationDidReceiveMemoryWarningNotification object:application];

#if TARGET_OS_IOS
            [notifcationCenter addObserver:defaultCenter selector:@selector(deviceOrientationDidChange:)
                                      name:UIDeviceOrientationDidChangeNotification object:nil];
            [notifcationCenter addObserver:defaultCenter selector:@selector(applicationStatusBarChanged:)
                                      name:UIApplicationWillChangeStatusBarOrientationNotification object:application];
#endif
            
            // Handle Session Start/End for managing Skyhook Queue
            [defaultCenter addObserver:defaultCenter
                              selector:@selector(handleSessionStart)
                                  name:TuneSessionManagerSessionDidStart
                                object:nil];

            [defaultCenter addObserver:defaultCenter
                              selector:@selector(handleSessionEnd)
                                  name:TuneSessionManagerSessionDidEnd
                                object:nil];
#endif
        }
        
        return defaultCenter;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Center Observing Itself

- (void)handleSessionStart {
    [self startSkyhookQueue];
}

- (void)handleSessionEnd {
    [self stopAndClearSkyhookQueue];
}

# pragma mark - Skyhook Queue Methods

- (void)clearSkyhookQueue {
    [_skyhookQueue cancelAllOperations];
}

- (void)initSkyhookQueue {
    _skyhookQueue = [NSOperationQueue new];
    [self stopSkyhookQueue];
    [_skyhookQueue setMaxConcurrentOperationCount:1];
}

- (void)stopSkyhookQueue {
    [_skyhookQueue setSuspended:YES];
}

- (void)stopAndClearSkyhookQueue {
    // If the skyhook queue is suspended (like in the case where the user comments out `startArtisan`)
    // and we call `waitUntilAllOperationsAreFinished` it will block indefinitely. So we only stop the
    // queue and block if it's running.
    if (!_skyhookQueue.suspended) {
        [self waitTilQueueFinishes];
        [self stopSkyhookQueue];
    }
    [self clearSkyhookQueue];
}
- (void)startSkyhookQueue {
    [_skyhookQueue setSuspended:NO];
}

- (void)waitTilQueueFinishes {
    [_skyhookQueue waitUntilAllOperationsAreFinished];
}

- (void)postQueuedSkyhook:(NSString *)hookName {
    [self postQueuedSkyhook:hookName object:nil userInfo:nil];
}

- (void)postQueuedSkyhook:(NSString *)hookName object:(id)hookSender {
    [self postQueuedSkyhook:hookName object:hookSender userInfo:nil];
}

- (void)postQueuedSkyhook:(NSString *)hookName object:(id)hookSender userInfo:(NSDictionary *)userInfo {
    TuneSkyhookPayload *payload = [[TuneSkyhookPayload alloc] initWithName:hookName object:hookSender userInfo:userInfo];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                            selector:@selector(postSkyhookOperation:)
                                                                              object:payload];
    [_skyhookQueue addOperation:operation];
}

- (void)postSkyhookOperation:(TuneSkyhookPayload *)payload {
    [self postSkyhook:payload.skyhookName object:payload.object userInfo:payload.userInfo];
}

# pragma mark - Observer Methods

- (void)addObserver:(id)hookObserver selector:(SEL)hookSelector name:(NSString *)hookName object:(id)hookSender priority:(int)priority {
    @synchronized(self) {
        NSMutableArray *observers = _hooks[hookName];
        if (observers == nil) {
            observers = [NSMutableArray array];
            _hooks[hookName] = observers;
        };
        
        __block long insertIndex = -1;
        
        [observers enumerateObjectsUsingBlock:^(TuneSkyhookObserver *observer, NSUInteger idx, BOOL *stop) {
            if (observer.priority > priority) {
                // The new observer should be added here
                insertIndex = idx;
                *stop = YES;
            }
        }];
        
        TuneSkyhookObserver *newObserver = [[TuneSkyhookObserver alloc] initWithObserver:hookObserver selector:hookSelector sender:hookSender priority:priority];
        
        if (insertIndex == -1) {
            // Just add it to the end
            [observers addObject:newObserver];
        } else {
            // Add it at the specified index
            [observers insertObject:newObserver atIndex:insertIndex];
        }
    }
}

- (void)addObserver:(id)hookObserver selector:(SEL)hookSelector name:(NSString *)hookName object:(id)hookSender {
    [self addObserver:hookObserver selector:hookSelector name:hookName object:hookSender priority:TuneSkyhookPriorityIrrelevant];
}

- (void)removeObserver:(id)hookObserver name:(NSString *)hookName object:(id)hookSender {
    @synchronized(self) {
        NSMutableArray *observers = _hooks[hookName];
        if (observers == nil) return;
        
        __block NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSet];
        
        [observers enumerateObjectsUsingBlock:^(TuneSkyhookObserver *observer, NSUInteger idx, BOOL *stop) {
            if (observer != nil && observer.observer != hookObserver) return;
            if (hookSender != nil && hookSender != observer.sender) return;
            
            [indexesToRemove addIndex:idx];
        }];
        
        [observers removeObjectsAtIndexes:indexesToRemove];
    }
}

- (void)removeObserver:(id)hookObserver {
    for (NSString *hookName in [_hooks allKeys]) {
        [self removeObserver:hookObserver name:hookName object:nil];
    }
}

/* Removes a specific TuneSkyhookObserver from a given hook */
- (void)removeSkyhookObserver:(TuneSkyhookObserver *)hookObserver name:(NSString *)hookName {
    @synchronized(self) {
        NSMutableArray *observers = _hooks[hookName];
        [observers removeObject:hookObserver];
    }
}

# pragma mark - Post Methods

- (void)postSkyhook:(NSString *)hookName {
    [self postSkyhook:hookName object:nil userInfo:nil];
}

- (void)postSkyhook:(NSString *)hookName object:(id)hookSender {
    [self postSkyhook:hookName object:hookSender userInfo:nil];
}

- (void)postSkyhook:(NSString *)hookName object:(id)hookSender userInfo:(NSDictionary *)userInfo {
    [self postSkyhook:hookName object:hookSender userInfo:userInfo returnedObjectBlock:nil];
}

- (void)postSkyhook:(NSString *)hookName object:(id)hookSender userInfo:(NSDictionary *)userInfo returnedObjectBlock:(void (^)(id))returnedObjectBlock {
    NSMutableArray *observers;
    
    @synchronized(self) {
        observers = [_hooks[hookName] copy];
    }
    
    if (observers == nil) return;
    
    TuneSkyhookPayload *payload = [[TuneSkyhookPayload alloc] initWithName:hookName object:hookSender userInfo:userInfo];
    
    for (TuneSkyhookObserver *observer in observers) {
        // If the observer is no longer valid, remove it from the list automatically
        if (![observer isStillValid]) {
            [self removeSkyhookObserver:observer name:hookName];
        } else if ([observer matchesSender:hookSender]) {
            [observer sendPayload:payload];
            
            if (returnedObjectBlock) {
                returnedObjectBlock(payload.returnObject);
            }
            
            payload.returnObject = nil;
        }
    }
}

- (BOOL)hasObserverForHook:(NSString *)hookName {
    return [_hooks[hookName] count] != 0;
}

- (NSString *)debugHook:(NSString *)hookName {
    NSDictionary *hooks = nil;
    
    @synchronized(self) {
        hooks = [_hooks copy];
    }
    
    __block NSString *returnString = @"";
    
    [hooks enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSArray *observers, BOOL *stop) {
        if ((hookName == nil || [hookName isEqualToString:name]) && observers.count > 0) {
            NSString *hookString = [NSString stringWithFormat:@"Skyhook: %@\n", name];
            
            for (TuneSkyhookObserver *observer in observers) {
                NSString *observerString = [NSString stringWithFormat:@"\t- Priority: %d\n\t  Observer: %@\n\t  Selector: %@\n\t  Object: %@\n", observer.priority, observer.observer, NSStringFromSelector(observer.selector), observer.sender];
                hookString = [hookString stringByAppendingString:observerString];
            }
            
            returnString = [returnString stringByAppendingString:hookString];
        }
    }];
    
    if (!returnString.length) return @"No hooks registered";
    
    return returnString;
}

#pragma mark - Notification propagation

#if !TARGET_OS_WATCH

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [self postSkyhook:UIApplicationDidBecomeActiveNotification object:nil];
}
- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self postSkyhook:UIApplicationDidEnterBackgroundNotification object:nil];
}
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self postSkyhook:UIApplicationDidFinishLaunchingNotification object:nil];
}
- (void)applicationWillTerminate:(NSNotification *)notification {
    [self postSkyhook:UIApplicationWillTerminateNotification object:nil];
}
- (void)applicationWillResignActive:(NSNotification *)notification {
    [self postSkyhook:UIApplicationWillResignActiveNotification object:nil];
}
- (void)applicationWillEnterForeground:(NSNotification *)notification {
    [self postSkyhook:UIApplicationWillEnterForegroundNotification object:nil];
}
- (void)applicationLowMemory:(NSNotification *)notification {
    [self postSkyhook:UIApplicationDidReceiveMemoryWarningNotification object:nil];
}

#endif

#if TARGET_OS_IOS

- (void)deviceOrientationDidChange:(NSNotification *)notification {
    [self postSkyhook:UIDeviceOrientationDidChangeNotification object:nil];
}
- (void)applicationStatusBarChanged:(NSNotification *)notification {
    [self postSkyhook:UIApplicationWillChangeStatusBarOrientationNotification object:nil userInfo:notification.userInfo];
}

#endif

#pragma mark - Testing Helpers

#if TESTING
+ (void)nilDefaultCenter {
    defaultCenter = nil;
}
#endif

@end
