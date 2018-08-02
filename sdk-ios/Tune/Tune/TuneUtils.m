//
//  TuneUtils.m
//  Tune
//
//  Created by Pavel Yurchenko on 7/24/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "TuneUtils.h"
#import "TuneStringUtils.h"
#import "TuneKeyStrings.h"
#import "TuneManager.h"
#import "TuneUserDefaultsUtils.h"
#import "TuneUserProfile.h"
#import "TuneKeyStrings.h"
#import "TuneLog.h"
#import <CommonCrypto/CommonDigest.h>
#import <MobileCoreServices/UTType.h>
#if TARGET_OS_IOS
#import <SystemConfiguration/SystemConfiguration.h>
#endif
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#if TARGET_OS_IOS
NSString * const PASTEBOARD_NAME_FACEBOOK_APP = @"fb_app_attribution";
#endif

#if TARGET_OS_WATCH
#import <WatchKit/WatchKit.h>
#endif



NSMutableArray *alertTitles;
NSMutableArray *alertMessages;
NSMutableArray *alertCompletionBlocks;

#if TARGET_OS_IOS
UIWindow *tuneAlertWindow;
#endif

BOOL isAlertVisible;

@implementation TuneUtils

+(void)initialize {
    alertTitles = [NSMutableArray array];
    alertMessages = [NSMutableArray array];
    alertCompletionBlocks = [NSMutableArray array];
}

#if TARGET_OS_IOS
+ (NSString*)generateFBCookieIdString {
    NSString * attributionID = nil;
    
    UIPasteboard *pb = [UIPasteboard pasteboardWithName:PASTEBOARD_NAME_FACEBOOK_APP create:NO];
    if (pb) {
        attributionID = [pb.string copy];
    }
    
    return attributionID;
}
#endif

