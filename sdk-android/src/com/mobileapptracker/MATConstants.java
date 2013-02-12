package com.mobileapptracker;

public class MATConstants {
    // SharedPreferences filename for referrer
    static final String PREFS_REFERRER = "mat_referrer";
    // SharedPreferences filename for Facebook re-engagement intent
    static final String PREFS_FACEBOOK_INTENT = "mat_fb_intent";
    // SharedPreferences filename for a MAT install
    static final String PREFS_INSTALL = "mat_install";
    // SharedPreferences filename for MAT ID
    static final String PREFS_MAT_ID = "mat_id";
    // SharedPreferences filename for queued events
    static final String PREFS_NAME = "mat_queue";
    // SharedPreferences filename for previously seen app version
    static final String PREFS_VERSION = "mat_app_version";
    // Date format for sending event date
    static final String DATE_FORMAT = "yyyy-MM-dd HH:mm:ss";
    // MAT Android SDK version number
    static final String SDK_VERSION = "2.1";
    // Debug log tag
    static final String TAG = "MobileAppTracker";
    // Max number of events to dump when queued
    static final int MAX_DUMP_SIZE = 50;
    // Set a network timeout time of 5s
    static final int TIMEOUT = 5000;
    // Time in milliseconds to wait for INSTALL_REFERRER before tracking
    static final int DELAY = 3000;
}
