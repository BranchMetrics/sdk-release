//
//  TuneAppToAppTracker.m
//  Tune
//
//  Created by John Bender on 2/27/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import <MobileCoreServices/UTType.h>

#import "TuneAppToAppTracker.h"
#import "TuneHttpRequest.h"
#import "TuneKeyStrings.h"
#import "TuneNetworkUtils.h"
#import "TuneUserProfileKeys.h"
#import "TuneUtils.h"

static NSString * const TUNE_PASTEBOARD_NAME_TRACKING_COOKIE = @"com.tune.sdkpbref";

static NSString * const TUNE_APP_TO_APP_TRACKING_STATUS = @"TUNE_APP_TO_APP_TRACKING_STATUS";

static const NSInteger TUNE_APP_TO_APP_REQUEST_FAILED_ERROR_CODE = 1401;
static const NSInteger TUNE_APP_TO_APP_RESPONSE_ERROR_CODE = 1402;

@interface TuneAppToAppTracker() {
    NSOperationQueue *sendQueue;
    void (^completionHandler)(NSData *data, NSURLResponse *response, NSError *connectionError);
}
@end


@implementation TuneAppToAppTracker

- (id)init {
    if( self = [super init] ) {
        sendQueue = [NSOperationQueue new];
    }
    return self;
}

- (void)startMeasurementSessionForTargetBundleId:(NSString*)targetBundleId
                               publisherBundleId:(NSString*)publisherBundleId
                                    advertiserId:(NSString*)advertiserId
                                      campaignId:(NSString*)campaignId
                                     publisherId:(NSString*)publisherId
                                        redirect:(BOOL)shouldRedirect
                                      domainName:(NSString*)domainName {
    if( ![TuneNetworkUtils isNetworkReachable] ) return;
    
    if (!targetBundleId) targetBundleId = TUNE_STRING_EMPTY;
    if (!advertiserId) advertiserId = TUNE_STRING_EMPTY;
    if (!campaignId) campaignId = TUNE_STRING_EMPTY;
    if (!publisherId) publisherId = TUNE_STRING_EMPTY;
    
    NSString *strLink = [NSString stringWithFormat:@"%@://%@/%@?%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@",
                         TUNE_KEY_HTTPS, domainName, TUNE_SERVER_PATH_TRACKING_ENGINE,
                         TUNE_KEY_ACTION, TUNE_EVENT_CLICK,
                         TUNE_KEY_PUBLISHER_ADVERTISER_ID, advertiserId,
                         TUNE_KEY_PACKAGE_NAME, targetBundleId,
                         TUNE_KEY_CAMPAIGN_ID, campaignId,
                         TUNE_KEY_PUBLISHER_ID, publisherId,
                         TUNE_KEY_RESPONSE_FORMAT, TUNE_KEY_XML];
    
    DebugLog(@"app-to-app tracking link: %@", strLink);
    
    NSMutableDictionary *dictItems = [NSMutableDictionary dictionary];
    [dictItems setValue:targetBundleId forKey:TUNE_KEY_TARGET_BUNDLE_ID];
    [dictItems setValue:@(shouldRedirect) forKey:TUNE_KEY_REDIRECT];
    [dictItems setValue:publisherBundleId forKey:TUNE_KEY_PACKAGE_NAME];
    [dictItems setValue:advertiserId forKey:TUNE_KEY_ADVERTISER_ID];
    [dictItems setValue:campaignId forKey:TUNE_KEY_CAMPAIGN_ID];
    [dictItems setValue:publisherId forKey:TUNE_KEY_PUBLISHER_ID];
    
    NSURL * url = [NSURL URLWithString:strLink];
    NSURLRequest * request = [NSURLRequest requestWithURL:url
                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                          timeoutInterval:TUNE_NETWORK_REQUEST_TIMEOUT_INTERVAL];

    __weak typeof(self) weakSelf = self;
    completionHandler = ^(NSData *data, NSURLResponse *response, NSError *connectionError) {
        if( connectionError != nil )
            [weakSelf failedToRequestTrackingId:dictItems withError:connectionError];
        else
            [weakSelf storeToPasteBoardTrackingId:@{TUNE_KEY_SERVER_RESPONSE: data}];
    };
    
    // TODO: consider using common helper method in TuneHttpUtils
    if( [NSURLSession class] ) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        [[session dataTaskWithRequest:request completionHandler:completionHandler] resume];
    } else {
        SEL ector = @selector(sendAsynchronousRequest:queue:completionHandler:);
        if( [NSURLConnection respondsToSelector:ector] ) {
            // iOS 6
            NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:[NSURLConnection methodSignatureForSelector:ector]];
            [invocation setTarget:[NSURLConnection class]];
            [invocation setSelector:ector];
            [invocation setArgument:&request atIndex:2];
            [invocation setArgument:&sendQueue atIndex:3];
            void (^connectionCompletionHandler)(NSURLResponse *response, NSData *data, NSError *connectionError) =
            ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                completionHandler( data, response, connectionError );
            };
            [invocation setArgument:&connectionCompletionHandler atIndex:4];
            [invocation invoke];
        }
    }
}

- (void)failedToRequestTrackingId:(NSMutableDictionary *)params withError:(NSError *)error {
    DebugLog(@"failedToRequestTrackingId: dict = %@, error = %@", params, error);
    
    NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
    [errorDetails setValue:TUNE_KEY_ERROR_TUNE_APP_TO_APP_FAILURE forKey:NSLocalizedFailureReasonErrorKey];
    [errorDetails setValue:@"Failed to start app-to-app tracking." forKey:NSLocalizedDescriptionKey];
    [errorDetails setValue:error forKey:NSUnderlyingErrorKey];
    
    NSError *errorForUser = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN code:TUNE_APP_TO_APP_REQUEST_FAILED_ERROR_CODE userInfo:errorDetails];
    if( [_delegate respondsToSelector:@selector(queueRequestDidFailWithError:)] )
        [_delegate queueRequestDidFailWithError:errorForUser];
}

