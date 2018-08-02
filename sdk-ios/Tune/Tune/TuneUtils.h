//
//  TuneUtils.h
//  Tune
//
//  Created by Pavel Yurchenko on 7/24/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import <UIKit/UIKit.h>

#if !TARGET_OS_WATCH
#import <SystemConfiguration/SystemConfiguration.h>
#endif

#import <MobileCoreServices/UTType.h>
#import <sys/xattr.h>
#import <dlfcn.h>
#import <objc/runtime.h>

@interface TuneUtils : NSObject

#if TARGET_OS_IOS
+ (nullable NSString*)generateFBCookieIdString;
#endif

+ (nonnull NSString *)getUUID;

/*!
 Wrapper for NSClassFromString that works for Swift classes as well
 @param className class name to get Class of
 */
+ (nullable Class)getClassFromString:(nonnull NSString *)className;

+ (nonnull NSString *)bundleId;
+ (nonnull NSString *)bundleName;
+ (nonnull NSString *)bundleVersion;
+ (nonnull NSString *)stringVersion;

+ (nonnull NSDate *)installDate;

+ (nullable NSString*)getStringForKey:(nonnull NSString*)key fromPasteBoard:(nonnull NSString *)pasteBoardName;

+ (BOOL)checkJailBreak;

+ (float)numericiOSVersion:(nonnull NSString *)iOSVersion;
+ (float)numericiOSSystemVersion;

+ (nullable NSString *)jsonSerialize:(nullable id)object;
+ (nullable NSData *)jsonSerializedDataForObject:(nullable id)object;
+ (nullable id)jsonDeserializeData:(nullable NSData *)jsonData;
+ (nullable id)jsonDeserializeString:(nullable NSString *)jsonString;

+ (nullable NSString *)hashMd5:(nullable NSString *)input;
+ (nullable NSString *)hashSha1:(nullable NSString *)input;
+ (nullable NSString *)hashSha256:(nullable NSString *)input;

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

+ (nullable id)objectOrNull:(nullable id)object;
+ (CGSize)screenSize;

#pragma mark -

/** Returns a string that can be used as a URL query string.
 
 This recursively traverses the dictionary in order to create
 a query string. So, imagine an NSDictionary that looks like
 this:
 
 NSDictionary *myVars = @{
 @"name": @"Kyle",
 @"attributes": @{
 @"company": @"Tune"
 }
 }
 
 It would result in a query string like this:
 
 attributes[company]=Artisan&name="Kyle"
 
 The order is determined by the key names.
 
 @warning All keys *must* be NSStrings, or they will be ignored. Similarly, all values must be either NSStrings or NSDictionary objects which adhere to the same rules.
 
 @param dictionary The dictionary to convert
 
 @param namespaceString Wraps the keys with a namespace, for instance if set to "myname", all keys will be "myname[key]". This is really only used for recursion—most of the time you'll want to just set this to nil.
 */
+ (nullable NSString *)dictionaryAsQueryString:(nullable NSDictionary *)dictionary withNamespace:(nullable NSString *)namespaceString;

#pragma mark -

+ (BOOL)object:(nullable id)receiver respondsToSelector:(nonnull SEL)aSelector;

#pragma mark - NSBundle Helper

+ (nullable NSBundle *)currentBundle;

#pragma mark -

/*!
 * Finds out if the very first "session" request has already completed, by checking if "open_log_id" key exits in the user profile.
 * This check is useful to control which query params are included in the requests, since some of the params are valid only with the very first "session" request.
 *
 * @return true if the first session request has already been completed, no otherwise
 */
+ (BOOL)isFirstSessionRequestComplete;

@end
