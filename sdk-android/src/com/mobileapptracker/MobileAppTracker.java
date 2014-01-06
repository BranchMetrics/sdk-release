package com.mobileapptracker;

import java.io.File;
import java.io.UnsupportedEncodingException;
import java.lang.ref.WeakReference;
import java.net.URLEncoder;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.BroadcastReceiver;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.database.Cursor;
import android.graphics.Point;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.Uri;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings.Secure;
import android.telephony.TelephonyManager;
import android.util.Log;
import android.view.WindowManager;
import android.webkit.WebView;

/**
 * @author tony@hasoffers.com
 * @author john.gu@hasoffers.com
 */
public final class MobileAppTracker {
    public static final int GENDER_MALE = 0;
    public static final int GENDER_FEMALE = 1;
    
    private static final Uri ATTRIBUTION_ID_CONTENT_URI = Uri.parse("content://com.facebook.katana.provider.AttributionIdProvider");
    private static final String ATTRIBUTION_ID_COLUMN_NAME = "aid";
    private static final String IV = "heF9BATUfWuISyO8";
    
    // The fields to encrypt in http request
    private static final List<String> ENCRYPT_LIST = Arrays.asList(
            "ir",
            "d",
            "db",
            "dm",
            "ma",
            "ov",
            "cc",
            "l",
            "an",
            "pn",
            "av",
            "dc",
            "ad",
            "android_id_md5",
            "android_id_sha1",
            "android_id_sha256",
            "r",
            "c",
            "id",
            "ua",
            "tpid",
            "ar",
            "ti",
            "age",
            "gender",
            "latitude",
            "longitude",
            "altitude",
            "connection_type",
            "mobile_country_code",
            "mobile_network_code",
            "screen_density",
            "screen_layout_size",
            "android_purchase_status",
            "referral_source",
            "referral_url",
            "google_aid",
            "app_ad_tracking",
            "facebook_user_id",
            "google_user_id",
            "twitter_user_id");

    // Interface for reading platform response to tracking calls
    private MATResponse matResponse;
    // Interface for making url requests
    private UrlRequester urlRequester;

    // Whether connectivity receiver is registered or not
    private boolean isRegistered;
    // Whether to allow duplicate installs from this device
    private boolean allowDups;
    // Whether to collect device ID
    private boolean collectDeviceId;
    // Whether to collect MAC address
    private boolean collectMacAddress;
    // Whether to show debug output
    private boolean debugMode;
    // Whether device had app installed prior to SDK integration or not
    private boolean existingUser;
    // Whether variables were initialized correctly
    private boolean initialized;
    // Whether to make a post conversion call, only for updating install referrer
    private boolean postConversion;

    // Table of fields to pass in http request
    private ConcurrentHashMap<String, String> paramTable;
    // The context passed into the constructor
    private Context mContext;
    // Local Encryption object
    private Encryption encryption;
    // Thread pool for running the GetLink Runnables
    private ScheduledExecutorService pool;
    // Binary semaphore for controlling adding to queue/dumping queue
    private Semaphore queueAvailable;
    // SharedPreferences for storing events that were not fired
    private SharedPreferences eventQueue;

    private static volatile MobileAppTracker mat = null;

    private MobileAppTracker() {
    }

    /**
     * Get existing MAT singleton object
     * @return MobileAppTracker instance
     */
    public static synchronized MobileAppTracker getInstance() {
        return mat;
    }

    /**
     * Instantiates a new MobileAppTracker.
     * @param context the application context
     * @param advertiserId the MAT advertiser ID for the app
     * @param key the MAT advertiser key for the app
     * @param collectDeviceId whether to collect device ID
     * @param collectMacAddress whether to collect MAC address
     */
    public static void init(Context context, String advertiserId, String key, boolean collectDeviceId, boolean collectMacAddress) {
        mat = new MobileAppTracker();

        mat.initLocalVariables(context, key, collectDeviceId, collectMacAddress);
        mat.initialized = mat.populateRequestParamTable(context, advertiserId);

        mat.eventQueue = context.getSharedPreferences(MATConstants.PREFS_NAME, Context.MODE_PRIVATE);
        if (mat.initialized && mat.getQueueSize() > 0 && MobileAppTracker.isOnline(context)) {
            try {
                mat.dumpQueue();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }

        // Set up connectivity listener so we dump the queue when re-connected to Internet
        BroadcastReceiver networkStateReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if (isOnline(context) && mat.getQueueSize() > 0) {
                    try {
                        mat.dumpQueue();
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                    }
                }
            }
        };

        if (mat.isRegistered) {
            // Unregister receiver in case one is still previously registered
            context.getApplicationContext().unregisterReceiver(networkStateReceiver);
            mat.isRegistered = false;
        }

