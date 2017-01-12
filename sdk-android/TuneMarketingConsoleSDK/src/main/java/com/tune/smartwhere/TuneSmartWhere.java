package com.tune.smartwhere;

import android.content.Context;

import com.tune.TuneUtils;

import java.lang.reflect.Method;
import java.util.HashMap;

import static com.tune.TuneConstants.STRING_FALSE;
import static com.tune.TuneConstants.STRING_TRUE;

/**
 * TUNE-SmartWhere bridge class. Provides methods to start and stop SmartWhere proximity monitoring.
 *
 * Created by gordonstewart on 8/17/16.
 *
 * @author gordon@smartwhere.com
 */

public class TuneSmartWhere {
    private static volatile TuneSmartWhere instance = null;

    public static final String TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_PROXIMITYCONTROL = "com.proximity.library.ProximityControl";
    public static final String TUNE_SMARTWHERE_NOTIFICATION_SERVICE = "com.tune.smartwhere.TuneSmartWhereNotificationService";

    public static final String TUNE_SMARTWHERE_API_KEY = "API_KEY";
    public static final String TUNE_SMARTWHERE_API_SECRET = "API_SECRET";
    public static final String TUNE_SMARTWHERE_APPLICATION_ID = "APPLICATION_ID";
    public static final String TUNE_SMARTWHERE_SERVICE_AUTO_START = "SERVICE_AUTO_START";
    public static final String TUNE_SMARTWHERE_ENABLE_GEOFENCE_RANGING = "ENABLE_GEOFENCE_RANGING";
    public static final String TUNE_SMARTWHERE_PROMPT_FOR_LOCATION_PERMISSION = "PROMPT_FOR_LOCATION_PERMISSION";
    public static final String TUNE_SMARTWHERE_NOTIFICATION_HANDLER_SERVICE = "NOTIFICATION_HANDLER_SERVICE";
    public static final String TUNE_SMARTWHERE_DEBUG_LOG = "DEBUG_LOG";
    public static final String TUNE_SMARTWHERE_PACKAGE_NAME = "PACKAGE_NAME";

    public static final String TUNE_SMARTWHERE_METHOD_CONFIGURE_SERVICE = "configureService";
    public static final String TUNE_SMARTWHERE_METHOD_START_SERVICE = "startService";
    public static final String TUNE_SMARTWHERE_METHOD_STOP_SERVICE = "stopService";

    protected TuneSmartWhere() {
    }

    /**
     * Gets the shared instance of this class.
     * @return shared instance of this class
     */
    public static synchronized TuneSmartWhere getInstance() {
        if (instance == null) {
            instance = new TuneSmartWhere();
        }
        return instance;
    }

    /**
     * Checks if SmartWhere ProximityControl class is available.
     * @return true if ProximityControl class is available, false otherwise
     */
    public boolean isSmartWhereAvailable() {
        return classForName(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_PROXIMITYCONTROL) != null;
    }

    /**
     * Starts SmartWhere proximity monitoring when SmartWhere ProximityControl class is available.
     *
     * @param context Application Context
     * @param tuneAdvertiserId TUNE Advertiser ID
     * @param tuneConversionKey TUNE Conversion Key
     * @param debugMode Debug Mode
     */
    public void startMonitoring(Context context, String tuneAdvertiserId, String tuneConversionKey, boolean debugMode) {
        Class targetClass = classForName(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_PROXIMITYCONTROL);
        if (targetClass != null) {
            HashMap<String, String> config = new HashMap<>();

            config.put(TUNE_SMARTWHERE_API_KEY, tuneAdvertiserId);
            config.put(TUNE_SMARTWHERE_API_SECRET, tuneConversionKey);
            config.put(TUNE_SMARTWHERE_APPLICATION_ID, tuneAdvertiserId);
            config.put(TUNE_SMARTWHERE_SERVICE_AUTO_START, STRING_TRUE);
            config.put(TUNE_SMARTWHERE_ENABLE_GEOFENCE_RANGING, STRING_TRUE);
            config.put(TUNE_SMARTWHERE_PROMPT_FOR_LOCATION_PERMISSION, STRING_FALSE);
            config.put(TUNE_SMARTWHERE_NOTIFICATION_HANDLER_SERVICE, TUNE_SMARTWHERE_NOTIFICATION_SERVICE);

            if (debugMode) {
                config.put(TUNE_SMARTWHERE_DEBUG_LOG, STRING_TRUE);
            }

            try {
                @SuppressWarnings("unchecked")
                Method configureService = targetClass.getMethod(TUNE_SMARTWHERE_METHOD_CONFIGURE_SERVICE, Context.class, HashMap.class);
                configureService.invoke(targetClass, context, config);

                @SuppressWarnings("unchecked")
                Method startService = targetClass.getMethod(TUNE_SMARTWHERE_METHOD_START_SERVICE, Context.class);
                startService.invoke(targetClass, context);
            } catch (Exception e) {
                TuneUtils.log("TuneSmartWhere.startMonitoring: " + e.getLocalizedMessage());
            }
        }
    }

