//
//  TuneTracker.h
//  Tune
//
//  Created by John Bender on 2/28/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TuneEvent;

@protocol TuneDelegate;
@protocol TuneTrackerDelegate;

@interface TuneTracker : NSObject

@property (nonatomic, assign) id <TuneDelegate> delegate;
@property (nonatomic, assign) id <TuneTrackerDelegate> trackerDelegate;

@property (nonatomic, assign) BOOL fbLogging;
@property (nonatomic, assign) BOOL fbLimitUsage;

#if TESTING
@property (nonatomic, assign) BOOL allowDuplicateRequests;
#endif

+ (TuneTracker *)sharedInstance;

#if TESTING
+ (void)resetSharedInstance;
#endif

- (void)startTracker;

- (void)applicationDidOpenURL:(NSString *)urlString sourceApplication:(NSString *)sourceApplication;

- (void)measureEvent:(TuneEvent *)event;

- (void)measureTuneLinkClick:(NSString *)clickedTuneLinkUrl;

- (BOOL)isiAdAttribution;

- (void)urlStringForEvent:(TuneEvent *)event
             trackingLink:(NSString**)trackingLink
            encryptParams:(NSString**)encryptParams;
@end

@protocol TuneTrackerDelegate <NSObject>
@optional
- (void)_tuneURLTestingCallbackWithParamsToBeEncrypted:(NSString*)paramsToBeEncrypted withPlaintextParams:(NSString*)plaintextParams;
@end
