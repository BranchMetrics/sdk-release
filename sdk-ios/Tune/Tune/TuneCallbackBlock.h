//
//  TuneCallbackBlock.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/30/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^CodeBlockCallback)(void);

@interface TuneCallbackBlock : NSObject {
    NSTimer *timer;
    NSTimeInterval delay;
    NSObject *lock;
    BOOL fireOnce;
    BOOL blockFired;
    BOOL canceled;
    CodeBlockCallback block;
}

- (id)initWithCallbackBlock:(void(^)(void))callbackBlock fireOnce:(BOOL)shouldFireOnce;

- (NSTimeInterval)getDelay;
- (void)executeBlock;
- (void)startTimer:(NSTimeInterval)timeInterval;
- (void)stopTimer;
- (BOOL)isCanceled;

@end
