//
//  TuneUserProfileKeys.m
//  TuneMarketingConsoleSDK
//
//  Created by Charles Gilliam on 8/7/15.
//  Copyright (c) 2015 Tune. All rights reserved.
//

#import "TuneUserProfileKeys.h"

NSString *const TUNE_KEY_SESSION_ID                     = @"session_id";
NSString *const TUNE_KEY_SESSION_LAST_DATE              = @"last_session_date";
NSString *const TUNE_KEY_SESSION_CURRENT_DATE           = @"current_session_date";
NSString *const TUNE_KEY_SESSION_COUNT                  = @"session_count";
NSString *const TUNE_KEY_IS_FIRST_SESSION               = @"is_first_session";

NSString *const TUNE_KEY_INSTALL_RECEIPT                = @"apple_receipt";

NSString *const TUNE_KEY_INSDATE                        = @"insdate";
NSString *const TUNE_KEY_SESSION_DATETIME               = @"session_datetime";
NSString *const TUNE_KEY_SYSTEM_DATE                    = @"system_date";

NSString *const TUNE_KEY_REFERRAL_URL                   = @"referral_url";
NSString *const TUNE_KEY_REFERRAL_SOURCE                = @"referral_source";
NSString *const TUNE_KEY_REDIRECT_URL                   = @"redirect_url";

NSString *const TUNE_KEY_INSTALL_LOG_ID                 = @"install_log_id";
NSString *const TUNE_KEY_UPDATE_LOG_ID                  = @"update_log_id";
NSString *const TUNE_KEY_OPEN_LOG_ID                    = @"open_log_id";
NSString *const TUNE_KEY_LAST_OPEN_LOG_ID               = @"last_open_log_id";

NSString *const TUNE_KEY_CURRENCY_CODE                  = @"currency_code";

NSString *const TUNE_KEY_OS_JAILBROKE                   = @"os_jailbroke";

NSString *const TUNE_KEY_TRACKING_ID                    = @"tracking_id";
NSString *const TUNE_KEY_MAT_ID                         = @"mat_id";
NSString *const TUNE_KEY_FB_COOKIE_ID                   = @"fb_cookie_id";

NSString *const TUNE_KEY_IOS_IFV                        = @"ios_ifv";
NSString *const TUNE_KEY_IOS_IFA                        = @"ios_ifa";
NSString *const TUNE_KEY_IOS_AD_TRACKING                = @"ios_ad_tracking";

NSString *const TUNE_KEY_IAD_ATTRIBUTION                = @"iad_attribution";
NSString *const TUNE_KEY_IAD_IMPRESSION_DATE            = @"impression_datetime";
NSString *const TUNE_KEY_IAD_CAMPAIGN_ID                = @"iad_campaign_id";
NSString *const TUNE_KEY_IAD_CAMPAIGN_NAME              = @"iad_campaign_name";
NSString *const TUNE_KEY_IAD_CAMPAIGN_ORG_NAME          = @"iad_campaign_org_name";
NSString *const TUNE_KEY_IAD_CLICK_DATE                 = @"iad_click_date";
NSString *const TUNE_KEY_IAD_CONVERSION_DATE            = @"iad_conversion_date";
NSString *const TUNE_KEY_IAD_LINE_ID                    = @"iad_line_id";
NSString *const TUNE_KEY_IAD_LINE_NAME                  = @"iad_line_name";
NSString *const TUNE_KEY_IAD_CREATIVE_ID                = @"iad_creative_id";
NSString *const TUNE_KEY_IAD_CREATIVE_NAME              = @"iad_creative_name";

NSString *const TUNE_KEY_APP_AD_TRACKING                = @"app_ad_tracking";

NSString *const TUNE_KEY_IS_PAYING_USER                 = @"is_paying_user";