- (void)storeToPasteBoardTrackingId:(NSDictionary *)params {
    NSString *response = [[NSString alloc] initWithData:[params valueForKey:TUNE_KEY_SERVER_RESPONSE] encoding:NSUTF8StringEncoding];
    
    DebugLog(@"TuneUtils storeToPasteBoardTrackingId: %@", response);
    
    NSString *strSuccess = [TuneUtils parseXmlString:response forTag:TUNE_KEY_SUCCESS];
    NSString *strRedirectUrl = [TuneUtils parseXmlString:response forTag:TUNE_KEY_URL];
//#if TARGET_OS_IOS
//    NSString *strTrackingId = [TuneUtils parseXmlString:response forTag:TUNE_KEY_TRACKING_ID];
//    NSString *strPublisherBundleId = [params valueForKey:TUNE_KEY_PACKAGE_NAME];
//    NSNumber *strTargetBundleId = [params valueForKey:TUNE_KEY_TARGET_BUNDLE_ID];
//#endif
    NSNumber *strRedirect = [params valueForKey:TUNE_KEY_REDIRECT];
    
    DebugLog(@"Success = %@, RedirectUrl = %@, Redirect = %@", strSuccess, strRedirectUrl, strRedirect);
    
    BOOL success = [strSuccess boolValue];
    BOOL redirect = [strRedirect boolValue];
    
    if(success) {
//#if TARGET_OS_IOS
//        UIPasteboard * cookiePasteBoard = [UIPasteboard pasteboardWithName:TUNE_PASTEBOARD_NAME_TRACKING_COOKIE create:YES];
//        
//        if (cookiePasteBoard) {
//            cookiePasteBoard.persistent = YES;
//
//            NSString *sessionDate = [NSString stringWithFormat:@"%ld", (long)round( [[NSDate date] timeIntervalSince1970] )];
//
//            NSMutableDictionary *itemsDict = [NSMutableDictionary dictionary];
//            [itemsDict setValue:strPublisherBundleId forKey:TUNE_KEY_PACKAGE_NAME];
//            [itemsDict setValue:strTrackingId forKey:TUNE_KEY_TRACKING_ID];
//            [itemsDict setValue:sessionDate forKey:TUNE_KEY_SESSION_DATETIME];
//            [itemsDict setValue:strTargetBundleId forKey:TUNE_KEY_TARGET_BUNDLE_ID];
//            
//            //NSData * archivedData = [NSKeyedArchiver archivedDataWithRootObject:itemsDict];
//            //[cookiePasteBoard setValue:archivedData forPasteboardType:(NSString*)kUTTypeTagSpecificationKey];
//        }
//#endif
        
        NSString *successDetails = [NSString stringWithFormat:@"{\"%@\":{\"message\":\"Started app-to-app tracking.\",\"success\":\"%d\",\"redirect\":\"%d\",\"redirect_url\":\"%@\"}}", TUNE_APP_TO_APP_TRACKING_STATUS, success, redirect, strRedirectUrl ? strRedirectUrl : TUNE_STRING_EMPTY];
        NSData *successData = [successDetails dataUsingEncoding:NSUTF8StringEncoding];
        
        if( [_delegate respondsToSelector:@selector(queueRequestDidSucceedWithData:)] )
            [_delegate queueRequestDidSucceedWithData:successData];
        
        if(redirect && 0 < [strRedirectUrl length]) {
#if !TARGET_OS_WATCH
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:strRedirectUrl]];
#endif
        }
    } else {
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:TUNE_KEY_ERROR_TUNE_APP_TO_APP_FAILURE forKey:NSLocalizedFailureReasonErrorKey];
        [errorDetails setValue:@"Failed to start app-to-app tracking." forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:TUNE_KEY_ERROR_DOMAIN code:TUNE_APP_TO_APP_RESPONSE_ERROR_CODE userInfo:errorDetails];
        if( [_delegate respondsToSelector:@selector(queueRequestDidFailWithError:)] )
            [_delegate queueRequestDidFailWithError:error];
    }
}

+ (NSString*)getPublisherBundleId {
    return [TuneUtils getStringForKey:TUNE_KEY_PACKAGE_NAME fromPasteBoard:TUNE_PASTEBOARD_NAME_TRACKING_COOKIE];
}

+ (NSString*)getSessionDateTime {
    return [TuneUtils getStringForKey:TUNE_KEY_SESSION_DATETIME fromPasteBoard:TUNE_PASTEBOARD_NAME_TRACKING_COOKIE];
}

+ (NSString*)getAdvertiserId {
    return [TuneUtils getStringForKey:TUNE_KEY_ADVERTISER_ID fromPasteBoard:TUNE_PASTEBOARD_NAME_TRACKING_COOKIE];
}

+ (NSString*)getCampaignId {
    return [TuneUtils getStringForKey:TUNE_KEY_CAMPAIGN_ID fromPasteBoard:TUNE_PASTEBOARD_NAME_TRACKING_COOKIE];
}

+ (NSString*)getTrackingId {
    return [TuneUtils getStringForKey:TUNE_KEY_TRACKING_ID fromPasteBoard:TUNE_PASTEBOARD_NAME_TRACKING_COOKIE];
}

@end
