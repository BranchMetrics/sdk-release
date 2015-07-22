//
//  TuneAdParams.m
//  Tune
//
//  Created by Harshal Ogale on 7/9/14.
//  Copyright (c) 2014 Tune. All rights reserved.
//

#import "TuneAdParams.h"
#import "TuneAdUtils.h"
#import "../Common/TuneSettings.h"
#import "../Common/TuneTracker.h"
#import "../Common/TuneUtils.h"
#import "../Common/TuneUserAgentCollector.h"
#import "../Common/Tune_internal.h"

@implementation TuneAdParams

+ (NSString *)jsonForAdType:(TuneAdType)adType placement:(NSString *)placement metadata:(TuneAdMetadata *)metadata orientations:(TuneAdOrientation)orientations
{
    return [self jsonForAdType:adType placement:placement metadata:metadata orientations:orientations ad:nil];
}

+ (NSString *)jsonForAdType:(TuneAdType)adType placement:(NSString *)placement metadata:(TuneAdMetadata *)metadata orientations:(TuneAdOrientation)orientations ad:(TuneAd *)ad
{
    TuneSettings *tuneParams = [[Tune sharedManager] parameters];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:[self appInfo:tuneParams] forKey:@"app"];
    [dict setValue:metadata ? @(metadata.debugMode) : tuneParams.debugMode forKey:@"debugMode"];
    [dict setValue:[self deviceInfo:tuneParams metadata:metadata] forKey:@"device"];
    [dict setValue:metadata.keywords forKey:@"keywords"];
    [dict setValue:metadata.customTargets forKey:@"targets"];
    [dict setValue:placement forKey:@"placement"];
    [dict setValue:tuneParams.lastOpenLogId forKey:@"lastOpenLogId"];
    [dict setValue:[self identifierInfo:tuneParams] forKey:@"ids"];
    [dict setValue:ad.refs forKey:@"refs"];
    [dict setValue:[self screenInfo:tuneParams] forKey:@"screen"];
    [dict setValue:TUNEVERSION forKey:@"sdkVersion"];
    [dict setValue:tuneParams.pluginName forKey:@"plugin"];
    [dict setValue:[self orientationInfo:tuneParams metadata:metadata orientations:orientations adType:adType] forKey:@"sizes"];
    [dict setValue:[self userInfo:tuneParams metadata:(TuneAdMetadata *)metadata] forKey:@"user"];
    
    // get current interface orientation
    UIInterfaceOrientation barOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    BOOL isLandscape = UIInterfaceOrientationIsLandscape(barOrientation);
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(barOrientation);
    
    NSString *currentOrientation = isLandscape ? @"landscape" : (isPortrait ? @"portrait" : @"unknown");
    [dict setValue:currentOrientation forKey:@"currentOrientation"];
    
    NSString *str = [TuneUtils jsonSerialize:dict];
    
    //DLog(@"json = %@", str);
    
    return str;
}

+ (NSDictionary *)deviceInfo:(TuneSettings *)tuneParams metadata:(TuneAdMetadata *)metadata
{
    NetworkStatus status = [TuneUtils networkReachabilityStatus];
    NSString *connectionType = NotReachable == status ? nil : (ReachableViaWiFi == status ? @"wifi" : @"mobile");
    
    NSTimeZone *currentTimeZone = [NSTimeZone localTimeZone];
    NSString *strTimezone = [currentTimeZone abbreviation];
    
    NSString *strCpuType = tuneParams.deviceCpuType ? [tuneParams.deviceCpuType stringValue] : TUNE_STRING_EMPTY;
    NSString *strCpuSubType = tuneParams.deviceCpuSubtype ? [tuneParams.deviceCpuSubtype stringValue] : TUNE_STRING_EMPTY;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:@"iOS" forKey:@"os"];
    [dict setValue:tuneParams.osVersion forKey:@"osVersion"];
    [dict setValue:tuneParams.deviceBrand forKey:@"deviceBrand"];
    [dict setValue:tuneParams.deviceModel forKey:@"deviceModel"];
    [dict setValue:tuneParams.countryCode forKey:@"country"];
    [dict setValue:tuneParams.language forKey:@"language"];
    [dict setValue:tuneParams.deviceCarrier forKey:@"deviceCarrier"];
    [dict setValue:strCpuType forKey:@"deviceCpuType"];
    [dict setValue:strCpuSubType forKey:@"deviceCpuSubType"];
    [dict setValue:tuneParams.mobileCountryCode forKey:@"mcc"];
    [dict setValue:tuneParams.mobileCountryCodeISO forKey:@"mccIso"];
    [dict setValue:tuneParams.mobileNetworkCode forKey:@"mnc"];
    
    [dict setValue:metadata ? [@(metadata.latitude) stringValue] : tuneParams.latitude forKey:@"latitude"];
    [dict setValue:metadata ? [@(metadata.longitude) stringValue] : tuneParams.longitude forKey:@"longitude"];
    [dict setValue:metadata ? [@(metadata.altitude) stringValue] : tuneParams.altitude forKey:@"altitude"];
    
    [dict setValue:[TuneUserAgentCollector userAgent] forKey:@"userAgent"];
    [dict setValue:tuneParams.jailbroken forKey:@"osJailbroke"];
    [dict setValue:connectionType forKey:@"connectionType"];
    [dict setValue:strTimezone forKey:@"timezone"];
    
    return dict;
}

