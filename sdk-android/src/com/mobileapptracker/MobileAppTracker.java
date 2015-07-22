package com.mobileapptracker;

import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.accounts.Account;
import android.accounts.AccountManager;
import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.location.Location;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.util.Patterns;
import android.widget.Toast;

/**
 * @author tony@hasoffers.com
 * @author john.gu@hasoffers.com
 */
public class MobileAppTracker {
    private final String IV = "heF9BATUfWuISyO8";
    
    /* Protected fields needed for unit tests */
    // Connectivity receiver
    protected BroadcastReceiver networkStateReceiver;
    // The context passed into the constructor
    protected Context mContext;
    // Thread pool for public method execution
    protected ExecutorService pubQueue;
    // Queue interface object for storing events that were not fired
    protected MATEventQueue eventQueue;
    // Parameters container
    protected MATParameters params;
    // Interface for testing URL requests
    protected MATTestRequest tuneRequest; // note: this has no setter - must subclass to set
    
    protected MATUser mUser;
    // Whether variables were initialized correctly
    protected boolean initialized;
    // Whether connectivity receiver is registered or not
    protected boolean isRegistered;
    
    // Deferred deeplink helper class
    private MATDeferredDplinkr dplinkr;
    // Preloaded apps data values to send
    private MATPreloadData mPreloadData;
    
    // Interface for making url requests
    private MATUrlRequester urlRequester;
    // Encryptor for url
    private MATEncryption encryption;
    // Interface for reading platform response to tracking calls
    private MATResponse tuneListener;

    // Whether to show debug output
    private boolean debugMode;
    // Whether to open deferred deeplinks
    private boolean deferredDplink;
    // Max timeout to wait for deferred deeplink
    private int deferredDplinkTimeout;
    // If this is the first app install, try to find deferred deeplink
    private boolean firstInstall;
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
    
    private static volatile MobileAppTracker tune = null;

    protected MobileAppTracker() {
    }

    /**
     * Get existing TUNE singleton object
     * @return Tune instance
     */
    public static synchronized MobileAppTracker getInstance() {
        return tune;
    }

    /**
     * Initializes the TUNE SDK.
     * @param context the application context
     * @param advertiserId the TUNE advertiser ID for the app
     * @param conversionKey the TUNE advertiser key for the app
     * @return Tune instance with initialized values
     */
    public static synchronized MobileAppTracker init(Context context, final String advertiserId, final String conversionKey) {
        if (tune == null) {
            tune = new MobileAppTracker();
            tune.mContext = context.getApplicationContext();
            tune.pubQueue = Executors.newSingleThreadExecutor();
            tune.mUser = new MATUser();
            
            tune.initAll(advertiserId, conversionKey);
        }
        return tune;
    }
    
    /**
     * Private initialization function for TUNE SDK.
     * @param advertiserId the TUNE advertiser ID for the app
     * @param conversionKey the TUNE conversion key for the app
     */
    protected void initAll(String advertiserId, String conversionKey) {
        // Dplinkr init
        dplinkr = MATDeferredDplinkr.initialize(advertiserId, conversionKey, mContext.getPackageName());
        
        params = MATParameters.init(this, mContext, advertiserId, conversionKey);
        
        initLocalVariables(conversionKey);

        eventQueue = new MATEventQueue(mContext, this);
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
        urlRequester = new MATUrlRequester();
        encryption = new MATEncryption(key.trim(), IV);
        
        initTime = System.currentTimeMillis();
        gotReferrer = !(mContext.getSharedPreferences(MATConstants.PREFS_TUNE, Context.MODE_PRIVATE).getString(MATConstants.KEY_REFERRER, "").equals(""));
        firstInstall = false;
        firstSession = true;
        initialized = false;
        isRegistered = false;
        debugMode = false;
        fbLogging = false;
    }

    /**
     * Returns true if an Internet connection is detected.
     * @param context the app context to check connectivity from
     * @return whether Internet connection exists
     */
    public static boolean isOnline(Context context) {
        ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
        return activeNetworkInfo != null && activeNetworkInfo.isConnected();
    }

