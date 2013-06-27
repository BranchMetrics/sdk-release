//
//  MATUtils.h
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/24/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MobileAppTracker/MobileAppTracker.h>
#import <sys/xattr.h>
#import <dlfcn.h>
#import <objc/runtime.h>

/****************************************
 *  VERY IMPORTANT!
 *  These values should be zero for releases.
 ****************************************/
#define DEBUG_JAILBREAK_LOG         0
#define DEBUG_LINK_LOG              0
#define DEBUG_LOG                   0
#define DEBUG_REQUEST_LOG           0
#define DEBUG_REMOTE_LOG            0
#define DEBUG_STAGING               0

@protocol MATConnectionManagerDelegate;

@interface MATUtils : NSObject

extern const float IOS_VERSION_501; // float equivalent of 5.0.1

+ (NSString*)generateUserAgentString;
+ (NSString*)generateFBCookieIdString;
+ (NSString*)generateODIN1String;

/// Returns Mac address string and also fills dataBuf with 6 bytes of
/// address plain representation
+ (NSString *)generateMacAddressString:(unsigned char*)dataBuf;

+ (NSString *)getUUID;
+ (NSString *)getOpenUDID;

+ (NSString *)bundleId;

+ (BOOL)isNetworkReachable;

+ (void)setShouldDebug:(BOOL)yesorno;

+ (void)startTrackingSessionForTargetBundleId:(NSString*)targetBundleId
                            publisherBundleId:(NSString*)publisherBundleId
                                 advertiserId:(NSString*)advertiserId
                                   campaignId:(NSString*)campaignId
                                  publisherId:(NSString*)publisherId
                                     redirect:(BOOL)shouldRedirect
                           connectionDelegate:(id<MATConnectionManagerDelegate>)matDelegate;

+ (void)sendRequestGetInstallLogIdWithLink:(NSString *)link
                                    params:(NSMutableDictionary*)params
                        connectionDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate;

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

+ (NSDateFormatter *)sharedDateFormatter;
+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;

+ (void)handleInstallLogId:(NSMutableDictionary *)params;
+ (void)failedToRequestInstallLogId:(NSMutableDictionary *)params withError:(NSError *)error;

+ (float)getNumericiOSVersion:(NSString *)iOSVersion;
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL;

+ (NSString *)serverDomainName;

@end