+ (NSDictionary *)appInfo:(TuneSettings *)tuneParams
{
    NSString *keyCheck = [tuneParams.conversionKey substringFromIndex:tuneParams.conversionKey.length - 4];
    NSString *strInstallDate = [TuneAdUtils urlEncode:tuneParams.installDate];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:tuneParams.advertiserId forKey:@"advertiserId"];
    [dict setValue:keyCheck forKey:@"keyCheck"];
    [dict setValue:tuneParams.packageName forKey:@"package"];
    [dict setValue:strInstallDate forKey:@"installDate"];
    [dict setValue:tuneParams.appVersion forKey:@"version"];
    [dict setValue:tuneParams.appName forKey:@"name"];
    
    return dict;
}

+ (NSDictionary *)screenInfo:(TuneSettings *)tuneParams
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:tuneParams.screenHeight forKey:@"height"];
    [dict setValue:tuneParams.screenWidth forKey:@"width"];
    [dict setValue:tuneParams.screenDensity forKey:@"density"];
    
    return dict;
}

+ (NSDictionary *)userInfo:(TuneSettings *)tuneParams metadata:(TuneAdMetadata *)metadata
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setValue:tuneParams.userEmailMd5 forKey:@"userEmailMd5"];
    [dict setValue:tuneParams.userEmailSha1 forKey:@"userEmailSha1"];
    [dict setValue:tuneParams.userEmailSha256 forKey:@"userEmailSha256"];
    [dict setValue:tuneParams.userId forKey:@"userId"];
    [dict setValue:tuneParams.userNameMd5 forKey:@"userNameMd5"];
    [dict setValue:tuneParams.userNameSha1 forKey:@"userNameSha1"];
    [dict setValue:tuneParams.userNameSha256 forKey:@"userNameSha256"];
    [dict setValue:tuneParams.phoneNumberMd5 forKey:@"userPhoneMd5"];
    [dict setValue:tuneParams.phoneNumberSha1 forKey:@"userPhoneSha1"];
    [dict setValue:tuneParams.phoneNumberSha256 forKey:@"userPhoneSha256"];
    [dict setValue:tuneParams.facebookUserId forKey:@"facebookUserId"];
    [dict setValue:tuneParams.googleUserId forKey:@"googleUserId"];
    [dict setValue:tuneParams.twitterUserId forKey:@"twitterUserId"];
    [dict setValue:tuneParams.trusteTPID forKey:@"trusteTPID"];
    [dict setValue:tuneParams.payingUser forKey:@"payingUser"];
    
    if(metadata.birthDate)
    {
        NSString *strBirthDate = [TuneAdUtils urlEncode:metadata.birthDate];
        [dict setValue:strBirthDate forKey:@"birthDate"];
    }
    
    if(metadata)
    {
        [dict setValue:[@(metadata.gender) stringValue] forKey:@"gender"];
    }
    
    return dict;
}

+ (NSDictionary *)orientationInfo:(TuneSettings *)tuneParams metadata:(TuneAdMetadata *)metadata orientations:(TuneAdOrientation)orientations adType:(TuneAdType)adType
{
    BOOL isLandscape = TuneAdOrientationAll == orientations || TuneAdOrientationLandscape & orientations;
    BOOL isPortrait = TuneAdOrientationAll == orientations || TuneAdOrientationPortrait & orientations;
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    if(isPortrait)
    {
        NSNumber *ht = TuneAdTypeBanner == adType ? @([TuneAd bannerHeightPortrait]) : tuneParams.screenHeight;
        
        NSMutableDictionary *dictPortrait = [NSMutableDictionary dictionary];
        dictPortrait[@"width"]  = tuneParams.screenWidth;
        dictPortrait[@"height"] = ht;
        
        dict[@"portrait"]       = dictPortrait;
    }
    
    if(isLandscape)
    {
        NSNumber *ht = TuneAdTypeBanner == adType ? @([TuneAd bannerHeightLandscape]) : tuneParams.screenWidth;
        
        NSMutableDictionary *dictLandscape = [NSMutableDictionary dictionary];
        dictLandscape[@"width"]     = tuneParams.screenHeight;
        dictLandscape[@"height"]    = ht;
        
        dict[@"landscape"]          = dictLandscape;
    }
    
    return dict;
}

+ (NSDictionary *)identifierInfo:(TuneSettings *)tuneParams
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"matId"]             = tuneParams.matId;
    [dict setValue:tuneParams.ifa forKey:@"ifa"];
    dict[@"iosAdTracking"]     = @([tuneParams.ifaTracking boolValue]);
    [dict setValue:tuneParams.ifv forKey:@"ifv"];
    
    return dict;
}

@end
