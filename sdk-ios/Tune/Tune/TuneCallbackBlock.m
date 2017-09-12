//
//  TuneCallbackBlock.m
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/30/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneCallbackBlock.h"

@implementation TuneCallbackBlock

- (id)initWithCallbackBlock:(void(^)(void))callbackBlock fireOnce:(BOOL)shouldFireOnce {
    self = [self init];
    if (self) {
        lock = [[NSObject alloc] init];
        fireOnce = shouldFireOnce;
        blockFired = NO;
        block = callbackBlock;
        canceled = NO;
    }
    
    return self;
}

- (NSTimeInterval)getDelay {
    return delay;
}

- (void)executeBlock {
    @synchronized(lock) {
        @try {
            if (timer != nil) {
                if (timer.isValid) {
                    // timer could still fire, invalidate to stop
                    [timer invalidate];
                }
                timer = nil;
            }
            
            if (!fireOnce || (fireOnce && !blockFired)) {
                blockFired = YES;
                
                if (block != nil) {
                    block();
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"Error in executing callback block: %@",exception);
        }
    }
}

- (void)startTimer:(NSTimeInterval)timeInterval {
    @synchronized(lock) {
        delay = timeInterval;
        canceled = NO;
        timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                 target:self
                                               selector:@selector(executeBlock)
                                               userInfo:nil
                                                repeats:NO];
    }
}

- (void)stopTimer {
    @synchronized(lock) {
        @try {
            if (timer != nil) {
                if (timer.isValid) {
                    // invalidate timer to stop
                    [timer invalidate];
                    canceled = YES;
                }
                timer = nil;
            }
        } @catch (NSException *exception) {
            NSLog(@"Error in executing callback block: %@",exception);
        }
    }
}

- (BOOL)isCanceled {
    @synchronized(lock) {
        return canceled;
    }
}

@end
