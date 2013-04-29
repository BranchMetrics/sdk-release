package com.mobileapptracker;

import java.io.File;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
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

import android.app.AlertDialog;
import android.content.BroadcastReceiver;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.content.res.Resources;
import android.database.Cursor;
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
import android.view.View;
import android.view.WindowManager;
import android.webkit.WebSettings;
import android.webkit.WebView;

/**
 * @author tony@hasoffers.com
 * @author john.gu@hasoffers.com
 */
public class MobileAppTracker {
    private static final Uri ATTRIBUTION_ID_CONTENT_URI = Uri.parse("content://com.facebook.katana.provider.AttributionIdProvider");
    private static final String ATTRIBUTION_ID_COLUMN_NAME = "aid";
    private static final String IV = "heF9BATUfWuISyO8";
    
    // Interface for reading platform response to tracking calls
    private MATResponse matResponse;
    // Interface for making url requests
    private UrlRequester urlRequester;
    
    // Whether to allow duplicate installs from this device
    private boolean allowDups = false;
    // Whether to show debug output
    private boolean debugMode = false;
    // Whether variables were initialized correctly
    private boolean initialized = false;
    // Whether MobileAppTracker class was constructed
    private boolean constructed = false;
    // Whether to use https encryption or not
    private boolean httpsEncryption = true;
    // Whether app has been installed or not
    private String install;
    // Advertiser key in our system
    private String key;
    
    // Table of fields to pass in http request
    private ConcurrentHashMap<String, String> paramTable;
    // The context passed into the constructor
    private Context context;
    // Local Encryption object
    private Encryption URLEnc;
    // Thread pool for running the GetLink Runnables
    private ScheduledExecutorService pool;
    // The fields to encrypt in http request
    private List<String> encryptList;
    // Binary semaphore for controlling adding to queue/dumping queue
    private Semaphore queueAvailable;
    // SharedPreferences for storing events that were not fired
    private SharedPreferences EventQueue;
    private SharedPreferences SP;

