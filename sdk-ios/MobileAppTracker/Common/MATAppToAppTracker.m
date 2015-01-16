//
//  MATAppToAppTracker.m
//  MobileAppTracker
//
//  Created by John Bender on 2/27/14.
//  Copyright (c) 2014 HasOffers. All rights reserved.
//

#import <MobileCoreServices/UTType.h>

#import "MATAppToAppTracker.h"
#import "MATKeyStrings.h"
#import "MATReachability.h"
#import "MATUtils.h"

static NSString * const PASTEBOARD_NAME_TRACKING_COOKIE = @"com.hasoffers.matsdkref";

static NSString * const MAT_APP_TO_APP_TRACKING_STATUS = @"MAT_APP_TO_APP_TRACKING_STATUS";

static const NSInteger MAT_APP_TO_APP_REQUEST_FAILED_ERROR_CODE = 1401;
static const NSInteger MAT_APP_TO_APP_RESPONSE_ERROR_CODE = 1402;

@interface MATAppToAppTracker()
{
    MATReachability *reachability;
}
@end


@implementation MATAppToAppTracker

-(id) init
{
    self = [super init];
    if( self ) {
        reachability = [MATReachability reachabilityForInternetConnection];
    }
    return self;
}

- (void)startTrackingSessionForTargetBundleId:(NSString*)targetBundleId
                            publisherBundleId:(NSString*)publisherBundleId
                                 advertiserId:(NSString*)advertiserId
                                   campaignId:(NSString*)campaignId
                                  publisherId:(NSString*)publisherId
                                     redirect:(BOOL)shouldRedirect
                                   domainName:(NSString*)domainName
{
    if( [reachability currentReachabilityStatus] == NotReachable ) return;
    
    if (!targetBundleId) targetBundleId = MAT_STRING_EMPTY;
    if (!advertiserId) advertiserId = MAT_STRING_EMPTY;
    if (!campaignId) campaignId = MAT_STRING_EMPTY;
    if (!publisherId) publisherId = MAT_STRING_EMPTY;
    
    NSString *strLink = [NSString stringWithFormat:@"%@://%@/%@?%@=%@&%@=%@&%@=%@&%@=%@&%@=%@&%@=%@",
                         @"https", domainName, MAT_SERVER_PATH_TRACKING_ENGINE,
                         MAT_KEY_ACTION, MAT_EVENT_CLICK,
                         MAT_KEY_PUBLISHER_ADVERTISER_ID, advertiserId,
                         MAT_KEY_PACKAGE_NAME, targetBundleId,
                         MAT_KEY_CAMPAIGN_ID, campaignId,
                         MAT_KEY_PUBLISHER_ID, publisherId,
                         MAT_KEY_RESPONSE_FORMAT, MAT_KEY_XML];
    
    DLog(@"app-to-app tracking link: %@", strLink);
    
    NSMutableDictionary *dictItems = [NSMutableDictionary dictionary];
    [dictItems setValue:targetBundleId forKey:MAT_KEY_TARGET_BUNDLE_ID];
    [dictItems setValue:@(shouldRedirect) forKey:MAT_KEY_REDIRECT];
    [dictItems setValue:publisherBundleId forKey:MAT_KEY_PACKAGE_NAME];
    [dictItems setValue:advertiserId forKey:MAT_KEY_ADVERTISER_ID];
    [dictItems setValue:campaignId forKey:MAT_KEY_CAMPAIGN_ID];
    [dictItems setValue:publisherId forKey:MAT_KEY_PUBLISHER_ID];
    
    NSURL * url = [NSURL URLWithString:strLink];
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url
                                                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                        timeoutInterval:MAT_NETWORK_REQUEST_TIMEOUT_INTERVAL];

    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0 ), ^{
        NSError *err;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&err];
        if( err != nil ) {
            [self failedToRequestTrackingId:dictItems withError:err];
        } else {
            [self storeToPasteBoardTrackingId:@{MAT_KEY_SERVER_RESPONSE: data}];
        }
    });
}


- (void)failedToRequestTrackingId:(NSMutableDictionary *)params withError:(NSError *)error
{
    DLog(@"failedToRequestTrackingId: dict = %@, error = %@", params, error);
    
    NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
    [errorDetails setValue:MAT_KEY_ERROR_MAT_APP_TO_APP_FAILURE forKey:NSLocalizedFailureReasonErrorKey];
    [errorDetails setValue:@"Failed to start app-to-app tracking." forKey:NSLocalizedDescriptionKey];
    [errorDetails setValue:error forKey:NSUnderlyingErrorKey];
    
    NSError *errorForUser = [NSError errorWithDomain:MAT_KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:MAT_APP_TO_APP_REQUEST_FAILED_ERROR_CODE userInfo:errorDetails];
    if( [_delegate respondsToSelector:@selector(queueRequestDidFailWithError:)] )
        [_delegate queueRequestDidFailWithError:errorForUser];
}


