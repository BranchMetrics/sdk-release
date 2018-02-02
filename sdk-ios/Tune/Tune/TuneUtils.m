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
#import <CommonCrypto/CommonDigest.h>
#import <MobileCoreServices/UTType.h>
#if TARGET_OS_IOS
#import <SystemConfiguration/SystemConfiguration.h>
#endif
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#import <UIKit/UIKit.h>

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

+ (NSString *)parseXmlString:(NSString *)strXml forTag:(NSString *)tag {
    NSString *value = nil;
    
    NSString *strStartTag = [NSString stringWithFormat:@"<%@>", tag];
    NSString *strEndTag = [NSString stringWithFormat:@"</%@>", tag];
    
    NSRange rangeStart = [strXml rangeOfString:strStartTag];
    NSRange rangeEnd = [strXml rangeOfString:strEndTag];
    
    if(NSNotFound != rangeStart.location && NSNotFound != rangeEnd.location) {
        NSInteger start = rangeStart.location + rangeStart.length;
        NSInteger end = rangeEnd.location;
        
        value = [strXml substringWithRange:NSMakeRange(start, end - start)];
    }
    
    return value;
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
        NSLog(@"TUNE: checkJailBreak: exception: %@", exception);
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
    NSDictionary *appAttrs = nil;
    
    // Use NSDocumentDirectory / NSCachesDirectory folder creation date as the app install date because this value persists across updates
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSSearchPathDirectory targetFolder = NSDocumentDirectory;
#if TARGET_OS_TV // || TARGET_OS_WATCH
    targetFolder = NSCachesDirectory;
#endif
    
    @try {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(targetFolder, NSUserDomainMask, YES);
        NSString *path = nil;
        if (paths.count > 0) {
            path = [paths objectAtIndex:0];
        } else {
            DebugLog(@"NSDocumentDirectory / NSCachesDirectory not found, falling back to NSBundle creation date.");
            path = [[TuneUtils currentBundle] bundlePath];
        }
        appAttrs = [fileManager attributesOfItemAtPath:path error:nil];
        date = appAttrs[NSFileCreationDate];
    } @catch (NSException *exception) {
        ErrorLog(@"An exception occurred while trying to extract folder creation date. Exception: %@", exception);
    }
    
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
            DebugLog(@"JSON serializer: error = %@, input = %@", error, object);
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
            DebugLog(@"JSON serializer: error = %@, input = %@", error, object);
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
            DebugLog(@"JSON de-serializer: error = %@, input = %@", error, [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]);
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

+ (id)objectStringOrNull:(id)object {
    return [object description] ?: [NSNull null];
}

+ (id)object:(id)object orDefault:(id)def {
    return object ?: def;
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

/*!
 Determine width, height of the main screen depending on the current status bar orientation.
 Ref: http://stackoverflow.com/a/14809642
 */
+ (CGRect)screenBoundsForStatusBarOrientation {
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

#pragma mark - Alert View Helper

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    [self showAlertWithTitle:title message:message completionBlock:nil];
}

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message completionBlock:(void (^)(void))completionHandler {
    if ([NSThread isMainThread]) {
        [self innerShowAlertWithTitle:title
                              message:message
                      completionBlock:completionHandler];
    } else {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self innerShowAlertWithTitle:title
                                  message:message
                          completionBlock:completionHandler];
        }];
    }
}

#if TARGET_OS_WATCH

+ (void)innerWatchShowAlertWithTitle:(NSString *)title message:(NSString *)message completionBlock:(void (^)(void))completionHandler {
    __block id block = completionHandler ? [completionHandler copy] : nil;
    
    if(isAlertVisible) {
        [alertTitles addObject:title];
        [alertMessages addObject:message];
        [alertCompletionBlocks addObject:(id)completionHandler ?: (id)[NSNull null]];
    } else {
        isAlertVisible = YES;
        
        WKAlertAction *alertAction = [WKAlertAction actionWithTitle:@"OK" style:WKAlertActionStyleCancel handler:^{
            isAlertVisible = NO;
            NSString *nextTitle = [alertTitles firstObject];
            NSString *nextMessage = [alertMessages firstObject];
            void (^nextBlock)(void) = alertCompletionBlocks.count > 0 ? [alertCompletionBlocks firstObject] : nil;
            
            if(nextTitle && nextMessage) {
                [TuneUtils showAlertWithTitle:nextTitle message:nextMessage completionBlock:nextBlock];
                [alertTitles removeObjectAtIndex:0];
                [alertMessages removeObjectAtIndex:0];
                [alertCompletionBlocks removeObjectAtIndex:0];
            }
            
            if(block && (id)[NSNull null] != (id)block) {
                void (^curBlock)(void) = (void (^)(void))block;
                curBlock();
            }
        }];
        
        [[[WKExtension sharedExtension] rootInterfaceController] presentAlertControllerWithTitle:title
                                                                                         message:message
                                                                                  preferredStyle:WKAlertControllerStyleAlert
                                                                                         actions:@[alertAction]];
    }
}

