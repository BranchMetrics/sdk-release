package com.tune.smartwhere;

import android.content.Context;

import com.tune.BuildConfig;
import com.tune.Tune;
import com.tune.TuneEvent;
import com.tune.TuneUtils;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;

import java.lang.reflect.Method;
import java.util.ArrayList;
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
    protected static volatile TuneSmartWhere instance = null;

    static final String TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX = "T_A_V_";
    static final String TUNE_SDK_VERSION_TRACKING_KEY = "TUNE_SDK_VERSION";
    static final String TUNE_MAT_ID_TRACKING_KEY = "TUNE_MAT_ID";

    static final String TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_PROXIMITYCONTROL = "com.proximity.library.ProximityControl";
    static final String TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_ATTRIBUTE = "com.proximity.library.Attribute";
    static final String TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_TRACKING_ATTRIBUTE = "com.proximity.library.TrackingAttribute";
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
    private static final String TUNE_SMARTWHERE_ATTRIBUTE_METHOD_SET_ATTRIBUTE_VALUE = "setAttributeValue";
    private static final String TUNE_SMARTWHERE_ATTRIBUTE_METHOD_REMOVE_ATTRIBUTE_VALUE = "removeAttributeValue";
    private static final String TUNE_SMARTWHERE_ATTRIBUTE_METHOD_GET_ATTRIBUTE_MAP = "getAttributes";
    private static final String TUNE_SMARTWHERE_ATTRIBUTE_METHOD_GET_INSTANCE = "getInstance";

    private TuneSmartwhereConfiguration mConfiguration;

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
            mConfiguration = new TuneSmartwhereConfiguration();
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
        return (mConfiguration != null);
    }

    /**
     * Get the current {@link TuneSmartwhereConfiguration}.
     * @return the current {@link TuneSmartwhereConfiguration}.
     * To make changes to the Smartwhere options, use {@link TuneSmartWhere#configure(TuneSmartwhereConfiguration)}
     */
    public TuneSmartwhereConfiguration getConfiguration() {
        return (mConfiguration == null ? new TuneSmartwhereConfiguration() : mConfiguration);
    }


    public void configure(TuneSmartwhereConfiguration configuration) {
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
    void startMonitoring(Context context, String tuneAdvertiserId, String tuneConversionKey, boolean debugMode) {
        Class targetClass = classForName(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_PROXIMITYCONTROL);
        if (targetClass != null) {

            setTrackingAttributeValue(context, TUNE_SDK_VERSION_TRACKING_KEY, BuildConfig.VERSION_NAME);
            setTrackingAttributeValue(context, TUNE_MAT_ID_TRACKING_KEY, Tune.getInstance().getMatId());

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
     * @param context Application Context
     */
    void stopMonitoring(Context context) {
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
                TuneUtils.log("TuneSmartWhere.processMappedEvent: " + e.getLocalizedMessage());
            }
        }
    }

    /**
     * Add user attributes that are used for conditions and notification replacements from TuneAnalyticsVariable.
     * @param context Application Context
     * @param analyticsVariable TuneAnalyticsVariable
     */
    public void setAttributeValueFromAnalyticsVariable(Context context, TuneAnalyticsVariable analyticsVariable) {
        Class<?> targetClass = classForName(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_ATTRIBUTE);
        if (targetClass == null) return;

        try {
            Method getInstance = targetClass.getMethod(TUNE_SMARTWHERE_ATTRIBUTE_METHOD_GET_INSTANCE, Context.class);
            Object instanceOfAttributeClass = getInstance.invoke(targetClass,context);
            Method setAttributeValue = targetClass.getMethod(TUNE_SMARTWHERE_ATTRIBUTE_METHOD_SET_ATTRIBUTE_VALUE, String.class, String.class);
            Method removeAttributeValue = targetClass.getMethod(TUNE_SMARTWHERE_ATTRIBUTE_METHOD_REMOVE_ATTRIBUTE_VALUE, String.class);
            String name = analyticsVariable.getName();
            String value = analyticsVariable.getValue();
            if (name != null && name.length() > 0){
                if ( value != null){
                    String finalName = TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + name;
                    setAttributeValue.invoke(instanceOfAttributeClass, finalName, value);
                } else {
                    String finalName = TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + name;
                    removeAttributeValue.invoke(instanceOfAttributeClass, finalName);

                }
            }
        } catch (Exception e) {
            TuneUtils.log("TuneSmartWhere.setAttributeValueFromAnalyticsVariable: " + e.getLocalizedMessage());
        }
    }

    /**
     * Add user attributes that are used for conditions and notification replacements from TuneEvent tags.
     * @param context Application Context
     * @param event TuneEvent
     */
    public void setAttributeValuesFromEventTags(Context context, TuneEvent event) {
        Class<?> targetClass = classForName(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_ATTRIBUTE);
        if (targetClass == null) return;

        for (TuneAnalyticsVariable tag : event.getTags()) {
            setAttributeValueFromAnalyticsVariable(context, tag);
        }
    }

    /**
     * Remove an attribute by name
     * @param context Application Context
     * @param variableName String
     */
    public void clearAttributeValue(Context context, String variableName) {
        Class<?> targetClass = classForName(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_ATTRIBUTE);
        if (targetClass == null) return;

        try {
            Method getInstance = targetClass.getMethod(TUNE_SMARTWHERE_ATTRIBUTE_METHOD_GET_INSTANCE, Context.class);
            Object instanceOfAttributeClass = getInstance.invoke(targetClass,context);
            Method removeAttributeValue = targetClass.getMethod(TUNE_SMARTWHERE_ATTRIBUTE_METHOD_REMOVE_ATTRIBUTE_VALUE, String.class);

            String finalName = TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + variableName;
            removeAttributeValue.invoke(instanceOfAttributeClass, finalName);
        } catch (Exception e) {
            TuneUtils.log("TuneSmartWhere.clearAttributeValue: " + e.getLocalizedMessage());
        }
    }

    /**
     * Remove all attributes
     * @param context Application Context
     */
    public void clearAllAttributeValues(Context context) {
        Class<?> targetClass = classForName(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_ATTRIBUTE);
        if (targetClass == null) return;

        try {
            Method getInstance = targetClass.getMethod(TUNE_SMARTWHERE_ATTRIBUTE_METHOD_GET_INSTANCE, Context.class);
            Object instanceOfAttributeClass = getInstance.invoke(targetClass,context);
            Method removeAttributeValue = targetClass.getMethod(TUNE_SMARTWHERE_ATTRIBUTE_METHOD_REMOVE_ATTRIBUTE_VALUE, String.class);
            Method getAttributeMap = targetClass.getMethod(TUNE_SMARTWHERE_ATTRIBUTE_METHOD_GET_ATTRIBUTE_MAP);
            Object attributes = getAttributeMap.invoke(instanceOfAttributeClass);

            ArrayList<String> keysToRemove = new ArrayList<>();
            //noinspection unchecked
            for (String name : ((HashMap<String, String>) attributes).keySet()) {
                if (name.startsWith(TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX)) {
                    keysToRemove.add(name);
                }
            }
            for (String name : keysToRemove) {
                removeAttributeValue.invoke(instanceOfAttributeClass, name);
            }
        } catch (Exception e) {
            TuneUtils.log("TuneSmartWhere.clearAllAttributeValues: " + e.getLocalizedMessage());
        }
    }

    /**
     * Add attribute to be sent as metadata with tracking.
     * @param context Application Context
     * @param name String value of the attribute name
     * @param value String value of the attribute value
     */
    void setTrackingAttributeValue(Context context, String name, String value) {
        Class<?> targetClass = classForName(TUNE_SMARTWHERE_COM_PROXIMITY_LIBRARY_TRACKING_ATTRIBUTE);
        if (targetClass == null) return;

        try {
            Method getInstance = targetClass.getMethod(TUNE_SMARTWHERE_ATTRIBUTE_METHOD_GET_INSTANCE, Context.class);
            Object instanceOfAttributeClass = getInstance.invoke(targetClass,context);
            Method setAttributeValue = targetClass.getMethod(TUNE_SMARTWHERE_ATTRIBUTE_METHOD_SET_ATTRIBUTE_VALUE, String.class, String.class);
            Method removeAttributeValue = targetClass.getMethod(TUNE_SMARTWHERE_ATTRIBUTE_METHOD_REMOVE_ATTRIBUTE_VALUE, String.class);

            if (name != null && name.length() > 0){
                if ( value != null){
                    String finalName = TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + name;
                    setAttributeValue.invoke(instanceOfAttributeClass, finalName, value);
                } else {
                    String finalName = TUNE_SMARTWHERE_ANALYTICS_VARIABLE_ATTRIBUTE_PREFIX + name;
                    removeAttributeValue.invoke(instanceOfAttributeClass, finalName);

                }
            }
        } catch (Exception e) {
            TuneUtils.log("TuneSmartWhere.setTrackingAttributeValue: " + e.getLocalizedMessage());
        }
    }

    static synchronized void setInstance(TuneSmartWhere tuneProximity) {
        instance = tuneProximity;
    }

    // Required for SmartWhere Unit Tests
    @SuppressWarnings("WeakerAccess")
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