    protected void addEventToQueue(String link, String data, JSONObject postBody, boolean firstSession) {
        pool.execute(eventQueue.new Add(link, data, postBody, firstSession));
    }

    protected void dumpQueue() {
        if (!isOnline(mContext)) return;
        
        pool.execute(eventQueue.new Dump());
    }

    /**
     * Main session measurement function; this function should be called in onResume().
     */
    public void measureSession() {
        // If no SharedPreferences value for install exists, set it and mark firstInstall true
        SharedPreferences installed = mContext.getSharedPreferences(MATConstants.PREFS_TUNE, Context.MODE_PRIVATE);
        if (!installed.contains(MATConstants.KEY_INSTALL)) {
            installed.edit().putBoolean(MATConstants.KEY_INSTALL, true).commit();
            firstInstall = true;
        }

        notifiedPool = false;
        measureEvent(new MATEvent("session"));
    }
    
    /**
     * Event measurement function that measures an event for the given eventName.
     * @param eventName event name in TUNE system
     */
    public void measureEvent(String eventName) {
        measureEvent(new MATEvent(eventName));
    }
    
    /**
     * Event measurement function that measures an event for the given eventId.
     * @param eventId event ID in TUNE system
     */
    public void measureEvent(int eventId) {
        measureEvent(new MATEvent(eventId));
    }
    
    /**
     * Event measurement function that measures an event based on TuneEvent values.
     * Create a TuneEvent to pass in with:</br>
     * <pre>new TuneEvent(eventName)</pre>
     * @param eventData custom data to associate with the event
     */
    public void measureEvent(final MATEvent eventData) {
        pubQueue.execute(new Runnable() { public void run() {
            measure(eventData);
        }});
    }
    
    private synchronized void measure(MATEvent eventData) {
        if (!initialized) return;
        
        dumpQueue();
        
        params.setAction("conversion"); // Default to conversion
        Date runDate = new Date();
        if (eventData.getEventName() != null) {
            String eventName = eventData.getEventName();
            if (fbLogging) {
                MATFBBridge.logEvent(eventData);
            }
            if (eventName.equals("close")) {
                return; // Don't send close events
            } else if (eventName.equals("open") || eventName.equals("install") || 
                       eventName.equals("update") || eventName.equals("session")) {
                params.setAction("session");
                runDate = new Date(runDate.getTime() + MATConstants.DELAY);
            }
        }
        
        if (eventData.getRevenue() > 0) {
            if (mUser != null) {
                mUser.withPayingUser(true);
            }
        }
        
        String link = MATUrlBuilder.buildLink(eventData, mPreloadData, debugMode);
        String data = MATUrlBuilder.buildDataUnencrypted(eventData, mUser);
        JSONArray eventItemsJson = new JSONArray();
        if (eventData.getEventItems() != null) {
            for (int i = 0; i < eventData.getEventItems().size(); i++) {
                eventItemsJson.put(eventData.getEventItems().get(i).toJSON());
            }
        }
        JSONObject postBody = MATUrlBuilder.buildBody(eventItemsJson, eventData.getReceiptData(), eventData.getReceiptSignature(), params.getUserEmails());
        
        if (tuneRequest != null) {
            tuneRequest.constructedRequest(link, data, postBody);
        }
        
        addEventToQueue(link, data, postBody, firstSession);
        // Mark firstSession false
        firstSession = false;
        dumpQueue();
        
        if (tuneListener != null) {
            tuneListener.enqueuedActionWithRefId(eventData.getRefId());
        }
        
        return;
    }

