//
//  TuneUtils.m
//  Tune
//
//  Created by Pavel Yurchenko on 7/24/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "TuneUtils.h"

#import "TuneKeyStrings.h"
#import "TuneSettings.h"
#import "TuneUtils.h"

#include <CommonCrypto/CommonDigest.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#if TARGET_OS_IOS
NSString * const PASTEBOARD_NAME_FACEBOOK_APP = @"fb_app_attribution";
#endif

static NSString* const USER_DEFAULT_KEY_PREFIX = @"_TUNE_";

TuneReachability *reachability;

#if TESTING
NSString *overrideNetworkStatus;
#endif

@implementation TuneUtils

+(void)initialize
{
#if !TARGET_OS_WATCH
    reachability = [TuneReachability reachabilityForInternetConnection];
    [reachability startNotifier];
#endif
}

+ (NSInteger)daysBetweenDate:(NSDate*)fromDateTime andDate:(NSDate*)toDateTime
{
    NSDate *fromDate;
    NSDate *toDate;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    [calendar rangeOfUnit:NSCalendarUnitDay
                startDate:&fromDate
                 interval:NULL
                  forDate:fromDateTime];
    [calendar rangeOfUnit:NSCalendarUnitDay
                startDate:&toDate
                 interval:NULL
                  forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSCalendarUnitDay
                                               fromDate:fromDate
                                                 toDate:toDate
                                                options:0];
    
    return [difference day];
}

#if TARGET_OS_IOS
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
#endif

+ (NSString *)getUUID
{
    return [[NSUUID UUID] UUIDString];
    /*
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    NSString *returnString = [(__bridge NSString*)string copy];
    CFRelease(string);
    
    return returnString;
     */
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
    
#if TARGET_OS_IOS
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
#endif
    
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
    
    // Note: Moved this synchronize call to Tune handleNotification: -- UIApplicationWillResignActiveNotification notification,
    // so that the synchronize method instead of being called for each key, gets called only once just before the app becomes inactive.
    //[defaults synchronize];
}

+ (void)synchronizeUserDefaults
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)checkJailBreak
{
#if TARGET_OS_SIMULATOR
    return NO;
#else

    // METHOD 1: Check for file paths of some commonly used hacks
    // array of jail broken paths
    NSArray *jailBrokenPaths = @[@"/Applications/Cydia.app",
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
                                @"/usr/sbin/sshd"];
    
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
#if TARGET_OS_IOS
        jailBroken = system (NULL) != 0;
#endif
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
#endif
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

#if !TARGET_OS_WATCH
+ (TuneNetworkStatus)networkReachabilityStatus
{
    TuneNetworkStatus stat = [reachability currentReachabilityStatus];
    
#if TESTING
    stat = overrideNetworkStatus && ![overrideNetworkStatus boolValue] ? TuneNotReachable : [reachability currentReachabilityStatus];
#endif
    
    return stat;
}
#endif

+ (BOOL)isNetworkReachable
{
    BOOL reachable = 
#if TARGET_OS_WATCH
    YES;
#else
    TuneNotReachable != [self networkReachabilityStatus];
    
#if TESTING
    reachable = overrideNetworkStatus ? [overrideNetworkStatus boolValue] : TuneNotReachable != [reachability currentReachabilityStatus];
#endif
#endif
    DLog(@"TuneUtils: isNetworkReachable: status = %d", reachable);
    
    return reachable;
}


#if TESTING

+ (void)overrideNetworkReachability:(NSString *)reachable
{
    overrideNetworkStatus = reachable;
}

#endif
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
#if TARGET_OS_WATCH
    return 2.0;
#else
    return [TuneUtils numericiOSVersion:[[UIDevice currentDevice] systemVersion]];
#endif
}

// Refer: http://developer.apple.com/library/ios/#qa/qa1719/_index.html#//apple_ref/doc/uid/DTS40011342
// How do I prevent files from being backed up to iCloud and iTunes?
//
// For iOS versions 5.0.1 and above set a flag to denote that the queue storage files should not be backed up on iCloud.
// No-op for iOS versions 5.0 and below.
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    DLog(@"TuneUtils addSkipBackupAttributeToItemAtURL: %@", URL);
    
    BOOL success = NO;
    
    if([[NSFileManager defaultManager] fileExistsAtPath: [URL path]])
    {
        NSError *error = nil;
        success = [URL setResourceValue:@(YES)
                                 forKey:NSURLIsExcludedFromBackupKey
                                  error:&error];
#if DEBUG_LOG
        if(!success)
        {
            NSLog(@"TuneUtils addSkipBackupAttributeToItemAtURL: Error excluding %@ from backup %@", [URL lastPathComponent], error);
        }
#endif
    }
    
    return success;
}

