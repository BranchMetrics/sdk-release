//
//  MATKeyStrings.m
//  MobileAppTrackeriOS
//
//  Created by Pavel Yurchenko on 7/24/12.
//  Copyright (c) 2012 Scopic Software. All rights reserved.
//

#import "MATKeyStrings.h"

NSString * const KEY_ACTION                     	= @"action";
NSString * const KEY_ADVERTISER_ID                  = @"advertiser_id";
NSString * const KEY_APP_NAME                       = @"app_name";
NSString * const KEY_APP_VERSION                    = @"app_version";
NSString * const KEY_APPLE                          = @"Apple";
NSString * const KEY_CAMPAIGN_ID                    = @"campaign_id";
NSString * const KEY_PUBLISHER_ID                   = @"publisher_id";
NSString * const KEY_CFBUNDLEIDENTIFIER             = @"CFBundleIdentifier";
NSString * const KEY_CFBUNDLENAME                   = @"CFBundleName";
NSString * const KEY_CFBUNDLEVERSION            	= @"CFBundleVersion";
NSString * const KEY_CONVERSION_USER_AGENT      	= @"conversion_user_agent";
NSString * const KEY_COUNTRY_CODE                   = @"country_code";
NSString * const KEY_CURRENCY                   	= @"currency_code";
NSString * const KEY_CURRENCY_USD                	= @"USD";
NSString * const KEY_DATA                       	= @"data";
NSString * const KEY_DEBUG                      	= @"debug";
NSString * const KEY_DEVICE_BRAND               	= @"device_brand";
NSString * const KEY_DEVICE_CARRIER             	= @"device_carrier";
NSString * const KEY_DEVICE_ID                  	= @"device_id";
NSString * const KEY_DEVICE_MODEL               	= @"device_model";
NSString * const KEY_DOMAIN                     	= @"domain";
NSString * const KEY_EVENT_REFERRAL             	= @"event_referral";
NSString * const KEY_FB_COOKIE_ID               	= @"fb_cookie_id";
NSString * const KEY_GUID_EMPTY                 	= @"00000000-0000-0000-0000-000000000000";
NSString * const KEY_HTTP                           = @"HTTP";
NSString * const KEY_HTTPS                      	= @"HTTPS";
NSString * const KEY_INSDATE                    	= @"insdate";
NSString * const KEY_INSTALL_DATE               	= @"install_date";
NSString * const KEY_IOS                            = @"ios";
NSString * const KEY_IOS_AD_TRACKING                = @"ios_ad_tracking";
NSString * const KEY_IOS_IFA                        = @"ios_ifa";
NSString * const KEY_IOS_IFV                        = @"ios_ifv";
NSString * const KEY_IOS_PURCHASE_STATUS            = @"ios_purchase_status";
NSString * const KEY_JSON                           = @"json";
NSString * const KEY_KEY                            = @"key";
NSString * const KEY_KEY_INDEX                      = @"key_index";
NSString * const KEY_LANGUAGE                       = @"language";
NSString * const KEY_MAC_ADDRESS                    = @"mac_address";
NSString * const KEY_MAT_APP_VERSION                = @"mat_app_version";
NSString * const KEY_MAT_ID                         = @"mat_id";
NSString * const KEY_ODIN                           = @"odin";
NSString * const KEY_OPEN_UDID                      = @"open_udid";
NSString * const KEY_OS_JAILBROKE               	= @"os_jailbroke";
NSString * const KEY_OS_VERSION                     = @"os_version";
NSString * const KEY_PACKAGE_NAME                   = @"package_name";
NSString * const KEY_PUBLISHER_ADVERTISER_ID        = @"publisher_advertiser_id";
NSString * const KEY_PUBLISHER_PACKAGE_NAME         = @"publisher_package_name";
NSString * const KEY_REDIRECT                       = @"redirect";
NSString * const KEY_REDIRECT_URL                   = @"redirect_url";
NSString * const KEY_REF_ID                         = @"advertiser_ref_id";
NSString * const KEY_RESPONSE_FORMAT                = @"response_format";
NSString * const KEY_REVENUE                        = @"revenue";
NSString * const KEY_SDK                        	= @"sdk";
NSString * const KEY_SERVER_RESPONSE                = @"server_response";
NSString * const KEY_SESSION_DATETIME           	= @"session_datetime";
NSString * const KEY_SITE_EVENT_ID                  = @"site_event_id";
NSString * const KEY_SITE_EVENT_NAME                = @"site_event_name";
NSString * const KEY_SITE_ID                        = @"site_id";
NSString * const KEY_SKIP_DUP                      	= @"skip_dup";
NSString * const KEY_SOURCE                         = @"source";
NSString * const KEY_STAGING                        = @"staging";
NSString * const KEY_SUCCESS                        = @"success";
NSString * const KEY_SYSTEM_DATE                    = @"system_date";
NSString * const KEY_TARGET_BUNDLE_ID               = @"target_package";
NSString * const KEY_TRACKING_ID                    = @"tracking_id";
NSString * const KEY_TRUSTE_TPID                    = @"truste_tpid";
NSString * const KEY_URL                            = @"url";
NSString * const KEY_USER_ID                        = @"user_id";
NSString * const KEY_VER                            = @"ver";
NSString * const KEY_XML                            = @"xml";

NSString * const KEY_CARRIER_COUNTRY_CODE           = @"mobile_country_code";
NSString * const KEY_CARRIER_COUNTRY_CODE_ISO       = @"carrier_country_code";
NSString * const KEY_CARRIER_NETWORK_CODE           = @"mobile_network_code";

NSString * const DEFAULT_LOCALE_IDENTIFIER          = @"en_us";
NSString * const DEFAULT_TIMEZONE                   = @"UTC";

NSString * const NORMALLY_ENCRYPTED                 = @"normally_encrypted";
NSString * const HIGHLY_ENCRYPTED                   = @"highly_encrypted";

NSString * const EVENT_INSTALL                      = @"install";
NSString * const EVENT_UPDATE                       = @"update";
NSString * const EVENT_OPEN                         = @"open";
NSString * const EVENT_CLICK                        = @"click";
NSString * const EVENT_CLOSE                        = @"close";
NSString * const EVENT_CONVERSION                   = @"conversion";

NSString * const HTTP_METHOD_POST                   = @"POST";
NSString * const HTTP_CONTENT_TYPE                  = @"content-type";
NSString * const HTTP_CONTENT_TYPE_APPLICATION_JSON = @"application/json";

NSString * const KEY_ERROR_DOMAIN_MOBILEAPPTRACKER      = @"com.hasoffers.MobileAppTracker";

NSString * const KEY_ERROR_MAT_ADVERTISER_ID_MISSING    = @"mat_advertiser_id_missing";
NSString * const KEY_ERROR_MAT_ADVERTISER_KEY_MISSING   = @"mat_advertiser_key_missing";
NSString * const KEY_ERROR_MAT_APP_TO_APP_FAILURE       = @"mat_app_to_app_failure";
NSString * const KEY_ERROR_MAT_NETWORK_NOT_REACHABLE    = @"mat_network_not_reachable";

NSString * const STRING_EMPTY                           = @"";

NSString * const SERVER_DOMAIN_COOKIE_TRACKING          = @"http://launch1.co";
NSString * const SERVER_DOMAIN_REGULAR_TRACKING_PROD    = @"engine.mobileapptracking.com";
NSString * const SERVER_DOMAIN_REGULAR_TRACKING_STAGE   = @"engine.stage.mobileapptracking.com";
NSString * const SERVER_PATH_TRACKING_ENGINE            = @"serve";