package com.tune;

import android.Manifest;
import android.accounts.Account;
import android.accounts.AccountManager;
import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.location.Location;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;
import android.util.Log;
import android.util.Patterns;
import android.widget.Toast;

import com.tune.http.TuneUrlRequester;
import com.tune.http.UrlRequester;
import com.tune.location.TuneLocationListener;
import com.tune.ma.TuneManager;
import com.tune.ma.analytics.model.TuneAnalyticsVariable;
import com.tune.ma.analytics.model.TuneVariableType;
import com.tune.ma.configuration.TuneConfiguration;
import com.tune.ma.eventbus.TuneEventBus;
import com.tune.ma.eventbus.event.TuneEventOccurred;
import com.tune.ma.eventbus.event.userprofile.TuneUpdateUserProfile;
import com.tune.ma.experiments.model.TuneInAppMessageExperimentDetails;
import com.tune.ma.experiments.model.TunePowerHookExperimentDetails;
import com.tune.ma.model.TuneCallback;
import com.tune.ma.model.TuneDeepActionCallback;
import com.tune.ma.push.TunePushInfo;
import com.tune.ma.push.settings.TuneNotificationBuilder;
import com.tune.ma.utils.TuneDebugLog;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * @author tony@hasoffers.com
 * @author john.gu@hasoffers.com
 */
public class Tune {
    private final String IV = "heF9BATUfWuISyO8";

    /* Protected fields needed for unit tests */
    // Connectivity receiver
    protected BroadcastReceiver networkStateReceiver;
    // The context passed into the constructor
    protected Context mContext;
    // Thread pool for public method execution
    protected ExecutorService pubQueue;
    // Queue interface object for storing events that were not fired
    protected TuneEventQueue eventQueue;
    // Location listener
    protected TuneLocationListener locationListener;
    // Parameters container
    protected TuneParameters params;
    // Interface for testing URL requests
    protected TuneTestRequest tuneRequest; // note: this has no setter - must subclass to set

    // Whether variables were initialized correctly
    protected boolean initialized;
    // Whether connectivity receiver is registered or not
    protected boolean isRegistered;
    // Whether to collect location or not
    protected boolean collectLocation;

    // Deferred deeplink helper class
    private TuneDeferredDplinkr dplinkr;
    // Preloaded apps data values to send
    private TunePreloadData mPreloadData;

    // Interface for making url requests
    private UrlRequester urlRequester;
    // Encryptor for url
    private TuneEncryption encryption;
    // Interface for reading platform response to tracking calls
    private TuneListener tuneListener;

    // Whether to show debug output
    private boolean debugMode;
    // If this is the first session of the app lifecycle, wait for the GAID and referrer
    private boolean firstSession;
    // Whether we're invoking FB event logging
    private boolean fbLogging;
    // Time that SDK was initialized
    private long initTime;
    // Time that SDK received referrer
    private long referrerTime;

    // Whether Google Advertising ID was received
    boolean gotGaid;
    // Whether INSTALL_REFERRER was received
    boolean gotReferrer;
    // Whether we've already notified the pool to stop waiting
    boolean notifiedPool;
    // Thread pool for running the request Runnables
    ExecutorService pool;

    private static volatile Tune tune = null;

    protected Tune() {
    }

    /**
     * Get existing TUNE singleton object
     * @return Tune instance
     */
    public static synchronized Tune getInstance() {
        return tune;
    }

    /**
     * Initializes the TUNE SDK with TMA off by default.
     * @param context Application context
     * @param advertiserId TUNE advertiser ID
     * @param conversionKey TUNE conversion key
     * @return Tune instance with initialized values
     */
    public static synchronized Tune init(Context context, String advertiserId, String conversionKey) {
        return init(context, advertiserId, conversionKey, false);
    }

    /**
     * Initializes the TUNE SDK.
     * @param context Application context
     * @param advertiserId TUNE advertiser ID
     * @param conversionKey TUNE conversion key
     * @param turnOnTMA Whether to enable TMA or not
     * @return Tune instance with initialized values
     */
    public static synchronized Tune init(Context context, String advertiserId, String conversionKey, boolean turnOnTMA) {
        return init(context, advertiserId, conversionKey, turnOnTMA, null);
    }

    /**
     * Initializes the TUNE SDK.
     * @param context Application context
     * @param advertiserId TUNE advertiser ID
     * @param conversionKey TUNE conversion key
     * @param turnOnTMA Whether to enable TMA or not
     * @param configuration custom SDK configuration
     * @return Tune instance with initialized values
     */
    public static synchronized Tune init(Context context, String advertiserId, String conversionKey, boolean turnOnTMA, TuneConfiguration configuration) {
        if (tune == null) {
            tune = new Tune();
            tune.mContext = context.getApplicationContext();
            tune.pubQueue = Executors.newSingleThreadExecutor();

            if (turnOnTMA && TuneUtils.hasPermission(context, Manifest.permission.INTERNET)) {
                // Enable the event bus
                TuneEventBus.enable();
                // Init TuneManager
                TuneManager.init(context.getApplicationContext(), configuration);
            } else {
                // Disable the event bus if TMA is not on
                TuneEventBus.disable();
            }

            tune.initAll(advertiserId, conversionKey);

            // Location listener init
            tune.locationListener = new TuneLocationListener(context);
            // Check configuration for whether to collect location or not
            if (configuration != null) {
                tune.collectLocation = configuration.shouldAutoCollectDeviceLocation();
                if (tune.collectLocation) {
                    // Get initial location
                    tune.locationListener.startListening();
                }
            }
        }
        return tune;
    }

    static void setInstance(Tune newTune) {
        tune = newTune;
    }

    /**
     * Clear Tune singleton so it may be re-initialized.
     */
    static synchronized void clear() {
        tune = null;
    }

