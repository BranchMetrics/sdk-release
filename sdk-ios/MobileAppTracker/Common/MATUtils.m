//
//  MATUtils.m
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/24/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "MATUtils.h"
#import "MATKeyStrings.h"
#import "MATConnectionManager.h"
#import "../MobileAppTracker.h"
#import "MATConnectionManager.h"

#import <MobileCoreServices/UTType.h>
#import <SystemConfiguration/SystemConfiguration.h>

#include <CommonCrypto/CommonDigest.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

const float MAT_IOS_VERSION_501 = 5.01f;

NSString * const PASTEBOARD_NAME_TRACKING_COOKIE = @"com.hasoffers.matsdkref";
NSString * const PASTEBOARD_NAME_FACEBOOK_APP = @"fb_app_attribution";

NSString * const MAT_APP_TO_APP_TRACKING_STATUS = @"MAT_APP_TO_APP_TRACKING_STATUS";

@interface MATUtils (PrivateMethods)

+ (NSString *)parseXmlString:(NSString *)strXml forTag:(NSString *)tag;

@end

@implementation MATUtils

static NSDateFormatter *dateFormatter = nil;

static BOOL _shouldDebug = NO;

+ (NSDateFormatter *)sharedDateFormatter
{
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale * usLocale = [[NSLocale alloc] initWithLocaleIdentifier:DEFAULT_LOCALE_IDENTIFIER];
        [dateFormatter setLocale:usLocale];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:DEFAULT_TIMEZONE]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [usLocale release];
    }
    
    return dateFormatter;
}

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


+ (NSString*)generateUserAgentString
{    
    // perform this code on the main thread, since it creates a UIWebView.
    __block NSString *userAgent = STRING_EMPTY;
    
    void(^block)(void)=  ^{
        UIWebView* webView = [[UIWebView alloc] init];
        userAgent = [[webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"] copy];
        [webView release], webView = nil;
    };
 
    // Make sure that the dispatch_sync call does not get dead-locked when called on the main thread
    // Ref: http://stackoverflow.com/questions/5225130/grand-central-dispatch-gcd-vs-performselector-need-a-better-explanation/5226271#5226271
    if([NSThread isMainThread])
    {
        // execute the code on the current (main) thread
        block();
    }
    else
    {
        // synchronously execute the code on the main thread
        dispatch_sync(dispatch_get_main_queue(), block);
    }
    
    return [userAgent autorelease];
}


+ (NSString*)generateFBCookieIdString
{
    NSString * attributionID = nil;
    
    UIPasteboard *pb = [UIPasteboard pasteboardWithName:PASTEBOARD_NAME_FACEBOOK_APP create:NO];
    if (pb)
    {
        attributionID = [pb.string copy];
    }
    
    return [attributionID autorelease];
}

+ (NSString *)getUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);

    return [( NSString *)string autorelease];
}

+ (void)startTrackingSessionForTargetBundleId:(NSString*)targetBundleId
                            publisherBundleId:(NSString*)publisherBundleId
                                 advertiserId:(NSString*)advertiserId
                                   campaignId:(NSString*)campaignId
                                  publisherId:(NSString*)publisherId
                                     redirect:(BOOL)shouldRedirect
                           connectionDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate
{
    if (!targetBundleId) targetBundleId = STRING_EMPTY;
    if (!advertiserId) advertiserId     = STRING_EMPTY;
    if (!campaignId) campaignId         = STRING_EMPTY;
    if (!publisherId) publisherId       = STRING_EMPTY;
    
    NSString *domainName = [MATUtils serverDomainName];
    
    NSString *strLink = [NSString stringWithFormat:@"%@://%@/%@?%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@",
                                                   @"https", domainName, SERVER_PATH_TRACKING_ENGINE,
                                                   KEY_ACTION, EVENT_CLICK,
                                                   KEY_PUBLISHER_ADVERTISER_ID, advertiserId,
                                                   KEY_PACKAGE_NAME, targetBundleId,
                                                   KEY_CAMPAIGN_ID, campaignId,
                                                   KEY_PUBLISHER_ID, publisherId,
                                                   KEY_RESPONSE_FORMAT, KEY_XML];
    
    DLog(@"app-to-app tracking link: %@", strLink);
    
    NSMutableDictionary *dictItems = [NSMutableDictionary dictionary];
    [dictItems setValue:targetBundleId forKey:KEY_TARGET_BUNDLE_ID];
    [dictItems setValue:[NSNumber numberWithBool:shouldRedirect] forKey:KEY_REDIRECT];
    [dictItems setValue:publisherBundleId forKey:KEY_PACKAGE_NAME];
    [dictItems setValue:advertiserId forKey:KEY_ADVERTISER_ID];
    [dictItems setValue:campaignId forKey:KEY_CAMPAIGN_ID];
    [dictItems setValue:publisherId forKey:KEY_PUBLISHER_ID];
    
    MATConnectionManager *cm = [MATConnectionManager sharedManager];
    
    [cm beginRequestGetTrackingId:strLink
               withDelegateTarget:[MATUtils class]
              withSuccessSelector:@selector(storeToPasteBoardTrackingId:)
              withFailureSelector:@selector(failedToRequestTrackingId:withError:)
                     withArgument:dictItems
                     withDelegate:connectionDelegate];
}

