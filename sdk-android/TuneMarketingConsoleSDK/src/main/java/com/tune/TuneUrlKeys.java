package com.tune;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/**
 * Created by johng on 12/30/15.
 */
public class TuneUrlKeys {
    // General SDK data keys
    public static final String ACTION = "action";
    public static final String ADVERTISER_ID = "advertiser_id";
    public static final String DEBUG_MODE = "debug";
    public static final String EVENT_ID = "site_event_id";
    public static final String EVENT_NAME = "site_event_name";
    public static final String PACKAGE_NAME = "package_name";
    public static final String REFERRAL_SOURCE = "referral_source";
    public static final String REFERRAL_URL = "referral_url";
    public static final String TRACKING_ID = "tracking_id";
    public static final String SYSTEM_DATE = "system_date";
    public static final String SDK = "sdk";
    public static final String SDK_RETRY_ATTEMPT = "sdk_retry_attempt";
    public static final String SDK_VER = "ver";
    public static final String TRANSACTION_ID = "transaction_id";
    public static final String RESPONSE_FORMAT = "response_format";

    // Preloaded app keys
    public static final String PUBLISHER_ID = "publisher_id";
    public static final String OFFER_ID = "offer_id";
    public static final String AGENCY_ID = "agency_id";
    public static final String PUBLISHER_REF_ID = "publisher_ref_id";
    public static final String PUBLISHER_SUB_PUBLISHER = "publisher_sub_publisher";
    public static final String PUBLISHER_SUB_SITE = "publisher_sub_site";
    public static final String PUBLISHER_SUB_CAMPAIGN = "publisher_sub_campaign";
    public static final String PUBLISHER_SUB_ADGROUP = "publisher_sub_adgroup";
    public static final String PUBLISHER_SUB_AD = "publisher_sub_ad";
    public static final String PUBLISHER_SUB_KEYWORD = "publisher_sub_keyword";
    public static final String PUBLISHER_SUB1 = "publisher_sub1";
    public static final String PUBLISHER_SUB2 = "publisher_sub2";
    public static final String PUBLISHER_SUB3 = "publisher_sub3";
    public static final String PUBLISHER_SUB4 = "publisher_sub4";
    public static final String PUBLISHER_SUB5 = "publisher_sub5";
    public static final String ADVERTISER_SUB_PUBLISHER = "advertiser_sub_publisher";
    public static final String ADVERTISER_SUB_SITE = "advertiser_sub_site";
    public static final String ADVERTISER_SUB_CAMPAIGN = "advertiser_sub_campaign";
    public static final String ADVERTISER_SUB_ADGROUP = "advertiser_sub_adgroup";
    public static final String ADVERTISER_SUB_AD = "advertiser_sub_ad";
    public static final String ADVERTISER_SUB_KEYWORD = "advertiser_sub_keyword";

