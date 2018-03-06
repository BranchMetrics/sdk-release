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

+ (TuneEventQueue *)sharedQueue;

/*!
 Method used to enqueue a request in the main Tune event queue.
 */
- (void)enqueueUrlRequest:(NSString*)trackingLink
              eventAction:(NSString*)actionName
                    refId:(NSString*)refId
            encryptParams:(NSString*)encryptParams
                 postData:(NSDictionary*)postData
                  runDate:(NSDate*)runDate;

/*!
 Method used to immediately send a request, bypassing the main Tune event queue.
 */
- (void)sendUrlRequestImmediately:(NSString*)trackingLink
                      eventAction:(NSString*)actionName
                            refId:(NSString*)refId
                    encryptParams:(NSString*)encryptParams
                         postData:(NSDictionary*)postData
                          runDate:(NSDate*)runDate;

/*!
 Update currently enqueued requests to include the provided referral_url and referral_source.
 */
- (void)updateEnqueuedEventsWithReferralUrl:(NSString *)url referralSource:(NSString *)bundleId;

/*!
 If a session request is currently enqueued, include the provided iAd attribution info in the request url / post data.
 @param iadInfo iAd info available on iOS 9+ to be used to update the enqueued session request post data
 @param impressionDate iAd attribution impression date available on iOS 8 to be used to update the enqueued session request
 @param completionHandler Completion handler block that contains updated url / postData when the update is successful
 */
- (void)updateEnqueuedSessionEventWithIadAttributionInfo:(NSDictionary *)iadInfo impressionDate:(NSDate *)impressionDate completionHandler:(void(^)(BOOL updated, NSString * refId, NSString *url, NSDictionary *postData))completionHandler;

- (void)setDelegate:(id<TuneEventQueueDelegate>)delegate;

@end


@protocol TuneEventQueueDelegate <NSObject>

@optional
/*!
 Optional callback fired when an event request succeeds.
 */
- (void)queueRequest:requestUrl didSucceedWithData:(NSData *)data;

/*!
 Optional callback fired when an event request fails.
 */
- (void)queueRequestDidFailWithError:(NSError *)error;

- (void)queueRequestDidFailWithError:(NSError *)error request:(NSString *)request response:(NSString *)response;

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
