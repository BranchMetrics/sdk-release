//
//  TuneEventQueue.h
//  Tune
//
//  Created by John Bender on 8/12/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT int const TUNE_NETWORK_REQUEST_TIMEOUT_INTERVAL;

@protocol TuneEventQueueDelegate;

/*!
 Main Tune event queue.
 */
@interface TuneEventQueue : NSObject

+(void) setDelegate:(id <TuneEventQueueDelegate>)delegate;

/*!
 Method used to enqueue a request in the main Tune event queue.
 */
+(void) enqueueUrlRequest:(NSString*)trackingLink
            encryptParams:(NSString*)encryptParams
                 postData:(NSString*)postData
                  runDate:(NSDate*)runDate;

#if TESTING
+ (instancetype)sharedInstance;
+ (NSMutableArray *)events;
+ (NSDictionary *)eventAtIndex:(NSUInteger)index;
+ (NSUInteger)queueSize;
+ (void)drain;
+ (void)dumpQueue;
+ (void)setForceNetworkError:(BOOL)isError code:(NSInteger)code;
+ (NSTimeInterval)retryDelayForAttempt:(NSInteger)attempt;
#endif

@end


@protocol TuneEventQueueDelegate <NSObject>

@optional
/*!
 Optional callback fired when an event request succeeds.
 */
- (void)queueRequestDidSucceedWithData:(NSData *)data;

/*!
 Optional callback fired when an event request fails.
 */
- (void)queueRequestDidFailWithError:(NSError *)error;

@required

/*!
 Encryption key to be provided by the delegate.
 */
- (NSString*)encryptionKey;

/*!
 iAd attribution BOOL value to be provided by the delegate.
 */
- (BOOL)isiAdAttribution;

@end
