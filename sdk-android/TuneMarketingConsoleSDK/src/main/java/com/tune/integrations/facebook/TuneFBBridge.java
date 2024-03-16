package com.tune.integrations.facebook;

import java.lang.reflect.Method;
import java.util.Locale;

import android.content.Context;
import android.os.Bundle;

import com.tune.TuneDebugLog;
import com.tune.TuneEvent;
import com.tune.TuneParameters;

public class TuneFBBridge {
    /* From FB SDK's AppEventsConstants.java */
    
    /** Log this event when an app is being activated. */
    public static final String EVENT_NAME_ACTIVATED_APP = "fb_mobile_activate_app";

    /** Log this event when a user has completed registration with the app. */
    public static final String EVENT_NAME_COMPLETED_REGISTRATION = "fb_mobile_complete_registration";
    
    /** Log this event when a user has viewed a form of content in the app. */
    public static final String EVENT_NAME_VIEWED_CONTENT = "fb_mobile_content_view";

    /** Log this event when a user has performed a search within the app. */
    public static final String EVENT_NAME_SEARCHED = "fb_mobile_search";

    /**
     * Log this event when the user has rated an item in the app.
     * The valueToSum passed to logEvent should be the numeric rating.
     */
    public static final String EVENT_NAME_RATED = "fb_mobile_rate";

    /** Log this event when the user has completed a tutorial in the app. */
    public static final String EVENT_NAME_COMPLETED_TUTORIAL = "fb_mobile_tutorial_completion";

    // Ecommerce related

    /**
     * Log this event when the user has added an item to their cart.
     * The valueToSum passed to logEvent should be the item's price.
     */
    public static final String EVENT_NAME_ADDED_TO_CART = "fb_mobile_add_to_cart";

    /**
     * Log this event when the user has added an item to their wishlist.
     * The valueToSum passed to logEvent should be the item's price.
     */
    public static final String EVENT_NAME_ADDED_TO_WISHLIST = "fb_mobile_add_to_wishlist";

    /**
     * Log this event when the user has entered the checkout process.
     * The valueToSum passed to logEvent should be the total price in the cart.
     */
    public static final String EVENT_NAME_INITIATED_CHECKOUT = "fb_mobile_initiated_checkout";

    /** Log this event when the user has entered their payment info. */
    public static final String EVENT_NAME_ADDED_PAYMENT_INFO = "fb_mobile_add_payment_info";

    /**
     * Log this event when the user has completed a purchase.
     */
    public static final String EVENT_NAME_PURCHASED = "fb_mobile_purchase";

    // Gaming related

    /** Log this event when the user has achieved a level in the app. */
    public static final String EVENT_NAME_ACHIEVED_LEVEL = "fb_mobile_level_achieved";

    /** Log this event when the user has unlocked an achievement in the app. */
    public static final String EVENT_NAME_UNLOCKED_ACHIEVEMENT = "fb_mobile_achievement_unlocked";

    /**
     * Log this event when the user has spent app credits.
     * The valueToSum passed to logEvent should be the number of credits spent.
     */
    public static final String EVENT_NAME_SPENT_CREDITS = "fb_mobile_spent_credits";


    // Event parameters

    /**
     * Parameter key used to specify currency used with logged event.  E.g. "USD", "EUR", "GBP".
     * See ISO-4217 for specific values.  One reference for these is http://en.wikipedia.org/wiki/ISO_4217.
     */
    public static final String EVENT_PARAM_CURRENCY = "fb_currency";
    
    /**
     * Parameter key used to specify a generic content type/family for the logged event, e.g. "music", "photo",
     * "video".  Options to use will vary based upon what the app is all about.
     */
    public static final String EVENT_PARAM_CONTENT_TYPE = "fb_content_type";
    
    /**
     * Parameter key used to specify an ID for the specific piece of content being logged about.
     * Could be an EAN, article identifier, etc., depending on the nature of the app.
     */
    public static final String EVENT_PARAM_CONTENT_ID = "fb_content_id";

    /** Parameter key used to specify the string provided by the user for a search operation. */
    public static final String EVENT_PARAM_SEARCH_STRING = "fb_search_string";

