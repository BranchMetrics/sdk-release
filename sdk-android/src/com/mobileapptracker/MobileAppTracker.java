package com.mobileapptracker;

import java.io.File;
import java.io.UnsupportedEncodingException;
import java.lang.ref.WeakReference;
import java.net.URLDecoder;
import java.net.URLEncoder;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;

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
public class MobileAppTracker {
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
            "twitter_user_id",
            "attribute_sub1",
            "attribute_sub2",
            "attribute_sub3",
            "attribute_sub4",
            "attribute_sub5",
            "user_name",
            "user_email");

    // Interface for reading platform response to tracking calls
    protected MATResponse matResponse;
    // Interface for making url requests
    private UrlRequester urlRequester;
    // Interface for testing URL requests
    protected MATTestRequest matRequest; // note: this has no setter - must subclass to set

    // Whether connectivity receiver is registered or not
    protected boolean isRegistered;
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

    // Connectivity receiver
    protected BroadcastReceiver networkStateReceiver;
    // Table of fields to pass in http request
    private ConcurrentHashMap<String, String> paramTable;
    // The context passed into the constructor
    protected Context mContext;
    // Local Encryption object
    private Encryption encryption;
    // Thread pool for running the GetLink Runnables
    private ScheduledExecutorService pool;

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
     * Instantiates a new MobileAppTracker singleton.
     * @param context the application context
     * @param advertiserId the MAT advertiser ID for the app
     * @param key the MAT advertiser key for the app
     * @param collectDeviceId whether to collect device ID
     * @param collectMacAddress whether to collect MAC address
     */
    public static void init(Context context, String advertiserId, String key, boolean collectDeviceId, boolean collectMacAddress) {
        mat = new MobileAppTracker();
        mat.initAll(context, advertiserId, key, collectDeviceId, collectMacAddress);
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
     * Private initialization function for MobileAppTracker.
     * @param context the application context
     * @param advertiserId the MAT advertiser ID for the app
     * @param key the MAT advertiser key for the app
     * @param collectDeviceId whether to collect device ID
     * @param collectMacAddress whether to collect MAC address
     */
    protected void initAll(Context context, String advertiserId, String key, boolean collectDeviceId, boolean collectMacAddress) {
        initLocalVariables(context, key, collectDeviceId, collectMacAddress);
        initialized = populateRequestParamTable(context, advertiserId);

        eventQueue = new MATEventQueue(context, mat);
        
        // Dump any existing requests in queue on start
        if (initialized) {
            dumpQueue();
        }

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
            context.getApplicationContext().unregisterReceiver(networkStateReceiver);
            isRegistered = false;
        }

        IntentFilter filter = new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION);
        context.getApplicationContext().registerReceiver(networkStateReceiver, filter);
        isRegistered = true;
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
                setDeviceCarrier(tm.getNetworkOperatorName());

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
            setCurrencyCode(MATConstants.DEFAULT_CURRENCY_CODE);

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
        String matId = getStringFromSharedPreferences(context, MATConstants.PREFS_MAT_ID, "mat_id");
        if (matId.length() == 0) {
            // generate MAT ID once and save in shared preferences
            matId = UUID.randomUUID().toString();
            saveToSharedPreferences(context, MATConstants.PREFS_MAT_ID, "mat_id", matId);
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
    public boolean isOnline(Context context) {
        ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo activeNetworkInfo = connectivityManager.getActiveNetworkInfo();
        return activeNetworkInfo != null && activeNetworkInfo.isConnected();
    }

    protected void addEventToQueue(String link, String eventItems, String action, double revenue, String currency, String refId, String inAppPurchaseData,
            String inAppSignature, String eventAttribute1, String eventAttribute2, String eventAttribute3, String eventAttribute4, String eventAttribute5, boolean shouldBuildData, Date runDate) {
        pool.execute(eventQueue.new Add(
                link,
                eventItems,
                action,
                revenue,
                currency,
                refId,
                inAppPurchaseData,
                inAppSignature,
                eventAttribute1,
                eventAttribute2,
                eventAttribute3,
                eventAttribute4,
                eventAttribute5,
                shouldBuildData,
                runDate));
    }

    protected void dumpQueue() {
        if (!isOnline(mContext)) return;
        
        pool.execute(eventQueue.new Dump());
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
    public String setTracking(
                              String publisherAdvertiserId,
                              String targetPackageName,
                              String publisherId,
                              String campaignId,
                              boolean doRedirect
                             ) {
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
     * Main tracking session function; this function should be called at every app open.
     * @return 1 on request sent and -1 on failure
     */
    public int trackSession() {
        return track("session", null, getRevenue(), getCurrencyCode(), getRefId(), null, null);
    }

    /**
     * trackSession call that bypasses already-sent check
     * and with post_conversion=1 for updating referrer value of existing MAT install
     */
    void trackSessionWithReferrer() {
        postConversion = true;
        track("session", null, 0, null, null, null, null);
        postConversion = false;
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
    public int trackPurchase(
                             String event, 
                             int purchaseStatus,
                             double revenue,
                             String currency,
                             String refId,
                             String inAppPurchaseData,
                             String inAppSignature
                            ) {
        setPurchaseStatus(purchaseStatus);
        return track(event, null, revenue, currency, refId, inAppPurchaseData, inAppSignature);
    }

    /**
     * Tracking event function, track events by event ID or name.
     * @param event event name or event ID in MAT system
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event) {
        return track(event, null, 0, getCurrencyCode(), null, null, null);
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
        return track(event, jsonArray.toString(), 0, getCurrencyCode(), null, null, null);
    }
    
    /**
     * Tracking event function, track events by event ID or name, event item, revenue, currency, and advertiser ref ID.
     * @param event event name or event ID in MAT system
     * @param eventItem event item to post to server.
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, MATEventItem eventItem, double revenue, String currency, String refId) {
        return trackAction(event, eventItem, revenue, currency, refId, null, null);
    }

    /**
     * Tracking event function, track events by event ID or name, event item, and
     *  in-app purchase data and signature for purchase verification.
     * @param event event name or event ID in MAT system
     * @param eventItem event item to post to server.
     * @param inAppPurchaseData the receipt data from Google Play
     * @param inAppSignature the receipt signature from Google Play
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, MATEventItem eventItem, double revenue, String currency, String refId, String inAppPurchaseData, String inAppSignature) {
        JSONArray jsonArray = new JSONArray();
        jsonArray.put(eventItem.toJSON());
        return track(event, jsonArray.toString(), revenue, currency, refId, inAppPurchaseData, inAppSignature);
    }

    /**
     * Tracking event function, track events by event ID or name, and a list of event items.
     * @param event event name or event ID in MAT system
     * @param list List of event items to post to server.
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, List<MATEventItem> list) {
        return trackAction(event, list, 0, getCurrencyCode(), null, null, null);
    }

    /**
     * Tracking event function, track events by event ID or name, a list of event items,
     *  revenue, currency, and advertiser ref ID.
     * @param event event name or event ID in MAT system
     * @param list List of event items to post to server.
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, List<MATEventItem> list, double revenue, String currency, String refId) {
        return trackAction(event, list, revenue, currency, refId, null, null);
    }

    /**
     * Tracking event function, track events by event ID or name, a list of event items,
     *  and in-app purchase data and signature for purchase verification.
     * @param event event name or event ID in MAT system
     * @param list List of event items to post to server.
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     * @param inAppPurchaseData the receipt data from Google Play
     * @param inAppSignature the receipt signature from Google Play
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, List<MATEventItem> list, double revenue, String currency, String refId, String inAppPurchaseData, String inAppSignature) {
        // Create a JSONArray of event items
        JSONArray jsonArray = new JSONArray();
        for (int i = 0; i < list.size(); i++) {
            jsonArray.put(list.get(i).toJSON());
        }
        return track(event, jsonArray.toString(), revenue, currency, refId, inAppPurchaseData, inAppSignature);
    }

    /**
     * Tracking event function, track events by event ID or name, revenue.
     * @param event event name or event ID in MAT system
     * @param revenue revenue amount tied to the action
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, double revenue) {
        return trackAction(event, revenue, getCurrencyCode(), null);
    }

    /**
     * Tracking event function, track events by event ID or name, revenue and currency.
     * @param event event name or event ID in MAT system
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(String event, double revenue, String currency) {
        return trackAction(event, revenue, currency, null);
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
     * Tracking event function, track events by event ID or name, revenue, currency,
     * advertiser ref ID, and in-app purchase data and signature for purchase verification.
     * @param event event name or event ID in MAT system
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @param refId the advertiser ref ID to associate with the event
     * @param inAppPurchaseData the receipt data from Google Play
     * @param inAppSignature the receipt signature from Google Play
     * @return 1 on request sent and -1 on failure.
     */
    public int trackAction(
                           String event,
                           double revenue,
                           String currency,
                           String refId,
                           String inAppPurchaseData,
                           String inAppSignature
                          ) {
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
    private synchronized int track(
                                   String event,
                                   String eventItems,
                                   double revenue,
                                   String currency,
                                   String refId,
                                   String inAppPurchaseData,
                                   String inAppSignature
                                  ) {
        if (!initialized) return -1;

        dumpQueue();

        setAction("conversion"); // Default to conversion
        Date runDate = new Date();
        if (containsChar(event)) { // check if eventid contains a character
            if (event.equals("close")) return -1; // Don't send close events anymore
            else if (event.equals("open") || event.equals("install") || 
                     event.equals("update") || event.equals("session")) {
                setAction("session");
                runDate = new Date(runDate.getTime() + MATConstants.DELAY);
            }
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

        addEventToQueue(link, eventItems, getAction(), revenue, currency, refId, inAppPurchaseData, inAppSignature, 
                getEventAttribute1(), getEventAttribute2(), getEventAttribute3(), getEventAttribute4(), getEventAttribute5(), true, runDate);
        dumpQueue();

        // Clear the parameters that should be reset between events
        setEventId(null);
        setEventName(null);
        setRevenue(0);
        setCurrencyCode(MATConstants.DEFAULT_CURRENCY_CODE);
        setRefId(null);
        setEventAttribute1(null);
        setEventAttribute2(null);
        setEventAttribute3(null);
        setEventAttribute4(null);
        setEventAttribute5(null);

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

        if (existingUser) {
            link.append("&existing_user=1");
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
    private String buildData(String origLink, String action, double revenue, String currency, String refId,
            String attribute1, String attribute2, String attribute3, String attribute4, String attribute5) {
        StringBuilder link = new StringBuilder(origLink);

        setRevenue(revenue);
        if (currency != null) {
            setCurrencyCode(currency);
        }
        setRefId(refId);
        setEventAttribute1(attribute1);
        setEventAttribute2(attribute2);
        setEventAttribute3(attribute3);
        setEventAttribute4(attribute4);
        setEventAttribute5(attribute5);

        // Try to update referrer value if we don't have one
        if (getInstallReferrer() == null || getInstallReferrer().length() == 0) {
            String referrer = getStringFromSharedPreferences(mContext, MATConstants.PREFS_REFERRER, "referrer");
            setInstallReferrer(referrer);
        }

        // Append install log id if we have it stored
        if (getInstallLogId().length() > 0) {
            link.append("&install_log_id=" + getInstallLogId());
        } else if (getUpdateLogId().length() > 0) {
            link.append("&update_log_id=" + getUpdateLogId());
        }
        
        // Append open log IDs if we have them
        if (getOpenLogId().length() > 0) {
            link.append("&open_log_id=" + getOpenLogId());
        }
        if (getLastOpenLogId().length() > 0) {
            link.append("&last_open_log_id=" + getLastOpenLogId());
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
        String intent = getStringFromSharedPreferences(mContext, MATConstants.PREFS_FACEBOOK_INTENT, "action");
        if (intent.length() != 0) {
            try {
                intent = URLEncoder.encode(intent, "UTF-8");
            } catch (UnsupportedEncodingException e) {
                e.printStackTrace();
            }
            // Append Facebook re-engagement intent to url as "source"
            link.append("&source=").append(intent);
            // Clear the fb intent
            SharedPreferences.Editor editor = mContext.getSharedPreferences(MATConstants.PREFS_FACEBOOK_INTENT, Context.MODE_PRIVATE).edit();
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

        if (matRequest != null) {
            matRequest.paramsToBeEncrypted(data.toString());
        }

        try {
            data = new StringBuilder(Encryption.bytesToHex(encryption.encrypt(data.toString())));
        } catch (Exception e) {
            e.printStackTrace();
        }
        link.append("&da=").append(data.toString());

        return link.toString();
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

    /*
     * Helper function for making single request and displaying response
     */
    protected void makeRequest(
            String link,
            String eventItems,
            String action,
            double revenue,
            String currency,
            String refId,
            String iapData,
            String iapSignature,
            String eventAttribute1,
            String eventAttribute2,
            String eventAttribute3,
            String eventAttribute4,
            String eventAttribute5,
            boolean shouldBuildData) {

        if (shouldBuildData) {
            link = buildData(link, action, revenue, currency, refId, eventAttribute1, eventAttribute2, eventAttribute3, eventAttribute4, eventAttribute5);
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

        // Callback to request verification (testing) interface
        if( matRequest != null ) {
            matRequest.constructedRequest( link, postData );
        }

        if (debugMode) {
            Log.d(MATConstants.TAG, "Sending " + action + " event to server...");
        }

        JSONObject response = urlRequester.requestUrl(link, postData);

        // if reponse is null, it was a bad request
        if (response == null) return;
        
        // if response is empty, it should be requeued
        try {
            if (response.getString("success") == null) {
                addEventToQueue(link, eventItems, action, revenue, currency, refId, iapData, iapSignature,
                        eventAttribute1, eventAttribute2, eventAttribute3, eventAttribute4, eventAttribute5, false, new Date());
                if (debugMode) Log.d(MATConstants.TAG, "Request failed: track will be queued");
                return;
            }
        } catch (JSONException e) {
            e.printStackTrace();
            return;
        }

        // notify matResponse of success or failure
        if (matResponse != null) {
            try {
                if (response.getString("success").equals("true")) {
                    matResponse.didSucceedWithData(response);
                } else {
                    matResponse.didFailWithError(response);
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }

        // save open log id
        try {
            String eventType = response.getString("site_event_type");
            if (eventType.equals("open")) {
                String logId = response.getString("log_id");
                if (getOpenLogId() == null) {
                    setOpenLogId(logId);
                }
                setLastOpenLogId(logId);
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
    }

    /******************
     * Public Getters *
     ******************/

    /**
     * Gets the action of the event
     * @return install/update/conversion
     */
    public String getAction() {
        return paramTable.get("ac");
    }

    /**
     * Gets the MAT advertiser ID.
     * @return MAT advertiser ID
     */
    public String getAdvertiserId() {
        return paramTable.get("adv");
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
     * Gets the ANDROID_ID of the device
     * @return ANDROID_ID
     */
    public String getAndroidId() {
        return paramTable.get("ad");
    }

    /**
     * Gets the MD5 hash of the ANDROID_ID of the device
     * @return ANDROID_ID MD5 hash
     */
    public String getAndroidIdMd5() {
        return paramTable.get("android_id_md5");
    }

    /**
     * Gets the SHA-1 hash of the ANDROID_ID of the device
     * @return ANDROID_HD SHA-1 hash
     */
    public String getAndroidIdSha1() {
        return paramTable.get("android_id_sha1");
    }
    
    /**
     * Gets the SHA-256 hash of the ANDROID_ID of the device
     * @return ANDROID_HD SHA-256 hash
     */
    public String getAndroidIdSha256() {
        return paramTable.get("android_id_sha256");
    }

    /**
     * Gets the app name
     * @return app name
     */
    public String getAppName() {
        return paramTable.get("an");
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

    /**
     * Gets the connection type (mobile or WIFI);.
     * @return whether device is connected by WIFI or mobile data connection
     */
    public String getConnectionType() {
        return paramTable.get("connection_type");
    }

    /**
     * Gets the ISO 639-1 country code
     * @return ISO 639-1 country code
     */
    public String getCountryCode() {
        return paramTable.get("cc");
    }

    /**
     * Gets the device brand/manufacturer (HTC, Apple, etc)
     * @return device brand/manufacturer name
     */
    public String getDeviceBrand() {
        return paramTable.get("db");
    }

    /**
     * Gets the Device ID, also known as IMEI/MEID, if any
     * @return device IMEI/MEID
     */
    public String getDeviceId() {
        return paramTable.get("d");
    }

    /**
     * Gets the device model name
     * @return device model name
     */
    public String getDeviceModel() {
        return paramTable.get("dm");
    }

    /**
     * Gets the ISO 4217 currency code.
     * @return ISO 4217 currency code
     */
    public String getCurrencyCode() {
        return paramTable.get("c");
    }

    /**
     * Gets the device carrier if any
     * @return mobile device carrier/service provider name
     */
    public String getDeviceCarrier() {
        return paramTable.get("dc");
    }

    public String getEventAttribute1() {
        return paramTable.get("attribute_sub1");
    }

    public String getEventAttribute2() {
        return paramTable.get("attribute_sub2");
    }

    public String getEventAttribute3() {
        return paramTable.get("attribute_sub3");
    }

    public String getEventAttribute4() {
        return paramTable.get("attribute_sub4");
    }

    public String getEventAttribute5() {
        return paramTable.get("attribute_sub5");
    }

    /**
     * Gets the last event id set.
     * @return event ID in MAT
     */
    public String getEventId() {
        return paramTable.get("ei");
    }

    /**
     * Gets the last event name set.
     * @return event name in MAT
     */
    public String getEventName() {
        return paramTable.get("en");
    }

    /**
     * Gets value previously set of existing user or not.
     * @return whether user existed prior to install
     */
    public boolean getExistingUser() {
        return existingUser;
    }

    /**
     * Gets the Facebook user ID previously set.
     * @return Facebook user ID
     */
    public String getFacebookUserId() {
        return paramTable.get("facebook_user_id");
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
     * Gets the Google Play Services Advertising ID.
     * @return Google advertising ID
     */
    public String getGoogleAdvertisingId() {
        return paramTable.get("google_aid");
    }

    /**
     * Gets the Google user ID previously set.
     * @return Google user ID
     */
    public String getGoogleUserId() {
        return paramTable.get("google_user_id");
    }

    /**
     * Gets the date of app install
     * @return date that app was installed
     */
    public String getInstallDate() {
        return paramTable.get("id");
    }

    /**
     * Gets the MAT install log ID
     * @return MAT install log ID
     */
    public String getInstallLogId() {
        // Get log id from SharedPreferences
        return getStringFromSharedPreferences(mContext, MATConstants.PREFS_LOG_ID_INSTALL, MATConstants.PREFS_LOG_ID_KEY);
    }

    /**
     * Gets the Google Play INSTALL_REFERRER
     * @return Play INSTALL_REFERRER
     */
    public String getInstallReferrer() {
        return paramTable.get("ir");
    }

    /**
     * Gets the language of the device
     * @return device language
     */
    public String getLanguage() {
        return paramTable.get("l");
    }

    /**
     * Gets the last MAT open log ID
     * @return most recent MAT open log ID
     */
    public String getLastOpenLogId() {
        // Get log id from SharedPreferences
        return getStringFromSharedPreferences(mContext, MATConstants.PREFS_LOG_ID_LAST_OPEN, MATConstants.PREFS_LOG_ID_KEY);
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
     * Get whether the user has limit ad tracking enabled or not.
     * @return limit ad tracking enabled or not
     */
    public boolean getLimitAdTrackingEnabled() {
        int isLATEnabled = Integer.parseInt(paramTable.get("app_ad_tracking"));
        return (isLATEnabled == 0);
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
     * Gets the MAC address of device
     * @return device MAC address
     */
    public String getMacAddress() {
        return paramTable.get("ma");
    }

    /**
     * Gets the MAT ID generated on install
     * @return MAT ID
     */
    public String getMatId() {
        return paramTable.get("mi");
    }

    /**
     * Gets the mobile country code.
     * @return mobile country code associated with the carrier
     */
    public String getMCC() {
        return paramTable.get("mobile_country_code");
    }

    /**
     * Gets the mobile network code.
     * @return mobile network code associated with the carrier
     */
    public String getMNC() {
        return paramTable.get("mobile_network_code");
    }

    /**
     * Gets the first MAT open log ID
     * @return first MAT open log ID
     */
    public String getOpenLogId() {
        // Get log id from SharedPreferences
        return getStringFromSharedPreferences(mContext, MATConstants.PREFS_LOG_ID_OPEN, MATConstants.PREFS_LOG_ID_KEY);
    }

    /**
     * Gets the Android OS version
     * @return Android OS version
     */
    public String getOsVersion() {
        return paramTable.get("ov");
    }

    
    /**
     * Gets the app package name
     * @return package name of app
     */
    public String getPackageName() {
        return paramTable.get("pn");
    }

    /**
     * Get SDK plugin name used
     * @return name of MAT plugin
     */
    public String getPluginName() {
        return paramTable.get("sdk_plugin");
    }

    /**
     * Gets the package name of the app that started this Activity, if any
     * @return source package name that caused open via StartActivityForResult
     */
    public String getReferralSource() {
        return paramTable.get("referral_source");
    }

    /**
     * Gets the url scheme that started this Activity, if any
     * @return full url of app scheme that caused open
     */
    public String getReferralUrl() {
        return paramTable.get("referral_url");
    }

    /**
     * Gets the advertiser ref ID.
     * @return advertiser ref ID set by SDK
     */
    public String getRefId() {
        return paramTable.get("ar");
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
     * Gets the screen density of the device
     * @return 0.75/1.0/1.5/2.0/3.0/4.0 for ldpi/mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi
     */
    public String getScreenDensity() {
        return paramTable.get("screen_density");
    }

    /**
     * Gets the screen size of the device
     * @return widthxheight
     */
    public String getScreenSize() {
        return paramTable.get("screen_layout_size");
    }

    /**
     * Gets the MAT SDK version
     * @return MAT SDK version
     */
    public String getSDKVersion() {
        return MATConstants.SDK_VERSION;
    }

    /**
     * Gets the MAT site ID set
     * @return site ID in MAT
     */
    public String getSiteId() {
        return paramTable.get("si");
    }

    /**
     * Gets the TRUSTe ID set
     * @return TRUSTe ID
     */
    public String getTRUSTeId() {
        return paramTable.get("tpid");
    }

    /**
     * Gets the Twitter user ID previously set.
     * @return Twitter user ID
     */
    public String getTwitterUserID() {
        return paramTable.get("twitter_user_id");
    }

    /**
     * Gets the MAT update log ID
     * @return MAT update log ID
     */
    public String getUpdateLogId() {
        // Get log id from SharedPreferences
        return getStringFromSharedPreferences(mContext, MATConstants.PREFS_LOG_ID_UPDATE, MATConstants.PREFS_LOG_ID_KEY);
    }

    /**
     * Gets the device browser user agent
     * @return device user agent
     */
    public String getUserAgent() {
        return paramTable.get("ua");
    }

    /**
     * Gets the custom user email.
     * @return custom user email
     */
    public String getUserEmail() {
        String userEmail = paramTable.get("user_email");
        try {
            URLDecoder.decode(userEmail, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        return userEmail;
    }

    /**
     * Gets the custom user ID.
     * @return custom user id
     */
    public String getUserId() {
        return paramTable.get("ui");
    }

    /**
     * Gets the custom user name.
     * @return custom user name
     */
    public String getUserName() {
        return paramTable.get("user_name");
    }

    /******************
     * Public Setters *
     ******************/

    /**
     * Sets the user's age.
     * @param age User age to track in MAT
     */
    public void setAge(int age) {
        putInParamTable("age", Integer.toString(age));
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
     * Sets the ISO 4217 currency code.
     * @param currency_code the currency code
     */
    public void setCurrencyCode(String currency_code) {
        if (currency_code == null || currency_code.equals("")) {
            setCurrencyCode(MATConstants.DEFAULT_CURRENCY_CODE);
        } else {
            putInParamTable("c", currency_code);
        }
    }

    public void setEventAttribute1(String value) {
        setEventAttribute(1, value);
    }

    public void setEventAttribute2(String value) {
        setEventAttribute(2, value);
    }

    public void setEventAttribute3(String value) {
        setEventAttribute(3, value);
    }

    public void setEventAttribute4(String value) {
        setEventAttribute(4, value);
    }

    public void setEventAttribute5(String value) {
        setEventAttribute(5, value);
    }

    /**
     * Sets the user ID to associate with Facebook
     * @param fb_user_id
     */
    public void setFacebookUserId(String fb_user_id) {
        putInParamTable("facebook_user_id", fb_user_id);
    }

    /**
     * Sets the user gender.
     * @param gender use MobileAppTracker.GENDER_MALE, MobileAppTracker.GENDER_FEMALE
     */
    public void setGender(int gender) {
        putInParamTable("gender", Integer.toString(gender));
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
     * Overrides the Google Play INSTALL_REFERRER received
     * @param referrer Your custom referrer value
     */
    public void setInstallReferrer(String referrer) {
        putInParamTable("ir", referrer);
    }

    /**
     * Sets the device latitude.
     * @param latitude the device latitude
     */
    public void setLatitude(double latitude) {
        putInParamTable("latitude", Double.toString(latitude));
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
     * Sets the app package name
     * @param package_name App package name
     */
    public void setPackageName(String package_name) {
        if (package_name == null || package_name.equals("")) {
            setPackageName(mContext.getPackageName());
        } else {
            putInParamTable("pn", package_name);
        }
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
     * Sets the MAT site ID to specify which app to attribute to
     * @param site_id MAT site ID to attribute to
     */
    public void setSiteId(String site_id) {
        putInParamTable("si", site_id);
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
     * Sets the custom user email.
     * @param user_email
     */
    public void setUserEmail(String user_email) {
        putInParamTable("user_email", user_email);
    }

    /**
     * Sets the custom user ID.
     * @param user_id the new user id
     */
    public void setUserId(String user_id) {
        putInParamTable("ui", user_id);
    }

    /**
     * Sets the custom user name.
     * @param user_name
     */
    public void setUserName(String user_name) {
        putInParamTable("user_name", user_name);
    }

    /*******************
     * Private Setters *
     *******************/

    private void setAdvertiserId(String advertiserId) {
        putInParamTable("adv", advertiserId);
    }

    private void setAction(String action) {
        putInParamTable("ac", action);
    }

    private void setAndroidId(String android_id) {
        putInParamTable("ad", android_id);
    }

    private void setAndroidIdMd5(String android_id_md5) {
        putInParamTable("android_id_md5", android_id_md5);
    }

    private void setAndroidIdSha1(String android_id_sha1) {
        putInParamTable("android_id_sha1", android_id_sha1);
    }

    private void setAndroidIdSha256(String android_id_sha256) {
        putInParamTable("android_id_sha256", android_id_sha256);
    }

    private void setAppName(String app_name) {
        putInParamTable("an", app_name);
    }

    private void setAppVersion(int app_version) {
        putInParamTable("av", Integer.toString(app_version));
    }

    private void setConnectionType(String connection_type) {
        putInParamTable("connection_type", connection_type);
    }

    private void setCountryCode(String country_code) {
        putInParamTable("cc", country_code);
    }

    private void setDeviceBrand(String device_brand) {
        putInParamTable("db", device_brand);
    }

    private void setDeviceCarrier(String carrier) {
        putInParamTable("dc", carrier);
    }

    private void setDeviceId(String device_id) {
        putInParamTable("d", device_id);
    }

    private void setDeviceModel(String device_model) {
        putInParamTable("dm", device_model);
    }

    private void setEventAttribute(int number, String value) {
        putInParamTable("attribute_sub" + number, value);
    }

    private void setEventId(String event_id) {
        putInParamTable("ei", event_id);
    }

    private void setEventName(String event_name) {
        putInParamTable("en", event_name);
    }

    private void setInstallDate(String install_date) {
        putInParamTable("id", install_date);
    }

    private void setLanguage(String language) {
        putInParamTable("l", language);
    }

    private void setLastOpenLogId(String logId) {
        // Store log id in SharedPreferences
        saveToSharedPreferences(mContext, MATConstants.PREFS_LOG_ID_LAST_OPEN, MATConstants.PREFS_LOG_ID_KEY, logId);
    }

    private void setMacAddress(String mac_address) {
        putInParamTable("ma", mac_address);
    }

    private void setMatId(String mat_id) {
        putInParamTable("mi", mat_id);
    }

    private void setMCC(String mcc) {
        putInParamTable("mobile_country_code", mcc);
    }

    private void setMNC(String mnc) {
        putInParamTable("mobile_network_code", mnc);
    }

    private void setOpenLogId(String logId) {
        // Store log id in SharedPreferences
        saveToSharedPreferences(mContext, MATConstants.PREFS_LOG_ID_OPEN, MATConstants.PREFS_LOG_ID_KEY, logId);
    }

    private void setOsVersion(String os_version) {
        putInParamTable("ov", os_version);
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

    private void setReferralSource(String referralPackage) {
        putInParamTable("referral_source", referralPackage);
    }

    private void setReferralUrl(String referralUrl) {
        putInParamTable("referral_url", referralUrl);
    }

    private void setRefId(String ref_id) {
        putInParamTable("ar", ref_id);
    }

    private void setRevenue(double revenue) {
        putInParamTable("r", Double.toString(revenue));
    }

    private void setScreenDensity(String density) {
        putInParamTable("screen_density", density);
    }

    private void setScreenSize(String screensize) {
        putInParamTable("screen_layout_size", screensize);
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
            if (value.equals("")) {
                paramTable.remove(key);
            } else {
                try {
                    value = URLEncoder.encode(value, "UTF-8");
                } catch (UnsupportedEncodingException e) {
                    e.printStackTrace();
                }
                paramTable.put(key, value);
            }
        } else if (key != null && value == null) {
            paramTable.remove(key);
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

    private void saveToSharedPreferences(Context context, String prefsName, String prefsKey, String prefsValue) {
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE).edit().putString(prefsKey, prefsValue).commit();
    }

    private String getStringFromSharedPreferences(Context context, String prefsName, String prefsKey) {
        return context.getSharedPreferences(prefsName, Context.MODE_PRIVATE).getString(prefsKey, "");
    }

    /**
     * Facebook's code for retrieving Facebook cookie value
     * @param contentResolver app's ContentResolver to access to FB ContentProvider
     * @return Facebook cookie id, or null if not there
     */
    protected String getAttributionId(ContentResolver contentResolver) {
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