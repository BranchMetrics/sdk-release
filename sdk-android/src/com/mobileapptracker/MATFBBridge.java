package com.mobileapptracker;

import java.lang.reflect.Method;

import android.content.Context;
import android.os.Bundle;

class MATFBBridge {
    /** From FB SDK's AppEventsConstants.java */
    
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
     * The {@link AppEventsLogger#logPurchase(java.math.BigDecimal, java.util.Currency)} method is a shortcut for
     * logging this event.
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
     * See ISO-4217 for specific values.  One reference for these is <http://en.wikipedia.org/wiki/ISO_4217>.
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

    /**
     * Parameter key used to specify source application package
     */
    public static final String EVENT_PARAM_SOURCE_APPLICATION = "fb_mobile_launch_source";
    
    private static Object logger;
    private static boolean justActivated = false;
    
    public static void startLogger(Context context) {
        try {
            Class<?>[] methodParams = new Class[1];
            methodParams[0] = Context.class;
            
            // Call the FB AppEventsLogger's activateApp method with Context
            Method method = Class.forName("com.facebook.AppEventsLogger").getMethod("activateApp", methodParams);
            Object[] args = new Object[1];
            args[0] = context;
            method.invoke(null, args);
            
            justActivated = true;
            
            // Call the AppEventsLogger's newLogger method with same Context
            method = Class.forName("com.facebook.AppEventsLogger").getMethod("newLogger", methodParams);
            logger = method.invoke(null, args);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    // Sends event to FB SDK's logEvent
    public static void logEvent(String eventName, double revenue, String currency, String refId) {
        if (logger != null) {
            try {
                Class<?>[] methodParams = new Class[3];
                methodParams[0] = String.class;
                methodParams[1] = double.class;
                methodParams[2] = Bundle.class;
                
                Method method = logger.getClass().getMethod("logEvent", methodParams);
                
                /**
                 *  Try to map the event name to a FB event name
                 *  Based on recommended event names from
                 *  https://developers.mobileapptracking.com/app-events-sdk/
                 */
                String fbEventName = eventName;
                double valueToSum = revenue;
                Parameters matParams = Parameters.getInstance();
                
                String eventNameLower = eventName.toLowerCase();
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
                        valueToSum = Double.parseDouble(matParams.getEventRating());
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
                        valueToSum = Double.parseDouble(matParams.getEventQuantity());
                    } catch (Exception e) {
                    }
                }
                
                // Construct Bundle of FB params from MAT params
                Bundle bundle = new Bundle();
                addBundleValue(bundle, EVENT_PARAM_CURRENCY, currency);
                addBundleValue(bundle, EVENT_PARAM_CONTENT_ID, matParams.getEventContentId());
                addBundleValue(bundle, EVENT_PARAM_CONTENT_TYPE, matParams.getEventContentType());
                addBundleValue(bundle, EVENT_PARAM_SEARCH_STRING, matParams.getEventSearchString());
                addBundleValue(bundle, EVENT_PARAM_NUM_ITEMS, matParams.getEventQuantity());
                addBundleValue(bundle, EVENT_PARAM_LEVEL, matParams.getEventLevel());
                addBundleValue(bundle, EVENT_PARAM_SOURCE_APPLICATION, matParams.getReferralSource());
                
                Object[] args = new Object[3];
                args[0] = fbEventName;
                args[1] = valueToSum;
                args[2] = bundle;
                method.invoke(logger, args);
                
                justActivated = false;
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
    
    private static void addBundleValue(Bundle bundle, String key, String value) {
        if (value != null) {
            bundle.putString(key, value);
        }
    }
}
