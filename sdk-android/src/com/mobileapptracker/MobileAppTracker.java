package com.mobileapptracker;

import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.location.Location;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.Uri;
import android.util.Log;

/**
 * @author tony@hasoffers.com
 * @author john.gu@hasoffers.com
 */
public class MobileAppTracker {
    public static final int GENDER_MALE = 0;
    public static final int GENDER_FEMALE = 1;
    
    private final String IV = "heF9BATUfWuISyO8";
    
    // Interface for reading platform response to tracking calls
    protected MATResponse matResponse;
    // Interface for making url requests
    private MATUrlRequester urlRequester;
    // Encryptor for url
    private Encryption encryption;
    // Interface for testing URL requests
    protected MATTestRequest matRequest; // note: this has no setter - must subclass to set

    // Whether connectivity receiver is registered or not
    protected boolean isRegistered;
    // Whether to show debug output
    private boolean debugMode;
    // Whether preloaded attribution applies or not
    private boolean preLoaded;
    // Whether variables were initialized correctly
    protected boolean initialized;

    // Connectivity receiver
    protected BroadcastReceiver networkStateReceiver;
    // Parameters container
    protected Parameters params;
    // The context passed into the constructor
    protected Context mContext;
    // Thread pool for running the request Runnables
    private ExecutorService pool;
    // Thread pool for public method execution
    protected ExecutorService pubQueue;

    // Queue interface object for storing events that were not fired
    protected MATEventQueue eventQueue;
    
    private static volatile MobileAppTracker mat = null;

    protected MobileAppTracker() {
    }

    /**
     * Get existing MAT singleton object
     * @return MobileAppTracker instance
     */
    public static synchronized MobileAppTracker getInstance() {
        return mat;
    }

    /**
     * Initializes a MobileAppTracker.
     * @param context the application context
     * @param advertiserId the MAT advertiser ID for the app
     * @param conversionKey the MAT advertiser key for the app
     */
    public static void init(Context context, final String advertiserId, final String conversionKey) {
        mat = new MobileAppTracker();
        mat.mContext = context.getApplicationContext();
        mat.pubQueue = Executors.newSingleThreadExecutor();
        
        mat.pubQueue.execute(new Runnable() { public void run() { 
            mat.initAll(advertiserId, conversionKey);
        }});
    }
    
