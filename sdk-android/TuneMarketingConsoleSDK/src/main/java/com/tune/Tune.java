package com.tune;

import android.content.Context;

/**
 * Public Factory to the Tune SDK.
 *
 * To create an instance of the Tune singleton, use the appropriate init methods.
 *
 * At any time after initialization, the {@link ITune} interface can be retrieved
 * by calling the static method {@link Tune#getInstance()}
 */
public class Tune {
    /**
     * Initializes the TUNE SDK.
     * @param context Application context
     * @param advertiserId TUNE advertiser ID
     * @param conversionKey TUNE conversion key
     * @return Tune instance with initialized values
     */
    public static synchronized ITune init(Context context, String advertiserId, String conversionKey) {
        return init(context, advertiserId, conversionKey, null);
    }

    /**
     * Initializes the TUNE SDK.
     * @param context Application context
     * @param advertiserId TUNE advertiser ID
     * @param conversionKey TUNE conversion key
     * @param packageName Package Name (or null to use the Application package name)
     * @return Tune instance with initialized values
     */
    public static synchronized ITune init(Context context, String advertiserId, String conversionKey, String packageName) {
        if (getInstance() == null) {
            TuneInternal.initAll(context, advertiserId, conversionKey, packageName);
        }

        return getInstance();
    }

    /**
     * Get existing TUNE singleton interface object
     * @return Tune instance
     */
    public static synchronized ITune getInstance() {
        return TuneInternal.getInstance();
    }

    /**
     * Gets the TUNE Android SDK version
     * @return TUNE Android SDK version
     */
    public static String getSDKVersion() {
        return BuildConfig.VERSION_NAME;
    }

    /**
     * Turns debug mode on or off, under tag "TUNE", with a log listener.
     * @param debug whether to enable debug output
     */
    public static void setDebugMode(boolean debug) {
        TuneInternal.setDebugMode(debug);
    }

    /**
     * Noninstantiable Tune class.
     */
    private Tune() {
        throw new AssertionError("This class cannot be instantiated");
    }
}
