//
//  TuneEventQueue+Testing.h
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 9/25/15.
//  Copyright © 2015 Tune. All rights reserved.
//

#import "TuneEventQueue.h"

@interface TuneEventQueue (Testing)

- (void)waitUntilAllOperationsAreFinishedOnQueue;
- (void)cancelAllOperationsOnQueue;
+ (void)resetSharedInstance;
+ (instancetype)sharedInstance;
+ (NSMutableArray *)events;
+ (NSDictionary *)eventAtIndex:(NSUInteger)index;
+ (NSUInteger)queueSize;
+ (void)drainQueue;
+ (void)dumpQueue;
+ (void)setForceNetworkError:(BOOL)isError code:(NSInteger)code;
+ (NSTimeInterval)retryDelayForAttempt:(NSInteger)attempt;

@end