    // Encrypted data keys
    public static final String ALTITUDE = "altitude";
    public static final String ANDROID_ID = "android_id";
    public static final String ANDROID_ID_MD5 = "android_id_md5";
    public static final String ANDROID_ID_SHA1 = "android_id_sha1";
    public static final String ANDROID_ID_SHA256 = "android_id_sha256";
    public static final String APP_AD_TRACKING = "app_ad_tracking";
    public static final String APP_NAME = "app_name";
    public static final String APP_VERSION = "app_version";
    public static final String APP_VERSION_NAME = "app_version_name";
    public static final String CONNECTION_TYPE = "connection_type";
    public static final String COUNTRY_CODE = "country_code";
    public static final String DEVICE_BRAND = "device_brand";
    public static final String DEVICE_BUILD = "build";
    public static final String DEVICE_CARRIER = "device_carrier";
    public static final String DEVICE_CPU_TYPE = "device_cpu_type";
    public static final String DEVICE_CPU_SUBTYPE = "device_cpu_subtype";
    public static final String DEVICE_ID = "device_id";
    public static final String DEVICE_MODEL = "device_model";
    public static final String FIRE_AD_TRACKING_DISABLED = "fire_ad_tracking_disabled";
    public static final String FIRE_AID = "fire_aid";
    public static final String GOOGLE_AD_TRACKING_DISABLED = "google_ad_tracking_disabled";
    public static final String GOOGLE_AID = "google_aid";
    public static final String INSTALL_DATE = "insdate";
    public static final String INSTALL_BEGIN_TIMESTAMP = "download_date";
    public static final String REFERRER_CLICK_TIMESTAMP = "click_timestamp";
    public static final String INSTALL_REFERRER = "install_referrer";
    public static final String INSTALLER = "installer";
    public static final String LANGUAGE = "language";
    public static final String LAST_OPEN_LOG_ID = "last_open_log_id";
    public static final String LATITUDE = "latitude";
    public static final String LOCALE = "locale";
    public static final String LONGITUDE = "longitude";
    public static final String MAC_ADDRESS = "mac_address";
    public static final String MAT_ID = "mat_id";
    public static final String MOBILE_COUNTRY_CODE = "mobile_country_code";
    public static final String MOBILE_NETWORK_CODE = "mobile_network_code";
    public static final String OPEN_LOG_ID = "open_log_id";
    public static final String OS_VERSION = "os_version";
    public static final String PURCHASE_STATUS = "android_purchase_status";
    public static final String REFERRER_DELAY = "referrer_delay";
    public static final String SCREEN_DENSITY = "screen_density";
    public static final String SCREEN_LAYOUT_SIZE = "screen_layout_size";
    public static final String SDK_PLUGIN = "sdk_plugin";
    public static final String SDK_VERSION = "sdk_version";
    public static final String TRUSTE_ID = "truste_tpid";
    public static final String USER_AGENT = "conversion_user_agent";

    // Event data keys
    public static final String ATTRIBUTE1 = "attribute_sub1";
    public static final String ATTRIBUTE2 = "attribute_sub2";
    public static final String ATTRIBUTE3 = "attribute_sub3";
    public static final String ATTRIBUTE4 = "attribute_sub4";
    public static final String ATTRIBUTE5 = "attribute_sub5";
    public static final String CONTENT_ID = "content_id";
    public static final String CONTENT_TYPE = "content_type";
    public static final String CURRENCY_CODE = "currency_code";
    public static final String DATE1 = "date1";
    public static final String DATE2 = "date2";
    public static final String DEVICE_FORM = "device_form";
    public static final String LEVEL = "level";
    public static final String QUANTITY = "quantity";
    public static final String RATING = "rating";
    public static final String REF_ID = "advertiser_ref_id";
    public static final String REVENUE = "revenue";
    public static final String SEARCH_STRING = "search_string";

    // User data keys
    public static final String AGE = "age";
    public static final String EXISTING_USER = "existing_user";
    public static final String FACEBOOK_USER_ID = "facebook_user_id";
    public static final String GENDER = "gender";
    public static final String GOOGLE_USER_ID = "google_user_id";
    public static final String IS_COPPA = "is_coppa";
    public static final String IS_PAYING_USER = "is_paying_user";
    public static final String TWITTER_USER_ID = "twitter_user_id";
    public static final String USER_EMAIL_MD5 = "user_email_md5";
    public static final String USER_EMAIL_SHA1 = "user_email_sha1";
    public static final String USER_EMAIL_SHA256 = "user_email_sha256";
    public static final String USER_ID = "user_id";
    public static final String USER_NAME_MD5 = "user_name_md5";
    public static final String USER_NAME_SHA1 = "user_name_sha1";
    public static final String USER_NAME_SHA256 = "user_name_sha256";
    public static final String USER_PHONE_MD5 = "user_phone_md5";
    public static final String USER_PHONE_SHA1 = "user_phone_sha1";
    public static final String USER_PHONE_SHA256 = "user_phone_sha256";

    // Post data keys
    public static final String EVENT_ITEMS = "data";
    public static final String RECEIPT_DATA = "store_iap_data";
    public static final String RECEIPT_SIGNATURE = "store_iap_signature";
    public static final String USER_EMAILS = "user_emails";

