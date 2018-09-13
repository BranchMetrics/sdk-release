package com.tune;

public class TuneConstants {
    // SharedPreferences filename for TUNE
    public static final String PREFS_TUNE = "com.mobileapptracking";
    // SharedPreferences filename for queued events
    static final String PREFS_QUEUE = "mat_queue";

    // Key for install referrer
    static final String KEY_REFERRER = "mat_referrer";
    // Key for install status
    static final String KEY_INSTALL = "mat_installed";
    // Key for open log id
    static final String KEY_LOG_ID = "mat_log_id_open";
    // Key for last open log id
    static final String KEY_LAST_LOG_ID = "mat_log_id_last_open";
    // Key for MAT ID
    static final String KEY_TUNE_ID = "mat_id";
    // Key for paying user
    static final String KEY_PAYING_USER = "mat_is_paying_user";
    // Key for phone number
    static final String KEY_PHONE_NUMBER = "mat_phone_number";
    // Key for IS_COPPA
    static final String KEY_COPPA = "mat_is_coppa";
    // Key for user email (Gmail)
    static final String KEY_USER_EMAIL = "mat_user_email";
    // Key for user emails (Other emails aside from primary Gmail)
    static final String KEY_USER_EMAILS = "mat_user_emails";
    // Key for user ID
    static final String KEY_USER_ID = "mat_user_id";
    // Key for user name
    static final String KEY_USER_NAME = "mat_user_name";
    // InstallBeginTimestamp
    static final String KEY_INSTALL_BEGIN_TIMESTAMP = "install_begin_timestamp";
    // ReferrerClickTimestamp
    static final String KEY_REFERRER_CLICK_TIMESTAMP = "referrer_click_timestamp";
    // Url parameter key and response key for Tune Link invoke url
    public static final String KEY_INVOKE_URL = "invoke_url";

    // Server domain
    static final String TUNE_DOMAIN = "engine.mobileapptracking.com";
    // Deeplink endpoint
    public static final String DEEPLINK_DOMAIN = "deeplink.mobileapptracking.com";

    public static final String STRING_TRUE = "true";
    public static final String STRING_FALSE = "false";

    public static final String SERVER_RESPONSE_SUCCESS = "success";

    public static final String PREF_UNSET = "0";
    public static final String PREF_SET = "1";

    // IS_COPPA Minimum Age restriction (US)
    public static final int COPPA_MINIMUM_AGE = 13;

    // Max number of events to dump when queued
    static final int MAX_DUMP_SIZE = 50;
    // Set a network timeout time of 60s
    public static final int TIMEOUT = 60000;
    // Request delay time of 60s
    static final int DELAY = 60000;

    static final String[] PLUGIN_NAMES = {
        "air",
        "cocos2dx",
        "corona",
        "js",
        "marmalade",
        "phonegap",
        "react-native",
        "titanium",
        "unity",
        "xamarin"
    };

    static final String UUID_EMPTY = "00000000-0000-0000-0000-000000000000";

    static final String FIRE_ADVERTISING_ID_KEY = "advertising_id";
    static final String FIRE_LIMIT_AD_TRACKING_KEY = "limit_ad_tracking";

    static final String GOOGLE_ACCOUNT_TYPE = "com.google";
}
