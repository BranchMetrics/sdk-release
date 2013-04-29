//
//  MATUtils.m
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/24/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "MATUtils.h"
#import "MATUserAgent.h"
#import "MATOpenUDID.h"
#import "MATKeyStrings.h"
#import "MATConnectionManager.h"
#import "MobileAppTracker.h"
#import "MATConnectionManager.h"

#import <MobileCoreServices/UTType.h>
#import <SystemConfiguration/SystemConfiguration.h>

#include <CommonCrypto/CommonDigest.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

const float IOS_VERSION_501 = 5.01f;

NSString * const PASTEBOARD_NAME_TRACKING_COOKIE = @"com.hasoffers.matsdkref";
NSString * const PASTEBOARD_NAME_FACEBOOK_APP = @"fb_app_attribution";

NSString * const MAT_APP_TO_APP_TRACKING_STATUS = @"MAT_APP_TO_APP_TRACKING_STATUS";

@interface MATUtils (PrivateMethods)

+ (NSString *)parseXmlString:(NSString *)strXml forTag:(NSString *)tag;

@end

@implementation MATUtils

static NSDateFormatter *dateFormatter = nil;

static BOOL _shouldDebug = FALSE;

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
    
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&fromDate
                 interval:NULL forDate:fromDateTime];
    [calendar rangeOfUnit:NSDayCalendarUnit startDate:&toDate
                 interval:NULL forDate:toDateTime];
    
    NSDateComponents *difference = [calendar components:NSDayCalendarUnit
                                               fromDate:fromDate toDate:toDate options:0];
    
    return [difference day];
}


+ (NSString*)generateUserAgentString
{    
    MATUserAgent * userAgent = [[MATUserAgent alloc] init];
    NSString * agentString = [userAgent.agentString copy];
    [userAgent release]; userAgent = nil;
    
    return [agentString autorelease];
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

+ (NSString*)generateODIN1String
{
    NSString * odinString = nil;
    
    const unsigned int addrBufSize = 6;
    
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    unsigned char addrBuf[addrBufSize];
    [self generateMacAddressString:&addrBuf[0]];
    if (CC_SHA1(addrBuf, addrBufSize, digest))
    {
        odinString = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                      digest[0], digest[1], digest[2], digest[3], digest[4], digest[5], digest[6], digest[7], digest[8], digest[9], 
                      digest[10], digest[11], digest[12], digest[13], digest[14], digest[15], digest[16], digest[17], digest[18], digest[19]];
    }
    
    return odinString;
}

+ (NSString *)generateMacAddressString:(unsigned char*)dataBuf
{
    int mgmtInfoBase[6];
    char *msgBuffer = NULL;
    NSString *errorFlag = NULL;
    size_t length;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET; // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE; // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK; // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST; // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
        errorFlag = @"if_nametoindex failure";
    // Get the size of the data available (store in len)
    else if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
        errorFlag = @"sysctl mgmtInfoBase failure";
    // Alloc memory based on above call
    else if ((msgBuffer = malloc(length)) == NULL)
        errorFlag = @"buffer allocation failure";
    // Get system information, store in buffer
    else if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
    {
        free(msgBuffer);
        errorFlag = @"sysctl msgBuffer failure";
    }
    else
    {
        // Map msgbuffer to interface message structure
        struct if_msghdr *interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
        
        // Map to link-level socket structure
        struct sockaddr_dl *socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
        
        // Copy link layer address data in socket structure to an array
        unsigned char macAddress[6];        
        memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
        
        if (dataBuf)
        {
            memcpy(dataBuf, &macAddress[0], 6);
        }
        
        // Read from char array into a string object, into traditional Mac address format
        NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                                      macAddress[0], macAddress[1], macAddress[2], macAddress[3], macAddress[4], macAddress[5]];
        
        // Release the buffer memory
        free(msgBuffer);

        return macAddressString;
    }
    
    // Error...    
    return errorFlag;
}

+ (NSString *)getUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);

    return [( NSString *)string autorelease];    
}

