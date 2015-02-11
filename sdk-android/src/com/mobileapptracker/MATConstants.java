package com.mobileapptracker;

class MATConstants {
    // SharedPreferences filename for referrer
    static final String PREFS_REFERRER = "mat_referrer";
    // SharedPreferences filename for Facebook re-engagement intent
    static final String PREFS_FACEBOOK_INTENT = "mat_fb_intent";
    // SharedPreferences filename for a MAT install
    static final String PREFS_INSTALL = "mat_install";
    // Key for PREFS_INSTALL
    static final String PREFS_INSTALL_KEY = "installed";
    // SharedPreferences filename for install log ID
    static final String PREFS_LOG_ID_INSTALL = "mat_log_id_install";
    // SharedPreferences filename for update log ID
    static final String PREFS_LOG_ID_UPDATE = "mat_log_id_update";
    // SharedPreferences filename for update log ID
    static final String PREFS_LOG_ID_OPEN = "mat_log_id_open";
    // SharedPreferences filename for update log ID
    static final String PREFS_LOG_ID_LAST_OPEN = "mat_log_id_last_open";
    // Key for PREFS_LOG_ID_INSTALL, PREFS_LOG_ID_UPDATE, PREFS_LOG_ID_OPEN
    static final String PREFS_LOG_ID_KEY = "logId";
    // SharedPreferences filename for MAT ID
    static final String PREFS_MAT_ID = "mat_id";
    // SharedPreferences filename for queued events
    static final String PREFS_QUEUE = "mat_queue";
    // SharedPreferences filename for previously seen app version
    static final String PREFS_VERSION = "mat_app_version";
    // SharedPreferences filename for revenue-generating users
    static final String PREFS_IS_PAYING_USER = "mat_is_paying_user";
    // SharedPreferences filename for user IDs
    static final String PREFS_USER_IDS = "mat_user_ids";
    
    // GET_ACCOUNTS permission
    static final String PERMISSION_GET_ACCOUNTS = "android.permission.GET_ACCOUNTS";
    
    // Server domain
    static final String MAT_DOMAIN = "engine.mobileapptracking.com";
    // Server domain for debug
    static final String MAT_DOMAIN_DEBUG = "debug.engine.mobileapptracking.com";
    // Deeplink endpoint
    static final String DEEPLINK_DOMAIN = "deeplink.mobileapptracking.com";
    
    // MAT Android SDK version number
    static final String SDK_VERSION = "3.7.1";
    // Debug log tag
    static final String TAG = "MobileAppTracker";
    // Max number of events to dump when queued
    static final int MAX_DUMP_SIZE = 50;
    // Set a network timeout time of 60s
    static final int TIMEOUT = 60000;
    // Request delay time of 60s
    static final long DELAY = 60000;
    
    // Default currency code is USD
    static final String DEFAULT_CURRENCY_CODE = "USD";
    
    static final String[] PLUGIN_NAMES = {
        "air",
        "cocos2dx",
        "js",
        "marmalade",
        "phonegap",
        "titanium",
        "unity",
        "xamarin"
    };
}