NSString *const TUNE_KEY_EXISTING_USER                  = @"existing_user";
NSString *const TUNE_KEY_USER_EMAIL                     = @"user_email";
NSString *const TUNE_KEY_USER_EMAIL_MD5                 = @"user_email_md5";
NSString *const TUNE_KEY_USER_EMAIL_SHA1                = @"user_email_sha1";
NSString *const TUNE_KEY_USER_EMAIL_SHA256              = @"user_email_sha256";
NSString *const TUNE_KEY_USER_ID                        = @"user_id";
NSString *const TUNE_KEY_USER_NAME                      = @"user_name";
NSString *const TUNE_KEY_USER_NAME_MD5                  = @"user_name_md5";
NSString *const TUNE_KEY_USER_NAME_SHA1                 = @"user_name_sha1";
NSString *const TUNE_KEY_USER_NAME_SHA256               = @"user_name_sha256";
NSString *const TUNE_KEY_USER_PHONE                     = @"user_phone";
NSString *const TUNE_KEY_USER_PHONE_MD5                 = @"user_phone_md5";
NSString *const TUNE_KEY_USER_PHONE_SHA1                = @"user_phone_sha1";
NSString *const TUNE_KEY_USER_PHONE_SHA256              = @"user_phone_sha256";
NSString *const TUNE_KEY_FACEBOOK_USER_ID               = @"facebook_user_id";
NSString *const TUNE_KEY_TWITTER_USER_ID                = @"twitter_user_id";
NSString *const TUNE_KEY_GOOGLE_USER_ID                 = @"google_user_id";

NSString *const TUNE_KEY_AGE                            = @"age";
NSString *const TUNE_KEY_GENDER                         = @"gender";

NSString *const TUNE_KEY_LATITUDE                       = @"latitude";
NSString *const TUNE_KEY_LONGITUDE                      = @"longitude";
NSString *const TUNE_KEY_ALTITUDE                       = @"altitude";
NSString *const TUNE_KEY_LOCATION_HORIZONTAL_ACCURACY   = @"location_horizontal_accuracy";
NSString *const TUNE_KEY_LOCATION_TIMESTAMP             = @"location_timestamp";
NSString *const TUNE_KEY_LOCATION_VERTICAL_ACCURACY     = @"location_vertical_accuracy";

NSString *const TUNE_KEY_TRUSTE_TPID                    = @"truste_tpid";

NSString *const TUNE_KEY_OS_TYPE                        = @"os_type";
NSString *const TUNE_KEY_DEVICE_MODEL                   = @"device_model";
NSString *const TUNE_KEY_DEVICE_CPUTYPE                 = @"device_cpu_type";
NSString *const TUNE_KEY_DEVICE_CPUSUBTYPE              = @"device_cpu_subtype";
NSString *const TUNE_KEY_DEVICE_CARRIER                 = @"device_carrier";
NSString *const TUNE_KEY_DEVICE_BRAND                   = @"device_brand";
NSString *const TUNE_KEY_SCREEN_HEIGHT                  = @"screen_height";
NSString *const TUNE_KEY_SCREEN_WIDTH                   = @"screen_width";
NSString *const TUNE_KEY_SCREEN_SIZE                    = @"screen_size";
NSString *const TUNE_KEY_SCREEN_DENSITY                 = @"screen_density";
NSString *const TUNE_KEY_CARRIER_COUNTRY_CODE           = @"mobile_country_code";
NSString *const TUNE_KEY_CARRIER_COUNTRY_CODE_ISO       = @"carrier_country_code";
NSString *const TUNE_KEY_CARRIER_NETWORK_CODE           = @"mobile_network_code";
NSString *const TUNE_KEY_COUNTRY_CODE                   = @"country_code";
NSString *const TUNE_KEY_OS_VERSION                     = @"os_version";
NSString *const TUNE_KEY_LANGUAGE                       = @"language";

NSString *const TUNE_KEY_LOCATION_AUTH_STATUS           = @"location_auth_status";
NSString *const TUNE_KEY_BLUETOOTH_STATE                = @"bluetooth_state";