    /**
     * Stops SmartWhere proximity monitoring.
     */
    public void stopMonitoring(Context context) {
        Class targetClass = classForName(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_PROXIMITYCONTROL);
        if (targetClass != null) {
            HashMap<String, String> config = new HashMap<>();

            config.put(TUNE_SMARTWHERE_SERVICE_AUTO_START, STRING_FALSE);

            try {
                @SuppressWarnings("unchecked")
                Method configureService = targetClass.getMethod(TUNE_SMARTWHERE_METHOD_CONFIGURE_SERVICE, Context.class, HashMap.class);
                configureService.invoke(targetClass, context, config);

                @SuppressWarnings("unchecked")
                Method stopService = targetClass.getMethod(TUNE_SMARTWHERE_METHOD_STOP_SERVICE, Context.class);
                stopService.invoke(targetClass, context);
            } catch (Exception e) {
                TuneUtils.log("TuneSmartWhere.stopMonitoring: " + e.getLocalizedMessage());
            }
        }
    }

    /**
     * Sets the SmartWhere debug mode.
     * @param context Application Context
     * @param mode boolean value for debug mode, defaults to false.
     */
    public void setDebugMode(Context context, final boolean mode) {
        Class targetClass = classForName(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_PROXIMITYCONTROL);
        if (targetClass != null) {
            HashMap<String, String> config = new HashMap<String, String>() {{
                put(TUNE_SMARTWHERE_DEBUG_LOG, (mode) ? STRING_TRUE : STRING_FALSE);
            }};
            try {
                @SuppressWarnings("unchecked")
                Method configureService = targetClass.getMethod(TUNE_SMARTWHERE_METHOD_CONFIGURE_SERVICE, Context.class, HashMap.class);
                configureService.invoke(targetClass, context, config);
            } catch (Exception e) {
                TuneUtils.log("TuneSmartWhere.setDebugMode: " + e.getLocalizedMessage());
            }
        }
    }

    /**
     * Sets the SmartWhere Application ID and API Key.
     * @param context Application Context
     * @param packageName TUNE package name
     */
    public void setPackageName(Context context, final String packageName) {
        Class targetClass = classForName(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_PROXIMITYCONTROL);
        if (targetClass != null) {
            HashMap<String, String> config = new HashMap<String, String>() {{
                put(TUNE_SMARTWHERE_PACKAGE_NAME, packageName);
            }};
            try {
                @SuppressWarnings("unchecked")
                Method configureService = targetClass.getMethod(TUNE_SMARTWHERE_METHOD_CONFIGURE_SERVICE, Context.class, HashMap.class);
                configureService.invoke(targetClass, context, config);
            } catch (Exception e) {
                TuneUtils.log("TuneSmartWhere.setPackageName: " + e.getLocalizedMessage());
            }
        }
    }

    protected static synchronized void setInstance(TuneSmartWhere tuneProximity) {
        instance = tuneProximity;
    }

    protected Class classForName(String name) {
        try {
            return Class.forName(name);
        } catch (ClassNotFoundException e) {
            return null;
        }
    }
}