+ (NSString *)getOpenUDID
{
    return [MATOpenUDID value];
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
                                                   KEY_HTTPS, domainName, SERVER_PATH_TRACKING_ENGINE,
                                                   KEY_ACTION, EVENT_CLICK,
                                                   KEY_PUBLISHER_ADVERTISER_ID, advertiserId,
                                                   KEY_PACKAGE_NAME, targetBundleId,
                                                   KEY_CAMPAIGN_ID, campaignId,
                                                   KEY_PUBLISHER_ID, publisherId,
                                                   KEY_RESPONSE_FORMAT, KEY_XML];
    
#if DEBUG_LOG
    NSLog(@"app-to-app tracking link: %@", strLink);
#endif
    
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

+ (void)sendRequestGetInstallLogIdWithLink:(NSString *)link
                                    params:(NSMutableDictionary*)params
                        connectionDelegate:(id<MATConnectionManagerDelegate>)connectionDelegate
{
    // fire a network request to fetch the install_log_id from the server
    
    // Sample Request:
    //http://engine.stage.mobileapptracking.com/v1/Integrations/Sdk/GetLog.csv?debug=13&sdk=android&package_name=com.hasofferstestapp&advertiser_id=877&data=77f89db08afe4cefd98babeb5eef7c604adf8e83e6c5d3c9c296d1641b0a4404ec0031e49da11404da1bbf728f15ca1663f63a9e77bf15b7a86dfb1218f15e5d&fields[]=log_id&fields[]=type
    
    // Sample Response:
    //513e26ffeb323-20130311-1,install
    
#if DEBUG_LOG
    NSLog(@"requestInstallLogId: link = %@", link);
#endif
    
    [params setValue:[MobileAppTracker sharedManager] forKey:@"delegateTarget"];
    
    MATConnectionManager *cm = [MATConnectionManager sharedManager];
    
    [cm beginRequestGetInstallLogId:link
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
#if DEBUG_LOG
    NSLog(@"failedToRequestTrackingId: dict = %@, error = %@", params, error);
#endif
    
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

#if DEBUG_LOG
    NSLog(@"%@", response);
#endif
    
    NSString *strSuccess = [self parseXmlString:response forTag:KEY_SUCCESS];
    NSString *strRedirectUrl = [self parseXmlString:response forTag:KEY_URL];
    NSString *strTrackingId = [self parseXmlString:response forTag:KEY_TRACKING_ID];
    NSString *strPublisherBundleId = [params valueForKey:KEY_PACKAGE_NAME];
    NSNumber *strTargetBundleId = [params valueForKey:KEY_TARGET_BUNDLE_ID];
    NSNumber *strRedirect = [params valueForKey:KEY_REDIRECT];

#if DEBUG_LOG
    NSLog(@"Success = %@, TrackingId = %@, RedirectUrl = %@, TargetBundleId = %@, Redirect = %@", strSuccess, strTrackingId, strRedirectUrl, strTargetBundleId, strRedirect);
#endif
    
    bool success = [strSuccess boolValue];
    bool redirect = [strRedirect boolValue];
    
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
    // get the target bundle id that another app_with_mat_sdk might have stored on the pasteboard
    NSString * storedBundleId = [MATUtils getStringForKey:KEY_TARGET_BUNDLE_ID fromPasteBoard:PASTEBOARD_NAME_TRACKING_COOKIE];

#if DEBUG_LOG
    NSLog(@"isTrackingSessionStartedForTargetApplication: pb_name = %@", PASTEBOARD_NAME_TRACKING_COOKIE);
    NSLog(@"isTrackingSessionStartedForTargetApplication: stored = %@, target = %@", storedBundleId, targetBundleId);
#endif
    
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
    [defaults synchronize];
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
                                @"/Applications/RockApp.app",
                                @"/Applications/Icy.app",
                                @"/usr/sbin/sshd",
                                @"/usr/bin/sshd",
                                @"/usr/libexec/sftp-server",
                                @"/Applications/WinterBoard.app",
                                @"/Applications/SBSettings.app",
                                @"/Applications/MxTube.app",
                                @"/Applications/IntelliScreen.app",
                                @"/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
                                @"/Applications/FakeCarrier.app",
                                @"/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
                                @"/private/var/lib/apt",
                                @"/Applications/blackra1n.app",
                                @"/private/var/stash",
                                @"/private/var/mobile/Library/SBSettings/Themes",
                                @"/System/Library/LaunchDaemons/com.ikey.bbot.plist",
                                @"/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
                                @"/private/var/tmp/cydia.log",
                                @"/private/var/lib/cydia", nil];
    
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
            // METHOD 3: Check if the standard Foundation framework is present at the expected file path.
            
            // There's no shell access, but check if we are being cheated
            
            // class is NSFileManager and method is fileExistsAtPath:
            Class class = NSClassFromString(@"NSFileManager");
            SEL method = NSSelectorFromString(@"fileExistsAtPath:");
            
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

+ (NSString *)getMacAddress
{    
    return [[[MATUtils generateMacAddressString:NULL] copy] autorelease];
}

+ (NSString *)bundleId
{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:KEY_CFBUNDLEIDENTIFIER];
}