    /**
     * Private initialization function for MobileAppTracker.
     * @param advertiserId the MAT advertiser ID for the app
     * @param conversionKey the MAT conversion key for the app
     */
    protected void initAll(String advertiserId, String conversionKey) {
        Parameters.init(mContext, advertiserId, conversionKey);
        params = Parameters.getInstance();
        
        initLocalVariables(conversionKey);

        eventQueue = new MATEventQueue(mContext, mat);
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
        encryption = new Encryption(key.trim(), IV);
        
        initialized = false;
        isRegistered = false;
        debugMode = false;
        preLoaded = false;
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

    protected void addEventToQueue(String link, String data, JSONObject postBody, Date runDate) {
        pool.execute(eventQueue.new Add(link, data, postBody, runDate));
    }

    protected void dumpQueue() {
        if (!isOnline(mContext)) return;
        
        pool.execute(eventQueue.new Dump());
    }
    
    /**
     * Main session measurement function; this function should be called at every app open.
     */
    public void measureSession() {
        pubQueue.execute(new Runnable() { public void run() {
            measure("session", null, 0, getCurrencyCode(), getRefId(), null, null, false);
        }});
    }

    /**
     * measureSession call that bypasses already-sent check
     * and with post_conversion=1 for updating referrer value of existing MAT install
     */
    void measureInstallWithReferrer() {
        measure("install", null, 0, null, null, null, null, true);
    }

    /**
     * Event measurement function, by event name.
     * @param eventName event name in MAT system
     */
    public void measureAction(String eventName) {
        measureAction(eventName, null, 0, getCurrencyCode(), null, null, null);
    }
    
    /**
     * Event measurement function, by event name, revenue and currency.
     * @param eventName event name in MAT system
     * @param revenue revenue amount tied to the event
     * @param currency currency code for the revenue amount
     */
    public void measureAction(String eventName, double revenue, String currency) {
        measureAction(eventName, null, revenue, currency, null, null, null);
    }
    
    /**
     * Event measurement function, by event name, revenue, currency, and advertiser ref ID.
     * @param eventName event name in MAT system
     * @param revenue revenue amount tied to the event
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     */
    public void measureAction(String eventName, double revenue, String currency, String refId) {
        measureAction(eventName, null, revenue, currency, refId, null, null);
    }
    
    /**
     * Event measurement function, by event name, event items,
     *  revenue, currency, and advertiser ref ID.
     * @param eventName event name in MAT system
     * @param eventItems List of event items to associate with event
     * @param revenue revenue amount tied to the event
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     */
    public void measureAction(String eventName, List<MATEventItem> eventItems, double revenue, String currency, String refId) {
        measureAction(eventName, eventItems, revenue, currency, refId, null, null);
    }
    
    /**
     * Event measurement function
     * @param eventName event name in MAT system
     * @param eventItems List of event items to associate with event
     * @param revenue revenue amount tied to the event
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     * @param purchaseData the receipt data from Google Play
     * @param purchaseSignature the receipt signature from Google Play
     */
    public void measureAction(final String eventName, final List<MATEventItem> eventItems, final double revenue,
            final String currency, final String refId, final String purchaseData, final String purchaseSignature) {
        // Create a JSONArray of event items
        final JSONArray jsonArray = new JSONArray();
        if (eventItems != null) {
            for (int i = 0; i < eventItems.size(); i++) {
                jsonArray.put(eventItems.get(i).toJSON());
            }
        }

        pubQueue.execute(new Runnable() { public void run() { 
            measure(eventName, jsonArray, revenue, currency, refId, purchaseData, purchaseSignature, false);
        }});
    }
    
    /**
     * Event measurement function, by event ID.
     * @param eventId event ID in MAT system
     */
    public void measureAction(int eventId) {
        measureAction(eventId, null, 0, getCurrencyCode(), null, null, null);
    }
    
    /**
     * Event measurement function, by event ID, revenue and currency.
     * @param eventId event ID in MAT system
     * @param revenue revenue amount tied to the event
     * @param currency currency code for the revenue amount
     */
    public void measureAction(int eventId, double revenue, String currency) {
        measureAction(eventId, null, revenue, currency, null, null, null);
    }
    
    /**
     * Event measurement function, by event ID, revenue, currency, and advertiser ref ID.
     * @param eventId event ID in MAT system
     * @param revenue revenue amount tied to the event
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     */
    public void measureAction(int eventId, double revenue, String currency, String refId) {
        measureAction(eventId, null, revenue, currency, refId, null, null);
    }
    
    /**
     * Event measurement function, by event ID, event items,
     *  revenue, currency, and advertiser ref ID.
     * @param eventId event ID in MAT system
     * @param eventItems List of event items to associate with event
     * @param revenue revenue amount tied to the event
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     */
    public void measureAction(int eventId, List<MATEventItem> eventItems, double revenue, String currency, String refId) {
        measureAction(eventId, eventItems, revenue, currency, refId, null, null);
    }
    
    /**
     * Event measurement function
     * @param eventId event ID in MAT system
     * @param eventItems List of event items to associate with event
     * @param revenue revenue amount tied to the event
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     * @param purchaseData the receipt data from Google Play
     * @param purchaseSignature the receipt signature from Google Play
     */
    public void measureAction(final int eventId, final List<MATEventItem> eventItems, final double revenue,
            final String currency, final String refId, final String purchaseData, final String purchaseSignature) {
        // Create a JSONArray of event items
        final JSONArray jsonArray = new JSONArray();
        if (eventItems != null) {
            for (int i = 0; i < eventItems.size(); i++) {
                jsonArray.put(eventItems.get(i).toJSON());
            }
        }

        pubQueue.execute(new Runnable() { public void run() { 
            measure(eventId, jsonArray, revenue, currency, refId, purchaseData, purchaseSignature, false);
        }});
    }
    
    /**
     * Method calls a new action event based on class member settings.
     * @param event event name or event ID in MAT system
     * @param eventItems MATEventItem json data to post to the server
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     * @param inAppPurchaseData the receipt data from Google Play
     * @param inAppSignature the receipt signature from Google Play
     */
    private synchronized void measure(
                                   Object event,
                                   JSONArray eventItems,
                                   double revenue,
                                   String currency,
                                   String refId,
                                   String inAppPurchaseData,
                                   String inAppSignature,
                                   boolean postConversion
                                  ) {
        if (!initialized) return;
        
        dumpQueue();
        
        params.setAction("conversion"); // Default to conversion
        Date runDate = new Date();
        if (event instanceof String) {
            if (event.equals("close")) {
                return; // Don't send close events
            } else if (event.equals("open") || event.equals("install") || 
                    event.equals("update") || event.equals("session")) {
                // For post_conversion call, send action=install
                if (postConversion) {
                    params.setAction("install");
                } else {
                    params.setAction("session");
                }
                runDate = new Date(runDate.getTime() + MATConstants.DELAY);
            } else {
                params.setEventName((String)event);
            }
        } else if (event instanceof Integer) {
            params.setEventId(Integer.toString((Integer)event));
        } else {
            Log.d(MATConstants.TAG, "Received invalid event name or id value, not measuring event");
            return;
        }
        
        params.setRevenue(Double.toString(revenue));
        if (revenue > 0) {
            params.setIsPayingUser(Integer.toString(1));
        }
        
        params.setCurrencyCode(currency);
        params.setRefId(refId);
        
        String link = MATUrlBuilder.buildLink(debugMode, preLoaded, postConversion);
        String data = MATUrlBuilder.buildDataUnencrypted();
        JSONObject postBody = MATUrlBuilder.buildBody(eventItems, inAppPurchaseData, inAppSignature);
        
        if (matRequest != null) {
            matRequest.constructedRequest(link, data, postBody);
        }
        
        addEventToQueue(link, data, postBody, runDate);
        dumpQueue();
        
        if (matResponse != null) {
            matResponse.enqueuedActionWithRefId(refId);
        }
        
        // Clear the parameters that should be reset between events
        params.resetAfterRequest();
        
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
        
        JSONObject response = urlRequester.requestUrl(fullLink, postBody, debugMode);
        
        // The only way we get null from MATUrlRequester is if *our server* returned HTTP 400.
        // In that case, we should not retry this request.
        if (response == null) {
            if( matResponse != null ) {
                // null isn't the most useful error message, but at least it's a notification
                matResponse.didFailWithError(response);
            }
            return true; // request went through, don't retry
        }
        
        // if response is empty, it should be requeued
        if (!response.has("success")) {
            if (debugMode) Log.d(MATConstants.TAG, "Request failed, event will remain in queue");
            return false; // request failed to reach our server, retry
        }

        // notify matResponse of success or failure
        if (matResponse != null) {
            boolean success = false;
            try {
                if (response.getString("success").equals("true")) {
                    success = true;
                }
            } catch (JSONException e) {
                e.printStackTrace();
                return false; // request failed to reach our server, retry
            }

            if (success) {
                matResponse.didSucceedWithData(response);
            } else {
                matResponse.didFailWithError(response);
            }
        }

        // save open log id
        try {
            String eventType = response.getString("site_event_type");
            if (eventType.equals("open")) {
                String logId = response.getString("log_id");
                if (getOpenLogId() == null) {
                    params.setOpenLogId(logId);
                }
                params.setLastOpenLogId(logId);
            }
        } catch (JSONException e) {
        }
        
        // Output server response and accepted/rejected status for debug mode
        if (debugMode) {
            Log.d(MATConstants.TAG, "Server response: " + response.toString());
            if (response.length() > 0) {
                try {
                    // Read whether event was accepted or rejected
                    if (response.has("log_action") && !response.getString("log_action").equals("null")) {
                        JSONObject logAction = response.getJSONObject("log_action");
                        if (logAction.has("conversion")) {
                            JSONObject conversion = logAction.getJSONObject("conversion");
                            if (conversion.has("status")) {
                                String status = conversion.getString("status");
                                if (status.equals("rejected")) {
                                    String statusCode = conversion.getString("status_code");
                                    Log.d(MATConstants.TAG, "Event was rejected by server: status code " + statusCode);
                                } else {
                                    Log.d(MATConstants.TAG, "Event was accepted by server");
                                }
                            }
                        }
                    } else {
                        if (response.has("options")) {
                            JSONObject options = response.getJSONObject("options");
                            if (options.has("conversion_status")) {
                                String conversionStatus = options.getString("conversion_status");
                                Log.d(MATConstants.TAG, "Event was " + conversionStatus + " by server");
                            }
                        }
                    }
                } catch (JSONException e) {
                    Log.d(MATConstants.TAG, "Server response status could not be parsed");
                    e.printStackTrace();
                }
            }
        }
        
        return true; // request went through, don't retry
    }

    private void waitForParams() {
        Date maxWait = null;
        
        while (params == null) {
            // put this code inside the loop so it won't run at all if params != null
            if (maxWait == null) {
                maxWait = new Date(new Date().getTime() + 1000);
            }
            if (maxWait.before(new Date())) {
                Log.w(MATConstants.TAG, "after waiting 1 s, params is still null -- will probably lead to NullPointerException");
                break;
            }

            try {
                Thread.sleep(50);
            } catch (InterruptedException e) {
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
        waitForParams();
        return params.getAction();
    }

    /**
     * Gets the MAT advertiser ID.
     * @return MAT advertiser ID
     */
    public String getAdvertiserId() {
        waitForParams();
        return params.getAdvertiserId();
    }

    /**
     * Gets the user age set.
     * @return age
     */
    public int getAge() {
        waitForParams();
        return Integer.parseInt(params.getAge());
    }

    /**
     * Gets the device altitude. Must be set, not automatically retrieved.
     * @return device altitude
     */
    public double getAltitude() {
        waitForParams();
        return Double.parseDouble(params.getAltitude());
    }

    /**
     * Get whether the user has app-level ad tracking enabled or not.
     * @return app-level ad tracking enabled or not
     */
    public boolean getAppAdTrackingEnabled() {
        waitForParams();
        int adTrackingEnabled = Integer.parseInt(params.getAppAdTrackingEnabled());
        return (adTrackingEnabled == 1);
    }

    /**
     * Gets the app name
     * @return app name
     */
    public String getAppName() {
        waitForParams();
        return params.getAppName();
    }

    /**
     * Gets the app version
     * @return app version
     */
    public int getAppVersion() {
        waitForParams();
        return Integer.parseInt(params.getAppVersion());
    }

    /**
     * Gets the connection type (mobile or WIFI);.
     * @return whether device is connected by WIFI or mobile data connection
     */
    public String getConnectionType() {
        waitForParams();
        return params.getConnectionType();
    }

    /**
     * Gets the ISO 639-1 country code
     * @return ISO 639-1 country code
     */
    public String getCountryCode() {
        waitForParams();
        return params.getCountryCode();
    }

    /**
     * Gets the ISO 4217 currency code.
     * @return ISO 4217 currency code
     */
    public String getCurrencyCode() {
        waitForParams();
        return params.getCurrencyCode();
    }

    /**
     * Gets the device brand/manufacturer (HTC, Apple, etc)
     * @return device brand/manufacturer name
     */
    public String getDeviceBrand() {
        waitForParams();
        return params.getDeviceBrand();
    }

    /**
     * Gets the device model name
     * @return device model name
     */
    public String getDeviceModel() {
        waitForParams();
        return params.getDeviceModel();
    }

    /**
     * Gets the device carrier if any
     * @return mobile device carrier/service provider name
     */
    public String getDeviceCarrier() {
        waitForParams();
        return params.getDeviceCarrier();
    }

    /**
     * Get the first event attribute for the current action.
     * @return event attribute 1
     */
    public String getEventAttribute1() {
        waitForParams();
        return params.getEventAttribute1();
    }

    /**
     * Get the second event attribute for the current action.
     * @return event attribute 2
     */
    public String getEventAttribute2() {
        waitForParams();
        return params.getEventAttribute2();
    }

    /**
     * Get the third event attribute for the current action.
     * @return event attribute 3
     */
    public String getEventAttribute3() {
        waitForParams();
        return params.getEventAttribute3();
    }

    /**
     * Get the fourth event attribute for the current action.
     * @return event attribute 4
     */
    public String getEventAttribute4() {
        waitForParams();
        return params.getEventAttribute4();
    }

    /**
     * Get the fifth event attribute for the current action.
     * @return event attribute 5
     */
    public String getEventAttribute5() {
        waitForParams();
        return params.getEventAttribute5();
    }

    /**
     * Gets the last event id set.
     * @return event ID in MAT
     */
    public String getEventId() {
        waitForParams();
        return params.getEventId();
    }

    /**
     * Gets the last event name set.
     * @return event name in MAT
     */
    public String getEventName() {
        waitForParams();
        return params.getEventName();
    }

    /**
     * Gets value previously set of existing user or not.
     * @return whether user existed prior to install
     */
    public boolean getExistingUser() {
        waitForParams();
        int intExisting = Integer.parseInt(params.getExistingUser());
        return (intExisting == 1);
    }

    /**
     * Gets the Facebook user ID previously set.
     * @return Facebook user ID
     */
    public String getFacebookUserId() {
        waitForParams();
        return params.getFacebookUserId();
    }

    /**
     * Gets the user gender set.
     * @return gender 0 for male, 1 for female
     */
    public int getGender() {
        waitForParams();
        return Integer.parseInt(params.getGender());
    }

    /**
     * Gets the Google Play Services Advertising ID.
     * @return Google advertising ID
     */
    public String getGoogleAdvertisingId() {
        waitForParams();
        return params.getGoogleAdvertisingId();
    }

    /**
     * Gets whether use of the Google Play Services Advertising ID is limited by user request.
     * @return whether tracking is limited
     */
    public boolean getGoogleAdTrackingLimited() {
        waitForParams();
        int intLimited = Integer.parseInt(params.getGoogleAdTrackingLimited());
        return intLimited == 0? false : true;
    }

    /**
     * Gets the Google user ID previously set.
     * @return Google user ID
     */
    public String getGoogleUserId() {
        waitForParams();
        return params.getGoogleUserId();
    }

    /**
     * Gets the date of app install
     * @return date that app was installed, epoch seconds
     */
    public long getInstallDate() {
        waitForParams();
        return Long.parseLong(params.getInstallDate());
    }

    /**
     * Gets the MAT install log ID
     * @return MAT install log ID
     */
    public String getInstallLogId() {
        waitForParams();
        return params.getInstallLogId();
    }

    /**
     * Gets the Google Play INSTALL_REFERRER
     * @return Play INSTALL_REFERRER
     */
    public String getInstallReferrer() {
        waitForParams();
        return params.getInstallReferrer();
    }

    /**
     * Gets whether the user is revenue-generating or not
     * @return true if the user has produced revenue, false if not
     */
    public boolean getIsPayingUser() {
        waitForParams();
        String isPayingUser = params.getIsPayingUser();
        return isPayingUser.equals("1");
    }

    /**
     * Gets the language of the device
     * @return device language
     */
    public String getLanguage() {
        waitForParams();
        return params.getLanguage();
    }

    /**
     * Gets the last MAT open log ID
     * @return most recent MAT open log ID
     */
    public String getLastOpenLogId() {
        waitForParams();
        return params.getLastOpenLogId();
    }

    /**
     * Gets the device latitude. Must be set, not automatically retrieved.
     * @return device latitude
     */
    public double getLatitude() {
        waitForParams();
        return Double.parseDouble(params.getLatitude());
    }

    /**
     * Gets the device longitude. Must be set, not automatically retrieved.
     * @return device longitude
     */
    public double getLongitude() {
        waitForParams();
        return Double.parseDouble(params.getLongitude());
    }

    /**
     * Gets the MAT ID generated on install
     * @return MAT ID
     */
    public String getMatId() {
        waitForParams();
        return params.getMatId();
    }

    /**
     * Gets the mobile country code.
     * @return mobile country code associated with the carrier
     */
    public String getMCC() {
        waitForParams();
        return params.getMCC();
    }

    /**
     * Gets the mobile network code.
     * @return mobile network code associated with the carrier
     */
    public String getMNC() {
        waitForParams();
        return params.getMNC();
    }

    /**
     * Gets the first MAT open log ID
     * @return first MAT open log ID
     */
    public String getOpenLogId() {
        waitForParams();
        return params.getOpenLogId();
    }

    /**
     * Gets the Android OS version
     * @return Android OS version
     */
    public String getOsVersion() {
        waitForParams();
        return params.getOsVersion();
    }

    
    /**
     * Gets the app package name
     * @return package name of app
     */
    public String getPackageName() {
        waitForParams();
        return params.getPackageName();
    }

    /**
     * Get SDK plugin name used
     * @return name of MAT plugin
     */
    public String getPluginName() {
        waitForParams();
        return params.getPluginName();
    }

    /**
     * Gets the package name of the app that started this Activity, if any
     * @return source package name that caused open via StartActivityForResult
     */
    public String getReferralSource() {
        waitForParams();
        return params.getReferralSource();
    }

    /**
     * Gets the url scheme that started this Activity, if any
     * @return full url of app scheme that caused open
     */
    public String getReferralUrl() {
        waitForParams();
        return params.getReferralUrl();
    }

    /**
     * Gets the advertiser ref ID.
     * @return advertiser ref ID set by SDK
     */
    public String getRefId() {
        waitForParams();
        return params.getRefId();
    }

    /**
     * Gets the revenue amount set
     * @return revenue amount
     */
    public Double getRevenue() {
        waitForParams();
        return Double.parseDouble(params.getRevenue());
    }

    /**
     * Gets the screen density of the device
     * @return 0.75/1.0/1.5/2.0/3.0/4.0 for ldpi/mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi
     */
    public String getScreenDensity() {
        waitForParams();
        return params.getScreenDensity();
    }

    /**
     * Gets the screen height of the device in pixels
     * @return height
     */
    public String getScreenHeight() {
        waitForParams();
        return params.getScreenHeight();
    }

    /**
     * Gets the screen width of the device in pixels
     * @return width
     */
    public String getScreenWidth() {
        waitForParams();
        return params.getScreenWidth();
    }

    /**
     * Gets the MAT SDK version
     * @return MAT SDK version
     */
    public String getSDKVersion() {
        waitForParams();
        return params.getSdkVersion();
    }

    /**
     * Gets the MAT site ID set
     * @return site ID in MAT
     */
    public String getSiteId() {
        waitForParams();
        return params.getSiteId();
    }

    /**
     * Gets the TRUSTe ID set
     * @return TRUSTe ID
     */
    public String getTRUSTeId() {
        waitForParams();
        return params.getTRUSTeId();
    }

    /**
     * Gets the Twitter user ID previously set.
     * @return Twitter user ID
     */
    public String getTwitterUserId() {
        waitForParams();
        return params.getTwitterUserId();
    }

    /**
     * Gets the MAT update log ID
     * @return MAT update log ID
     */
    public String getUpdateLogId() {
        waitForParams();
        return params.getUpdateLogId();
    }

    /**
     * Gets the device browser user agent
     * @return device user agent
     */
    public String getUserAgent() {
        waitForParams();
        return params.getUserAgent();
    }

    /**
     * Gets the custom user email.
     * @return custom user email
     */
    public String getUserEmail() {
        waitForParams();
        return params.getUserEmail();
    }

    /**
     * Gets the custom user ID.
     * @return custom user id
     */
    public String getUserId() {
        waitForParams();
        return params.getUserId();
    }

    /**
     * Gets the custom user name.
     * @return custom user name
     */
    public String getUserName() {
        waitForParams();
        return params.getUserName();
    }

    /******************
     * Public Setters *
     ******************/


    /**
     * Sets the preloaded app's advertiser sub ad
     * @param subAd Preloaded advertiser sub ad
     */
    public void setAdvertiserSubAd(final String subAd) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setAdvertiserSubAd(subAd);
        }});
    }
    
    /**
     * Sets the preloaded app's advertiser sub adgroup
     * @param subAdgroup Preloaded advertiser sub adgroup
     */
    public void setAdvertiserSubAdgroup(final String subAdgroup) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setAdvertiserSubAdgroup(subAdgroup);
        }});
    }
    
    /**
     * Sets the preloaded app's advertiser sub campaign
     * @param subCampaign Preloaded advertiser sub campaign
     */
    public void setAdvertiserSubCampaign(final String subCampaign) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setAdvertiserSubCampaign(subCampaign);
        }});
    }
    
    /**
     * Sets the preloaded app's advertiser sub keyword
     * @param subKeyword Preloaded advertiser sub keyword
     */
    public void setAdvertiserSubKeyword(final String subKeyword) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setAdvertiserSubKeyword(subKeyword);
        }});
    }
    
    /**
     * Sets the preloaded app's advertiser sub publisher
     * @param subPublisher Preloaded advertiser sub publisher
     */
    public void setAdvertiserSubPublisher(final String subPublisher) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setAdvertiserSubPublisher(subPublisher);
        }});
    }
    
    /**
     * Sets the preloaded app's advertiser sub site
     * @param subSite Preloaded advertiser sub site
     */
    public void setAdvertiserSubSite(final String subSite) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setAdvertiserSubSite(subSite);
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
        pubQueue.execute(new Runnable() { public void run() {
            params.setAndroidId(androidId);
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
     * Sets the device IMEI/MEID
     * @param deviceId device IMEI/MEID
     */
    public void setDeviceId(final String deviceId) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setDeviceId(deviceId);
        }});
    }

    /**
     * Sets the content type associated with an app event.
     * @param contentType the content type
     */
    public void setEventContentType(final String contentType) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setEventContentType(contentType);
        }});
    }

    /**
     * Sets the content ID associated with an app event.
     * @param contentId the content ID
     */
    public void setEventContentId(final String contentId) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setEventContentId(contentId);
        }});
    }

    /**
     * Sets the level associated with an app event.
     * @param level the level
     */
    public void setEventLevel(final int level) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setEventLevel(Integer.toString(level));
        }});
    }

    /**
     * Sets the quantity associated with an app event.
     * @param quantity the quantity
     */
    public void setEventQuantity(final int quantity) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setEventQuantity(Integer.toString(quantity));
        }});
    }

    /**
     * Sets the search string associated with an app event.
     * @param searchString the search string
     */
    public void setEventSearchString(final String searchString) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setEventSearchString(searchString);
        }});
    }

    /**
     * Sets the rating associated with an app event.
     * @param rating the rating
     */
    public void setEventRating(final float rating) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setEventRating(Float.toString(rating));
        }});
    }

    /**
     * Sets the first date associated with an app event.
     * @param date the date
     */
    public void setEventDate1(final Date date) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setEventDate1(Long.toString(date.getTime()/1000)); // convert ms to s
        }});
    }

    /**
     * Sets the second date associated with an app event.
     * @param date the date
     */
    public void setEventDate2(final Date date) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setEventDate2(Long.toString(date.getTime()/1000)); // convert ms to s
        }});
    }

    /**
     * Sets the first attribute associated with an app event.
     * @param value the attribute
     */
    public void setEventAttribute1(final String value) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setEventAttribute1(value);
        }});
    }

    /**
     * Sets the second attribute associated with an app event.
     * @param value the attribute
     */
    public void setEventAttribute2(final String value) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setEventAttribute2(value);
        }});
    }

    /**
     * Sets the third attribute associated with an app event.
     * @param value the attribute
     */
    public void setEventAttribute3(final String value) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setEventAttribute3(value);
        }});
    }

    /**
     * Sets the fourth attribute associated with an app event.
     * @param value the attribute
     */
    public void setEventAttribute4(final String value) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setEventAttribute4(value);
        }});
    }

    /**
     * Sets the fifth attribute associated with an app event.
     * @param value the attribute
     */
    public void setEventAttribute5(final String value) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setEventAttribute5(value);
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
        pubQueue.execute(new Runnable() { public void run() { 
            params.setGoogleAdvertisingId(adId);
            params.setGoogleAdTrackingLimited(Integer.toString(intLimit));
        }});
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
     * Sets the device location.
     * @param location the device location
     */
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
     * @param response a MATResponse object that will be called when server request is complete
     */
    public void setMATResponse(MATResponse response) {
        matResponse = response;
    }

    /**
     * Sets the preloaded app's offer ID
     * @param offerId Preloaded offer ID
     */
    public void setOfferId(final String offerId) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setOfferId(offerId);
        }});
    }

    /**
     * Sets the app package name
     * @param package_name App package name
     */
    public void setPackageName(final String package_name) {
        pubQueue.execute(new Runnable() { public void run() { 
            if (package_name == null || package_name.equals("")) {
                params.setPackageName(mContext.getPackageName());
            } else {
                params.setPackageName(package_name);
            }
        }});
    }
    
    /**
     * Sets the preloaded app's publisher ID
     * @param publisherId Preloaded publisher ID
     */
    public void setPublisherId(final String publisherId) {
        // Publisher ID is required for preloaded attribution
        preLoaded = true;
        pubQueue.execute(new Runnable() { public void run() {
            params.setPublisherId(publisherId);
        }});
    }
    
    /**
     * Sets the preloaded app's publisher reference ID
     * @param publisherRefId Preloaded publisher reference ID
     */
    public void setPublisherReferenceId(final String publisherRefId) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setPublisherReferenceId(publisherRefId);
        }});
    }
    
    /**
     * Sets the preloaded app's publisher sub ad
     * @param subAd Preloaded publisher sub ad
     */
    public void setPublisherSubAd(final String subAd) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setPublisherSubAd(subAd);
        }});
    }
    
    /**
     * Sets the preloaded app's publisher sub adgroup
     * @param subAdgroup Preloaded publisher sub adgroup
     */
    public void setPublisherSubAdgroup(final String subAdgroup) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setPublisherSubAdgroup(subAdgroup);
        }});
    }
    
    /**
     * Sets the preloaded app's publisher sub campaign
     * @param subCampaign Preloaded publisher sub campaign
     */
    public void setPublisherSubCampaign(final String subCampaign) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setPublisherSubCampaign(subCampaign);
        }});
    }
    
    /**
     * Sets the preloaded app's publisher sub keyword
     * @param subKeyword Preloaded publisher sub keyword
     */
    public void setPublisherSubKeyword(final String subKeyword) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setPublisherSubKeyword(subKeyword);
        }});
    }
    
    /**
     * Sets the preloaded app's publisher sub publisher
     * @param subPublisher Preloaded publisher sub publisher
     */
    public void setPublisherSubPublisher(final String subPublisher) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setPublisherSubPublisher(subPublisher);
        }});
    }
    
    /**
     * Sets the preloaded app's publisher sub site
     * @param subSite Preloaded publisher sub site
     */
    public void setPublisherSubSite(final String subSite) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setPublisherSubSite(subSite);
        }});
    }
    
    /**
     * Sets the preloaded app's publisher sub1
     * @param sub1 Preloaded publisher sub1 value
     */
    public void setPublisherSub1(final String sub1) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setPublisherSub1(sub1);
        }});
    }
    
    /**
     * Sets the preloaded app's publisher sub2
     * @param sub2 Preloaded publisher sub2 value
     */
    public void setPublisherSub2(final String sub2) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setPublisherSub2(sub2);
        }});
    }
    
    /**
     * Sets the preloaded app's publisher sub3
     * @param sub3 Preloaded publisher sub3 value
     */
    public void setPublisherSub3(final String sub3) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setPublisherSub3(sub3);
        }});
    }
    
    /**
     * Sets the preloaded app's publisher sub4
     * @param sub4 Preloaded publisher sub4 value
     */
    public void setPublisherSub4(final String sub4) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setPublisherSub4(sub4);
        }});
    }
    
    /**
     * Sets the preloaded app's publisher sub5
     * @param sub5 Preloaded publisher sub5 value
     */
    public void setPublisherSub5(final String sub5) {
        pubQueue.execute(new Runnable() { public void run() {
            params.setPublisherSub5(sub5);
        }});
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
     * Sets the MAT site ID to specify which app to attribute to
     * @param site_id MAT site ID to attribute to
     */
    public void setSiteId(final String site_id) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setSiteId(site_id);
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
     * @param user_email
     */
    public void setUserEmail(final String user_email) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setUserEmail(user_email);
        }});
    }

    /**
     * Sets the custom user ID.
     * @param user_id the new user id
     */
    public void setUserId(final String user_id) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setUserId(user_id);
        }});
    }

    /**
     * Sets the custom user name.
     * @param user_name
     */
    public void setUserName(final String user_name) {
        pubQueue.execute(new Runnable() { public void run() { 
            params.setUserName(user_name);
        }});
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
    }

    /**
     * Turns debug mode on or off, under tag "MobileAppTracker".
     * @param debug whether to enable debug output
     */
    public void setDebugMode(final boolean debug) {
        pubQueue.execute(new Runnable() { public void run() { 
            debugMode = debug;
        }});
    }
}