+ (NSString *)getUUID {
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

+ (Class)getClassFromString:(NSString *)className {
    // If class name exists in Obj-C, return it
    if (NSClassFromString(className)) {
        return NSClassFromString(className);
    }
    
    // Otherwise, try looking for the Swift class name
    NSString *appName = [[TuneUtils currentBundle] objectForInfoDictionaryKey:(__bridge NSString *)kCFBundleNameKey];
    // CFBundleName not found, return
    if (!appName) {
        return nil;
    }
    // Replace spaces with underscore in CFBundleName
    appName = [appName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString *classStringName = [NSString stringWithFormat:@"_TtC%lu%@%lu%@", (unsigned long)appName.length, appName, (unsigned long)className.length, className];
    return NSClassFromString(classStringName);
}

+ (NSString*)getStringForKey:(NSString*)key fromPasteBoard:(NSString *)pasteBoardName {
    NSString *storedValue = nil;
    
#if TARGET_OS_IOS
    UIPasteboard *cookiePasteBoard = [UIPasteboard pasteboardWithName:pasteBoardName create:NO];
    
    if (key && cookiePasteBoard) {
        NSDictionary * itemsDict = nil;
        id items = [cookiePasteBoard valueForPasteboardType:(NSString*)kUTTypeTagSpecificationKey];
        if (items) {
            itemsDict = [NSKeyedUnarchiver unarchiveObjectWithData:items];
        }
        
        if (itemsDict) {
            storedValue = [itemsDict objectForKey:key];
        }
    }
#endif
    
    return storedValue;
}

+ (BOOL)checkJailBreak {
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
    
    // An app crash was reported in some rare cases due to nil argument being passed to NSString hasPrefix:.
    // Use try-catch to make sure that if at all the exception occurs, it gets contained in-place and doesn't cause app crash.
    @try {
        for (NSString * path in jailBrokenPaths) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                jailBroken = YES;
                break;
            }
        }
        
        if(!jailBroken) {
            // METHOD 2: Check if a shell is present
            // Jailbroken devices have shell access, system(NULL) returns a non-zero value if a shell is present
    #if TARGET_OS_IOS
            // iOS 11 doesn't compile if this is called
            //jailBroken = system (NULL) != 0;
    #endif
            if(!jailBroken) {
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
    } @catch (NSException *exception) {
        NSString *errorMessage = [NSString stringWithFormat:@"TUNE: checkJailBreak: exception: %@", exception];
        [TuneLog.shared logError:errorMessage];
    }
    
    return jailBroken;
#endif
}

+ (NSBundle *)currentBundle {
    NSBundle *currentBundle = nil;
#if TESTING
    // Test resources are part of the test bundle, reroute to it instead of the main bundle.
    Class classTests = NSClassFromString(@"TuneUtilsTests");
    currentBundle = [NSBundle bundleForClass:classTests];

    // Why not use the more common [NSBundle bundleForClass:[self class]]?
    // Since TuneUtils is part of the framework, bundleForClass will return the framework bundle!
    // This leads to unit test failures due to missing data.
    // currentBundle = [NSBundle bundleForClass:[self class]];
#else
    
    // Within an app, configuration files and other resources are part of the main bundle.
    currentBundle = [NSBundle mainBundle];
#endif
    return currentBundle;
}

+ (NSString *)bundleId {
    return [[TuneUtils currentBundle] objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleIdentifierKey];
}

+ (NSString *)bundleName {
    return [[TuneUtils currentBundle] objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleNameKey];
}

+ (NSString *)bundleVersion {
    return [[TuneUtils currentBundle] objectForInfoDictionaryKey:(__bridge NSString*)kCFBundleVersionKey];
}

+ (NSString *)stringVersion {
    return [[TuneUtils currentBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (NSDate *)installDate {
    NSDate *date = nil;
    
    // First check the NSDocumentDirectory / NSCachesDirectory folder creation date as the app install date because this value persists across updates
    NSSearchPathDirectory targetFolder = NSDocumentDirectory;
#if TARGET_OS_TV
    targetFolder = NSCachesDirectory;
#endif
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(targetFolder, NSUserDomainMask, YES);
    if (paths.count > 0) {
        date = [self creationDateOfPath:[paths objectAtIndex:0]];
    }
    
    // Try the bundle creation date if NSDocumentDirectory / NSCachesDirectory is not available
    if (!date) {
        date = [self creationDateOfPath:[[TuneUtils currentBundle] bundlePath]];
    }
    
    return date;
}

+ (NSDate *)creationDateOfPath:(NSString *)path {
    NSDate *date = nil;
    
    NSError *error;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    if (error) {
        // Is this a severe error or just informational?
        //NSString *errorMessage = [NSString stringWithFormat:@"Failed to get creation date: %@", error];
        //[TuneLog.shared logError:errorMessage];
    }
    date = attributes[NSFileCreationDate];
    
    return date;
}

/*!
 Converts an iOS version string x.y.z to its equivalent float representation.
 
 Note: This method assumes that the individual sub-version components -- y or z -- have values between 0..9.
 */
+ (float)numericiOSVersion:(NSString *)iOSVersion {
    NSArray *arr = [iOSVersion componentsSeparatedByString:@"."];
    
    float version = 0;
    float factor = 1;
    
    for (NSString *component in arr) {
        version += ([component floatValue] * factor);
        factor /= 10;
    }
    
    return version;
}

/*!
 Numeric representation of the iOS system version string x.y.z.
 */
+ (float)numericiOSSystemVersion {
#if TARGET_OS_WATCH
    return [TuneUtils numericiOSVersion:[[WKInterfaceDevice currentDevice] systemVersion]];
#else
    return [TuneUtils numericiOSVersion:[[UIDevice currentDevice] systemVersion]];
#endif
}

+ (NSData *)jsonSerializedDataForObject:(id)object {
    NSData *output = nil;
    
    if(object && (id)[NSNull null] != object) {
        NSError *error;
        output = [NSJSONSerialization dataWithJSONObject:object
                                                 options:0
                                                   error:&error];
        if (error) {
            NSString *errorMessage = [NSString stringWithFormat:@"JSON serializer: error = %@, input = %@", error, object];
            [TuneLog.shared logError:errorMessage];
        }
    }
    
    return output;
}

+ (NSString *)jsonSerialize:(id)object {
    NSString *output = nil;
    
    if(object && (id)[NSNull null] != object) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                           options:0
                                                             error:&error];
        
        if (jsonData) {
            output = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"JSON serializer: error = %@, input = %@", error, object];
            [TuneLog.shared logError:errorMessage];
        }
    }
    
    return output;
}

+ (id)jsonDeserializeData:(NSData *)jsonData {
    id object = nil;
    
    if(jsonData && (id)[NSNull null] != jsonData && jsonData.length > 0) {
        NSError *error;
        object = [NSJSONSerialization JSONObjectWithData:jsonData
                                                 options:0
                                                   error:&error];
        
        if (error) {
            NSString *errorMessage = [NSString stringWithFormat:@"JSON de-serializer: error = %@, input = %@", error, [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
            [TuneLog.shared logError:errorMessage];
        }
    }
    
    return object;
}

+ (id)jsonDeserializeString:(NSString *)jsonString {
    return jsonString && (id)[NSNull null] != jsonString ? [self jsonDeserializeData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]] : nil;
}


#pragma mark - Base64 Encoding/Decoding Methods

/*!
 Creates an NSData object containing the Base64 decoded representation of
 the Base64 string.
 @param encodedString the Base64 string to decode
 @return NSData representation of the Base64 string
 */
+ (NSData *)tuneDataFromBase64String:(NSString *)encodedString {
    NSData *decodedData = nil;
    
    // if iOS 7+
    if([NSData instancesRespondToSelector:@selector(initWithBase64EncodedString:options:)]) {
        decodedData = [[NSData alloc] initWithBase64EncodedString:encodedString options:NSDataBase64DecodingIgnoreUnknownCharacters];
    } else {
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
+ (NSString *)tuneBase64EncodedStringFromData:(NSData *)data {
    // Get NSString from NSData object in Base64
    NSString *encodedString = nil;
    
    // if iOS 7+
    if([data respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        encodedString = [data base64EncodedStringWithOptions:0];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        encodedString = [data base64Encoding];
#pragma clang diagnostic pop
    }
    
    return encodedString;
}

+ (NSString *)hashMd5:(NSString *)input {
    NSMutableString *strHash = nil;
    
    if(input) {
        const char *cStr = [input UTF8String];
        unsigned char hash[CC_MD5_DIGEST_LENGTH];
        
        if ( CC_MD5( cStr, (unsigned int)strlen(cStr), hash ) ) {
            strHash = [NSMutableString string];
            
            for (int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i) {
                [strHash appendFormat:@"%02x", hash[i]];
            }
        }
    }
    
    return strHash;
}

+ (NSString *)hashSha1:(NSString *)input {
    NSMutableString *strHash = nil;
    
    if(input) {
        const char *cStr = [input UTF8String];
        unsigned char hash[CC_SHA1_DIGEST_LENGTH];
        
        if ( CC_SHA1( cStr, (unsigned int)strlen(cStr), hash ) ) {
            strHash = [NSMutableString string];
            
            for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; ++i) {
                [strHash appendFormat:@"%02x", hash[i]];
            }
        }
    }
    
    return strHash;
}

+ (NSString *)hashSha256:(NSString *)input {
    NSMutableString *strHash = nil;
    
    if(input) {
        const char *cStr = [input UTF8String];
        unsigned char hash[CC_SHA256_DIGEST_LENGTH];
        
        if ( CC_SHA256( cStr, (unsigned int)strlen(cStr), hash ) ) {
            strHash = [NSMutableString string];
            
            for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; ++i) {
                [strHash appendFormat:@"%02x", hash[i]];
            }
        }
    }
    
    return strHash;
}

+ (void)addUrlQueryParamValue:(id)value
                       forKey:(NSString*)key
                  queryParams:(NSMutableString*)params {
    NSString *useString = [self urlEncodeQueryParamValue:value];
    
    if(useString) {
        [params appendFormat:@"&%@=%@", key, useString];
    }
}

+ (NSString *)urlEncodeQueryParamValue:(id)value {
    NSString *useString = nil;
    
    if( value != nil ) {
        if([value isKindOfClass:[NSNumber class]]) {
            useString = [(NSNumber*)value stringValue];
        }
        else if([value isKindOfClass:[NSDate class]]) {
            useString = [@((long)round( [value timeIntervalSince1970] )) stringValue];
        }
        else if([value isKindOfClass:[NSString class]]) {
            useString = [TuneStringUtils urlEncodeString:value];
        }
    }
    
    return useString;
}

+ (id)objectOrNull:(id)object {
    return object ?: [NSNull null];
}

+ (CGSize)screenSize {
    CGSize screenSize = CGSizeZero;
#if !TARGET_OS_WATCH
    // Make sure that the collected screen size is independent of the current device orientation,
    // when iOS version
    // >= 8.0 use "nativeBounds"
    // <  8.0 use "bounds"
    if([UIScreen instancesRespondToSelector:@selector(nativeBounds)]) {
        CGSize nativeScreenSize = [[UIScreen mainScreen] nativeBounds].size;
        CGFloat nativeScreenScale = [[UIScreen mainScreen] nativeScale];
        screenSize = CGSizeMake(nativeScreenSize.width / nativeScreenScale, nativeScreenSize.height / nativeScreenScale);
    } else {
        screenSize = [[UIScreen mainScreen] bounds].size;
    }
#endif
    return screenSize;
}

#pragma mark - String Helper Methods

+ (NSString *)dictionaryAsQueryString:(NSDictionary *)dictionary withNamespace:(NSString *)namespaceString {
    NSArray *allKeys = [[dictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *queryStringPairs = [NSMutableArray array];
    
    NSString *escapedNamespaceString = nil;
    
    if (namespaceString.length) {
        escapedNamespaceString = [TuneStringUtils urlEncodeString:namespaceString];
    }
    
    for (id key in allKeys) {
        if ([key isKindOfClass:[NSString class]]) {
            NSString *keyString = (NSString *)key;
            id value = [dictionary valueForKey:key];
            
            if ([value isKindOfClass:[NSDictionary class]]) {
                [queryStringPairs addObject:[TuneUtils dictionaryAsQueryString:value withNamespace:keyString]];
            } else {
                if (![value isKindOfClass:[NSString class]]) {
                    value = [NSString stringWithFormat:@"%@", value];
                }
                
                NSString *escapedKey = [TuneStringUtils urlEncodeString:keyString];
                NSString *escapedValue = [TuneStringUtils urlEncodeString:value];
                
                if (escapedNamespaceString != nil) {
                    escapedKey = [NSString stringWithFormat:@"%@[%@]", escapedNamespaceString, escapedKey];
                }
                
                NSString *queryPair = [NSString stringWithFormat:@"%@=%@", escapedKey, escapedValue];
                [queryStringPairs addObject:queryPair];
            }
        }
    }
    
    return [queryStringPairs componentsJoinedByString:@"&"];
}

#pragma mark - NSObject Helpers

+ (BOOL)object:(id)receiver respondsToSelector:(SEL)aSelector {
    return [receiver respondsToSelector:aSelector];
}

#pragma mark -

+ (BOOL)isFirstSessionRequestComplete {
    return nil != [TuneUserDefaultsUtils userDefaultValueforKey:TUNE_KEY_OPEN_LOG_ID];
}

@end
