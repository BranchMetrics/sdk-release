package com.tune.ma.profile;

import com.tune.TuneUrlKeys;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;

/**
 * Created by charlesgilliam on 1/15/16.
 */
public class TuneProfileKeys {
    public static final String SCREEN_HEIGHT = "screen_height";
    public static final String SCREEN_WIDTH = "screen_width";

    public static final String OS_TYPE = "os_type";
    public static final String MINUTES_FROM_GMT = "minutesFromGMT";
    public static final String HARDWARE_TYPE = "hardwareType";
    public static final String APP_BUILD = "appBuild";
    public static final String API_LEVEL = "apiLevel";
    public static final String INTERFACE_IDIOM = "interfaceIdiom";
    public static final String GEO_COORDINATE = "geo_coordinate";

    public static final String USER_EMAIL = "user_email";
    public static final String USER_NAME = "user_name";
    public static final String USER_PHONE = "user_phone";

    public static final String SESSION_ID = "session_id";
    public static final String SESSION_LAST_DATE = "last_session_date";
    public static final String SESSION_CURRENT_DATE = "current_session_date";
    public static final String SESSION_COUNT = "session_count";
    public static final String IS_FIRST_SESSION = "is_first_session";

    public static final String DEVICE_TOKEN = "deviceToken";
    public static final String IS_PUSH_ENABLED = "pushEnabled";


