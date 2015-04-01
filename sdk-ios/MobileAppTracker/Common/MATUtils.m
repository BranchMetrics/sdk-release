//
//  MATUtils.m
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/24/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "MATUtils.h"
#import "MATKeyStrings.h"
#import "MATReachability.h"
#import "MATSettings.h"

#import "../MobileAppTracker.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <MobileCoreServices/UTType.h>

#include <CommonCrypto/CommonDigest.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

const float MAT_IOS_VERSION_501 = 5.01f;

NSString * const PASTEBOARD_NAME_FACEBOOK_APP = @"fb_app_attribution";

static NSString* const USER_DEFAULT_KEY_PREFIX = @"_MAT_";


@implementation MATUtils

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSDayCalendarUnit
                startDate:&fromDate
                 interval:NULL
                  forDate:fromDateTime];
    [calendar rangeOfUnit:NSDayCalendarUnit
                startDate:&toDate
                 interval:NULL
                  forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSDayCalendarUnit
                                               fromDate:fromDate
                                                 toDate:toDate
                                                options:0];
    
    return [difference day];
}


+ (NSString*)generateFBCookieIdString
{
    NSString * attributionID = nil;
    
    UIPasteboard *pb = [UIPasteboard pasteboardWithName:PASTEBOARD_NAME_FACEBOOK_APP create:NO];
    if (pb)
    {
        attributionID = [pb.string copy];
    }
    
    return attributionID;
}

+ (NSString *)getUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    NSString *returnString = [(__bridge NSString*)string copy];
    CFRelease(string);
    
    return returnString;
}


+ (NSString *)parseXmlString:(NSString *)strXml forTag:(NSString *)tag
{
    NSString *value = nil;
    
    NSString *strStartTag = [NSString stringWithFormat:@"<%@>", tag];
    NSString *strEndTag = [NSString stringWithFormat:@"</%@>", tag];
    
    NSRange rangeStart = [strXml rangeOfString:strStartTag];
    NSRange rangeEnd = [strXml rangeOfString:strEndTag];
    
    if(NSNotFound != rangeStart.location && NSNotFound != rangeEnd.location)
    {
        NSInteger start = rangeStart.location + rangeStart.length;
        NSInteger end = rangeEnd.location;
        
        value = [strXml substringWithRange:NSMakeRange(start, end - start)];
    }
    
    return value;
}


+ (NSString*)getStringForKey:(NSString*)key fromPasteBoard:(NSString *)pasteBoardName
{
    NSString *storedValue = nil;
    
    UIPasteboard *cookiePasteBoard = [UIPasteboard pasteboardWithName:pasteBoardName create:NO];
    
    if (key && cookiePasteBoard)
    {
        NSDictionary * itemsDict = nil;
        id items = [cookiePasteBoard valueForPasteboardType:(NSString*)kUTTypeTagSpecificationKey];
        if (items)
        {
            itemsDict = [NSKeyedUnarchiver unarchiveObjectWithData:items];
        }
        
        if (itemsDict)
        {
            storedValue = [itemsDict objectForKey:key];
        }
    }
    
    return storedValue;
}


+ (id)userDefaultValueforKey:(NSString *)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *newKey = [NSString stringWithFormat:@"%@%@", USER_DEFAULT_KEY_PREFIX, key];
    
    id value = [defaults valueForKey:newKey];
    
    // return value for new key if exists, else return value for old key
    if( value ) return value;
    return [defaults valueForKey:key];
}

+ (void)setUserDefaultValue:(id)value forKey:(NSString* )key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    key = [NSString stringWithFormat:@"%@%@", USER_DEFAULT_KEY_PREFIX, key];
    [defaults setValue:value forKey:key];
    
    // Note: Moved this synchronize call to MobileAppTracker handleNotification: -- UIApplicationWillResignActiveNotification notification,
    // so that the synchronize method instead of being called for each key, gets called only once just before the app becomes inactive.
    //[defaults synchronize];
}

