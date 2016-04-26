//
//  TuneCallbackBlock.h
//  TuneMarketingConsoleSDK
//
//  Created by Matt Gowie on 8/30/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^CodeBlockCallback)();

@interface TuneCallbackBlock : NSObject {
    NSTimer *timer;
    NSObject *lock;
    BOOL fireOnce;
    BOOL blockFired;
    CodeBlockCallback block;
}

- (id)initWithCallbackBlock:(void(^)())callbackBlock fireOnce:(BOOL)shouldFireOnce;

- (void)setDelay:(NSTimeInterval)timeInterval;
- (void)executeBlock;

@end
