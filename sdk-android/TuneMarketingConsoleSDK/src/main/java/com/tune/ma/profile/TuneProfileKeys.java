package com.tune.ma.profile;

import com.tune.TuneUrlKeys;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;

/**
 * Created by charlesgilliam on 1/15/16.
 * @deprecated IAM functionality. This method will be removed in Tune Android SDK v6.0.0
 */
@Deprecated
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

    private static final String USER_EMAIL = "user_email";      // reserved, but not used
    private static final String USER_NAME = "user_name";        // reserved, but not used
    private static final String USER_PHONE = "user_phone";      // reserved, but not used

    public static final String SESSION_ID = "session_id";
    public static final String SESSION_LAST_DATE = "last_session_date";
    public static final String SESSION_CURRENT_DATE = "current_session_date";
    public static final String SESSION_COUNT = "session_count";
    public static final String IS_FIRST_SESSION = "is_first_session";

    public static final String DEVICE_TOKEN = "deviceToken";
    public static final String IS_PUSH_ENABLED = "pushEnabled";

    /**
     * WARNING: It is very important that all new profile variables get added to this array OR to the REDACT array
     */
    private static final String[] PROFILE_KEYS = new String[] {
        OS_TYPE,
        APP_BUILD,
        API_LEVEL,
        INTERFACE_IDIOM,

        USER_EMAIL,                                        // Reserved, but not used
        USER_NAME,                                         // Reserved, but not used
        USER_PHONE,                                        // Reserved, but not used

        SESSION_ID,
        SESSION_LAST_DATE,
        SESSION_CURRENT_DATE,
        SESSION_COUNT,
        IS_FIRST_SESSION,

        IS_PUSH_ENABLED                                    // Set to NO if COPPA
    };

    private static final String[] PROFILE_KEYS_REDACT = new String[] {
        SCREEN_HEIGHT,
        SCREEN_WIDTH,
        MINUTES_FROM_GMT,
        HARDWARE_TYPE,
        GEO_COORDINATE,
        DEVICE_TOKEN,
    };

    /**
     * Return a Set of All Profile Keys, both redacted and non-redacted
     * @return the full Set of Profile Keys
     */
    public static final Set<String> getAllProfileKeys() {
        Set<String> keys = new HashSet<>(Arrays.asList(PROFILE_KEYS));
        keys.addAll(getRedactedProfileKeys());

        return keys;
    }

    /**
     * @return the set of redacted Profile Keys
     */
    public static final Set<String> getRedactedProfileKeys() {
        return new HashSet<>(Arrays.asList(PROFILE_KEYS_REDACT));
    }


    // Method should be called wherever a case-insensitive check of a string against existing profile variables is needed; case-insensitivity achieved by lowercasing input and set's contents
    // TODO: Currently cannot use something locale neutral here (such as Locale.ROOT) as our infrastructure can currently only support latin characters for variable names (i.e. English).
    // TODO: If infrastruture changes, consider whether it's possible to broaden character support for variables (and change Locale.ENGLISH to Locale.ROOT)

    static Set<String> sSystemVariables = null;
    static Object lockObject = new Object();
    static boolean isSystemVariable(String checkedString) {
        String lowercasedCheckedString = checkedString.toLowerCase(Locale.ENGLISH);

        // Create a set of system variables if one doesn't exist yet.
        // System Variables are expensive to calculate, but they do not change over the lifetime of the instance.
        synchronized (lockObject) {
            if (sSystemVariables == null) {
                sSystemVariables = new HashSet<String>();

                Set<String> keys = TuneUrlKeys.getAllUrlKeys();
                keys.addAll(getAllProfileKeys());

                for (String key : keys) {
                    sSystemVariables.add(key.toLowerCase(Locale.ENGLISH));
                }
            }
        }

        return sSystemVariables.contains(lowercasedCheckedString);
    }
}
