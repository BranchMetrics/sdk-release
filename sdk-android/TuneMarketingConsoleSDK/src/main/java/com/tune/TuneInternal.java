package com.tune;

import android.Manifest;
import android.accounts.Account;
import android.accounts.AccountManager;
import android.annotation.SuppressLint;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.location.Location;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Patterns;
import android.widget.Toast;

import com.tune.http.TuneUrlRequester;
import com.tune.http.UrlRequester;
import com.tune.integrations.facebook.TuneFBBridge;
import com.tune.location.TuneLocationListener;
import com.tune.utils.TuneOptional;
import com.tune.utils.TuneStringUtils;
import com.tune.utils.TuneUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.lang.ref.WeakReference;
import java.security.InvalidParameterException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * @author andyp@tune.com
 * @author johng@tune.com
 */
public class TuneInternal implements ITune {
    private static final String IV = "heF9BATUfWuISyO8";

    // The context passed into the constructor
    final WeakReference<Context> mApplicationReference;
    // Thread pool for public method execution
    private ExecutorService pubQueue = null;
    // Queue interface object for storing events that were not fired
    protected TuneEventQueue eventQueue;
    // Location listener
    protected TuneLocationListener locationListener;
    // Parameters container
    protected TuneParameters params;
    // Interface for testing URL requests
    private TuneTestRequest tuneRequest;

    // Whether connectivity receiver is registered or not
    private boolean isRegistered;

    // Whether to collect location or not
    private boolean collectLocation;

    // Deferred deeplink helper class
    private TuneDeeplinker dplinkr;

    // Preloaded apps data values to send
    private TunePreloadData mPreloadData;

    // Interface for making url requests
    private UrlRequester urlRequester;
    // Encryptor for url
    private TuneEncryption encryption;
    // Interface for reading platform response to tracking calls
    private ITuneListener tuneListener;

    // Whether to show debug output
    private static boolean debugMode;

    // TODO: REFACTOR into FirstRun Logic
    // If this is the first session of the app lifecycle, wait for the advertising ID and referrer
    private boolean firstSession;

    // TODO: REFACTOR into FirstRun Logic
    // Is this the first install with the Tune SDK. This will be true for the entire first session.
    protected boolean isFirstInstall;

    // TODO: REFACTOR into FirstRun Logic
    // Time that SDK was initialized
    private long initTime;

    // TODO: REFACTOR into FirstRun Logic
    // Time SDK last measuredSession
    protected long timeLastMeasuredSession;

    // Whether we're invoking FB event logging
    private boolean fbLogging;

    // Thread pool for running the request Runnables
    private final ExecutorService pool;

    private static volatile TuneInternal sTuneInstance = null;

    // Container for FirstRun Logic
    final TuneFirstRunLogic firstRunLogic;

    protected TuneInternal(Context context) {
        if (context == null) {
            TuneDebugLog.e("Tune must be initialized with a valid context");
            throw new InvalidParameterException("Tune must be initialized with a valid context");
        }
        // Application Context is what the Tune SDK will use internally.
        Context applicationContext = context.getApplicationContext();

        mApplicationReference = new WeakReference<>(applicationContext);
        pool = Executors.newSingleThreadExecutor();
        firstRunLogic = new TuneFirstRunLogic();

        // Create a default TuneListener
        setListener(defaultTuneListener);
    }

    /**
     * Get existing TUNE singleton object.
     * @return Tune instance
     */
    public static synchronized TuneInternal getInstance() {
        return sTuneInstance;
    }

    /**
     * Wait for Initialization to complete.
     * @param milliseconds Number of milliseconds to wait for initialization to complete.
     * @return true if initialization completed in the time frame expected.
     */
    boolean waitForInit(long milliseconds) {
        return params.waitForInitComplete(milliseconds);
    }

    /**
     * Wait for the FirstRun startup sequence to complete.
     * This method is called exclusively by TuneEventQueue.
     * @param timeToWait Time to wait (in milliseconds)
     */
    void waitForFirstRunData(int timeToWait) {
        firstRunLogic.waitForFirstRunData(mApplicationReference.get(), timeToWait);
    }

