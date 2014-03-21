//
//  MATAppToAppTracker.h
//  MobileAppTracker
//
//  Created by John Bender on 2/27/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MATConnectionManager.h"

@interface MATAppToAppTracker : NSObject

@property (nonatomic, assign) id <MATConnectionManagerDelegate> delegate;

- (void)startTrackingSessionForTargetBundleId:(NSString*)targetBundleId
                            publisherBundleId:(NSString*)publisherBundleId
                                 advertiserId:(NSString*)advertiserId
                                   campaignId:(NSString*)campaignId
                                  publisherId:(NSString*)publisherId
                                     redirect:(BOOL)shouldRedirect
                                   domainName:(NSString*)domainName
                            connectionManager:(MATConnectionManager*)connectionManager;

+ (NSString*)getPublisherBundleId;
+ (NSString*)getSessionDateTime;
+ (NSString*)getAdvertiserId;
+ (NSString*)getCampaignId;
+ (NSString*)getTrackingId;

@end