NSString *const TUNE_KEY_SITE_EVENT_ID                  = @"site_event_id";
NSString *const TUNE_KEY_SITE_EVENT_NAME                = @"site_event_name";
NSString *const TUNE_KEY_APP_NAME                       = @"app_name";
NSString *const TUNE_KEY_APP_VERSION                    = @"app_version";
NSString *const TUNE_KEY_ADVERTISER_ID                  = @"advertiser_id";
NSString *const TUNE_KEY_KEY                            = @"key";
NSString *const TUNE_KEY_PACKAGE_NAME                   = @"package_name";

NSString *const TUNE_KEY_DEVICE_FORM                    = @"device_form";
NSString *const TUNE_KEY_DEVICE_FORM_TV                 = @"tv";
NSString *const TUNE_KEY_DEVICE_FORM_WEARABLE           = @"wearable";

NSString *const TUNE_KEY_ADVERTISER_SUB_AD              = @"advertiser_sub_ad";
NSString *const TUNE_KEY_ADVERTISER_SUB_ADGROUP         = @"advertiser_sub_adgroup";
NSString *const TUNE_KEY_ADVERTISER_SUB_CAMPAIGN        = @"advertiser_sub_campaign";
NSString *const TUNE_KEY_ADVERTISER_SUB_KEYWORD         = @"advertiser_sub_keyword";
NSString *const TUNE_KEY_ADVERTISER_SUB_PUBLISHER       = @"advertiser_sub_publisher";
NSString *const TUNE_KEY_ADVERTISER_SUB_SITE            = @"advertiser_sub_site";
NSString *const TUNE_KEY_AGENCY_ID                      = @"agency_id";
NSString *const TUNE_KEY_OFFER_ID                       = @"offer_id";
NSString *const TUNE_KEY_PRELOAD_DATA                   = @"attr_set";
NSString *const TUNE_KEY_PUBLISHER_REF_ID               = @"publisher_ref_id";
NSString *const TUNE_KEY_PUBLISHER_SUB_AD               = @"publisher_sub_ad";
NSString *const TUNE_KEY_PUBLISHER_SUB_AD_REF           = @"publisher_sub_ad_ref";
NSString *const TUNE_KEY_PUBLISHER_SUB_AD_NAME          = @"publisher_sub_ad_name";
NSString *const TUNE_KEY_PUBLISHER_SUB_ADGROUP          = @"publisher_sub_adgroup";
NSString *const TUNE_KEY_PUBLISHER_SUB_CAMPAIGN         = @"publisher_sub_campaign";
NSString *const TUNE_KEY_PUBLISHER_SUB_CAMPAIGN_REF     = @"publisher_sub_campaign_ref";
NSString *const TUNE_KEY_PUBLISHER_SUB_CAMPAIGN_NAME    = @"publisher_sub_campaign_name";
NSString *const TUNE_KEY_PUBLISHER_SUB_KEYWORD          = @"publisher_sub_keyword";
NSString *const TUNE_KEY_PUBLISHER_SUB_PLACEMENT_REF    = @"publisher_sub_placement_ref";
NSString *const TUNE_KEY_PUBLISHER_SUB_PLACEMENT_NAME   = @"publisher_sub_placement_name";
NSString *const TUNE_KEY_PUBLISHER_SUB_PUBLISHER        = @"publisher_sub_publisher";
NSString *const TUNE_KEY_PUBLISHER_SUB_PUBLISHER_REF    = @"publisher_sub_publisher_ref";
NSString *const TUNE_KEY_PUBLISHER_SUB_SITE             = @"publisher_sub_site";
NSString *const TUNE_KEY_PUBLISHER_SUB1                 = @"publisher_sub1";
NSString *const TUNE_KEY_PUBLISHER_SUB2                 = @"publisher_sub2";
NSString *const TUNE_KEY_PUBLISHER_SUB3                 = @"publisher_sub3";
NSString *const TUNE_KEY_PUBLISHER_SUB4                 = @"publisher_sub4";
NSString *const TUNE_KEY_PUBLISHER_SUB5                 = @"publisher_sub5";