+ (void)synchronizeUserDefaults
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)checkJailBreak
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#endif
    
    // METHOD 1: Check for file paths of some commonly used hacks
    // array of jail broken paths
    NSArray *jailBrokenPaths = [NSArray arrayWithObjects:
                                @"/Applications/Cydia.app",
                                @"/Applications/blackra1n.app",
                                @"/Applications/FakeCarrier.app",
                                @"/Applications/Icy.app",
                                @"/Applications/IntelliScreen.app",
                                @"/Applications/MxTube.app",
                                @"/Applications/RockApp.app",
                                @"/Applications/SBSettings.app",
                                @"/Applications/WinterBoard.app",
                                @"/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
                                @"/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
                                @"/private/var/lib/apt",
                                @"/private/var/lib/cydia",
                                @"/private/var/mobile/Library/SBSettings/Themes",
                                @"/private/var/stash",
                                @"/private/var/tmp/cydia.log",
                                @"/System/Library/LaunchDaemons/com.ikey.bbot.plist",
                                @"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
                                @"/usr/bin/sshd",
                                @"/usr/libexec/sftp-server",
                                @"/usr/sbin/sshd", nil];
    
    BOOL jailBroken = NO;
    for (NSString * path in jailBrokenPaths)
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            jailBroken = YES;
            break;
        }
    }
    
    if(!jailBroken)
    {
        // METHOD 2: Check if a shell is present
        // Jailbroken devices have shell access, system(NULL) returns a non-zero value if a shell is present
        jailBroken = system (NULL) != 0;
        
        if(!jailBroken)
        {
            // METHOD 3: There's no shell access, but check if we are being cheated.
            // Check if the standard Foundation framework is present at the expected file path.
            // xCon operates by inserting its own code between an application trying to detect jailbreak and the original code of the function. In case of system function we can't detect if we are calling the original or not. However, we can check integrity of other methods that are being spoofed by xCon. So, by checking the module (name of the file where the actual code resides) of Objective-C call -[NSFileManager fileExistsAtPath:] I can safely assume if we are being cheated. The check is performed with dladdr() call.
            
            // class is NSFileManager and method is fileExistsAtPath:
            Class class = NSFileManager.class;
            SEL method = @selector(fileExistsAtPath:);
            
            IMP implementation = class_getMethodImplementation (class, method);
            
            Dl_info info;
            dladdr((const void*)implementation, &info);
            
            // Assume that the device is jailbroken if info.dli_fname does not equal "/System/Library/Frameworks/Foundation.framework/Foundation"
            NSString *actualPath = [NSString stringWithFormat:@"%s", info.dli_fname];
            jailBroken = NSOrderedSame != [actualPath compare:@"/System/Library/Frameworks/Foundation.framework/Foundation"];
        }
    }
    
#if DEBUG_JAILBREAK_LOG
    jailBroken ? NSLog(@"Jailbreak detected!") : NSLog(@"No Jailbreak detected");
#endif
    
    return jailBroken;
}


+ (NSString *)bundleId
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString*)kCFBundleIdentifierKey];
}

+ (NSDate *)installDate
{
    // Determine install date from app bundle
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
    NSDictionary *appAttrs = [fileManager attributesOfItemAtPath:bundlePath error:nil];
    return appAttrs[NSFileCreationDate];
}


+ (BOOL)isNetworkReachable
{
    DLog(@"MATUtils: isNetworkReachable: status = %ld", (long)[[MATReachability reachabilityForInternetConnection] currentReachabilityStatus]);
    return NotReachable != [[MATReachability reachabilityForInternetConnection] currentReachabilityStatus];
}


/*!
 Converts an iOS version string x.y.z to its equivalent float representation.

 Note: This method assumes that the individual sub-version components -- y or z -- have values between 0..9.
*/
+ (float)numericiOSVersion:(NSString *)iOSVersion
{
    NSArray *arr = [iOSVersion componentsSeparatedByString:@"."];
    
    float version = 0;
    float factor = 1;
    
    for (NSString *component in arr)
    {
        version += ([component floatValue] * factor);
        factor /= 10;
    }
    
    return version;
}

/*!
 Numeric representation of the iOS system version string x.y.z.
*/
+ (float)numericiOSSystemVersion
{
    return [MATUtils numericiOSVersion:[[UIDevice currentDevice] systemVersion]];
}

