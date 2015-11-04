//
//  TuneKeyStrings.m
//  Tune
//
//  Created by Pavel Yurchenko on 7/24/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "TuneKeyStrings.h"

NSString * const TUNE_KEY_ACTION                         = @"action";
NSString * const TUNE_KEY_ADVERTISER_ID                  = @"advertiser_id";
NSString * const TUNE_KEY_APP_AD_TRACKING                = @"app_ad_tracking";
NSString * const TUNE_KEY_APP_NAME                       = @"app_name";
NSString * const TUNE_KEY_APP_VERSION                    = @"app_version";
NSString * const TUNE_KEY_BLUETOOTH_STATE                = @"bluetooth_state";
NSString * const TUNE_KEY_BYPASS_THROTTLING              = @"bypass_throttling";
NSString * const TUNE_KEY_CAMPAIGN_ID                    = @"campaign_id";
NSString * const TUNE_KEY_PUBLISHER_ID                   = @"publisher_id";
NSString * const TUNE_KEY_CONVERSION_USER_AGENT          = @"conversion_user_agent";
NSString * const TUNE_KEY_COUNTRY_CODE                   = @"country_code";
NSString * const TUNE_KEY_CURRENCY_CODE                  = @"currency_code";
NSString * const TUNE_KEY_CURRENCY_USD                   = @"USD";
NSString * const TUNE_KEY_DATA                           = @"data";
NSString * const TUNE_KEY_DEBUG                          = @"debug";
NSString * const TUNE_KEY_DEEPLINK_CHECKED               = @"mat_deeplink_checked";
NSString * const TUNE_KEY_DEVICE_BRAND                   = @"device_brand";
NSString * const TUNE_KEY_DEVICE_CARRIER                 = @"device_carrier";
NSString * const TUNE_KEY_DEVICE_CPUTYPE                 = @"device_cpu_type";
NSString * const TUNE_KEY_DEVICE_CPUSUBTYPE              = @"device_cpu_subtype";
NSString * const TUNE_KEY_DEVICE_FORM                    = @"device_form";
NSString * const TUNE_KEY_DEVICE_FORM_WEARABLE           = @"wearable";
NSString * const TUNE_KEY_DEVICE_MODEL                   = @"device_model";
NSString * const TUNE_KEY_EXISTING_USER                  = @"existing_user";
NSString * const TUNE_KEY_FACEBOOK_USER_ID               = @"facebook_user_id";

#if TARGET_OS_IOS
NSString * const TUNE_KEY_FB_COOKIE_ID                   = @"fb_cookie_id";
#endif