NSString *const TUNE_KEY_INTERFACE_IDIOM                = @"interfaceIdiom";
NSString *const TUNE_KEY_HARDWARE_TYPE                  = @"hardwareType";
NSString *const TUNE_KEY_MINUTES_FROM_GMT               = @"minutesFromGMT";
NSString *const TUNE_KEY_SDK_VERSION                    = @"SDKVersion";
NSString *const TUNE_KEY_DEVICE_TOKEN                   = @"deviceToken";
NSString *const TUNE_KEY_PUSH_ENABLED                   = @"pushEnabled";

NSString *const TUNE_KEY_GEO_COORDINATE                 = @"geo_coordinate";

@implementation TuneUserProfileKeys

+ (NSSet *)getSystemVariables {
    /* This is a set of all profile variables that we (can) register.  The user is not
     *     allowed to register anything with these names since it could cause conflicts.
     *
     * I created this list by copying the above constants and using the following regex on them.
     *
     * FIND:
           ^NSString \*const ([A-Z_0-9]+).+$
     * REPLACE:
           $1,
     *
     * This was in Atom so your exact regex may slightly differ by syntax.
     */
    return [NSSet setWithObjects:
            TUNE_KEY_SESSION_ID,
            TUNE_KEY_SESSION_LAST_DATE,
            TUNE_KEY_SESSION_CURRENT_DATE,
            TUNE_KEY_SESSION_COUNT,
            TUNE_KEY_IS_FIRST_SESSION,
            
            TUNE_KEY_INSTALL_RECEIPT,
            
            TUNE_KEY_INSDATE,
            TUNE_KEY_SESSION_DATETIME,
            TUNE_KEY_SYSTEM_DATE,
            
            TUNE_KEY_REFERRAL_URL,
            TUNE_KEY_REFERRAL_SOURCE,
            TUNE_KEY_REDIRECT_URL,
            
            TUNE_KEY_INSTALL_LOG_ID,
            TUNE_KEY_UPDATE_LOG_ID,
            TUNE_KEY_OPEN_LOG_ID,
            TUNE_KEY_LAST_OPEN_LOG_ID,
            
            TUNE_KEY_CURRENCY_CODE,
            
            TUNE_KEY_OS_JAILBROKE,
            
            TUNE_KEY_TRACKING_ID,
            TUNE_KEY_MAT_ID,
            TUNE_KEY_FB_COOKIE_ID,
            
            TUNE_KEY_IOS_IFV,
            TUNE_KEY_IOS_IFA,
            TUNE_KEY_IOS_AD_TRACKING,
            
            TUNE_KEY_IAD_ATTRIBUTION,
            TUNE_KEY_IAD_IMPRESSION_DATE,
            TUNE_KEY_IAD_CAMPAIGN_ID,
            TUNE_KEY_IAD_CAMPAIGN_NAME,
            TUNE_KEY_IAD_CAMPAIGN_ORG_NAME,
            TUNE_KEY_IAD_LINE_ID,
            TUNE_KEY_IAD_LINE_NAME,
            TUNE_KEY_IAD_CREATIVE_ID,
            TUNE_KEY_IAD_CREATIVE_NAME,
            
            TUNE_KEY_APP_AD_TRACKING,
            
            TUNE_KEY_IS_PAYING_USER,
            
            TUNE_KEY_EXISTING_USER,
            TUNE_KEY_USER_EMAIL,
            TUNE_KEY_USER_EMAIL_MD5,
            TUNE_KEY_USER_EMAIL_SHA1,
            TUNE_KEY_USER_EMAIL_SHA256,
            TUNE_KEY_USER_ID,
            TUNE_KEY_USER_NAME,
            TUNE_KEY_USER_NAME_MD5,
            TUNE_KEY_USER_NAME_SHA1,
            TUNE_KEY_USER_NAME_SHA256,
            TUNE_KEY_USER_PHONE,
            TUNE_KEY_USER_PHONE_MD5,
            TUNE_KEY_USER_PHONE_SHA1,
            TUNE_KEY_USER_PHONE_SHA256,
            TUNE_KEY_FACEBOOK_USER_ID,
            TUNE_KEY_TWITTER_USER_ID,
            TUNE_KEY_GOOGLE_USER_ID,
            
            TUNE_KEY_AGE,
            TUNE_KEY_GENDER,
            
            TUNE_KEY_LATITUDE,
            TUNE_KEY_LONGITUDE,
            TUNE_KEY_ALTITUDE,
            TUNE_KEY_LOCATION_HORIZONTAL_ACCURACY,
            TUNE_KEY_LOCATION_TIMESTAMP,
            TUNE_KEY_LOCATION_VERTICAL_ACCURACY,
            
            TUNE_KEY_TRUSTE_TPID,
            
            TUNE_KEY_OS_TYPE,
            TUNE_KEY_DEVICE_MODEL,
            TUNE_KEY_DEVICE_CPUTYPE,
            TUNE_KEY_DEVICE_CPUSUBTYPE,
            TUNE_KEY_DEVICE_CARRIER,
            TUNE_KEY_DEVICE_BRAND,
            TUNE_KEY_SCREEN_HEIGHT,
            TUNE_KEY_SCREEN_WIDTH,
            TUNE_KEY_SCREEN_SIZE,
            TUNE_KEY_SCREEN_DENSITY,
            TUNE_KEY_CARRIER_COUNTRY_CODE,
            TUNE_KEY_CARRIER_COUNTRY_CODE_ISO,
            TUNE_KEY_CARRIER_NETWORK_CODE,
            TUNE_KEY_COUNTRY_CODE,
            TUNE_KEY_OS_VERSION,
            TUNE_KEY_LANGUAGE,
            
            TUNE_KEY_LOCATION_AUTH_STATUS,
            TUNE_KEY_BLUETOOTH_STATE,
            
            TUNE_KEY_SITE_EVENT_ID,
            TUNE_KEY_SITE_EVENT_NAME,
            TUNE_KEY_APP_NAME,
            TUNE_KEY_APP_VERSION,
            TUNE_KEY_ADVERTISER_ID,
            TUNE_KEY_KEY,
            TUNE_KEY_PACKAGE_NAME,
            
            TUNE_KEY_DEVICE_FORM,
            TUNE_KEY_DEVICE_FORM_TV,
            TUNE_KEY_DEVICE_FORM_WEARABLE,
            
            TUNE_KEY_ADVERTISER_SUB_AD,
            TUNE_KEY_ADVERTISER_SUB_ADGROUP,
            TUNE_KEY_ADVERTISER_SUB_CAMPAIGN,
            TUNE_KEY_ADVERTISER_SUB_KEYWORD,
            TUNE_KEY_ADVERTISER_SUB_PUBLISHER,
            TUNE_KEY_ADVERTISER_SUB_SITE,
            TUNE_KEY_AGENCY_ID,
            TUNE_KEY_OFFER_ID,
            TUNE_KEY_PRELOAD_DATA,
            TUNE_KEY_PUBLISHER_REF_ID,
            TUNE_KEY_PUBLISHER_SUB_AD,
            TUNE_KEY_PUBLISHER_SUB_ADGROUP,
            TUNE_KEY_PUBLISHER_SUB_CAMPAIGN,
            TUNE_KEY_PUBLISHER_SUB_KEYWORD,
            TUNE_KEY_PUBLISHER_SUB_PUBLISHER,
            TUNE_KEY_PUBLISHER_SUB_SITE,
            TUNE_KEY_PUBLISHER_SUB1,
            TUNE_KEY_PUBLISHER_SUB2,
            TUNE_KEY_PUBLISHER_SUB3,
            TUNE_KEY_PUBLISHER_SUB4,
            TUNE_KEY_PUBLISHER_SUB5,
            
            TUNE_KEY_INTERFACE_IDIOM,
            TUNE_KEY_HARDWARE_TYPE,
            TUNE_KEY_MINUTES_FROM_GMT,
            TUNE_KEY_SDK_VERSION,
            TUNE_KEY_DEVICE_TOKEN,
            TUNE_KEY_PUSH_ENABLED,
            
            TUNE_KEY_GEO_COORDINATE,
            nil];
}

@end