#elif TARGET_OS_TV

+ (void)innerTvosShowAlertWithTitle:(NSString *)title message:(NSString *)message completionBlock:(void (^)(void))completionHandler {
    if(isAlertVisible) {
        [alertTitles addObject:title];
        [alertMessages addObject:message];
        [alertCompletionBlocks addObject:(id)completionHandler ?: (id)[NSNull null]];
    } else {
        isAlertVisible = YES;
        
        __block id block = completionHandler ? [completionHandler copy] : nil;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    isAlertVisible = NO;
                                                    NSString *nextTitle = [alertTitles firstObject];
                                                    NSString *nextMessage = [alertMessages firstObject];
                                                    id blk = alertCompletionBlocks.count > 0 ? [alertCompletionBlocks firstObject] : nil;
                                                    void (^nextBlock)(void) = [NSNull null] == blk ? nil : blk;
                                                    
                                                    if(nextTitle && nextMessage) {
                                                        [TuneUtils showAlertWithTitle:nextTitle message:nextMessage completionBlock:nextBlock];
                                                        [alertTitles removeObjectAtIndex:0];
                                                        [alertMessages removeObjectAtIndex:0];
                                                        [alertCompletionBlocks removeObjectAtIndex:0];
                                                    }
                                                    
                                                    if(block && (id)[NSNull null] != (id)block) {
                                                        void (^curBlock)(void) = (void (^)(void))block;
                                                        curBlock();
                                                    }
                                                }]];
        
        // do not animate the alert view display, so as to reduce the time required and avoid clash with client app UI operations
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:alert animated:NO completion:nil];
    }
}

#elif TARGET_OS_IOS

+ (void)innerIosShowAlertWithTitle:(NSString *)title message:(NSString *)message completionBlock:(void (^)(void))completionHandler {
    if(NSClassFromString(@"UIAlertController")) {
        if(isAlertVisible) {
            [alertTitles addObject:title];
            [alertMessages addObject:message];
            [alertCompletionBlocks addObject:(id)completionHandler ?: (id)[NSNull null]];
        } else {
            isAlertVisible = YES;
            
            __block id block = completionHandler ? [completionHandler copy] : nil;
            
            static dispatch_once_t tuneAlertWindowOnceToken;
            dispatch_once(&tuneAlertWindowOnceToken, ^{
                tuneAlertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                tuneAlertWindow.windowLevel = UIWindowLevelAlert;
                tuneAlertWindow.rootViewController = [UIViewController new];
            });
            
            tuneAlertWindow.hidden = NO;
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        isAlertVisible = NO;
                                                        NSString *nextTitle = [alertTitles firstObject];
                                                        NSString *nextMessage = [alertMessages firstObject];
                                                        id blk = alertCompletionBlocks.count > 0 ? [alertCompletionBlocks firstObject] : nil;
                                                        void (^nextBlock)(void) = [NSNull null] == blk ? nil : blk;
                                                        
                                                        if(nextTitle && nextMessage) {
                                                            [TuneUtils showAlertWithTitle:nextTitle message:nextMessage completionBlock:nextBlock];
                                                            [alertTitles removeObjectAtIndex:0];
                                                            [alertMessages removeObjectAtIndex:0];
                                                            [alertCompletionBlocks removeObjectAtIndex:0];
                                                        } else {
                                                            tuneAlertWindow.hidden = YES;
                                                        }
                                                        
                                                        if(block && (id)[NSNull null] != (id)block) {
                                                            void (^curBlock)(void) = (void (^)(void))block;
                                                            curBlock();
                                                        }
                                                    }]];
            
            // do not animate the alert view display, so as to reduce the time required and avoid clash with client app UI operations
            [tuneAlertWindow.rootViewController presentViewController:alert animated:NO completion:nil];
        }
    } else {
        Class classUIAlertView = NSClassFromString(@"UIAlertView");
        id alert = [[classUIAlertView alloc] initWithTitle:title
                                                   message:message
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
        [alert show];
    }
}

#endif

+ (void)innerShowAlertWithTitle:(NSString *)title message:(NSString *)message completionBlock:(void (^)(void))completionHandler {
#if TESTING
    completionHandler();
    return;
#else
    
#if TARGET_OS_WATCH
    [self innerWatchShowAlertWithTitle:title message:message completionBlock:completionHandler];
#elif TARGET_OS_TV
    [self innerTvosShowAlertWithTitle:title message:message completionBlock:completionHandler];
#else
    [self innerIosShowAlertWithTitle:title message:message completionBlock:completionHandler];
#endif
    
#endif
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