    // Package Private
    void shutDown() {
        TuneDebugLog.d("Tune shutDown()");

        if (sTuneInstance != null) {
            firstRunLogic.cancel();

            synchronized (pool) {
                pool.notifyAll();
                pool.shutdown();
            }

            try {
                pool.awaitTermination(1, TimeUnit.SECONDS);

                // The executor is done, however it may have posted events.  It is difficult to know
                // when those are done, but without a sleep() here, they generally are *not* done.
                Thread.sleep(100);
            } catch (InterruptedException e) {
                TuneDebugLog.e("Error waiting for Pool Shutdown", e);
            }

            pubQueue.shutdownNow();
        } else {
            TuneDebugLog.d("Tune already shut down");
        }

        params.destroy();

        sTuneInstance = null;
        TuneDebugLog.d("Tune shutDown() complete");
    }

    /**
     * Public constructor.
     */
    static synchronized ITune initAll(Context context, String advertiserId, String conversionKey, String packageName) {
        // A valid Context is required to initialize Tune.
        if (context == null) {
            TuneDebugLog.e("Invalid Parameter: Context cannot be null.");
            return null;
        }

        return initAll(new TuneInternal(context), advertiserId, conversionKey, packageName);
    }

    /**
     * Internal constructor.
     *
     * @param tune TuneInternal
     * @param advertiserId String
     * @param conversionKey String
     * @param packageName String
     *
     * @return ITUne interface
     */
    protected static synchronized ITune initAll(TuneInternal tune, String advertiserId, String conversionKey, String packageName) {
        // A valid Context is required to initialize Tune.
        if (sTuneInstance == null) {
            sTuneInstance = tune;

            sTuneInstance.pubQueue = Executors.newSingleThreadExecutor();
            sTuneInstance.initLocal(advertiserId, conversionKey, packageName);

            // Location listener init (default to true)
            sTuneInstance.locationListener = new TuneLocationListener(sTuneInstance.mApplicationReference.get());

            TuneDebugLog.alwaysLog("Initializing Tune Version " + Tune.getSDKVersion());
        } else {
            TuneDebugLog.i("Tune Already Initialized");
        }
        return sTuneInstance;
    }

    private void initLocal(String advertiserId, String conversionKey, String packageName) {
        Context context = mApplicationReference.get();

        // Dplinkr init
        dplinkr = new TuneDeeplinker(advertiserId, conversionKey, context.getPackageName());

        // Get app package information if it is missing
        if (TuneStringUtils.isNullOrEmpty(packageName)) {
            packageName = context.getPackageName();
        }

        params = TuneParameters.init(this, context, advertiserId, conversionKey, packageName);

        // Apply the package name to the rest of the SDK
        applyPackageName(packageName);

        initLocalVariables(conversionKey);

        eventQueue = new TuneEventQueue(context, this);

        // Set up connectivity listener so we dump the queue when re-connected to Internet
        BroadcastReceiver networkStateReceiver = new BroadcastReceiver() {
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
                context.unregisterReceiver(networkStateReceiver);
            } catch (java.lang.IllegalArgumentException e) {
                TuneDebugLog.d("Invalid state.", e);
            }
            isRegistered = false;
        }