+ (void)sendRequestGetInstallLogIdWithLink:(NSString *)weblink
                                    params:(NSMutableDictionary*)params
                        connectionDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate
{
    // fire a network request to fetch the install_log_id from the server
    
    // Sample Request:
    //https://engine.stage.mobileapptracking.com/v1/Integrations/Sdk/GetLog.csv?debug=13&sdk=android&package_name=com.hasofferstestapp&advertiser_id=877&data=77f89db08afe4cefd98babeb5eef7c604adf8e83e6c5d3c9c296d1641b0a4404ec0031e49da11404da1bbf728f15ca1663f63a9e77bf15b7a86dfb1218f15e5d&fields[]=log_id&fields[]=type
    
    // Sample Response:
    //513e26ffeb323-20130311-1,install
    
    DLog(@"requestInstallLogId: link = %@", weblink);
    
    [params setValue:[MobileAppTracker sharedManager] forKey:@"delegateTarget"];
    
    MATConnectionManager *cm = [MATConnectionManager sharedManager];
    
    [cm beginRequestGetInstallLogId:weblink
                 withDelegateTarget:[MATUtils class]
                withSuccessSelector:@selector(handleInstallLogId:)
                withFailureSelector:@selector(failedToRequestInstallLogId:withError:)
                       withArgument:params
                       withDelegate:connectionDelegate];
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
        int start = rangeStart.location + rangeStart.length;
        int end = rangeEnd.location;
        
        value = [strXml substringWithRange:NSMakeRange(start, end - start)];
    }
    
    return value;
}

+ (void)failedToRequestTrackingId:(NSMutableDictionary *)params withError:(NSError *)error
{
    DLog(@"failedToRequestTrackingId: dict = %@, error = %@", params, error);
    
    MobileAppTracker *mat = [MobileAppTracker sharedManager];
    
    NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
    [errorDetails setValue:KEY_ERROR_MAT_APP_TO_APP_FAILURE forKey:NSLocalizedFailureReasonErrorKey];
    [errorDetails setValue:@"Failed to start app-to-app tracking." forKey:NSLocalizedDescriptionKey];
    [errorDetails setValue:error forKey:NSUnderlyingErrorKey];
    
    NSError *errorForUser = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:1301 userInfo:errorDetails];
    [mat performSelector:NSSelectorFromString(@"notifyDelegateFailureWithError:") withObject:errorForUser];
}

