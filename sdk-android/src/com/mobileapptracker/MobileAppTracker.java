package com.mobileapptracker;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TimeZone;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.conn.ClientConnectionManager;
import org.apache.http.conn.scheme.PlainSocketFactory;
import org.apache.http.conn.scheme.Scheme;
import org.apache.http.conn.scheme.SchemeRegistry;
import org.apache.http.conn.ssl.SSLSocketFactory;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.impl.conn.tsccm.ThreadSafeClientConnManager;
import org.apache.http.params.BasicHttpParams;
import org.apache.http.params.HttpConnectionParams;
import org.apache.http.params.HttpParams;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

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
    private static boolean DEBUG = false;

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
    // Thread pool for running the getLink Runnables
    private ScheduledExecutorService pool;
    // Singleton http client for firing requests
    private HttpClient client;
    // The fields to encrypt in http request
    private List<String> encryptList;
    // Binary semaphore for controlling adding to queue/dumping queue
    private Semaphore queueAvailable;
    // SharedPreferences for storing events that were not fired
    private SharedPreferences EventQueue;
    private SharedPreferences SP;

    /**
     * Instantiates a new MobileAppTracker.
     *
     * @param context the application context
     * @param collectDeviceId whether to collect device id
     * @param collectMacAddress whether to collect MAC address
     */
    public MobileAppTracker(Context context, String advertiserId, String key, boolean collectDeviceId, boolean collectMacAddress) {
        if (constructed) return;
        constructed = true;
        this.context = context;
        pool = Executors.newSingleThreadScheduledExecutor();
        queueAvailable = new Semaphore(1, true);

        // Set up HttpClient
        SchemeRegistry registry = new SchemeRegistry();
        registry.register(new Scheme("http", PlainSocketFactory.getSocketFactory(), 80));
        registry.register(new Scheme("https", SSLSocketFactory.getSocketFactory(), 443));
        HttpParams params = new BasicHttpParams();
        HttpConnectionParams.setSocketBufferSize(params, 8192);
        HttpConnectionParams.setConnectionTimeout(params, MATConstants.TIMEOUT);
        HttpConnectionParams.setSoTimeout(params, MATConstants.TIMEOUT);

        ClientConnectionManager connManager = new ThreadSafeClientConnManager(params, registry);
        client = new DefaultHttpClient(connManager, params);

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
                                    "connection_type",
                                    "mobile_country_code",
                                    "mobile_network_code",
                                    "screen_density",
                                    "screen_layout_size",
                                    "ti",
                                    "android_purchase_status");

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
                ConnectivityManager connectivityManager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
                if (connectivityManager.getActiveNetworkInfo() != null && getQueueSize() > 0) {
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
     * @param advertiserId the advertiser ID in MAT
     * @param key the advertiser key
     */
    public MobileAppTracker(Context context, String advertiserId, String key) {
        this(context, advertiserId, key, true, true);
    }

    /**
     * Saves an event to the queue, used if there is no Internet connection.
     * @param event URL of the event postback
     * @param json (Optional) JSON information to post to server
     */
    private void addEventToQueue(String event, String json) {
        // Acquire semaphore before modifying queue
        try {
            queueAvailable.acquire();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
        // JSON-serialize the link and json to store in Shared Preferences as a string
        JSONObject jsonEvent = new JSONObject();
        try {
            jsonEvent.put("link", event);
            if (json != null) {
                jsonEvent.put("json", json);
            }
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

        // Iterate through events and do postbacks for each, using getLink
        for (; x <= size; x++) {
            String key = Integer.valueOf(x).toString();
            String eventJson = EventQueue.getString(key, null);

            if (eventJson != null) {
                String link = null;
                String json = null;
                try {
                    // De-serialize the stored string from the queue to get URL and json values
                    JSONObject event = new JSONObject(eventJson);
                    link = (String) event.get("link");
                    if (event.has("json")) {
                        json = (String) event.get("json");
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }

                if (link != null) {
                    try {
                        setQueueSize(getQueueSize() - 1);
                        SharedPreferences.Editor editor = EventQueue.edit();
                        editor.remove(key);
                        editor.commit();
                        pool.execute(new getLink(link, json));
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
                setAppVersion(context.getPackageManager().getPackageInfo(this.context.getPackageName(), 0).versionCode);
            } catch (Exception e) {
                Log.d(MATConstants.TAG, "App version not found");
                setAppVersion(0);
            }

            try {
                String appFile = context.getPackageManager().getApplicationInfo(this.context.getPackageName(), 0).sourceDir;
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
            handler.post(new getUserAgent(context));

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

        StringBuilder url = new StringBuilder("http://engine.mobileapptracking.com/serve?action=click&sdk=android");
        url.append("&publisher_advertiser_id=").append(publisherAdvertiserId);
        url.append("&package_name=").append(targetPackageName);
        if (publisherId != null) {
            url.append("&publisher_id=").append(publisherId);
        }
        if (campaignId != null) {
            url.append("&campaign_id=").append(campaignId);
        }
        url.append("&response_format=json");

        HttpGet request = new HttpGet(url.toString());
        try {
            HttpResponse response = client.execute(request);
            BufferedReader reader = new BufferedReader(new InputStreamReader(response.getEntity().getContent(), "UTF-8"), 8192);
            String json = reader.readLine();
            JSONObject jsonObject = new JSONObject(json);
            trackingId = jsonObject.getString("tracking_id");
            redirectUrl = jsonObject.getString("url");
        } catch (Exception e) {
            e.printStackTrace();
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
                if (DEBUG) Log.d(MATConstants.TAG, "App version has changed since last trackInstall, sending update to server");
                track("update", null, 0, null);
                editor = SP.edit();
                editor.putString("version", Integer.toString(getAppVersion()));
                editor.commit();
                return 3;
            }
            if (DEBUG) Log.d(MATConstants.TAG, "Install has been tracked before");
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

        return track("install", null, 0, null);
    }

    /**
     * Tracking update function, this function can be called to send an update event.
     * @return 1 on success and -1 on failure.
     */
    public int trackUpdate() {
        // mark app as tracked so that install postback url won't be called again
        SharedPreferences.Editor editor;
        SP = context.getSharedPreferences(MATConstants.PREFS_INSTALL, 0);
        editor = SP.edit();
        editor.putString("install", "installed");
        editor.commit();
        SP = context.getSharedPreferences(MATConstants.PREFS_VERSION, 0);
        editor = SP.edit();
        editor.putString("version", Integer.toString(getAppVersion()));
        editor.commit();
        return track("update", null, 0, null);
    }

    public int trackPurchase(String event, int purchaseStatus, double revenue, String currency) {
        setPurchaseStatus(purchaseStatus);
        return track(event, null, revenue, currency);
    }

    /**
     * Method for applications to track events using a new action event with event id.
     * @param eventid event id
     * @return 1 on success and -1 on failure.
     */
    public int trackAction(String eventid) {
        return track(eventid, null, 0, null);
    }

    /**
     * Method for applications to track events using a new action event with event id, map (event item).
     * @param eventid event id
     * @param map Map of an event item to convert to json to post to server.
     * @return 1 on success and -1 on failure.
     */
    public int trackAction(String eventid, @SuppressWarnings("rawtypes") Map map) {
        // Create a JSONObject using the given Map
        JSONObject jsonObject = new JSONObject(map);
        JSONArray jsonArray = new JSONArray();
        jsonArray.put(jsonObject);
        return track(eventid, jsonArray.toString(), 0, null);
    }

    /**
     * Method for applications to track events using a new action event with event id, list of event items.
     * @param eventid event id
     * @param list List of event items to convert to json to post to server.
     * @return 1 on success and -1 on failure.
     */
    public int trackAction(String eventid, @SuppressWarnings("rawtypes") List list) {
        // Create a JSONArray using the given List of Maps
        JSONArray jsonArray = new JSONArray();
        for (int i = 0; i < list.size(); i++) {
            @SuppressWarnings("rawtypes")
            JSONObject jsonObject = new JSONObject((Map) list.get(i));
            jsonArray.put(jsonObject);
        }
        return track(eventid, jsonArray.toString(), 0, null);
    }

    /**
     * Method for applications to track events using a new action event with event id, revenue.
     * @param eventid event id
     * @param revenue revenue amount tied to the action
     * @return 1 on success and -1 on failure.
     */
    public int trackAction(String eventid, double revenue) {
        return track(eventid, null, revenue, null);
    }

    /**
     * Method for applications to track events using a new action event with event id, revenue and currency.
     * @param eventid event id
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @return 1 on success and -1 on failure.
     */
    public int trackAction(String eventid, double revenue, String currency) {
        return track(eventid, null, revenue, currency);
    }

    /**
     * Method calls a new action event based on class member settings.
     * @param eventid event id
     * @param json JSON data to post to the server
     * @param revenue revenue amount tied to the action
     * @param currency currency code for the revenue amount
     * @return 1 on success, 2 if already installed and -1 on failure.
     */
    private synchronized int track(String eventid, String json, double revenue, String currency) {
        if (!initialized) return -1;

        paramTable.remove("ei");
        paramTable.remove("en"); // clear eventcache

        setAction("conversion"); // Default to conversion
        if (containsChar(eventid)) { // check if eventid contains a character
            if (eventid.equals("open")) setAction("open");
            else if (eventid.equals("close")) setAction("close");
            else if (eventid.equals("install")) setAction("install");
            else if (eventid.equals("update")) setAction("update");
            else setEventName(eventid);
        } else {
            setEventId(eventid);
        }

        setRevenue(revenue);
        if (currency != null) {
            setCurrencyCode(currency);
        }

        String link = null;
        try {
            link = buildLink();
        } catch (Exception e) {
            e.printStackTrace();
        }

        if (isOnline()) {
            try {
                pool.schedule(new getLink(link, json), MATConstants.DELAY, TimeUnit.MILLISECONDS);
            } catch (Exception e) {
                e.printStackTrace();
            }
        } else {
            addEventToQueue(link, json);
            if (DEBUG) Log.d(MATConstants.TAG, "Not online: track will be queued");
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
        StringBuilder link = new StringBuilder(encryption);
        link.append(getAdvertiserId()).append(".engine.mobileapptracking.com/serve?s=android&ver=").append(MATConstants.SDK_VERSION).append("&pn=").append(getPackageName());
        for (String key: paramTable.keySet()) {
            // Append fields from paramTable that don't need to be encrypted
            if (!encryptList.contains(key)) {
                link.append("&").append(key).append("=").append(paramTable.get(key));
            }
        }

        // If logging on, use debug mode
        if (DEBUG) {
            link.append("&debug=1&skip_dup=1");
        }

        try {
            // Append app referrer fields from content provider if exists
            Uri allTitles = Uri.parse("content://" + getPackageName() + "/referrer_apps");
            Cursor c = context.getContentResolver().query(allTitles, null, null, null, "publisher_package_name desc");
            if (c != null && c.moveToFirst()) {
                String trackingId = c.getString(c.getColumnIndex(MATProvider.TRACKING_ID));
                // UTF-8 encode the tracking ID
                try {
                    trackingId = URLEncoder.encode(trackingId, "UTF-8");
                } catch (Exception e) {
                }

                // Add to paramTable for data encrypting
                paramTable.put("tracking_id", trackingId);
            }
            c.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        return link.toString();
    }

    /**
     * Builds encrypted data in conversion link based on class member values.
     * @param origLink the base URL to append data to
     * @return encrypted URL string based on class settings.
     */
    private String buildData(String origLink) {
        StringBuilder link = new StringBuilder(origLink);

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

        SimpleDateFormat sdfDate = new SimpleDateFormat(MATConstants.DATE_FORMAT, Locale.US);
        Date now = new Date();
        String currentTime = sdfDate.format(now);
        try {
            currentTime = URLEncoder.encode(currentTime, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            if (DEBUG) Log.d(MATConstants.TAG, "convert system date failed");
        }

        // Construct the data string from field names in encryptList and encrypt it
        StringBuilder data = new StringBuilder();
        for (String encrypt: encryptList) {
            if (paramTable.get(encrypt) != null) {
                data.append("&").append(encrypt).append("=").append(paramTable.get(encrypt));
            }
        }
        data.append("&sd=").append(currentTime);

        try {
            if (getAttributionId(context.getContentResolver()) != null) {
                link.append("&fb_cookie_id=").append(getAttributionId(context.getContentResolver()));
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

        try {
            data = new StringBuilder(this.URLEnc.bytesToHex(this.URLEnc.encrypt(data.toString())));
        } catch (Exception e) {
            e.printStackTrace();
        }

        link.append("&da=").append(data.toString());
        return link.toString();
    }

    /**
     *  Runnable for creating a WebView and getting the device user agent
     */
    public class getUserAgent implements Runnable {
        private Context context;

        public getUserAgent(Context context) {
            this.context = context;
        }

        public void run() {
            try {
                // Create WebView to set user agent, then destroy WebView
                WebView webview = new WebView(this.context);
                webview.setVisibility(View.GONE);
                WebSettings settings = webview.getSettings();
                settings.setAppCacheEnabled(false);
                settings.setCacheMode(WebSettings.LOAD_NO_CACHE);
                settings.setJavaScriptEnabled(false);
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
    public class getLink implements Runnable {
        private String link = null;
        private String json = null;
        public int status = -2;

        /**
         * Instantiates a new getLink Runnable.
         * @param link url to request
         * @param json json data to post
         */
        public getLink(String link, String json) {
            this.link = link;
            this.json = json;
        }

        /* (non-Javadoc)
         * @see java.lang.Runnable#run()
         */
        public void run() {
            if (DEBUG) Log.d(MATConstants.TAG, "Sending event to server...");

            try {
                link = buildData(link);
            } catch (Exception e) {
                e.printStackTrace();
            }

            try {
                // If json data passed, do a post to server with the json. Else do regular get call.
                HttpResponse response;
                if (json == null) {
                    HttpGet request = new HttpGet(link);
                    response = client.execute(request);
                } else {
                    JSONObject data = new JSONObject();
                    JSONArray value = new JSONArray(json);
                    data.put("data", value);

                    StringEntity se = new StringEntity(data.toString());
                    se.setContentType("application/json");
                    HttpPost request = new HttpPost(link);
                    request.setEntity(se);
                    response = client.execute(request);
                }
                // Response
                status =  response.getStatusLine().getStatusCode();
                if (status == HttpStatus.SC_OK) {
                    if (DEBUG) Log.d(MATConstants.TAG, "Event was sent");
                } else {
                    addEventToQueue(link, json);
                    if (DEBUG) Log.d(MATConstants.TAG, "Event failed with status " + status);
                    return;
                }

                // Read HTTPResponse content
                BufferedReader reader = new BufferedReader(new InputStreamReader(response.getEntity().getContent(), "UTF-8"), 8192);
                String success = reader.readLine();
                reader.close();

                // Check whether install event was logged by checking status value
                if (success != null) {
                    if (DEBUG) Log.d(MATConstants.TAG, "Server response: " + success);
                    success = success.split("\\s*\\\"status\\\"\\s*\\:\\s*")[1];
                    if (success.startsWith("\"rejected\"")) {
                        success = success.split("\\s*\\\"status_code\\\"\\:\\s*")[1];
                        String statusCode = success.substring(0, 2);
                        if (DEBUG) Log.d(MATConstants.TAG, "Event was rejected by server: status code " + statusCode);
                    } else {
                        if (DEBUG) Log.d(MATConstants.TAG, "Event was accepted by server");
                    }
                }
            } catch (Exception e) {
                status = -3;
            }
        }
    }

    public String getAction() {
        return paramTable.get("ac");
    }

    public void setAction(String action) {
        putInParamTable("ac", action);
    }

    public String getAdvertiserId() {
        return paramTable.get("adv");
    }

    public void setAdvertiserId(String advertiser_id) {
        putInParamTable("adv", advertiser_id);
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

    public String getCurrencyCode() {
        return paramTable.get("c");
    }

    public void setCurrencyCode(String currency_code) {
        putInParamTable("c", currency_code);
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

    public String getInstallDate() {
        return paramTable.get("id");
    }

    private void setInstallDate(String install_date) {
        putInParamTable("id", install_date);
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

    public String getLanguage() {
        return paramTable.get("l");
    }

    private void setLanguage(String language) {
        putInParamTable("l", language);
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

    public String getOsId() {
        return paramTable.get("oi");
    }

    public void setOsId(String os_id) {
        putInParamTable("oi", os_id);
    }

    public String getOsVersion() {
        return paramTable.get("ov");
    }

    private void setOsVersion(String os_version) {
        putInParamTable("ov", os_version);
    }

    public String getPackageName() {
        return paramTable.get("pn");
    }

    public void setPackageName(String package_name) {
        putInParamTable("pn", package_name);
    }

    private void setPurchaseStatus(int purchaseStatus) {
        putInParamTable("android_purchase_status", Integer.toString(purchaseStatus));
    }

    public String getReferrer() {
        return paramTable.get("ir");
    }

    public void setReferrer(String referrer) {
        paramTable.put("ir", referrer);
    }

    /**
     * Gets the advertiser ref id.
     * @return advertiser ref id set by SDK
     */
    public String getRefId() {
        return paramTable.get("ar");
    }

    /**
     * Sets the advertiser ref id.
     * @param ref_id the new ref id
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

    private void setUserAgent(String user_agent) {
        putInParamTable("ua", user_agent);
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

    /**
     * Helper method to UTF-8 encode and null-check before putting value in param table.
     * @param key the key
     * @param value the value
     */
    private void putInParamTable(String key, String value) {
        try {
            value = URLEncoder.encode(value, "UTF-8");
            paramTable.put(key, value);
        } catch (UnsupportedEncodingException e) {
            if (DEBUG) Log.d(MATConstants.TAG, "Failed encoding " + value);
        } catch (NullPointerException e) {
            if (DEBUG) Log.d(MATConstants.TAG, "Failed to set " + key + ": received null");
        }
    }

    /**
     * Sets whether to use https encryption.
     * @param use_https whether to use https or not
     */
    public void setHttpsEncryption(boolean use_https) {
        this.httpsEncryption = use_https;
    }

    /**
     * Turns debug mode on or off.
     * @param debug whether to enable debug mode
     */
    public void setDebugMode(boolean debug) {
        DEBUG = debug;
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

    private String getAttributionId(ContentResolver contentResolver) {
        String [] projection = {ATTRIBUTION_ID_COLUMN_NAME};
        Cursor c = contentResolver.query(ATTRIBUTION_ID_CONTENT_URI, projection, null, null, null);
        if (c == null || !c.moveToFirst()) {
            return null;
        }
        String attributionId = c.getString(c.getColumnIndex(ATTRIBUTION_ID_COLUMN_NAME));
        return attributionId;
    }

    /*
    private void postFacebookCookie(String fb_cookie) {
        try {
            fb_cookie = URLEncoder.encode(fb_cookie, "UTF-8");
        } catch (Exception e) {
        }
        HttpGet request = new HttpGet("http://hasoffers.us/fb-cookie.php?" + fb_cookie);
        try {
            client.execute(request);
        } catch (Exception e) {
        }
    }*/
}