NSString * const TUNE_KEY_GEOFENCE_NAME                  = @"geofence_name";
NSString * const TUNE_KEY_GOOGLE_USER_ID                 = @"google_user_id";
NSString * const TUNE_KEY_GUID_EMPTY                     = @"00000000-0000-0000-0000-000000000000";
NSString * const TUNE_KEY_HTTPS                          = @"https";
NSString * const TUNE_KEY_IAD_ATTRIBUTION                = @"iad_attribution";
NSString * const TUNE_KEY_IAD_IMPRESSION_DATE            = @"impression_datetime";
NSString * const TUNE_KEY_IAD_CAMPAIGN_ID                = @"iad_campaign_id";
NSString * const TUNE_KEY_IAD_CAMPAIGN_NAME              = @"iad_campaign_name";
NSString * const TUNE_KEY_IAD_CAMPAIGN_ORG_NAME          = @"iad_campaign_org_name";
NSString * const TUNE_KEY_IAD_LINE_ID                    = @"iad_line_id";
NSString * const TUNE_KEY_IAD_LINE_NAME                  = @"iad_line_name";
NSString * const TUNE_KEY_IAD_CREATIVE_ID                = @"iad_creative_id";
NSString * const TUNE_KEY_IAD_CREATIVE_NAME              = @"iad_creative_name";
NSString * const TUNE_KEY_INSDATE                        = @"insdate";
NSString * const TUNE_KEY_INSTALL_LOG_ID                 = @"install_log_id";
NSString * const TUNE_KEY_INSTALL_RECEIPT                = @"apple_receipt";
NSString * const TUNE_KEY_IOS                            = @"ios";
NSString * const TUNE_KEY_IOS_AD_TRACKING                = @"ios_ad_tracking";
NSString * const TUNE_KEY_IOS_IFA                        = @"ios_ifa";
NSString * const TUNE_KEY_IOS_IFA_DEEPLINK               = @"ad_id";
NSString * const TUNE_KEY_IOS_IFV                        = @"ios_ifv";
NSString * const TUNE_KEY_IOS_PURCHASE_STATUS            = @"ios_purchase_status";
NSString * const TUNE_KEY_IS_PAYING_USER                 = @"is_paying_user";
NSString * const TUNE_KEY_JSON                           = @"json";
NSString * const TUNE_KEY_KEY                            = @"key";
NSString * const TUNE_KEY_LAST_OPEN_LOG_ID               = @"last_open_log_id";
NSString * const TUNE_KEY_LANGUAGE                       = @"language";
NSString * const TUNE_KEY_LOCATION_AUTH_STATUS           = @"location_auth_status";
NSString * const TUNE_KEY_LOCATION_HORIZONTAL_ACCURACY   = @"location_horizontal_accuracy";
NSString * const TUNE_KEY_LOCATION_TIMESTAMP             = @"location_timestamp";
NSString * const TUNE_KEY_LOCATION_VERTICAL_ACCURACY     = @"location_vertical_accuracy";
NSString * const TUNE_KEY_LOG_ID                         = @"log_id";
NSString * const TUNE_KEY_MAT_ID                         = @"mat_id";
NSString * const TUNE_KEY_ODIN                           = @"odin";
NSString * const TUNE_KEY_OPEN_LOG_ID                    = @"open_log_id";
NSString * const TUNE_KEY_OPEN_UDID                      = @"open_udid";
NSString * const TUNE_KEY_OS_ID                          = @"os_id";
NSString * const TUNE_KEY_OS_JAILBROKE                   = @"os_jailbroke";
NSString * const TUNE_KEY_OS_VERSION                     = @"os_version";
NSString * const TUNE_KEY_PACKAGE_NAME                   = @"package_name";
NSString * const TUNE_KEY_POST_CONVERSION                = @"post_conversion";
NSString * const TUNE_KEY_PUBLISHER_ADVERTISER_ID        = @"publisher_advertiser_id";
NSString * const TUNE_KEY_REDIRECT                       = @"redirect";
NSString * const TUNE_KEY_REDIRECT_URL                   = @"redirect_url";
NSString * const TUNE_KEY_REF_ID                         = @"advertiser_ref_id";
NSString * const TUNE_KEY_REFERRAL_SOURCE                = @"referral_source";
NSString * const TUNE_KEY_REFERRAL_URL                   = @"referral_url";
NSString * const TUNE_KEY_REQUEST_URL                    = @"request_url";
NSString * const TUNE_KEY_RESPONSE_FORMAT                = @"response_format";
NSString * const TUNE_KEY_RETRY_COUNT                    = @"sdk_retry_attempt";
NSString * const TUNE_KEY_REVENUE                        = @"revenue";
NSString * const TUNE_KEY_RUN_DATE                       = @"run_date";
NSString * const TUNE_KEY_SCREEN_DENSITY                 = @"screen_density";
NSString * const TUNE_KEY_SCREEN_SIZE                    = @"screen_size";
NSString * const TUNE_KEY_SDK                            = @"sdk";
NSString * const TUNE_KEY_SDK_PLUGIN                     = @"sdk_plugin";
NSString * const TUNE_KEY_SERVER_RESPONSE                = @"server_response";
NSString * const TUNE_KEY_SESSION_DATETIME               = @"session_datetime";
NSString * const TUNE_KEY_SITE_EVENT_ID                  = @"site_event_id";
NSString * const TUNE_KEY_SITE_EVENT_NAME                = @"site_event_name";
NSString * const TUNE_KEY_SITE_EVENT_TYPE                = @"site_event_type";
NSString * const TUNE_KEY_SITE_ID                        = @"site_id";
NSString * const TUNE_KEY_SKIP_DUP                       = @"skip_dup";
NSString * const TUNE_KEY_STAGING                        = @"staging";
NSString * const TUNE_KEY_STORE_RECEIPT                  = @"store_receipt";
NSString * const TUNE_KEY_SUCCESS                        = @"success";
NSString * const TUNE_KEY_SYSTEM_DATE                    = @"system_date";
NSString * const TUNE_KEY_TARGET_BUNDLE_ID               = @"target_package";
NSString * const TUNE_KEY_TRACKING_ID                    = @"tracking_id";
NSString * const TUNE_KEY_TRANSACTION_ID                 = @"transaction_id";
NSString * const TUNE_KEY_TRUSTE_TPID                    = @"truste_tpid";
NSString * const TUNE_KEY_TVOS                           = @"tvos";
NSString * const TUNE_KEY_WATCHOS                        = @"watchos";
NSString * const TUNE_KEY_TWITTER_USER_ID                = @"twitter_user_id";
NSString * const TUNE_KEY_UPDATE_LOG_ID                  = @"update_log_id";
NSString * const TUNE_KEY_URL                            = @"url";
NSString * const TUNE_KEY_USER_EMAIL                     = @"user_email";
NSString * const TUNE_KEY_USER_ID                        = @"user_id";
NSString * const TUNE_KEY_USER_NAME                      = @"user_name";
NSString * const TUNE_KEY_USER_PHONE                     = @"user_phone";