+ (void)storeToPasteBoardTrackingId:(NSMutableDictionary *)params
{
    NSString *response = [[NSString alloc] initWithData:[params valueForKey:KEY_SERVER_RESPONSE] encoding:NSUTF8StringEncoding];

    DLog(@"MATUtils storeToPasteBoardTrackingId: %@", response);
    
    NSString *strSuccess = [self parseXmlString:response forTag:KEY_SUCCESS];
    NSString *strRedirectUrl = [self parseXmlString:response forTag:KEY_URL];
    NSString *strTrackingId = [self parseXmlString:response forTag:KEY_TRACKING_ID];
    NSString *strPublisherBundleId = [params valueForKey:KEY_PACKAGE_NAME];
    NSNumber *strTargetBundleId = [params valueForKey:KEY_TARGET_BUNDLE_ID];
    NSNumber *strRedirect = [params valueForKey:KEY_REDIRECT];

    DLog(@"Success = %@, TrackingId = %@, RedirectUrl = %@, TargetBundleId = %@, Redirect = %@", strSuccess, strTrackingId, strRedirectUrl, strTargetBundleId, strRedirect);
    
    BOOL success = [strSuccess boolValue];
    BOOL redirect = [strRedirect boolValue];
    
    MobileAppTracker *mat = [MobileAppTracker sharedManager];
    
    if(success)
    {
        UIPasteboard * cookiePasteBoard = [UIPasteboard pasteboardWithName:PASTEBOARD_NAME_TRACKING_COOKIE create:YES];
        if (cookiePasteBoard)
        {
            cookiePasteBoard.persistent = YES;
            
            NSMutableDictionary * itemsDict = [NSMutableDictionary dictionary];
            [itemsDict setValue:strPublisherBundleId forKey:KEY_PACKAGE_NAME];
            [itemsDict setValue:strTrackingId forKey:KEY_TRACKING_ID];
            [itemsDict setValue:[MATUtils formattedCurrentDateTime] forKey:KEY_SESSION_DATETIME];
            [itemsDict setValue:strTargetBundleId forKey:KEY_TARGET_BUNDLE_ID];
            
            NSData * archivedData = [NSKeyedArchiver archivedDataWithRootObject:itemsDict];
            [cookiePasteBoard setValue:archivedData forPasteboardType:(NSString*)kUTTypeTagSpecificationKey];
        }
        
        NSString *successDetails = [NSString stringWithFormat:@"{\"%@\":{\"message\":\"Started app-to-app tracking.\",\"success\":\"%d\",\"redirect\":\"%d\",\"redirect_url\":\"%@\"}}", MAT_APP_TO_APP_TRACKING_STATUS, success, redirect, strRedirectUrl ? strRedirectUrl : STRING_EMPTY];
        
        [mat performSelector:NSSelectorFromString(@"notifyDelegateSuccessMessage:") withObject:successDetails];
        
        if(redirect && strRedirectUrl && 0 < strRedirectUrl.length)
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:strRedirectUrl]];
        }
    }
    else
    {
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:KEY_ERROR_MAT_APP_TO_APP_FAILURE forKey:NSLocalizedFailureReasonErrorKey];
        [errorDetails setValue:@"Failed to start app-to-app tracking." forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:1302 userInfo:errorDetails];
        [mat performSelector:NSSelectorFromString(@"notifyDelegateFailureWithError:") withObject:error];
    }
    [response release]; response = nil;
}

+ (NSString *)formattedCurrentDateTime
{
    return [[MATUtils sharedDateFormatter] stringFromDate:[NSDate date]];
}

+ (void)stopTrackingSession
{
    UIPasteboard * cookiePasteBoard = [UIPasteboard pasteboardWithName:PASTEBOARD_NAME_TRACKING_COOKIE create:NO];
    if (cookiePasteBoard)
    {
        [UIPasteboard removePasteboardWithName:PASTEBOARD_NAME_TRACKING_COOKIE];
    }
}

+ (BOOL)isTrackingSessionStartedForTargetApplication:(NSString*)targetBundleId
{
    // get the target bundle id that another app_with_MAT_SDK might have stored on the pasteboard
    NSString * storedBundleId = [MATUtils getStringForKey:KEY_TARGET_BUNDLE_ID fromPasteBoard:PASTEBOARD_NAME_TRACKING_COOKIE];
    
    DLog(@"isTrackingSessionStartedForTargetApplication: pb_name = %@", PASTEBOARD_NAME_TRACKING_COOKIE);
    DLog(@"isTrackingSessionStartedForTargetApplication: stored = %@, target = %@", storedBundleId, targetBundleId);
    
    // a tracking session would exist if the target bundle id stored on the pasteboard matches the current target bundle id
    return storedBundleId && NSOrderedSame == [storedBundleId caseInsensitiveCompare:targetBundleId];
}

+ (NSString*)getPublisherBundleId
{
    return [MATUtils getStringForKey:KEY_PACKAGE_NAME fromPasteBoard:PASTEBOARD_NAME_TRACKING_COOKIE];
}

