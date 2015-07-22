//
//  TuneUtils.h
//  Tune
//
//  Created by Pavel Yurchenko on 7/24/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/UTType.h>
#import <sys/xattr.h>
#import <dlfcn.h>
#import <objc/runtime.h>

#import "../Tune.h"
#import "TuneReachability.h"

@interface TuneUtils : NSObject

FOUNDATION_EXPORT const float TUNE_IOS_VERSION_501; // float equivalent of 5.0.1

+ (NSString*)generateFBCookieIdString;

+ (NSString *)getUUID;

+ (NSString *)bundleId;
+ (NSDate *)installDate;

+ (BOOL)isNetworkReachable;

+ (NetworkStatus)networkReachabilityStatus;

+ (NSString*)getStringForKey:(NSString*)key fromPasteBoard:(NSString *)pasteBoardName;

+ (id)userDefaultValueforKey:(NSString *)key;
+ (void)setUserDefaultValue:(id)value forKey:(NSString* )key;
+ (void)synchronizeUserDefaults;

+ (BOOL)checkJailBreak;

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime;

+ (float)numericiOSVersion:(NSString *)iOSVersion;
+ (float)numericiOSSystemVersion;

+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL;

+ (NSString *)jsonSerialize:(id)object;

+ (NSString *)parseXmlString:(NSString *)strXml forTag:(NSString *)tag;

+ (NSString *)hashMd5:(NSString *)input;
+ (NSString *)hashSha1:(NSString *)input;
+ (NSString *)hashSha256:(NSString *)input;

#if TESTING
+ (void)overrideNetworkReachability:(NSString *)reachable;
#endif

+ (void)addUrlQueryParamValue:(id)value
                       forKey:(NSString*)key
                  queryParams:(NSMutableString*)params;

/*!
 Converts input object to equivalent string representation for use as value of a url query param.
 Returns stringValue for NSNumber*, timeIntervalSince1970 stringValue for NSDate*, and url-encoded string for NSString*, nil otherwise.
 */
+ (NSString *)urlEncodeQueryParamValue:(id)value;


#pragma mark -

+ (NSData *)tuneDataFromBase64String:(NSString *)aString;
+ (NSString *)tuneBase64EncodedStringFromData:(NSData *)data;

/*!
 Collects IFA if ASIdentifierManager class in AdSupport.framework is dynamically accessible.
 @return An array with two items [advertisingIdentifier - NSUUID*, isAdvertisingTrackingEnabled - NSNumber*]
 */
+ (NSArray *)ifaInfo;

@end