        IntentFilter filter = new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION);
        context.getApplicationContext().registerReceiver(networkStateReceiver, filter);
        mat.isRegistered = true;
    }

    /**
     * Instantiates a new MobileAppTracker with device ID/MAC address collection by default.
     * @param context the application context
     * @param advertiserId the MAT advertiser ID for the app
     * @param key the MAT advertiser key for the app
     */
    public static void init(Context context, String advertiserId, String key) {
        init(context, advertiserId, key, true, true);
    }

    /**
     * Initialize class variables
     * @param context the application context
     * @param key the advertiser key
     * @param collectDeviceId whether to collect device ID
     * @param collectMacAddress whether to collect MAC address
     * @return
     */
    private void initLocalVariables(Context context, String key, boolean collectDeviceId, boolean collectMacAddress) {
        mContext = context.getApplicationContext();
        pool = Executors.newSingleThreadScheduledExecutor();
        queueAvailable = new Semaphore(1, true);
        urlRequester = new UrlRequester();
        encryption = new Encryption(key.trim(), MobileAppTracker.IV);

        isRegistered = false;
        allowDups = false;
        debugMode = false;
        existingUser = false;
        initialized = false;
        postConversion = false;

        this.collectDeviceId = collectDeviceId;
        this.collectMacAddress = collectMacAddress;
    }

    /**
     * Helper to populate the device params to send
     * @param context the application Context
     * @param advertiserId the advertiser id in MAT
     * @return whether params were successfully collected or not
     */
    @SuppressWarnings("deprecation")
    @SuppressLint("NewApi")
    private boolean populateRequestParamTable(Context context, String advertiserId) {
        paramTable = new ConcurrentHashMap<String, String>();

        boolean hasDeviceIdPermission = (context.checkCallingOrSelfPermission(MATConstants.DEVICE_ID_PERMISSION) == PackageManager.PERMISSION_GRANTED);
        boolean hasMacAddressPermission = (context.checkCallingOrSelfPermission(MATConstants.MAC_ADDRESS_PERMISSION) == PackageManager.PERMISSION_GRANTED);

        try {
            // Strip the whitespace from advertiser id
            setAdvertiserId(advertiserId.trim());
            setAction("conversion");

            // Get app package information
            String packageName = context.getPackageName();
            setPackageName(packageName);

            // Get app name
            PackageManager pm = context.getPackageManager();
            try {
                ApplicationInfo ai = pm.getApplicationInfo(packageName, 0);
                setAppName(pm.getApplicationLabel(ai).toString());

                // Get last modified date of app file as install date
                String appFile = pm.getApplicationInfo(packageName, 0).sourceDir;
                long insdate = new File(appFile).lastModified();
                Date installDate = new Date(insdate);
                SimpleDateFormat sdfDate = new SimpleDateFormat(MATConstants.DATE_FORMAT, Locale.US);
                sdfDate.setTimeZone(TimeZone.getTimeZone("UTC"));
                setInstallDate(sdfDate.format(installDate));
            } catch (NameNotFoundException e) {
                if (debugMode) {
                    Log.d(MATConstants.TAG, "ApplicationInfo not found");
                }
            }
            // Get app version
            try {
                PackageInfo pi = pm.getPackageInfo(packageName, 0);
                setAppVersion(pi.versionCode);
            } catch (NameNotFoundException e) {
                if (debugMode) {
                    Log.d(MATConstants.TAG, "App version not found");
                }
                setAppVersion(0);
            }

            // Get generic device information
            setDeviceModel(android.os.Build.MODEL);
            setDeviceBrand(android.os.Build.MANUFACTURER);
            setOsVersion(android.os.Build.VERSION.RELEASE);
            // Screen density
            float density = context.getResources().getDisplayMetrics().density;
            setScreenDensity(Float.toString(density));
            WindowManager wm = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
            int width;
            int height;
            // Screen layout size
            if (android.os.Build.VERSION.SDK_INT >= 13) {
                Point size = new Point();
                wm.getDefaultDisplay().getSize(size);
                width = size.x;
                height = size.y;
            } else {
                width = wm.getDefaultDisplay().getWidth();
                height = wm.getDefaultDisplay().getHeight();
            }
            setScreenSize(Integer.toString(width) + "x" + Integer.toString(height));

            // Set the device connection type, WIFI or mobile
            ConnectivityManager connManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            NetworkInfo mWifi = connManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
            if (mWifi.isConnected()) {
                setConnectionType("WIFI");
            } else {
                setConnectionType("mobile");
            }

            // Network and locale info
            setLanguage(Locale.getDefault().getDisplayLanguage(Locale.US));
            TelephonyManager tm = (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);
            if (tm != null) {
                if (tm.getNetworkCountryIso() != null) {
                    setCountryCode(tm.getNetworkCountryIso());
                } else if (collectDeviceId && hasDeviceIdPermission) {
                    if (tm.getSimCountryIso() != null) {
                        setCountryCode(tm.getSimCountryIso());
                    }
                }
                setCarrier(tm.getNetworkOperatorName());

                // Set Mobile Country Code and Mobile Network Code
                String networkOperator = tm.getNetworkOperator();
                if (networkOperator != null) {
                    try {
                        String mcc = networkOperator.substring(0, 3);
                        String mnc = networkOperator.substring(3);
                        setMCC(mcc);
                        setMNC(mnc);
                    } catch (IndexOutOfBoundsException e) {
                        if (debugMode) {
                            // networkOperator is unreliable for CDMA devices
                            Log.d(MATConstants.TAG, "MCC/MNC not found");
                        }
                    }
                }
            } else {
                setCountryCode(Locale.getDefault().getCountry());
            }

            // execute Runnable on UI thread to set user agent
            Handler handler = new Handler(Looper.getMainLooper());
            handler.post(new GetUserAgent(context));

            // Default params
            setLimitAdTrackingEnabled(false);
            setCurrencyCode("USD");

            // Get the device identifiers
            populateDeviceIdentifiers(context, hasDeviceIdPermission, hasMacAddressPermission);

            return true;
        } catch (Exception e) {
            if (debugMode) {
                Log.d(MATConstants.TAG, "MobileAppTracker initialization failed");
                e.printStackTrace();
            }
            return false;
        }
    }

    /**
     * Helper to get device identifiers
     * @param context the application Context
     * @param hasDeviceIdPermission whether app has READ_PHONE_STATE permission
     * @param hasMacAddressPermission whether app has ACCESS_WIFI_STATE permission
     * @return
     */
    private void populateDeviceIdentifiers(Context context, boolean hasDeviceIdPermission, boolean hasMacAddressPermission) {
        // Set the MAT ID, from existing or generate a new UUID
        SharedPreferences SP = context.getSharedPreferences(MATConstants.PREFS_MAT_ID, Context.MODE_PRIVATE);
        String matId = SP.getString("mat_id", "");
        if (matId.length() == 0) {
            // generate MAT ID once and save in shared preferences
            matId = UUID.randomUUID().toString();
            SharedPreferences.Editor editor = SP.edit();
            editor.putString("mat_id", matId);
            editor.commit();
        }
        setMatId(matId);
        
        // Set ANDROID ID
        setAndroidId(Secure.getString(context.getContentResolver(), Secure.ANDROID_ID));
        
        // Only collect device id if READ_PHONE_STATE permission exists
        if (collectDeviceId && hasDeviceIdPermission) {
            String deviceId = ((TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE)).getDeviceId();
            setDeviceId(deviceId);
        }
        
        // Only collect MAC address if ACCESS_WIFI_STATE permission exists
        if (collectMacAddress && hasMacAddressPermission) {
            WifiManager wifiMan = (WifiManager) context.getSystemService(Context.WIFI_SERVICE);
            if (wifiMan != null) {
                WifiInfo wifiInfo = wifiMan.getConnectionInfo();
                if (wifiInfo != null) {
                    if (wifiInfo.getMacAddress() != null) {
                        setMacAddress(wifiInfo.getMacAddress());
                    }
                }
            }
        }
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

    /**
     * Saves an event to the queue, used if there is no Internet connection.
     * @param link URL of the event postback
     * @param eventItems (Optional) MATEventItem JSON information to post to server
     * @param action the action for the event (conversion/install/open)
     * @param revenue value associated with the event
     * @param currency currency code for the revenue
     * @param refId the advertiser ref ID associated with the event
     * @param iapData the receipt data from Google Play
     * @param iapSignature the receipt signature from Google Play
     * @param shouldBuildData whether link needs encrypted data to be appended or not
     */
    private void addEventToQueue(String link, String eventItems, String action, double revenue, String currency, String refId, String iapData, String iapSignature, boolean shouldBuildData) throws InterruptedException {
        // Acquire semaphore before modifying queue
        queueAvailable.acquire();

        try {
            // JSON-serialize the link and json to store in Shared Preferences as a string
            JSONObject jsonEvent = new JSONObject();
            try {
                jsonEvent.put("link", link);
                if (eventItems != null) {
                    jsonEvent.put("event_items", eventItems);
                }
                jsonEvent.put("action", action);
                jsonEvent.put("revenue", revenue);
                if (currency == null) {
                    currency = "USD";
                }
                jsonEvent.put("currency", currency);
                if (refId != null) {
                    jsonEvent.put("ref_id", refId);
                }
                if (iapData != null) {
                    jsonEvent.put("iap_data", iapData);
                }
                if (iapSignature != null) {
                    jsonEvent.put("iap_signature", iapSignature);
                }
                jsonEvent.put("should_build_data", shouldBuildData);
            } catch (JSONException e) {
                if (debugMode) {
                    e.printStackTrace();
                }
                // Return if we can't create JSONObject
                return;
            }
            SharedPreferences.Editor editor = eventQueue.edit();
            int count = getQueueSize() + 1;
            setQueueSize(count);
            String eventIndex = Integer.valueOf(count).toString();
            editor.putString(eventIndex, jsonEvent.toString());
            editor.commit();
        } finally {
            queueAvailable.release();
        }
    }

    /**
     * Returns the current event queue size.
     * @return the event queue size
     */
    private int getQueueSize() {
        return eventQueue.getInt("queuesize", 0);
    }

    /**
     * Sets the event queue size to value.
     * @param value the new queue size
     */
    private void setQueueSize(int value) {
        SharedPreferences.Editor editor = eventQueue.edit();
        if (value < 0) value = 0;
        editor.putInt("queuesize", value);
        editor.commit();
    }

    /**
     * Processes the event queue, method will only process MAX_DUMP_SIZE events per call.
     * @return void
     * @throws InterruptedException 
     */
    private synchronized void dumpQueue() throws InterruptedException {
        queueAvailable.acquire();

        try {
            int size = getQueueSize();
            if (size == 0) {
                return;
            }

            int index = 1;
            if (size > MATConstants.MAX_DUMP_SIZE) {
                index = 1 + (size - MATConstants.MAX_DUMP_SIZE);
            }

            // Iterate through events and do postbacks for each, using GetLink
            for (; index <= size; index++) {
                String key = Integer.valueOf(index).toString();
                String eventJson = eventQueue.getString(key, null);

                if (eventJson != null) {
                    String link = null;
                    String eventItems = null;
                    String action = null;
                    double revenue = 0;
                    String currency = null;
                    String refId = null;
                    String iapData = null;
                    String iapSignature = null;
                    boolean shouldBuildData = false;
                    try {
                        // De-serialize the stored string from the queue to get URL and json values
                        JSONObject event = new JSONObject(eventJson);
                        link = event.getString("link");
                        if (event.has("event_items")) {
                            eventItems = event.getString("event_items");
                        }
                        action = event.getString("action");
                        revenue = event.getDouble("revenue");
                        currency = event.getString("currency");
                        if (event.has("ref_id")) {
                            refId = event.getString("ref_id");
                        }
                        if (event.has("iap_data")) {
                            iapData = event.getString("iap_data");
                        }
                        if (event.has("iap_signature")) {
                            iapSignature = event.getString("iap_signature");
                        }
                        shouldBuildData = event.getBoolean("should_build_data");
                    } catch (JSONException e) {
                        if (debugMode) {
                            e.printStackTrace();
                        }
                        // Can't rebuild saved request, remove from queue and return
                        setQueueSize(getQueueSize() - 1);
                        SharedPreferences.Editor editor = eventQueue.edit();
                        editor.remove(key);
                        editor.commit();
                        return;
                    }

                    // Remove request from queue and execute
                    setQueueSize(getQueueSize() - 1);
                    SharedPreferences.Editor editor = eventQueue.edit();
                    editor.remove(key);
                    editor.commit();

                    try {
                        pool.execute(new GetLink(link, eventItems, action, revenue, currency, refId, iapData, iapSignature, shouldBuildData));
                    } catch (Exception e) {
                        if (debugMode) {
                            Log.d(MATConstants.TAG, "Request could not be executed from queue");
                            e.printStackTrace();
                        }
                    }
                }
            }
        } finally {
            queueAvailable.release();
        }
    }

    /**
     * Insert referring app info into target app's content provider. Redirects user to target app's download url if doRedirect is true.
     * @param publisherAdvertiserId the advertiser id of the publishing app (referring app)
     * @param targetPackageName the target package name being referred to
     * @param publisherId (optional) the publisher id for referral
     * @param campaignId (optional) the campaign id for referral
     * @param doRedirect whether to automatically redirect user to target app's url or not
     * @return download url to target app
     */
    public String setTracking(String publisherAdvertiserId, String targetPackageName, String publisherId, String campaignId, boolean doRedirect) {
        // Track a click with the app-to-app parameters and get a tracking ID back
        String trackingId = "";
        String redirectUrl = "";

        StringBuilder url = new StringBuilder("https://").append(MATConstants.MAT_DOMAIN).append("/serve?action=click&sdk=android");
        url.append("&publisher_advertiser_id=").append(publisherAdvertiserId);
        url.append("&package_name=").append(targetPackageName);
        if (publisherId != null) {
            url.append("&publisher_id=").append(publisherId);
        }
        if (campaignId != null) {
            url.append("&campaign_id=").append(campaignId);
        }
        url.append("&response_format=json");

        JSONObject response = urlRequester.requestUrl(url.toString(), null);
        if (response != null) {
            try {
                trackingId = response.getString("tracking_id");
                redirectUrl = response.getString("url");
            } catch (JSONException e) {
                if (debugMode) {
                    Log.d(MATConstants.TAG, "Unable to get tracking ID or redirect url from app-to-app tracking");
                }
                return "";
            }
        }

        ContentValues values = new ContentValues();
        values.put(MATProvider.PUBLISHER_PACKAGE_NAME, getPackageName());
        values.put(MATProvider.TRACKING_ID, trackingId);

        Uri CONTENT_URI = Uri.parse("content://" + targetPackageName + "/referrer_apps");
        mContext.getContentResolver().insert(CONTENT_URI, values);

        // If doRedirect is true, take user to the url returned by the server
        if (doRedirect) {
            try {
                Intent i = new Intent(Intent.ACTION_VIEW, Uri.parse(redirectUrl));
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                mContext.startActivity(i);
            } catch (ActivityNotFoundException e) {
                if (debugMode) {
                    Log.d(MATConstants.TAG, "Unable to start activity to open " + redirectUrl);
                }
            }
        }

        return redirectUrl;
    }

    /**
     * Main tracking install function, this function only needs to be successfully called one time on application install.
     * Subsequent calls will not send more installs.
     * @return 1 on request sent, 2 on already installed state, 3 on update, and -1 on failure
     */
    public int trackInstall() {
        if (existingUser) {
            return trackInstallOrUpdate("update");
        } else {
            return trackInstallOrUpdate("install");
        }
    }

    /**
     * trackInstall call that bypasses already-sent check
     * and with post_conversion=1 for updating referrer value of existing MAT install
     */
    void trackInstallWithReferrer() {
        postConversion = true;
        if (existingUser) {
            track("update", null, getRevenue(), getCurrencyCode(), getRefId(), null, null);
        } else {
            track("install", null, getRevenue(), getCurrencyCode(), getRefId(), null, null);
        }
        postConversion = false;
    }

    /**
     * Helper function that sends install or update one time per app version
     * @param eventType install or update
     * @return 1 on request sent, 2 on already installed state, 3 on update, and -1 on failure
     */
    private int trackInstallOrUpdate(String eventType) {
        SharedPreferences.Editor editor;
        SharedPreferences SP = mContext.getSharedPreferences(MATConstants.PREFS_INSTALL, Context.MODE_PRIVATE);
        String install = SP.getString("install", "");
        if (!install.equals("")) { // has it been tracked before?
            SP = mContext.getSharedPreferences(MATConstants.PREFS_VERSION, Context.MODE_PRIVATE);
            String savedVersion = SP.getString("version", "");
            if (savedVersion.length() != 0 && Integer.parseInt(savedVersion) != getAppVersion()) { // If have been tracked before, check if is an update
                if (debugMode) Log.d(MATConstants.TAG, "App version has changed since last trackInstall, sending update to server");
                track("update", null, getRevenue(), getCurrencyCode(), getRefId(), null, null);
                editor = SP.edit();
                editor.putString("version", Integer.toString(getAppVersion()));
                editor.commit();
                return 3;
            }
            if (debugMode) Log.d(MATConstants.TAG, eventType + " has been tracked before");
            return 2;
        } else {
            // mark app as tracked so that postback url won't be called again
            SP = mContext.getSharedPreferences(MATConstants.PREFS_INSTALL, Context.MODE_PRIVATE);
            editor = SP.edit();
            editor.putString("install", "installed");
            editor.commit();
            SP = mContext.getSharedPreferences(MATConstants.PREFS_VERSION, Context.MODE_PRIVATE);
            editor = SP.edit();
            editor.putString("version", Integer.toString(getAppVersion()));
            editor.commit();
        }
        return track(eventType, null, getRevenue(), getCurrencyCode(), getRefId(), null, null);
    }

    /**
     * Tracking event function, track purchase events with a special purchase status parameter.
     * @param event event name or event ID in MAT system
     * @param purchaseStatus the status of the purchase: 0 for success, 1 for fail, 2 for refund
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     * @param inAppPurchaseData the receipt data from Google Play
     * @param inAppSignature the receipt signature from Google Play
     * @return 1 on request sent and -1 on failure
     */
    public int trackPurchase(String event, int purchaseStatus, double revenue, String currency, String refId, String inAppPurchaseData, String inAppSignature) {
        setPurchaseStatus(purchaseStatus);
        return track(event, null, revenue, currency, refId, inAppPurchaseData, inAppSignature);
    }

    /**
     * Tracking event function, track events by event ID or name.
     * @param event event name or event ID in MAT system
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event) {
        return track(event, null, getRevenue(), getCurrencyCode(), getRefId(), null, null);
    }

    /**
     * Tracking event function, track events by event ID or name, and event item.
     * @param event event name or event ID in MAT system
     * @param eventItem event item to post to server.
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, MATEventItem eventItem) {
        JSONArray jsonArray = new JSONArray();
        jsonArray.put(eventItem.toJSON());
        return track(event, jsonArray.toString(), getRevenue(), getCurrencyCode(), getRefId(), null, null);
    }

    /**
     * Tracking event function, track events by event ID or name, event item, and in-app purchase data and signature for purchase verification.
     * @param event event name or event ID in MAT system
     * @param eventItem event item to post to server.
     * @param inAppPurchaseData the receipt data from Google Play
     * @param inAppSignature the receipt signature from Google Play
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, MATEventItem eventItem, String inAppPurchaseData, String inAppSignature) {
        JSONArray jsonArray = new JSONArray();
        jsonArray.put(eventItem.toJSON());
        return track(event, jsonArray.toString(), getRevenue(), getCurrencyCode(), getRefId(), inAppPurchaseData, inAppSignature);
    }

    /**
     * Tracking event function, track events by event ID or name, and a list of event items.
     * @param event event name or event ID in MAT system
     * @param list List of event items to post to server.
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, List<MATEventItem> list) {
        // Create a JSONArray of event items
        JSONArray jsonArray = new JSONArray();
        for (int i = 0; i < list.size(); i++) {
            jsonArray.put(list.get(i).toJSON());
        }
        return track(event, jsonArray.toString(), getRevenue(), getCurrencyCode(), getRefId(), null, null);
    }

    /**
     * Tracking event function, track events by event ID or name, a list of event items, and in-app purchase data and signature for purchase verification.
     * @param event event name or event ID in MAT system
     * @param list List of event items to post to server.
     * @param inAppPurchaseData the receipt data from Google Play
     * @param inAppSignature the receipt signature from Google Play
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, List<MATEventItem> list, String inAppPurchaseData, String inAppSignature) {
        // Create a JSONArray of event items
        JSONArray jsonArray = new JSONArray();
        for (int i = 0; i < list.size(); i++) {
            jsonArray.put(list.get(i).toJSON());
        }
        return track(event, jsonArray.toString(), getRevenue(), getCurrencyCode(), getRefId(), inAppPurchaseData, inAppSignature);
    }

    /**
     * Tracking event function, track events by event ID or name, revenue.
     * @param event event name or event ID in MAT system
     * @param revenue revenue amount tied to the action
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, double revenue) {
        return track(event, null, revenue, getCurrencyCode(), getRefId(), null, null);
    }

    /**
     * Tracking event function, track events by event ID or name, revenue and currency.
     * @param event event name or event ID in MAT system
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, double revenue, String currency) {
        return track(event, null, revenue, currency, getRefId(), null, null);
    }

    /**
     * Tracking event function, track events by event ID or name, revenue, currency, and advertiser ref ID.
     * @param event event name or event ID in MAT system
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, double revenue, String currency, String refId) {
        return track(event, null, revenue, currency, refId, null, null);
    }

    /**
     * Tracking event function, track events by event ID or name, revenue, currency, advertiser ref ID, and in-app purchase data and signature for purchase verification.
     * @param event event name or event ID in MAT system
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     * @param inAppPurchaseData the receipt data from Google Play
     * @param inAppSignature the receipt signature from Google Play
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, double revenue, String currency, String refId, String inAppPurchaseData, String inAppSignature) {
        return track(event, null, revenue, currency, refId, inAppPurchaseData, inAppSignature);
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
     * @return 1 on request sent and -1 on failure.
     */
    private synchronized int track(String event, String eventItems, double revenue, String currency, String refId, String inAppPurchaseData, String inAppSignature) {
        if (!initialized) return -1;
        
        if (isOnline(mContext) && getQueueSize() > 0) {
            try {
                dumpQueue();
            } catch (InterruptedException e) {
                e.printStackTrace();
                Thread.currentThread().interrupt();
            }
        }

        // Clear the parameters from parameter table that should be reset between events
        paramTable.remove("ei");
        paramTable.remove("en");
        paramTable.remove("ar");
        paramTable.remove("r");

        setAction("conversion"); // Default to conversion
        if (containsChar(event)) { // check if eventid contains a character
            if (event.equals("open")) setAction("open");
            else if (event.equals("close")) return -1; // Don't send close events anymore
            else if (event.equals("install")) setAction("install");
            else if (event.equals("update")) setAction("update");
            else setEventName(event);
        } else {
            setEventId(event);
        }

        String link = buildLink();
        if (link == null) {
            if (debugMode) {
                Log.d(MATConstants.TAG, "Error constructing url for tracking call");
            }
            return -1;
        }

        String action = getAction();
        if (isOnline(mContext)) {
            try {
                pool.schedule(new GetLink(link, eventItems, action, revenue, currency, refId, inAppPurchaseData, inAppSignature, true), MATConstants.DELAY, TimeUnit.MILLISECONDS);
            } catch (Exception e) {
                if (debugMode) {
                    Log.d(MATConstants.TAG, "Request could not be executed from track");
                    e.printStackTrace();
                }
            }
        } else {
            if (!action.equals("open")) {
                if (debugMode) Log.d(MATConstants.TAG, "Not online: track will be queued");
                try {
                    addEventToQueue(link, eventItems, action, revenue, currency, refId, inAppPurchaseData, inAppSignature, true);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        }
        return 1;
    }
    
    /**
     * Builds a new link string based on class member values.
     * @return encrypted URL string based on class settings.
     */
    private String buildLink() {
        StringBuilder link = new StringBuilder("https://").append(getAdvertiserId()).append(".");
        if (debugMode) {
            link.append(MATConstants.MAT_DOMAIN_DEBUG);
        } else {
            link.append(MATConstants.MAT_DOMAIN);
        }
        link.append("/serve?s=android&ver=").append(MATConstants.SDK_VERSION);
        
        // Append SDK plugin name if exists
        String pluginName = getPluginName();
        if (pluginName != null) {
            link.append("&sdk_plugin=").append(pluginName);
        }

        link.append("&pn=").append(getPackageName());
        for (String key: paramTable.keySet()) {
            // Append fields from paramTable that don't need to be encrypted
            if (!ENCRYPT_LIST.contains(key)) {
                link.append("&").append(key).append("=").append(paramTable.get(key));
            }
        }

        // If allow duplicates on, skip duplicate check logic
        if (allowDups) {
            link.append("&skip_dup=1");
        }

        // If logging on, use debug mode
        if (debugMode) {
            link.append("&debug=1");
        }

        if (postConversion) {
            link.append("&post_conversion=1");
        }

        // Append app-to-app tracking id if exists
        try {
            Uri allTitles = Uri.parse("content://" + getPackageName() + "/referrer_apps");
            Cursor c = mContext.getContentResolver().query(allTitles, null, null, null, "publisher_package_name desc");
            // Append tracking ID from content provider if exists
            if (c != null && c.moveToFirst()) {
                String trackingId = c.getString(c.getColumnIndex(MATProvider.TRACKING_ID));
                // UTF-8 encode the tracking ID
                try {
                    trackingId = URLEncoder.encode(trackingId, "UTF-8");
                } catch (UnsupportedEncodingException e) {
                    e.printStackTrace();
                }
                
                // Add to paramTable for data encrypting
                paramTable.put("ti", trackingId);
                c.close();
            }
        } catch (Exception e) {
            if (debugMode) {
                Log.d(MATConstants.TAG, "Error reading app-to-app values");
                e.printStackTrace();
            }
        }
        return link.toString();
    }

    /**
     * Builds encrypted data in conversion link based on class member values.
     * @param origLink the base URL to append data to
     * @param action the event action (install/update/open/conversion)
     * @param revenue revenue associated with event
     * @param currency currency code for event
     * @param refId the advertiser ref ID to associate with the event
     * @return encrypted URL string based on class settings.
     */
    private String buildData(String origLink, String action, double revenue, String currency, String refId) {
        StringBuilder link = new StringBuilder(origLink);

        setRevenue(revenue);
        if (currency != null) {
            setCurrencyCode(currency);
        }
        setRefId(refId);

        // Try to update referrer value if we don't have one
        if (getReferrer() == null || getReferrer().length() == 0) {
            SharedPreferences SP = mContext.getSharedPreferences(MATConstants.PREFS_REFERRER, Context.MODE_PRIVATE);
            String referrer = SP.getString("referrer", "");
            setReferrer(referrer);
        }

        // For opens and events, try to add install_log_id
        if (action.equals("open") || action.equals("conversion")) {
            // Append install log id for opens and events if we have it stored
            if (getInstallLogId().length() > 0) {
                link.append("&install_log_id=" + getInstallLogId());
            } else if (getUpdateLogId().length() > 0) {
                link.append("&update_log_id=" + getUpdateLogId());
            } else {
                // Call GetLog endpoint
                if (isTodayLatestDate(MATConstants.PREFS_LAST_LOG_ID, MATConstants.PREFS_LAST_LOG_ID_KEY)) {
                    // Build the url to request the log id
                    StringBuilder logIdUrl = new StringBuilder("https://").append(MATConstants.MAT_DOMAIN).append("/v1/Integrations/Sdk/GetLog?sdk=android&package_name=").append(getPackageName()).append("&advertiser_id=").append(getAdvertiserId()).append("&keys[mac_address]=").append(getMacAddress()).append("&keys[device_id]=").append(getDeviceId());
                    // Add encrypted package name as data
                    StringBuilder encryptedPackageName = new StringBuilder("package_name=").append(getPackageName());
                    try {
                        encryptedPackageName = new StringBuilder(Encryption.bytesToHex(encryption.encrypt(encryptedPackageName.toString())));
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    logIdUrl.append("&data=").append(encryptedPackageName.toString());

                    String logId = "";
                    String type = "";
                    JSONObject response = urlRequester.requestUrl(logIdUrl.toString(), null);
                    if (response != null) {
                        if (!response.isNull("data")) {
                            try {
                                JSONObject data = response.getJSONObject("data");
                                logId = data.getString("log_id");
                                type = data.getString("type");
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                        }
                    }

                    // Set the returned log id and append to link
                    if (logId.length() > 0) {
                        if (type.equals("install")) {
                            setInstallLogId(logId);
                            link.append("&install_log_id=" + logId);
                        } else if (type.equals("update")) {
                            setUpdateLogId(logId);
                            link.append("&update_log_id=" + logId);
                        }
                    } else {
                        // If open doesn't contain log_id, log it to serve_no_log
                        if (action.equals("open")) {
                            if (debugMode) Log.d(MATConstants.TAG, "Log ID not found for open/event, sending as no_log data");
                            // Change tracking engine url to hit serve_no_log endpoint
                            link = new StringBuilder(link.toString().replace("serve", "serve_no_log"));
                        }
                    }
                } else {
                    if (debugMode) Log.d(MATConstants.TAG, "SDK has already requested a log ID today, not requesting");
                    // If open doesn't contain log_id, log it to serve_no_log
                    if (action.equals("open")) {
                        if (debugMode) Log.d(MATConstants.TAG, "Log ID not found for open/event, sending as no_log data");
                        // Change tracking engine url to hit serve_no_log endpoint
                        link = new StringBuilder(link.toString().replace("serve", "serve_no_log"));
                    }
                }
            }
        }

        // Append Facebook mobile cookie value if exists
        try {
            String facebookCookie = getAttributionId(mContext.getContentResolver());
            if (facebookCookie != null) {
                link.append("&fb_cookie_id=").append(facebookCookie);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

        // Check if there is a Facebook re-engagement intent saved in SharedPreferences
        SharedPreferences SP = mContext.getSharedPreferences(MATConstants.PREFS_FACEBOOK_INTENT, Context.MODE_PRIVATE);
        String intent = SP.getString("action", "");
        if (intent.length() != 0) {
            try {
                intent = URLEncoder.encode(intent, "UTF-8");
            } catch (UnsupportedEncodingException e) {
                e.printStackTrace();
            }
            // Append Facebook re-engagement intent to url as "source"
            link.append("&source=").append(intent);
            // Clear the fb intent
            SharedPreferences.Editor editor = SP.edit();
            editor.remove("action");
            editor.commit();
        }

        // Construct the data string from field names in encryptList and encrypt it
        StringBuilder data = new StringBuilder();
        for (String encrypt: ENCRYPT_LIST) {
            if (paramTable.get(encrypt) != null) {
                data.append("&").append(encrypt).append("=").append(paramTable.get(encrypt));
            }
        }

        SimpleDateFormat sdfDate = new SimpleDateFormat(MATConstants.DATE_FORMAT, Locale.US);
        Date now = new Date();
        String currentTime = sdfDate.format(now);
        try {
            currentTime = URLEncoder.encode(currentTime, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        data.append("&sd=").append(currentTime);

        try {
            data = new StringBuilder(Encryption.bytesToHex(encryption.encrypt(data.toString())));
        } catch (Exception e) {
            e.printStackTrace();
        }
        link.append("&da=").append(data.toString());

        return link.toString();
    }

    /**
     *  Function that checks whether we have set a date value for given SharedPreferences filename and key in the past day
     *  @param prefsName SharedPreferences filename of saved date value
     *  @param prefsKey SharedPreferences key in filename for saved date value
     *  @return true if first time being set today, false otherwise
     */
    private boolean isTodayLatestDate(String prefsName, String prefsKey) {
        SimpleDateFormat sdf = new SimpleDateFormat(MATConstants.DATE_ONLY_FORMAT, Locale.getDefault());
        Calendar today = Calendar.getInstance();

        SharedPreferences SP = mContext.getSharedPreferences(prefsName, Context.MODE_PRIVATE);
        String lastDateStr = SP.getString(prefsKey, "");

        // Check if last date exists in SharedPreferences
        if (lastDateStr.length() > 0) {
            // Recreate Calendar of last open date from string
            Calendar lastDate = Calendar.getInstance();
            try {
                lastDate.setTime(sdf.parse(lastDateStr));
            } catch (ParseException e) {
                e.printStackTrace();
            }

            // Compare today's date with last date seen
            TimeIgnoringComparator dateComparator = new TimeIgnoringComparator();
            if (dateComparator.compare(today, lastDate) == 1) {
                // Save today's date as last open
                setLastDate(sdf, today, prefsName, prefsKey);
                return true;
            } else {
                // Current date is not newer than last seen date so do not send open
                return false;
            }
        } else {
            // No previous last date, save today's date as last seen date
            setLastDate(sdf, today, prefsName, prefsKey);
            return true;
        }
    }

    /**
     *  Runnable for creating a WebView and getting the device user agent
     */
    private class GetUserAgent implements Runnable {
        private final WeakReference<Context> weakContext;

        public GetUserAgent(Context context) {
            weakContext = new WeakReference<Context>(context);
        }

        public void run() {
            try {
                // Create WebView to set user agent, then destroy WebView
                WebView wv = new WebView(weakContext.get());
                String userAgent = wv.getSettings().getUserAgentString();
                wv.destroy();
                setUserAgent(userAgent);
            } catch (Exception e) {
                if (debugMode) {
                    Log.d(MATConstants.TAG, "Could not get user agent");
                    e.printStackTrace();
                }
            }
        }
    }

    /**
     * Runnable for making a single http request.
     */
    private class GetLink implements Runnable {
        private String link = null;
        private String eventItems = null;
        private String action = null;
        private double revenue = 0;
        private String currency = null;
        private String refId = null;
        private String iapData = null;
        private String iapSignature = null;
        private boolean shouldBuildData = false;

        /**
         * Instantiates a new GetLink Runnable.
         * @param link url to request
         * @param eventItems eventItem data to post
         * @param action the event action
         * @param revenue the revenue amount
         * @param currency the currency code
         * @param refId the advertiser ref ID associated with the event
         * @param iapData the receipt data from Google Play
         * @param iapSignature the receipt signature from Google Play
         * @param shouldBuildData whether link needs encrypted data appended
         */
        public GetLink(String link, String eventItems, String action, double revenue, String currency, String refId, String iapData, String iapSignature, boolean shouldBuildData) {
            this.link = link;
            this.eventItems = eventItems;
            this.action = action;
            this.revenue = revenue;
            this.currency = currency;
            this.refId = refId;
            this.iapData = iapData;
            this.iapSignature = iapSignature;
            this.shouldBuildData = shouldBuildData;
        }

        public void run() {
            if (shouldBuildData) {
                link = buildData(link, action, revenue, currency, refId);
            }

            // If action is open, check whether we have done an open in the past 24h
            // If true, don't send open
            if (action.equals("open")) {
                if (!isTodayLatestDate(MATConstants.PREFS_LAST_OPEN, MATConstants.PREFS_LAST_OPEN_KEY)) {
                    if (debugMode) Log.d(MATConstants.TAG, "SDK has already sent an open today, not sending request");
                    return;
                }
            }

            if (debugMode) {
                Log.d(MATConstants.TAG, "Sending " + action + " event to server...");
            }

            // Construct JSONObject from eventItems and iapData/iapSignature
            JSONObject postData = new JSONObject();
            try {
                if (eventItems != null) {
                    // Add event items under key "data"
                    JSONArray eventItemsJson = new JSONArray(eventItems);
                    postData.put("data", eventItemsJson);
                }

                if (iapData != null) {
                    postData.put("store_iap_data", iapData);
                }

                if (iapSignature != null) {
                    postData.put("store_iap_signature", iapSignature);
                }
            } catch (JSONException e) {
                if (debugMode) Log.d(MATConstants.TAG, "Could not build JSON for event items or verification values");
                e.printStackTrace();
            }

            JSONObject response = urlRequester.requestUrl(link, postData);
            if (response == null) {
                try {
                    addEventToQueue(link, eventItems, action, revenue, currency, refId, iapData, iapSignature, false);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                    Thread.currentThread().interrupt();
                }
                if (debugMode) Log.d(MATConstants.TAG, "Request failed: track will be queued");
                return;
            }

            // Signal didSucceedWithData event to interface
            if (matResponse != null) {
                matResponse.didSucceedWithData(response);
            }

            // Set log ID from install/update response
            if (action.equals("install")) {
                try {
                    setInstallLogId(response.getString("log_id"));
                } catch (JSONException e) {
                    if (debugMode) {
                        Log.d(MATConstants.TAG, "Install log id could not be found in response");
                        e.printStackTrace();
                    }
                }
            } else if (action.equals("update")) {
                try {
                    setUpdateLogId(response.getString("log_id"));
                } catch (JSONException e) {
                    if (debugMode) {
                        Log.d(MATConstants.TAG, "Update log id could not be found in response");
                        e.printStackTrace();
                    }
                }
            }

            if (debugMode) {
                Log.d(MATConstants.TAG, "Server response: " + response.toString());
                if (response.length() > 0) {
                    try {
                        if (!response.getString("log_action").equals("null")) {
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
        }
    }

    /******************
     * Public Setters *
     ******************/

    /**
     * Gets the MAT advertiser ID.
     * @return MAT advertiser ID
     */
    public String getAdvertiserId() {
        return paramTable.get("adv");
    }

    /**
     * Sets the MAT advertiser ID.
     * @param advertiser_id MAT advertiser ID
     */
    public void setAdvertiserId(String advertiser_id) {
        putInParamTable("adv", advertiser_id);
    }

    /**
     * Gets the user age set.
     * @return age
     */
    public int getAge() {
        if (paramTable.get("age") == null) {
            return 0;
        }
        return Integer.parseInt(paramTable.get("age"));
    }

    /**
     * Sets the user's age.
     * @param age User age to track in MAT
     */
    public void setAge(int age) {
        putInParamTable("age", Integer.toString(age));
    }

    /**
     * Gets the device altitude. Must be set, not automatically retrieved.
     * @return device altitude
     */
    public double getAltitude() {
        if (paramTable.get("altitude") == null) {
            return 0;
        }
        return Double.parseDouble(paramTable.get("altitude"));
    }

    /**
     * Sets the device altitude.
     * @param altitude device altitude
     */
    public void setAltitude(double altitude) {
        putInParamTable("altitude", Double.toString(altitude));
    }

    /**
     * Sets whether app was previously installed prior to version with MAT SDK
     * @param existing true if this user already had the app installed prior to updating to MAT version
     */
    public void setExistingUser(boolean existing) {
        existingUser = existing;
    }
    
    /**
     * Gets the ISO 4217 currency code.
     * @return ISO 4217 currency code
     */
    public String getCurrencyCode() {
        return paramTable.get("c");
    }

    /**
     * Sets the ISO 4217 currency code.
     * @param currency_code the currency code
     */
    public void setCurrencyCode(String currency_code) {
        putInParamTable("c", currency_code);
    }

    /**
     * Sets the user ID to associate with Facebook
     * @param fb_user_id
     */
    public void setFacebookUserId(String fb_user_id) {
        putInParamTable("facebook_user_id", fb_user_id);
    }

    /**
     * Gets the user gender set.
     * @return gender 0 for male, 1 for female
     */
    public int getGender() {
        if (paramTable.get("gender") == null) {
            return 0;
        }
        return Integer.parseInt(paramTable.get("gender"));
    }

    /**
     * Sets the user gender.
     * @param gender use MobileAppTracker.GENDER_MALE, MobileAppTracker.GENDER_FEMALE
     */
    public void setGender(int gender) {
        putInParamTable("gender", Integer.toString(gender));
    }

    /**
     * Gets the Google Play Services Advertising ID.
     * @return Google advertising ID
     */
    public String getGoogleAdvertisingId() {
        return paramTable.get("google_aid");
    }
    
    /**
     * Sets the Google Play Services Advertising ID
     * @param adId Google Play advertising ID
     */
    public void setGoogleAdvertisingId(String adId) {
        putInParamTable("google_aid", adId);
    }

    /**
     * Sets the user ID to associate with Google
     * @param google_user_id
     */
    public void setGoogleUserId(String google_user_id) {
        putInParamTable("google_user_id", google_user_id);
    }

    /**
     * Sets the key used for encrypting the event urls, key length needs to be either 128, 192, or 256 bits.
     * @param key the new key
     * 
     * @deprecated This should only be set by the constructor.
     */
    @Deprecated
    public void setKey(String key) {
        encryption = new Encryption(key.trim(), MobileAppTracker.IV);
    }

    /**
     * Gets the device latitude. Must be set, not automatically retrieved.
     * @return device latitude
     */
    public double getLatitude() {
        if (paramTable.get("latitude") == null) {
            return 0;
        }
        return Double.parseDouble(paramTable.get("latitude"));
    }

    /**
     * Sets the device latitude.
     * @param latitude the device latitude
     */
    public void setLatitude(double latitude) {
        putInParamTable("latitude", Double.toString(latitude));
    }

    /**
     * Get whether the user has limit ad tracking enabled or not.
     * @return limit ad tracking enabled or not
     */
    public boolean getLimitAdTrackingEnabled() {
        int isLATEnabled = Integer.parseInt(paramTable.get("app_ad_tracking"));
        return (isLATEnabled == 0);
    }

    /**
     * Sets whether the app user has chosen to limit ad tracking.
     * @param isLATEnabled true if user has opted out of ad tracking, false if not (default)
     */
    public void setLimitAdTrackingEnabled(boolean isLATEnabled) {
        if (isLATEnabled) {
            putInParamTable("app_ad_tracking", Integer.toString(0));
        } else {
            putInParamTable("app_ad_tracking", Integer.toString(1));
        }
    }

    /**
     * Gets the device longitude. Must be set, not automatically retrieved.
     * @return device longitude
     */
    public double getLongitude() {
        if (paramTable.get("longitude") == null) {
            return 0;
        }
        return Double.parseDouble(paramTable.get("longitude"));
    }

    /**
     * Sets the device longitude.
     * @param longitude the device longitude
     */
    public void setLongitude(double longitude) {
        putInParamTable("longitude", Double.toString(longitude));
    }

    /**
     * Register a MATResponse interface to receive server response callback
     * @param response a MATResponse object that will be called when server request is complete
     */
    public void setMATResponse(MATResponse response) {
        matResponse = response;
    }

    /**
     * Gets the app package name
     * @return package name of app
     */
    public String getPackageName() {
        return paramTable.get("pn");
    }

    /**
     * Sets the app package name
     * @param package_name App package name
     */
    public void setPackageName(String package_name) {
        putInParamTable("pn", package_name);
    }

    /**
     * Get referral sources from Activity
     * @param act Activity to get referring package name and url scheme from
     */
    public void setReferralSources(Activity act) {
        // Set source package
        setReferralSource(act.getCallingPackage());
        // Set source url query
        Intent intent = act.getIntent();
        if (intent != null) {
            Uri uri = intent.getData();
            if (uri != null) {
                String referralUrl = uri.toString();
                setReferralUrl(referralUrl);
            }
        }
    }

    /**
     * Gets the Google Play INSTALL_REFERRER
     * @return Play INSTALL_REFERRER
     */
    public String getReferrer() {
        return paramTable.get("ir");
    }

    /**
     * Overrides the Google Play INSTALL_REFERRER received
     * @param referrer Your custom referrer value
     */
    public void setReferrer(String referrer) {
        putInParamTable("ir", referrer);
    }

    /**
     * Gets the advertiser ref ID.
     * @return advertiser ref ID set by SDK
     */
    public String getRefId() {
        return paramTable.get("ar");
    }

    /**
     * Sets the advertiser ref ID.
     * @param ref_id the new ref ID
     */
    public void setRefId(String ref_id) {
        putInParamTable("ar", ref_id);
    }

    /**
     * Gets the revenue amount set
     * @return revenue amount
     */
    public Double getRevenue() {
        if (paramTable.get("r") == null) {
            return Double.valueOf(0);
        }
        return Double.parseDouble(paramTable.get("r"));
    }

    /**
     * Sets the revenue amount to report on next tracking call
     * @param revenue Revenue amount
     */
    public void setRevenue(double revenue) {
        putInParamTable("r", Double.toString(revenue));
    }

    /**
     * Gets the MAT site ID set
     * @return site ID in MAT
     */
    public String getSiteId() {
        return paramTable.get("si");
    }

    /**
     * Sets the MAT site ID to specify which app to attribute to
     * @param site_id MAT site ID to attribute to
     */
    public void setSiteId(String site_id) {
        putInParamTable("si", site_id);
    }

    /**
     * Gets the TRUSTe ID set
     * @return TRUSTe ID
     */
    public String getTRUSTeId() {
        return paramTable.get("tpid");
    }

    /**
     * Sets the TRUSTe ID, should generate via their SDK
     * @param tpid TRUSTe ID
     */
    public void setTRUSTeId(String tpid) {
        putInParamTable("tpid", tpid);
    }

    /**
     * Sets the user ID to associate with Twitter
     * @param twitter_user_id
     */
    public void setTwitterUserId(String twitter_user_id) {
        putInParamTable("twitter_user_id", twitter_user_id);
    }

    /**
     * Gets the custom user ID.
     * @return custom user id
     */
    public String getUserId() {
        return paramTable.get("ui");
    }

    /**
     * Sets the custom user ID.
     * @param user_id the new user id
     */
    public void setUserId(String user_id) {
        putInParamTable("ui", user_id);
    }

    /*******************
     * Private Setters *
     *******************/
    
    /**
     * Gets the action of the event
     * @return install/update/conversion
     */
    public String getAction() {
        return paramTable.get("ac");
    }

    private void setAction(String action) {
        putInParamTable("ac", action);
    }

    /**
     * Gets the ANDROID_ID of the device
     * @return ANDROID_ID
     */
    public String getAndroidId() {
        return paramTable.get("ad");
    }

    private void setAndroidId(String android_id) {
        putInParamTable("ad", android_id);
    }

    /**
     * Gets the MD5 hash of the ANDROID_ID of the device
     * @return ANDROID_ID MD5 hash
     */
    public String getAndroidIdMd5() {
        return paramTable.get("android_id_md5");
    }

    private void setAndroidIdMd5(String android_id_md5) {
        putInParamTable("android_id_md5", android_id_md5);
    }

    /**
     * Gets the SHA-1 hash of the ANDROID_ID of the device
     * @return ANDROID_HD SHA-1 hash
     */
    public String getAndroidIdSha1() {
        return paramTable.get("android_id_sha1");
    }

    private void setAndroidIdSha1(String android_id_sha1) {
        putInParamTable("android_id_sha1", android_id_sha1);
    }

    /**
     * Gets the SHA-256 hash of the ANDROID_ID of the device
     * @return ANDROID_HD SHA-256 hash
     */
    public String getAndroidIdSha256() {
        return paramTable.get("android_id_sha256");
    }

    private void setAndroidIdSha256(String android_id_sha256) {
        putInParamTable("android_id_sha256", android_id_sha256);
    }

    /**
     * Gets the app name
     * @return app name
     */
    public String getAppName() {
        return paramTable.get("an");
    }

    private void setAppName(String app_name) {
        putInParamTable("an", app_name);
    }

    /**
     * Gets the app version
     * @return app version
     */
    public int getAppVersion() {
        if (paramTable.get("av") == null) {
            return 0;
        }
        return Integer.parseInt(paramTable.get("av"));
    }

    private void setAppVersion(int app_version) {
        putInParamTable("av", Integer.toString(app_version));
    }

    /**
     * Gets the device carrier if any
     * @return mobile device carrier/service provider name
     */
    public String getCarrier() {
        return paramTable.get("dc");
    }

    private void setCarrier(String carrier) {
        putInParamTable("dc", carrier);
    }

    /**
     * Gets the connection type (mobile or WIFI);.
     * @return whether device is connected by WIFI or mobile data connection
     */
    public String getConnectionType() {
        return paramTable.get("connection_type");
    }

    private void setConnectionType(String connection_type) {
        putInParamTable("connection_type", connection_type);
    }

    /**
     * Gets the ISO 639-1 country code
     * @return ISO 639-1 country code
     */
    public String getCountryCode() {
        return paramTable.get("cc");
    }

    private void setCountryCode(String country_code) {
        putInParamTable("cc", country_code);
    }

    /**
     * Gets the device brand/manufacturer (HTC, Apple, etc)
     * @return device brand/manufacturer name
     */
    public String getDeviceBrand() {
        return paramTable.get("db");
    }

    private void setDeviceBrand(String device_brand) {
        putInParamTable("db", device_brand);
    }

    /**
     * Gets the Device ID, also known as IMEI/MEID, if any
     * @return device IMEI/MEID
     */
    public String getDeviceId() {
        return paramTable.get("d");
    }

    private void setDeviceId(String device_id) {
        putInParamTable("d", device_id);
    }

    /**
     * Gets the device model name
     * @return device model name
     */
    public String getDeviceModel() {
        return paramTable.get("dm");
    }

    private void setDeviceModel(String device_model) {
        putInParamTable("dm", device_model);
    }

    /**
     * Gets the last event id set.
     * @return event ID in MAT
     */
    public String getEventId() {
        return paramTable.get("ei");
    }

    /**
     * Sets the event id set.
     * @return event_id the event ID in MAT
     */
    private void setEventId(String event_id) {
        putInParamTable("ei", event_id);
    }

    /**
     * Gets the last event name set.
     * @return event name in MAT
     */
    public String getEventName() {
        return paramTable.get("en");
    }

    private void setEventName(String event_name) {
        putInParamTable("en", event_name);
    }

    /**
     * Gets the date of app install
     * @return date that app was installed
     */
    public String getInstallDate() {
        return paramTable.get("id");
    }

    private void setInstallDate(String install_date) {
        putInParamTable("id", install_date);
    }

    /**
     * Gets the MAT install log ID
     * @return MAT install log ID
     */
    public String getInstallLogId() {
        // Get log id from SharedPreferences
        SharedPreferences SP = mContext.getSharedPreferences(MATConstants.PREFS_LOG_ID_INSTALL, Context.MODE_PRIVATE);
        return SP.getString("logId", "");
    }

    private void setInstallLogId(String logId) {
        // Store log id from install in SharedPreferences
        SharedPreferences SP = mContext.getSharedPreferences(MATConstants.PREFS_LOG_ID_INSTALL, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = SP.edit();
        editor.putString(MATConstants.PREFS_LOG_ID_KEY, logId);
        editor.commit();
    }

    /**
     * Gets the language of the device
     * @return device language
     */
    public String getLanguage() {
        return paramTable.get("l");
    }

    private void setLanguage(String language) {
        putInParamTable("l", language);
    }

    // Sets last date in given SharedPreferences file and key to given date
    private void setLastDate(SimpleDateFormat sdf, Calendar date, String prefsName, String key) {
        String dateStr = sdf.format(date.getTime());
        SharedPreferences SP = mContext.getSharedPreferences(prefsName, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = SP.edit();
        editor.putString(key, dateStr);
        editor.commit();
    }

    /**
     * Gets the MAC address of device
     * @return device MAC address
     */
    public String getMacAddress() {
        return paramTable.get("ma");
    }

    private void setMacAddress(String mac_address) {
        putInParamTable("ma", mac_address);
    }

    /**
     * Gets the MAT ID generated on install
     * @return MAT ID
     */
    public String getMatId() {
        return paramTable.get("mi");
    }

    private void setMatId(String mat_id) {
        putInParamTable("mi", mat_id);
    }

    /**
     * Gets the mobile country code.
     * @return mobile country code associated with the carrier
     */
    public String getMCC() {
        return paramTable.get("mobile_country_code");
    }

    private void setMCC(String mcc) {
        putInParamTable("mobile_country_code", mcc);
    }

    /**
     * Gets the mobile network code.
     * @return mobile network code associated with the carrier
     */
    public String getMNC() {
        return paramTable.get("mobile_network_code");
    }

    private void setMNC(String mnc) {
        putInParamTable("mobile_network_code", mnc);
    }

    /**
     * Gets the Android OS version
     * @return Android OS version
     */
    public String getOsVersion() {
        return paramTable.get("ov");
    }

    private void setOsVersion(String os_version) {
        putInParamTable("ov", os_version);
    }

    /**
     * Get SDK plugin name used
     * @return name of MAT plugin
     */
    public String getPluginName() {
        return paramTable.get("sdk_plugin");
    }

    /**
     * Set the name of plugin used, if any
     * @param plugin_name
     */
    public void setPluginName(String plugin_name) {
        // Validate plugin name
        if (Arrays.asList(MATConstants.PLUGIN_NAMES).contains(plugin_name)) {
            putInParamTable("sdk_plugin", plugin_name);
        } else {
            if (debugMode) {
                throw new IllegalArgumentException("Plugin name not acceptable");
            }
        }
    }

    private void setPurchaseStatus(int purchaseStatus) {
        putInParamTable("android_purchase_status", Integer.toString(purchaseStatus));
    }

    /**
     * Gets the package name of the app that started this Activity, if any
     * @return source package name that caused open via StartActivityForResult
     */
    public String getReferralSource() {
        return paramTable.get("referral_source");
    }

    private void setReferralSource(String referralPackage) {
        putInParamTable("referral_source", referralPackage);
    }

    /**
     * Gets the url scheme that started this Activity, if any
     * @return full url of app scheme that caused open
     */
    public String getReferralUrl() {
        return paramTable.get("referral_url");
    }

    private void setReferralUrl(String referralUrl) {
        putInParamTable("referral_url", referralUrl);
    }

    /**
     * Gets the screen density of the device
     * @return 0.75/1.0/1.5/2.0/3.0/4.0 for ldpi/mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi
     */
    public String getScreenDensity() {
        return paramTable.get("screen_density");
    }

    private void setScreenDensity(String density) {
        putInParamTable("screen_density", density);
    }

    /**
     * Gets the screen size of the device
     * @return widthxheight
     */
    public String getScreenSize() {
        return paramTable.get("screen_layout_size");
    }

    private void setScreenSize(String screensize) {
        putInParamTable("screen_layout_size", screensize);
    }

    /**
     * Gets the MAT SDK version
     * @return MAT SDK version
     */
    public String getSDKVersion() {
        return MATConstants.SDK_VERSION;
    }

    /**
     * Gets the MAT update log ID
     * @return MAT update log ID
     */
    public String getUpdateLogId() {
        // Get log id from SharedPreferences
        SharedPreferences SP = mContext.getSharedPreferences(MATConstants.PREFS_LOG_ID_UPDATE, Context.MODE_PRIVATE);
        return SP.getString("logId", "");
    }

    private void setUpdateLogId(String logId) {
        // Store log id from install in SharedPreferences
        SharedPreferences SP = mContext.getSharedPreferences(MATConstants.PREFS_LOG_ID_UPDATE, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = SP.edit();
        editor.putString(MATConstants.PREFS_LOG_ID_KEY, logId);
        editor.commit();
    }

    /**
     * Gets the device browser user agent
     * @return device user agent
     */
    public String getUserAgent() {
        return paramTable.get("ua");
    }

    private void setUserAgent(String user_agent) {
        putInParamTable("ua", user_agent);
    }

    /**
     * Helper method to UTF-8 encode and null-check before putting value in param table.
     * @param key the key
     * @param value the value
     */
    private void putInParamTable(String key, String value) {
        if (key != null && value != null) {
            try {
                value = URLEncoder.encode(value, "UTF-8");
            } catch (UnsupportedEncodingException e) {
                e.printStackTrace();
            }
            paramTable.put(key, value);
        }
    }

    /**
     * Enable sending ANDROID_ID as MD5 hash in request - removes raw ANDROID_ID
     */
    public void setUseAndroidIdMd5() {
        setAndroidIdMd5(Encryption.md5(Secure.getString(mContext.getContentResolver(), Secure.ANDROID_ID)));
        setAndroidId("");
    }

    /**
     * Enable sending ANDROID_ID as SHA-1 hash in request - removes raw ANDROID_ID
     */
    public void setUseAndroidIdSha1() {
        setAndroidIdSha1(Encryption.sha1(Secure.getString(mContext.getContentResolver(), Secure.ANDROID_ID)));
        setAndroidId("");
    }

    /**
     * Enable sending ANDROID_ID as SHA-256 hash in request - removes raw ANDROID_ID
     */
    public void setUseAndroidIdSha256() {
        setAndroidIdSha256(Encryption.sha256(Secure.getString(mContext.getContentResolver(), Secure.ANDROID_ID)));
        setAndroidId("");
    }

    /**
     * Enables acceptance of duplicate installs from this device.
     * @param allow whether to allow duplicate installs from device
     */
    public void setAllowDuplicates(boolean allow) {
        allowDups = allow;
    }

    /**
     * Turns debug mode on or off, under tag "MobileAppTracker".
     * @param debug whether to enable debug output
     */
    public void setDebugMode(boolean debug) {
        debugMode = debug;
    }

    /**
     * Facebook's code for retrieving Facebook cookie value
     * @param contentResolver app's ContentResolver to access to FB ContentProvider
     * @return Facebook cookie id, or null if not there
     */
    private String getAttributionId(ContentResolver contentResolver) {
        String [] projection = {ATTRIBUTION_ID_COLUMN_NAME};
        Cursor c = contentResolver.query(ATTRIBUTION_ID_CONTENT_URI, projection, null, null, null);
        if (c == null || !c.moveToFirst()) {
            return null;
        }
        String attributionId = c.getString(c.getColumnIndex(ATTRIBUTION_ID_COLUMN_NAME));
        c.close();
        return attributionId;
    }

    /**
     * Helper method for whether String contains a char.
     * @param s the string
     * @return whether given String contains a char
     */
    private static boolean containsChar(final String s) {
        for (char c: s.toCharArray()) {
            if (Character.isLetter(c)) {
                return true;
            }
        }
        return false;
    }
}