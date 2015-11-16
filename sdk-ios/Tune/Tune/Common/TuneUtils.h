//
//  TuneUtils.h
//  Tune
//
//  Created by Pavel Yurchenko on 7/24/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <MobileCoreServices/UTType.h>

#if TARGET_OS_IOS
#import <SystemConfiguration/SystemConfiguration.h>
#endif

#import <UIKit/UIKit.h>

#import <sys/xattr.h>
#import <dlfcn.h>
#import <objc/runtime.h>

#import "TuneReachability.h"

@interface TuneUtils : NSObject

#if TARGET_OS_IOS
+ (nullable NSString*)generateFBCookieIdString;
#endif

+ (nonnull NSString *)getUUID;

+ (nonnull NSString *)bundleId;
+ (nonnull NSDate *)installDate;

+ (BOOL)isNetworkReachable;

#if !TARGET_OS_WATCH
+ (TuneNetworkStatus)networkReachabilityStatus;
#endif

+ (nullable NSString*)getStringForKey:(nonnull NSString*)key fromPasteBoard:(nonnull NSString *)pasteBoardName;

+ (nullable id)userDefaultValueforKey:(nonnull NSString *)key;
+ (void)setUserDefaultValue:(nonnull id)value forKey:(nonnull NSString* )key;
+ (void)synchronizeUserDefaults;

+ (BOOL)checkJailBreak;

+ (NSInteger)daysBetweenDate:(nonnull NSDate*)fromDateTime andDate:(nonnull NSDate*)toDateTime;

+ (float)numericiOSVersion:(nonnull NSString *)iOSVersion;
+ (float)numericiOSSystemVersion;

+ (BOOL)addSkipBackupAttributeToItemAtURL:(nonnull NSURL *)URL;

+ (nullable NSString *)jsonSerialize:(nullable id)object;

+ (nullable NSString *)parseXmlString:(nullable NSString *)strXml forTag:(nullable NSString *)tag;

+ (nullable NSString *)hashMd5:(nullable NSString *)input;
+ (nullable NSString *)hashSha1:(nullable NSString *)input;
+ (nullable NSString *)hashSha256:(nullable NSString *)input;

#if TESTING
+ (void)overrideNetworkReachability:(nullable NSString *)reachable;
#endif

/*!
 Appends the key, value pair to the query string if the url-encoded value is non-nil.
 <code>&key=value</code>
 @param value value to be url-encoded and appended to the query string
 @param key key to be appended to the query string
 @param params query string to which the key-value pair has to be appended
 */
+ (void)addUrlQueryParamValue:(nonnull id)value
                       forKey:(nonnull NSString*)key
                  queryParams:(nonnull NSMutableString*)params;

/*!
 Converts input object to equivalent string representation for use as value of a url query param.
 Returns stringValue for NSNumber*, timeIntervalSince1970 stringValue for NSDate*, and url-encoded string for NSString*, nil otherwise.
 */
+ (nullable NSString *)urlEncodeQueryParamValue:(nullable id)value;


#pragma mark -

+ (nonnull NSData *)tuneDataFromBase64String:(nonnull NSString *)aString;
+ (nonnull NSString *)tuneBase64EncodedStringFromData:(nonnull NSData *)data;

#pragma mark -

+ (CGSize)screenSize;
+ (CGRect)screenBoundsForStatusBarOrientation;

#pragma mark - String Helper Methods

+ (nullable NSString *)urlEncode:(nullable NSString *)string;
+ (nullable NSString *)urlEncode:(nullable NSString *)string usingEncoding:(NSStringEncoding)encoding;

#pragma mark - NSURLSession Helper

+ (nullable NSData *)sendSynchronousDataTaskWithRequest:(nonnull NSURLRequest *)request forSession:(nonnull NSURLSession *)session returningResponse:(NSURLResponse *_Nullable*_Nullable)response error:(NSError *_Nullable*_Nullable)error;

@end
