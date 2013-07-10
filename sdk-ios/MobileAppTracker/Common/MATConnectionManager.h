//
//  ConnectionManager.h
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/21/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <netinet/in.h>
#import <UIKit/UIKit.h>

#import "MATRequestsQueue.h"
#import "MATReachability.h"

FOUNDATION_EXPORT int const MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL;

@protocol MATConnectionManagerDelegate;

@interface MATConnectionManager : NSObject<NSURLConnectionDelegate>
{
    MATRequestsQueue * requestsQueue_;
    MATReachability * reachability_;
    NetworkStatus status_;
    BOOL dumpingQueue_, _shouldDebug, _shouldAllowDuplicates;
    NSUInteger dumpTriesFailures_;
}
+ (MATConnectionManager*)sharedManager;
+ (void)destroyManager;

@property (nonatomic, assign) NetworkStatus status;
@property (nonatomic, assign) BOOL shouldDebug;
@property (nonatomic, assign) BOOL shouldAllowDuplicates;
@property (nonatomic, assign) id<MATConnectionManagerDelegate> delegate;

- (void)beginUrlRequest:(NSString *)link andPOSTData:(NSString*)postData withDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate;

- (void)beginRequestGetTrackingId:(NSString *)link
               withDelegateTarget:(id)target
              withSuccessSelector:(SEL)selectorSuccess
              withFailureSelector:(SEL)selectorFailure
                     withArgument:(NSMutableDictionary *)dict
                     withDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate;

- (void)beginRequestGetInstallLogId:(NSString *)link
                 withDelegateTarget:(id)target
                withSuccessSelector:(SEL)selectorSuccess
                withFailureSelector:(SEL)selectorFailure
                       withArgument:(NSMutableDictionary *)dict
                       withDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate;

@end


@protocol MATConnectionManagerDelegate <NSObject>

@optional
- (void)connectionManager:(MATConnectionManager *)manager didSucceedWithData:(NSData *)data;
- (void)connectionManager:(MATConnectionManager *)manager didFailWithError:(NSError *)error;

@end