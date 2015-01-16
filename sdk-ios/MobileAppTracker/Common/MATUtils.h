//
//  MATUtils.h
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/24/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/xattr.h>
#import <dlfcn.h>
#import <objc/runtime.h>

#import "../MobileAppTracker.h"

@interface MATUtils : NSObject

FOUNDATION_EXPORT const float MAT_IOS_VERSION_501; // float equivalent of 5.0.1

+ (NSString*)generateFBCookieIdString;

+ (NSString *)getUUID;

+ (NSString *)bundleId;
+ (NSDate *)installDate;

+ (BOOL)isNetworkReachable;

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


#pragma mark -

+ (NSData *)MATdataFromBase64String:(NSString *)aString;
+ (NSString *)MATbase64EncodedStringFromData:(NSData *)data;

@end