+ (NSString*)getSessionDateTime
{
    return [MATUtils getStringForKey:KEY_SESSION_DATETIME fromPasteBoard:PASTEBOARD_NAME_TRACKING_COOKIE];
}

+ (NSString*)getAdvertiserId
{
    return [MATUtils getStringForKey:KEY_ADVERTISER_ID fromPasteBoard:PASTEBOARD_NAME_TRACKING_COOKIE];
}

+ (NSString*)getCampaignId
{
    return [MATUtils getStringForKey:KEY_CAMPAIGN_ID fromPasteBoard:PASTEBOARD_NAME_TRACKING_COOKIE];
}

+ (NSString*)getTrackingId
{
    return [MATUtils getStringForKey:KEY_TRACKING_ID fromPasteBoard:PASTEBOARD_NAME_TRACKING_COOKIE];
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
    return [defaults valueForKey:key];
}

+ (void)setUserDefaultValue:(id)value forKey:(NSString* )key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:value forKey:key];
    
    // Note: Moved this synchronize call to MobileAppTracker handleNotification: -- UIApplicationWillResignActiveNotification notification,
    // so that the synchronize method instead of being called for each key, gets called only once just before the app becomes inactive.
    //[defaults synchronize];
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
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:KEY_CFBUNDLEIDENTIFIER];
}

+ (BOOL)isNetworkReachable
{
    DLog(@"MATUtils: isNetworkReachable: status = %d", [[MATReachability reachabilityForInternetConnection] currentReachabilityStatus]);
    return NotReachable != [[MATReachability reachabilityForInternetConnection] currentReachabilityStatus];
}

#pragma mark - install_log_id request handler methods

+ (void)handleInstallLogId:(NSMutableDictionary *)params
{
    DLog(@"MATUtils handleInstallLogId: params = %@", params);
    
    if([[MobileAppTracker sharedManager] respondsToSelector:@selector(handleInstallLogId:)])
    {
        [[MobileAppTracker sharedManager] performSelector:@selector(handleInstallLogId:) withObject:params];
    }
}

+ (void)failedToRequestInstallLogId:(NSMutableDictionary *)params withError:(NSError *)error
{
    DLog(@"MATUtils failedToRequestInstallLogId: params = %@, \nerror = %@", params, error);
    
    if([[MobileAppTracker sharedManager] respondsToSelector:@selector(failedToRequestInstallLogId:withError:)])
    {
        [[MobileAppTracker sharedManager] performSelector:@selector(failedToRequestInstallLogId:withError:) withObject:params withObject:error];
    }
}