    /**
     * Private initialization function for TUNE SDK.
     * @param advertiserId the TUNE advertiser ID for the app
     * @param conversionKey the TUNE conversion key for the app
     */
    protected void initAll(String advertiserId, String conversionKey) {
        // Dplinkr init
        dplinkr = TuneDeferredDplinkr.initialize(advertiserId, conversionKey, mContext.getPackageName());

        params = TuneParameters.init(this, mContext, advertiserId, conversionKey);

        initLocalVariables(conversionKey);

        eventQueue = new TuneEventQueue(mContext, this);
        // Dump any existing requests in queue on start
        dumpQueue();

        // Set up connectivity listener so we dump the queue when re-connected to Internet
        networkStateReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if (isRegistered) {
                    dumpQueue();
                }
            }
        };

        if (isRegistered) {
            // Unregister receiver in case one is still previously registered
            try {
                mContext.unregisterReceiver(networkStateReceiver);
            } catch (java.lang.IllegalArgumentException e) {
            }
            isRegistered = false;
        }

        IntentFilter filter = new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION);
        mContext.registerReceiver(networkStateReceiver, filter);
        isRegistered = true;

        initialized = true;
    }

    /**
     * Initialize class variables
     * @param key the conversion key
     */
    private void initLocalVariables(String key) {
        pool = Executors.newSingleThreadExecutor();
        urlRequester = new TuneUrlRequester();
        encryption = new TuneEncryption(key.trim(), IV);

        initTime = System.currentTimeMillis();
        gotReferrer = !(mContext.getSharedPreferences(TuneConstants.PREFS_TUNE, Context.MODE_PRIVATE).getString(TuneConstants.KEY_REFERRER, "").equals(""));
        firstSession = true;
        initialized = false;
        isRegistered = false;
        debugMode = false;
        fbLogging = false;
        collectLocation = true;
    }

    /**
     * Returns true if an Internet connection is detected.
     * @param context the app context to check connectivity from
     * @return whether Internet connection exists
     */
    public static synchronized boolean isOnline(Context context) {
        ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
        return activeNetworkInfo != null && activeNetworkInfo.isConnected();
    }

    protected void addEventToQueue(String link, String data, JSONObject postBody, boolean firstSession) {
        if (pool.isShutdown()) {
            return;
        }

        pool.execute(eventQueue.new Add(link, data, postBody, firstSession));
    }

    protected void dumpQueue() {
        if (!isOnline(mContext)) {
            return;
        }

        if (pool.isShutdown()) {
            return;
        }

        pool.execute(eventQueue.new Dump());
    }

    /**
     * Main session measurement function; this function should be called in onResume().
     */
    public void measureSession() {
        notifiedPool = false;
        measureEvent(new TuneEvent("session"));
        if (debugMode) {
            Handler handler = new Handler(Looper.getMainLooper());
            handler.post(new Runnable() {
                public void run() {
                    Toast.makeText(mContext, "TUNE measureSession called", Toast.LENGTH_LONG).show();
                }
            });
        }
    }

    /**
     * Event measurement function that measures an event for the given eventName.
     * @param eventName event name in TUNE system
     */
    public void measureEvent(String eventName) {
        measureEvent(new TuneEvent(eventName));
    }

    /**
     * Event measurement function that measures an event for the given eventId.
     * @param eventId event ID in TUNE system
     * @deprecated TUNE does not support measuring events using event IDs. Please use {@link #measureEvent(String)} or {@link #measureEvent(TuneEvent)} methods.
     */
    @Deprecated public void measureEvent(int eventId) {
        measureEvent(new TuneEvent(eventId));
    }

    /**
     * Event measurement function that measures an event based on TuneEvent values.
     * Create a TuneEvent to pass in with:</br>
     * <pre>new TuneEvent(eventName)</pre>
     * @param eventData custom data to associate with the event
     */
    public void measureEvent(final TuneEvent eventData) {
        if (TextUtils.isEmpty(eventData.getEventName()) && eventData.getEventId() == 0) {
            Log.w(TuneConstants.TAG, "Event name or ID cannot be null, empty, or zero");
            return;
        }

        // Post event to TuneEventBus for TMA
        TuneEventBus.post(new TuneEventOccurred(eventData));

        updateLocation();

        pubQueue.execute(new Runnable() {
            public void run() {
                measure(eventData);
            }
        });
    }

    private synchronized void measure(TuneEvent eventData) {
        if (!initialized) return;

        dumpQueue();

        params.setAction("conversion"); // Default to conversion
        if (eventData.getEventName() != null) {
            String eventName = eventData.getEventName();
            if (fbLogging) {
                TuneFBBridge.logEvent(eventData);
            }
            if (eventName.equals("close")) {
                return; // Don't send close events
            } else if (eventName.equals("open") || eventName.equals("install") ||
                       eventName.equals("update") || eventName.equals("session")) {
                params.setAction("session");
            }
        }

        if (eventData.getRevenue() > 0) {
            params.setIsPayingUser("1");
        }

        String link = TuneUrlBuilder.buildLink(eventData, mPreloadData, debugMode);
        String data = TuneUrlBuilder.buildDataUnencrypted(eventData);
        JSONArray eventItemsJson = new JSONArray();
        if (eventData.getEventItems() != null) {
            for (int i = 0; i < eventData.getEventItems().size(); i++) {
                eventItemsJson.put(eventData.getEventItems().get(i).toJson());
            }
        }
        JSONObject postBody = TuneUrlBuilder.buildBody(eventItemsJson, eventData.getReceiptData(), eventData.getReceiptSignature(), params.getUserEmails());

        if (tuneRequest != null) {
            tuneRequest.constructedRequest(link, data, postBody);
        }

        addEventToQueue(link, data, postBody, firstSession);
        // Mark firstSession false
        firstSession = false;
        dumpQueue();

        if (tuneListener != null) {
            tuneListener.enqueuedActionWithRefId(eventData.getRefId());
            tuneListener.enqueuedRequest(link + "&data=" + data, postBody);
        }

        return;
    }

    /**
     * Helper function for making single request and displaying response
     * @return true if request was sent successfully and should be removed from queue
     */
    protected boolean makeRequest(String link, String data, JSONObject postBody) {
        if (debugMode) TuneUtils.log("Sending event to server...");

        // If location not set before sending, try to get location again
        updateLocation();

        String encData = TuneUrlBuilder.updateAndEncryptData(data, encryption);
        String fullLink = link + "&data=" + encData;

        JSONObject response = urlRequester.requestUrl(fullLink, postBody, debugMode);

        // The only way we get null from TuneUrlRequester is if *our server* returned HTTP 400.
        // In that case, we should not retry this request.
        if (response == null) {
            if (tuneListener != null) {
                // null isn't the most useful error message, but at least it's a notification
                tuneListener.didFailWithError(response);
            }
            return true;
        }

        // if response is empty, it should be requeued
        if (!response.has("success")) {
            if (debugMode) TuneUtils.log("Request failed, event will remain in queue");
            return false;
        }

        // notify tuneListener of success or failure
        if (tuneListener != null) {
            boolean success = false;
            try {
                if (response.getString("success").equals("true")) {
                    success = true;
                }
            } catch (JSONException e) {
                e.printStackTrace();
                return false;
            }

            if (success) {
                tuneListener.didSucceedWithData(response);
            } else {
                tuneListener.didFailWithError(response);
            }
        }

        // save open log id
        try {
            String eventType = response.getString("site_event_type");
            if (eventType.equals("open")) {
                String logId = response.getString("log_id");
                if (getOpenLogId().equals("")) {
                    params.setOpenLogId(logId);
                }
                params.setLastOpenLogId(logId);
            }
        } catch (JSONException e) {
        }

        return true; // request went through, don't retry
    }

    /**
     * If location autocollect is enabled,
     * tries to get latest location from TuneLocationListener, triggering update if needed
     */
    protected void updateLocation() {
        if (collectLocation) {
            if (params.getLocation() == null &&
                    locationListener != null) {
                Location lastLocation = locationListener.getLastLocation();
                if (lastLocation != null) {
                    params.setLocation(new TuneLocation(lastLocation));
                }
            }
        }
    }

    /******************
     * Public Getters *
     ******************/

    /**
     * Gets the action of the event
     * @return install/update/conversion
     */
    public String getAction() {
        return params.getAction();
    }

    /**
     * Gets the TUNE advertiser ID.
     * @return TUNE advertiser ID
     */
    public String getAdvertiserId() {
        return params.getAdvertiserId();
    }

    /**
     * Gets the user age.
     *
     * NOTE: this value must be set with {@link Tune#setAge(int)} otherwise this method will return 0.
     *
     * @return age, if set. If no value is set this method returns 0.
     */
    public int getAge() {
        String ageString = params.getAge();
        int age = 0;
        if (ageString != null) {
            try {
                age = Integer.parseInt(ageString);
            } catch (NumberFormatException e) {
                TuneDebugLog.e(TuneConstants.TAG, "Error parsing age value " + ageString, e);
            }
        }

        return age;
    }

    /**
     * Gets the device altitude.
     *
     * NOTE: this value must be set with {@link Tune#setAltitude(double)} otherwise this method will return 0.
     *
     * @return device altitude, if set. If no value is set returns 0.0
     */
    public double getAltitude() {
        String altitudeString = params.getAltitude();
        double altitude = 0.0d;
        if (altitudeString != null) {
            try {
                altitude = Double.parseDouble(altitudeString);
            } catch (NumberFormatException e) {
                TuneDebugLog.e(TuneConstants.TAG, "Error parsing altitude value " + altitudeString, e);
            }
        }
        return altitude;
    }

    /**
     * Gets the ANDROID_ID of the device that was set with {@link Tune#setAndroidId(String)}
     * @return ANDROID_ID
     */
    public String getAndroidId() {
        return params.getAndroidId();
    }

    /**
     * Get whether the user has app-level ad tracking enabled or not.
     * @return app-level ad tracking enabled or not
     */
    public boolean getAppAdTrackingEnabled() {
        String appAdTrackingEnabledString = params.getAppAdTrackingEnabled();
        int adTrackingEnabled = 0;
        if (appAdTrackingEnabledString != null) {
            try {
                adTrackingEnabled = Integer.parseInt(appAdTrackingEnabledString);
            } catch (NumberFormatException e) {
                TuneDebugLog.e(TuneConstants.TAG, "Error parsing adTrackingEnabled value " + appAdTrackingEnabledString, e);
            }
        }

        return (adTrackingEnabled == 1);
    }

    /**
     * Gets the app name
     * @return app name
     */
    public String getAppName() {
        return params.getAppName();
    }

    /**
     * Gets the app version
     * @return app version
     */
    public int getAppVersion() {
        String appVersionString = params.getAppVersion();
        int appVersion = 0;
        if (appVersionString != null) {
            try {
                appVersion = Integer.parseInt(appVersionString);
            } catch (NumberFormatException e) {
                TuneDebugLog.e(TuneConstants.TAG, "Error parsing appVersion value " + appVersionString, e);
            }

        }
        return appVersion;
    }

    /**
     * Gets the connection type (mobile or WIFI);.
     * @return whether device is connected by WIFI or mobile data connection
     */
    public String getConnectionType() {
        return params.getConnectionType();
    }

    /**
     * Gets the ISO 639-1 country code
     * @return ISO 639-1 country code
     */
    public String getCountryCode() {
        return params.getCountryCode();
    }

    /**
     * Gets the ISO 4217 currency code.
     * @return ISO 4217 currency code
     */
    public String getCurrencyCode() {
        return params.getCurrencyCode();
    }

    /**
     * Gets the device brand/manufacturer (HTC, Apple, etc)
     * @return device brand/manufacturer name
     */
    public String getDeviceBrand() {
        return params.getDeviceBrand();
    }

    /**
     * Gets the device carrier if any
     * @return mobile device carrier/service provider name
     */
    public String getDeviceCarrier() {
        return params.getDeviceCarrier();
    }

    /**
     * Gets the Device ID, also known as IMEI/MEID, if any
     * @return device IMEI/MEID
     */
    public String getDeviceId() {
        return params.getDeviceId();
    }

    /**
     * Gets the device model name
     * @return device model name
     */
    public String getDeviceModel() {
        return params.getDeviceModel();
    }

    /**
     * Gets value previously set of existing user or not.
     * @return whether user existed prior to install
     */
    public boolean getExistingUser() {
        int intExisting = Integer.parseInt(params.getExistingUser());
        return (intExisting == 1);
    }

    /**
     * Gets the Facebook user ID previously set.
     * @return Facebook user ID
     */
    public String getFacebookUserId() {
        return params.getFacebookUserId();
    }

    /**
     * Gets the user gender set with {@link Tune#setGender(TuneGender)}.
     * @return gender
     */
    public TuneGender getGender() {
        String gender = params.getGender();
        if ("0".equals(gender)) {
            return TuneGender.MALE;
        } else if ("1".equals(gender)) {
            return TuneGender.FEMALE;
        } else {
            return TuneGender.UNKNOWN;
        }
    }

    /**
     * Gets the Google Play Services Advertising ID.
     * @return Google advertising ID
     */
    public String getGoogleAdvertisingId() {
        return params.getGoogleAdvertisingId();
    }

    /**
     * Gets whether use of the Google Play Services Advertising ID is limited by user request.
     * @return whether tracking is limited
     */
    public boolean getGoogleAdTrackingLimited() {
        String googleAdTrackingLimitedString = params.getGoogleAdTrackingLimited();
        int googleAdTrackingLimited = 0;
        try {
            googleAdTrackingLimited = Integer.parseInt(googleAdTrackingLimitedString);
        } catch (NumberFormatException e) {
            TuneDebugLog.e(TuneConstants.TAG, "Error parsing googleAdTrackingLimited value " + googleAdTrackingLimitedString, e);
        }

        return (googleAdTrackingLimited != 0);
    }

    /**
     * Gets the Google user ID previously set.
     * @return Google user ID
     */
    public String getGoogleUserId() {
        return params.getGoogleUserId();
    }

    /**
     * Gets the date of app install
     * @return date that app was installed, epoch seconds
     */
    public long getInstallDate() {
        String installDateString = params.getInstallDate();
        long installDate = 0l;
        if (installDateString != null) {
            try {
                installDate = Long.parseLong(installDateString);
            } catch (NumberFormatException e) {
                TuneDebugLog.e(TuneConstants.TAG, "Error parsing installDate value " + installDateString, e);
            }
        }
        return installDate;
    }

    /**
     * Gets the Google Play INSTALL_REFERRER
     * @return Play INSTALL_REFERRER
     */
    public String getInstallReferrer() {
        return params.getInstallReferrer();
    }

    /**
     * Gets whether the user is revenue-generating or not
     * @return true if the user has produced revenue, false if not
     */
    public boolean getIsPayingUser() {
        String isPayingUser = params.getIsPayingUser();
        return "1".equals(isPayingUser);
    }

    /**
     * Gets the language of the device
     * @return device language
     */
    public String getLanguage() {
        return params.getLanguage();
    }

    /**
     * Gets the last TUNE open log ID
     * @return most recent TUNE open log ID
     */
    public String getLastOpenLogId() {
        return params.getLastOpenLogId();
    }

    /**
     * Gets the device latitude.
     *
     * NOTE: Must be set by {@link Tune#setLatitude(double)}. This value is not automatically retrieved.
     * @return device latitude
     */
    public double getLatitude() {
        String latitudeString = params.getLatitude();
        double latitude = 0d;
        if (latitudeString != null) {
            try {
                latitude = Double.parseDouble(latitudeString);
            } catch (NumberFormatException e) {
                TuneDebugLog.e(TuneConstants.TAG, "Error parsing latitude value " + latitudeString, e);
            }
        }

        return latitude;
    }

    /**
     * Gets the device longitude.
     *
     * NOTE: This value must be set by {@link Tune#setLongitude(double)}. This value is not automatically retrieved.
     * @return device longitude
     */
    public double getLongitude() {
        String longitudeString = params.getLongitude();
        double longitude = 0d;
        if (longitudeString != null) {
            try {
                longitude = Double.parseDouble(longitudeString);
            } catch (NumberFormatException e) {
                TuneDebugLog.e(TuneConstants.TAG, "Error parsing longitude value " + longitudeString, e);
            }
        }

        return longitude;
    }

    /**
     * Gets the MAC address of device
     * @return device MAC address
     */
    public String getMacAddress() {
        return params.getMacAddress();
    }

    /**
     * Gets the MAT ID generated on install
     * @return MAT ID
     */
    public String getMatId() {
        return params.getMatId();
    }

    /**
     * Gets the mobile country code.
     * @return mobile country code associated with the carrier
     */
    public String getMCC() {
        return params.getMCC();
    }

    /**
     * Gets the mobile network code.
     * @return mobile network code associated with the carrier
     */
    public String getMNC() {
        return params.getMNC();
    }

    /**
     * Gets the first TUNE open log ID
     * @return first TUNE open log ID
     */
    public String getOpenLogId() {
        return params.getOpenLogId();
    }

    /**
     * Gets the Android OS version
     * @return Android OS version
     */
    public String getOsVersion() {
        return params.getOsVersion();
    }


    /**
     * Gets the app package name
     * @return package name of app
     */
    public String getPackageName() {
        return params.getPackageName();
    }

    /**
     * Get SDK plugin name used
     * @return name of TUNE plugin
     */
    public String getPluginName() {
        return params.getPluginName();
    }

    /**
     * Gets the package name of the app that started this Activity, if any
     * @return source package name that caused open via StartActivityForResult
     */
    public String getReferralSource() {
        return params.getReferralSource();
    }

    /**
     * Gets the url scheme that started this Activity, if any
     * @return full url of app scheme that caused open
     */
    public String getReferralUrl() {
        return params.getReferralUrl();
    }

    /**
     * Gets the screen density of the device
     * @return 0.75/1.0/1.5/2.0/3.0/4.0 for ldpi/mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi
     */
    public String getScreenDensity() {
        return params.getScreenDensity();
    }

    /**
     * Gets the screen height of the device in pixels
     * @return height
     */
    public String getScreenHeight() {
        return params.getScreenHeight();
    }

    /**
     * Gets the screen width of the device in pixels
     * @return width
     */
    public String getScreenWidth() {
        return params.getScreenWidth();
    }

    /**
     * Gets the TUNE SDK version
     * @return TUNE SDK version
     */
    public String getSDKVersion() {
        return params.getSdkVersion();
    }

    /**
     * Gets the TRUSTe ID set
     * @return TRUSTe ID
     */
    public String getTRUSTeId() {
        return params.getTRUSTeId();
    }

    /**
     * Gets the Twitter user ID previously set.
     * @return Twitter user ID
     */
    public String getTwitterUserId() {
        return params.getTwitterUserId();
    }

    /**
     * Gets the device browser user agent
     * @return device user agent
     */
    public String getUserAgent() {
        return params.getUserAgent();
    }

    /**
     * Gets the custom user email.
     * @return custom user email
     */
    public String getUserEmail() {
        return params.getUserEmail();
    }

    /**
     * Gets the custom user ID.
     * @return custom user id
     */
    public String getUserId() {
        return params.getUserId();
    }

    /**
     * Gets the custom user name.
     * @return custom user name
     */
    public String getUserName() {
        return params.getUserName();
    }

    /******************
     * Public Setters *
     ******************/

    /**
     * Sets the TUNE advertiser ID
     * @param advertiserId TUNE advertiser ID
     */
    public void setAdvertiserId(final String advertiserId) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setAdvertiserId(advertiserId);
        }});
    }

    /**
     * Sets the user's age. When age is set to a value less than 13 IAM push notifications will not be sent to this device, in order to comply with COPPA.
     * See https://www.ftc.gov/enforcement/rules/rulemaking-regulatory-reform-proceedings/childrens-online-privacy-protection-rule
     * @param age User age
     */
    public void setAge(final int age) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setAge(Integer.toString(age));
        }});
    }

    /**
     * Sets the device altitude.
     * @param altitude device altitude
     */
    public void setAltitude(final double altitude) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setAltitude(Double.toString(altitude));
        }});
    }

    /**
     * Sets the ANDROID ID
     * @param androidId ANDROID_ID
     */
    public void setAndroidId(final String androidId) {
        if (dplinkr != null) {
            dplinkr.setAndroidId(androidId);
            requestDeeplink();
        }
        // Params sometimes not initialized by the time GetGAID thread finishes
        if (params != null) {
            params.setAndroidId(androidId);
        }
    }

    /**
     * Sets the ANDROID ID MD5 hash
     * @param androidIdMd5 ANDROID_ID MD5 hash
     */
    public void setAndroidIdMd5(final String androidIdMd5) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setAndroidIdMd5(androidIdMd5);
        }});
    }

    /**
     * Sets the ANDROID ID SHA-1 hash
     * @param androidIdSha1 ANDROID_ID SHA-1 hash
     */
    public void setAndroidIdSha1(final String androidIdSha1) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setAndroidIdSha1(androidIdSha1);
        }});
    }

    /**
     * Sets the ANDROID ID SHA-256 hash
     * @param androidIdSha256 ANDROID_ID SHA-256 hash
     */
    public void setAndroidIdSha256(final String androidIdSha256) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setAndroidIdSha256(androidIdSha256);
        }});
    }

    /**
     * Sets whether app-level ad tracking is enabled.
     * @param adTrackingEnabled true if user has opted out of ad tracking at the app-level, false if not
     */
    public void setAppAdTrackingEnabled(final boolean adTrackingEnabled) {
        pubQueue.execute(new Runnable() {
            public void run() {
                if (adTrackingEnabled) {
                    params.setAppAdTrackingEnabled(Integer.toString(1));
                } else {
                    params.setAppAdTrackingEnabled(Integer.toString(0));
                }
            }
        });
    }

    /**
     * Sets the conversion key for the SDK
     * @param conversionKey TUNE conversion key
     */
    public void setConversionKey(final String conversionKey) {
        pubQueue.execute(new Runnable() {
            public void run() {
                params.setConversionKey(conversionKey);
            }
        });
    }

    /**
     * Sets the ISO 4217 currency code.
     * @param currencyCode the currency code
     */
    public void setCurrencyCode(final String currencyCode) {
        pubQueue.execute(new Runnable() {
            public void run() {
                if (currencyCode == null || currencyCode.equals("")) {
                    params.setCurrencyCode(TuneConstants.DEFAULT_CURRENCY_CODE);
                } else {
                    params.setCurrencyCode(currencyCode);
                }
            }
        });
    }

    public void setDeeplinkListener(TuneDeeplinkListener listener) {
        dplinkr.setListener(listener);
    }

    /**
     * Sets the device brand, or manufacturer
     * @param deviceBrand device brand
     */
    public void setDeviceBrand(final String deviceBrand) {
        pubQueue.execute(new Runnable() {
            public void run() {
                params.setDeviceBrand(deviceBrand);
            }
        });
    }

    /**
     * Sets the device IMEI/MEID
     * @param deviceId device IMEI/MEID
     */
    public void setDeviceId(final String deviceId) {
        pubQueue.execute(new Runnable() {
            public void run() {
                params.setDeviceId(deviceId);
            }
        });
    }

    /**
     * Sets the device model
     * @param deviceModel device model
     */
    public void setDeviceModel(final String deviceModel) {
        pubQueue.execute(new Runnable() {
            public void run() {
                params.setDeviceModel(deviceModel);
            }
        });
    }

    /**
     * Sets whether app was previously installed prior to version with TUNE SDK
     * @param existing true if this user already had the app installed prior to updating to TUNE version
     */
    public void setExistingUser(final boolean existing) {
        pubQueue.execute(new Runnable() { public void run() {
            if (existing) {
                params.setExistingUser(Integer.toString(1));
            } else {
                params.setExistingUser(Integer.toString(0));
            }
        }});
    }

    /**
     * Sets the user ID to associate with Facebook
     * @param userId
     */
    public void setFacebookUserId(final String userId) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setFacebookUserId(userId);
        }});
    }

    /**
     * Sets the user gender.
     * @param gender use TuneGender.MALE, TuneGender.FEMALE
     */
    public void setGender(final TuneGender gender) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setGender(gender);
        }});
    }

    /**
     * Sets the Google Play Services Advertising ID
     * @param adId Google Play advertising ID
     * @param isLATEnabled whether user has requested to limit use of the Google ad ID
     */
    public void setGoogleAdvertisingId(final String adId, boolean isLATEnabled) {
        final int intLimit = isLATEnabled? 1 : 0;

        if (dplinkr != null) {
            dplinkr.setGoogleAdvertisingId(adId, intLimit);
            requestDeeplink();
        }
        if (params != null) {
            params.setGoogleAdvertisingId(adId);
            params.setGoogleAdTrackingLimited(Integer.toString(intLimit));
        }
        gotGaid = true;
        if (gotReferrer && !notifiedPool) {
            synchronized (pool) {
                pool.notifyAll();
                notifiedPool = true;
            }
        }
    }

    /**
     * Sets the user ID to associate with Google
     * @param userId
     */
    public void setGoogleUserId(final String userId) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setGoogleUserId(userId);
        }});
    }

    /**
     * Overrides the Google Play INSTALL_REFERRER received
     * @param referrer Your custom referrer value
     */
    public void setInstallReferrer(final String referrer) {
        // Record when referrer was received
        gotReferrer = true;
        referrerTime = System.currentTimeMillis();
        if (params != null) {
            params.setReferrerDelay(referrerTime - initTime);
        }
        pubQueue.execute(new Runnable() { public void run() {
            params.setInstallReferrer(referrer);
        }});
    }

    /**
     * Sets whether the user is revenue-generating or not
     * @param isPayingUser true if the user has produced revenue, false if not
     */
    public void setIsPayingUser(final boolean isPayingUser) {
        pubQueue.execute(new Runnable() { public void run() {
            if (isPayingUser) {
                params.setIsPayingUser(Integer.toString(1));
            } else {
                params.setIsPayingUser(Integer.toString(0));
            }
        }});
    }

    /**
     * Sets the device latitude.
     * @param latitude the device latitude
     */
    public void setLatitude(final double latitude) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setLatitude(Double.toString(latitude));
        }});
    }

    /**
     * Sets the device location
     * @param location the device location
     */
    public void setLocation(final Location location) {
        if (location == null) {
            TuneDebugLog.e(TuneConstants.TAG, "Location may not be null");
            return;
        }
        pubQueue.execute(new Runnable() { public void run() {
            params.setLocation(new TuneLocation(location));
        }});
    }

    /**
     * Sets the device location
     * @param location the device location as a TuneLocation
     */
    public void setLocation(final TuneLocation location) {
        if (location == null) {
            TuneDebugLog.e(TuneConstants.TAG, "Location may not be null");
            return;
        }

        setShouldAutoCollectDeviceLocation(false);

        pubQueue.execute(new Runnable() {
            @Override
            public void run() {
                params.setLocation(location);
            }
        });
    }

    /**
     * Sets the device longitude.
     * @param longitude the device longitude
     */
    public void setLongitude(final double longitude) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setLongitude(Double.toString(longitude));
        }});
    }

    /**
     * Register a TuneListener interface to receive server response callback
     * @param listener a TuneListener object that will be called when server request is complete
     */
    public void setListener(TuneListener listener) {
        tuneListener = listener;
    }

    /**
     * Sets the device MAC address.
     * @param macAddress device MAC address
     */
    public void setMacAddress(final String macAddress) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setMacAddress(macAddress);
        }});
    }

    /**
     * Sets the device OS version
     * @param osVersion device OS version
     */
    public void setOsVersion(final String osVersion) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setOsVersion(osVersion);
        }});
    }

    /**
     * Sets the app package name
     * @param packageName App package name
     */
    public void setPackageName(final String packageName) {
        dplinkr.setPackageName(packageName);
        pubQueue.execute(new Runnable() { public void run() {
            if (TextUtils.isEmpty(packageName)) {
                params.setPackageName(mContext.getPackageName());
            } else {
                params.setPackageName(packageName);
            }
        }});
    }

    /**
     * Sets the device phone number
     * @param phoneNumber Phone number
     */
    public void setPhoneNumber(final String phoneNumber) {
        pubQueue.execute(new Runnable() { public void run() {
            if (TextUtils.isEmpty(phoneNumber)) {
                params.setPhoneNumber(phoneNumber);
            } else {
                // Regex remove all non-digits from phoneNumber
                String phoneNumberDigits = phoneNumber.replaceAll("\\D+", "");
                // Convert to digits from foreign characters if needed
                StringBuilder digitsBuilder = new StringBuilder();
                for (int i = 0; i < phoneNumberDigits.length(); i++) {
                    int numberParsed = Integer.parseInt(String.valueOf(phoneNumberDigits.charAt(i)));
                    digitsBuilder.append(numberParsed);
                }
                params.setPhoneNumber(digitsBuilder.toString());
            }
        }});
    }

    /**
     * Sets publisher information for device preloaded apps
     * @param preloadData Preload app attribution data
     */
    public void setPreloadedApp(TunePreloadData preloadData) {
        mPreloadData = preloadData;
        // Only do this if TMA is not disabled
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PUBLISHER_ID, preloadData.publisherId)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.OFFER_ID, preloadData.offerId)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.AGENCY_ID, preloadData.agencyId)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PUBLISHER_REF_ID, preloadData.publisherReferenceId)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PUBLISHER_SUB_PUBLISHER, preloadData.publisherSubPublisher)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PUBLISHER_SUB_SITE, preloadData.publisherSubSite)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PUBLISHER_SUB_CAMPAIGN, preloadData.publisherSubCampaign)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PUBLISHER_SUB_ADGROUP, preloadData.publisherSubAdgroup)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PUBLISHER_SUB_AD, preloadData.publisherSubAd)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PUBLISHER_SUB_KEYWORD, preloadData.publisherSubKeyword)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PUBLISHER_SUB1, preloadData.publisherSub1)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PUBLISHER_SUB2, preloadData.publisherSub2)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PUBLISHER_SUB3, preloadData.publisherSub3)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PUBLISHER_SUB4, preloadData.publisherSub4)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.PUBLISHER_SUB5, preloadData.publisherSub5)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ADVERTISER_SUB_PUBLISHER, preloadData.advertiserSubPublisher)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ADVERTISER_SUB_SITE, preloadData.advertiserSubSite)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ADVERTISER_SUB_CAMPAIGN, preloadData.advertiserSubCampaign)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ADVERTISER_SUB_ADGROUP, preloadData.advertiserSubAdgroup)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ADVERTISER_SUB_AD, preloadData.advertiserSubAd)));
        TuneEventBus.post(new TuneUpdateUserProfile(new TuneAnalyticsVariable(TuneUrlKeys.ADVERTISER_SUB_KEYWORD, preloadData.advertiserSubKeyword)));
    }

    /**
     * Get referral sources from Activity
     * @param act Activity to get referring package name and url scheme from
     */
    public void setReferralSources(final Activity act) {
        pubQueue.execute(new Runnable() { public void run() {
            // Set source package
            params.setReferralSource(act.getCallingPackage());
            // Set source url query
            Intent intent = act.getIntent();
            if (intent != null) {
                Uri uri = intent.getData();
                if (uri != null) {
                    params.setReferralUrl(uri.toString());
                }
            }
        }});
    }

    /**
     * Set referral url (deeplink)
     * @param url deeplink with which app was invoked
     */
    public void setReferralUrl(final String url) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setReferralUrl(url);
        }});
    }

    /**
     * Sets the TRUSTe ID, should generate via their SDK
     * @param tpid TRUSTe ID
     */
    public void setTRUSTeId(final String tpid) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setTRUSTeId(tpid);
        }});
    }

    /**
     * Sets the user ID to associate with Twitter
     * @param userId
     */
    public void setTwitterUserId(final String userId) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setTwitterUserId(userId);
        }});
    }

    /**
     * Sets the custom user email.
     * @param userEmail the user email
     */
    public void setUserEmail(final String userEmail) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setUserEmail(userEmail);
        }});
    }

    /**
     * Sets the custom user ID.
     * @param userId the user id
     */
    public void setUserId(final String userId) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setUserId(userId);
        }});
    }

    /**
     * Sets the custom user name.
     * @param userName the username
     */
    public void setUserName(final String userName) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setUserName(userName);
        }});
    }

    /**
     * Set the name of plugin used, if any
     * @param pluginName
     */
    public void setPluginName(final String pluginName) {
        // Validate plugin name
        if (Arrays.asList(TuneConstants.PLUGIN_NAMES).contains(pluginName)) {
            pubQueue.execute(new Runnable() { public void run() {
                params.setPluginName(pluginName);
            }});
        } else {
            if (debugMode) {
                throw new IllegalArgumentException("Plugin name not acceptable");
            }
        }
    }

    /**
     * Turns debug mode on or off, under tag "TUNE".
     *
     * Additionally, setting this to 'true' will cause two exceptions to be thrown to aid in debugging the IAM configuration.
     * Normally IAM will log an error to the console when you misconfigure or misuse a method, but this way an exception is thrown to
     * quickly and explicitly find what is misconfigured.
     *
     *  - TuneIAMNotEnabledException: This will be thrown if you use a IAM method without IAM enabled.
     *  - TuneIAMConfigurationException: This will be thrown if the arguments passed to an IAM method are invalid. The exception message will have more details.
     *
     * @param debug whether to enable debug output
     */
    public void setDebugMode(final boolean debug) {
        debugMode = debug;
        pubQueue.execute(new Runnable() { public void run() {
            params.setDebugMode(debug);
        }});
        if (debug) {
            TuneDebugLog.setLogLevel(Log.DEBUG);
            Handler handler = new Handler(Looper.getMainLooper());
            handler.post(new Runnable() {
                public void run() {
                    Toast.makeText(mContext, "TUNE Debug Mode Enabled, do not release with this enabled!!", Toast.LENGTH_LONG).show();
                }
            });
        } else {
            TuneDebugLog.setLogLevel(Log.ERROR);
        }
    }


    /**
     * Checks the current status of debug mode.
     *
     * @return Whether debug mode is on or off.
     */
    public boolean isInDebugMode() {
        return debugMode;
    }

    /**
     * Enables or disables primary Gmail address collection
     * Requires GET_ACCOUNTS permission
     * @param collectEmail whether to collect device email address
     */
    public void setEmailCollection(final boolean collectEmail) {
        pubQueue.execute(new Runnable() {
            @Override
            public void run() {
                boolean accountPermission = TuneUtils.hasPermission(mContext, Manifest.permission.GET_ACCOUNTS);
                if (collectEmail && accountPermission) {
                    // Set primary Gmail address as user email
                    Account[] accounts = AccountManager.get(mContext).getAccountsByType("com.google");
                    if (accounts.length > 0) {
                        params.setUserEmail(accounts[0].name);
                    }

                    // Store the rest of email addresses
                    HashMap<String, String> emailMap = new HashMap<String, String>();
                    accounts = AccountManager.get(mContext).getAccounts();
                    for (Account account : accounts) {
                        if (Patterns.EMAIL_ADDRESS.matcher(account.name).matches()) {
                            emailMap.put(account.name, account.type);
                        }
                        Set<String> emailKeys = emailMap.keySet();
                        String[] emailArr = emailKeys.toArray(new String[emailKeys.size()]);
                        params.setUserEmails(emailArr);
                    }
                }
            }
        });
    }

    /**
     * Whether to log TUNE events in the FB SDK as well
     * @param logging Whether to send TUNE events to FB as well
     * @param context Activity context
     * @param limitEventAndDataUsage Whether user opted out of ads targeting
     */
    public void setFacebookEventLogging(boolean logging, Context context, boolean limitEventAndDataUsage) {
        fbLogging = logging;
        if (logging && (context != null)) {
            TuneFBBridge.startLogger(context, limitEventAndDataUsage);
        }
    }

    /**
     * Whether to autocollect device location if location is enabled
     * @param autoCollect Autocollect device location, default is true
     */
    public void setShouldAutoCollectDeviceLocation(boolean autoCollect) {
        collectLocation = autoCollect;
        if (!collectLocation) {
            locationListener.stopListening();
        }
    }

    /********************
     ** Power Hook API *
     ******************/

    /**
     * Registers a Power Hook for use with TUNE.
     *
     * Use this method to declare the existence of a Power Hook you would like to pass in from TUNE.  This declaration should occur in {@link android.app.Application#onCreate()}.
     *
     * @param hookId The name of the configuration setting to register. Name must be unique for this app and cannot be empty.
     * @param friendlyName The name for this hook that will be displayed in TMC. This value cannot be empty.
     * @param defaultValue The default value for this hook.  This value will be used if no value is passed in from TMC for this app. This value cannot be nil.
     *
     */
    public void registerPowerHook(String hookId, String friendlyName, String defaultValue) {
        if (TuneManager.getPowerHookManagerForUser("registerPowerHook") == null) {
            return;
        }

        TuneManager.getInstance().getPowerHookManager().registerPowerHook(hookId, friendlyName, defaultValue, null, null);
    }

    /**
     * Registers a single-value (non-code-block) Power Hook for use with TUNE.
     *
     * Use this method to declare the existence of a Power Hook you would like to pass in from TUNE.  This declaration should occur in the {@link android.app.Application#onCreate()} method of your Application.
     *
     * @param hookId The name of the configuration setting to register. Name must be unique for this app and cannot be empty.
     * @param friendlyName The name for this hook that will be displayed in TMC. This value cannot be empty.
     * @param defaultValue The default value for this hook.  This value will be used if no value is passed in from TMC for this app. This value cannot be nil.
     * @param description The description for this Power Hook. This will be shown on the web to help identify this Power Hook if many are registered.
     * @param approvedValues The values that are allowed for this Power Hook. Any values entered on the web that don't fit within this array of values will not propagate to the app.
     *
     */
    // NOTE: Private til we release this API.
    private void registerPowerHook(String hookId, String friendlyName, String defaultValue, String description, List<String> approvedValues) {
        if (TuneManager.getPowerHookManagerForUser("registerPowerHook") == null) {
            return;
        }

        TuneManager.getInstance().getPowerHookManager().registerPowerHook(hookId, friendlyName, defaultValue, description, approvedValues);
    }

    /**
     * Gets the value of a Power Hook.
     *
     * Use this method to get the value of a Power Hook from TUNE.  This will return the value specified in IAM web console, or the default value if none has been specified.
     *
     * NOTE: If no hook was registered for the given ID, this method will return null.
     *
     * @param hookId The name of the Power Hook you wish to retrieve. Will return nil if the Power Hook has not been registered.
     */
    public String getValueForHookById(String hookId) {
        if (TuneManager.getPowerHookManagerForUser("getValueForHookById") == null) {
            return null;
        }

        return TuneManager.getInstance().getPowerHookManager().getValueForHookById(hookId);
    }

    /**
     * Sets the value of a Power Hook.
     *
     * Use this method to set the value of a Power Hook from TUNE.
     *
     * NOTE: ** This is for QA purposes only, you should not use this method in Production as it will override the value sent from the web platform. **
     *
     * @param hookId The name of the Power Hook you wish to set the value for.
     * @param value The new value you would like to test.
     */
    public void setValueForHookById(String hookId, String value) {
        if (TuneManager.getPowerHookManagerForUser("setValueForHookById") == null) {
            return;
        }

        TuneManager.getInstance().getPowerHookManager().setValueForHookById(hookId, value);
    }

    /**
     * Register a callback when any Power Hooks have changed due to a new value from the Server.
     *
     * NOTE: Only the latest callback registered will be executed.
     * 
     * NOTE: ** The thread calling the block of code is not guaranteed to be on the main thread.  If the code inside of the block requires executing on the main thread you will need to implement this logic. **
     *
     * @param callback The block of code to be executed.
     *
     */
    public void onPowerHooksChanged(TuneCallback callback) {
        if (TuneManager.getPowerHookManagerForUser("onPowerHooksChanged") == null) {
            return;
        }

        TuneManager.getInstance().getPowerHookManager().onPowerHooksChanged(callback);
    }

    /********************
     ** Deep Action API *
     ******************/

    /**
     * Registers a code-block Deep Action for use with TUNE.
     *
     * Use this method to declare the existence of a Power Hook you would like to pass in from TUNE.
     *
     * @param actionId The name of the deep action to register. Name must be unique for this app and cannot be null or empty.
     * @param friendlyName The friendly name for this action that will be displayed in TMC. This value cannot be null.
     * @param defaultData The default values for this deep action.  These values will be used if no value is passed in from TMC for this app. This cannot be null.
     * @param action The code block that implements Runnable to execute when this Deep Action fires. This cannot be null
     */
    public void registerDeepAction(String actionId, String friendlyName, Map<String, String> defaultData, TuneDeepActionCallback action) {
        if (TuneManager.getDeepActionManagerForUser("registerDeepAction") == null) {
            return;
        }

        TuneManager.getInstance().getDeepActionManager().registerDeepAction(actionId, friendlyName, null, defaultData, null, action);
    }

    /**
     * Executes a previously registered Deep Action code-block. The data to be used by the current execution of the deep action code-block is derived by merging the Map provided here with the default Map provided during deep action registration. Also, the new values take preference over the default values when the keys match.
     *
     * @param activity Activity object to be made available to the deep action code-block. This object may be null depending on its usage in the code-block.
     * @param actionId Non-empty non-null name of a previously registered deep action code-block.
     * @param data Values to be used with the deep action. This Map may be null or empty or contain string keys and values.
     */
    public void executeDeepAction(Activity activity, String actionId, Map<String, String> data) {
        if (TuneManager.getDeepActionManagerForUser("executeDeepAction") == null) {
            return;
        }

        TuneManager.getInstance().getDeepActionManager().executeDeepAction(activity, actionId, data);
    }

    /**
     * Registers a code-block Deep Action for use with TUNE.
     *
     * Use this method to declare the existence of a Power Hook you would like to pass in from TUNE.
     *
     * @param actionId The name of the deep action to register. Name must be unique for this app and cannot be null or empty.
     * @param friendlyName The friendly name for this action that will be displayed in TMC. This value cannot be null.
     * @param description An optional description ofr this Deep Action.
     * @param defaultData The default values for this deep action.  These values will be used if no value is passed in from TMC for this app. This cannot be null.
     * @param action The code block that implements Runnable to execute when this Deep Action fires. This cannot be null
     */
    // NOTE: Private til we release this API.
    private void registerDeepAction(String actionId, String friendlyName, String description, Map<String, String> defaultData, TuneDeepActionCallback action) {
        if (TuneManager.getDeepActionManagerForUser("registerDeepAction") == null) {
            return;
        }

        TuneManager.getInstance().getDeepActionManager().registerDeepAction(actionId, friendlyName, description, defaultData, null, action);
    }

    /**
     * Registers a code-block Deep Action for use with TUNE.
     *
     * Use this method to declare the existence of a Power Hook you would like to pass in from TUNE.
     *
     * @param actionId The name of the deep action to register. Name must be unique for this app and cannot be null or empty.
     * @param friendlyName The friendly name for this action that will be displayed in TMC. This value cannot be null.
     * @param description An optional description ofr this Deep Action.
     * @param defaultData The default values for this deep action.  These values will be used if no value is passed in from TMC for this app. This cannot be null.
     * @param approvedValues An optional Map of key to list of approved values.
     * @param action The code block that implements Runnable to execute when this Deep Action fires. This cannot be null
     */
    // NOTE: Private til we release this API.
    private void registerDeepAction(String actionId, String friendlyName, String description, Map<String, String> defaultData, Map<String, List<String>> approvedValues, TuneDeepActionCallback action) {
        if (TuneManager.getDeepActionManagerForUser("registerDeepAction") == null) {
            return;
        }

        TuneManager.getInstance().getDeepActionManager().registerDeepAction(actionId, friendlyName, description, defaultData, approvedValues, action);
    }

    /****************************
     ** Experiment Details API *
     **************************/

    /**
     * Get details for all currently running Power Hook Variable experiments.
     *
     * Details include the hook id for the Power Hook, experiment and variation ids and start
     * and end date of the experiment.
     *
     * Returns a `Map` of experiment details for all running Power Hook variable experiments,
     * where the keys are the `String` Power Hook IDs of the Power Hooks, and the values
     * are `TunePowerHookExperimentDetails` objects.
     */
    public Map<String, TunePowerHookExperimentDetails> getPowerHookExperimentDetails() {
        if (TuneManager.getExperimentManagerForUser("getPowerHookExperimentDetails") == null) {
            return null;
        }

        return TuneManager.getInstance().getExperimentManager().getPhookExperimentDetails();
    }


    /**
     * Get details for all currently running In App Message experiments.
     *
     * Details include the experiment and variation ids and start and end date of the experiment.
     *
     * Returns a `HashMap` of experiment details for all running In App Message experiments,
     * where the keys are the `String` campaign ids of the In App Messages, and the values are
     * `TuneInAppMessageExperimentDetails` objects.
     */
    public Map<String, TuneInAppMessageExperimentDetails> getInAppMessageExperimentDetails() {
        if (TuneManager.getExperimentManagerForUser("getInAppMessageExperimentDetails") == null) {
            return null;
        }

        return TuneManager.getInstance().getExperimentManager().getInAppExperimentDetails();
    }

    /**************************************
     ** On First Playlist Downloaded API *
     ************************************/

    /** Register callback when the first playlist is downloaded for App's lifetime.
     *
     * Use this method to register a callback the first time a playlist is downloaded. This call is non-blocking so code execution will continue immediately to the next line of code.
     *
     * <b>IMPORTANT:</b> The thread executing the callback is not going to be on the main thread. You will need to implement custom logic if you want to ensure that the block of code always executes on the main thread.
     *
     * If the first playlist has already been downloaded when this call is made the callback is executed immediately on a background thread.
     *
     * Otherwise the callback will fire after {@value TuneConstants#DEFAULT_FIRST_PLAYLIST_DOWNLOADED_TIMEOUT} milliseconds or when the first playlist is downloaded, whichever comes first.
     *
     * NOTE: This callback will fire upon first playlist download from the application start and upon each callback registration call.
     * If registered more than once, the latest callback will always fire, regardless of whether a previously registered callback already executed.
     * We do not recommend registering more than once but if you do so, please make sure that executing the callback more than once will not cause any issues in your app.
     *
     * NOTE: Only one callback can be registered at a time. Each time a callback is registered it will fire.
     *
     * NOTE: Pending callbacks will be canceled upon app background and resumed upon app foreground.
     *
     * WARNING: If TMA is not enabled then this callback will never fire.
     *
     * @param callback A TuneCallback object that is to be executed.
     *
     *
     */
    public void onFirstPlaylistDownloaded(final TuneCallback callback) {
        if (TuneManager.getPlaylistManagerForUser("onFirstPlaylistDownloaded") == null) {
            return;
        }

        TuneManager.getInstance().getPlaylistManager().onFirstPlaylistDownloaded(callback, TuneConstants.DEFAULT_FIRST_PLAYLIST_DOWNLOADED_TIMEOUT);
    }


    /** Register callback when the first playlist is downloaded for the App's lifetime.
     *
     * Use this method to register a callback for the first time a playlist is downloaded.  This call is non-blocking so code execution will continue immediately to the next line of code.
     *
     * <b>IMPORTANT:</b> The thread executing the callback is not going to be on the main thread. You will need to implement custom logic if you want to ensure that the block of code always executes on the main thread.
     *
     * If the first playlist has already been downloaded when this call is made the callback is executed immediately on a background thread.
     *
     * Otherwise the callback will fire after the given timeout (in milliseconds) or when the first playlist is downloaded, whichever comes first.
     *
     * If the timeout is greater than zero, the callback will fire when the timeout expires or the first playlist is downloaded, whichever comes first.
     *
     * NOTE: This callback will fire upon first playlist download from the application start and upon each callback registration call.
     * If registered more than once, the latest callback will always fire, regardless of whether a previously registered callback already executed.
     * We do not recommend registering more than once but if you do so, please make sure that executing the callback more than once will not cause any issues in your app.
     *
     * NOTE: Only one callback can be registered at a time. Each time a callback is registered it will fire.
     *
     * NOTE: Pending callbacks will be canceled upon app background and resumed upon app foreground.
     *
     * WARNING: If TMA is not enabled then this callback will never fire.
     *
     * @param callback A TuneCallback object that is to be executed.
     * @param timeout The number of miliseconds to wait until executing the callback regardless
     *                of Playlist download.
     *
     */
    public void onFirstPlaylistDownloaded(TuneCallback callback, long timeout) {
        if (TuneManager.getPlaylistManagerForUser("onFirstPlaylistDownloaded") == null) {
            return;
        }

        TuneManager.getInstance().getPlaylistManager().onFirstPlaylistDownloaded(callback, timeout);
    }


    /*************
     ** Push API *
     *************/

    /**
     * Provide Tune with your Push Sender ID. This is your Google API Project Number. We will handle getting the GCM registration Id for each device.<br>
     * <br>
     * You get your project number when you set up a project at https://console.developers.google.com/project
     *
     * By setting a push sender Id you are implicitly enabling Tune Push Messaging.
     *
     * IMPORTANT: If you use this method you should not use {@link Tune#setPushNotificationRegistrationId(String)}
     *
     * @param pushSenderId Your Push Sender Id.
     */
    public void setPushNotificationSenderId(String pushSenderId) {
        if (TuneManager.getPushManagerForUser("setPushNotificationSenderId") == null) {
            return;
        }

        TuneManager.getInstance().getPushManager().setPushNotificationSenderId(pushSenderId);
    }

    /**
     * Provide Tune with your GCM registration id for this device.<br>
     * <br>
     *
     * By using this method you are implicitly enabling Tune Push Messaging.
     *
     * IMPORTANT: If you use this method you should not use {@link Tune#setPushNotificationSenderId(String)}
     *
     * @param registrationId The device token you want to use.
     */
    public void setPushNotificationRegistrationId(String registrationId) {
        if (TuneManager.getPushManagerForUser("setPushNotificationRegistrationId") == null) {
            return;
        }

        TuneManager.getInstance().getPushManager().setPushNotificationRegistrationId(registrationId);
    }

    /**
     * Provide Tune with a notification builder to provide defaults for your app's notifications.<br>
     * <br>
     * If you do not use {@link #setPushNotificationSenderId(String)} this doesn't do anything.
     * Important: If you do not provide a small icon for your notifications via the builder we will default to using your app icon. This may look odd if your app is targeting API 21+ because the OS will take only the alpha of the icon and display that on a neutral background. If your app is set to target API 21+ we strongly recommend that you take advantage of the {@link TuneNotificationBuilder} API.
     *
     * @param builder by providing an {@link TuneNotificationBuilder} you can provide defaults for your app's notifications for Artisan Push Messages, like the small icon
     */
    public void setPushNotificationBuilder(TuneNotificationBuilder builder) {
        if (TuneManager.getPushManagerForUser("setPushNotificationBuilder") == null) {
            return;
        }

        TuneManager.getInstance().getPushManager().setTuneNotificationBuilder(builder);
    }

    /**
     * Specify whether the current user has opted out of push messaging.<br/>
     * <br/>
     * This information is added to the personalization profile of the current user for segmentation, targeting, and reporting purposes. <br>
     * <br>
     * Also, if you are using Tune Push, then by default Tune will assume push messaging is enabled as long as the user has Google Play Services installed on their device and we can successfully get a device token for their device. <br>
     * <br>
     * If you have a custom setting that gives your end users the ability to turn off notifications for your app, you can use this method to pass that setting on to Tune. Tune will not send notifications to devices where this setting is turned off. <br>
     * <br>
     * This can be called from anywhere in your app. <br>
     *
     * @param optedOutOfPush Whether the user opted out of push messaging.
     */
    public void setOptedOutOfPush(boolean optedOutOfPush) {
        if (TuneManager.getPushManagerForUser("setOptedOutOfPush") == null) {
            return;
        }

        TuneManager.getInstance().getPushManager().setOptedOutOfPush(optedOutOfPush);
    }

    /**
     * Returns the currently registered device token for push.
     * <br/>
     *
     * @return The currently registered device token for push, or null if we aren't registered.
     */
    public String getDeviceToken() {
        if (TuneManager.getPushManagerForUser("getDeviceToken") == null) {
            return null;
        }

        return TuneManager.getInstance().getPushManager().getDeviceToken();
    }

    /**
     * Returns if the user manually disabled push on the Application Setting page.
     * <br/>
     * If this returns true then nothing will be allowed to be posted to the tray, not just push notifications
     * <br/>
     *
     * @return Whether the user manually disabled push from the Application Settings screen if API Level >= 19, otherwise false.
     */
    public boolean didUserManuallyDisablePush() {
        if (TuneManager.getPushManagerForUser("didUserManuallyDisablePush") == null) {
            return false;
        }

        return TuneManager.getInstance().getPushManager().didUserManuallyDisablePush();
    }

    /**
     * Returns if the current session is because the user opened a push notification.
     * <br/>
     * This status is reset to false when the application becomes backgrounded.
     * *NOTE:* If you are implementing {@link com.tune.ma.application.TuneActivity} manually then this should be called after `super.onStart();` in the activity.
     * <br/>
     *
     * @return true if this session was started because the user opened a push message, otherwise false.
     */
    public boolean didSessionStartFromTunePush() {
        if (TuneManager.getPushManagerForUser("didSessionStartFromTunePush") == null) {
            return false;
        }

        return TuneManager.getInstance().getPushManager().didOpenFromTunePushThisSession();
    }

    /**
     * Returns a POJO containing information about the push message that started the current session.
     * <br/>
     * This is reset to null when the application becomes backgrounded.
     * *NOTE:* If you are implementing {@link com.tune.ma.application.TuneActivity} manually then this should be called after `super.onStart();` in the activity.
     * <br/>
     *
     * @return Information about the last opened push if {@link Tune#didSessionStartFromTunePush()} is true, otherwise null.
     */
    public TunePushInfo getTunePushInfoForSession() {
        if (TuneManager.getPushManagerForUser("getTunePushInfoForSession") == null) {
            return null;
        }

        return TuneManager.getInstance().getPushManager().getLastOpenedPushInfo();
    }

    /****************
     ** Segment API *
     ****************/

    /**
     * Returns whether the user belongs to the given segment
     * @param segmentId Segment ID to check for a match
     * @return whether the user belongs to the given segment
     */
    public boolean isUserInSegmentId(String segmentId) {
        if (TuneManager.getPlaylistManagerForUser("isUserInSegmentId") == null) {
            return false;
        }

        return TuneManager.getInstance().getPlaylistManager().isUserInSegmentId(segmentId);
    }

    /**
     * Returns whether the user belongs to any of the given segments
     * @param segmentIds Segment IDs to check for a match
     * @return whether the user belongs to any of the given segments
     */
    public boolean isUserInAnySegmentIds(List<String> segmentIds) {
        if (TuneManager.getPlaylistManagerForUser("isUserInAnySegmentIds") == null) {
            return false;
        }

        return TuneManager.getInstance().getPlaylistManager().isUserInAnySegmentIds(segmentIds);
    }

    /**
     * Checks for a deferred deeplink if exists
     * Opens deferred deeplink if found and returns value in TuneDeeplinkListener
     * @param listener listener for deeplink value or error
     */
    public void checkForDeferredDeeplink(TuneDeeplinkListener listener) {
        setDeeplinkListener(listener);
        if (firstInstall()) {
            dplinkr.enable(true);
        } else {
            dplinkr.enable(false);
            listener.didFailDeeplink("Not first install, not checking for deferred deeplink");
        }
        // If GetGAID thread has completed by the time this is called,
        // then get the deeplink now. Otherwise, wait until device identifiers are set
        if (dplinkr.getGoogleAdvertisingId() != null || dplinkr.getAndroidId() != null) {
            requestDeeplink();
        }
    }

    private void requestDeeplink() {
        if (dplinkr.isEnabled()) {
            // Try to set user agent here after User Agent thread completed
            dplinkr.setUserAgent(params.getUserAgent());
            dplinkr.checkForDeferredDeeplink(mContext, urlRequester);
        }
    }

    private boolean firstInstall() {
        // If SharedPreferences value for install exists, set firstInstall false
        SharedPreferences installed = mContext.getSharedPreferences(TuneConstants.PREFS_TUNE, Context.MODE_PRIVATE);
        if (installed.contains(TuneConstants.KEY_INSTALL)) {
            return false;
        } else {
            // Set install value in SharedPreferences if not there
            installed.edit().putBoolean(TuneConstants.KEY_INSTALL, true).apply();
            return true;
        }
    }

    /**
     * Helper function to check Google Play INSTALL_REFERRER for deeplink
     * @param timeout maximum timeout to wait for referrer in ms
     */
    /*
    // Removed due to Chrome issue with passing referrer through intent: https://code.google.com/p/chromium/issues/detail?id=459711
    private String checkReferrerForDeferredDeeplink(int timeout) {
        String deeplink = "";
        // Start timing for timeout
        long startTime = System.currentTimeMillis();

        // Wait up to timeout length for referrer to get populated
        while (!gotReferrer) {
            // We've exceeded timeout, stop waiting
            if ((System.currentTimeMillis() - startTime) > timeout) {
                break;
            }

            // Check again in 50ms
            try {
                Thread.sleep(50);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }

        // Read referrer for deeplink
        if (gotReferrer) {
            String referrer = params.getInstallReferrer();
            try {
                // If no mat_deeplink in referrer, return
                int deeplinkStart = referrer.indexOf("mat_deeplink=");
                if (deeplinkStart == -1) {
                    return deeplink;
                }

                deeplinkStart += 13;
                int deeplinkEnd = referrer.indexOf("&", deeplinkStart);
                if (deeplinkEnd == -1) {
                    deeplink = referrer.substring(deeplinkStart);
                } else {
                    deeplink = referrer.substring(deeplinkStart, deeplinkEnd);
                }

                // Try to decode deeplink if needed
                deeplink = URLDecoder.decode(deeplink, "UTF-8");
                // Open deeplink
                if (deeplink.length() != 0) {
                    if (tuneListener != null) {
                        tuneListener.didReceiveDeeplink(deeplink);
                    }
                    Intent i = new Intent(Intent.ACTION_VIEW);
                    i.setData(Uri.parse(deeplink));
                    i.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

                    mContext.startActivity(i);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        return deeplink;
    }*/

    // Class Getters/Setters
    /////////////////////////

    protected void setUrlRequester(UrlRequester urlRequester) {
        this.urlRequester = urlRequester;
    }


    /**********************
     * MA Profile Methods *
     **********************/

    // Register

    /**
     * Register a custom profile variable for this user.<br/>
     * <br/>
     * This custom variable will be included in this user's personalization profile, and can be used for segmentation, targeting, and reporting purposes.<br/>
     * <br/>
     * Once registered, the value for this variable can be set using {@link Tune#setCustomProfileStringValue(String, String)}. The default value is nil. <br>
     * <br>
     * This method should be called in your Application class {@link android.app.Application#onCreate()} method.<br>
     * <br>
     *
     * @param variableName Name of the variable to register for the current user. Valid characters for this name include [0-9],[a-z],[A-Z], -, and _. Any other characters will automatically be stripped out.
     */
    public void registerCustomProfileString(String variableName) {
        if (TuneManager.getProfileForUser("registerCustomProfileString") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().registerCustomProfileVariable(
                TuneAnalyticsVariable.Builder(variableName)
                        .withType(TuneVariableType.STRING)
                        .build());
    }

    /**
     * Register a custom profile variable for this user.<br/>
     * <br/>
     * This custom variable will be included in this user's personalization profile, and can be used for segmentation, targeting, and reporting purposes.<br/>
     * <br/>
     * Once registered, the value for this variable can be set using {@link Tune#setCustomProfileDate(String, Date)}. The default value is nil. <br>
     * <br>
     * This method should be called in your Application class {@link android.app.Application#onCreate()} method.<br>
     * <br>
     *
     * @param variableName Name of the variable to register for the current user. Valid characters for this name include [0-9],[a-z],[A-Z], -, and _. Any other characters will automatically be stripped out.
     */
    public void registerCustomProfileDate(String variableName) {
        if (TuneManager.getProfileForUser("registerCustomProfileDate") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().registerCustomProfileVariable(
                TuneAnalyticsVariable.Builder(variableName)
                        .withType(TuneVariableType.DATETIME)
                        .build());
    }

    /**
     * Register a custom profile variable for this user.<br/>
     * <br/>
     * This custom variable will be included in this user's personalization profile, and can be used for segmentation, targeting, and reporting purposes.<br/>
     * <br/>
     * Once registered, the value for this variable can be set using {@link Tune#setCustomProfileNumber(String, double)}, {@link Tune#setCustomProfileNumber(String, float)}, or {@link Tune#setCustomProfileNumber(String, int)}.
     * You may use these setters interchangeably. The default value is nil.
     * <br>
     * This method should be called in your Application class {@link android.app.Application#onCreate()} method.<br>
     * <br>
     *
     * @param variableName Name of the variable to register for the current user. Valid characters for this name include [0-9],[a-z],[A-Z], -, and _. Any other characters will automatically be stripped out.
     */
    public void registerCustomProfileNumber(String variableName) {
        if (TuneManager.getProfileForUser("registerCustomProfileNumber") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().registerCustomProfileVariable(
                TuneAnalyticsVariable.Builder(variableName)
                        .withType(TuneVariableType.FLOAT)
                        .build());
    }

    /**
     * Register a custom profile variable for this user.<br/>
     * <br/>
     * This custom variable will be included in this user's personalization profile, and can be used for segmentation, targeting, and reporting purposes.<br/>
     * <br/>
     * Once registered, the value for this variable can be set using {@link Tune#setCustomProfileGeolocation(String, TuneLocation)}. The default value is nil. <br>
     * <br>
     * This method should be called in your Application class {@link android.app.Application#onCreate()} method.<br>
     * <br>
     *
     * @param variableName Name of the variable to register for the current user. Valid characters for this name include [0-9],[a-z],[A-Z], -, and _. Any other characters will automatically be stripped out.
     */
    public void registerCustomProfileGeolocation(String variableName) {
        if (TuneManager.getProfileForUser("registerCustomProfileGeolocation") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().registerCustomProfileVariable(
                TuneAnalyticsVariable.Builder(variableName)
                        .withType(TuneVariableType.GEOLOCATION)
                        .build());
    }

    /**
     * Register a custom profile variable for this user.<br/>
     * <br/>
     * This custom variable will be included in this user's personalization profile, and can be used for segmentation, targeting, and reporting purposes.<br/>
     * <br/>
     * Once registered, the value for this variable can be set using {@link Tune#setCustomProfileStringValue(String, String)}. The default value is nil. <br>
     * <br>
     * This method should be called in your Application class {@link android.app.Application#onCreate()} method.<br>
     * <br>
     *
     * @param variableName Name of the variable to register for the current user. Valid characters for this name include [0-9],[a-z],[A-Z], -, and _. Any other characters will automatically be stripped out.
     * @param defaultValue Initial value for the variable.
     */
    public void registerCustomProfileString(String variableName, String defaultValue) {
        if (TuneManager.getProfileForUser("registerCustomProfileString") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().registerCustomProfileVariable(new TuneAnalyticsVariable(variableName, defaultValue));
    }

    /**
     * Register a custom profile variable for this user.<br/>
     * <br/>
     * This custom variable will be included in this user's personalization profile, and can be used for segmentation, targeting, and reporting purposes.<br/>
     * <br/>
     * Once registered, the value for this variable can be set using {@link Tune#setCustomProfileDate(String, Date)}. The default value is nil. <br>
     * <br>
     * This method should be called in your Application class {@link android.app.Application#onCreate()} method.<br>
     * <br>
     *
     * @param variableName Name of the variable to register for the current user. Valid characters for this name include [0-9],[a-z],[A-Z], -, and _. Any other characters will automatically be stripped out.
     * @param defaultValue Initial value for the variable.
     */
    public void registerCustomProfileDate(String variableName, Date defaultValue) {
        if (TuneManager.getProfileForUser("registerCustomProfileDate") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().registerCustomProfileVariable(new TuneAnalyticsVariable(variableName, defaultValue));
    }

    /**
     * Register a custom profile variable for this user.<br/>
     * <br/>
     * This custom variable will be included in this user's personalization profile, and can be used for segmentation, targeting, and reporting purposes.<br/>
     * <br/>
     * Once registered, the value for this variable can be set using {@link Tune#setCustomProfileNumber(String, double)}, {@link Tune#setCustomProfileNumber(String, float)}, or {@link Tune#setCustomProfileNumber(String, int)}.
     * You may use these setters interchangeably. The default value is nil.
     * <br>
     * This method should be called in your Application class {@link android.app.Application#onCreate()} method.<br>
     * <br>
     *
     * @param variableName Name of the variable to register for the current user. Valid characters for this name include [0-9],[a-z],[A-Z], -, and _. Any other characters will automatically be stripped out.
     * @param defaultValue Initial value for the variable.
     */
    public void registerCustomProfileNumber(String variableName, int defaultValue) {
        if (TuneManager.getProfileForUser("registerCustomProfileNumber") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().registerCustomProfileVariable(new TuneAnalyticsVariable(variableName, defaultValue));
    }

    /**
     * Register a custom profile variable for this user.<br/>
     * <br/>
     * This custom variable will be included in this user's personalization profile, and can be used for segmentation, targeting, and reporting purposes.<br/>
     * <br/>
     * Once registered, the value for this variable can be set using {@link Tune#setCustomProfileNumber(String, double)}, {@link Tune#setCustomProfileNumber(String, float)}, or {@link Tune#setCustomProfileNumber(String, int)}.
     * You may use these setters interchangeably. The default value is nil.
     * <br>
     * This method should be called in your Application class {@link android.app.Application#onCreate()} method.<br>
     * <br>
     *
     * @param variableName Name of the variable to register for the current user. Valid characters for this name include [0-9],[a-z],[A-Z], -, and _. Any other characters will automatically be stripped out.
     * @param defaultValue Initial value for the variable.
     */
    public void registerCustomProfileNumber(String variableName, double defaultValue) {
        if (TuneManager.getProfileForUser("registerCustomProfileNumber") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().registerCustomProfileVariable(new TuneAnalyticsVariable(variableName, defaultValue));
    }

    /**
     * Register a custom profile variable for this user.<br/>
     * <br/>
     * This custom variable will be included in this user's personalization profile, and can be used for segmentation, targeting, and reporting purposes.<br/>
     * <br/>
     * Once registered, the value for this variable can be set using {@link Tune#setCustomProfileNumber(String, double)}, {@link Tune#setCustomProfileNumber(String, float)}, or {@link Tune#setCustomProfileNumber(String, int)}.
     * You may use these setters interchangeably. The default value is nil.
     * <br>
     * This method should be called in your Application class {@link android.app.Application#onCreate()} method.<br>
     * <br>
     *
     * @param variableName Name of the variable to register for the current user. Valid characters for this name include [0-9],[a-z],[A-Z], -, and _. Any other characters will automatically be stripped out.
     * @param defaultValue Initial value for the variable.
     */
    public void registerCustomProfileNumber(String variableName, float defaultValue) {
        if (TuneManager.getProfileForUser("registerCustomProfileNumber") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().registerCustomProfileVariable(new TuneAnalyticsVariable(variableName, defaultValue));
    }

    /**
     * Register a custom profile variable for this user.<br/>
     * <br/>
     * This custom variable will be included in this user's personalization profile, and can be used for segmentation, targeting, and reporting purposes.<br/>
     * <br/>
     * Once registered, the value for this variable can be set using {@link Tune#setCustomProfileGeolocation(String, TuneLocation)}. The default value is nil. <br>
     * <br>
     * This method should be called in your Application class {@link android.app.Application#onCreate()} method.<br>
     * <br>
     *
     * @param variableName Name of the variable to register for the current user. Valid characters for this name include [0-9],[a-z],[A-Z], -, and _. Any other characters will automatically be stripped out.
     * @param defaultValue Initial value for the variable.
     */
    public void registerCustomProfileGeolocation(String variableName, TuneLocation defaultValue) {
        if (TuneManager.getProfileForUser("registerCustomProfileGeolocation") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().registerCustomProfileVariable(new TuneAnalyticsVariable(variableName, defaultValue));
    }

    // Set

    /**
     * Set or update the value associated with a custom string profile variable.<br/>
     * <br/>
     * This new value will be used as part of this user's personalization profile, and will be used from this point forward for segmentation, targeting, and reporting purposes.<br/>
     * <br>
     * This can be called from anywhere in your app after the appropriate register call in {@link android.app.Application#onCreate()}. <br>
     * <br>

     * @param value Value to use for the given variable.
     * @param variableName Variable to which this value should be assigned.
     */
    public void setCustomProfileStringValue(String variableName, String value) {
        if (TuneManager.getProfileForUser("setCustomProfileStringValue") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().setCustomProfileVariable(new TuneAnalyticsVariable(variableName, value));
    }

    /**
     * Set or update the value associated with a custom date profile variable.<br/>
     * <br/>
     * This new value will be used as part of this user's personalization profile, and will be used from this point forward for segmentation, targeting, and reporting purposes.<br/>
     * <br>
     * This can be called from anywhere in your app after the appropriate register call in {@link android.app.Application#onCreate()}. <br>
     * <br>

     * @param value Value to use for the given variable.
     * @param variableName Variable to which this value should be assigned.
     */
    public void setCustomProfileDate(String variableName, Date value) {
        if (TuneManager.getProfileForUser("setCustomProfileDate") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().setCustomProfileVariable(new TuneAnalyticsVariable(variableName, value));
    }

    /**
     * Set or update the value associated with a custom number profile variable.<br/>
     * <br/>
     * This new value will be used as part of this user's personalization profile, and will be used from this point forward for segmentation, targeting, and reporting purposes.<br/>
     * <br>
     * This can be called from anywhere in your app after the appropriate register call in {@link android.app.Application#onCreate()}. <br>
     * <br>

     * @param value Value to use for the given variable.
     * @param variableName Variable to which this value should be assigned.
     */
    public void setCustomProfileNumber(String variableName, int value) {
        if (TuneManager.getProfileForUser("setCustomProfileNumber") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().setCustomProfileVariable(new TuneAnalyticsVariable(variableName, value));
    }

    /**
     * Set or update the value associated with a custom number profile variable.<br/>
     * <br/>
     * This new value will be used as part of this user's personalization profile, and will be used from this point forward for segmentation, targeting, and reporting purposes.<br/>
     * <br>
     * This can be called from anywhere in your app after the appropriate register call in {@link android.app.Application#onCreate()}. <br>
     * <br>

     * @param value Value to use for the given variable.
     * @param variableName Variable to which this value should be assigned.
     */
    public void setCustomProfileNumber(String variableName, double value) {
        if (TuneManager.getProfileForUser("setCustomProfileNumber") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().setCustomProfileVariable(new TuneAnalyticsVariable(variableName, value));
    }

    /**
     * Set or update the value associated with a custom number profile variable.<br/>
     * <br/>
     * This new value will be used as part of this user's personalization profile, and will be used from this point forward for segmentation, targeting, and reporting purposes.<br/>
     * <br>
     * This can be called from anywhere in your app after the appropriate register call in {@link android.app.Application#onCreate()}. <br>
     * <br>

     * @param value Value to use for the given variable.
     * @param variableName Variable to which this value should be assigned.
     */
    public void setCustomProfileNumber(String variableName, float value) {
        if (TuneManager.getProfileForUser("setCustomProfileNumber") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().setCustomProfileVariable(new TuneAnalyticsVariable(variableName, value));
    }

    /**
     * Set or update the value associated with a custom location profile variable.<br/>
     * <br/>
     * This new value will be used as part of this user's personalization profile, and will be used from this point forward for segmentation, targeting, and reporting purposes.<br/>
     * <br>
     * This can be called from anywhere in your app after the appropriate register call in {@link android.app.Application#onCreate()}. <br>
     * <br>

     * @param value Value to use for the given variable.
     * @param variableName Variable to which this value should be assigned.
     */
    public void setCustomProfileGeolocation(String variableName, TuneLocation value) {
        if (TuneManager.getProfileForUser("setCustomProfileGeolocation") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().setCustomProfileVariable(new TuneAnalyticsVariable(variableName, value));
    }

    // Get

    /**
     * Get the value associated with a custom string profile variable.
     * <br/>
     * Return the value stored for the custom profile variable. Must be called after the appropriate register call in {@link android.app.Application#onCreate()}.
     * <br/>
     * This will return null if the variable was registered without a default and has never been set, or if has been explicitly set as null.
     *
     * @param variableName Name of the custom profile variable.
     * @return Value stored for the variable. It may be null.
     */
    public String getCustomProfileString(String variableName) {
        if (TuneManager.getProfileForUser("getCustomProfileString") == null) {
            return null;
        }

        TuneAnalyticsVariable var = TuneManager.getInstance().getProfileManager().getCustomProfileVariable(variableName);
        if (var == null) {
            return null;
        } else {
            return var.getValue();
        }
    }

    /**
     * Get the value associated with a custom date profile variable.
     * <br/>
     * Return the value stored for the custom profile variable. Must be called after the appropriate register call in {@link android.app.Application#onCreate()}.
     * <br/>
     * This will return null if the variable was registered without a default and has never been set, or if has been explicitly set as null.
     *
     * @param variableName Name of the custom profile variable.
     * @return Value stored for the variable. It may be null.
     */
    public Date getCustomProfileDate(String variableName) {
        if (TuneManager.getProfileForUser("getCustomProfileDate") == null) {
            return null;
        }

        TuneAnalyticsVariable var = TuneManager.getInstance().getProfileManager().getCustomProfileVariable(variableName);
        if (var == null) {
            return null;
        } else {
            return TuneAnalyticsVariable.stringToDate(var.getValue());
        }
    }

    /**
     * Get the value associated with a custom number profile variable.
     * <br/>
     * Return the value stored for the custom profile variable. Must be called after the appropriate register call in {@link android.app.Application#onCreate()}.
     * <br/>
     * This will return null if the variable was registered without a default and has never been set, or if has been explicitly set as null.
     *
     * @param variableName Name of the custom profile variable.
     * @return Value stored for the variable. It may be null.
     */
    public Number getCustomProfileNumber(String variableName) {
        if (TuneManager.getProfileForUser("getCustomProfileNumber") == null) {
            return null;
        }

        TuneAnalyticsVariable var = TuneManager.getInstance().getProfileManager().getCustomProfileVariable(variableName);
        if (var == null || var.getValue() == null) {
            return null;
        } else {
            return new BigDecimal(var.getValue());
        }
    }

    /**
     * Get the value associated with a custom location profile variable.
     * <br/>
     * Return the value stored for the custom profile variable. Must be called after the appropriate register call in {@link android.app.Application#onCreate()}.
     * <br/>
     * This will return null if the variable was registered without a default and has never been set, or if has been explicitly set as null.
     *
     * @param variableName Name of the custom profile variable.
     * @return Value stored for the variable. It may be null.
     */
    public TuneLocation getCustomProfileGeolocation(String variableName) {
        if (TuneManager.getProfileForUser("getCustomProfileGeolocation") == null) {
            return null;
        }

        TuneAnalyticsVariable var = TuneManager.getInstance().getProfileManager().getCustomProfileVariable(variableName);
        if (var == null) {
            return null;
        } else {
            return TuneAnalyticsVariable.stringToGeolocation(var.getValue());
        }
    }

    /**
     * Returns In-App Marketing's generated app ID value
     * @return App ID in In-App Marketing, or null if IAM was not enabled
     */
    public String getAppId() {
        if (TuneManager.getProfileForUser("getAppId") == null) {
            return null;
        }

        return TuneManager.getInstance().getProfileManager().getAppId();
    }

    // Clear

    /**
     * Unset the value for a user profile variable.<br/>
     * <br/>
     * Use this method to clear out the value for any custom user profile variable.
     * <br/>
     * This must be called after the associated register call.
     * <br/>
     * NOTE: This will not stop the variable from being registered again on the next {@link android.app.Application#onCreate()}.
     * <br/>
     */
    public void clearCustomProfileVariable(String variableName) {
        if (TuneManager.getProfileForUser("clearCustomProfileVariable") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().clearCertainCustomProfileVariable(variableName);
    }

    /**
     * Clear out all previously specified profile information.<br/>
     * <br/>
     * Use this method to clear out all custom profile variables.
     * <br/>
     * This will only clear out all profile variables that have been registered before this call.
     * <br/>
     * NOTE: This will not stop the variables from being registered again on the next {@link android.app.Application#onCreate()}.
     * <br/>
     */
    public void clearAllCustomProfileVariables() {
        if (TuneManager.getProfileForUser("clearAllCustomProfileVariables") == null) {
            return;
        }

        TuneManager.getInstance().getProfileManager().clearAllCustomProfileVariables();
    }
}