    /**
     * WARNING: It is very important that all new profile variables get added to this array OR to the REDACT array
     */
    private static final String[] URL_KEYS = new String[] {
        TuneUrlKeys.ACTION,
        TuneUrlKeys.ADVERTISER_ID,
        TuneUrlKeys.ADVERTISER_SUB_AD,
        TuneUrlKeys.ADVERTISER_SUB_ADGROUP,
        TuneUrlKeys.ADVERTISER_SUB_CAMPAIGN,
        TuneUrlKeys.ADVERTISER_SUB_KEYWORD,
        TuneUrlKeys.ADVERTISER_SUB_PUBLISHER,
        TuneUrlKeys.ADVERTISER_SUB_SITE,
        TuneUrlKeys.AGE,
        TuneUrlKeys.AGENCY_ID,
        TuneUrlKeys.ANDROID_ID_MD5,
        TuneUrlKeys.ANDROID_ID_SHA1,
        TuneUrlKeys.ANDROID_ID_SHA256,
        TuneUrlKeys.APP_AD_TRACKING,                       // (change value to "1")
        TuneUrlKeys.APP_NAME,
        TuneUrlKeys.APP_VERSION,
        TuneUrlKeys.APP_VERSION_NAME,
        TuneUrlKeys.ATTRIBUTE1,
        TuneUrlKeys.ATTRIBUTE2,
        TuneUrlKeys.ATTRIBUTE3,
        TuneUrlKeys.ATTRIBUTE4,
        TuneUrlKeys.ATTRIBUTE5,
        TuneUrlKeys.CONTENT_ID,
        TuneUrlKeys.CONTENT_TYPE,
        TuneUrlKeys.DATE1,
        TuneUrlKeys.DATE2,
        TuneUrlKeys.DEBUG_MODE,
        TuneUrlKeys.EVENT_ID,
        TuneUrlKeys.EVENT_ITEMS,
        TuneUrlKeys.EVENT_NAME,
        TuneUrlKeys.EXISTING_USER,
        TuneUrlKeys.FIRE_AD_TRACKING_DISABLED,
        TuneUrlKeys.FIRE_AID,
        TuneUrlKeys.GOOGLE_AD_TRACKING_DISABLED,           // (Set to protected)
        TuneUrlKeys.GOOGLE_AID,
        TuneUrlKeys.INSTALLER,
        TuneUrlKeys.INSTALL_BEGIN_TIMESTAMP,
        TuneUrlKeys.INSTALL_DATE,
        TuneUrlKeys.INSTALL_REFERRER,
        TuneUrlKeys.IS_COPPA,
        TuneUrlKeys.LANGUAGE,
        TuneUrlKeys.LAST_OPEN_LOG_ID,
        TuneUrlKeys.LEVEL,
        TuneUrlKeys.MAT_ID,
        TuneUrlKeys.OFFER_ID,
        TuneUrlKeys.PACKAGE_NAME,
        TuneUrlKeys.PUBLISHER_ID,
        TuneUrlKeys.PUBLISHER_REF_ID,
        TuneUrlKeys.PUBLISHER_SUB1,
        TuneUrlKeys.PUBLISHER_SUB2,
        TuneUrlKeys.PUBLISHER_SUB3,
        TuneUrlKeys.PUBLISHER_SUB4,
        TuneUrlKeys.PUBLISHER_SUB5,
        TuneUrlKeys.PUBLISHER_SUB_AD,
        TuneUrlKeys.PUBLISHER_SUB_ADGROUP,
        TuneUrlKeys.PUBLISHER_SUB_CAMPAIGN,
        TuneUrlKeys.PUBLISHER_SUB_KEYWORD,
        TuneUrlKeys.PUBLISHER_SUB_PUBLISHER,
        TuneUrlKeys.PUBLISHER_SUB_SITE,
        TuneUrlKeys.PURCHASE_STATUS,
        TuneUrlKeys.QUANTITY,
        TuneUrlKeys.RATING,
        TuneUrlKeys.RECEIPT_DATA,
        TuneUrlKeys.RECEIPT_SIGNATURE,
        TuneUrlKeys.REFERRAL_SOURCE,
        TuneUrlKeys.REFERRER_CLICK_TIMESTAMP,
        TuneUrlKeys.REFERRER_DELAY,
        TuneUrlKeys.REF_ID,
        TuneUrlKeys.RESPONSE_FORMAT,
        TuneUrlKeys.REVENUE,
        TuneUrlKeys.SDK,
        TuneUrlKeys.SDK_PLUGIN,
        TuneUrlKeys.SDK_RETRY_ATTEMPT,
        TuneUrlKeys.SDK_VER,
        TuneUrlKeys.SDK_VERSION,
        TuneUrlKeys.SEARCH_STRING,
        TuneUrlKeys.SYSTEM_DATE,
        TuneUrlKeys.TRACKING_ID,
        TuneUrlKeys.TRANSACTION_ID,
        TuneUrlKeys.USER_ID,
    };