    /**
     * Parameter key used to specify how many items are being processed for an EVENT_NAME_INITIATED_CHECKOUT
     * or EVENT_NAME_PURCHASE event.
     */
    public static final String EVENT_PARAM_NUM_ITEMS = "fb_num_items";

    /** Parameter key used to specify the level achieved in a EVENT_NAME_LEVEL_ACHIEVED event. */
    public static final String EVENT_PARAM_LEVEL = "fb_level";
    
    private static Object logger;
    private static boolean justActivated = false;
    
    public static void startLogger(Context context, boolean limitEventAndDataUsage) {
        // Check for Facebook SDK version to determine API calls
        String sdkVersion = getFbSdkVersion();
        startLoggerForVersion(sdkVersion, context, limitEventAndDataUsage);
    }
    
    private static String getFbSdkVersion() {
        // Try to invoke 4.x SDK via reflection
        try {
            // > 4.0, com.facebook.FacebookSdk -> getSdkVersion()
            Method sdkVersionMethod = Class.forName("com.facebook.FacebookSdk").getMethod("getSdkVersion");
            return (String)sdkVersionMethod.invoke(null);
        } catch (Exception e) {
            // Reflection failed for 4.x, try 3.x
            TuneDebugLog.d("getFbSdkVersion() failed for 4.x", e);
            try {
                // < 4.0, com.facebook.Settings -> getSdkVersion()
                Method sdkVersionMethod = Class.forName("com.facebook.Settings").getMethod("getSdkVersion");
                return (String)sdkVersionMethod.invoke(null);
            } catch (Exception e1) {
                TuneDebugLog.d("getFbSdkVersion() failed", e1);
            }
        }
        return "";
    }
    
    private static void startLoggerForVersion(String sdkVersion, Context context, boolean limitEventAndDataUsage) {
        // If we were able to determine SDK version, start the logger
        if (!sdkVersion.isEmpty()) {
            String appEventsLoggerClassName = "";
            String setLimitEventAndDataUsageClassName = "";
            if (sdkVersion.startsWith("4.")) {
                // 4.x AppEventsLogger class name
                appEventsLoggerClassName = "com.facebook.appevents.AppEventsLogger";
                // 4.x setLimitEventAndDataUsage class name
                setLimitEventAndDataUsageClassName = "com.facebook.FacebookSdk";
            } else if (sdkVersion.startsWith("3.")) {
                // 3.x AppEventsLogger class name
                appEventsLoggerClassName = "com.facebook.AppEventsLogger";
                // 3.x setLimitEventAndDataUsage class name
                setLimitEventAndDataUsageClassName = "com.facebook.Settings";
            } 
            
            try {
                // Call AppEventsLogger's activateApp method with Context
                Class<?>[] activateMethodParams = new Class[1];
                activateMethodParams[0] = Context.class;
                Method activateMethod = Class.forName(appEventsLoggerClassName).getMethod("activateApp", activateMethodParams);
                Object[] activateArgs = new Object[1];
                activateArgs[0] = context;
                activateMethod.invoke(null, activateArgs);
                
                justActivated = true;
                
                // Call setLimitEventAndDataUsage method with Context and limitEvent setting
                Class<?>[] limitMethodParams = new Class[2];
                limitMethodParams[0] = Context.class;
                limitMethodParams[1] = boolean.class;
                Method limitMethod = Class.forName(setLimitEventAndDataUsageClassName).getMethod("setLimitEventAndDataUsage", limitMethodParams);
                Object[] limitArgs = new Object[2];
                limitArgs[0] = context;
                limitArgs[1] = limitEventAndDataUsage;
                limitMethod.invoke(null, limitArgs);
                
                // Call AppEventsLogger's newLogger method with same Context
                Method loggerMethod = Class.forName(appEventsLoggerClassName).getMethod("newLogger", activateMethodParams);
                logger = loggerMethod.invoke(null, activateArgs);
            } catch (Exception e) {
                TuneDebugLog.d("startLoggerForVersion() exception", e);
            }
        }
    }
    