+ (BOOL)isNetworkReachable
{
#if DEBUG_LOG
    NSLog(@"MATUtils: isNetworkReachable");
    NSLog(@"MATUtils: isNetworkReachable: status = %d", [[MATReachability reachabilityForInternetConnection] currentReachabilityStatus]);
#endif
    return NotReachable != [[MATReachability reachabilityForInternetConnection] currentReachabilityStatus];
}

#pragma mark - install_log_id request handler methods

+ (void)handleInstallLogId:(NSMutableDictionary *)params
{
#if DEBUG_LOG
    NSLog(@"MATUtils handleInstallLogId: params = %@", params);
#endif
    
    if([[MobileAppTracker sharedManager] respondsToSelector:@selector(handleInstallLogId:)])
    {
        [[MobileAppTracker sharedManager] performSelector:@selector(handleInstallLogId:) withObject:params];
    }
}

+ (void)failedToRequestInstallLogId:(NSMutableDictionary *)params withError:(NSError *)error
{
#if DEBUG_LOG
    NSLog(@"MATUtils failedToRequestInstallLogId: params = %@, \nerror = %@", params, error);
#endif
    
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
#if DEBUG_LOG
    NSLog(@"MATUtils.addSkipBackupAttributeToItemAtURL: %@", URL);
#endif
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);
    
    float systemVersion = [MATUtils getNumericiOSVersion:[[UIDevice currentDevice] systemVersion]];
    
    BOOL success = FALSE;
    
    if(systemVersion == IOS_VERSION_501)
    {
        const char* filePath = [[URL path] fileSystemRepresentation];
        
        const char* attrName = "com.apple.MobileBackup";
        u_int8_t attrValue = 1;
        
        int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
        success = result == 0;
    }
    else if(systemVersion > IOS_VERSION_501)
    {
        NSError *error = nil;
        success = [URL setResourceValue:[NSNumber numberWithBool:YES]
                                 forKey:NSURLIsExcludedFromBackupKey
                                  error:&error];
#if DEBUG_LOG
        if(!success)
        {
            NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
        }
#endif
    }
    
    return success;
}

+ (NSString *)serverDomainName
{
    //domainName = @"api.dev.platform.hasservers.com";
    //domainName = @"dev.engine.mobileapptracking.com"
    
    NSString *domainName = nil;
    
    if([[[MobileAppTracker sharedManager].sdkDataParameters valueForKey:KEY_STAGING] boolValue])
    {
        domainName = SERVER_DOMAIN_REGULAR_TRACKING_STAGE;
    }
    else
    {
        // when debugging on PROD, use a different server domain name
        domainName = (_shouldDebug ? SERVER_DOMAIN_REGULAR_TRACKING_PROD_DEBUG : SERVER_DOMAIN_REGULAR_TRACKING_PROD);
    }
#if DEBUG_LINK_LOG
    NSLog(@"MATUtils serverDomainName: stage  = %d", [[[MobileAppTracker sharedManager].sdkDataParameters valueForKey:KEY_STAGING] boolValue]);
    NSLog(@"MATUtils serverDomainName: debug  = %d", _shouldDebug);
    NSLog(@"MATUtils serverDomainName: domain = %@", domainName);
#endif
    
    return domainName;
}

+ (void)setShouldDebug:(BOOL)yesorno
{
    _shouldDebug = yesorno;
}

@end