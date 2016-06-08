//
//  TuneUserProfile.h
//  TuneMarketingConsoleSDK
//
//  Created by Daniel Koch on 8/3/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TuneAnalyticsVariable.h"
#import "TuneModule.h"

@class TuneLocation;
@class TunePreloadData;

@protocol TuneUserProfileDelegate;

@interface TuneUserProfile : TuneModule

@property (nonatomic, assign) id <TuneUserProfileDelegate> delegate;

/////////////////////////////////////////////////
#pragma mark - App ID Generators
/////////////////////////////////////////////////

#if TARGET_OS_IOS
- (void)loadFacebookCookieId;
#endif

#if !TARGET_OS_WATCH
- (void)updateIFA;
- (void)clearIFA;
#endif

- (NSString *)hashedAppId;

/////////////////////////////////////////////////
#pragma mark - Profile Variable Management
/////////////////////////////////////////////////

- (void) registerString:(NSString *)variableName;
- (void) registerString:(NSString *)variableName hashed:(BOOL)shouldAutoHash;
- (void) registerBoolean:(NSString *)variableName;
- (void) registerDateTime:(NSString *)variableName;
- (void) registerNumber:(NSString *)variableName;
- (void) registerGeolocation:(NSString *)variableName;
- (void) registerVersion:(NSString *)variableName;

- (void) registerString:(NSString *)variableName withDefault:(NSString *)value;
- (void) registerString:(NSString *)variableName withDefault:(NSString *) value hashed:(BOOL)shouldAutoHash;
- (void) registerBoolean:(NSString *)variableName withDefault:(NSNumber *)value;
- (void) registerDateTime:(NSString *)variableName withDefault:(NSDate *)value;
- (void) registerNumber:(NSString *)variableName withDefault:(NSNumber *)value;
- (void) registerGeolocation:(NSString *)variableName withDefault:(TuneLocation *)value;
- (void) registerVersion:(NSString *)variableName withDefault:(NSString *)value;

- (void) setStringValue:(NSString *)value forVariable:(NSString *)name;
- (void) setBooleanValue:(NSNumber *)value forVariable:(NSString *)name;
- (void) setDateTimeValue:(NSDate *)value forVariable:(NSString *)name;
- (void) setNumberValue:(NSNumber *)value forVariable:(NSString *)name;
- (void) setGeolocationValue:(TuneLocation *)value forVariable:(NSString *)name;
- (void) setVersionValue:(NSString *)value forVariable:(NSString *)name;

- (NSString *)getCustomProfileString:(NSString *)name;
- (NSNumber *)getCustomProfileNumber:(NSString *)name;
- (NSDate *)getCustomProfileDateTime:(NSString *)name;
- (TuneLocation *)getCustomProfileGeolocation:(NSString *)name;

- (void) clearVariable:(NSString *)key;
- (void) clearCustomVariables:(NSSet *)variables;
- (void) clearCustomProfile;

- (id) getProfileValue:(NSString *)key;
- (TuneAnalyticsVariable *) getProfileVariable:(NSString*)key;
- (NSDictionary *) getProfileVariables;

/////////////////////////////////////////////////
#pragma mark - Single-property Getters and Setters
/////////////////////////////////////////////////

- (BOOL)tooYoungForTargetedAds;

- (NSString *)deviceId;

- (NSString *)installReceipt;

- (void)setDeviceToken:(NSString *)deviceToken;
- (NSString *)deviceToken;

- (void)setPushEnabled:(NSString *)pushEnabled;
- (NSString *)pushEnabled;

- (void)setSessionId:(NSString *)sessionId;
- (NSString *)sessionId;

- (void)setLastSessionDate:(NSDate *)lastSessionDate;
- (NSDate *)lastSessionDate;

- (void)setCurrentSessionDate:(NSDate *)currentSessionDate;
- (NSDate *)currentSessionDate;

- (void)setSessionCount:(NSNumber *)count;
- (NSNumber *)sessionCount;

- (void)setInstallDate:(NSDate *)installDate;
- (NSDate *)installDate;

- (void)setSessionDate:(NSString *)sessionDate;
- (NSString *)sessionDate;

- (void)setSystemDate:(NSDate *)systemDate;
- (NSDate *)systemDate;

- (void)setTuneId:(NSString *)tuneId;
- (NSString *)tuneId;

- (void)setIsFirstSession:(NSNumber *)isFirstSession;
- (NSNumber *)isFirstSession;

- (void)setInstallLogId:(NSString *)installLogId;
- (NSString *)installLogId;

- (void)setUpdateLogId:(NSString *)updateLogId;
- (NSString *)updateLogId;

- (void)setOpenLogId:(NSString *)openLogId;
- (NSString *)openLogId;

- (void)setLastOpenLogId:(NSString *)lastOpenLogId;
- (NSString *)lastOpenLogId;

- (void)setAdvertiserId:(NSString *)advertiserId;
- (NSString *)advertiserId;

- (void)setConversionKey:(NSString *)conversionKey;
- (NSString *)conversionKey;

