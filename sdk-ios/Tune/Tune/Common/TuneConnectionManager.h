//
//  ConnectionManager.h
//  Tune
//
//  Created by Pavel Yurchenko on 7/21/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <netinet/in.h>
#import <UIKit/UIKit.h>

#import "TuneReachability.h"

@class TuneRequestsQueue;

@protocol TuneConnectionManagerDelegate;

@interface TuneConnectionManager : NSObject<NSURLConnectionDelegate>
{
    TuneRequestsQueue * requestsQueue_;
    TuneReachability * reachability_;
    NetworkStatus status_;
    BOOL dumpingQueue_, _shouldDebug;
    
    NSOperationQueue *queueQueue;
}

@property (nonatomic, assign) NetworkStatus status;
@property (nonatomic, assign) BOOL shouldDebug;
@property (nonatomic, assign) BOOL shouldAllowDuplicates;
@property (nonatomic, assign) id<TuneConnectionManagerDelegate> delegate;

@property (nonatomic, readonly) TuneRequestsQueue * requestsQueue;

- (void)enqueueUrlRequest:(NSString*)trackingLink
            encryptParams:(NSString*)encryptParams
              andPOSTData:(NSString*)postData
                  runDate:(NSDate*)runDate;

- (void)beginRequestGetTrackingId:(NSString*)trackingLink
               withDelegateTarget:(id)target
              withSuccessSelector:(SEL)selectorSuccess
              withFailureSelector:(SEL)selectorFailure
                     withArgument:(NSMutableDictionary *)dict;

@end


@protocol TuneConnectionManagerDelegate <NSObject>

@required
- (void)connectionManager:(TuneConnectionManager *)manager didSucceedWithData:(NSData *)data;
- (void)connectionManager:(TuneConnectionManager *)manager didFailWithError:(NSError *)error;

- (NSString*)encryptionKey;
- (BOOL)isiAdAttribution;
- (NSString*)userAgent;

@end