//
//  TuneEventQueue.h
//  Tune
//
//  Created by John Bender on 8/12/14.
//  Copyright (c) 2014 TUNE. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT const NSTimeInterval TUNE_NETWORK_REQUEST_TIMEOUT_INTERVAL;

@protocol TuneEventQueueDelegate;

/*!
 Main Tune event queue.
 */
@interface TuneEventQueue : NSObject

+ (void)setDelegate:(id<TuneEventQueueDelegate>)delegate;

/*!
 Method used to enqueue a request in the main Tune event queue.
 */
+ (void)enqueueUrlRequest:(NSString*)trackingLink
              eventAction:(NSString*)actionName
            encryptParams:(NSString*)encryptParams
                 postData:(NSString*)postData
                  runDate:(NSDate*)runDate;

/*!
 Update currently enqueued requests to include the provided referral_url and referral_source.
 */
+ (void)updateEnqueuedEventsWithReferralUrl:(NSString *)url referralSource:(NSString *)bundleId;

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