NSString * const TUNE_KEY_USER_NAME_MD5                  = @"user_name_md5";
NSString * const TUNE_KEY_USER_NAME_SHA1                 = @"user_name_sha1";
NSString * const TUNE_KEY_USER_NAME_SHA256               = @"user_name_sha256";
NSString * const TUNE_KEY_USER_EMAIL_MD5                 = @"user_email_md5";
NSString * const TUNE_KEY_USER_EMAIL_SHA1                = @"user_email_sha1";
NSString * const TUNE_KEY_USER_EMAIL_SHA256              = @"user_email_sha256";
NSString * const TUNE_KEY_USER_PHONE_MD5                 = @"user_phone_md5";
NSString * const TUNE_KEY_USER_PHONE_SHA1                = @"user_phone_sha1";
NSString * const TUNE_KEY_USER_PHONE_SHA256              = @"user_phone_sha256";

NSString * const TUNE_KEY_VER                            = @"ver";
NSString * const TUNE_KEY_XML                            = @"xml";

NSString * const TUNE_KEY_CWORKS_CLICK                   = @"cworks_click";
NSString * const TUNE_KEY_CWORKS_IMPRESSION              = @"cworks_impression";

NSString * const TUNE_KEY_EVENT_CONTENT_TYPE             = @"content_type";
NSString * const TUNE_KEY_EVENT_CONTENT_ID               = @"content_id";
NSString * const TUNE_KEY_EVENT_LEVEL                    = @"level";
NSString * const TUNE_KEY_EVENT_QUANTITY                 = @"quantity";
NSString * const TUNE_KEY_EVENT_SEARCH_STRING            = @"search_string";
NSString * const TUNE_KEY_EVENT_RATING                   = @"rating";
NSString * const TUNE_KEY_EVENT_DATE1                    = @"date1";
NSString * const TUNE_KEY_EVENT_DATE2                    = @"date2";
NSString * const TUNE_KEY_EVENT_ATTRIBUTE_SUB1           = @"attribute_sub1";
NSString * const TUNE_KEY_EVENT_ATTRIBUTE_SUB2           = @"attribute_sub2";
NSString * const TUNE_KEY_EVENT_ATTRIBUTE_SUB3           = @"attribute_sub3";
NSString * const TUNE_KEY_EVENT_ATTRIBUTE_SUB4           = @"attribute_sub4";
NSString * const TUNE_KEY_EVENT_ATTRIBUTE_SUB5           = @"attribute_sub5";