+ (NSString *)jsonSerialize:(id)object
{
    NSString *output = nil;
    
    if(object)
    {
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
+ (NSData *)tuneDataFromBase64String:(NSString *)encodedString
{
    NSData *decodedData = nil;
    
    // if iOS 7+
    if([NSData instancesRespondToSelector:@selector(initWithBase64EncodedString:options:)])
    {
        decodedData = [[NSData alloc] initWithBase64EncodedString:encodedString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    else
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        decodedData = [[NSData alloc] initWithBase64Encoding:encodedString];
#pragma clang diagnostic pop
    }
    
    return decodedData;
}

/*!
 Creates an NSString object that contains the Base64 encoding of the
 NSData. Each line is 64 characters long.
 @param data NSData to be Base64 encoded
 @return Base64 encoded string representation of data
 */
+ (NSString *)tuneBase64EncodedStringFromData:(NSData *)data
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        encodedString = [data base64Encoding];
#pragma clang diagnostic pop
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

+ (void)addUrlQueryParamValue:(id)value
                       forKey:(NSString*)key
                  queryParams:(NSMutableString*)params
{
    NSString *useString = [self urlEncodeQueryParamValue:value];
    
    if(useString)
    {
        [params appendFormat:@"&%@=%@", key, useString];
    }
}

+ (NSString *)urlEncodeQueryParamValue:(id)value
{
    NSString *useString = nil;
    
    if( value != nil )
    {
        if( [value isKindOfClass:[NSNumber class]] )
            useString = [(NSNumber*)value stringValue];
        else if( [value isKindOfClass:[NSDate class]] )
            useString = [@((long)round( [value timeIntervalSince1970] )) stringValue];
        else if( [value isKindOfClass:[NSString class]] )
            useString = [TuneUtils urlEncode:(NSString*)value];
    }
    
    return useString;
}

+ (CGSize)screenSize
{
    CGSize screenSize = CGSizeZero;
#if !TARGET_OS_WATCH
    // Make sure that the collected screen size is independent of the current device orientation,
    // when iOS version
    // >= 8.0 use "nativeBounds"
    // <  8.0 use "bounds"
    if([UIScreen instancesRespondToSelector:@selector(nativeBounds)])
    {
        CGSize nativeScreenSize = [[UIScreen mainScreen] nativeBounds].size;
        CGFloat nativeScreenScale = [[UIScreen mainScreen] nativeScale];
        screenSize = CGSizeMake(nativeScreenSize.width / nativeScreenScale, nativeScreenSize.height / nativeScreenScale);
    }
    else
    {
        screenSize = [[UIScreen mainScreen] bounds].size;
    }
#endif
    return screenSize;
}

/*!
 Determine width, height of the main screen depending on the current status bar orientation.
 Ref: http://stackoverflow.com/a/14809642
 */
+ (CGRect)screenBoundsForStatusBarOrientation
{
#if TARGET_OS_WATCH
    return CGRectZero; // TODO: fix of watchOS
#else
    // portrait screen size
    CGSize screenSize = [self screenSize];
    
    // if current status bar orientation is landscape, then swap the screen width-height values
    BOOL isLandscape = FALSE;
    if( [[UIApplication sharedApplication] respondsToSelector:@selector(statusBarOrientation)] ) {
        //isLandscape = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
        NSInteger orientation = (NSInteger)[[UIApplication sharedApplication] performSelector:@selector(statusBarOrientation)];
        isLandscape = (orientation == 3 || orientation == 4);
    }
    
    CGFloat curWidth = isLandscape ? screenSize.height : screenSize.width;
    CGFloat curHeight = isLandscape ? screenSize.width : screenSize.height;
    
    return CGRectMake(0, 0, curWidth, curHeight);
#endif
}


#pragma mark - String Helper Methods

+ (NSString *)urlEncode:(NSString *)string
{
    return [self urlEncode:string usingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)urlEncode:(NSString *)inputString usingEncoding:(NSStringEncoding)encoding
{
    NSString *encodedString = nil;
    
    if(inputString && (id)[NSNull null] != inputString)
    {
        CFStringRef stringRef = CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                        (CFStringRef)inputString,
                                                                        NULL,
                                                                        (CFStringRef)@"!*'\"();:@&=+$,/?%#[] ",
                                                                        CFStringConvertNSStringEncodingToEncoding(encoding));
        encodedString = [(__bridge NSString*)stringRef copy];
        CFRelease( stringRef );
    }
    
    return encodedString;
}

+ (void)logCharacterSet:(NSCharacterSet*)characterSet
{
    unichar unicharBuffer[20];
    int index = 0;
    
    for (unichar uc = 0; uc < (0xFFFF); uc ++)
    {
        if ([characterSet characterIsMember:uc])
        {
            unicharBuffer[index] = uc;
            
            index ++;
            
            if (index == 20)
            {
                NSString * characters = [NSString stringWithCharacters:unicharBuffer length:index];
                NSLog(@"%@", characters);
                
                index = 0;
            }
        }
    }
    
    if (index != 0)
    {
        NSString * characters = [NSString stringWithCharacters:unicharBuffer length:index];
        NSLog(@"%@", characters);
    }
}


#pragma mark - NSURLSession Helpers

+ (nullable NSData *)sendSynchronousDataTaskWithRequest:(nonnull NSURLRequest *)request forSession:(NSURLSession *)session returningResponse:(NSURLResponse *_Nullable*_Nullable)response error:(NSError *_Nullable*_Nullable)error {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSData *data = nil;
    [[session dataTaskWithRequest:request completionHandler:^(NSData *taskData, NSURLResponse *taskResponse, NSError *taskError) {
        data = taskData;
        if (response) {
            *response = taskResponse;
        }
        if (error) {
            *error = taskError;
        }
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return data;
}


@end