    private static final String[] URL_KEYS_REDACT = new String[] {
        TuneUrlKeys.ALTITUDE,
        TuneUrlKeys.ANDROID_ID,
        TuneUrlKeys.CONNECTION_TYPE,
        TuneUrlKeys.COUNTRY_CODE,
        TuneUrlKeys.CURRENCY_CODE,
        TuneUrlKeys.DEVICE_BRAND,
        TuneUrlKeys.DEVICE_BUILD,
        TuneUrlKeys.DEVICE_CARRIER,
        TuneUrlKeys.DEVICE_CPU_SUBTYPE,
        TuneUrlKeys.DEVICE_CPU_TYPE,
        TuneUrlKeys.DEVICE_FORM,
        TuneUrlKeys.DEVICE_ID,
        TuneUrlKeys.DEVICE_MODEL,
        TuneUrlKeys.FACEBOOK_USER_ID,
        TuneUrlKeys.GENDER,
        TuneUrlKeys.GOOGLE_USER_ID,
        TuneUrlKeys.IS_PAYING_USER,
        TuneUrlKeys.LATITUDE,
        TuneUrlKeys.LOCALE,
        TuneUrlKeys.LONGITUDE,
        TuneUrlKeys.MAC_ADDRESS,
        TuneUrlKeys.MOBILE_COUNTRY_CODE,
        TuneUrlKeys.MOBILE_NETWORK_CODE,
        TuneUrlKeys.OPEN_LOG_ID,
        TuneUrlKeys.OS_VERSION,
        TuneUrlKeys.REFERRAL_URL,
        TuneUrlKeys.SCREEN_DENSITY,
        TuneUrlKeys.SCREEN_LAYOUT_SIZE,
        TuneUrlKeys.TRUSTE_ID,
        TuneUrlKeys.TWITTER_USER_ID,
        TuneUrlKeys.USER_AGENT,
        TuneUrlKeys.USER_EMAILS,
        TuneUrlKeys.USER_EMAIL_MD5,
        TuneUrlKeys.USER_EMAIL_SHA1,
        TuneUrlKeys.USER_EMAIL_SHA256,
        TuneUrlKeys.USER_NAME_MD5,
        TuneUrlKeys.USER_NAME_SHA1,
        TuneUrlKeys.USER_NAME_SHA256,
        TuneUrlKeys.USER_PHONE_MD5,
        TuneUrlKeys.USER_PHONE_SHA1,
        TuneUrlKeys.USER_PHONE_SHA256,
    };

    /**
     * Return a Set of All Url Keys, both redacted and non-redacted
     * @return the full Set of Url Keys
     */
    public static final Set<String> getAllUrlKeys() {
        Set<String> keys = new HashSet<>(Arrays.asList(URL_KEYS));
        keys.addAll(getRedactedUrlKeys());

        return keys;
    }

    /**
     * @return the set of redacted Url Keys
     */
    public static final Set<String> getRedactedUrlKeys() {
        return new HashSet<>(Arrays.asList(URL_KEYS_REDACT));
    }

}