NSString * const TUNE_KEY_ITEM                           = @"item";
NSString * const TUNE_KEY_QUANTITY                       = @"quantity";
NSString * const TUNE_KEY_UNIT_PRICE                     = @"unit_price";

NSString * const TUNE_KEY_AGE                            = @"age";
NSString * const TUNE_KEY_GENDER                         = @"gender";

NSString * const TUNE_KEY_LATITUDE                       = @"latitude";
NSString * const TUNE_KEY_LONGITUDE                      = @"longitude";
NSString * const TUNE_KEY_ALTITUDE                       = @"altitude";

NSString * const TUNE_KEY_ATTRIBUTE_SUB1                 = @"attribute_sub1";
NSString * const TUNE_KEY_ATTRIBUTE_SUB2                 = @"attribute_sub2";
NSString * const TUNE_KEY_ATTRIBUTE_SUB3                 = @"attribute_sub3";
NSString * const TUNE_KEY_ATTRIBUTE_SUB4                 = @"attribute_sub4";
NSString * const TUNE_KEY_ATTRIBUTE_SUB5                 = @"attribute_sub5";

NSString * const TUNE_KEY_CARRIER_COUNTRY_CODE           = @"mobile_country_code";
NSString * const TUNE_KEY_CARRIER_COUNTRY_CODE_ISO       = @"carrier_country_code";
NSString * const TUNE_KEY_CARRIER_NETWORK_CODE           = @"mobile_network_code";

NSString * const TUNE_DEFAULT_LOCALE_IDENTIFIER          = @"en_us";
NSString * const TUNE_DEFAULT_TIMEZONE                   = @"UTC";

NSString * const TUNE_EVENT_INSTALL                      = @"install";
NSString * const TUNE_EVENT_UPDATE                       = @"update";
NSString * const TUNE_EVENT_OPEN                         = @"open";
NSString * const TUNE_EVENT_CLICK                        = @"click";
NSString * const TUNE_EVENT_CLOSE                        = @"close";
NSString * const TUNE_EVENT_CONVERSION                   = @"conversion";
NSString * const TUNE_EVENT_GEOFENCE                     = @"geofence";

NSString * const TUNE_HTTP_METHOD_POST                   = @"POST";
NSString * const TUNE_HTTP_CONTENT_LENGTH                = @"content-length";
NSString * const TUNE_HTTP_CONTENT_TYPE                  = @"content-type";
NSString * const TUNE_HTTP_CONTENT_TYPE_APPLICATION_JSON = @"application/json";

NSString * const TUNE_KEY_ERROR_DOMAIN                   = @"com.tune.Tune";

NSString * const TUNE_KEY_ERROR_TUNE_SERVER_ERROR                = @"tune_error_server_error";
NSString * const TUNE_KEY_ERROR_TUNE_ADVERTISER_ID_MISSING       = @"tune_error_advertiser_id_missing";
NSString * const TUNE_KEY_ERROR_TUNE_CONVERSION_KEY_MISSING      = @"tune_error_conversion_key_missing";
NSString * const TUNE_KEY_ERROR_TUNE_CONVERSION_KEY_INVALID      = @"tune_error_conversion_key_invalid";
NSString * const TUNE_KEY_ERROR_TUNE_INVALID_PARAMETERS          = @"tune_error_invalid_parameters";
NSString * const TUNE_KEY_ERROR_TUNE_APP_TO_APP_FAILURE          = @"tune_error_app_to_app_failure";
NSString * const TUNE_KEY_ERROR_TUNE_NETWORK_NOT_REACHABLE       = @"tune_error_network_not_reachable";
NSString * const TUNE_KEY_ERROR_TUNE_OPEN_EVENT                  = @"tune_error_open_event_error";
NSString * const TUNE_KEY_ERROR_TUNE_CLOSE_EVENT                 = @"tune_error_close_event_error";