    /**
     * Instantiates a new MobileAppTracker.
     * @param context the application context
     * @param advertiserId the MAT advertiser ID for the app
     * @param key the MAT advertiser key for the app
     * @param collectDeviceId whether to collect device id
     * @param collectMacAddress whether to collect MAC address
     */
    public MobileAppTracker(Context context, String advertiserId, String key, boolean collectDeviceId, boolean collectMacAddress) {
        if (constructed) return;
        constructed = true;
        this.context = context;
        pool = Executors.newSingleThreadScheduledExecutor();
        queueAvailable = new Semaphore(1, true);
        urlRequester = new UrlRequester();
        
        paramTable = new ConcurrentHashMap<String, String>();
        encryptList = Arrays.asList("ir",
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
                                    "r",
                                    "c",
                                    "id",
                                    "ua",
                                    "tpid",
                                    "ar",
                                    "ti",
                                    "connection_type",
                                    "mobile_country_code",
                                    "mobile_network_code",
                                    "screen_density",
                                    "screen_layout_size",
                                    "android_purchase_status",
                                    "event_referrer");
        
        initialized = initializeVariables(context, advertiserId, key, collectDeviceId, collectMacAddress);
        URLEnc = new Encryption(key, MobileAppTracker.IV);
        EventQueue = context.getSharedPreferences(MATConstants.PREFS_NAME, 0);
        SP = context.getSharedPreferences(MATConstants.PREFS_INSTALL, 0);
        install = SP.getString("install", "");
        if (initialized && getQueueSize() > 0 && isOnline()) {
            dumpQueue();
        }
        
        // Set up connectivity listener so we dump the queue when re-connected to Internet
        BroadcastReceiver networkStateReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if (isOnline() && getQueueSize() > 0) {
                    dumpQueue();
                }
            }
        };
        
        // Unregister receiver in case one is still previously registered
        try {
            context.getApplicationContext().unregisterReceiver(networkStateReceiver);
        } catch (IllegalArgumentException e) {
        }
        IntentFilter filter = new IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION);
        context.getApplicationContext().registerReceiver(networkStateReceiver, filter);
    }

    /**
     * Instantiates a new MobileAppTracker with collectDeviceId, collectMacAddress enabled by default.
     * @param context the application context
     * @param advertiserId the MAT advertiser ID for the app
     * @param key the MAT advertiser key for the app
     */
    public MobileAppTracker(Context context, String advertiserId, String key) {
        this(context, advertiserId, key, true, true);
    }

    /**
     * Saves an event to the queue, used if there is no Internet connection.
     * @param link URL of the event postback
     * @param json (Optional) JSON information to post to server
     * @param action the action for the event (conversion/install/open)
     * @param revenue value associated with the event
     * @param currency currency code for the revenue
     * @param shouldBuildData whether link needs encrypted data to be appended or not
     */
    private void addEventToQueue(String link, String json, String action, double revenue, String currency, boolean shouldBuildData) {
        // Acquire semaphore before modifying queue
        try {
            queueAvailable.acquire();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        // JSON-serialize the link and json to store in Shared Preferences as a string
        JSONObject jsonEvent = new JSONObject();
        try {
            jsonEvent.put("link", link);
            if (json != null) {
                jsonEvent.put("json", json);
            }
            jsonEvent.put("action", action);
            jsonEvent.put("revenue", revenue);
            if (currency == null) {
                currency = "USD";
            }
            jsonEvent.put("currency", currency);
            jsonEvent.put("should_build_data", shouldBuildData);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        SharedPreferences.Editor editor = EventQueue.edit();
        int count = EventQueue.getInt("queuesize", 0);
        count += 1;
        String cnt = Integer.valueOf(count).toString();
        editor.putString(cnt, jsonEvent.toString());
        editor.putInt("queuesize", count);
        editor.commit();
        queueAvailable.release();
    }

    /**
     * Returns the current event queue size.
     * @return the event queue size
     */
    private int getQueueSize() {
        return EventQueue.getInt("queuesize", 0);
    }

    /**
     * Sets the event queue size to value.
     * @param value the new queue size
     */
    private void setQueueSize(int value) {
        SharedPreferences.Editor editor = EventQueue.edit();
        if (value < 0) value = 0;
        editor.putInt("queuesize", value);
        editor.commit();
    }

    /**
     * Processes the event queue, method will only process MAX_DUMP_SIZE events per call.
     * @return void
     */
    private synchronized void dumpQueue() {
        int size = getQueueSize();
        if (size == 0) {
            return;
        }
        
        int x = 1;
        if (size > MATConstants.MAX_DUMP_SIZE) {
            x = 1 + (size - MATConstants.MAX_DUMP_SIZE);
        }
        
        // Iterate through events and do postbacks for each, using GetLink
        for (; x <= size; x++) {
            String key = Integer.valueOf(x).toString();
            String eventJson = EventQueue.getString(key, null);
            
            if (eventJson != null) {
                String link = null;
                String json = null;
                String action = null;
                double revenue = 0;
                String currency = null;
                boolean shouldBuildData = false;
                try {
                    // De-serialize the stored string from the queue to get URL and json values
                    JSONObject event = new JSONObject(eventJson);
                    link = event.getString("link");
                    if (event.has("json")) {
                        json = event.getString("json");
                    }
                    action = event.getString("action");
                    revenue = event.getDouble("revenue");
                    currency = event.getString("currency");
                    shouldBuildData = event.getBoolean("should_build_data");
                } catch (JSONException e) {
                    e.printStackTrace();
                }
                
                if (link != null) {
                    try {
                        setQueueSize(getQueueSize() - 1);
                        SharedPreferences.Editor editor = EventQueue.edit();
                        editor.remove(key);
                        editor.commit();
                        pool.execute(new GetLink(link, json, action, revenue, currency, shouldBuildData));
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }
        }
    }

    /**
     * Returns the class initialization state.
     * @return whether MobileAppTracker was initialized or not
     */
    public boolean isInitialized() {
        return initialized;
    }

    /**
     * Returns true if an Internet connection is detected.
     * @return whether Internet connection exists
     */
    private boolean isOnline() {
        try {
            ConnectivityManager connectivityManager = (ConnectivityManager) this.context.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (connectivityManager.getActiveNetworkInfo() != null) {
                // we are connected to a network
                return true;
            }
        } catch (Exception e) {
        }
        return false;
    }

    /**
     * Initializes all main class variables.
     * @param context the application context
     * @param advertiserId the advertiser id in MAT
     * @param key the advertiser key
     * @param collectDeviceId whether to collect device id
     * @param collectMacAddress whether to collect MAC address
     * @return whether variables were initialized successfully
     */
    private boolean initializeVariables(Context context, String advertiserId, String key, boolean collectDeviceId, boolean collectMacAddress) {
        try {
            setAdvertiserId(advertiserId);
            setKey(key);
            setAction("conversion");
            
            SP = context.getSharedPreferences(MATConstants.PREFS_MAT_ID, 0);
            String matId = SP.getString("mat_id", "");
            if (matId.length() == 0) {
                // generate MAT ID once and save in shared preferences
                matId = UUID.randomUUID().toString();
                SharedPreferences.Editor editor = SP.edit();
                editor.putString("mat_id", matId);
                editor.commit();
            }
            setMatId(matId);
            setAndroidId(Secure.getString(context.getContentResolver(), Secure.ANDROID_ID));
            setDeviceModel(android.os.Build.MODEL);
            setDeviceBrand(android.os.Build.MANUFACTURER);
            setOsVersion(android.os.Build.VERSION.RELEASE);
            
            if (collectDeviceId) {
                setDeviceId(getDeviceId(context));
            }
            
            if (collectMacAddress) {
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
            
            // Set the device connection type, WIFI or mobile
            ConnectivityManager connManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            NetworkInfo mWifi = connManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);
            if (mWifi.isConnected()) {
                setConnectionType("WIFI");
            } else {
                setConnectionType("mobile");
            }
            
            TelephonyManager tm = (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);
            if (tm != null) {
                if (tm.getNetworkCountryIso() != null) {
                    setCountryCode(tm.getNetworkCountryIso());
                } else if (collectDeviceId) {
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
                    } catch (Exception e) {
                        // networkOperator is unreliable for CDMA devices
                        Log.d(MATConstants.TAG, "MCC/MNC not found");
                    }
                }
            } else {
                setCountryCode(Locale.getDefault().getCountry());
            }
            
            setLanguage(Locale.getDefault().getDisplayLanguage(Locale.US));
            setCurrencyCode("USD");
            
            try {
                Resources appR = context.getResources();
                CharSequence txt = appR.getText(appR.getIdentifier("app_name", "string", context.getPackageName()));
                setAppName(txt.toString());
            } catch (Exception e) {
                Log.d(MATConstants.TAG, "App name not found");
            }
            
            setPackageName(context.getPackageName());
            
            // retrieving Android market referrer value
            try {
                SP = context.getSharedPreferences(MATConstants.PREFS_REFERRER, 0);
                setReferrer(SP.getString("referrer", ""));
            } catch (Exception e) {
                Log.d(MATConstants.TAG, "Referrer not found");
            }
            
            try {
                SP = context.getSharedPreferences(MATConstants.PREFS_INSTALL, 0);
                install = SP.getString("install", "");
            } catch (Exception e) {
                install = "";
            }
            
            try {
                setAppVersion(context.getPackageManager().getPackageInfo(context.getPackageName(), 0).versionCode);
            } catch (Exception e) {
                Log.d(MATConstants.TAG, "App version not found");
                setAppVersion(0);
            }
            
            try {
                String appFile = context.getPackageManager().getApplicationInfo(context.getPackageName(), 0).sourceDir;
                long insdate = new File(appFile).lastModified();
                Date installDate = new Date(insdate);
                SimpleDateFormat sdfDate = new SimpleDateFormat(MATConstants.DATE_FORMAT, Locale.US);
                sdfDate.setTimeZone(TimeZone.getTimeZone("UTC"));
                setInstallDate(sdfDate.format(installDate));
            } catch (Exception e) {
                setInstallDate("0");
            }
            
            // execute Runnable on UI thread to set user agent
            Handler handler = new Handler(Looper.getMainLooper());
            handler.post(new GetUserAgent(context));
            
            // Show annoying alert about debug mode if enabled
            if (debugMode) {
                try {
                    AlertDialog.Builder builder = new AlertDialog.Builder(context);
                    builder.setTitle("Debug Mode Enabled");
                    builder.setMessage("MAT SDK debug mode is enabled - please disable before app submission.");
                    builder.show();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
            
            // Set screen density
            float density = context.getResources().getDisplayMetrics().density;
            setScreenDensity(Float.toString(density));
            
            // Set screen layout size
            WindowManager wm = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
            int width = wm.getDefaultDisplay().getWidth();
            int height = wm.getDefaultDisplay().getHeight();
            setScreenSize(Integer.toString(width) + "x" + Integer.toString(height));
            
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
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
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        
        ContentValues values = new ContentValues();
        values.put(MATProvider.PUBLISHER_PACKAGE_NAME, getPackageName());
        values.put(MATProvider.TRACKING_ID, trackingId);
        
        Uri CONTENT_URI = Uri.parse("content://" + targetPackageName + "/referrer_apps");
        context.getContentResolver().insert(CONTENT_URI, values);
        
        // If doRedirect is true, take user to the url returned by the server
        if (doRedirect) {
            try {
                Intent i = new Intent(Intent.ACTION_VIEW, Uri.parse(redirectUrl));
                i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(i);
            } catch (Exception e) {
            }
        }
        
        return redirectUrl;
    }

    /**
     * trackInstall with default context.
     * @return 1 on success, 2 on already installed state, 3 on update, and -1 on failure
     */
    public int trackInstall() {
        return trackInstall(context);
    }

    /**
     * Main tracking Install function, this function only needs to be successfully called one time on application install.
     * @param context the application context
     * @return 1 on success, 2 on already installed state, 3 on update, and -1 on failure
     */
    public synchronized int trackInstall(Context context) {
        SharedPreferences.Editor editor;
        SP = context.getSharedPreferences(MATConstants.PREFS_INSTALL, 0);
        install = SP.getString("install", "");
        if (!install.equals("")) { // has it been tracked before?
            SP = context.getSharedPreferences(MATConstants.PREFS_VERSION, 0);
            String savedVersion = SP.getString("version", "");
            if (savedVersion.length() != 0 && Integer.parseInt(savedVersion) != getAppVersion()) { // If have been tracked before, check if is an update
                if (debugMode) Log.d(MATConstants.TAG, "App version has changed since last trackInstall, sending update to server");
                track("update", null, 0, null);
                editor = SP.edit();
                editor.putString("version", Integer.toString(getAppVersion()));
                editor.commit();
                return 3;
            }
            if (debugMode) Log.d(MATConstants.TAG, "Install has been tracked before");
            return 2;
        } else {
            // mark app as tracked so that postback url won't be called again
            SP = context.getSharedPreferences(MATConstants.PREFS_INSTALL, 0);
            editor = SP.edit();
            editor.putString("install", "installed");
            editor.commit();
            SP = context.getSharedPreferences(MATConstants.PREFS_VERSION, 0);
            editor = SP.edit();
            editor.putString("version", Integer.toString(getAppVersion()));
            editor.commit();
        }
        return track("install", null, 0, null);
    }

    /**
     * Tracking update function, this function can be called to send an update event.
     * @return 1 on success and -1 on failure.
     */
    public int trackUpdate() {
        SharedPreferences.Editor editor;
        SP = context.getSharedPreferences(MATConstants.PREFS_INSTALL, 0);
        install = SP.getString("install", "");
        if (!install.equals("")) { // has it been tracked before?
            SP = context.getSharedPreferences(MATConstants.PREFS_VERSION, 0);
            String savedVersion = SP.getString("version", "");
            if (savedVersion.length() != 0 && Integer.parseInt(savedVersion) != getAppVersion()) { // If have been tracked before, check if is an update
                if (debugMode) Log.d(MATConstants.TAG, "App version has changed since last trackInstall, sending update to server");
                track("update", null, 0, null);
                editor = SP.edit();
                editor.putString("version", Integer.toString(getAppVersion()));
                editor.commit();
                return 3;
            }
            if (debugMode) Log.d(MATConstants.TAG, "Update has been tracked before");
            return 2;
        } else {
            // mark app as tracked so that postback url won't be called again
            SP = context.getSharedPreferences(MATConstants.PREFS_INSTALL, 0);
            editor = SP.edit();
            editor.putString("install", "installed");
            editor.commit();
            SP = context.getSharedPreferences(MATConstants.PREFS_VERSION, 0);
            editor = SP.edit();
            editor.putString("version", Integer.toString(getAppVersion()));
            editor.commit();
            this.install = "installed";
        }
        return track("update", null, 0, null);
    }

    /**
     * Method for applications to track purchase events with a special purchase status parameter.
     * @param event event name or event ID in MAT system
     * @param purchaseStatus the status of the purchase: 0 for success, 1 for fail, 2 for refund
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @return 1 on success and -1 on failure
     */
    public int trackPurchase(String event, int purchaseStatus, double revenue, String currency) {
        setPurchaseStatus(purchaseStatus);
        return track(event, null, revenue, currency);
    }

    /**
     * Method for applications to track events using a new action event with event id.
     * @param event event name or event ID in MAT system
     * @return 1 on success and -1 on failure.
     */
    public int trackAction(String event) {
        return track(event, null, 0, null);
    }

    /**
     * Method for applications to track events using a new action event with event id, map (event item).
     * @param event event name or event ID in MAT system
     * @param map HashMap of an event item to convert to json to post to server.
     * @return 1 on success and -1 on failure.
     */
    public int trackAction(String event, HashMap<String, String> map) {
        // Create a JSONObject using the given HashMap
        JSONObject jsonObject = new JSONObject(map);
        JSONArray jsonArray = new JSONArray();
        jsonArray.put(jsonObject);
        return track(event, jsonArray.toString(), 0, null);
    }

    /**
     * Method for applications to track events using a new action event with event id, list of event items.
     * @param event event name or event ID in MAT system
     * @param list List of event items to convert to json to post to server.
     * @return 1 on success and -1 on failure.
     */
    public int trackAction(String event, List<HashMap<String, String>> list) {
        // Create a JSONArray using the given List of Maps
        JSONArray jsonArray = new JSONArray();
        for (int i = 0; i < list.size(); i++) {
            JSONObject jsonObject = new JSONObject((HashMap<String, String>) list.get(i));
            jsonArray.put(jsonObject);
        }
        return track(event, jsonArray.toString(), 0, null);
    }

    /**
     * Method for applications to track events using a new action event with event id, revenue.
     * @param event event name or event ID in MAT system
     * @param revenue revenue amount tied to the action
     * @return 1 on success and -1 on failure.
     */
    public int trackAction(String event, double revenue) {
        return track(event, null, revenue, null);
    }

    /**
     * Method for applications to track events using a new action event with event id, revenue and currency.
     * @param event event name or event ID in MAT system
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @return 1 on success and -1 on failure.
     */
    public int trackAction(String event, double revenue, String currency) {
        return track(event, null, revenue, currency);
    }

    /**
     * Method calls a new action event based on class member settings.
     * @param event event name or event ID in MAT system
     * @param json JSON data to post to the server
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @return 1 on success, 2 if already installed and -1 on failure.
     */
    private synchronized int track(String event, String json, double revenue, String currency) {
        if (!initialized) return -1;
        
        if (isOnline() && getQueueSize() > 0) {
            dumpQueue();
        }
        
        // Clear the parameters from parameter table that should be reset between events
        paramTable.remove("android_purchase_status");
        paramTable.remove("ar");
        paramTable.remove("ei");
        paramTable.remove("en");
        paramTable.remove("event_referrer");
        
        setAction("conversion"); // Default to conversion
        if (containsChar(event)) { // check if eventid contains a character
            if (event.equals("open")) setAction("open");
            else if (event.equals("close")) setAction("close");
            else if (event.equals("install")) setAction("install");
            else if (event.equals("update")) setAction("update");
            else setEventName(event);
        } else {
            setEventId(event);
        }
        
        String link = null;
        try {
            link = buildLink();
        } catch (Exception e) {
            e.printStackTrace();
            return -1;
        }
        
        String action = getAction();
        if (isOnline()) {
            try {
                pool.schedule(new GetLink(link, json, action, revenue, currency, true), MATConstants.DELAY, TimeUnit.MILLISECONDS);
            } catch (Exception e) {
                e.printStackTrace();
            }
        } else {
            if (!action.equals("open")) {
                addEventToQueue(link, json, action, revenue, currency, true);
                if (debugMode) Log.d(MATConstants.TAG, "Not online: track will be queued");
            }
        }
        return 1;
    }
    
    /**
     * Builds a new link string based on class member values.
     * @return encrypted URL string based on class settings.
     */
    private String buildLink() {
        String encryption = "https://";
        if (!httpsEncryption) {
            encryption = "http://";
        }
        StringBuilder link = new StringBuilder(encryption).append(getAdvertiserId()).append(".");
        if (debugMode) {
            link.append(MATConstants.MAT_DOMAIN_DEBUG);
        } else {
            link.append(MATConstants.MAT_DOMAIN);
        }
        link.append("/serve?s=android&ver=").append(MATConstants.SDK_VERSION).append("&pn=").append(getPackageName());
        for (String key: paramTable.keySet()) {
            // Append fields from paramTable that don't need to be encrypted
            if (!encryptList.contains(key)) {
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
        
        // Append app-to-app tracking id if exists
        try {
            Uri allTitles = Uri.parse("content://" + getPackageName() + "/referrer_apps");
            Cursor c = context.getContentResolver().query(allTitles, null, null, null, "publisher_package_name desc");
            // Append tracking ID from content provider if exists
            if (c != null && c.moveToFirst()) {
                String trackingId = c.getString(c.getColumnIndex(MATProvider.TRACKING_ID));
                // UTF-8 encode the tracking ID
                try {
                    trackingId = URLEncoder.encode(trackingId, "UTF-8");
                } catch (Exception e) {
                }
                
                // Add to paramTable for data encrypting
                paramTable.put("ti", trackingId);
                c.close();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return link.toString();
    }
    
    /**
     * Builds encrypted data in conversion link based on class member values.
     * @param origLink the base URL to append data to
     * @param action the event action (install/update/open/conversion)
     * @return encrypted URL string based on class settings.
     */
    private String buildData(String origLink, String action, double revenue, String currency) {
        StringBuilder link = new StringBuilder(origLink);
        
        setRevenue(revenue);
        if (currency != null) {
            setCurrencyCode(currency);
        }
        
        // update referrer value if INSTALL_REFERRER intent wasn't received during initialization
        if (getReferrer() != null && getReferrer().length() == 0) {
            SP = context.getSharedPreferences(MATConstants.PREFS_REFERRER, 0);
            try {
                String referrer = SP.getString("referrer", "");
                if (referrer.length() != 0) {
                    setReferrer(referrer);
                }
            } catch (ClassCastException e) {
                e.printStackTrace();
            }
        }
        
        // For opens and events, try to add install_log_id
        if (action.equals("open") || action.equals("conversion")) {
            // If log id not set, wait a few seconds in case install/update was just sent
            if (getInstallLogId().length() == 0 && getUpdateLogId().length() == 0) {
                try {
                    Thread.sleep(MATConstants.DELAY);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
            // Append install log id for opens and events if we have it stored
            if (getInstallLogId().length() > 0) {
                link.append("&install_log_id=" + getInstallLogId());
            } else if (getUpdateLogId().length() > 0) {
                link.append("&update_log_id=" + getUpdateLogId());
            } else {
                // Call GetLog endpoint
                if (isTodayLatestDate(MATConstants.PREFS_LAST_LOG_ID, MATConstants.PREFS_LAST_LOG_ID_KEY)) {
                    // Build the url to request the log id
                    StringBuilder logIdUrl = new StringBuilder("http://").append(MATConstants.MAT_DOMAIN).append("/v1/Integrations/Sdk/GetLog?sdk=android&package_name=").append(getPackageName()).append("&advertiser_id=").append(getAdvertiserId()).append("&keys[mac_address]=").append(getMacAddress()).append("&keys[device_id]=").append(getDeviceId());
                    // Add encrypted package name as data
                    StringBuilder encryptedPackageName = new StringBuilder("package_name=").append(getPackageName());
                    try {
                        encryptedPackageName = new StringBuilder(URLEnc.bytesToHex(URLEnc.encrypt(encryptedPackageName.toString())));
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    logIdUrl.append("&data=").append(encryptedPackageName.toString());
                    
                    String logId = "";
                    String type = "";
                    JSONObject response = urlRequester.requestUrl(logIdUrl.toString(), null);
                    if (response != null) {
                        try {
                            JSONObject data = response.getJSONObject("data");
                            logId = data.getString("log_id");
                            type = data.getString("type");
                        } catch (Exception e) {
                            e.printStackTrace();
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
        
        try {
            String facebookCookie = getAttributionId(context.getContentResolver());
            if (facebookCookie != null) {
                link.append("&fb_cookie_id=").append(facebookCookie);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        
        // Check if there is a Facebook re-engagement intent saved in SharedPreferences
        SP = context.getSharedPreferences(MATConstants.PREFS_FACEBOOK_INTENT, 0);
        String intent = SP.getString("action", "");
        if (intent.length() != 0) {
            try {
                intent = URLEncoder.encode(intent, "UTF-8");
            } catch (UnsupportedEncodingException e) {
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
        for (String encrypt: encryptList) {
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
            data = new StringBuilder(this.URLEnc.bytesToHex(this.URLEnc.encrypt(data.toString())));
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
        
        SP = context.getSharedPreferences(prefsName, 0);
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
        private Context context;
        
        public GetUserAgent(Context context) {
            this.context = context;
        }
        
        public void run() {
            try {
                // Create WebView to set user agent, then destroy WebView
                WebView webview = new WebView(this.context);
                webview.setVisibility(View.GONE);
                WebSettings settings = webview.getSettings();
                settings.setCacheMode(WebSettings.LOAD_NO_CACHE);
                settings.setSavePassword(false);
                setUserAgent(webview.getSettings().getUserAgentString());
                webview.destroy();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
    
    /**
     * Runnable for making a single http request.
     */
    private class GetLink implements Runnable {
        private String link = null;
        private String json = null;
        private String action = null;
        private double revenue = 0;
        private String currency = null;
        private boolean shouldBuildData = false;
        
        /**
         * Instantiates a new GetLink Runnable.
         * @param link url to request
         * @param json json data to post
         * @param action the event action
         * @param revenue the revenue amount
         * @param currency the currency code
         * @param shouldBuildData whether link needs encrypted data appended
         */
        public GetLink(String link, String json, String action, double revenue, String currency, boolean shouldBuildData) {
            this.link = link;
            this.json = json;
            this.action = action;
            this.revenue = revenue;
            this.currency = currency;
            this.shouldBuildData = shouldBuildData;
        }
        
        public void run() {
            if (shouldBuildData) {
                try {
                    link = buildData(link, action, revenue, currency);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
            
            // If action is open, check whether we have done an open in the past 24h
            // If true, don't send open
            if (action.equals("open")) {
                if (!isTodayLatestDate(MATConstants.PREFS_LAST_OPEN, MATConstants.PREFS_LAST_OPEN_KEY)) {
                    if (debugMode) Log.d(MATConstants.TAG, "SDK has already sent an open today, not sending request");
                    return;
                }
            }
            
            Log.d(MATConstants.TAG, "Sending " + action + " event to server...");
            
            try {
                JSONObject response = urlRequester.requestUrl(link, json);
                if (response == null) {
                    addEventToQueue(link, json, action, revenue, currency, false);
                    if (debugMode) Log.d(MATConstants.TAG, "Request failed: track will be queued");
                    return;
                }
                
                // Signal didSucceedWithData event to interface
                if (matResponse != null) {
                    matResponse.didSucceedWithData(response);
                }
                
                // Set log ID from install/update response
                if (action.equals("install")) {
                    setInstallLogId(response.getString("log_id"));
                } else if (action.equals("update")) {
                    setUpdateLogId(response.getString("log_id"));
                }
                
                if (debugMode) {
                    Log.d(MATConstants.TAG, "Server response: " + response.toString());
                    if (response.length() > 0) {
                        String success = response.getJSONObject("log_action").getJSONObject("conversion").getString("status");
                        if (success.equals("rejected")) {
                            String statusCode = response.getJSONObject("log_action").getJSONObject("conversion").getString("status_code");
                            Log.d(MATConstants.TAG, "Event was rejected by server: status code " + statusCode);
                        } else {
                            Log.d(MATConstants.TAG, "Event was accepted by server");
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }
    
    /******************
     * Public Setters *
     ******************/
    public String getAdvertiserId() {
        return paramTable.get("adv");
    }

    public void setAdvertiserId(String advertiser_id) {
        putInParamTable("adv", advertiser_id);
    }

    public String getCurrencyCode() {
        return paramTable.get("c");
    }

    public void setCurrencyCode(String currency_code) {
        putInParamTable("c", currency_code);
    }

    public String getEventId() {
        return paramTable.get("ei");
    }

    public void setEventId(String event_id) {
        putInParamTable("ei", event_id);
    }

    public String getEventName() {
        return paramTable.get("en");
    }

    public void setEventName(String event_name) {
        putInParamTable("en", event_name);
    }

    public String getEventReferrer() {
        return paramTable.get("event_referrer");
    }
    
    public void setEventReferrer(String referrerPackage) {
        putInParamTable("event_referrer", referrerPackage);
    }

    /**
     * Gets the key used for encrypting the event urls.
     * @return key
     */
    public final String getKey() {
        return this.key;
    }

    /**
     * Sets the key used for encrypting the event urls, key length needs to be either 128, 192, or 256 bits.
     * @param key the new key
     */
    public void setKey(String key) {
        this.key = key;
        URLEnc = new Encryption(key, MobileAppTracker.IV);
    }

    public void setMATResponse(MATResponse response) {
        matResponse = response;
    }

    public String getOsId() {
        return paramTable.get("oi");
    }

    public void setOsId(String os_id) {
        putInParamTable("oi", os_id);
    }

    public String getPackageName() {
        return paramTable.get("pn");
    }

    public void setPackageName(String package_name) {
        putInParamTable("pn", package_name);
    }

    public String getReferrer() {
        return paramTable.get("ir");
    }

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

    public String getRevenue() {
        return paramTable.get("r");
    }

    public void setRevenue(double revenue) {
        putInParamTable("r", Double.toString(revenue));
    }

    public String getSiteId() {
        return paramTable.get("si");
    }

    public void setSiteId(String site_id) {
        putInParamTable("si", site_id);
    }

    public String getTRUSTeId() {
        return paramTable.get("tpid");
    }

    public void setTRUSTeId(String tpid) {
        putInParamTable("tpid", tpid);
    }

    /**
     * Gets the custom user ID.
     * @return the user id
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
    
    public String getAction() {
        return paramTable.get("ac");
    }

    private void setAction(String action) {
        putInParamTable("ac", action);
    }

    public String getAndroidId() {
        return paramTable.get("ad");
    }

    private void setAndroidId(String android_id) {
        putInParamTable("ad", android_id);
    }

    public String getAppName() {
        return paramTable.get("an");
    }

    private void setAppName(String app_name) {
        putInParamTable("an", app_name);
    }

    public int getAppVersion() {
        if (paramTable.get("av") == null) {
            return 0;
        }
        return Integer.parseInt(paramTable.get("av"));
    }

    private void setAppVersion(int app_version) {
        putInParamTable("av", Integer.toString(app_version));
    }

    public String getCarrier() {
        return paramTable.get("dc");
    }

    private void setCarrier(String carrier) {
        putInParamTable("dc", carrier);
    }

    /**
     * Gets the connection type (mobile or WIFI);.
     * @return connection type
     */
    public String getConnectionType() {
        return paramTable.get("connection_type");
    }

    private void setConnectionType(String connection_type) {
        putInParamTable("connection_type", connection_type);
    }

    public String getCountryCode() {
        return paramTable.get("cc");
    }

    private void setCountryCode(String country_code) {
        putInParamTable("cc", country_code);
    }

    public String getDeviceBrand() {
        return paramTable.get("db");
    }

    private void setDeviceBrand(String device_brand) {
        putInParamTable("db", device_brand);
    }

    public String getDeviceId() {
        return paramTable.get("d");
    }

    private void setDeviceId(String device_id) {
        putInParamTable("d", device_id);
    }

    public String getDeviceModel() {
        return paramTable.get("dm");
    }

    private void setDeviceModel(String device_model) {
        putInParamTable("dm", device_model);
    }

    public String getInstallDate() {
        return paramTable.get("id");
    }

    private void setInstallDate(String install_date) {
        putInParamTable("id", install_date);
    }

    public String getLanguage() {
        return paramTable.get("l");
    }

    private void setLanguage(String language) {
        putInParamTable("l", language);
    }

    // Sets last date in given SharedPreferences file and key to given date
    private void setLastDate(SimpleDateFormat sdf, Calendar date, String prefsName, String key) {
        String dateStr = sdf.format(date.getTime());
        SP = context.getSharedPreferences(prefsName, 0);
        SharedPreferences.Editor editor = SP.edit();
        editor.putString(key, dateStr);
        editor.commit();
    }

    public String getInstallLogId() {
        // Get log id from SharedPreferences
        SP = context.getSharedPreferences(MATConstants.PREFS_LOG_ID_INSTALL, 0);
        return SP.getString("logId", "");
    }

    private void setInstallLogId(String logId) {
        // Store log id from install in SharedPreferences
        SP = context.getSharedPreferences(MATConstants.PREFS_LOG_ID_INSTALL, 0);
        SharedPreferences.Editor editor = SP.edit();
        editor.putString(MATConstants.PREFS_LOG_ID_KEY, logId);
        editor.commit();
    }

    public String getMacAddress() {
        return paramTable.get("ma");
    }

    private void setMacAddress(String mac_address) {
        putInParamTable("ma", mac_address);
    }

    public String getMatId() {
        return paramTable.get("mi");
    }

    private void setMatId(String mat_id) {
        putInParamTable("mi", mat_id);
    }

    /**
     * Gets the mobile country code.
     * @return the mcc
     */
    public String getMCC() {
        return paramTable.get("mobile_country_code");
    }

    private void setMCC(String mcc) {
        putInParamTable("mobile_country_code", mcc);
    }

    /**
     * Gets the mobile network code.
     * @return the mobile network code
     */
    public String getMNC() {
        return paramTable.get("mobile_network_code");
    }

    private void setMNC(String mnc) {
        putInParamTable("mobile_network_code", mnc);
    }

    public String getOsVersion() {
        return paramTable.get("ov");
    }

    private void setOsVersion(String os_version) {
        putInParamTable("ov", os_version);
    }

    private void setPurchaseStatus(int purchaseStatus) {
        putInParamTable("android_purchase_status", Integer.toString(purchaseStatus));
    }

    public String getScreenDensity() {
        return paramTable.get("screen_density");
    }

    private void setScreenDensity(String density) {
        putInParamTable("screen_density", density);
    }

    public String getScreenSize() {
        return paramTable.get("screen_layout_size");
    }

    private void setScreenSize(String screensize) {
        putInParamTable("screen_layout_size", screensize);
    }

    public String getUpdateLogId() {
        // Get log id from SharedPreferences
        SP = context.getSharedPreferences(MATConstants.PREFS_LOG_ID_UPDATE, 0);
        return SP.getString("logId", "");
    }

    private void setUpdateLogId(String logId) {
        // Store log id from install in SharedPreferences
        SP = context.getSharedPreferences(MATConstants.PREFS_LOG_ID_UPDATE, 0);
        SharedPreferences.Editor editor = SP.edit();
        editor.putString(MATConstants.PREFS_LOG_ID_KEY, logId);
        editor.commit();
    }

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
        if (value != null) {
            try {
                value = URLEncoder.encode(value, "UTF-8");
                paramTable.put(key, value);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
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
     * Sets whether to use https encryption.
     * @param use_https whether to use https or not
     */
    public void setHttpsEncryption(boolean use_https) {
        httpsEncryption = use_https;
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
     * Returns the Android device ID.
     * @param context the application context
     * @return Android device ID
     */
    private String getDeviceId(Context context) {
        return ((TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE)).getDeviceId();
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