- (void)setAppBundleId:(NSString *)bId;
- (NSString *)appBundleId;

- (void)setAppName:(NSString *)appName;
- (NSString *)appName;

- (void)setAppVersion:(NSString *)appVersion;
- (NSString *)appVersion;

- (void)setAppVersionName:(NSString *)appVersionName;
- (NSString *)appVersionName;

- (void)setWearable:(NSNumber *)wearable;
- (NSNumber *)wearable;

- (void)setExistingUser:(NSNumber *)existingUser;
- (NSNumber *)existingUser;

- (void)setAppleAdvertisingIdentifier:(NSString *)advertisingId;
- (NSString *)appleAdvertisingIdentifier;

- (void)setAppleAdvertisingTrackingEnabled:(NSNumber *)adTrackingEnabled;
- (NSNumber *)appleAdvertisingTrackingEnabled;

- (void)setAppleVendorIdentifier:(NSString *)appleVendorIdentifier;
- (NSString *)appleVendorIdentifier;

- (void)setCurrencyCode:(NSString *)currencyCode;
- (NSString *)currencyCode;

- (void)setJailbroken:(NSNumber *)jailbroken;
- (NSNumber *)jailbroken;

- (void)setPackageName:(NSString *)packageName;
- (NSString *)packageName;

- (void)setTRUSTeId:(NSString *)tpid;
- (NSString *)trusteTPID;

- (void)setUserId:(NSString *)userId;
- (NSString *)userId;

- (void)setTrackingId:(NSString *)trackingId;
- (NSString *)trackingId;

- (void)setFacebookUserId:(NSString *)facebookUserId;
- (NSString *)facebookUserId;

- (void)setFacebookCookieId:(NSString *)facebookCookieId;
- (NSString *)facebookCookieId;

- (void)setTwitterUserId:(NSString *)twitterUserId;
- (NSString *)twitterUserId;

- (void)setGoogleUserId:(NSString *)googleUserId;
- (NSString *)googleUserId;

- (void)setAge:(NSNumber *)age;
- (NSNumber *)age;

- (void)setGender:(NSNumber *)gender;
- (NSNumber *)gender;

- (void)setAppAdTracking:(NSNumber *)enable;
- (NSNumber *)appAdTracking;

- (void)setLocationAuthorizationStatus:(NSNumber *)authStatus;
- (NSNumber *)locationAuthorizationStatus;

- (void)setBluetoothState:(NSNumber *)bluetoothState;
- (NSNumber *)bluetoothState;

- (void)setPayingUser:(NSNumber *)payingState;
- (NSNumber *)payingUser;

- (void)setOsType:(NSString *)osType;
- (NSString *)osType;

- (void)setDeviceModel:(NSString *)deviceModel;
- (NSString *)deviceModel;

- (void)setDeviceCpuType:(NSNumber *)deviceCpuType;
- (NSNumber *)deviceCpuType;

- (void)setDeviceCpuSubtype:(NSNumber *)deviceCpuSubtype;
- (NSNumber *)deviceCpuSubtype;

- (void)setDeviceCarrier:(NSString *)deviceCarrier;
- (NSString *)deviceCarrier;

- (void)setDeviceBrand:(NSString *)deviceBrand;
- (NSString *)deviceBrand;

- (void)setScreenHeight:(NSNumber *)screenHeight;
- (NSNumber *)screenHeight;

- (void)setScreenWidth:(NSNumber *)screenWidth;
- (NSNumber *)screenWidth;

- (void)setScreenSize:(NSString *)screenSize;
- (NSString *)screenSize;

- (void)setScreenDensity:(NSNumber *)screenDensity;
- (NSNumber *)screenDensity;

- (void)setMobileCountryCode:(NSString *)mobileCountryCode;
- (NSString *)mobileCountryCode;

- (void)setMobileCountryCodeISO:(NSString *)mobileCountryCodeISO;
- (NSString *)mobileCountryCodeISO;

- (void)setMobileNetworkCode:(NSString *)mobileNetworkCode;
- (NSString *)mobileNetworkCode;

- (void)setCountryCode:(NSString *)countryCode;
- (NSString *)countryCode;

- (void)setOsVersion:(NSString *)osVersion;
- (NSString *)osVersion;

- (void)setLanguage:(NSString *)language;
- (NSString *)language;

- (void)setReferralUrl:(NSString *)url;
- (NSString *)referralUrl;

- (void)setReferralSource:(NSString *)source;
- (NSString *)referralSource;

- (void)setRedirectUrl:(NSString *)redirectUrl;
- (NSString *)redirectUrl;

- (void)setIadAttribution:(NSNumber *)iadAttribution;
- (NSNumber *)iadAttribution;

- (void)setIadImpressionDate:(NSDate *)iadImpressionDate;
- (NSDate *)iadImpressionDate;

- (void)setIadCampaignId:(NSString *)iadCampaignId;
- (NSString *)iadCampaignId;

- (void)setIadCampaignName:(NSString *)iadCampaignName;
- (NSString *)iadCampaignName;