    /**
     * Helper function for making single request and displaying response
     * @return true if request was sent successfully and should be removed from queue
     */
    protected boolean makeRequest(String link, String data, JSONObject postBody) {
        if (debugMode) Log.d(MATConstants.TAG, "Sending event to server...");
        
        String encData = MATUrlBuilder.updateAndEncryptData(data, encryption);
        String fullLink = link + "&data=" + encData;
        
        JSONObject response = MATUrlRequester.requestUrl(fullLink, postBody, debugMode);
        
        // The only way we get null from MATUrlRequester is if *our server* returned HTTP 400.
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
            if (debugMode) Log.d(MATConstants.TAG, "Request failed, event will remain in queue");
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
     * Gets the user age set.
     * @return age
     */
    public int getAge() {
        return Integer.parseInt(params.getAge());
    }

    /**
     * Gets the device altitude. Must be set, not automatically retrieved.
     * @return device altitude
     */
    public double getAltitude() {
        return Double.parseDouble(params.getAltitude());
    }

    /**
     * Gets the ANDROID_ID of the device
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
        int adTrackingEnabled = Integer.parseInt(params.getAppAdTrackingEnabled());
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
        return Integer.parseInt(params.getAppVersion());
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
     * Gets the user gender set.
     * @return gender 0 for male, 1 for female
     */
    public int getGender() {
        return Integer.parseInt(params.getGender());
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
        int intLimited = Integer.parseInt(params.getGoogleAdTrackingLimited());
        return intLimited == 0 ? false : true;
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
        return Long.parseLong(params.getInstallDate());
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
        return isPayingUser.equals("1");
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
     * Gets the device latitude. Must be set, not automatically retrieved.
     * @return device latitude
     */
    public double getLatitude() {
        return Double.parseDouble(params.getLatitude());
    }

    /**
     * Gets the device longitude. Must be set, not automatically retrieved.
     * @return device longitude
     */
    public double getLongitude() {
        return Double.parseDouble(params.getLongitude());
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
     * Gets the advertiser ref ID.
     * @return advertiser ref ID set by SDK
     */
    public String getRefId() {
        return params.getRefId();
    }

    /**
     * Gets the revenue amount set
     * @return revenue amount
     */
    public Double getRevenue() {
        return Double.parseDouble(params.getRevenue());
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
     * Gets the TUNE site ID set
     * @return site ID in TUNE
     */
    public String getSiteId() {
        return params.getSiteId();
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

    public MATUser getUser() {
        return mUser;
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
     * Sets the user's age.
     * @param age User age to track in MAT
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
        }
        // Params sometimes not initialized by the time GetGAID thread finishes
        if (params != null) {
            params.setAndroidId(androidId);
        }
        
        if (deferredDplink) {
            checkForDeferredDeeplink(deferredDplinkTimeout);
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
        pubQueue.execute(new Runnable() { public void run() { 
            if (adTrackingEnabled) {
                params.setAppAdTrackingEnabled(Integer.toString(1));
            } else {
                params.setAppAdTrackingEnabled(Integer.toString(0));
            }
        }});
    }

    /**
     * Sets the conversion key for the SDK
     * @param conversionKey TUNE conversion key
     */
    public void setConversionKey(final String conversionKey) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setConversionKey(conversionKey);
        }});
    }

    /**
     * Sets the ISO 4217 currency code.
     * @param currency_code the currency code
     */
    public void setCurrencyCode(final String currency_code) {
        pubQueue.execute(new Runnable() { public void run() { 
            if (currency_code == null || currency_code.equals("")) {
                params.setCurrencyCode(MATConstants.DEFAULT_CURRENCY_CODE);
            } else {
                params.setCurrencyCode(currency_code);
            }
        }});
    }
    
    /**
     * Sets the device brand, or manufacturer
     * @param deviceBrand device brand
     */
    public void setDeviceBrand(final String deviceBrand) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setDeviceBrand(deviceBrand);
        }});
    }

    /**
     * Sets the device IMEI/MEID
     * @param deviceId device IMEI/MEID
     */
    public void setDeviceId(final String deviceId) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setDeviceId(deviceId);
        }});
    }
    
    /**
     * Sets the device model
     * @param deviceModel device model
     */
    public void setDeviceModel(final String deviceModel) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setDeviceModel(deviceModel);
        }});
    }
    
    /**
     * Sets whether app was previously installed prior to version with MAT SDK
     * @param existing true if this user already had the app installed prior to updating to MAT version
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
     * @param fb_user_id
     */
    public void setFacebookUserId(final String fb_user_id) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setFacebookUserId(fb_user_id);
        }});
    }
    
    /**
     * Sets the user gender.
     * @param gender use MobileAppTracker.GENDER_MALE, MobileAppTracker.GENDER_FEMALE
     */
    public void setGender(final int gender) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setGender(Integer.toString(gender));
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
        
        if (deferredDplink) {
            checkForDeferredDeeplink(deferredDplinkTimeout);
        }
    }
    
    /**
     * Sets the user ID to associate with Google
     * @param google_user_id
     */
    public void setGoogleUserId(final String google_user_id) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setGoogleUserId(google_user_id);
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
    
    public void setLocation(final Location location) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setLocation(location);
        }});
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
     * Sets the device MAC address.
     * @param macAddress device MAC address
     */
    public void setMacAddress(final String macAddress) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setMacAddress(macAddress);
        }});
    }

    /**
     * Register a MATResponse interface to receive server response callback
     * @param listener a MATResponse object that will be called when server request is complete
     */
    public void setMATResponse(MATResponse listener) {
        tuneListener = listener;
        dplinkr.setListener(listener);
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
            if (packageName == null || packageName.equals("")) {
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
            // Regex remove all non-digits from phoneNumber
            String phoneNumberDigits = phoneNumber.replaceAll("\\D+", "");
            // Convert to digits from foreign characters if needed
            StringBuilder digitsBuilder = new StringBuilder();
            for (int i = 0; i < phoneNumberDigits.length(); i++) {
                int numberParsed = Integer.parseInt(String.valueOf(phoneNumberDigits.charAt(i)));
                digitsBuilder.append(numberParsed);
            }
            if (mUser != null) {
                mUser.withPhoneNumber(digitsBuilder.toString());
            }
        }});
    }
    
    /**
     * Sets publisher information for device preloaded apps
     * @param preloadData Preload app attribution data
     */
    public void setPreloadedApp(MATPreloadData preloadData) {
        mPreloadData = preloadData;
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
     * Sets the TUNE site ID to specify which app to attribute to
     * @param siteId TUNE site ID to attribute to
     */
    public void setSiteId(final String siteId) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setSiteId(siteId);
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
     * @param twitter_user_id
     */
    public void setTwitterUserId(final String twitter_user_id) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setTwitterUserId(twitter_user_id);
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

    public void setUser(MATUser user) {
        // Save auto-retrieved values if new ones don't exist
        boolean isPayingUser = user.getIsPayingUser() == false ? mUser.getIsPayingUser() : user.getIsPayingUser();
        String userEmail = user.getUserEmail() == null ? mUser.getUserEmail() : user.getUserEmail();
        String userId = user.getUserId() == null ? mUser.getUserId() : user.getUserId();
        String userName = user.getUserName() == null? mUser.getUserName() : user.getUserName();
        String phoneNumber = user.getPhoneNumber() == null? mUser.getPhoneNumber() : user.getPhoneNumber();
        
        mUser = user;
        // Restore previous values after setting user
        mUser.withPayingUser(isPayingUser)
             .withUserEmail(userEmail)
             .withUserId(userId)
             .withUserName(userName)
             .withPhoneNumber(phoneNumber);
    }

    /**
     * Set the name of plugin used, if any
     * @param plugin_name
     */
    public void setPluginName(final String plugin_name) {
        // Validate plugin name
        if (Arrays.asList(MATConstants.PLUGIN_NAMES).contains(plugin_name)) {
            pubQueue.execute(new Runnable() { public void run() { 
                params.setPluginName(plugin_name);
            }});
        } else {
            if (debugMode) {
                throw new IllegalArgumentException("Plugin name not acceptable");
            }
        }
    }

    /**
     * Enables acceptance of duplicate installs from this device.
     * @param allow whether to allow duplicate installs from device
     */
    public void setAllowDuplicates(final boolean allow) {
        pubQueue.execute(new Runnable() { public void run() { 
            if (allow) {
                params.setAllowDuplicates(Integer.toString(1));
            } else {
                params.setAllowDuplicates(Integer.toString(0));
            }
        }});
        if (allow) {
            Handler handler = new Handler(Looper.getMainLooper());
            handler.post(new Runnable() {
                public void run() {
                    Toast.makeText(mContext, "TUNE Allow Duplicate Requests Enabled, do not release with this enabled!!", Toast.LENGTH_LONG).show();
                }
            });
        }
    }

    /**
     * Turns debug mode on or off, under tag "MobileAppTracker".
     * @param debug whether to enable debug output
     */
    public void setDebugMode(final boolean debug) {
        debugMode = debug;
        pubQueue.execute(new Runnable() { public void run() {
            params.setDebugMode(debug);
        }});
        if (debug) {
            Handler handler = new Handler(Looper.getMainLooper());
            handler.post(new Runnable() {
                public void run() {
                    Toast.makeText(mContext, "TUNE Debug Mode Enabled, do not release with this enabled!!", Toast.LENGTH_LONG).show();
                }
            });
        }
    }
    
    /**
     * Enables or disables opening deferred deeplinks
     * @param enableDeferredDeeplink whether to open deferred deeplinks
     * @param timeout maximum timeout to wait for deeplink in ms
     */
    public void setDeferredDeeplink(boolean enableDeferredDeeplink, int timeout) {
        deferredDplink = enableDeferredDeeplink;
        deferredDplinkTimeout = timeout;
    }
    
    /**
     * Enables or disables primary Gmail address collection
     * Requires GET_ACCOUNTS permission
     * @param collectEmail whether to collect device email address
     */
    public void setEmailCollection(final boolean collectEmail) {
        pubQueue.execute(new Runnable() { public void run() {
            boolean accountPermission = (mContext.checkCallingOrSelfPermission(MATConstants.PERMISSION_GET_ACCOUNTS) == PackageManager.PERMISSION_GRANTED);
            if (collectEmail && accountPermission) {
                // Set primary Gmail address as user email
                Account[] accounts = AccountManager.get(mContext).getAccountsByType("com.google");
                if (accounts.length > 0) {
                    if (mUser != null) {
                        mUser.withUserEmail(accounts[0].name);
                    }
                }
                
                // Store the rest of email addresses
                HashMap<String, String> emailMap = new HashMap<String, String>();
                accounts = AccountManager.get(mContext).getAccounts();
                for (Account account : accounts) {
                    if (Patterns.EMAIL_ADDRESS.matcher(account.name).matches()) {
                        emailMap.put(account.name, account.type);
                    }
                }
                Set<String> emailKeys = emailMap.keySet();
                String[] emailArr = emailKeys.toArray(new String[emailKeys.size()]);
                params.setUserEmails(emailArr);
            }
        }});
    }
    
    /**
     * Whether to log TUNE events in the FB SDK as well
     * @param logging Whether to send TUNE events to FB as well
     * @param context Activity context
     * @param limitEventAndDataUsage Whether user opted out of ads targeting
     */
    public void setFacebookEventLogging(boolean logging, Context context, boolean limitEventAndDataUsage) {
        fbLogging = logging;
        if (logging) {
            MATFBBridge.startLogger(context, limitEventAndDataUsage);
        }
    }
    
    /**
     * Helper function to open a deferred deeplink if exists
     * @param timeout maximum timeout to wait for deeplink in ms
     */
    private String checkForDeferredDeeplink(int timeout) {
        if (firstInstall) {
            // Try to set user agent here after User Agent thread completed
            dplinkr.setUserAgent(params.getUserAgent());
            return dplinkr.checkForDeferredDeeplink(mContext, urlRequester, timeout);
        }
        return "";
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
}