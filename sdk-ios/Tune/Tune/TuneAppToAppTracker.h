//
//  TuneAppToAppTracker.h
//  Tune
//
//  Created by John Bender on 2/27/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TuneEventQueue.h"

@interface TuneAppToAppTracker : NSObject

@property (nonatomic, weak) id <TuneEventQueueDelegate> delegate;

- (void)startMeasurementSessionForTargetBundleId:(NSString *)targetBundleId
                               publisherBundleId:(NSString *)publisherBundleId
                                    advertiserId:(NSString *)advertiserId
                                      campaignId:(NSString *)campaignId
                                     publisherId:(NSString *)publisherId
                                        redirect:(BOOL)shouldRedirect
                                      domainName:(NSString *)domainName;

+ (NSString *)getPublisherBundleId;
+ (NSString *)getSessionDateTime;
+ (NSString *)getAdvertiserId;
+ (NSString *)getCampaignId;
+ (NSString *)getTrackingId;

@end