- (void)storeToPasteBoardTrackingId:(NSDictionary *)params
{
    NSString *response = [[NSString alloc] initWithData:[params valueForKey:MAT_KEY_SERVER_RESPONSE] encoding:NSUTF8StringEncoding];
    
    DLog(@"MATUtils storeToPasteBoardTrackingId: %@", response);
    
    NSString *strSuccess = [MATUtils parseXmlString:response forTag:MAT_KEY_SUCCESS];
    NSString *strRedirectUrl = [MATUtils parseXmlString:response forTag:MAT_KEY_URL];
    NSString *strTrackingId = [MATUtils parseXmlString:response forTag:MAT_KEY_TRACKING_ID];
    NSString *strPublisherBundleId = [params valueForKey:MAT_KEY_PACKAGE_NAME];
    NSNumber *strTargetBundleId = [params valueForKey:MAT_KEY_TARGET_BUNDLE_ID];
    NSNumber *strRedirect = [params valueForKey:MAT_KEY_REDIRECT];
    
    DLog(@"Success = %@, TrackingId = %@, RedirectUrl = %@, TargetBundleId = %@, Redirect = %@", strSuccess, strTrackingId, strRedirectUrl, strTargetBundleId, strRedirect);
    
    BOOL success = [strSuccess boolValue];
    BOOL redirect = [strRedirect boolValue];
    
    if(success)
    {
        UIPasteboard * cookiePasteBoard = [UIPasteboard pasteboardWithName:PASTEBOARD_NAME_TRACKING_COOKIE create:YES];
        if (cookiePasteBoard)
        {
            cookiePasteBoard.persistent = YES;

            NSString *sessionDate = [NSString stringWithFormat:@"%ld", (long)round( [[NSDate date] timeIntervalSince1970] )];

            NSMutableDictionary * itemsDict = [NSMutableDictionary dictionary];
            [itemsDict setValue:strPublisherBundleId forKey:MAT_KEY_PACKAGE_NAME];
            [itemsDict setValue:strTrackingId forKey:MAT_KEY_TRACKING_ID];
            [itemsDict setValue:sessionDate forKey:MAT_KEY_SESSION_DATETIME];
            [itemsDict setValue:strTargetBundleId forKey:MAT_KEY_TARGET_BUNDLE_ID];
            
            NSData * archivedData = [NSKeyedArchiver archivedDataWithRootObject:itemsDict];
            [cookiePasteBoard setValue:archivedData forPasteboardType:(NSString*)kUTTypeTagSpecificationKey];
        }
        
        NSString *successDetails = [NSString stringWithFormat:@"{\"%@\":{\"message\":\"Started app-to-app tracking.\",\"success\":\"%d\",\"redirect\":\"%d\",\"redirect_url\":\"%@\"}}", MAT_APP_TO_APP_TRACKING_STATUS, success, redirect, strRedirectUrl ? strRedirectUrl : MAT_STRING_EMPTY];
        NSData *successData = [successDetails dataUsingEncoding:NSUTF8StringEncoding];
        
        if( [_delegate respondsToSelector:@selector(queueRequestDidSucceedWithData:)] )
            [_delegate queueRequestDidSucceedWithData:successData];
        
        if(redirect && 0 < [strRedirectUrl length])
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:strRedirectUrl]];
        }
    }
    else
    {
        NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
        [errorDetails setValue:MAT_KEY_ERROR_MAT_APP_TO_APP_FAILURE forKey:NSLocalizedFailureReasonErrorKey];
        [errorDetails setValue:@"Failed to start app-to-app tracking." forKey:NSLocalizedDescriptionKey];
        
        NSError *error = [NSError errorWithDomain:MAT_KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:MAT_APP_TO_APP_RESPONSE_ERROR_CODE userInfo:errorDetails];
        if( [_delegate respondsToSelector:@selector(queueRequestDidFailWithError:)] )
            [_delegate queueRequestDidFailWithError:error];
    }
}


+ (NSString*)getPublisherBundleId
{
    return [MATUtils getStringForKey:MAT_KEY_PACKAGE_NAME fromPasteBoard:PASTEBOARD_NAME_TRACKING_COOKIE];
}

+ (NSString*)getSessionDateTime
{
    return [MATUtils getStringForKey:MAT_KEY_SESSION_DATETIME fromPasteBoard:PASTEBOARD_NAME_TRACKING_COOKIE];
}

+ (NSString*)getAdvertiserId
{
    return [MATUtils getStringForKey:MAT_KEY_ADVERTISER_ID fromPasteBoard:PASTEBOARD_NAME_TRACKING_COOKIE];
}

+ (NSString*)getCampaignId
{
    return [MATUtils getStringForKey:MAT_KEY_CAMPAIGN_ID fromPasteBoard:PASTEBOARD_NAME_TRACKING_COOKIE];
}

+ (NSString*)getTrackingId
{
    return [MATUtils getStringForKey:MAT_KEY_TRACKING_ID fromPasteBoard:PASTEBOARD_NAME_TRACKING_COOKIE];
}

@end
