package com.mobileapptracker;

class MATConstants {
    // SharedPreferences filename for TUNE
    static final String PREFS_TUNE = "com.mobileapptracking";
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
    static final String KEY_MAT_ID = "mat_id";
    // Key for paying user
    static final String KEY_PAYING_USER = "mat_is_paying_user";
    // Key for phone number
    static final String KEY_PHONE_NUMBER = "mat_phone_number";
    // Key for user email
    static final String KEY_USER_EMAIL = "mat_user_email";
    // Key for user ID
    static final String KEY_USER_ID = "mat_user_id";
    // Key for user name
    static final String KEY_USER_NAME = "mat_user_name";
    
    // GET_ACCOUNTS permission
    static final String PERMISSION_GET_ACCOUNTS = "android.permission.GET_ACCOUNTS";
    
    // Server domain
    static final String MAT_DOMAIN = "engine.mobileapptracking.com";
    // Server domain for debug
    static final String MAT_DOMAIN_DEBUG = "debug.engine.mobileapptracking.com";
    // Deeplink endpoint
    static final String DEEPLINK_DOMAIN = "deeplink.mobileapptracking.com";
    
    // MAT Android SDK version number
    static final String SDK_VERSION = "3.10.1";
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
