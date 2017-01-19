//
//  TuneKeyStrings.m
//  Tune
//
//  Created by Pavel Yurchenko on 7/24/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "TuneKeyStrings.h"

NSString * const TUNE_KEY_ACTION                         = @"action";
NSString * const TUNE_KEY_BYPASS_THROTTLING              = @"bypass_throttling";
NSString * const TUNE_KEY_CAMPAIGN_ID                    = @"campaign_id";
NSString * const TUNE_KEY_PUBLISHER_ID                   = @"publisher_id";
NSString * const TUNE_KEY_CONVERSION_USER_AGENT          = @"conversion_user_agent";
NSString * const TUNE_KEY_CURRENCY_USD                   = @"USD";
NSString * const TUNE_KEY_DATA                           = @"data";
NSString * const TUNE_KEY_DEEPLINK_CHECKED               = @"mat_deeplink_checked";
NSString * const TUNE_KEY_GEOFENCE_NAME                  = @"geofence_name";
NSString * const TUNE_KEY_GUID_EMPTY                     = @"00000000-0000-0000-0000-000000000000";
NSString * const TUNE_KEY_HTTPS                          = @"https";
NSString * const TUNE_KEY_IAD_ATTRIBUTION_CHECKED        = @"iad_attribution_checked";
NSString * const TUNE_KEY_IAD_REQUEST_ATTEMPT            = @"iad_request_attempt";
NSString * const TUNE_KEY_IAD_REQUEST_TIMESTAMP          = @"iad_request_timestamp";
NSString * const TUNE_KEY_IOS                            = @"ios";
NSString * const TUNE_KEY_IOS_IFA_DEEPLINK               = @"ad_id";
NSString * const TUNE_KEY_IOS_PURCHASE_STATUS            = @"ios_purchase_status";
NSString * const TUNE_KEY_JSON                           = @"json";
NSString * const TUNE_KEY_LOG_ID                         = @"log_id";
NSString * const TUNE_KEY_NETWORK_REQUEST_PENDING        = @"network_request_pending";
NSString * const TUNE_KEY_ODIN                           = @"odin";
NSString * const TUNE_KEY_OPEN_UDID                      = @"open_udid";
NSString * const TUNE_KEY_OS_ID                          = @"os_id";
NSString * const TUNE_KEY_POST_CONVERSION                = @"post_conversion";
NSString * const TUNE_KEY_PUBLISHER_ADVERTISER_ID        = @"publisher_advertiser_id";
NSString * const TUNE_KEY_REDIRECT                       = @"redirect";
NSString * const TUNE_KEY_REF_ID                         = @"advertiser_ref_id";
NSString * const TUNE_KEY_REQUEST_URL                    = @"request_url";
NSString * const TUNE_KEY_RESPONSE_FORMAT                = @"response_format";
NSString * const TUNE_KEY_RETRY_COUNT                    = @"sdk_retry_attempt";
NSString * const TUNE_KEY_REVENUE                        = @"revenue";
NSString * const TUNE_KEY_RUN_DATE                       = @"run_date";
NSString * const TUNE_KEY_SDK                            = @"sdk";
NSString * const TUNE_KEY_SERVER_RESPONSE                = @"server_response";
NSString * const TUNE_KEY_SITE_EVENT_TYPE                = @"site_event_type";
NSString * const TUNE_KEY_STORE_RECEIPT                  = @"store_receipt";
NSString * const TUNE_KEY_SUCCESS                        = @"success";
NSString * const TUNE_KEY_TARGET_BUNDLE_ID               = @"target_package";
NSString * const TUNE_KEY_TRANSACTION_ID                 = @"transaction_id";
NSString * const TUNE_KEY_URL                            = @"url";
NSString * const TUNE_KEY_VER                            = @"ver";
NSString * const TUNE_KEY_XML                            = @"xml";

NSString * const TUNE_KEY_TVOS                           = @"tvos";
NSString * const TUNE_KEY_WATCHOS                        = @"watchos";

NSString * const TUNE_KEY_CWORKS_CLICK                   = @"cworks_click";
NSString * const TUNE_KEY_CWORKS_IMPRESSION              = @"cworks_impression";

NSString * const TUNE_KEY_ITEM                           = @"item";
NSString * const TUNE_KEY_QUANTITY                       = @"quantity";
NSString * const TUNE_KEY_UNIT_PRICE                     = @"unit_price";
NSString * const TUNE_KEY_ATTRIBUTE_SUB1                 = @"attribute_sub1";
NSString * const TUNE_KEY_ATTRIBUTE_SUB2                 = @"attribute_sub2";
NSString * const TUNE_KEY_ATTRIBUTE_SUB3                 = @"attribute_sub3";
NSString * const TUNE_KEY_ATTRIBUTE_SUB4                 = @"attribute_sub4";
NSString * const TUNE_KEY_ATTRIBUTE_SUB5                 = @"attribute_sub5";

// Url parameter key and response key for Tune Link invoke url
NSString * const TUNE_KEY_INVOKE_URL                     = @"invoke_url";

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
NSString * const TUNE_KEY_ERROR_TUNE_DUPLICATE_SESSION           = @"tune_error_duplicate_session";

NSString * const TUNE_KEY_MAT_INSTALL_LOG_ID                     = @"mat_install_log_id";
NSString * const TUNE_KEY_MAT_INSTALL_LOG_ID_REQUEST_TIMESTAMP   = @"mat_install_log_id_request_timestamp";
NSString * const TUNE_KEY_MAT_UPDATE_LOG_ID                      = @"mat_udpate_log_id";

NSString * const TUNE_KEY_MAT_FIXED_FOR_ICLOUD                   = @"mat_fixed_for_icloud";

NSString * const TUNE_KEY_PUSH_ENABLED_STATUS                    = @"TUNE_PUSH_ENABLED_STATUS";

NSString * const TUNE_STRING_EMPTY                               = @"";
NSString * const TUNE_STRING_TRUE                                = @"true";
NSString * const TUNE_STRING_FALSE                               = @"false";

NSString * const TUNE_SERVER_DOMAIN_COOKIE_TRACKING              = @"https://launch1.co";
NSString * const TUNE_SERVER_DOMAIN_REGULAR_TRACKING_PROD        = @"engine.mobileapptracking.com";
NSString * const TUNE_SERVER_DOMAIN_REGULAR_TRACKING_PROD_DEBUG  = @"debug.engine.mobileapptracking.com";
NSString * const TUNE_SERVER_DOMAIN_REGULAR_TRACKING_STAGE       = @"engine.stage.mobileapptracking.com";
NSString * const TUNE_SERVER_PATH_TRACKING_ENGINE                = @"serve";

NSString * const TUNE_SERVER_DOMAIN_DEEPLINK                     = @"deeplink.mobileapptracking.com";
NSString * const TUNE_SERVER_PATH_DEEPLINK                       = @"v1/link.txt";

NSString * const TUNE_FAKE_IAD_CAMPAIGN_ID                       = @"1234567890";


