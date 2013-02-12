//
//  MATUtils.h
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/24/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MATConnectionManager.h"
#import <MobileAppTracker/MobileAppTracker.h>

@interface MATUtils : NSObject

+ (NSString*)generateUserAgentString;
+ (NSString*)generateFBCookieIdString;
+ (NSString*)generateODIN1String;

/// Returns Mac address string and also fills dataBuf with 6 bytes of
/// address plain representation
+ (NSString *)generateMacAddressString:(unsigned char*)dataBuf;

+ (NSString *)getUUID;
+ (NSString *)getOpenUDID;

+ (NSString *)bundleId;

+ (void)startTrackingSessionForTargetBundleId:(NSString*)targetBundleId
                            publisherBundleId:(NSString*)publisherBundleId
                                 advertiserId:(NSString*)advertiserId
                                   campaignId:(NSString*)campaignId
                                  publisherId:(NSString*)publisherId
                                     redirect:(BOOL)shouldRedirect
                           connectionDelegate:(id<MATConnectionManagerDelegate>)matDelegate;

+ (void)stopTrackingSession;
+ (BOOL)isTrackingSessionStartedForTargetApplication:(NSString*)targetPackageName;

+ (NSString*)getPublisherBundleId;
+ (NSString*)getSessionDateTime;
+ (NSString*)getAdvertiserId;
+ (NSString*)getCampaignId;

+ (NSString*)getStringForKey:(NSString*)key fromPasteBoard:(NSString *)pasteBoardName;
+ (NSString*)getTrackingId;

+ (id)userDefaultValueforKey:(NSString *)key;
+ (void)setUserDefaultValue:(id)value forKey:(NSString* )key;

+ (NSString *)formattedCurrentDateTime;
+ (BOOL)checkJailBreak;
+ (NSString *)getMacAddress;

+ (void)storeToPasteBoardTrackingId:(NSMutableDictionary *)params;
+ (void)failedToRequestTrackingId:(NSMutableDictionary *)params withError:(NSError *)error;

@end