        IntentFilter filter = new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION);
        context.registerReceiver(networkStateReceiver, filter);
        isRegistered = true;

        if (!params.hasInstallFlagBeenSet()) {
            isFirstInstall = true;
            params.setInstallFlag();
        }
    }

    /**
     * Initialize class variables.
     * @param key the conversion key
     */
    private void initLocalVariables(String key) {
        urlRequester = new TuneUrlRequester();
        encryption = new TuneEncryption(key.trim(), IV);

        initTime = System.currentTimeMillis();
        firstSession = true;
        isRegistered = false;
        fbLogging = false;
        collectLocation = true;
    }

    /**
     * Returns true if an Internet connection is detected.
     * @return whether Internet connection exists
     */
    protected synchronized boolean isOnline() {
        Context context = mApplicationReference.get();

        if (context != null) {
            ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);

            if (connectivityManager != null) {
                NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
                return activeNetworkInfo != null && activeNetworkInfo.isConnected();
            }
        }
        return false;
    }

    protected ExecutorService getPubQueue() {
        return pubQueue;
    }

    /**
     * Helper method to obtain the Account Manager for the provided context
     * @param context Context
     * @return an Account Manager
     */
    protected AccountManager getAccountManager(Context context) {
        return AccountManager.get(context);
    }

    protected synchronized void addEventToQueue(String link, String data, JSONObject postBody, boolean firstSession) {
        synchronized (pool) {
            if (pool.isShutdown()) {
                return;
            }

            pool.execute(eventQueue.new Add(link, data, postBody, firstSession));
        }
    }

    protected synchronized void dumpQueue() {
        if (!isOnline()) {
            return;
        }

        synchronized (pool) {
            if (pool.isShutdown()) {
                return;
            }

            pool.execute(eventQueue.new Dump());
        }
    }

    /**
     * Measure new session.
     * Tune Android SDK plugins may use this method to trigger session measurement events.
     * This should be called in the equivalent of onResume().
     */
    public void measureSessionInternal() {
        timeLastMeasuredSession = System.currentTimeMillis();
        measureEvent(new TuneEvent(TuneEvent.NAME_SESSION));
        if (debugMode) {
            Handler handler = new Handler(Looper.getMainLooper());
            handler.post(new Runnable() {
                public void run() {
                    Toast.makeText(mApplicationReference.get(), "TUNE measureSession called", Toast.LENGTH_LONG).show();
                }
            });
        }
    }

    /**
     * Get the time the Tune SDK last measured a new session. This value may not update each time the app is foregrounded.
     * @return time of last session measurement in milliseconds (System time).
     */
    public long getTimeLastMeasuredSession() {
        return timeLastMeasuredSession;
    }

    /**
     * Allow (internal) access to setting the Tune Listener
     *
     * @param listener ITuneListener
     */
    public void setListener(ITuneListener listener) {
        tuneListener = listener;
    }

    protected void setTestRequest(final TuneTestRequest request) {
        tuneRequest = request;
    }

    /**
     * Event measurement function that measures an event for the given eventName.
     * @param eventName event name in TUNE system.  The eventName parameter cannot be null or empty
     */
    @Override
    public void measureEvent(@NonNull String eventName) {
        try {
            measureEvent(new TuneEvent(eventName));
        } catch (IllegalArgumentException e) {
            TuneDebugLog.e("measureEvent() " + e.getMessage());
            if (debugMode) {
                throw e;
            }
        }
    }

    /**
     * Event measurement function that measures an event based on TuneEvent values.
     * Create a TuneEvent to pass in with:<br>
     * <pre>new TuneEvent(eventName)</pre>
     * @param eventData custom data to associate with the event
     */
    @Override
    public void measureEvent(final TuneEvent eventData) {
        updateLocation();

        measure(eventData);
    }

    private void runQueue(String tag, Runnable runnable) {
        if (pubQueue != null) {
            TuneDebugLog.d("Run Queue: " + tag);
            pubQueue.execute(runnable);
        } else {
            TuneDebugLog.e("Run Queue NULL: " + tag);
        }

    }

    private void measureTuneLinkClick(final String clickedTuneLinkUrl) {
        // Go Asynchronous
        runQueue("measureTuneLinkClick", new Runnable() {
            public void run() {
                String link = TuneUrlBuilder.appendTuneLinkParameters(params, clickedTuneLinkUrl);
                String data = "";
                JSONObject postBody = new JSONObject();

                if (tuneRequest != null) {
                    tuneRequest.constructedRequest(link, data, postBody);
                }

                // Send the Tune Link click request immediately
                makeRequest(link, data, postBody);
            }
        });
    }

    private synchronized void measure(final TuneEvent eventData) {
        // Go Asynchronous
        runQueue("measure", new Runnable() {
            public void run() {
                if (sTuneInstance == null) {
                    TuneDebugLog.e("TUNE is not initialized");
                    return;
                }

                dumpQueue();

                params.setAction(TuneParameters.ACTION_CONVERSION); // Default to conversion
                if (eventData.getEventName() != null) {
                    String eventName = eventData.getEventName();
                    if (fbLogging) {
                        TuneFBBridge.logEvent(params, eventData);
                    }
                    if (TuneEvent.NAME_CLOSE.equals(eventName)) {
                        return; // Don't send close events
                    } else if (TuneEvent.NAME_OPEN.equals(eventName)
                            || TuneEvent.NAME_INSTALL.equals(eventName)
                            || TuneEvent.NAME_UPDATE.equals(eventName)
                            || TuneEvent.NAME_SESSION.equals(eventName)) {
                        params.setAction(TuneParameters.ACTION_SESSION);
                    }
                }

                if (eventData.getRevenue() > 0) {
                    params.setPayingUser(TuneConstants.PREF_SET);
                }

                String link = TuneUrlBuilder.buildLink(params, eventData, mPreloadData, debugMode);
                String data = TuneUrlBuilder.buildDataUnencrypted(params, eventData);
                JSONArray eventItemsJson = new JSONArray();
                if (eventData.getEventItems() != null) {
                    for (int i = 0; i < eventData.getEventItems().size(); i++) {
                        eventItemsJson.put(eventData.getEventItems().get(i).toJson());
                    }
                }
                JSONObject postBody =
                        TuneUrlBuilder.buildBody(eventItemsJson, eventData.getReceiptData(), eventData.getReceiptSignature());

                if (tuneRequest != null) {
                    tuneRequest.constructedRequest(link, data, postBody);
                }

                addEventToQueue(link, data, postBody, firstSession);
                // Mark firstSession false
                firstSession = false;
                dumpQueue();
            }
        });
    }

    /**
     * Helper function for making single request and displaying response.
     * @param link Url address
     * @param data Url link data
     * @param postBody Url post body
     * @return true if request was sent successfully and should be removed from queue
     */
    protected boolean makeRequest(String link, String data, JSONObject postBody) {
        TuneDebugLog.d("Sending event to server...");

        final boolean removeRequestFromQueue = true;
        final boolean retryRequestInQueue = false;

        if (link == null) { // This is an internal method and link should always be set, but for customer stability we will prevent NPEs
            TuneDebugLog.e("CRITICAL internal Tune request link is null");
            safeReportFailureToTuneListener("", "Internal Tune request link is null");
            return removeRequestFromQueue;
        }

        updateLocation(); // If location not set before sending, try to get location again

        String encData = TuneUrlBuilder.updateAndEncryptData(params, data, encryption);
        String fullLink = link + "&data=" + encData;

        if (tuneListener != null) {
            tuneListener.enqueuedRequest(fullLink, postBody);
        }

        JSONObject response = urlRequester.requestUrl(fullLink, postBody, debugMode);

        if (response == null) { // The only way we get null from TuneUrlRequester is if *our server* returned HTTP 400. Do not retry.
            safeReportFailureToTuneListener(fullLink, "Error 400 response from Tune");
            return removeRequestFromQueue;
        }

        if (!response.has(TuneConstants.SERVER_RESPONSE_SUCCESS)) { // if response is empty, it should be requeued
            TuneDebugLog.e("Request failed, event will remain in queue");
            safeReportFailureToTuneListener(fullLink, response);
            return retryRequestInQueue;
        }

        checkForExpandedTuneLinks(link, response);

        // notify tuneListener of success or failure
        boolean success;
        try {
            success = response.getBoolean(TuneConstants.SERVER_RESPONSE_SUCCESS);
        } catch (JSONException e) {
            TuneDebugLog.e("Error parsing response " + response + " to check for success", e);
            safeReportFailureToTuneListener(fullLink, response);
            return retryRequestInQueue;
        }

        safeReportSuccessOrFailureToTuneListener(fullLink, response, success);
        saveOpenLogId(response);

        return removeRequestFromQueue;
    }

    private void safeReportSuccessOrFailureToTuneListener(String url, JSONObject response, boolean success) {
        if (success) {
            safeReportSuccessToTuneListener(url, response);
        } else {
            safeReportFailureToTuneListener(url, response);
        }
    }

    private void safeReportSuccessToTuneListener(String url, JSONObject response) {
        if (tuneListener != null) {
            tuneListener.didSucceedWithData(url, response);
        }
    }

    private void safeReportFailureToTuneListener(String url, JSONObject response) {
        if (tuneListener != null) {
            tuneListener.didFailWithError(url, response);
        }
    }

    private void safeReportFailureToTuneListener(String url, String errorMessage) {
        Map<String, String> errors = new HashMap<>();
        errors.put("error", errorMessage);
        safeReportFailureToTuneListener(url, new JSONObject(errors));
    }

    private void saveOpenLogId(JSONObject response) {
        try {
            String eventType = response.optString("site_event_type");
            if ("open".equals(eventType)) {
                String logId = response.getString("log_id");
                if ("".equals(getOpenLogId())) {
                    params.setOpenLogId(logId);
                }
                params.setLastOpenLogId(logId);
            }
        } catch (JSONException e) {
            TuneDebugLog.e("Error parsing response " + response + " to save open log id", e);
        }
    }

    private void checkForExpandedTuneLinks(String link, JSONObject response) {
        try {
            if (isTuneLinkMeasurementRequest(link) && !isInvokeUrlParameterInReferralUrl()) {
                if (response.has(TuneConstants.KEY_INVOKE_URL)) {
                    dplinkr.handleExpandedTuneLink(response.getString(TuneConstants.KEY_INVOKE_URL));
                } else {
                    dplinkr.handleFailedExpandedTuneLink("There is no invoke url for this Tune Link");
                }
            }
        } catch (JSONException e) {
            TuneDebugLog.e("Error parsing response " + response + " to check for invoke url", e);
        }
    }

    private boolean isInvokeUrlParameterInReferralUrl() {
        return invokeUrlFromReferralUrl(params.getReferralUrl()).isPresent();
    }

    private boolean isTuneLinkMeasurementRequest(String link) {
        return link.contains(TuneUrlKeys.ACTION + "=" + TuneParameters.ACTION_CLICK);
    }

    protected TuneOptional<String> invokeUrlFromReferralUrl(String referralUrl) {
        String invokeUrl = null;
        try {
            Uri clickedLink = Uri.parse(referralUrl);
            invokeUrl = clickedLink.getQueryParameter(TuneConstants.KEY_INVOKE_URL);
        } catch (Exception e) {
            TuneDebugLog.e("Error looking for invoke_url in referral url: " + referralUrl, e);
        }
        return TuneOptional.ofNullable(invokeUrl);
    }

    /**
     * Update Location if autocollect is enabled.
     * If location autocollect is enabled, tries to get latest location from TuneLocationListener,
     * triggering an update if needed
     */
    private void updateLocation() {
        if (collectLocation && locationListener != null) {
            Location lastLocation = locationListener.getLastLocation();
            if (lastLocation != null) {
                params.setLocation(lastLocation);
            }
        }
    }

    /* ========================================================================================== */
    /* Public Getters                                                                             */
    /* ========================================================================================== */

    @Override
    public String getAction() {
        return params.getAction();
    }

    @Override
    public String getAdvertiserId() {
        return params.getAdvertiserId();
    }

    @Override
    public int getAge() {
        return params.getAgeNumeric();
    }

    @Override
    public String getAndroidId() {
        return params.getAndroidId();
    }

    @Override
    public boolean getAppAdTrackingEnabled() {
        return params.getAppAdTrackingEnabled();
    }

    @Override
    public String getAppName() {
        return params.getAppName();
    }

    @Override
    public int getAppVersion() {
        String appVersionString = params.getAppVersion();
        int appVersion = 0;
        if (appVersionString != null) {
            try {
                appVersion = Integer.parseInt(appVersionString);
            } catch (NumberFormatException e) {
                TuneDebugLog.e("Error parsing appVersion value " + appVersionString, e);
            }

        }
        return appVersion;
    }

    @Override
    public String getConnectionType() {
        return params.getConnectionType();
    }

    @Override
    public String getCountryCode() {
        return params.getCountryCode();
    }

    @Override
    public String getDeviceBrand() {
        return params.getDeviceBrand();
    }

    @Override
    public String getDeviceBuild() {
        return params.getDeviceBuild();
    }

    @Override
    public String getDeviceCarrier() {
        return params.getDeviceCarrier();
    }

    @Override
    public String getDeviceId() {
        return params.getDeviceId();
    }

    @Override
    public String getDeviceModel() {
        return params.getDeviceModel();
    }

    @Override
    public boolean getExistingUser() {
        int intExisting = Integer.parseInt(params.getExistingUser());
        return (intExisting == 1);
    }

    @Override
    public String getFacebookUserId() {
        return params.getFacebookUserId();
    }

    @Override
    public TuneGender getGender() {
        String gender = params.getGender();
        if (gender == null) {
            return TuneGender.UNKNOWN;
        }
        switch (gender) {
            case TuneGender.MALE_STRING_VAL:
                return TuneGender.MALE;
            case TuneGender.FEMALE_STRING_VAL:
                return TuneGender.FEMALE;
            default:
                return TuneGender.UNKNOWN;
        }
    }

    @Override
    public String getGoogleUserId() {
        return params.getGoogleUserId();
    }

    @Override
    public long getInstallDate() {
        String installDateString = params.getInstallDate();
        long installDate = 0L;
        if (installDateString != null) {
            try {
                installDate = Long.parseLong(installDateString);
            } catch (NumberFormatException e) {
                TuneDebugLog.e("Error parsing installDate value " + installDateString, e);
            }
        }
        return installDate;
    }

    @Override
    public String getInstallReferrer() {
        return params.getInstallReferrer();
    }

    @Override
    public boolean isPayingUser() {
        return TuneConstants.PREF_SET.equals(params.isPayingUser());
    }

    @Override
    public boolean isPrivacyProtectedDueToAge() {
        return params.isPrivacyProtectedDueToAge();
    }

    @Override
    public String getLanguage() {
        return params.getLanguage();
    }

    @Override
    public String getLocale() {
        return params.getLocale();
    }

    @Override
    public Location getLocation() {
        return params.getLocation();
    }

    @Override
    public String getMatId() {
        return params.getMatId();
    }

    @Override
    public String getMCC() {
        return params.getMCC();
    }

    @Override
    public String getMNC() {
        return params.getMNC();
    }

    @Override
    public String getOpenLogId() {
        return params.getOpenLogId();
    }

    @Override
    public String getOsVersion() {
        return params.getOsVersion();
    }

    @Override
    public String getPackageName() {
        return params.getPackageName();
    }

    @Override
    public boolean getPlatformAdTrackingLimited() {
        return params.getPlatformAdTrackingLimited();
    }

    @Override
    public String getPlatformAdvertisingId() {
        return params.getPlatformAdvertisingId();
    }

    @Override
    public String getReferralUrl() {
        return params.getReferralUrl();
    }

    @Override
    public String getScreenDensity() {
        return params.getScreenDensity();
    }

    @Override
    public String getScreenHeight() {
        return params.getScreenHeight();
    }

    @Override
    public String getScreenWidth() {
        return params.getScreenWidth();
    }

    @Override
    public String getTwitterUserId() {
        return params.getTwitterUserId();
    }

    @Override
    public String getUserAgent() {
        return params.getUserAgent();
    }

    @Override
    public String getUserEmail() {
        return params.getUserEmail();
    }

    @Override
    public String getUserId() {
        return params.getUserId();
    }

    @Override
    public String getUserName() {
        return params.getUserName();
    }


    /* ========================================================================================== */
    /* Public Setters                                                                             */
    /* ========================================================================================== */

    @Override
    public void setAge(int age) {
        params.setAge(Integer.toString(age));
    }

    public void setAndroidId(String androidId) {
        // Params sometimes not initialized by the time GetAdvertisingId thread finishes
        if (params != null) {
            params.setAndroidId(androidId);
            if (dplinkr != null) {
                dplinkr.setAndroidId(androidId);
                requestDeferredDeeplink();
            }
        }
    }

    @Override
    public void setAppAdTrackingEnabled(boolean adTrackingEnabled) {
        if (adTrackingEnabled) {
            params.setAppAdTrackingEnabled(TuneConstants.PREF_SET);
        } else {
            params.setAppAdTrackingEnabled(TuneConstants.PREF_UNSET);
        }
    }

    @Override
    public void setExistingUser(boolean existing) {
        if (existing) {
            params.setExistingUser(TuneConstants.PREF_SET);
        } else {
            params.setExistingUser(TuneConstants.PREF_UNSET);
        }
    }

    @Override
    public void setFacebookUserId(String userId) {
        params.setFacebookUserId(userId);
    }

    public void setFireAdvertisingId(String adId, boolean isLATEnabled) {
        final int intLimit = isLATEnabled ? 1 : 0;

        if (params != null) {
            params.setFireAdvertisingId(adId);
            params.setFireAdTrackingLimited(Integer.toString(intLimit));
        }
        setPlatformAdvertisingId(adId, isLATEnabled);
    }

    @Override
    public void setGender(final TuneGender gender) {
        params.setGender(gender);
    }

    public void setGoogleAdvertisingId(String adId, boolean isLATEnabled) {
        final int intLimit = isLATEnabled ? 1 : 0;

        if (params != null) {
            params.setGoogleAdvertisingId(adId);
            params.setGoogleAdTrackingLimited(Integer.toString(intLimit));
        }
        setPlatformAdvertisingId(adId, isLATEnabled);
    }

    @Override
    public void setGoogleUserId(String userId) {
        params.setGoogleUserId(userId);
    }

    @Override
    public void setInstallReferrer(String referrer) {
        // Record when referrer was received
        // TODO: REFACTOR into FirstRun Logic
        long referrerTime = System.currentTimeMillis();
        if (params != null) {
            params.setReferrerDelay(referrerTime - initTime);
            params.setInstallReferrer(referrer);
        }
    }

    @Override
    public void setPayingUser(boolean isPayingUser) {
        params.setPayingUser(isPayingUser ? TuneConstants.PREF_SET : TuneConstants.PREF_UNSET);
    }

    @Override
    public void setLocation(final Location location) {
        disableLocationAutoCollection();
        params.setLocation(location);
    }

    @Override
    public void setLocation(double latitude, double longitude, double altitude) {
        disableLocationAutoCollection();
        params.setLocation(latitude, longitude, altitude);
    }

    /**
     * Sets the device OS version.
     * @param osVersion device OS version
     */
    void setOsVersion(String osVersion) {
        params.setOsVersion(osVersion);
    }

    private void applyPackageName(String packageName) {
        dplinkr.setPackageName(packageName);
    }

    @Override
    public void setPhoneNumber(String phoneNumber) {
        params.setPhoneNumber(phoneNumber);
    }

    /**
     * Sets the Platform Advertising ID.
     * @param adId Advertising ID
     * @param isLATEnabled whether user has enabled limit ad tracking
     */
    void setPlatformAdvertisingId(String adId, boolean isLATEnabled) {
        final int intLimit = isLATEnabled ? 1 : 0;

        if (params != null) {
            params.setPlatformAdvertisingId(adId);
            params.setPlatformAdTrackingLimited(Integer.toString(intLimit));

            if (dplinkr != null) {
                dplinkr.setPlatformAdvertisingId(adId, intLimit);
                requestDeferredDeeplink();
            }
        }
        firstRunLogic.receivedAdvertisingId();
    }

    @Override
    public void setPreloadedAppData(final TunePreloadData preloadData) {
        mPreloadData = preloadData;
    }

    @Override
    public boolean setPrivacyProtectedDueToAge(boolean isPrivacyProtected) {
        int currentAge = getAge();

        // You cannot turn "off" privacy protection if age is within the COPPA boundary
        if (currentAge > 0 && currentAge < TuneConstants.COPPA_MINIMUM_AGE) {
            if (!isPrivacyProtected) {
                return false;
            }
        }

        // You can, however, turn "on" privacy protection regardless of age.
        params.setPrivacyExplicitlySetAsProtected(isPrivacyProtected);
        return true;
    }

    public void setReferralCallingPackage(@Nullable String referralCallingPackage) {
        params.setReferralSource(referralCallingPackage);
    }

    @Override
    public void setReferralUrl(String url) {
        params.setReferralUrl(url);

        if (url != null && isTuneLink(url)) {
            try {
                // In case the tune link already contains an invoke_url, short circuit and call the deeplink listener
                TuneOptional<String> invokeUrl = invokeUrlFromReferralUrl(url);
                if (invokeUrl.isPresent()) {
                    dplinkr.handleExpandedTuneLink(invokeUrl.get());
                }
            } catch (Exception e) {
                dplinkr.handleFailedExpandedTuneLink("Error accessing invoke_url from clicked Tune Link");
            } finally {
                measureTuneLinkClick(url);
            }
        }
    }

    @Override
    public void setTwitterUserId(String userId) {
        params.setTwitterUserId(userId);
    }

    @Override
    public void setUserEmail(String userEmail) {
        params.setUserEmail(userEmail);
    }

    public void setUserEmails(String[] userEmails) {
        // Obsolete
    }

    @Override
    public void setUserId(String userId) {
        params.setUserId(userId);
    }

    @Override
    public void setUserName(String userName) {
        params.setUserName(userName);
    }

    public void setPluginName(String pluginName) {
        // Validate plugin name
        if (Arrays.asList(TuneConstants.PLUGIN_NAMES).contains(pluginName)) {
            params.setPluginName(pluginName);
        } else {
            if (debugMode) {
                throw new IllegalArgumentException("Plugin name not acceptable");
            }
        }
    }

    static void setDebugMode(boolean debug) {
        debugMode = debug;

        if (debug) {
            TuneDebugLog.enableLog();
            TuneDebugLog.setLogLevel(TuneDebugLog.Level.DEBUG);
        } else {
            TuneDebugLog.disableLog();
            TuneDebugLog.setLogLevel(TuneDebugLog.Level.INFO);
        }
    }

    /**
     * Checks the current status of debug mode.
     * @return Whether debug mode is on or off.
     */
    public static boolean isInDebugMode() {
        return debugMode;
    }

    @SuppressLint("MissingPermission")
    @Override
    public void collectEmails() {
        // Obsolete
    }

    @Override
    public void clearEmails() {
        params.clearUserEmail();
    }

    @Override
    public void setFacebookEventLogging(boolean logging, boolean limitEventAndDataUsage) {
        Context context = mApplicationReference.get();
        if (context != null) {
            fbLogging = logging;
            if (logging) {
                TuneFBBridge.startLogger(context, limitEventAndDataUsage);
            }
        }
    }

    @Override
    public void disableLocationAutoCollection() {
        collectLocation = false;
        locationListener.stopListening();
    }

    /**
     * Get the current state of the Tune Parameters.
     * @return the {@link TuneParameters} used to initialize Tune.
     */
    public final TuneParameters getTuneParams() {
        return params;
    }

    /**
     * Default Tune Listener
     * This only logs when in DebugMode
     */
    private ITuneListener defaultTuneListener = new ITuneListener() {
        @Override
        public void enqueuedRequest(String url, JSONObject postData) {
            if (debugMode) {
                try {
                    Uri uri = Uri.parse(url);
                    String data = uri.getQueryParameter("data");
                    if (!TuneStringUtils.isNullOrEmpty(data)) {
                        url = url.replace("data=" + data, "data=");
                        url += new String(encryption.decrypt(data));
                    }
                } catch (Exception e) {
                }

                TuneDebugLog.d(url);
            }
        }

        @Override
        public void didSucceedWithData(String url, JSONObject data) {
        }

        @Override
        public void didFailWithError(String url, JSONObject error) {
        }
    };

    /* ========================================================================================== */
    /* Deeplink API                                                                               */
    /* ========================================================================================== */

    @Override
    public void unregisterDeeplinkListener() {
        dplinkr.setListener(null);
    }

    @Override
    public void registerDeeplinkListener(@Nullable TuneDeeplinkListener listener) {
        dplinkr.setListener(listener);
        requestDeferredDeeplink();
    }

    @Override
    public void registerCustomTuneLinkDomain(@NonNull String domainSuffix) {
        dplinkr.registerCustomTuneLinkDomain(domainSuffix);
    }

    @Override
    public boolean isTuneLink(@NonNull String appLinkUrl) {
        return dplinkr.isTuneLink(appLinkUrl);
    }

    /**
     * Request a deferred deep link if this is the first install of the app with the Tune SDK.
     */
    private void requestDeferredDeeplink() {
        final boolean shouldRequestDeferredDeeplink = isFirstInstall && dplinkr != null && params != null && (params.getPlatformAdvertisingId() != null || params.getAndroidId() != null);

        if (shouldRequestDeferredDeeplink) {
            dplinkr.requestDeferredDeeplink(params.getUserAgent(), urlRequester);
        }
    }

    /**
     * Set the Url Requester.
     * @param urlRequester UrlRequester
     */
    protected void setUrlRequester(final UrlRequester urlRequester) {
        this.urlRequester = urlRequester;
    }

}