// Refer: http://developer.apple.com/library/ios/#qa/qa1719/_index.html#//apple_ref/doc/uid/DTS40011342
// How do I prevent files from being backed up to iCloud and iTunes?
//
// For iOS versions 5.0.1 and above set a flag to denote that the queue storage files should not be backed up on iCloud.
// No-op for iOS versions 5.0 and below.
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    DLog(@"MATUtils addSkipBackupAttributeToItemAtURL: %@", URL);
    
    BOOL success = NO;
    
    if([[NSFileManager defaultManager] fileExistsAtPath: [URL path]])
    {
        float systemVersion = [MATUtils numericiOSSystemVersion];
        
        if(systemVersion == MAT_IOS_VERSION_501)
        {
            const char* filePath = [[URL path] fileSystemRepresentation];
            
            const char* attrName = "com.apple.MobileBackup";
            u_int8_t attrValue = 1;
            
            int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
            success = 0 == result;
        }
        else if(systemVersion > MAT_IOS_VERSION_501)
        {
            NSError *error = nil;
            success = [URL setResourceValue:@(YES)
                                     forKey:NSURLIsExcludedFromBackupKey
                                      error:&error];
#if DEBUG_LOG
            if(!success)
            {
                NSLog(@"MATUtils addSkipBackupAttributeToItemAtURL: Error excluding %@ from backup %@", [URL lastPathComponent], error);
            }
#endif
        }
    }
    
    return success;
}

+ (NSString *)jsonSerialize:(id)object
{
    NSString *output = nil;
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:0
                                                         error:&error];
    
    if (jsonData)
    {
        output = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    }
    else
    {
        DLog(@"JSON serializer: error = %@, input = %@", error, object);
    }
    
    return output;
}


#pragma mark - Base64 Encoding/Decoding Methods

/*!
 Creates an NSData object containing the Base64 decoded representation of
 the Base64 string.
 @param encodedString the Base64 string to decode
 @return NSData representation of the Base64 string
 */
+ (NSData *)MATdataFromBase64String:(NSString *)encodedString
{
    NSData *decodedData = nil;
    
    // if iOS 7+
    if([NSData instancesRespondToSelector:@selector(initWithBase64EncodedString:options:)])
    {
        decodedData = [[NSData alloc] initWithBase64EncodedString:encodedString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    else
    {
        decodedData = [[NSData alloc] initWithBase64Encoding:encodedString];
    }
    
    return decodedData;
}

/*!
 Creates an NSString object that contains the Base64 encoding of the
 NSData. Each line is 64 characters long.
 @param data NSData to be Base64 encoded
 @return Base64 encoded string representation of data
 */
+ (NSString *)MATbase64EncodedStringFromData:(NSData *)data
{
    // Get NSString from NSData object in Base64
    NSString *encodedString = nil;
    
    // if iOS 7+
    if([data respondsToSelector:@selector(base64EncodedStringWithOptions:)])
    {
        encodedString = [data base64EncodedStringWithOptions:0];
    }
    else
    {
        encodedString = [data base64Encoding];
    }
    
    return encodedString;
}

+ (NSString *)hashMd5:(NSString *)input
{
    NSMutableString *strHash = nil;
    
    if(input)
    {
        const char *cStr = [input UTF8String];
        unsigned char hash[CC_MD5_DIGEST_LENGTH];
        
        if ( CC_MD5( cStr, (unsigned int)strlen(cStr), hash ) )
        {
            strHash = [NSMutableString string];
            
            for (int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i)
            {
                [strHash appendFormat:@"%02x", hash[i]];
            }
        }
    }
    
    return strHash;
}

+ (NSString *)hashSha1:(NSString *)input
{
    NSMutableString *strHash = nil;
    
    if(input)
    {
        const char *cStr = [input UTF8String];
        unsigned char hash[CC_SHA1_DIGEST_LENGTH];
        
        if ( CC_SHA1( cStr, (unsigned int)strlen(cStr), hash ) )
        {
            strHash = [NSMutableString string];
            
            for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i)
            {
                [strHash appendFormat:@"%02x", hash[i]];
            }
        }
    }
    
    return strHash;
}

+ (NSString *)hashSha256:(NSString *)input
{
    NSMutableString *strHash = nil;
    
    if(input)
    {
        const char *cStr = [input UTF8String];
        unsigned char hash[CC_SHA256_DIGEST_LENGTH];
        
        if ( CC_SHA256( cStr, (unsigned int)strlen(cStr), hash ) )
        {
            strHash = [NSMutableString string];
            
            for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i)
            {
                [strHash appendFormat:@"%02x", hash[i]];
            }
        }
    }
    
    return strHash;
}


@end