    /*
    NOTE: To get this set I took all the constants from TuneUrlKeys and then ran this regex:
            Find:
             public static final String ([^ ]*) =.*
            Replace:
             TuneUrlKeys.$1,
          You'll want to repeat this process so it includes the constants in this file as well.
    WARNING: It is very important that all new profile variables get added to this array.
    */
    private static final Set<String> systemVariables = new HashSet<String>(Arrays.asList(
        TuneUrlKeys.ACTION,
        TuneUrlKeys.ADVERTISER_ID,
        TuneUrlKeys.DEBUG_MODE,
        TuneUrlKeys.EVENT_ID,
        TuneUrlKeys.EVENT_NAME,
        TuneUrlKeys.PACKAGE_NAME,
        TuneUrlKeys.REFERRAL_SOURCE,
        TuneUrlKeys.REFERRAL_URL,
        TuneUrlKeys.TRACKING_ID,
        TuneUrlKeys.SYSTEM_DATE,
        TuneUrlKeys.SDK,
        TuneUrlKeys.SDK_RETRY_ATTEMPT,
        TuneUrlKeys.SDK_VER,
        TuneUrlKeys.TRANSACTION_ID,

        TuneUrlKeys.PUBLISHER_ID,
        TuneUrlKeys.OFFER_ID,
        TuneUrlKeys.AGENCY_ID,
        TuneUrlKeys.PUBLISHER_REF_ID,
        TuneUrlKeys.PUBLISHER_SUB_PUBLISHER,
        TuneUrlKeys.PUBLISHER_SUB_SITE,
        TuneUrlKeys.PUBLISHER_SUB_CAMPAIGN,
        TuneUrlKeys.PUBLISHER_SUB_ADGROUP,
        TuneUrlKeys.PUBLISHER_SUB_AD,
        TuneUrlKeys.PUBLISHER_SUB_KEYWORD,
        TuneUrlKeys.PUBLISHER_SUB1,
        TuneUrlKeys.PUBLISHER_SUB2,
        TuneUrlKeys.PUBLISHER_SUB3,
        TuneUrlKeys.PUBLISHER_SUB4,
        TuneUrlKeys.PUBLISHER_SUB5,
        TuneUrlKeys.ADVERTISER_SUB_PUBLISHER,
        TuneUrlKeys.ADVERTISER_SUB_SITE,
        TuneUrlKeys.ADVERTISER_SUB_CAMPAIGN,
        TuneUrlKeys.ADVERTISER_SUB_ADGROUP,
        TuneUrlKeys.ADVERTISER_SUB_AD,
        TuneUrlKeys.ADVERTISER_SUB_KEYWORD,

        TuneUrlKeys.ALTITUDE,
        TuneUrlKeys.ANDROID_ID,
        TuneUrlKeys.ANDROID_ID_MD5,
        TuneUrlKeys.ANDROID_ID_SHA1,
        TuneUrlKeys.ANDROID_ID_SHA256,
        TuneUrlKeys.APP_AD_TRACKING,
        TuneUrlKeys.APP_NAME,
        TuneUrlKeys.APP_VERSION,
        TuneUrlKeys.APP_VERSION_NAME,
        TuneUrlKeys.CONNECTION_TYPE,
        TuneUrlKeys.COUNTRY_CODE,
        TuneUrlKeys.DEVICE_BRAND,
        TuneUrlKeys.DEVICE_CARRIER,
        TuneUrlKeys.DEVICE_CPU_TYPE,
        TuneUrlKeys.DEVICE_CPU_SUBTYPE,
        TuneUrlKeys.DEVICE_ID,
        TuneUrlKeys.DEVICE_MODEL,
        TuneUrlKeys.FIRE_AD_TRACKING_DISABLED,
        TuneUrlKeys.FIRE_AID,
        TuneUrlKeys.GOOGLE_AD_TRACKING_DISABLED,
        TuneUrlKeys.GOOGLE_AID,
        TuneUrlKeys.INSTALL_DATE,
        TuneUrlKeys.INSTALL_REFERRER,
        TuneUrlKeys.INSTALLER,
        TuneUrlKeys.LANGUAGE,
        TuneUrlKeys.LAST_OPEN_LOG_ID,
        TuneUrlKeys.LATITUDE,
        TuneUrlKeys.LONGITUDE,
        TuneUrlKeys.MAC_ADDRESS,
        TuneUrlKeys.MAT_ID,
        TuneUrlKeys.MOBILE_COUNTRY_CODE,
        TuneUrlKeys.MOBILE_NETWORK_CODE,
        TuneUrlKeys.OPEN_LOG_ID,
        TuneUrlKeys.OS_VERSION,
        TuneUrlKeys.PURCHASE_STATUS,
        TuneUrlKeys.REFERRER_DELAY,
        TuneUrlKeys.SCREEN_DENSITY,
        TuneUrlKeys.SCREEN_SIZE,
        TuneUrlKeys.SDK_PLUGIN,
        TuneUrlKeys.SDK_VERSION,
        TuneUrlKeys.TRUSTE_ID,
        TuneUrlKeys.USER_AGENT,

        TuneUrlKeys.ATTRIBUTE1,
        TuneUrlKeys.ATTRIBUTE2,
        TuneUrlKeys.ATTRIBUTE3,
        TuneUrlKeys.ATTRIBUTE4,
        TuneUrlKeys.ATTRIBUTE5,
        TuneUrlKeys.CONTENT_ID,
        TuneUrlKeys.CONTENT_TYPE,
        TuneUrlKeys.CURRENCY_CODE,
        TuneUrlKeys.DATE1,
        TuneUrlKeys.DATE2,
        TuneUrlKeys.DEVICE_FORM,
        TuneUrlKeys.LEVEL,
        TuneUrlKeys.QUANTITY,
        TuneUrlKeys.RATING,
        TuneUrlKeys.REF_ID,
        TuneUrlKeys.REVENUE,
        TuneUrlKeys.SEARCH_STRING,

        TuneUrlKeys.AGE,
        TuneUrlKeys.EXISTING_USER,
        TuneUrlKeys.FACEBOOK_USER_ID,
        TuneUrlKeys.GENDER,
        TuneUrlKeys.GOOGLE_USER_ID,
        TuneUrlKeys.IS_PAYING_USER,
        TuneUrlKeys.TWITTER_USER_ID,
        TuneUrlKeys.USER_EMAIL_MD5,
        TuneUrlKeys.USER_EMAIL_SHA1,
        TuneUrlKeys.USER_EMAIL_SHA256,
        TuneUrlKeys.USER_ID,
        TuneUrlKeys.USER_NAME_MD5,
        TuneUrlKeys.USER_NAME_SHA1,
        TuneUrlKeys.USER_NAME_SHA256,
        TuneUrlKeys.USER_PHONE_MD5,
        TuneUrlKeys.USER_PHONE_SHA1,
        TuneUrlKeys.USER_PHONE_SHA256,

        TuneUrlKeys.EVENT_ITEMS,
        TuneUrlKeys.RECEIPT_DATA,
        TuneUrlKeys.RECEIPT_SIGNATURE,
        TuneUrlKeys.USER_EMAILS,

        SCREEN_HEIGHT,
        SCREEN_WIDTH,

        OS_TYPE,
        MINUTES_FROM_GMT,
        HARDWARE_TYPE,
        APP_BUILD,
        API_LEVEL,
        INTERFACE_IDIOM,
        GEO_COORDINATE,

        USER_EMAIL,
        USER_NAME,
        USER_PHONE,

        SESSION_ID,
        SESSION_LAST_DATE,
        SESSION_CURRENT_DATE,
        SESSION_COUNT,
        IS_FIRST_SESSION,

        DEVICE_TOKEN,
        IS_PUSH_ENABLED
    ));

    // Method should be called wherever a case-insensitive check of a string against existing profile variables is needed; case-insensitivity achieved by lowercasing input and set's contents
    // TODO: Currently cannot use something locale neutral here (such as Locale.ROOT) as our infrastructure can currently only support latin characters for variable names (i.e. English).
    // TODO: If infrastruture changes, consider whether it's possible to broaden character support for variables (and change Locale.ENGLISH to Locale.ROOT)
    public static boolean isSystemVariable(String checkedString) {
        String lowercasedCheckedString = checkedString.toLowerCase(Locale.ENGLISH);
        for (String systemVariable : systemVariables) {
            if (lowercasedCheckedString.equals(systemVariable.toLowerCase(Locale.ENGLISH))) {
                return true;
            }
        }
        return false;
    }
}
