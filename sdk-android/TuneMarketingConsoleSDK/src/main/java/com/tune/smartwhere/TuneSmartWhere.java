package com.tune.smartwhere;

import android.content.Context;

import com.tune.Tune;
import com.tune.TuneDebugLog;
import com.tune.TuneEvent;

import java.lang.reflect.Method;
import java.util.HashMap;

import static com.tune.TuneConstants.STRING_FALSE;
import static com.tune.TuneConstants.STRING_TRUE;
import static com.tune.TuneEvent.NAME_SESSION;

/**
 * TUNE-SmartWhere bridge class. Provides methods to start and stop SmartWhere proximity monitoring.
 *
 * Created by gordonstewart on 8/17/16.
 *
 * @author gordon@smartwhere.com
 */

public class TuneSmartWhere {
    private static volatile TuneSmartWhere instance = null;

    private static final String TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_PROXIMITYCONTROL = "com.proximity.library.ProximityControl";
    private static final String TUNE_SMARTWHERE_NOTIFICATION_SERVICE = "com.tune.smartwhere.TuneSmartWhereNotificationService";

    private static final String TUNE_SMARTWHERE_API_KEY = "API_KEY";
    private static final String TUNE_SMARTWHERE_API_SECRET = "API_SECRET";
    private static final String TUNE_SMARTWHERE_APPLICATION_ID = "APPLICATION_ID";
    private static final String TUNE_SMARTWHERE_SERVICE_AUTO_START = "SERVICE_AUTO_START";
    private static final String TUNE_SMARTWHERE_ENABLE_GEOFENCE_RANGING = "ENABLE_GEOFENCE_RANGING";
    private static final String TUNE_SMARTWHERE_PROMPT_FOR_LOCATION_PERMISSION = "PROMPT_FOR_LOCATION_PERMISSION";
    private static final String TUNE_SMARTWHERE_NOTIFICATION_HANDLER_SERVICE = "NOTIFICATION_HANDLER_SERVICE";
    private static final String TUNE_SMARTWHERE_DEBUG_LOG = "DEBUG_LOG";
    private static final String TUNE_SMARTWHERE_PACKAGE_NAME = "PACKAGE_NAME";

    private static final String TUNE_SMARTWHERE_METHOD_CONFIGURE_SERVICE = "configureService";
    private static final String TUNE_SMARTWHERE_METHOD_START_SERVICE = "startService";
    private static final String TUNE_SMARTWHERE_METHOD_STOP_SERVICE = "stopService";
    private static final String TUNE_SMARTWHERE_METHOD_PROCESS_MAPPED_EVENT = "processMappedEvent";

    private TuneSmartWhereConfiguration mConfiguration;

    TuneSmartWhere() {
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
    public static boolean isSmartWhereAvailable() {
        return getInstance().isSmartWhereAvailableInternal();
    }

    /**
     * Enable Smartwhere.
     * @param context Application Context
     */
    public void enable(Context context) {
        if (!isEnabled()) {
            mConfiguration = new TuneSmartWhereConfiguration();
            startSmartWhereLocationMonitoring(context);
        }
    }

    /**
     * Disable Smartwhere.
     * @param context Application Context
     */
    public void disable(Context context) {
        if (isEnabled()) {
            mConfiguration = null;
            stopSmartWhereLocationMonitoring(context);
        }
    }

    /**
     * @return True if Smartwhere is enabled.
     */
    public boolean isEnabled() {
        boolean test = (mConfiguration != null);
        return (mConfiguration != null);
    }

    /**
     * Get the current {@link TuneSmartWhereConfiguration}.
     * @return the current {@link TuneSmartWhereConfiguration}.
     * To make changes to the Smartwhere options, use {@link TuneSmartWhere#configure(TuneSmartWhereConfiguration)}
     */
    public final TuneSmartWhereConfiguration getConfiguration() {
        return (mConfiguration == null ? new TuneSmartWhereConfiguration() : mConfiguration);
    }


    public void configure(TuneSmartWhereConfiguration configuration) {
        if (configuration == null) {
            return;
        }

        mConfiguration = configuration;
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
                TuneDebugLog.d("TuneSmartWhere.startMonitoring", e);
            }
        }
    }

    /**
     * Stops SmartWhere proximity monitoring.
     * @param context Application Context
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
                TuneDebugLog.d("TuneSmartWhere.stopMonitoring", e);
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
                TuneDebugLog.d("TuneSmartWhere.setDebugMode", e);
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
                TuneDebugLog.d("TuneSmartWhere.setPackageName", e);
            }
        }
    }

    /**
     * Processes events that are mapped on the server.
     * @param context Application Context
     * @param event TuneEventOccurred.
     */
    public void processMappedEvent(Context context, TuneEvent event) {
        Class targetClass = classForName(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_PROXIMITYCONTROL);
        if (targetClass != null) {
            try {
                @SuppressWarnings("unchecked")
                Method processMappedEvent = targetClass.getMethod(TUNE_SMARTWHERE_METHOD_PROCESS_MAPPED_EVENT, Context.class, String.class);
                String eventName = event.getEventName();
                if (eventName != null && !(eventName.equals(NAME_SESSION))) {
                    processMappedEvent.invoke(targetClass, context, eventName);
                }
            } catch (Exception e) {
                TuneDebugLog.d("TuneSmartWhere.processMappedEvent", e);
            }
        }
    }

    static synchronized void setInstance(TuneSmartWhere tuneProximity) {
        instance = tuneProximity;
    }

    // Required for SmartWhere Unit Tests
    protected boolean isSmartWhereAvailableInternal() {
        return classForName(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_PROXIMITYCONTROL) != null;
    }

    // Required for SmartWhere Unit Tests
    protected Class classForName(String name) {
        try {
            return Class.forName(name);
        } catch (ClassNotFoundException e) {
            return null;
        }
    }

    private void startSmartWhereLocationMonitoring(Context context) {
        if (isSmartWhereAvailable()) {
            startMonitoring(context, Tune.getInstance().getTuneParams().getAdvertiserId(), Tune.getInstance().getTuneParams().getConversionKey(), Tune.getInstance().isInDebugMode());
        }
    }

    private void stopSmartWhereLocationMonitoring(Context context) {
        if (isSmartWhereAvailable()) {
            stopMonitoring(context);
        }
    }


}