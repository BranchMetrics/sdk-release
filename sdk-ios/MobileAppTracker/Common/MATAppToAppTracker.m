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
#import "MATUtils.h"

static NSString * const PASTEBOARD_NAME_TRACKING_COOKIE = @"com.hasoffers.matsdkref";

static NSString * const MAT_APP_TO_APP_TRACKING_STATUS = @"MAT_APP_TO_APP_TRACKING_STATUS";


@implementation MATAppToAppTracker

- (void)startTrackingSessionForTargetBundleId:(NSString*)targetBundleId
                            publisherBundleId:(NSString*)publisherBundleId
                                 advertiserId:(NSString*)advertiserId
                                   campaignId:(NSString*)campaignId
                                  publisherId:(NSString*)publisherId
                                     redirect:(BOOL)shouldRedirect
                                   domainName:(NSString*)domainName
                            connectionManager:(MATConnectionManager*)connectionManager
{
    if (!targetBundleId) targetBundleId = STRING_EMPTY;
    if (!advertiserId) advertiserId = STRING_EMPTY;
    if (!campaignId) campaignId = STRING_EMPTY;
    if (!publisherId) publisherId = STRING_EMPTY;
    
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
    
    [connectionManager beginRequestGetTrackingId:strLink
                              withDelegateTarget:self
                             withSuccessSelector:@selector(storeToPasteBoardTrackingId:)
                             withFailureSelector:@selector(failedToRequestTrackingId:withError:)
                                    withArgument:dictItems];
}


- (void)failedToRequestTrackingId:(NSMutableDictionary *)params withError:(NSError *)error
{
    DLog(@"failedToRequestTrackingId: dict = %@, error = %@", params, error);
    
    NSMutableDictionary *errorDetails = [NSMutableDictionary dictionary];
    [errorDetails setValue:KEY_ERROR_MAT_APP_TO_APP_FAILURE forKey:NSLocalizedFailureReasonErrorKey];
    [errorDetails setValue:@"Failed to start app-to-app tracking." forKey:NSLocalizedDescriptionKey];
    [errorDetails setValue:error forKey:NSUnderlyingErrorKey];
    
    NSError *errorForUser = [NSError errorWithDomain:KEY_ERROR_DOMAIN_MOBILEAPPTRACKER code:1301 userInfo:errorDetails];
    [self.delegate connectionManager:(MATConnectionManager*)self didFailWithError:errorForUser];
}


- (void)storeToPasteBoardTrackingId:(NSMutableDictionary *)params
{
    NSString *response = [[NSString alloc] initWithData:[params valueForKey:KEY_SERVER_RESPONSE] encoding:NSUTF8StringEncoding];
    
    DLog(@"MATUtils storeToPasteBoardTrackingId: %@", response);
    
    NSString *strSuccess = [MATUtils parseXmlString:response forTag:KEY_SUCCESS];
    NSString *strRedirectUrl = [MATUtils parseXmlString:response forTag:KEY_URL];
    NSString *strTrackingId = [MATUtils parseXmlString:response forTag:KEY_TRACKING_ID];
    NSString *strPublisherBundleId = [params valueForKey:KEY_PACKAGE_NAME];
    NSNumber *strTargetBundleId = [params valueForKey:KEY_TARGET_BUNDLE_ID];
    NSNumber *strRedirect = [params valueForKey:KEY_REDIRECT];
    
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
            [itemsDict setValue:strPublisherBundleId forKey:KEY_PACKAGE_NAME];
            [itemsDict setValue:strTrackingId forKey:KEY_TRACKING_ID];
            [itemsDict setValue:sessionDate forKey:KEY_SESSION_DATETIME];
            [itemsDict setValue:strTargetBundleId forKey:KEY_TARGET_BUNDLE_ID];
            
            NSData * archivedData = [NSKeyedArchiver archivedDataWithRootObject:itemsDict];
            [cookiePasteBoard setValue:archivedData forPasteboardType:(NSString*)kUTTypeTagSpecificationKey];
        }
        
        NSString *successDetails = [NSString stringWithFormat:@"{\"%@\":{\"message\":\"Started app-to-app tracking.\",\"success\":\"%d\",\"redirect\":\"%d\",\"redirect_url\":\"%@\"}}", MAT_APP_TO_APP_TRACKING_STATUS, success, redirect, strRedirectUrl ? strRedirectUrl : STRING_EMPTY];
        NSData *successData = [successDetails dataUsingEncoding:NSUTF8StringEncoding];
        
        [self.delegate connectionManager:(MATConnectionManager*)self didSucceedWithData:successData];
        
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
        [self.delegate connectionManager:(MATConnectionManager*)self didFailWithError:error];
    }
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

@end