// Gets the float value equivalent of the iOS system version string x.y.z.
// Note: This method assumes that the individual sub-version components -- y or z -- have values between 0..9.
+ (float)getNumericiOSVersion:(NSString *)iOSVersion
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
        float systemVersion = [MATUtils getNumericiOSVersion:[[UIDevice currentDevice] systemVersion]];
        
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
            success = [URL setResourceValue:[NSNumber numberWithBool:YES]
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

+ (NSString *)serverDomainName
{
    NSString *domainName = nil;
    
    if([[[MobileAppTracker sharedManager].sdkDataParameters valueForKey:KEY_STAGING] boolValue])
    {
        domainName = SERVER_DOMAIN_REGULAR_TRACKING_STAGE;
    }
    else
    {
        // on PROD, use a different server domain name when DEBUG MODE is enabled
        domainName = _shouldDebug ? SERVER_DOMAIN_REGULAR_TRACKING_PROD_DEBUG : SERVER_DOMAIN_REGULAR_TRACKING_PROD;
    }
    
    DLLog(@"MATUtils serverDomainName: stage  = %d", [[[MobileAppTracker sharedManager].sdkDataParameters valueForKey:KEY_STAGING] boolValue]);
    DLLog(@"MATUtils serverDomainName: debug  = %d", _shouldDebug);
    DLLog(@"MATUtils serverDomainName: domain = %@", domainName);
    
    return domainName;
}

+ (void)setShouldDebug:(BOOL)yesorno
{
    _shouldDebug = yesorno;
}

#pragma mark - Base64 Encoding/Decoding Methods

//////////////////////////////////
//
//  NSData+Base64.m
//  base64
//
//  Created by Matt Gallagher on 2009/06/03.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//
//////////////////////////////////

//
// Mapping from 6 bit pattern to ASCII character.
//
static unsigned char MATbase64EncodeLookup[65] =
"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

//
// Definition for "masked-out" areas of the base64DecodeLookup mapping
//
#define xx 65

//
// Mapping from ASCII character to 6 bit pattern.
//
static unsigned char MATbase64DecodeLookup[256] =
{
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, 62, xx, xx, xx, 63,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, xx, xx, xx, xx, xx, xx,
    xx,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, xx, xx, xx, xx, xx,
    xx, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
    xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx, xx,
};

//
// Fundamental sizes of the binary and base64 encode/decode units in bytes
//
#define BINARY_UNIT_SIZE 3
#define BASE64_UNIT_SIZE 4

//
// NewBase64Decode
//
// Decodes the base64 ASCII string in the inputBuffer to a newly malloced
// output buffer.
//
//  inputBuffer - the source ASCII string for the decode
//	length - the length of the string or -1 (to specify strlen should be used)
//	outputLength - if not-NULL, on output will contain the decoded length
//
// returns the decoded buffer. Must be free'd by caller. Length is given by
//	outputLength.
//
void *MATNewBase64Decode(
                         const char *inputBuffer,
                         size_t length,
                         size_t *outputLength)
{
	if (length == -1)
	{
		length = strlen(inputBuffer);
	}
	
	size_t outputBufferSize =
    ((length+BASE64_UNIT_SIZE-1) / BASE64_UNIT_SIZE) * BINARY_UNIT_SIZE;
	unsigned char *outputBuffer = (unsigned char *)malloc(outputBufferSize);
	
	size_t i = 0;
	size_t j = 0;
	while (i < length)
	{
		//
		// Accumulate 4 valid characters (ignore everything else)
		//
		unsigned char accumulated[BASE64_UNIT_SIZE];
		size_t accumulateIndex = 0;
		while (i < length)
		{
			unsigned char decode = MATbase64DecodeLookup[inputBuffer[i++]];
			if (decode != xx)
			{
				accumulated[accumulateIndex] = decode;
				accumulateIndex++;
				
				if (accumulateIndex == BASE64_UNIT_SIZE)
				{
					break;
				}
			}
		}
		
		//
		// Store the 6 bits from each of the 4 characters as 3 bytes
		//
		// (Uses improved bounds checking suggested by Alexandre Colucci)
		//
		if(accumulateIndex >= 2)
			outputBuffer[j] = (accumulated[0] << 2) | (accumulated[1] >> 4);
		if(accumulateIndex >= 3)
			outputBuffer[j + 1] = (accumulated[1] << 4) | (accumulated[2] >> 2);
		if(accumulateIndex >= 4)
			outputBuffer[j + 2] = (accumulated[2] << 6) | accumulated[3];
		j += accumulateIndex - 1;
	}
	
	if (outputLength)
	{
		*outputLength = j;
	}
	return outputBuffer;
}

//
// NewBase64Encode
//
// Encodes the arbitrary data in the inputBuffer as base64 into a newly malloced
// output buffer.
//
//  inputBuffer - the source data for the encode
//	length - the length of the input in bytes
//  separateLines - if zero, no CR/LF characters will be added. Otherwise
//		a CR/LF pair will be added every 64 encoded chars.
//	outputLength - if not-NULL, on output will contain the encoded length
//		(not including terminating 0 char)
//
// returns the encoded buffer. Must be free'd by caller. Length is given by
//	outputLength.
//
char *MATNewBase64Encode(
                         const void *buffer,
                         size_t length,
                         bool separateLines,
                         size_t *outputLength)
{
	const unsigned char *inputBuffer = (const unsigned char *)buffer;
	
#define MAX_NUM_PADDING_CHARS 2
#define OUTPUT_LINE_LENGTH 64
#define INPUT_LINE_LENGTH ((OUTPUT_LINE_LENGTH / BASE64_UNIT_SIZE) * BINARY_UNIT_SIZE)
#define CR_LF_SIZE 2
	
	//
	// Byte accurate calculation of final buffer size
	//
	size_t outputBufferSize =
    ((length / BINARY_UNIT_SIZE)
     + ((length % BINARY_UNIT_SIZE) ? 1 : 0))
    * BASE64_UNIT_SIZE;
	if (separateLines)
	{
		outputBufferSize +=
        (outputBufferSize / OUTPUT_LINE_LENGTH) * CR_LF_SIZE;
	}
	
	//
	// Include space for a terminating zero
	//
	outputBufferSize += 1;
    
	//
	// Allocate the output buffer
	//
	char *outputBuffer = (char *)malloc(outputBufferSize);
	if (!outputBuffer)
	{
		return NULL;
	}
    
	size_t i = 0;
	size_t j = 0;
	const size_t lineLength = separateLines ? INPUT_LINE_LENGTH : length;
	size_t lineEnd = lineLength;
	
	while (true)
	{
		if (lineEnd > length)
		{
			lineEnd = length;
		}
        
		for (; i + BINARY_UNIT_SIZE - 1 < lineEnd; i += BINARY_UNIT_SIZE)
		{
			//
			// Inner loop: turn 48 bytes into 64 base64 characters
			//
			outputBuffer[j++] = MATbase64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
			outputBuffer[j++] = MATbase64EncodeLookup[((inputBuffer[i] & 0x03) << 4)
                                                      | ((inputBuffer[i + 1] & 0xF0) >> 4)];
			outputBuffer[j++] = MATbase64EncodeLookup[((inputBuffer[i + 1] & 0x0F) << 2)
                                                      | ((inputBuffer[i + 2] & 0xC0) >> 6)];
			outputBuffer[j++] = MATbase64EncodeLookup[inputBuffer[i + 2] & 0x3F];
		}
		
		if (lineEnd == length)
		{
			break;
		}
		
		//
		// Add the newline
		//
		outputBuffer[j++] = '\r';
		outputBuffer[j++] = '\n';
		lineEnd += lineLength;
	}
	
	if (i + 1 < length)
	{
		//
		// Handle the single '=' case
		//
		outputBuffer[j++] = MATbase64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
		outputBuffer[j++] = MATbase64EncodeLookup[((inputBuffer[i] & 0x03) << 4)
                                                  | ((inputBuffer[i + 1] & 0xF0) >> 4)];
		outputBuffer[j++] = MATbase64EncodeLookup[(inputBuffer[i + 1] & 0x0F) << 2];
		outputBuffer[j++] =	'=';
	}
	else if (i < length)
	{
		//
		// Handle the double '=' case
		//
		outputBuffer[j++] = MATbase64EncodeLookup[(inputBuffer[i] & 0xFC) >> 2];
		outputBuffer[j++] = MATbase64EncodeLookup[(inputBuffer[i] & 0x03) << 4];
		outputBuffer[j++] = '=';
		outputBuffer[j++] = '=';
	}
	outputBuffer[j] = 0;
	
	//
	// Set the output length and return the buffer
	//
	if (outputLength)
	{
		*outputLength = j;
	}
	return outputBuffer;
}

//
// dataFromBase64String:
//
// Creates an NSData object containing the base64 decoded representation of
// the base64 string 'aString'
//
// Parameters:
//    aString - the base64 string to decode
//
// returns the autoreleased NSData representation of the base64 string
//
+ (NSData *)MATdataFromBase64String:(NSString *)aString
{
	NSData *data = [aString dataUsingEncoding:NSASCIIStringEncoding];
	size_t outputLength;
	void *outputBuffer = MATNewBase64Decode([data bytes], [data length], &outputLength);
	NSData *result = [NSData dataWithBytes:outputBuffer length:outputLength];
	free(outputBuffer);
	return result;
}

//
// base64EncodedString
//
// Creates an NSString object that contains the base 64 encoding of the
// receiver's data. Lines are broken at 64 characters long.
//
// returns an autoreleased NSString being the base 64 representation of the
//	receiver.
//
+ (NSString *)MATbase64EncodedStringFromData:(NSData *)data
{
	size_t outputLength;
	char *outputBuffer =
    MATNewBase64Encode([data bytes], [data length], false, &outputLength);
	
	NSString *result =
    [
     [[NSString alloc] initWithBytes:outputBuffer
                              length:outputLength
                            encoding:NSASCIIStringEncoding]
     autorelease]
    ;
	free(outputBuffer);
	return result;
}

@end