NSString * const TUNE_KEY_MAT_INSTALL_LOG_ID                     = @"mat_install_log_id";
NSString * const TUNE_KEY_MAT_INSTALL_LOG_ID_REQUEST_TIMESTAMP   = @"mat_install_log_id_request_timestamp";
NSString * const TUNE_KEY_MAT_UPDATE_LOG_ID                      = @"mat_udpate_log_id";

NSString * const TUNE_KEY_MAT_FIXED_FOR_ICLOUD                   = @"mat_fixed_for_icloud";

NSString * const TUNE_STRING_EMPTY                               = @"";

NSString * const TUNE_SERVER_DOMAIN_COOKIE_TRACKING              = @"https://launch1.co";
NSString * const TUNE_SERVER_DOMAIN_REGULAR_TRACKING_PROD        = @"engine.mobileapptracking.com";
NSString * const TUNE_SERVER_DOMAIN_REGULAR_TRACKING_PROD_DEBUG  = @"debug.engine.mobileapptracking.com";
NSString * const TUNE_SERVER_DOMAIN_REGULAR_TRACKING_STAGE       = @"engine.stage.mobileapptracking.com";
NSString * const TUNE_SERVER_PATH_TRACKING_ENGINE                = @"serve";

NSString * const TUNE_SERVER_DOMAIN_DEEPLINK                     = @"deeplink.mobileapptracking.com";
NSString * const TUNE_SERVER_PATH_DEEPLINK                       = @"v1/link.txt";

NSString * const TUNE_KEY_ADVERTISER_SUB_AD              = @"advertiser_sub_ad";
NSString * const TUNE_KEY_ADVERTISER_SUB_ADGROUP         = @"advertiser_sub_adgroup";
NSString * const TUNE_KEY_ADVERTISER_SUB_CAMPAIGN        = @"advertiser_sub_campaign";
NSString * const TUNE_KEY_ADVERTISER_SUB_KEYWORD         = @"advertiser_sub_keyword";
NSString * const TUNE_KEY_ADVERTISER_SUB_PUBLISHER       = @"advertiser_sub_publisher";
NSString * const TUNE_KEY_ADVERTISER_SUB_SITE            = @"advertiser_sub_site";
NSString * const TUNE_KEY_AGENCY_ID                      = @"agency_id";
NSString * const TUNE_KEY_OFFER_ID                       = @"offer_id";
NSString * const TUNE_KEY_PRELOAD_DATA                   = @"attr_set";
NSString * const TUNE_KEY_PUBLISHER_REF_ID               = @"publisher_ref_id";
NSString * const TUNE_KEY_PUBLISHER_SUB_AD               = @"publisher_sub_ad";
NSString * const TUNE_KEY_PUBLISHER_SUB_ADGROUP          = @"publisher_sub_adgroup";
NSString * const TUNE_KEY_PUBLISHER_SUB_CAMPAIGN         = @"publisher_sub_campaign";
NSString * const TUNE_KEY_PUBLISHER_SUB_KEYWORD          = @"publisher_sub_keyword";
NSString * const TUNE_KEY_PUBLISHER_SUB_PUBLISHER        = @"publisher_sub_publisher";
NSString * const TUNE_KEY_PUBLISHER_SUB_SITE             = @"publisher_sub_site";
NSString * const TUNE_KEY_PUBLISHER_SUB1                 = @"publisher_sub1";
NSString * const TUNE_KEY_PUBLISHER_SUB2                 = @"publisher_sub2";
NSString * const TUNE_KEY_PUBLISHER_SUB3                 = @"publisher_sub3";
NSString * const TUNE_KEY_PUBLISHER_SUB4                 = @"publisher_sub4";
NSString * const TUNE_KEY_PUBLISHER_SUB5                 = @"publisher_sub5";