- (void)setIadCampaignOrgName:(NSString *)iadCampaignOrgName;
- (NSString *)iadCampaignOrgName;

- (void)setIadClickDate:(NSDate *)iadClickDate;
- (NSDate *)iadClickDate;

- (void)setIadConversionDate:(NSDate *)iadConversionDate;
- (NSDate *)iadConversionDate;

- (void)setIadLineId:(NSString *)iadLineId;
- (NSString *)iadLineId;

- (void)setIadLineName:(NSString *)iadLineName;
- (NSString *)iadLineName;

- (void)setIadCreativeId:(NSString *)iadCreativeId;
- (NSString *)iadCreativeId;

- (void)setIadCreativeName:(NSString *)iadCreativeName;
- (NSString *)iadCreativeName;

- (void)setAdvertiserSubAd:(NSString *)advertiserSubAd;
- (NSString *)advertiserSubAd;

- (void)setAdvertiserSubAdgroup:(NSString *)advertiserSubAdgroup;
- (NSString *)advertiserSubAdgroup;

- (void)setAdvertiserSubCampaign:(NSString *)advertiserSubCampaign;
- (NSString *)advertiserSubCampaign;

- (void)setAdvertiserSubKeyword:(NSString *)advertiserSubKeyword;
- (NSString *)advertiserSubKeyword;

- (void)setAdvertiserSubPublisher:(NSString *)advertiserSubPublisher;
- (NSString *)advertiserSubPublisher;

- (void)setAdvertiserSubSite:(NSString *)advertiserSubSite;
- (NSString *)advertiserSubSite;

- (void)setAgencyId:(NSString *)agencyId;
- (NSString *)agencyId;

- (void)setOfferId:(NSString *)offerId;
- (NSString *)offerId;

- (void)setPublisherId:(NSString *)publisherId;
- (NSString *)publisherId;

- (void)setPublisherReferenceId:(NSString *)publisherReferenceId;
- (NSString *)publisherReferenceId;

- (void)setPublisherSubAd:(NSString *)publisherSubAd;
- (NSString *)publisherSubAd;

- (void)setPublisherSubAdgroup:(NSString *)publisherSubAdgroup;
- (NSString *)publisherSubAdgroup;

- (void)setPublisherSubCampaign:(NSString *)publisherSubCampaign;
- (NSString *)publisherSubCampaign;

- (void)setPublisherSubKeyword:(NSString *)publisherSubKeyword;
- (NSString *)publisherSubKeyword;

- (void)setPublisherSubPublisher:(NSString *)publisherSubPublisher;
- (NSString *)publisherSubPublisher;

- (void)setPublisherSubSite:(NSString *)publisherSubSite;
- (NSString *)publisherSubSite;

- (void)setPublisherSub1:(NSString *)publisherSub1;
- (NSString *)publisherSub1;

- (void)setPublisherSub2:(NSString *)publisherSub2;
- (NSString *)publisherSub2;

- (void)setPublisherSub3:(NSString *)publisherSub3;
- (NSString *)publisherSub3;

- (void)setPublisherSub4:(NSString *)publisherSub4;
- (NSString *)publisherSub4;

- (void)setPublisherSub5:(NSString *)publisherSub5;
- (NSString *)publisherSub5;

- (void)setInterfaceIdiom:(NSString *)interfaceIdiom;
- (NSString *)interfaceIdiom;

- (void)setHardwareType:(NSString *)hardwareType;
- (NSString *)hardwareType;

- (void)setMinutesFromGMT:(NSNumber *)minutesFromGMT;
- (NSNumber *)minutesFromGMT;

- (void)setSDKVersion:(NSString *)sdkVersion;
- (NSString *)sdkVersion;

- (void)setUserEmail:(NSString *)email;
- (NSString *)userEmail;
- (NSString *)userEmailMd5;
- (NSString *)userEmailSha1;
- (NSString *)userEmailSha256;

- (void)setUserName:(NSString *)name;
- (NSString *)userName;
- (NSString *)userNameMd5;
- (NSString *)userNameSha1;
- (NSString *)userNameSha256;

- (void)setPhoneNumber:(NSString *)number;
- (NSString *)phoneNumber;
- (NSString *)phoneNumberMd5;
- (NSString *)phoneNumberSha1;
- (NSString *)phoneNumberSha256;

- (void)setLocation:(TuneLocation *)location;
- (TuneLocation *)location;

- (void)setIsTestFlightBuild:(NSNumber *)isTestFlightBuild;
- (NSNumber *)isTestFlightBuild;

- (void)setPreloadData:(TunePreloadData *)preloadData;

/////////////////////////////////////////////////
#pragma mark - Loading/Saving methods
/////////////////////////////////////////////////

- (void) loadSavedProfile;

/////////////////////////////////////////////////
#pragma mark - Marshaling methods
/////////////////////////////////////////////////

- (NSArray *)toArrayOfDictionaries;
- (NSDictionary *)toQueryDictionary;

@end