    // Sends event to FB SDK's logEvent
    public static void logEvent(TuneParameters params, TuneEvent event) {
        if (logger != null) {
            try {
                Class<?>[] methodParams = new Class[3];
                methodParams[0] = String.class;
                methodParams[1] = double.class;
                methodParams[2] = Bundle.class;
                
                Method method = logger.getClass().getMethod("logEvent", methodParams);
                
                /*
                   Try to map the event name to a FB event name
                   Based on recommended event names from
                   https://developers.mobileapptracking.com/app-events-sdk/
                 */
                String fbEventName = event.getEventName();
                double valueToSum = event.getRevenue();

                String eventNameLower = event.getEventName().toLowerCase(Locale.US);
                if (eventNameLower.contains("session")) {
                    // Don't send activation twice on first init
                    if (justActivated) {
                        return;
                    }
                    fbEventName = EVENT_NAME_ACTIVATED_APP;
                } else if (eventNameLower.contains("registration")) {
                    fbEventName = EVENT_NAME_COMPLETED_REGISTRATION;
                } else if (eventNameLower.contains("content_view")) {
                    fbEventName = EVENT_NAME_VIEWED_CONTENT;
                } else if (eventNameLower.contains("search")) {
                    fbEventName = EVENT_NAME_SEARCHED;
                } else if (eventNameLower.contains("rated")) {
                    fbEventName = EVENT_NAME_RATED;
                    try {
                        valueToSum = event.getRating();
                    } catch (Exception e) {
                    }
                } else if (eventNameLower.contains("tutorial_complete")) {
                    fbEventName = EVENT_NAME_COMPLETED_TUTORIAL;
                } else if (eventNameLower.contains("add_to_cart")) {
                    fbEventName = EVENT_NAME_ADDED_TO_CART;
                } else if (eventNameLower.contains("add_to_wishlist")) {
                    fbEventName = EVENT_NAME_ADDED_TO_WISHLIST;
                } else if (eventNameLower.contains("checkout_initiated")) {
                    fbEventName = EVENT_NAME_INITIATED_CHECKOUT;
                } else if (eventNameLower.contains("added_payment_info")) {
                    fbEventName = EVENT_NAME_ADDED_PAYMENT_INFO;
                } else if (eventNameLower.contains("purchase")) {
                    fbEventName = EVENT_NAME_PURCHASED;
                } else if (eventNameLower.contains("level_achieved")) {
                    fbEventName = EVENT_NAME_ACHIEVED_LEVEL;
                } else if (eventNameLower.contains("achievement_unlocked")) {
                    fbEventName = EVENT_NAME_UNLOCKED_ACHIEVEMENT;
                } else if (eventNameLower.contains("spent_credits")) {
                    fbEventName = EVENT_NAME_SPENT_CREDITS;
                    try {
                        valueToSum = event.getQuantity();
                    } catch (Exception e) {
                    }
                }
                
                // Construct Bundle of FB params from TUNE params
                Bundle bundle = new Bundle();
                addBundleValue(bundle, EVENT_PARAM_CURRENCY, event.getCurrencyCode());
                addBundleValue(bundle, EVENT_PARAM_CONTENT_ID, event.getContentId());
                addBundleValue(bundle, EVENT_PARAM_CONTENT_TYPE, event.getContentType());
                addBundleValue(bundle, EVENT_PARAM_SEARCH_STRING, event.getSearchString());
                addBundleValue(bundle, EVENT_PARAM_NUM_ITEMS, Integer.toString(event.getQuantity()));
                addBundleValue(bundle, EVENT_PARAM_LEVEL, Integer.toString(event.getLevel()));
                addBundleValue(bundle, "tune_referral_source", params.getReferralSource());
                addBundleValue(bundle, "tune_source_sdk", "TUNE-MAT");
                
                Object[] args = new Object[3];
                args[0] = fbEventName;
                args[1] = valueToSum;
                args[2] = bundle;
                method.invoke(logger, args);
                
                justActivated = false;
            } catch (Exception e) {
                TuneDebugLog.d("logEvent() exception", e);
            }
        }
    }
    
    private static void addBundleValue(Bundle bundle, String key, String value) {
        if (value != null) {
            bundle.putString(key, value);
        }
    }
}
